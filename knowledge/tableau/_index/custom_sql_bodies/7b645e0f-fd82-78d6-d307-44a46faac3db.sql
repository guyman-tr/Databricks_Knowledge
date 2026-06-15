select 
CID,
Active_Month, 
RegMonth, 
ActiveDate,
Seniority, 
FTD_Month, 
FTDdate, 
Country, 
Channel, 
EOM_Club, 
ACC_Revenue_Total,
CASE WHEN Channel = 'Friend Referral' THEN 1 ELSE 0 END Is_RAF,
case when Channel != 'Friend Referral' THEN 1 ELSE 0 END Is_Not_RAF,
CASE WHEN CountryID in (74,191,13,79,197,100,57,143,196,219,218,102,162,183,202,226,55,164,12) THEN 1 ELSE 0 END Is_RAF_Countries
from dbo.BI_DB_CID_MonthlyPanel_FullData
WHERE FTD_Month>=202301 AND Active_Month>=202301
AND ActiveDate <= DATEADD(month, -1, GETDATE())