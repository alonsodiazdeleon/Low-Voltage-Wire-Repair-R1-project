# Harness warranty analytics (R1 pilot)

Databricks-native analytics for **wiring harness repair** warranty work: join ServiceOS claims + QA answers to **EBOM/SBOM** and service parts, classify **free-text** connector/circuit/location, and roll up by harness family for PD/SQE action items.

## Pilot scope

- **Program filter:** `R1%` (R1S / R1T) — add to queries when ready (see `queries/01_staging/01_canonical_ingress.sql`).
- **Mapping authority:** EBOM-first (`dim_fct_catia_ebom_parts`, `dim_sbom_parts`, serviceable views as needed).
- **Canonical ingress:** matches the query that feeds the existing Databricks Dashboard (see `docs/DATA_CONTRACT.md`).

## Repository layout

| Path | Purpose |
|------|---------|
| `queries/01_staging/` | Dashboard-aligned base query (`tt` + `vs_rpt_flat_view`). |
| `queries/02_enrichment/` | SBOM/EBOM/SOS joins (add as you validate keys). |
| `notebooks/` | Profiling, Python/pandas, Jobs source. |
| `mapping/` | Connector/circuit **alias** definitions (CSV → load to Delta) and notes. |
| `docs/` | Data contract, table inventory, grains. |

## Hybrid delivery (org)

- **dbt:** Production curated layers (DE-owned); promote marts here when aligned.
- **This repo:** Domain SQL + notebooks until promotion.

## Next steps

1. Run `01_canonical_ingress.sql` in Databricks (adjust date/program filters).
2. Profile `dim_sbom_parts` / `dim_fct_catia_ebom_parts` join keys for R1%.
3. Add enrichment SQL under `queries/02_enrichment/` and optional Delta tables for mapping rules.

## Governance

Technician notes and images are approved for shared dashboards; avoid logging sensitive payloads in operational logs per org policy.
