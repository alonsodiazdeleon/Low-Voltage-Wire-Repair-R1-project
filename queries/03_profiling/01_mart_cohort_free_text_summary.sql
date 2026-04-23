-- One-row free-text health check on **mart cohort** (Q2 connector, Q3 circuit, Q4 location).
-- Source: `sandbox.adiazdeleon.harness_warranty_780095014_cohort` (same grain as 04 section B).
-- No trailing `;` (Genie / run-whole-file safe).

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
    WHEN connector_number IS NOT NULL AND TRIM(CAST(connector_number AS STRING)) <> ''
      THEN TRIM(CAST(connector_number AS STRING))
  END) AS distinct_connector_values,
  COUNT(DISTINCT CASE
    WHEN circuit IS NOT NULL AND TRIM(CAST(circuit AS STRING)) <> ''
      THEN TRIM(CAST(circuit AS STRING))
  END) AS distinct_circuit_values,
  COUNT(DISTINCT CASE
    WHEN reapair_location IS NOT NULL AND TRIM(CAST(reapair_location AS STRING)) <> ''
      THEN TRIM(CAST(reapair_location AS STRING))
  END) AS distinct_location_values
FROM sandbox.adiazdeleon.harness_warranty_780095014_cohort
