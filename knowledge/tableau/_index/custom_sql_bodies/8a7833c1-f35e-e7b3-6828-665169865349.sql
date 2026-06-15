SELECT 
	DISTINCT WithdrawID,
	bw.WithdrawPaymentID AS WithdrawProcessingID,
	CAST(bw.RequestDate AS DATE) AS RequestDate,
	CAST(bw.ModificationDate AS DATE) AS ModificationDate,
	bw.CID, 
	bw.[Amount_Withdraw] AS [CO Amount],
	wirecountry.Name AS CountryMOP,
	dr.Name AS Regulation,
	dc1.Name AS ClientCountry,
	MAX(CASE WHEN dtdt.DocumentID IS NOT NULL THEN 'Yes' ELSE 'NO' END) AS 'W8'

FROM [DWH_dbo].[Fact_BillingWithdraw] bw
left join [DWH_dbo].[Dim_Country] wirecountry on wirecountry.CountryID=bw.CountryIDAsInteger
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=bw.CID
JOIN DWH_dbo.Dim_Country dc1 ON dc1.CountryID=dc.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation dr ON dr.ID=dc.RegulationID
LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocument CD ON CD.CID=bw.CID
LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType dtdt on dtdt.DocumentID=CD.DocumentID and dtdt.DocumentTypeID=12	--W-8BEN Form
WHERE 
CAST(bw.ModificationDate AS DATE)>=CAST(GETDATE()-30 AS DATE)
AND bw.CashoutStatusID_Withdraw =3
AND bw.FundingTypeID_Funding=2 --WireTransfer
AND bw.CountryIDAsInteger=219 --United States
AND bw.SwiftCodeAsString NOT IN ('CMFGUS33',
'TRWIBEB1',
'TRNWUS31',
'CMFGUS33'
)
GROUP BY 
WithdrawID,
	bw.WithdrawPaymentID ,
	CAST(bw.RequestDate AS DATE) ,
	CAST(bw.ModificationDate AS DATE),
	bw.CID, 
	bw.[Amount_Withdraw],
	wirecountry.Name ,
	dr.Name,
	dc1.Name