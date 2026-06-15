SELECT 
    CAST(dc.RealCID as VARCHAR) AS CID,
    dc.GCID,
    cntr.Name AS Country,
    dc.BannerID,
    CAST(frst.registered AS DATE) AS Reg_Date,
    DATEADD(DAY, 90, CAST(frst.registered AS DATE)) AS Reg_Date_Plus90,
    -- נתונים מהטבלה הזמנית
    tck.FeeMonth,        -- יתעדכן לבד בכל חודש חדש (למשל 202504, 202505...)
    tck.MonthlyFee AS TicketFee

FROM BI_DB_dbo.BI_DB_CIDFirstDates AS frst
JOIN DWH_dbo.Dim_Customer AS dc    ON dc.RealCID = frst.CID 
JOIN DWH_dbo.Dim_Funnel   AS fnn   ON fnn.FunnelID = dc.FunnelID 
JOIN DWH_dbo.Dim_Country  AS cntr  ON frst.CountryID = cntr.CountryID 
-- Join פשוט לטבלה המרכזת
LEFT JOIN #AllTicketFees  AS tck   ON tck.CID = dc.RealCID

WHERE 
    dc.IsDepositor = 1 
    AND dc.RegisteredReal >= '2024-10-01' 
    AND dc.BannerID IN (
        '21810','21812','21811','21813','21647','21814','21815',
        '21809','21795','21817','21818','21816','21820','21819','22302'
    )