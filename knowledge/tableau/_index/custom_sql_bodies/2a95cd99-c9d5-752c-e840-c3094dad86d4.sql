SELECT	CAST(registered AS DATE) [Date]
		,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END RAF_Source
		,fd.NewMarketingRegion Region
        ,sum(case when Channel = 'Friend Referral' then 1 else 0 end) as Registrations
        ,count(distinct fd.ReferralID) as Refferers
        ,NULL as FTD
        ,NULL as Activations
        ,'Registration' AS Date_Type
FROM BI_DB..BI_DB_CIDFirstDates fd
join DWH.dbo.Dim_Customer dc
	on fd.CID = dc.RealCID
where registered >= DATEADD(MONTH,-6,GETDATE())
and fd.Channel = 'Friend Referral'
group by 
	CAST(registered AS DATE), 
	CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other' END,
	fd.NewMarketingRegion
UNION ALL
SELECT	CAST(fd.FirstNewFundedDate AS DATE) [Date]
		,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END RAF_Source
		,fd.NewMarketingRegion Region
        ,NULL as RAF_Registrations
        ,NULL as Refferers
        ,NULL as FTD
        ,SUM(case when Channel = 'Friend Referral' AND fd.FirstNewFundedDate IS NOT NULL then 1 else 0 END) Activations
        ,'Activation' AS Date_Type
FROM BI_DB..BI_DB_CIDFirstDates fd
join DWH.dbo.Dim_Customer dc
	on fd.CID = dc.RealCID
where fd.FirstNewFundedDate >= DATEADD(MONTH,-6,GETDATE())
and fd.Channel = 'Friend Referral'
group by 
	CAST(fd.FirstNewFundedDate AS DATE),
	CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other' END,
	fd.NewMarketingRegion
UNION ALL
SELECT	CAST(fd.FirstDepositDate AS DATE) [Date]
		,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END RAF_Source
		,fd.NewMarketingRegion Region
        ,NULL as RAF_Registrations
        ,NULL as Refferers
        ,SUM(case when Channel = 'Friend Referral' AND fd.FirstDepositDate IS NOT NULL then 1 else 0 END) as FTD
        ,NULL as Activations
        ,'FTD' AS Date_Type
FROM BI_DB..BI_DB_CIDFirstDates fd
join DWH.dbo.Dim_Customer dc
	on fd.CID = dc.RealCID
where fd.FirstDepositDate >= DATEADD(MONTH,-6,GETDATE())
and fd.Channel = 'Friend Referral'
group by 
	CAST(fd.FirstDepositDate AS DATE),
	CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other' END,
	fd.NewMarketingRegion