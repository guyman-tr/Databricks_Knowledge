SELECT aa.yr, aa.mnt, aa.Region, aa.Clubat_created_date, aa.num_distinct_card_instance_created, bb.num_distinct_card_instance_activated FROM 
(
SELECT 
    COUNT(DISTINCT vmcis.DWH_CardInstanceId) AS num_distinct_card_instance_created,
    MONTH(vmcis.InstanceCreatedDate) AS mnt,
    YEAR(vmcis.InstanceCreatedDate) AS yr,
    CASE 
        WHEN b.AccountSubProgramID IN (1,2,4,8) THEN 'UK'
        WHEN b.AccountSubProgramID IN (5,6,7,9,11,12) THEN 'EU'
        ELSE 'Other'
    END AS Region,
    dpl.Name AS Clubat_created_date
FROM eMoney_dbo.eMoney_Card_Instance_Summary vmcis
JOIN (
    SELECT * 
    FROM eMoney_dbo.eMoney_Dim_Account 
    WHERE IsValidETM = 1 
      AND GCID_Unique_Count = 1
) b
    ON vmcis.CID = b.CID
JOIN (
    SELECT  
        dr.FromDateID, 
        dr.ToDateID, 
        fsc.DateRangeID, 
        fsc.RealCID, 
        fsc.PlayerLevelID
    FROM DWH_dbo.Fact_SnapshotCustomer fsc
    INNER JOIN DWH_dbo.Dim_Range dr
        ON fsc.DateRangeID = dr.DateRangeID
) f 
    ON vmcis.CID = f.RealCID 
   AND vmcis.InstanceCreatedDate 
       BETWEEN CONVERT(date, CAST(f.FromDateID AS char(8))) 
           AND CONVERT(date, CAST(f.ToDateID AS char(8)))
JOIN DWH_dbo.Dim_PlayerLevel dpl 
    ON f.PlayerLevelID = dpl.PlayerLevelID
WHERE vmcis.InstanceCreatedDate IS NOT NULL 
  AND vmcis.InstanceCreatedDate >= '2024-06-01'
GROUP BY 
   CASE 
        WHEN b.AccountSubProgramID IN (1,2,4,8) THEN 'UK'
        WHEN b.AccountSubProgramID IN (5,6,7,9,11,12) THEN 'EU'
        ELSE 'Other'
    END ,
    dpl.Name,  
    MONTH(vmcis.InstanceCreatedDate), 
    YEAR(vmcis.InstanceCreatedDate)
) aa 

JOIN 

(
SELECT 
    COUNT(DISTINCT vmcis.DWH_CardInstanceId) AS num_distinct_card_instance_activated,
    MONTH(vmcis.InstanceActivationDate) AS mnt,
    YEAR(vmcis.InstanceActivationDate) AS yr,
    CASE 
        WHEN b.AccountSubProgramID IN (1,2,4,8) THEN 'UK'
        WHEN b.AccountSubProgramID IN (5,6,7,9,11,12) THEN 'EU'
        ELSE 'Other'
    END AS Region,
    dpl.Name AS Clubat_activated_date
FROM eMoney_dbo.eMoney_Card_Instance_Summary vmcis
JOIN (
    SELECT * 
    FROM eMoney_dbo.eMoney_Dim_Account 
    WHERE IsValidETM = 1 
      AND GCID_Unique_Count = 1
) b
    ON vmcis.CID = b.CID
JOIN (
    SELECT  
        dr.FromDateID, 
        dr.ToDateID, 
        fsc.DateRangeID, 
        fsc.RealCID, 
        fsc.PlayerLevelID
    FROM DWH_dbo.Fact_SnapshotCustomer fsc
    INNER JOIN DWH_dbo.Dim_Range dr
        ON fsc.DateRangeID = dr.DateRangeID
) f 
    ON vmcis.CID = f.RealCID 
   AND vmcis.InstanceActivationDate 
       BETWEEN CONVERT(date, CAST(f.FromDateID AS char(8))) 
           AND CONVERT(date, CAST(f.ToDateID AS char(8)))
JOIN DWH_dbo.Dim_PlayerLevel dpl 
    ON f.PlayerLevelID = dpl.PlayerLevelID
WHERE vmcis.InstanceActivationDate IS NOT NULL 
  AND vmcis.InstanceActivationDate >= '2024-06-01'
GROUP BY 
    CASE 
        WHEN b.AccountSubProgramID IN (1,2,4,8) THEN 'UK'
        WHEN b.AccountSubProgramID IN (5,6,7,9,11,12) THEN 'EU'
        ELSE 'Other'
    END , 
    dpl.Name,  
    MONTH(vmcis.InstanceActivationDate), 
    YEAR(vmcis.InstanceActivationDate)
) bb on aa.mnt=bb.mnt and aa.yr=bb.yr and aa.Region=bb.Region AND aa.Clubat_created_date=bb.Clubat_activated_date