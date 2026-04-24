# Harness warranty analytics

Databricks-native analytics for **wiring harness repair** warranty work: join ServiceOS claims + QA answers to **EBOM/SBOM** and service parts, classify **free-text** connector/circuit/location, and roll up by harness family for PD/SQE action items.

## Pilot scope

- **R1 filter:** optional — **off by default** in `01_canonical_ingress.sql`; uncomment `v_vehicle_model LIKE 'R1%'` (or `v_veh_program`) when you want R1S/R1T only.
- **Mapping authority:** EBOM-first (`dim_fct_catia_ebom_parts`, `dim_sbom_parts`, serviceable views as needed).
- **Canonical ingress:** matches the query that feeds the existing Databricks Dashboard (see `docs/DATA_CONTRACT.md`).

## Repository layout

| Path | Purpose |
|------|---------|
| `queries/01_staging/` | `01_canonical_ingress.sql` (base); `02_free_text_profile.sql` (multi-cell temp view + tops). |
| `queries/02_enrichment/` | `01`–`03` joins, **`04` CTAS** marts, **`04c`** smoke, **`04d`** mart QA. |
| `queries/03_profiling/` | Mart-cohort **Q2/Q3/Q4**; **NPI / MIH** **05**–**07** (links + link-shape; Genie-safe, one `SELECT` per file). |
| `docs/PARTS_AND_MARTS.md` | **Why** we use flat view + repair rates, not `fct_sos_detailed_service_rpt`. |
| `notebooks/` | Profiling, Python/pandas, Jobs source. |
| `mapping/` | Connector/circuit **alias** definitions (CSV → load to Delta) and notes. |
| `docs/` | Data contract, table inventory, grains, **`OPTIONAL_NPI_DRAWING_LINKS.md`** (`rep_npi_jira_mih_tracker` for **`05`–`06`**). |

## Hybrid delivery (org)

- **dbt:** Production curated layers (DE-owned); promote marts here when aligned.
- **This repo:** Domain SQL + notebooks until promotion.

## Next steps

1. Run `01_canonical_ingress.sql` in Databricks (adjust date; optional uncomment R1 model/program filter).
2. After **04** cohort exists, run **`queries/03_profiling/`** (`01`–`04`) for free-text summary + top 30s (Genie-safe). Or run **`02_free_text_profile.sql`** cell-by-cell in a notebook.
3. Read **`docs/PARTS_AND_MARTS.md`** (flat view = part lines; no SOS table required for MVP).
4. Run **`queries/02_enrichment/01_base_with_flat_view_parts.sql`** — confirm `pu_part_*` populate; use optional second block in file if parts sit on other SR rows.
5. Run **`02_lve_ebom_connector_to_harness_map.sql`** (full EBOM) as needed, or a saved table/view in your schema.
6. Run **`queries/02_enrichment/03_warranty_ebom_join.sql`** (ad-hoc; add outer `LIMIT` if needed) or **`queries/02_enrichment/04_mart_ctas_warranty_ebom.sql`** (sections A, B, C — targets `sandbox.adiazdeleon`; change in file if needed) to build durable tables and the **mart** with `ebom_match_type`.
7. Run **`queries/02_enrichment/04c_post_c_notebook_check.sql`** then **`04d_mart_quality_summary.sql`** after each mart refresh (counts + match mix).
8. Run **`queries/03_profiling/01`–`04`** for free-text summary + top 30s (mart cohort).
9. Run **`queries/03_profiling/05`**, **`06`**, and optional **`07`** (link blanks vs Google Drive / Docs) on **`commercial.reporting_service_npi.rep_npi_jira_mih_tracker`**. See **`docs/OPTIONAL_NPI_DRAWING_LINKS.md`**.
10. Add **Delta** mapping tables for Q2/Q3 free text as needed.

## Governance

Technician notes and images are approved for shared dashboards; avoid logging sensitive payloads in operational logs per org policy.
