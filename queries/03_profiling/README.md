# Profiling + drawing coverage (mart-aligned)

Same **harness labor + FPM + date** grain as **`04_mart_ctas_warranty_ebom.sql` section B**, but reads the materialized **`harness_warranty_780095014_cohort`** so results match the mart cohort without re-scanning QA + flat view logic in one giant script.

| Order | File | Output |
|-------|------|--------|
| 1 | **`01_mart_cohort_free_text_summary.sql`** | One row: null/blank % for Q2/Q3/Q4 + distinct value counts |
| 2 | **`02_mart_cohort_top_connector_text.sql`** | Top 30 raw `connector_number` (Q2) |
| 3 | **`03_mart_cohort_top_circuit_text.sql`** | Top 30 raw `circuit` (Q3) |
| 4 | **`04_mart_cohort_top_location_text.sql`** | Top 30 raw `reapair_location` (Q4) |
| 5 | **`05_mart_part_drawing_coverage_summary.sql`** | One row: distinct mart `pu_part_number` vs count with any NPI drawing link |
| 6 | **`06_mart_part_drawing_sample.sql`** | Up to 40 parts with one link row each (latest `revision` when present) |

**Prereq:** `sandbox.adiazdeleon.harness_warranty_780095014_cohort` and **`harness_mart_warranty_ebom`** exist (run **04** first).

**Genie / “run whole file”:** each file is a **single** `SELECT` with **no** trailing `;`.

**NPI drawing table (`stg_service_npi__parts_drawing_links`):** in many orgs the table is **restricted** or not **gold** yet. **`05`–`06` stay in the repo** as the target design; re-run (or point at the promoted FQN) when you are **authorized** — see **`docs/OPTIONAL_NPI_DRAWING_LINKS.md`**. Until then, work can continue on cohort profiling (**`01`–`04`**) and EBOM mart work.

**Legacy:** `queries/01_staging/02_free_text_profile.sql` still builds a temp view + multiple blocks — use that in a notebook **cell-by-cell**, or use this folder for repo runs.

When the links table is available, confirm columns with `DESCRIBE TABLE commercial.staging.stg_service_npi__parts_drawing_links` (or your gold replacement).
