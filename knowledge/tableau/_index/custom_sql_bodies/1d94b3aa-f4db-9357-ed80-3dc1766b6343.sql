SELECT n.*
      ,c.Parameter
	  ,c.ParameterDescription
	  ,c.ParameterWeight
	  ,CASE WHEN n.Risk_Final_Result <= 30 THEN 'Low_Final_Score' ELSE 'High_Final_Score'  END AS Final_Score_Classification
	  ,CASE WHEN n.P_Risk='Low' THEN 1 
	        WHEN n.P_Risk='Medium' THEN 2
			WHEN n.P_Risk='High' THEN 3
			ELSE 0 END AS P_Risk_Value
FROM (
SELECT j.*
     ,SUBSTRING(j.P_number, PATINDEX('%[0-9]%',j.P_number), 
        CASE 
            WHEN PATINDEX('%[0-9]%',j.P_number + 'X') > 0 
            THEN LEN(j.P_number) - PATINDEX('%[0-9]%', REVERSE(j.P_number))
            ELSE 1 
        END
    ) AS ParameterID
FROM (
SELECT UnPivoted.CID
      ,UnPivoted.P_number
	  ,UnPivoted.P_Risk
	  ,CASE WHEN b.eTM_AccountID IS NOT NULL THEN 'eTM' ELSE 'Not eTM' END AS Is_eTM
	  ,b.Regulation
	  ,b.CountryCitizenship
	  ,b.CountryPOB
	  ,b.CountryAddress
	  ,b.CountryAddress_IsHRC
	  ,b.CountryCitizenship_IsHRC
	  ,b.CountryPOB_IsHRC
	  ,b.Risk_Final_Result
	  ,CASE WHEN dc.PlayerStatusID=13 THEN 0
	         WHEN dc.PlayerStatusID=1 THEN 1
			 WHEN dc.PlayerStatusID IN (3,5,12) THEN 2
			 WHEN dc.PlayerStatusID IN (10,11) THEN 2
			 WHEN dc.PlayerStatusID IN (9,15) THEN 2
			 WHEN dc.PlayerStatusID IN (2,4,6,7,8,14) THEN 3
	    ELSE 'Error' END AS Player_Status_Score
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment
UNPIVOT
(
   P_Risk FOR P_number IN (
   P1_Risk,
   P2_Risk,
   P3_Risk,
   P4_Risk,
   P5_Risk,
   P6_Risk,
   P7_Risk,
   P8_Risk,
   P9_Risk,
   P10_Risk,
   P11_Risk,
   P12_Risk,
   P13_Risk,
   P14_Risk,
   P15_Risk,
   P16_Risk,
   P17_Risk,
   P18_Risk,
   P19_Risk,
   P20_Risk,
   P21_Risk,
   P22_Risk,
   P23_Risk,
   P24_Risk,
   P25_Risk,
   P26_Risk,
   P27_Risk,
   P28_Risk,
   P29_Risk,
   P30_Risk,
   P31_Risk,
   P32_Risk
)
) AS UnPivoted
INNER JOIN eMoney_dbo.eMoney_Customer_Risk_Assessment b ON b.CID=UnPivoted.CID
INNER JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=UnPivoted.CID
INNER JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID) j)n
LEFT JOIN (SELECT DISTINCT rsk.ParameterID
	           ,rsk.Parameter
	           ,rsk.ParameterDescription
	           ,rsk.ParameterWeight
FROM( 
SELECT CAST([parameter_id] AS INT) AS 'ParameterID'
      ,CAST([parameter] AS VARCHAR(30)) AS 'Parameter'
      ,CAST([parameter_description] AS VARCHAR(255)) AS 'ParameterDescription'
	  ,CAST([parameter_weight] AS FLOAT) AS 'ParameterWeight'
FROM [eMoney_dbo].[emoney_customer_risk_assessment_classification_table]) rsk) c ON c.ParameterID=n.ParameterID