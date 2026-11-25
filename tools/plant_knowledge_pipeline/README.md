# Plant knowledge validator

Standard-library Python validator for `assets/knowledge/plants.json`. It is read-only unless you explicitly ask it to write a report with `--report`.

From the Flutter project root:

```powershell
python tools/plant_knowledge_pipeline/validate_plants.py assets/knowledge/plants.json --report build/plant_knowledge_audit.json
```

Exit codes: `0` = schema/consistency checks passed (quality warnings may remain); `1` = record validation errors; `2` = unreadable input or invalid top-level structure.

The validator checks required fields, duplicate IDs/scientific-name strings, array types, controlled review/evidence values, toxicity nullability, and source-reference titles/URLs. It deliberately does not claim to verify botanical truth: that requires checking each source and the accepted taxonomy.
