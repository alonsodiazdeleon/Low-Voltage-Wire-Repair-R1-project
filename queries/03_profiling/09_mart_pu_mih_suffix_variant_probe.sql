-- PNs that are **unmatched** on exact `pu_norm` (same rules as **`08`**) with **derived** strings
--   to probe MIH: strip common suffixes and test against the same key set as **`05`**
--   (`service_pn` / `production_pn` / `svc_tracker_production_pn` combined).
-- Output one row per still-unmatched PN: variant strings + which variant **would** hit MIH.
-- Tuning: adjust `regexp_replace` if your part-number grammar differs. No trailing `;` (Genie safe).
-- `docs/OPTIONAL_NPI_DRAWING_LINKS.md`

WITH mart_pns AS (
  SELECT DISTINCT
    CAST(pu_part_number AS STRING) AS pu_raw,
    TRIM(UPPER(CAST(pu_part_number AS STRING))) AS pu_norm
  FROM sandbox.adiazdeleon.harness_mart_warranty_ebom
  WHERE TRIM(UPPER(COALESCE(CAST(pu_part_number AS STRING), ''))) <> ''
),
unmatched AS (
  SELECT p.pu_raw, p.pu_norm
  FROM mart_pns p
  WHERE NOT EXISTS (
    SELECT 1
    FROM commercial.reporting_service_npi.rep_npi_jira_mih_tracker d
    WHERE p.pu_norm = TRIM(UPPER(CAST(d.service_pn AS STRING)))
      OR p.pu_norm = TRIM(UPPER(CAST(d.production_pn AS STRING)))
      OR p.pu_norm = TRIM(UPPER(CAST(d.svc_tracker_production_pn AS STRING)))
  )
),
mih_keys AS (
  SELECT DISTINCT k
  FROM (
    SELECT TRIM(UPPER(CAST(service_pn AS STRING))) AS k
    FROM commercial.reporting_service_npi.rep_npi_jira_mih_tracker
    UNION ALL
    SELECT TRIM(UPPER(CAST(production_pn AS STRING)))
    FROM commercial.reporting_service_npi.rep_npi_jira_mih_tracker
    UNION ALL
    SELECT TRIM(UPPER(CAST(svc_tracker_production_pn AS STRING)))
    FROM commercial.reporting_service_npi.rep_npi_jira_mih_tracker
  ) x
  WHERE k IS NOT NULL
    AND TRIM(CAST(k AS STRING)) <> ''
),
v AS (
  SELECT
    u.pu_raw,
    u.pu_norm,
    regexp_replace(u.pu_norm, '-[A-Z]-[0-9]{3}$', '') AS norm_after_strip_letter_3digit,
    regexp_replace(u.pu_norm, '-[0-9]{3}$', '') AS norm_after_strip_3digit_only,
    regexp_replace(
      regexp_replace(u.pu_norm, '-[A-Z]-[0-9]{3}$', ''),
      '-[0-9]{3}$', ''
    ) AS norm_after_strip_both_revisions,
    regexp_replace(u.pu_norm, '-[A-Z]$', '') AS norm_after_strip_trailing_letter
  FROM unmatched u
)
SELECT
  v.pu_raw,
  v.pu_norm,
  v.norm_after_strip_letter_3digit,
  v.norm_after_strip_3digit_only,
  v.norm_after_strip_both_revisions,
  v.norm_after_strip_trailing_letter,
  m1.k IS NOT NULL AS mih_has_key_equal_strip_letter_3digit,
  m2.k IS NOT NULL AS mih_has_key_equal_strip_3digit_only,
  m3.k IS NOT NULL AS mih_has_key_equal_strip_both,
  m4.k IS NOT NULL AS mih_has_key_equal_strip_trailing_letter
FROM v
LEFT JOIN mih_keys m1 ON v.norm_after_strip_letter_3digit = m1.k
LEFT JOIN mih_keys m2 ON v.norm_after_strip_3digit_only = m2.k
LEFT JOIN mih_keys m3 ON v.norm_after_strip_both_revisions = m3.k
LEFT JOIN mih_keys m4 ON v.norm_after_strip_trailing_letter = m4.k
ORDER BY v.pu_norm
