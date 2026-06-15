SELECT fm.CID
     ,fm.AccountManager
	 ,kycp.CountryName
	 ,fm.EOM_Club
	 ,fm.EOM_Regulation CurrentRegulation
	 ,oa.Regulation PreviousRegulation
	 ,oa.RegulationChangeDate
	 ,fm.EOM_Equity Equity
	 ,fm.ACC_Revenue_Total Revenue
	 ,fm.ACC_TotalDeposits TotalDeposits
FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
LEFT JOIN [BI_DB].[dbo].[BI_DB_KYC_Panel] kycp WITH (NOLOCK)
ON fm.CID = kycp.RealCID
OUTER APPLY
(
SELECT TOP 1 RealCID
            ,dr.Name Regulation
			,dd.FullDate RegulationChangeDate
FROM [DWH].[dbo].[Fact_SnapshotCustomer] fsc WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Range] dr1 WITH (NOLOCK)
ON fsc.DateRangeID = dr1.DateRangeID
INNER JOIN DWH.dbo.Dim_Regulation dr WITH (NOLOCK)
ON fsc.RegulationID = dr.ID
INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
ON dr1.ToDateID = dd.DateKey
WHERE fsc.RealCID = fm.CID
AND fsc.RegulationID !=9
AND dr1.ToDateID >=20210401
ORDER BY dr1.DateRangeID desc
) oa
WHERE fm.ActiveDate = DATEFROMPARTS(YEAR(getdate()-1),MONTH(getdate()-1),1)
AND fm.EOM_Regulation = 'FSA Seychelles'