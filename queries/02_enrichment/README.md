# Enrichment queries (Phase 1+)

| File | Purpose |
|------|--------|
| **`01_base_with_flat_view_parts.sql`** | Same harness filter as `01_canonical_ingress` + **`pu_part_*`** (and `sr_pri_fail_part_*`) from **`vs_rpt_flat_view`**. Optional commented block: all part lines for those SRs. **No** `fct_sos_detailed_service_rpt` (restricted; not needed for MVP). |
| **`02_lve_ebom_connector_to_harness_map.sql`** | Full **`dim_fct_catia_ebom_parts`** with `child_pn_resolved` (no LVE/R1 filter — all releasing orgs). **Large** `SELECT *` — use a view or add limits in your workspace. Filter by system/program when **joining** to warranty. |

**Roadmap (new files as you go):**

1. **`02_lve_ebom_connector_to_harness_map.sql`** (connector → harness from EBOM/SBOM) — in repo; tune filters after first run.
2. **Serviceable views** — when service PN path differs from engineering EBOM.
3. **`stg_service_npi__parts_drawing_links`** — PDF link by `part_number` for heat-map / PD handoff.
4. **Warranty + map** — one saved query or view: `01_base_with_flat_view_parts` LEFT JOIN map on `pu_part_number`.
