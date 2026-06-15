SELECT 
    mimo.RealCID,

    -- Trading Deposits
    SUM(CASE 
            WHEN mimo.MIMOPlatform = 'TradingPlatform'
                 AND mimo.MIMOAction = 'Deposit'
                 AND mimo.FundingTypeID <> 33
            THEN mimo.AmountUSD 
            ELSE 0 
        END) AS Trading_Deposits_USD,

    -- Trading Withdrawals
    SUM(CASE 
            WHEN mimo.MIMOPlatform = 'TradingPlatform'
                 AND mimo.MIMOAction = 'Withdraw'
                 AND mimo.FundingTypeID <> 33
            THEN mimo.AmountUSD 
            ELSE 0 
        END) AS Trading_Withdrawals_USD,

    -- eMoney Inbound (external only)
    SUM(CASE 
            WHEN mimo.MIMOPlatform = 'eMoney'
                 AND mimo.MIMOAction = 'Deposit'
                 AND mimo.IsInternalTransfer = 0
            THEN mimo.AmountUSD 
            ELSE 0 
        END) AS eMoney_Inbound_USD,

    -- eMoney Outbound (external only)
    SUM(CASE 
            WHEN mimo.MIMOPlatform = 'eMoney'
                 AND mimo.MIMOAction = 'Withdraw'
                 AND mimo.IsInternalTransfer = 0
            THEN mimo.AmountUSD 
            ELSE 0 
        END) AS eMoney_Outbound_USD,

    -- Net Deposits
    (
        SUM(CASE 
                WHEN mimo.MIMOPlatform = 'TradingPlatform'
                     AND mimo.MIMOAction = 'Deposit'
                     AND mimo.FundingTypeID <> 33
                THEN mimo.AmountUSD ELSE 0 END)
      - SUM(CASE 
                WHEN mimo.MIMOPlatform = 'TradingPlatform'
                     AND mimo.MIMOAction = 'Withdraw'
                     AND mimo.FundingTypeID <> 33
                THEN mimo.AmountUSD ELSE 0 END)
      + SUM(CASE 
                WHEN mimo.MIMOPlatform = 'eMoney'
                     AND mimo.MIMOAction = 'Deposit'
                     AND mimo.IsInternalTransfer = 0
                THEN mimo.AmountUSD ELSE 0 END)
      - SUM(CASE 
                WHEN mimo.MIMOPlatform = 'eMoney'
                     AND mimo.MIMOAction = 'Withdraw'
                     AND mimo.IsInternalTransfer = 0
                THEN mimo.AmountUSD ELSE 0 END)
    ) AS Net_Deposits_USD

FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms mimo
Where 
 mimo.RealCID IN (
    SELECT DISTINCT CID FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New
    UNION
    SELECT DISTINCT CID FROM BI_DB_dbo.BI_DB_RiskAlertManagementTool
    WHERE CategoryName = 'AML'
)


GROUP BY mimo.RealCID