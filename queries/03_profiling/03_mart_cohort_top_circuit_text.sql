-- Top 30 raw circuit free-text (Q3) from mart cohort.
-- No trailing `;` (Genie safe).

SELECT
  TRIM(CAST(circuit AS STRING)) AS circuit,
  COUNT(*) AS row_count
FROM sandbox.adiazdeleon.harness_warranty_780095014_cohort
WHERE circuit IS NOT NULL AND TRIM(CAST(circuit AS STRING)) <> ''
GROUP BY TRIM(CAST(circuit AS STRING))
ORDER BY row_count DESC
LIMIT 30
