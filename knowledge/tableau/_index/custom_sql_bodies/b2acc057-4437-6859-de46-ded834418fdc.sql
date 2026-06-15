SELECT 
CID,
CAST(DateTime_VL2 AS date) AS VL2_Date,
CAST(DateTime_VL3 AS date) AS VL3_Date, 
DepositDate,
VL2_SOW, 
VL3_SOW,
FirstPayment_SOW,
Age_Tier,
Gender, 
CountryName, 
MarketingRegion, 
Channel,
SubChannel,
SUM(IsVL2) AS V2,
SUM(IsVL3) AS V3,
IsEV_Success_forFilter,
IsVL3 as IsVL3_forFilter,
Is_PhoneVerf_Success as Is_PhoneVerf_Success_forFilter,

SUM(V2toPOASameWeek) AS V2toPOASameWeek,
SUM(Is_POATry) Is_POATry,
SUM(Is_POAApproved) Is_POAApproved,

SUM(V2toPOISameWeek) AS V2toPOISameWeek,
SUM(Is_POITry) Is_POITry,
SUM(Is_POIApproved) Is_POIApproved,

SUM(V2toEVSameWeek) AS V2toEVSameWeek,
SUM(IsEV_Try) IsEV_Try,
SUM(IsEV_Success) IsEV_Success_Total, 

SUM(Is_PhoneVerf_Try) AS Is_PhoneVerf_Try,
SUM(Is_PhoneVerf_Success) AS Is_PhoneVerf_Success,

SUM(IsScreening_Try) AS  IsScreening_Try,
SUM(IsScreening_Success) AS IsScreening_Success,
 

SUM(IsTryDeposit) AS  IsTryDeposit,
SUM(Approved) AS  Approved,
SUM(Declined) AS  Declined,

SUM(V2toDepositTrySameWeek) AS V2toDepositTrySameWeek,
SUM(Approved_V2toDepositTrySameWeek) AS Approved_V2toDepositTrySameWeek,
SUM(Declined_V2toDepositTrySameWeek) AS Declined_V2toDepositTrySameWeek,

SUM(V3toDepositTrySameWeek) AS V3toDepositTrySameWeek,
SUM(Approved_V3toDepositTrySameWeek) AS Approved_V3toDepositTrySameWeek,
SUM(Declined_V3toDepositTrySameWeek) AS Declined_V3toDepositTrySameWeek,

FundingType,
CarTypeName,
Currency

FROM #temp
WHERE IsVL2 = 1 
AND (VL2_SOW >= '2025-05-04')

GROUP BY 
CID,
CAST(DateTime_VL2 AS date),
CAST(DateTime_VL3 AS date),
VL2_SOW, 
VL3_SOW,
Age_Tier,
Gender, 
CountryName, 
MarketingRegion, 
Channel,
SubChannel,
IsEV_Success_forFilter, 
IsVL3,
DepositDate,
FirstPayment_SOW,
FundingType,
CarTypeName,
Currency,
Is_PhoneVerf_Success