SELECT 
CAST(DateTime_VL1 AS date) AS VL1_Date,
CAST(DateTime_VL2 AS date) AS VL2_Date,
VL1_SOW, 
VL2_SOW, 
Age_Tier,
Gender, 
CountryName, 
Region,
Channel,
SubChannel,
Platform,
SUM(IsVL1) AS V1,
SUM(IsVL2) AS V2,
IsEV_Success_forFilter,
IsVL3 as IsVL3_forFilter,

SUM(V2toPOASameWeek) AS V2toPOASameWeek,
SUM(Is_POATry) Is_POATry,
SUM(Is_POAApproved) Is_POAApproved,
Is_POATry as Is_POATry_forFilter,
Is_POAApproved as Is_POAApproved_forFilter,

SUM(V2toPOISameWeek) AS V2toPOISameWeek,
SUM(Is_POITry) Is_POITry,
SUM(Is_POIApproved) Is_POIApproved,

SUM(V2toEVSameWeek) AS V2toEVSameWeek,
SUM(IsEV_Try) IsEV_Try,
SUM(IsEV_Success) IsEV_Success_Total, 

SUM(Is_PhoneVerf_Try) AS Is_PhoneVerf_Try,
SUM(Is_PhoneVerf_Success) AS Is_PhoneVerf_Success,
Is_PhoneVerf_Success_forFilter,

SUM(IsScreening_Try) AS  IsScreening_Try,
SUM(IsScreening_Success) AS IsScreening_Success
 
FROM #temp
WHERE IsVL1 = 1 
AND (VL2_SOW >= '2025-08-03' OR VL1_SOW >= '2025-08-03')

GROUP BY 
VL1_SOW, 
VL2_SOW, 
CAST(DateTime_VL1 AS date),
CAST(DateTime_VL2 AS date),
CountryName, 
Channel,
SubChannel,
Platform,
Region,
Age_Tier,
Gender, 
IsEV_Success_forFilter, 
Is_PhoneVerf_Success_forFilter,
IsVL3,
Is_POATry,
Is_POAApproved