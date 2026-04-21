# Harness warranty analytics

Databricks-native analytics for **wiring harness repair** warranty work: join ServiceOS claims + QA answers to **EBOM/SBOM** and service parts, classify **free-text** connector/circuit/location, and roll up by harness family for PD/SQE action items.

## Pilot scope

- **R1 filter:** optional — **off by default** in `01_canonical_ingress.sql`; uncomment `v_vehicle_model LIKE 'R1%'` (or `v_veh_program`) when you want R1S/R1T only.
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

1. Run `01_canonical_ingress.sql` in Databricks (adjust date; optional uncomment R1 model/program filter).
2. Profile `dim_sbom_parts` / `dim_fct_catia_ebom_parts` join keys (e.g. when R1 filter is on).
3. Add enrichment SQL under `queries/02_enrichment/` and optional Delta tables for mapping rules.

## Governance

Technician notes and images are approved for shared dashboards; avoid logging sensitive payloads in operational logs per org policy.
