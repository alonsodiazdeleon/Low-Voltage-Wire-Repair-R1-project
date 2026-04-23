-- Top 30 raw connector free-text (Q2) from mart cohort — drives `mapping/` alias design.
-- No trailing `;` (Genie safe).

SELECT
  TRIM(CAST(connector_number AS STRING)) AS connector_number,
  COUNT(*) AS row_count
FROM sandbox.adiazdeleon.harness_warranty_780095014_cohort
WHERE connector_number IS NOT NULL AND TRIM(CAST(connector_number AS STRING)) <> ''
GROUP BY TRIM(CAST(connector_number AS STRING))
ORDER BY row_count DESC
LIMIT 30
