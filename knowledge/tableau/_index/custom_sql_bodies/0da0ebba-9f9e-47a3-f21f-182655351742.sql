SELECT a.*,
case when 
    a.TaskIDEscalated in ('Yes') and 
    a.Outcome in ('Escalation to CY')
then SLA 
    when a.TaskIDEscalated in ('Yes') and 
    a.Outcome not in ('Escalation to CY') 
then SLA_Escalation
else SLA end as FinalSLA,
c.VerificationLevelID
 FROM BI_DB_dbo.[BI_DB_AssignmentToolSLAs] a
 left join 
	DWH_dbo.Dim_Customer c on c.RealCID = a.CID