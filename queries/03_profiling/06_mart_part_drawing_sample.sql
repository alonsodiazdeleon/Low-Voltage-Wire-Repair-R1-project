-- Sample: up to 40 distinct mart PNs with one drawing row each (prefer latest `revision` when ties).
-- No trailing `;` (Genie safe). If `revision` or `drawing_link` names differ, adjust to match DESCRIBE.
--
-- **Access:** `stg_service_npi__parts_drawing_links` may be **blocked** until gold / UC approval.
--   Re-run this file when access is granted. `docs/OPTIONAL_NPI_DRAWING_LINKS.md`

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
    d.revision,
    d.drawing_link,
    ROW_NUMBER() OVER (
      PARTITION BY p.pu_norm
      ORDER BY d.revision DESC NULLS LAST
    ) AS rn
  FROM mart_pns p
  LEFT JOIN commercial.staging.stg_service_npi__parts_drawing_links d
    ON TRIM(UPPER(CAST(d.part_number AS STRING))) = p.pu_norm
)
SELECT pu_raw, pu_norm, revision, drawing_link
FROM ranked
WHERE rn = 1
LIMIT 40
