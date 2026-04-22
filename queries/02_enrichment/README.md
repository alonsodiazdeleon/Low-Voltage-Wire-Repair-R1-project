# Enrichment queries (Phase 1+)

| File | Purpose |
|------|--------|
| **`01_base_with_flat_view_parts.sql`** | Same harness filter as `01_canonical_ingress` + **`pu_part_*`** (and `sr_pri_fail_part_*`) from **`vs_rpt_flat_view`**. Optional commented block: all part lines for those SRs. **No** `fct_sos_detailed_service_rpt` (restricted; not needed for MVP). |

**Roadmap (new files as you go):**

1. **`dim_sbom_parts`** — filter consumed part numbers to harness / connector / LVE / model.
2. **`dim_fct_catia_ebom_parts`** — parent harness ↔ child connector.
3. **Serviceable views** — when service PN path differs from engineering EBOM.
4. **`stg_service_npi__parts_drawing_links`** — PDF link by `part_number` for heat-map / PD handoff.
