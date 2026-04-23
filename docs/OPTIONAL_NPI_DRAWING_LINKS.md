# Optional: NPI part drawing links (`stg_service_npi__parts_drawing_links`)

**Status (project):** `commercial.staging.stg_service_npi__parts_drawing_links` is a **restricted** / **non–gold** table in some environments. Queries in **`queries/03_profiling/05`** and **`06`** are written as if the table is available; they will **fail or block** until Unity Catalog / gold access is approved.

**What to do when you have access (or a promoted gold table):**

1. Re-run **`05_mart_part_drawing_coverage_summary.sql`** and **`06_mart_part_drawing_sample.sql`**.
2. If the **gold** object lives at a different `catalog.schema.table`, find/replace the FQN in those two files (and in `docs/TABLE_INVENTORY.md`).

**Intent:** join distinct mart `pu_part_number` values to published drawing metadata (`part_number`, `revision`, `drawing_link` or successor columns) for heat-map and PD handoff work — same logic before and after promotion; only the table location and governance change.

**Short business justification (edit for your access ticket):** *Wiring harness warranty analytics: engineering drawing PDFs by part number to align field repairs with schematics. Analysis uses only part numbers and links already approved for product documentation; no customer PII.*

See also: **`docs/PARTS_AND_MARTS.md`** and **`queries/03_profiling/README.md`**.
