-- One row: how mart `pu_part_number` values relate to MIH `drawing_link` — not only “any link”
--   (see **`05`**) but **no tracker row**, **tracker but blank `drawing_link`**, and links that
--   **look like Google Drive / Docs** (common when engineering hosts PDFs on Drive).
-- `rep_npi_jira_mih_tracker` join on `service_pn` / `production_pn` / `svc_tracker_production_pn` (see **`05`** / **`06`**).
-- **has_tracker_row** = any joined row on those keys (uses `d.id` so a match via the third key counts).
-- No trailing `;` (Genie safe). `docs/OPTIONAL_NPI_DRAWING_LINKS.md`

WITH mart_pns AS (
  SELECT DISTINCT TRIM(UPPER(CAST(pu_part_number AS STRING))) AS pu_norm
  FROM sandbox.adiazdeleon.harness_mart_warranty_ebom
  WHERE TRIM(UPPER(COALESCE(CAST(pu_part_number AS STRING), ''))) <> ''
),
per_part AS (
  SELECT
    m.pu_norm,
    MAX(
      CASE
        WHEN d.id IS NOT NULL THEN 1
        ELSE 0
      END
    ) AS has_tracker_row,
    MAX(
      CASE
        WHEN d.drawing_link IS NOT NULL
          AND TRIM(CAST(d.drawing_link AS STRING)) <> ''
        THEN 1
        ELSE 0
      END
    ) AS has_nonempty_drawing_link,
    MAX(
      CASE
        WHEN d.drawing_link IS NOT NULL
          AND (
            LOWER(TRIM(CAST(d.drawing_link AS STRING))) LIKE '%drive.google%'
            OR LOWER(TRIM(CAST(d.drawing_link AS STRING))) LIKE '%docs.google%'
          )
        THEN 1
        ELSE 0
      END
    ) AS has_google_hosted_link
  FROM mart_pns m
  LEFT JOIN commercial.reporting_service_npi.rep_npi_jira_mih_tracker d
    ON m.pu_norm = TRIM(UPPER(CAST(d.service_pn AS STRING)))
    OR m.pu_norm = TRIM(UPPER(CAST(d.production_pn AS STRING)))
    OR m.pu_norm = TRIM(UPPER(CAST(d.svc_tracker_production_pn AS STRING)))
  GROUP BY m.pu_norm
)
SELECT
  COUNT(*) AS distinct_mart_pu_part_numbers,
  SUM(CASE WHEN has_tracker_row = 0 THEN 1 ELSE 0 END) AS pns_no_mih_row,
  SUM(
    CASE WHEN has_tracker_row = 1 AND has_nonempty_drawing_link = 0 THEN 1 ELSE 0 END
  ) AS pns_mih_matched_but_link_blank,
  SUM(has_nonempty_drawing_link) AS pns_with_any_nonblank_link,
  SUM(has_google_hosted_link) AS pns_with_link_containing_google_drive_or_docs
FROM per_part
