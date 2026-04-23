-- NPI drawing link coverage for distinct **mart** `pu_part_number` values (non-blank only).
-- Join: normalized PN ↔ `commercial.staging.stg_service_npi__parts_drawing_links.part_number`.
-- One result row. No trailing `;` (Genie safe). Confirm column names with DESCRIBE on the links table.
--
-- **Access:** `stg_service_npi__parts_drawing_links` is **restricted** / not gold in some orgs. If you
--   get a policy or governance block, skip until authorized — logic stays valid; swap FQN if DE
--   promotes a gold table. See: `docs/OPTIONAL_NPI_DRAWING_LINKS.md`.

WITH mart_pns AS (
  SELECT DISTINCT TRIM(UPPER(CAST(pu_part_number AS STRING))) AS pu_norm
  FROM sandbox.adiazdeleon.harness_mart_warranty_ebom
  WHERE TRIM(UPPER(COALESCE(CAST(pu_part_number AS STRING), ''))) <> ''
),
with_link AS (
  SELECT DISTINCT p.pu_norm
  FROM mart_pns p
  INNER JOIN commercial.staging.stg_service_npi__parts_drawing_links d
    ON TRIM(UPPER(CAST(d.part_number AS STRING))) = p.pu_norm
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
