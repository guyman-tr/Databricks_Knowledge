SELECT bdad.ModificationDateID
	  ,bdad.[Country (customer)] Country
	  ,bdad.Region region
	  ,bdad.FundingType
	  ,SUM(bdad.[Amount in $]) TotalAmount
FROM BI_DB..BI_DB_AllDeposits bdad
WHERE bdad.ModificationDateID>=CAST(CONVERT(VARCHAR(8),GETDATE()-7,112)AS int)
AND bdad.PaymentStatus = 'Approved'
AND bdad.[Country (customer)]  IN ('Taiwan',
                                  'Malaysia',
                                  'Philippines',
                                  'Singapore',
                                  'Vietnam',
                                  'Thailand',
                                  'Indonesia',
                                  'South Korea')
GROUP BY bdad.ModificationDateID
	  ,bdad.[Country (customer)] 
	  ,bdad.Region 
	  ,bdad.FundingType