# Enrichment queries (Phase 1+)

Add SQL here after profiling join keys:

1. **`fct_sos_detailed_service_rpt`** — parts on SR (join on VIN / WO / SR / date as validated).
2. **`dim_sbom_parts`** — filter to harness/connector/LVE/R1 model.
3. **`dim_fct_catia_ebom_parts`** — parent harness ↔ child connector.
4. **Serviceable views** — when service PN path differs from engineering EBOM.
5. **`stg_service_npi__parts_drawing_links`** — PDF link by `part_number` for heat-map / PD handoff.

Suggested pattern: build from `01_staging/01_canonical_ingress.sql` as a CTE or temp view, then layer joins in separate files (e.g. `02_with_sbom_parts.sql`).
