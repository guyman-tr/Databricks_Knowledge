SELECT 
    CAST(MAX(mdt.UpdateDate) AS DATE) AS MaxUpdateDate
FROM 
    eMoney_dbo.eMoney_Dim_Transaction mdt