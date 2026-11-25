#!/usr/bin/env python3
"""Validate Jeevan Sutra plant knowledge JSON without modifying source data."""
from __future__ import annotations
import argparse, collections, json, re, sys
from pathlib import Path
from urllib.parse import urlparse

REQUIRED = ("id", "commonName", "scientificName")
LIST_FIELDS = ("partsUsed", "traditionalReferences", "traditionalUses", "scientificEvidence",
               "knownCompounds", "evidenceLimitations", "precautions", "lookAlikes",
               "sources", "sourceDetails", "keywords")
ALLOWED_REVIEW = {"draft", "research_extracted", "needs_review", "reviewed", "approved", "rejected"}
ALLOWED_EVIDENCE = {"not_assessed", "traditional_use_only", "preclinical", "clinical_limited",
                    "clinical_moderate", "clinical_strong", "insufficient", "mixed"}


def norm(s: object) -> str:
    return re.sub(r"\s+", " ", str(s or "").strip()).casefold()


def validate(path: Path) -> tuple[list[str], dict]:
    errors: list[str] = []
    warnings: list[str] = []
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(data, dict) or not isinstance(data.get("plants"), list):
        raise ValueError('Expected a JSON object with a "plants" array.')
    plants = data["plants"]
    ids, scientific = {}, {}
    counts = collections.Counter()
    for i, p in enumerate(plants):
        at = f"plants[{i}]"
        if not isinstance(p, dict):
            errors.append(f"{at}: record must be an object")
            continue
        for field in REQUIRED:
            if not isinstance(p.get(field), str) or not p[field].strip():
                errors.append(f"{at}: missing/blank required field '{field}'")
        pid = norm(p.get("id"))
        sci = norm(p.get("scientificName"))
        if pid:
            if pid in ids: errors.append(f"{at}: duplicate id '{p.get('id')}' (also {ids[pid]})")
            else: ids[pid] = at
        if sci:
            if sci in scientific: errors.append(f"{at}: duplicate scientificName '{p.get('scientificName')}' (also {scientific[sci]})")
            else: scientific[sci] = at
        for field in LIST_FIELDS:
            value = p.get(field, [])
            if not isinstance(value, list): errors.append(f"{at}: '{field}' must be an array")
            elif any(not isinstance(x, (str, dict)) for x in value): errors.append(f"{at}: '{field}' contains unsupported value type")
        if not norm(p.get("family")): counts["missing_family"] += 1
        if not norm(p.get("identification")): counts["missing_identification"] += 1
        if not norm(p.get("safetySummary")): counts["missing_safety_summary"] += 1
        if not p.get("sourceDetails"): counts["missing_source_details"] += 1
        if not p.get("sources"): counts["missing_sources"] += 1
        status = p.get("reviewStatus", "draft")
        if status not in ALLOWED_REVIEW: errors.append(f"{at}: unknown reviewStatus '{status}'")
        evidence = p.get("evidenceLevel", "not_assessed")
        if evidence not in ALLOWED_EVIDENCE: warnings.append(f"{at}: unrecognized evidenceLevel '{evidence}' (check controlled vocabulary)")
        if p.get("isToxic") is not None and not isinstance(p.get("isToxic"), bool):
            errors.append(f"{at}: isToxic must be true, false, or null")
        # Safety and evidence are never inferred from missing data.
        if p.get("isToxic") is None and not norm(p.get("safetySummary")):
            counts["unknown_safety"] += 1
        for j, ref in enumerate(p.get("sourceDetails", []) if isinstance(p.get("sourceDetails"), list) else []):
            if isinstance(ref, str):
                if ref.strip():
                    counts["legacy_unstructured_source_notes"] += 1
                continue
            if not isinstance(ref, dict):
                errors.append(f"{at}.sourceDetails[{j}]: reference must be an object or legacy text note"); continue
            if not norm(ref.get("title")):
                errors.append(f"{at}.sourceDetails[{j}]: source title is required")
            url = ref.get("url")
            if url:
                parsed = urlparse(url)
                if parsed.scheme not in ("http", "https") or not parsed.netloc:
                    errors.append(f"{at}.sourceDetails[{j}]: invalid source URL '{url}'")
    if counts["legacy_unstructured_source_notes"]:
        warnings.append("Existing sourceDetails entries include legacy plain-text notes; convert them to structured references only after identifying the exact underlying source. Do not invent titles or URLs.")
    report = {
        "databaseVersion": data.get("databaseVersion"),
        "recordCount": len(plants),
        "uniqueFamilies": len({norm(p.get("family")) for p in plants if isinstance(p, dict) and norm(p.get("family"))}),
        "uniqueIds": len(ids),
        "uniqueScientificNames": len(scientific),
        "reviewStatuses": dict(collections.Counter(p.get("reviewStatus", "draft") for p in plants if isinstance(p, dict))),
        "evidenceLevels": dict(collections.Counter(p.get("evidenceLevel", "not_assessed") for p in plants if isinstance(p, dict))),
        "qualityGaps": dict(counts),
        "errorCount": len(errors),
        "warningCount": len(warnings),
        "errors": errors,
        "warnings": warnings,
    }
    return errors, report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("json_file", type=Path, help="Path to assets/knowledge/plants.json")
    ap.add_argument("--report", type=Path, help="Optional path to write JSON audit report")
    args = ap.parse_args()
    try:
        errors, report = validate(args.json_file)
    except Exception as exc:
        print(f"FATAL: {exc}", file=sys.stderr); return 2
    print(json.dumps({k: v for k, v in report.items() if k not in ("errors", "warnings")}, indent=2))
    if report["warnings"]:
        print("\nWARNINGS:"); print("\n".join("- " + x for x in report["warnings"]))
    if errors:
        print("\nERRORS:"); print("\n".join("- " + x for x in errors))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"\nReport written: {args.report}")
    print("\nVALIDATION PASSED" if not errors else "\nVALIDATION FAILED")
    return 0 if not errors else 1

if __name__ == "__main__":
    raise SystemExit(main())
