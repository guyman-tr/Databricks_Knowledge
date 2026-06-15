SELECT ch.CreatedDate as Routed_Date,ch.CaseId,c.CaseNumber,c.NumberOfTouches,c.Status,ch.NewValue as NewOwner,ch.OldValue as OldOwner,c.ClubLevel
 FROM crm.silver_crm_casehistory ch
left join bi_output.bi_output_customer_customer_support_case c on c.CaseID=ch.CaseId
where NewValue IN ('AML/OPS','APU Check Ups','FCMU - EDD project escalations','Risk eToro Money')
and CAST(ch.CreatedDate AS DATE) >='2025-01-01'