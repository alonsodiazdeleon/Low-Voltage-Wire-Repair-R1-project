-- NPI / MIH tracker: coverage of distinct **mart** `pu_part_number` (non-blank) vs tracker rows
-- with a non-blank `drawing_link`. Mart PN matches **`service_pn` or `production_pn`** (case-insensitive trim).
-- Target: `commercial.reporting_service_npi.rep_npi_jira_mih_tracker`.
-- One result row. No trailing `;` (Genie safe). See: `docs/OPTIONAL_NPI_DRAWING_LINKS.md`.

WITH mart_pns AS (
  SELECT DISTINCT TRIM(UPPER(CAST(pu_part_number AS STRING))) AS pu_norm
  FROM sandbox.adiazdeleon.harness_mart_warranty_ebom
  WHERE TRIM(UPPER(COALESCE(CAST(pu_part_number AS STRING), ''))) <> ''
),
with_link AS (
  SELECT DISTINCT p.pu_norm
  FROM mart_pns p
  INNER JOIN commercial.reporting_service_npi.rep_npi_jira_mih_tracker d
    ON p.pu_norm = TRIM(UPPER(CAST(d.service_pn AS STRING)))
    OR p.pu_norm = TRIM(UPPER(CAST(d.production_pn AS STRING)))
  WHERE d.drawing_link IS NOT NULL
    AND TRIM(CAST(d.drawing_link AS STRING)) <> ''
),
cnt_mart AS (SELECT COUNT(*) AS n FROM mart_pns),
cnt_link AS (SELECT COUNT(*) AS n FROM with_link)
SELECT
  m.n AS distinct_mart_pu_part_numbers,
  w.n AS distinct_parts_with_any_drawing_link,
  ROUND(100.0 * w.n / NULLIF(m.n, 0), 2) AS pct_mart_parts_with_link
FROM cnt_mart m
CROSS JOIN cnt_link w
