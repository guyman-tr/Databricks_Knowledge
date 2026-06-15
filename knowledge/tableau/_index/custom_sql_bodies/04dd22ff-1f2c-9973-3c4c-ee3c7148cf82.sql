SELECT 
    a.CID,
    a.GCID,
    a.KYC_Country,
    a.PlayerStatus,
    a.PlayerStatusReason,
    a.PlayerStatusSubReasonName,
    a.Previous_PlayerStatus,
    a.Previous_PlayerStatus_Reason,
    a.Previous_PlayerStatus_Sub_Reason,
    a.W8BEN_SignedDate,
    a.W8BEN_ExpiryDate,
    a.Ind_Done,
    a.Club,
    MAX(a.Has_Open_Position) AS Has_Open_Position,
    a.RealizedEquity,
	a.[Group]
FROM (
    SELECT 
        dc.RealCID AS CID,
        dc.GCID,
        dc1.Name AS KYC_Country,
        dpl.Name AS Club,
        dps.Name AS PlayerStatus,
        dpsr.Name AS PlayerStatusReason,
        dpssr.PlayerStatusSubReasonName,
        bdapsc.Previous_PlayerStatus,
        bdapsc.Previous_PlayerStatus_Reason,
        bdapsc.Previous_PlayerStatus_Sub_Reason,
        bdwus.SignedDate AS W8BEN_SignedDate,
        bdwus.ExpiryDate AS W8BEN_ExpiryDate,		
        bdtg.Ind_Done,
		bdwus.[Group],
        ISNULL(vl.RealizedEquity, 0) AS RealizedEquity,
        CASE WHEN bdppl.CID IS NOT NULL THEN 1 ELSE 0 END AS Has_Open_Position,
        ROW_NUMBER() OVER (
            PARTITION BY bdapsc.CID 
            ORDER BY bdapsc.Change_Date DESC
        ) AS RN
    FROM DWH_dbo.Dim_Customer dc
    JOIN DWH_dbo.Dim_Country dc1 
        ON dc.CountryID = dc1.DWHCountryID
    JOIN DWH_dbo.Dim_PlayerStatus dps 
        ON dc.PlayerStatusID = dps.PlayerStatusID 
        AND dps.PlayerStatusID = 15 -- Block Deposit & Trading
    JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr 
        ON dc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID 
        AND dpsr.PlayerStatusReasonID = 41 -- Tax
    JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr 
        ON dc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID 
        AND dpssr.PlayerStatusSubReasonID = 76 -- W-8BEN
    JOIN DWH_dbo.Dim_PlayerLevel dpl 
        ON dc.PlayerLevelID = dpl.PlayerLevelID
    LEFT JOIN BI_DB_dbo.BI_DB_PositionPnL bdppl 
        ON dc.RealCID = bdppl.CID 
        AND bdppl.DateID = CAST(CONVERT(CHAR(8), GETDATE() - 1, 112) AS INT)
    LEFT JOIN BI_DB_dbo.BI_DB_W8_Users_Status bdwus 
        ON bdwus.CID = dc.RealCID
    LEFT JOIN BI_DB_dbo.BI_DB_TIN_Gap bdtg 
        ON dc.RealCID = bdtg.CID
    LEFT JOIN BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes bdapsc 
        ON dc.RealCID = bdapsc.CID
    LEFT JOIN DWH_dbo.V_Liabilities vl 
        ON vl.CID = dc.RealCID 
        AND vl.DateID = CAST(CONVERT(CHAR(8), GETDATE() - 1, 112) AS INT)
    WHERE dc.IsValidCustomer = 1
) a
WHERE a.RN = 1
GROUP BY 
    a.CID,
    a.GCID,
    a.KYC_Country,
    a.PlayerStatus,
    a.PlayerStatusReason,
    a.PlayerStatusSubReasonName,
    a.Previous_PlayerStatus,
    a.Previous_PlayerStatus_Reason,
    a.Previous_PlayerStatus_Sub_Reason,
    a.W8BEN_SignedDate,
    a.W8BEN_ExpiryDate,
    a.Ind_Done,
    a.RealizedEquity,
    a.Club,
	a.[Group]