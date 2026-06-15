SELECT 
    aeo.FullDate,
	aeo.Region,
    bdcsm.ETF_HoldEOM,
    bdcsm.Smart_Portfolios_HoldEOM,
    bdcsm.[Copy_Trader_HoldEOM],
    bdcsm.CFD_ActiveOpen3M,
    bdcsm.Real_Crypto,
    bdcsm.Real_Non_US_Stocks,
    bdcsm.Real_US_Stocks,
    bdcsm.eMoney_ActiveOpen3M,
    bdcsm.Total_Products,
    aeo.[High_Bronze+]
FROM (
    SELECT 
        DateID,
        FullDate,
		Region,
        COUNT(vl.CID) AS [High_Bronze+]
    FROM (
        SELECT 
            vl.DateID,
            vl.FullDate,
            vl.CID,
			dc2.MarketingRegionManualName AS Region
        FROM DWH_dbo.V_Liabilities vl WITH (NOLOCK)
        JOIN (
            SELECT 
                DateKey
            FROM DWH_dbo.Dim_Date dd WITH (NOLOCK)
            WHERE 
                (IsLastDayOfMonth = 'Y' AND dd.CalendarYear >= 2024
                 AND dd.DateKey <= CAST(CONVERT(VARCHAR, EOMONTH(DATEADD(DAY, -1, GETDATE()), -1), 112) AS INT))
                OR dd.DateKey = CAST(FORMAT(GETDATE() - 1, 'yyyyMMdd') AS INT)
        ) eo ON vl.DateID = eo.DateKey
        INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
            ON vl.CID = fsc.RealCID
        INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
            ON fsc.DateRangeID = dr.DateRangeID
            AND  eo.DateKey BETWEEN dr.FromDateID AND dr.ToDateID
			INNER JOIN DWH_dbo.Dim_Country dc2 WITH (NOLOCK)
           ON fsc.CountryID = dc2.CountryID
        WHERE 
            fsc.IsValidCustomer = 1
            AND fsc.IsDepositor = 1
            AND (ISNULL(vl.ActualNWA, 0) + ISNULL(vl.Liabilities, 0)) >= 1000
    ) vl
    GROUP BY DateID, FullDate,Region
) aeo
JOIN (
    SELECT 
        FullDate,
        DateKey,
		Region,
        SUM(ETF_HoldEOM) AS ETF_HoldEOM,
        SUM(Smart_Portfolios_HoldEOM) AS Smart_Portfolios_HoldEOM,
        SUM([Copy_Trader_HoldEOM]) AS [Copy_Trader_HoldEOM],
        SUM(CFD_ActiveOpen3M) AS CFD_ActiveOpen3M,
        SUM(Real_Crypto) AS Real_Crypto,
        SUM(Real_Non_US_Stocks) AS Real_Non_US_Stocks,
        SUM(Real_US_Stocks) AS Real_US_Stocks,
        SUM(eMoney_ActiveOpen3M) AS eMoney_ActiveOpen3M,
        SUM(Total_Products) AS Total_Products
    FROM BI_DB_dbo.BI_DB_Cross_Selling_Monthly bdcsm
    WHERE 
        Total_Products > 0
        AND [High_Bronze+] = 1
        AND DateKey >= 20240131
    GROUP BY FullDate, DateKey,Region

    UNION

    SELECT 
        FullDate,
        DateKey,
		Region,
        SUM(bdcsd.ETF_Hold) AS ETF_HoldEOM,
        SUM(bdcsd.Smart_Portfolios_Hold) AS Smart_Portfolios_HoldEOM,
        SUM([Copy_Trader_Hold]) AS [Copy_Trader_HoldEOM],
        SUM(CFD_ActiveOpen3M) AS CFD_ActiveOpen3M,
        SUM(Real_Crypto) AS Real_Crypto,
        SUM(Real_Non_US_Stocks) AS Real_Non_US_Stocks,
        SUM(Real_US_Stocks) AS Real_US_Stocks,
        SUM(eMoney_ActiveOpen3M) AS eMoney_ActiveOpen3M,
        SUM(Total_Products) AS Total_Products
    FROM BI_DB_dbo.BI_DB_Cross_Selling_Daily bdcsd
    WHERE 
        bdcsd.DateKey = CAST(FORMAT(GETDATE() - 1, 'yyyyMMdd') AS INT)
        AND [High_Bronze+] = 1
    GROUP BY FullDate, DateKey,Region
) bdcsm
ON aeo.DateID = bdcsm.DateKey  AND aeo.Region = bdcsm.Region