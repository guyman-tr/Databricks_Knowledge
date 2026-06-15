SELECT
    COALESCE(mi.EOM_Action,   mo.EOM_Action)            AS EOM_Action,
    COALESCE(mi.Country,      mo.Country)               AS Country,
    COALESCE(mi.FundingType,  mo.FundingType)           AS FundingType,
    COALESCE(mi.UpdateDate,   mo.UpdateDate)            AS UpdateDate,
    COALESCE(mi.AccountSubProgram, mo.AccountSubProgram) AS AccountSubProgram,
    ISNULL(dc.EU, 0)                                     AS EU,
    ISNULL(mi.AmountUSD_Deposit,  0)                    AS AmountUSD_Deposit,
    ISNULL(mo.AmountUSD_Withdraw, 0)                    AS AmountUSD_Withdraw,
    ISNULL(mi.Total_Deposit,      0)                    AS Total_Deposit,
    ISNULL(mo.Total_Withdraw,     0)                    AS Total_Withdraw
FROM
(
    SELECT
        EOMONTH(a1.ModificationDate)              AS EOM_Action,
        mdcr.CountryName                     AS Country,
        CAST(a1.ModificationDate AS date)          AS UpdateDate,
        a1.FundingType                     AS FundingType,
        SUM(ISNULL(a1.[Amount in $], 0))         AS AmountUSD_Deposit,
        SUM(CASE WHEN ISNULL(a1.DepositID,0) > 0 THEN 1 ELSE 0 END) AS Total_Deposit,
        da.AccountSubProgram
    FROM BI_DB_dbo.BI_DB_AllDeposits a1
    INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout mdcr
        ON a1.[Country (customer)] = mdcr.CountryName
    LEFT JOIN eMoney_dbo.eMoney_Dim_Account da
        ON da.CID = a1.CID
    WHERE a1.PaymentStatus = 'Approved'
	and a1.ModificationDate>=DATEFROMPARTS(YEAR(DATEADD(MONTH, -6, GETDATE())),
                                      MONTH(DATEADD(MONTH, -6, GETDATE())),
                                      1)
    GROUP BY
        EOMONTH(a1.ModificationDate),
        mdcr.CountryName,
        CAST(a1.ModificationDate AS date),
        a1.FundingType,
        da.AccountSubProgram
) AS mi
FULL OUTER JOIN
(
    SELECT
        EOMONTH(a1.RequestDate)              AS EOM_Action,
        a1.Country                           AS Country,
        CAST(a1.UpdateDate AS date)          AS UpdateDate,
        dft.Name                             AS FundingType,
        SUM(ISNULL(a1.[Amount$Withdraw], 0)) AS AmountUSD_Withdraw,
        SUM(CASE WHEN ISNULL(a1.WithdrawID,0) > 0 THEN 1 ELSE 0 END) AS Total_Withdraw,
        da.AccountSubProgram
    FROM BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard a1
    INNER JOIN DWH_dbo.Dim_FundingType dft
        ON a1.FundingTypeID = dft.FundingTypeID
    INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout mdcr
        ON a1.Country = mdcr.CountryName
    LEFT JOIN eMoney_dbo.eMoney_Dim_Account da
        ON da.CID = a1.CID
    WHERE a1.CashoutStatusID_Funding = 3  -- Processed
    GROUP BY
        EOMONTH(a1.RequestDate),
        a1.Country,
        CAST(a1.UpdateDate AS date),
        dft.Name,
        da.AccountSubProgram
) AS mo
    ON  mi.EOM_Action        = mo.EOM_Action
    AND mi.Country           = mo.Country
    AND mi.FundingType       = mo.FundingType
    AND mi.UpdateDate        = mo.UpdateDate
    AND ISNULL(mi.AccountSubProgram,'') = ISNULL(mo.AccountSubProgram,'')
LEFT JOIN DWH_dbo.Dim_Country dc
    ON dc.[Name] = COALESCE(mi.Country, mo.Country)