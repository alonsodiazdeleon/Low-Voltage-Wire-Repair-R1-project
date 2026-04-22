-- Part lines from the same mart as the harness warranty base (no commercial SOS fact).
-- `main.vehicle_services.vs_rpt_flat_view` already exposes per-line part consumption:
--   pu_part_number, pu_part_quantity, pu_total_part_cost, etc. (reliability / ServiceOS analytic layer)
--
-- This extends ../01_staging/01_canonical_ingress.sql with those columns on the **same** labor-filtered rows.
-- Use unqualified `tier3` (QA / tt), not `s.tier3` — tier3 is not a column on `vs_rpt_flat_view` in this environment.
-- If `pu_part_number` is often null on cr_labor_code = 780095014 rows, use the OPTIONAL block at the bottom
-- to pull all part lines for the same SRs (uncomment and align filters).
--
-- Connector PN → parent harness PN: use SBOM/EBOM (e.g. dim_sbom_parts + dim_fct_catia_ebom_parts), not SOS.

WITH tt AS (
  SELECT DISTINCT
    service_request_id,
    tier3,
    MAX(CASE WHEN qa_q = '1. Which wiring harness repair(s) did you perform?' THEN qa_a[0] END) AS repair_type,
    MAX(CASE WHEN qa_q = '2. Which connector numbers were worked on?' THEN qa_a[0] END) AS connector_number,
    MAX(CASE WHEN qa_q = '3. Which circuit numbers were worked on?' THEN qa_a[0] END) AS circuit,
    MAX(CASE WHEN qa_q = '4. Where is the location of the repair in relation to the vehicle body?' THEN qa_a[0] END) AS reapair_location,
    MAX(CASE WHEN qa_q = '5. Upload image of the defect found BEFORE repairs are performed.' THEN has_image_keys END) AS image_before_repair,
    MAX(CASE WHEN qa_q = '5. Upload image of the defect found AFTER repairs are performed.' THEN has_image_keys END) AS image_after_repair
  FROM main.vehicle_services.vs_event_schema_flattened
  WHERE 1 = 1
    AND (tier1 = 'Wiring Harness Repair' OR tier3 = 'Wiring Harness Repair')
  GROUP BY service_request_id, tier3
)

SELECT DISTINCT
  s.v_vin,
  s.v_vehicle_model,
  s.v_veh_program,
  s.v_vehicle_platform,
  s.days_to_sr,
  s.wo_workorder_id,
  s.sr_service_request_number,
  s.sr_service_request_id,
  s.sr_created_date,
  s.sr_completed_date,
  s.mapped_endpoint,
  s.sr_concern,
  s.sr_technician_notes,
  s.sr_internal_technician_notes,
  tier3,
  tt.repair_type,
  tt.connector_number,
  tt.circuit,
  tt.reapair_location,
  tt.image_before_repair,
  tt.image_after_repair,
  s.vehicle_breakdown_grouping,
  s.sr_pri_fail_labor_sys,
  s.sr_pri_fail_labor_subsys,
  s.sr_pri_fail_part_number,
  s.sr_pri_fail_part_descr,
  s.cr_labor_code,
  s.cr_labor_description,
  s.pu_part_number,
  s.pu_part_description,
  s.pu_part_rpt_group,
  s.pu_part_quantity,
  s.pu_individual_part_cost,
  s.pu_total_part_cost,
  CASE WHEN s.vehicle_breakdown_grouping = 'Tow VBR' THEN TRUE ELSE FALSE END AS is_tow,
  CASE WHEN s.days_to_sr <= 90 THEN TRUE ELSE FALSE END AS is_3MIS
FROM main.vehicle_services.vs_rpt_flat_view s
LEFT JOIN tt ON s.sr_service_request_id = tt.service_request_id
WHERE 1 = 1
  AND s.is_field_performance_metric_included = 1
  AND s.cr_labor_code = '780095014'
  AND s.sr_completed_date >= '2026-01-01'
  -- Pilot R1: AND s.v_vehicle_model LIKE 'R1%'
  -- Alt pilot: AND s.v_veh_program LIKE 'R1%'
LIMIT 2000
;

-- =============================================================================
-- OPTIONAL — all part lines for SRs that appear in the harness-labor set above
-- Use when part consumption lives on a different flat_view row than labor 780095014.
-- Run as a second query; validate join keys and FPM filter with your team.
-- =============================================================================
/*
WITH tt AS (
  SELECT DISTINCT
    service_request_id,
    tier3,
    MAX(CASE WHEN qa_q = '1. Which wiring harness repair(s) did you perform?' THEN qa_a[0] END) AS repair_type,
    MAX(CASE WHEN qa_q = '2. Which connector numbers were worked on?' THEN qa_a[0] END) AS connector_number,
    MAX(CASE WHEN qa_q = '3. Which circuit numbers were worked on?' THEN qa_a[0] END) AS circuit,
    MAX(CASE WHEN qa_q = '4. Where is the location of the repair in relation to the vehicle body?' THEN qa_a[0] END) AS reapair_location,
    MAX(CASE WHEN qa_q = '5. Upload image of the defect found BEFORE repairs are performed.' THEN has_image_keys END) AS image_before_repair,
    MAX(CASE WHEN qa_q = '5. Upload image of the defect found AFTER repairs are performed.' THEN has_image_keys END) AS image_after_repair
  FROM main.vehicle_services.vs_event_schema_flattened
  WHERE 1 = 1
    AND (tier1 = 'Wiring Harness Repair' OR tier3 = 'Wiring Harness Repair')
  GROUP BY service_request_id, tier3
),
harness_sr AS (
  SELECT DISTINCT s.sr_service_request_id
  FROM main.vehicle_services.vs_rpt_flat_view s
  LEFT JOIN tt ON s.sr_service_request_id = tt.service_request_id
  WHERE s.is_field_performance_metric_included = 1
    AND s.cr_labor_code = '780095014'
    AND s.sr_completed_date >= '2026-01-01'
)
SELECT
  s.v_vin,
  s.sr_service_request_id,
  s.wo_workorder_id,
  s.cr_labor_code,
  s.pu_part_number,
  s.pu_part_description,
  s.pu_part_quantity,
  s.pu_total_part_cost
FROM main.vehicle_services.vs_rpt_flat_view s
INNER JOIN harness_sr h ON s.sr_service_request_id = h.sr_service_request_id
WHERE s.pu_part_number IS NOT NULL
  AND s.is_field_performance_metric_included = 1
LIMIT 5000
;
*/
