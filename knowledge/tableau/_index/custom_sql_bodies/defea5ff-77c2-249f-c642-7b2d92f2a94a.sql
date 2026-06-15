SELECT 
    t1.BalanceDate, 
    t2.TxCreatedDate, 
    t1.Total_C_Wallet_Balance_Per_Date, 
    t2.num_C2F_Tx 
FROM (
    SELECT 
        a.BalanceDate, 
        SUM(a.BalanceUSD) AS Total_C_Wallet_Balance_Per_Date  
    FROM [EXW_dbo].[EXW_FinanceReportsBalancesNew] a
    INNER JOIN (
        SELECT 
            mdt.CID
        FROM eMoney_dbo.eMoney_Dim_Transaction mdt
        WHERE 
            mdt.TxStatusModificationDateID >= 20250301 
            AND mdt.TxTypeID = 14
        GROUP BY mdt.CID
    ) c ON a.RealCID = c.CID
    WHERE 
        a.BalanceDate >= GETDATE() - 60
        AND a.IsTestAccount = 0
        AND a.ComplianceClosureEvent = 0
        AND a.AMLClosureEvent = 0
    GROUP BY a.BalanceDate
) t1  
JOIN (
    SELECT 
        mdt.TxCreatedDate, 
        COUNT(*) AS num_C2F_Tx 
    FROM eMoney_dbo.eMoney_Dim_Transaction mdt
    JOIN eMoney_dbo.eMoney_Dim_Account mda ON mdt.CID = mda.CID
    WHERE 
        mdt.TxTypeID = 14 
        AND mdt.IsTxSettled = 1 
        AND mdt.TxCreatedDate >= GETDATE() - 60 
        AND mda.IsValidETM = 1 
        AND mda.GCID_Unique_Count = 1 
    GROUP BY mdt.TxCreatedDate
) t2 ON t1.BalanceDate = t2.TxCreatedDate