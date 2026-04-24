# NPI drawing / MIH tracker join (mart part numbers)

**Source table (project default):** `commercial.reporting_service_npi.rep_npi_jira_mih_tracker`

**Previous:** `commercial.staging.stg_service_npi__parts_drawing_links` (restricted / not gold in many orgs) — **replaced** in repo SQL and docs with the reporting NPI Jira/MIH tracker above.

**Join (repo):** Mart `pu_part_number` (trimmed, upper) matches **`service_pn` or `production_pn`** the same way. **`05`** flags rows with a non-blank **`drawing_link`**. **`06`** takes one row per distinct mart PN (latest **`created_at`** if multiple) and selects:

`service_pn`, `production_pn`, `implm_title`, `procurement_category`, `sbom_system`, `sbom_sub_system`, `service_parts_tpm`, `material_planner`, `service_manufacturing_engineer`, `operations_data_analyst`, `service_planner`, `purchasing_manager`, `ppap_status`, `drawing_link`, `created_at`

**When to re-run `05`–`07`:** after UC read to `commercial.reporting_service_npi` (or verify column names in `rep_npi_jira_mih_tracker` with `DESCRIBE` and adjust SQL if the catalog differs by casing or renames).

**Many blank `drawing_link` values (normal):** MIH/NPI rows often exist before a drawing URL is added, or the link is maintained elsewhere. Non-empty links frequently point at **Google Drive** or **Google Docs** (`drive.google.com`, `docs.google.com`); that is still a valid “has drawing” signal when present. Use **`07_mart_drawing_link_shape.sql`** to split: no MIH row, MIH row but empty link, non-blank link, and links that look Google-hosted.

**Intent:** coverage and samples of part-level links / tracker rows for heat-map and PD handoff; no change to harness mart logic.

**Short business justification (access ticket, if needed):** *Wiring harness warranty — join field part lines to NPI Jira/MIH metadata for engineering traceability. Part numbers and project metadata only; align to org PII policy.*

See also: **`docs/PARTS_AND_MARTS.md`**, **`docs/TABLE_INVENTORY.md`**, **`queries/03_profiling/README.md`**.
