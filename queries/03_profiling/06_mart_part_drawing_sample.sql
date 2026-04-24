-- Sample: up to 40 distinct mart PNs with one tracker row each (latest `created_at` when multiple matches).
-- Mart PN = `service_pn` OR `production_pn` OR `svc_tracker_production_pn` (normalized).
-- Columns align to `rep_npi_jira_mih_tracker`.
-- The tracker also has a column `rn` (row id); the window below is aliased `match_rank` to avoid a name clash.
-- No trailing `;` (Genie). `docs/OPTIONAL_NPI_DRAWING_LINKS.md`

WITH mart_pns AS (
  SELECT DISTINCT
    CAST(pu_part_number AS STRING) AS pu_raw,
    TRIM(UPPER(CAST(pu_part_number AS STRING))) AS pu_norm
  FROM sandbox.adiazdeleon.harness_mart_warranty_ebom
  WHERE TRIM(UPPER(COALESCE(CAST(pu_part_number AS STRING), ''))) <> ''
),
ranked AS (
  SELECT
    p.pu_raw,
    p.pu_norm,
    d.service_pn,
    d.production_pn,
    d.svc_tracker_production_pn,
    d.implm_title,
    d.procurement_category,
    d.sbom_system,
    d.sbom_sub_system,
    d.service_parts_tpm,
    d.material_planner,
    d.service_manufacturing_engineer,
    d.operations_data_analyst,
    d.service_planner,
    d.purchasing_manager,
    d.ppap_status,
    d.drawing_link,
    d.created_at,
    ROW_NUMBER() OVER (
      PARTITION BY p.pu_norm
      ORDER BY d.created_at DESC NULLS LAST
    ) AS match_rank
  FROM mart_pns p
  LEFT JOIN commercial.reporting_service_npi.rep_npi_jira_mih_tracker d
    ON p.pu_norm = TRIM(UPPER(CAST(d.service_pn AS STRING)))
    OR p.pu_norm = TRIM(UPPER(CAST(d.production_pn AS STRING)))
    OR p.pu_norm = TRIM(UPPER(CAST(d.svc_tracker_production_pn AS STRING)))
)
SELECT
  pu_raw,
  pu_norm,
  service_pn,
  production_pn,
  svc_tracker_production_pn,
  implm_title,
  procurement_category,
  sbom_system,
  sbom_sub_system,
  service_parts_tpm,
  material_planner,
  service_manufacturing_engineer,
  operations_data_analyst,
  service_planner,
  purchasing_manager,
  ppap_status,
  drawing_link,
  created_at
FROM ranked
WHERE match_rank = 1
LIMIT 40
