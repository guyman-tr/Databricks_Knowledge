SELECT
COUNT(CF.CID) AS #OFCLIENTS,
CAST(CF.registered as date) as RegDate,
sum(case when CF.VerificationLevel3Date IS NOT NULL THEN 1 ELSE 0 END) AS Verified,
sum(case when CF.VerificationLevel2Date IS NOT NULL THEN 1 ELSE 0 END) AS VerLevel2,
SUM(case when CF.FirstDepositDate IS NULL or YEAR(CF.FirstDepositDate) = 1900 THEN 0 ELSE 1 END) AS FTDs,
sum(case when CF.FirstPosOpenDate IS NOT NULL THEN 1 ELSE 0 END ) AS FirstAction,
SUM(CASE
    -- Condition 1: Cashout occurred before Level 3 (Both dates NOT NULL and Cashout < Level 3)
    WHEN CF.FirstCashoutDate IS NOT NULL 
         AND CF.VerificationLevel3Date IS NOT NULL
         AND CF.FirstCashoutDate < CF.VerificationLevel3Date
    THEN 1
    
    -- Condition 2: Cashout occurred, but Level 3 is NULL (Cashout NOT NULL and Level 3 IS NULL)
    WHEN CF.FirstCashoutDate IS NOT NULL 
         AND CF.VerificationLevel3Date IS NULL
    THEN 1
    
    -- Otherwise, don't count it (e.g., both NULL, or cashout was after Level 3)
    ELSE 0
END) AS CO_Before,
CF.Country ,
dr.Name as Regulation,
dr1.Name as DesignatedRegulation
from BI_DB_dbo.BI_DB_CIDFirstDates CF
join DWH_dbo.Dim_Regulation dr on dr.ID=CF.RegulationID
join DWH_dbo.Dim_Regulation dr1 on dr1.ID=CF.DesignatedRegulationID
WHERE year(CF.registered)>=2025
group by
CF.Country,dr.Name,dr1.Name,CAST(CF.registered as date)