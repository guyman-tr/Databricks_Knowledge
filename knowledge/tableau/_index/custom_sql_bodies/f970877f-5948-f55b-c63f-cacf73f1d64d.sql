SELECT 

concat(case 
	when c.AccountTypeID = 2 then 1 
	when c.AccountTypeID = 15 then 1 
	else 2
	end
	,';'
	,z.TIN_Value
	,';'
	,
c.FirstName collate SQL_Latin1_General_CP1253_CI_AI, ' '
,c.LastName collate SQL_Latin1_General_CP1253_CI_AI
,
';') as 'column'
,case 
	when c.AccountTypeID = 2 then 1 
	when c.AccountTypeID = 15 then 1 
	else 2
	end as 'val'
,c.RealCID
,z.TIN_Value
,concat(
c.FirstName collate SQL_Latin1_General_CP1253_CI_AI, ' '
,c.LastName collate SQL_Latin1_General_CP1253_CI_AI
) as 'name'
,c.RegulationID
,c.VerificationLevelID
,c.RegisteredReal
,d.VerificationLevel2Date
,concat(left(z.TIN_Value,5),c.LastName) as '5SSNLastName'

--into #US
  from [DWH].[dbo].[Dim_Customer] c 

  left join [BI_DB].[dbo].[BI_DB_CIDFirstDates] d 
  on d.CID = c.RealCID



  left join [BI_DB].[dbo].[BI_DB_Tax_Compliance_TIN] z 
  on c.GCID = z.GCID
  and z.FieldID = 6

  where 
  c.CountryID = 219 
  --and len(z.TIN_Value) = 9 --only take 9 digit values
  --and len(concat(c.FirstName collate SQL_Latin1_General_CP1253_CI_AI, ' '
--,c.LastName collate SQL_Latin1_General_CP1253_CI_AI
--)) <= 40
 and c.VerificationLevelID >= 2 --level 2 or higher
 and d.VerificationLevel2Date >= '2021-01-01'