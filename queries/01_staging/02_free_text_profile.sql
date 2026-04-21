-- Free-text profile: connector_number (Q2), circuit (Q3), reapair_location (Q4)
-- Same tt + filters as 01_canonical_ingress.sql — keep pilot lines in sync when comparing.
--
-- Run in Databricks SQL: execute the FULL script (all statements). If your UI runs only
-- the first query, run each block (between dashed lines) separately in order.

-- =============================================================================
-- 0) Reusable base: distinct rows at same grain as canonical ingress (subset of cols)
-- =============================================================================
CREATE OR REPLACE TEMPORARY VIEW harness_warranty_base AS
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
  s.sr_service_request_id,
  s.v_vehicle_model,
  s.v_veh_program,
  tt.connector_number,
  tt.circuit,
  tt.reapair_location
FROM main.vehicle_services.vs_rpt_flat_view s
LEFT JOIN tt ON s.sr_service_request_id = tt.service_request_id
WHERE 1 = 1
  AND s.is_field_performance_metric_included = 1
  AND s.cr_labor_code = '780095014'
  AND s.sr_completed_date >= '2026-01-01'
  -- Pilot R1: AND s.v_vehicle_model LIKE 'R1%'
  -- Alt pilot: AND s.v_veh_program LIKE 'R1%'
;

-- =============================================================================
-- 1) Summary: row counts and null/blank rates (free text → mapping coverage)
-- =============================================================================
SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT sr_service_request_id) AS distinct_sr_id_count,
  ROUND(100.0 * SUM(CASE
    WHEN connector_number IS NULL OR TRIM(CAST(connector_number AS STRING)) = '' THEN 1
    ELSE 0
  END) / NULLIF(COUNT(*), 0), 2) AS pct_connector_null_or_blank,
  ROUND(100.0 * SUM(CASE
    WHEN circuit IS NULL OR TRIM(CAST(circuit AS STRING)) = '' THEN 1
    ELSE 0
  END) / NULLIF(COUNT(*), 0), 2) AS pct_circuit_null_or_blank,
  ROUND(100.0 * SUM(CASE
    WHEN reapair_location IS NULL OR TRIM(CAST(reapair_location AS STRING)) = '' THEN 1
    ELSE 0
  END) / NULLIF(COUNT(*), 0), 2) AS pct_location_null_or_blank,
  COUNT(DISTINCT CASE
    WHEN connector_number IS NOT NULL AND TRIM(CAST(connector_number AS STRING)) <> '' THEN TRIM(CAST(connector_number AS STRING))
  END) AS distinct_connector_values,
  COUNT(DISTINCT CASE
    WHEN circuit IS NOT NULL AND TRIM(CAST(circuit AS STRING)) <> '' THEN TRIM(CAST(circuit AS STRING))
  END) AS distinct_circuit_values,
  COUNT(DISTINCT CASE
    WHEN reapair_location IS NOT NULL AND TRIM(CAST(reapair_location AS STRING)) <> '' THEN TRIM(CAST(reapair_location AS STRING))
  END) AS distinct_location_values
FROM harness_warranty_base
;

-- =============================================================================
-- 2) Top 30 connector_number (raw)
-- =============================================================================
SELECT
  TRIM(CAST(connector_number AS STRING)) AS connector_number,
  COUNT(*) AS row_count
FROM harness_warranty_base
WHERE connector_number IS NOT NULL AND TRIM(CAST(connector_number AS STRING)) <> ''
GROUP BY TRIM(CAST(connector_number AS STRING))
ORDER BY row_count DESC
LIMIT 30
;

-- =============================================================================
-- 3) Top 30 circuit
-- =============================================================================
SELECT
  TRIM(CAST(circuit AS STRING)) AS circuit,
  COUNT(*) AS row_count
FROM harness_warranty_base
WHERE circuit IS NOT NULL AND TRIM(CAST(circuit AS STRING)) <> ''
GROUP BY TRIM(CAST(circuit AS STRING))
ORDER BY row_count DESC
LIMIT 30
;

-- =============================================================================
-- 4) Top 30 reapair_location
-- =============================================================================
SELECT
  TRIM(CAST(reapair_location AS STRING)) AS reapair_location,
  COUNT(*) AS row_count
FROM harness_warranty_base
WHERE reapair_location IS NOT NULL AND TRIM(CAST(reapair_location AS STRING)) <> ''
GROUP BY TRIM(CAST(reapair_location AS STRING))
ORDER BY row_count DESC
LIMIT 30
;
