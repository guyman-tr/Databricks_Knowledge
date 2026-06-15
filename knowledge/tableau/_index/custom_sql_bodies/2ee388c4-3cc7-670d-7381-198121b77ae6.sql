SELECT
    CASE WHEN dd.Date IS NULL THEN cd.Date ELSE dd.Date END AS Date,
    CASE WHEN dd.FundingType IS NULL THEN cd.FundingType ELSE dd.FundingType END AS FundingType,
    CASE WHEN dd.Country IS NULL THEN cd.Country ELSE dd.Country END AS Country,
    CASE WHEN dd.Region IS NULL THEN cd.Region ELSE dd.Region END AS Region,
    CASE WHEN dd.Flow IS NULL THEN cd.Flow ELSE dd.Flow END AS Flow,
        CASE WHEN dd.Type IS NULL THEN cd.Type ELSE dd.Type END AS Type,
    COALESCE(dd.NoOfDeposits, 0) AS NoOfDeposits,
    COALESCE(dd.TotalDepositAmountUSD, 0) AS TotalDepositAmountUSD,
    COALESCE(cd.NoOfWithdraws, 0) AS NoOfWithdraws,
    COALESCE(cd.TotalWithdrawAmountUSD, 0) AS TotalWithdrawAmountUSD
FROM (
    -- Subquery for deposits
    SELECT
        CAST(bd.ModificationDate AS DATE) AS Date,
        ft.Name AS FundingType,
        c.Name as Country,
        c.MarketingRegionManualName as Region,
        COUNT(DISTINCT bd.DepositID) AS NoOfDeposits,
        SUM(bd.Amount * bd.ExchangeRate) AS TotalDepositAmountUSD,
        case when bd.DepositTypeID=4 then 'Internal Transfer' else 'Other' end as Type,
        '' as Flow
        
    FROM 
        main.general.bronze_etoro_dwh_billingdeposithourly bd
    JOIN 
        main.billing.bronze_etoro_billing_funding_datafactory bf ON bf.FundingID = bd.FundingID
    JOIN 
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft ON ft.FundingTypeID = bf.FundingTypeID
    JOIN
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = bd.CID
    JOIN 
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c on c.CountryID = dc.CountryID
    WHERE 
        bd.ModificationDate >= DATEADD(DAY, -15, CURRENT_DATE())
        AND bd.PaymentStatusID = 2 -- approved
    GROUP BY 
        CAST(bd.ModificationDate AS DATE),
        ft.Name,
        c.Name,
        c.MarketingRegionManualName,case when bd.DepositTypeID=4 then 'Internal Transfer' else 'Other' end 
) dd
FULL OUTER JOIN (
    -- Subquery for cashouts
    SELECT
        CAST(WTF.ModificationDate AS DATE) AS Date,
        ft.Name AS FundingType,
        c.Name as Country,
        c.MarketingRegionManualName as Region,
        COUNT(DISTINCT WTF.ID) AS NoOfWithdraws,
        SUM(WTF.Amount) AS TotalWithdrawAmountUSD,
        case when bd.WithdrawTypeID=0 THEN 'Default' 
when bd.WithdrawTypeID=1 then 'Transfer' 
when bd.WithdrawTypeID=2 then 'ApprovedForClosure' else 'NULL' END AS Type,
case when bd.FlowID=1 THEN 'Open Trade Execution' 
when bd.FlowID=2 then 'Close Trade Execution' 
when bd.FlowID=3 then 'Internal Transfer' else 'NULL' END AS Flow

    FROM 
        main.billing.bronze_etoro_billing_vwithdrawtofunding WTF 
    JOIN 
        main.billing.bronze_etoro_billing_funding_datafactory bf ON bf.FundingID = WTF.FundingID
    JOIN 
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft ON ft.FundingTypeID = bf.FundingTypeID
    JOIN
        main.billing.bronze_etoro_billing_withdraw bd on bd.WithdrawID = WTF.WithdrawID
    JOIN
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = bd.CID
    JOIN 
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c on c.CountryID = dc.CountryID
    WHERE 
        WTF.CashoutStatusID = 3 
        AND WTF.ModificationDate >= DATEADD(DAY, -15, CURRENT_DATE())
    GROUP BY 
        CAST(WTF.ModificationDate AS DATE),
        ft.Name,
        c.Name,
        c.MarketingRegionManualName,
         case when bd.WithdrawTypeID=0 THEN 'Default' 
when bd.WithdrawTypeID=1 then 'Transfer' 
when bd.WithdrawTypeID=2 then 'ApprovedForClosure' else 'NULL' END,
case when bd.FlowID=1 THEN 'Open Trade Execution' 
when bd.FlowID=2 then 'Close Trade Execution' 
when bd.FlowID=3 then 'Internal Transfer' else 'NULL' END 
) cd ON 
    dd.Date = cd.Date
    AND dd.FundingType = cd.FundingType
    AND dd.Country = cd.Country
    AND dd.Region = cd.Region
    AND dd.Flow = cd.Flow
    AND dd.Type = cd.Type
ORDER BY 
    CASE WHEN dd.Date IS NULL THEN cd.Date ELSE dd.Date END,
    CASE WHEN dd.FundingType IS NULL THEN cd.FundingType ELSE dd.FundingType END