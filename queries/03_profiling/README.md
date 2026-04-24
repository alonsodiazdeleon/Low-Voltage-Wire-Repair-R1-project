# Profiling + drawing coverage (mart-aligned)

Same **harness labor + FPM + date** grain as **`04_mart_ctas_warranty_ebom.sql` section B**, but reads the materialized **`harness_warranty_780095014_cohort`** so results match the mart cohort without re-scanning QA + flat view logic in one giant script.

| Order | File | Output |
|-------|------|--------|
| 1 | **`01_mart_cohort_free_text_summary.sql`** | One row: null/blank % for Q2/Q3/Q4 + distinct value counts |
| 2 | **`02_mart_cohort_top_connector_text.sql`** | Top 30 raw `connector_number` (Q2) |
| 3 | **`03_mart_cohort_top_circuit_text.sql`** | Top 30 raw `circuit` (Q3) |
| 4 | **`04_mart_cohort_top_location_text.sql`** | Top 30 raw `reapair_location` (Q4) |
| 5 | **`05_mart_part_drawing_coverage_summary.sql`** | One row: distinct mart PNs vs count matching `rep_npi_jira_mih_tracker` on `service_pn` / `production_pn` with a `drawing_link` |
| 6 | **`06_mart_part_drawing_sample.sql`** | Up to 40 parts; SBOM, TPM, owners, `ppap_status`, `drawing_link`, `created_at` (see doc) |
| 7 | **`07_mart_drawing_link_shape.sql`** | One row: no-MIH vs MIH-but-blank-`drawing_link` vs any link vs Google Drive/Docs-shaped links |
| 8 | **`08_mart_pu_no_mih_match_sample.sql`** | Up to 30 PNs with **no** `service_pn` / `production_pn` / `svc_tracker_production_pn` match (debug formats) |
| 9 | **`09_mart_pu_mih_suffix_variant_probe.sql`** | All exact-unmatched PNs: suffix-stripped variants vs MIH key set (which strip would match?). **Validated** in pilot — keep; adjust regexes if part-number grammar changes. |

**Prereq:** `sandbox.adiazdeleon.harness_warranty_780095014_cohort` and **`harness_mart_warranty_ebom`** exist (run **04** first).

**Genie / “run whole file”:** each file is a **single** `SELECT` with **no** trailing `;`.

**NPI / MIH (`commercial.reporting_service_npi.rep_npi_jira_mih_tracker`):** join mart `pu_part_number` to **`service_pn` or `production_pn`**. Staging `stg_service_npi__parts_drawing_links` is not used. Column list: **`docs/OPTIONAL_NPI_DRAWING_LINKS.md`**; confirm with `DESCRIBE` if the catalog renames a field.

**Legacy:** `queries/01_staging/02_free_text_profile.sql` still builds a temp view + multiple blocks — use that in a notebook **cell-by-cell**, or use this folder for repo runs.

Confirm columns: `DESCRIBE TABLE commercial.reporting_service_npi.rep_npi_jira_mih_tracker`. **`09`** re-scans MIH to build a key set — can be heavy; run off-peak if the tracker is very large.
