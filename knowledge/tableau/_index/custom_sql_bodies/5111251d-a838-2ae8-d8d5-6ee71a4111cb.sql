SELECT s.*,
case when 
    TaskIDEscalated in ('Yes') and 
    Outcome in ('Escalation to CY')
then SLA 
    when TaskIDEscalated in ('Yes') and 
    Outcome not in ('Escalation to CY') 
then SLA_Escalation
else SLA end as FinalSLA,
dr.Name as Regulation
 FROM BI_DB.dbo.[BI_DB_AssignmentToolSLAs] s
join DWH.dbo.Dim_Customer c on c.RealCID=s.CID
join DWH.dbo.Dim_Regulation dr on dr.ID=c.RegulationID