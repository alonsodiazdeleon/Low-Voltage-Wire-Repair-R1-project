-- Canonical ingress: dashboard-aligned harness warranty base.
-- Run in Databricks SQL. Add pilot filter: AND v_veh_program LIKE 'R1%' when ready.
--
-- Mapping focus (free text → EBOM/SBOM): connector_number (Q2), circuit (Q3), reapair_location (Q4).
--
-- Qualifiers: match existing claims / dashboard SQL — mostly unqualified; `s.` only where needed
-- (e.g. `sr_completed_date` in WHERE). Output column name `tier3` (not `s.tier3`) per source.

with tt as (
select distinct
  service_request_id,
  tier3,
  max(case when qa_q = '1. Which wiring harness repair(s) did you perform?' then qa_a[0] end) as `repair_type`,
  max(case when qa_q = '2. Which connector numbers were worked on?' then qa_a[0] end) as `connector_number`,
  max(case when qa_q = '3. Which circuit numbers were worked on?' then qa_a[0] end) as `circuit`,
  max(case when qa_q = '4. Where is the location of the repair in relation to the vehicle body?' then qa_a[0] end) as `reapair_location`,
  max(case when qa_q = '5. Upload image of the defect found BEFORE repairs are performed.' then has_image_keys end) as `image_before_repair`,
  max(case when qa_q = '5. Upload image of the defect found AFTER repairs are performed.' then has_image_keys end) as `image_after_repair`


FROM main.vehicle_services.vs_event_schema_flattened
where 1=1
and (tier1 = 'Wiring Harness Repair' or tier3 = 'Wiring Harness Repair')
group by service_request_id, tier3
)


select distinct 
v_vin
,v_vehicle_model
,v_veh_program
,days_to_sr
,wo_workorder_id
,sr_service_request_number
,sr_service_request_id
,sr_created_date
,sr_completed_date
,mapped_endpoint
,sr_concern
,sr_technician_notes
,sr_internal_technician_notes
,tier3
,repair_type
,connector_number
,circuit
,reapair_location
,image_before_repair
,image_after_repair
,vehicle_breakdown_grouping
,sr_pri_fail_labor_sys
,sr_pri_fail_labor_subsys
,case when vehicle_breakdown_grouping = 'Tow VBR' then true else false end as is_tow
,case when days_to_sr <=90 then true else false end as is_3MIS
from main.vehicle_services.vs_rpt_flat_view s
left join tt on s.sr_service_request_id =tt.service_request_id
where 1=1
and is_field_performance_metric_included =1 
and cr_labor_code ='780095014'
and s.sr_completed_date >= '2026-01-01'
  -- and v_vehicle_model like 'R1%' --> Pilot R1: 
  --  and v_veh_program like 'R1%' --> Alt pilot 'launch', 'mca', 'Peregrine'
