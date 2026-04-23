-- Top 30 raw location free-text (Q4) from mart cohort.
-- No trailing `;` (Genie safe).

SELECT
  TRIM(CAST(reapair_location AS STRING)) AS reapair_location,
  COUNT(*) AS row_count
FROM sandbox.adiazdeleon.harness_warranty_780095014_cohort
WHERE reapair_location IS NOT NULL AND TRIM(CAST(reapair_location AS STRING)) <> ''
GROUP BY TRIM(CAST(reapair_location AS STRING))
ORDER BY row_count DESC
LIMIT 30
