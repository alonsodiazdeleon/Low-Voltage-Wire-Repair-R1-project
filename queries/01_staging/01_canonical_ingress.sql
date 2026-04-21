-- Canonical ingress: dashboard-aligned harness warranty base.
-- Run in Databricks SQL. Add pilot filter: AND v_veh_program LIKE 'R1%' when ready.
--
-- Mapping focus (free text → EBOM/SBOM): connector_number (Q2), circuit (Q3), reapair_location (Q4).

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
  s.tier3,
  tt.repair_type,
  tt.connector_number,
  tt.circuit,
  tt.reapair_location,
  tt.image_before_repair,
  tt.image_after_repair,
  s.vehicle_breakdown_grouping,
  s.sr_pri_fail_labor_sys,
  s.sr_pri_fail_labor_subsys,
  CASE WHEN s.vehicle_breakdown_grouping = 'Tow VBR' THEN TRUE ELSE FALSE END AS is_tow,
  CASE WHEN s.days_to_sr <= 90 THEN TRUE ELSE FALSE END AS is_3mis
FROM main.vehicle_services.vs_rpt_flat_view s
LEFT JOIN tt ON s.sr_service_request_id = tt.service_request_id
WHERE 1 = 1
  AND s.is_field_performance_metric_included = 1
  AND s.cr_labor_code = '780095014'
  AND s.sr_completed_date >= '2026-01-01'
  -- Pilot: AND s.v_veh_program LIKE 'R1%'
;
