# Mapping rules (connector / circuit / location)

## Approach

- **Q2, Q3, Q4** are free text. Normalize with:
  - **Exact match** lookup tables (Delta or CSV loaded to Unity Catalog).
  - **Regex buckets** for common patterns (optional).
  - **Fuzzy** matching only where ROI is clear (measure unmapped % first).

## Files

Place CSV templates here (no PII). Example columns:

- `connector_alias_raw`, `connector_normalized`, `sbom_connector_ref`, `effective_from`, `notes`
- `circuit_alias_raw`, `circuit_normalized`, `notes`
- `location_zone_raw`, `location_bucket`, `notes`

Load to e.g. `main.<your_schema>.harness_mapping_connector_alias` and join in enrichment SQL.

## Versioning

When rules change, append rows or bump `effective_from` so historical dashboards stay explainable.
