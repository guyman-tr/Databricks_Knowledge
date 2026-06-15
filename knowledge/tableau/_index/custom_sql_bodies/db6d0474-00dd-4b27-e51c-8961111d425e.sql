SELECT *,
case when 
    TaskIDEscalated in ('Yes') and 
    Outcome in ('Escalation to CY')
then SLA 
    when TaskIDEscalated in ('Yes') and 
    Outcome not in ('Escalation to CY') 
then SLA_Escalation
else SLA end as FinalSLA
 FROM BI_DB_dbo.[BI_DB_AssignmentToolSLAs]