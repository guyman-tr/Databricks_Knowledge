SELECT	CAST(registered AS DATE) [Date],
         CID AS InviteeID, 
		 dc.UserName InviteeUserName
		,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END RAF_Source
		,fd.NewMarketingRegion Region
        ,case when Channel = 'Friend Referral' then 1 else 0 end as Registrations
        ,fd.ReferralID as ReferralID,
		dc1.UserName RefferersUserName,
		dc1.FirstName ReffererFirstName,
		dc1.LastName ReffererLastName,
		CASE WHEN dc1.GuruStatusID >0 AND dc1.GuruStatusID <=6 THEN 1 else 0 END IsPI,
		dg.GuruStatusName
        ,CASE WHEN fd.FirstDepositDate IS NOT NULL THEN 1 ELSE 0 end as FTD
        ,CASE WHEN FirstNewFundedDate IS NOT NULL THEN 1 ELSE 0 end as Activations
FROM BI_DB..BI_DB_CIDFirstDates fd
join DWH.dbo.Dim_Customer dc
	on fd.CID = dc.RealCID
LEFT JOIN DWH.dbo.Dim_Customer dc1
	on dc1.RealCID = fd.ReferralID
JOIN	DWH.dbo.Dim_GuruStatus dg
    ON dc1.GuruStatusID=dg.GuruStatusID
where registered >= DATEADD(MONTH,-6,GETDATE())
and fd.Channel = 'Friend Referral'