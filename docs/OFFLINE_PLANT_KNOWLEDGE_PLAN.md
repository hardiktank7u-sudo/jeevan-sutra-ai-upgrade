# Jeevan Sutra — Offline Plant Knowledge Plan

## Current baseline (source archive reviewed 22 Nov 2026)

- 92 plant records; 50 distinct families.
- Every record has a non-empty scientific-name and family field, but these are not thereby taxonomically verified.
- 85/92 have an identification description; 7 do not.
- 81/92 have a safety summary; 11 do not.
- All 92 are marked `research_extracted`; none are marked as independently reviewed.
- All 92 use `evidenceLevel: not_assessed`.
- IDs and scientific-name strings are unique in this snapshot.

This is a quality snapshot, not a claim that all 92 records are scientifically validated. The catalogue's `sourcePolicy` says the records were extracted from the user's research collection and external authoritative sources are for later verification.

## Data rules

1. Do not create a record from a guessed common name or an AI-generated answer.
2. Keep the accepted scientific name, author citation (where available), family, and taxonomic source traceable.
3. Store traditional knowledge separately from modern scientific evidence. A traditional-use statement must not be rewritten as proof of efficacy.
4. `isToxic: null` means unknown/not assessed. Never convert missing safety data into `false`.
5. Keep safety summary and precautions separate; do not leave a blank safety field looking like a declaration of safety.
6. Every factual claim should be linked to a source reference and a `supports` description that says exactly which fields/claims it supports.
7. Keep `reviewStatus` as `draft` or `research_extracted` until a human review is completed. Track reviewer and review date for approved records.
8. Deduplicate using both stable record ID and normalized scientific name; possible synonyms should be represented explicitly rather than silently merged.
9. Do not count a plant toward a verified target until its taxonomy and minimum content review gates pass.

## Recommended record workflow

`candidate → taxonomy_checked → content_researched → safety_checked → reviewed → approved → published`

The current app model has a `reviewStatus` string. Until the model is extended, use the existing values conservatively and document any new controlled values before adding them to production data.

## Suggested minimum acceptance gates

- Valid stable ID, common name, scientific name, and family.
- Taxonomic source attached (e.g. accepted-name record from a recognized botanical authority).
- At least one source reference with a title, organization/authors, URL or DOI, and `supports` field.
- Identification notes are source-backed or explicitly marked unavailable.
- Safety status is explicit: supported warning, supported non-toxic statement, or unknown (`null`).
- Traditional uses and scientific evidence are separated; evidence level is not upgraded without relevant evidence.
- No duplicate ID or accepted scientific name.
- Human review status and date recorded before publication.

## Offline-first architecture (proposal; not applied to Firebase)

- **Bundled seed:** ship a validated, versioned JSON snapshot in `assets/knowledge/` so first launch and airplane-mode use work.
- **Local database:** use SQLite for larger catalogues, indexed by normalized common/scientific/Sanskrit/Hindi names, family, keywords, and stable ID. Keep the bundled snapshot as the recovery seed.
- **Remote master:** maintain a backend master separately from the local cache. Publish immutable dataset versions with `version`, `generatedAt`, `recordCount`, `checksum`, and schema version.
- **Sync:** app checks a small version manifest when online; downloads a complete or incremental update; validates checksum/schema; writes to a temporary local database; swaps only after validation. Failed updates leave the prior offline database untouched.
- **Assistant:** offline assistant should retrieve matching local records and clearly say when no reliable match exists. It must not invent medical advice or claim to diagnose/treat conditions. Online AI remains an optional enhancement.

## Backend decision still pending

Firestore is a plausible master store because Firebase is already part of the app, but no cloud schema, rules, indexes, or deployment should be changed without explicit approval. Before that, agree on record ownership, public-read/private-write rules, review workflow, versioning, and whether the published snapshot is generated in CI or manually.

## Data source strategy

Use authoritative taxonomy sources (for example, Kew Plants of the World Online and the Botanical Survey of India) for accepted names and distribution; use GBIF carefully for occurrence/taxonomic cross-checks; use peer-reviewed literature for scientific evidence; use recognized traditional materia medica/official publications for traditional references. Record the exact source and the exact claim it supports. Check dataset/API licensing and terms before bulk ingestion. Do not scrape indiscriminately.
