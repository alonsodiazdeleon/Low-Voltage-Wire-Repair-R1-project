-- Up to 30 distinct mart `pu_part_number` values that **do not** match **any** of
--   `service_pn`, `production_pn`, or `svc_tracker_production_pn` on the MIH tracker
--   (same normalization as **`05`–`07`**). Use to eyeball format / leading-zero / prefix issues.
-- No trailing `;` (Genie safe). `docs/OPTIONAL_NPI_DRAWING_LINKS.md`

WITH mart_pns AS (
  SELECT DISTINCT
    CAST(pu_part_number AS STRING) AS pu_raw,
    TRIM(UPPER(CAST(pu_part_number AS STRING))) AS pu_norm
  FROM sandbox.adiazdeleon.harness_mart_warranty_ebom
  WHERE TRIM(UPPER(COALESCE(CAST(pu_part_number AS STRING), ''))) <> ''
)
SELECT
  p.pu_raw,
  p.pu_norm
FROM mart_pns p
WHERE NOT EXISTS (
  SELECT 1
  FROM commercial.reporting_service_npi.rep_npi_jira_mih_tracker d
  WHERE p.pu_norm = TRIM(UPPER(CAST(d.service_pn AS STRING)))
    OR p.pu_norm = TRIM(UPPER(CAST(d.production_pn AS STRING)))
    OR p.pu_norm = TRIM(UPPER(CAST(d.svc_tracker_production_pn AS STRING)))
)
ORDER BY p.pu_norm
LIMIT 30
