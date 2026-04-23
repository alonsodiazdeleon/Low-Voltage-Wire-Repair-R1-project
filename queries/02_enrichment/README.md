# Enrichment queries (Phase 1+)

| File | Purpose |
|------|--------|
| **`01_base_with_flat_view_parts.sql`** | Same harness filter as `01_canonical_ingress` + **`pu_part_*`** (and `sr_pri_fail_part_*`) from **`vs_rpt_flat_view`**. Optional commented block: all part lines for those SRs. **No** `fct_sos_detailed_service_rpt` (restricted; not needed for MVP). |
| **`02_lve_ebom_connector_to_harness_map.sql`** | Full **`dim_fct_catia_ebom_parts`** with `child_pn_resolved` (no LVE/R1 filter — all releasing orgs). **Large** `SELECT *` — use a view or add limits in your workspace. Filter by system/program when **joining** to warranty. |
| **`03_warranty_ebom_join.sql`** | **`warranty_cohort` LEFT JOIN `ebom_base`** on `pu_part_number` = `child_pn_resolved` / `part_number` / `parent_part_number`. Adds `ebom_*` columns and **`ebom_match_type`**. For heavy jobs, use **`04_mart_ctas_warranty_ebom.sql`**. |
| **`04_mart_ctas_warranty_ebom.sql`** | **CTAS:** `sandbox.adiazdeleon` — `harness_ebom_dim_fct_catia_resolved` + `harness_warranty_780095014_cohort` + **`harness_mart_warranty_ebom`** (run A/B then C). |
| **`04c_post_c_notebook_check.sql`** | After C: `SELECT` that **returns a grid** (row counts + optional sample) — for notebooks; CTAS has no preview. |
| **`04d_mart_quality_summary.sql`** | One-row **mart QA**: distinct SRs / PNs, `ebom_match_type` counts, % matched, unmatched with non-blank `pu_part_number`. |

**Roadmap (new files as you go):**

1. **`02_lve_ebom_connector_to_harness_map.sql`** (connector → harness from EBOM/SBOM) — in repo; tune filters after first run.
2. **Serviceable views** — when service PN path differs from engineering EBOM.
3. **`stg_service_npi__parts_drawing_links`** — PDF link by `part_number` for heat-map / PD handoff.
4. **Warranty + map** — one saved query or view: `01_base_with_flat_view_parts` LEFT JOIN map on `pu_part_number`.
5. **Next baby step (implemented):** run **`04d_mart_quality_summary.sql`** after each mart refresh to track match mix before free-text / drawing work.
6. **Profiling + drawings:** **`../03_profiling/README.md`** — mart-cohort Q2/Q3/Q4 + NPI drawing coverage (Genie-safe).
