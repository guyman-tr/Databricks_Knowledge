select t.* 
,t.EOM_LSD AS LSD
,CASE WHEN t.EOM_Club IN ('LowBronze','HighBronze') THEN 'Bronze' ELSE t.EOM_Club END AS EOM_Club_New
,LAG(t.IsEOM_Funded_NEW,1) OVER (PARTITION BY t.CID ORDER BY ActiveDate) AS Lag_IsEOM_Funded_NEW
,bdcd.FirstNewFundedDate
,ISNULL(bdcd.Gender,'M') Gender
,dc1.MarketingRegionManualName
,dc1.Name AS CountryName
,ln.Name AS Language
,nm.CFD_Status AS Negative_Market_Status_Curr,
       CAST(CASE WHEN nm.CFD_Status = 'CFD_Blocked' THEN 'Yes' ELSE 'No' END AS CHAR) AS IsCFDBlocked_Curr,
       CASE 
           WHEN nm.CFD_Status = 'CFD_Allowed' AND ISNULL(nm.BlockDate, '1900-01-01') > '1900-01-01' THEN 'CFD_Allowed_were_Blocked' 
           ELSE nm.CFD_Status 
       END AS Negative_Market_Status_Include_H,
       CAST(CASE 
           WHEN (nm.CFD_Status = 'CFD_Allowed' AND ISNULL(nm.BlockDate, '1900-01-01') > '1900-01-01') OR nm.CFD_Status = 'CFD_Blocked' THEN 'Blocked' 
           ELSE 'NotBlocked' 
       END AS CHAR) AS IsCFDBlocked_Include_H

,CASE  
             WHEN bdcd.Channel LIKE '%Affiliate%' THEN 'Affiliate'
		     WHEN bdcd.Channel LIKE '%Direct%' THEN 'Direct'
			 WHEN bdcd.Channel LIKE '%Friend Referral%' THEN 'Friend Referral'
			 WHEN bdcd.Channel LIKE '%Media Performance%' THEN 'Media Performance'
		     WHEN bdcd.Channel LIKE '%Media Programmatic%' THEN 'Media Programmatic'
			 WHEN bdcd.Channel LIKE '%Mobile Acquisition%' THEN 'Mobile Acquisition'
			 WHEN bdcd.Channel LIKE '%SEM%' THEN 'SEM'
			 WHEN bdcd.Channel LIKE '%SEO%' THEN 'SEO'
		ELSE 'Other' END AS Channel_Group,

      CASE
	   WHEN t.Seniority = 0 THEN 'ThisMonth'
	   WHEN t.Seniority = 1 THEN '1_Month'
       WHEN t.Seniority = 2 THEN '2_Months'
       WHEN t.Seniority = 3 THEN '3_Months'
       WHEN t.Seniority = 4 THEN '4_Months'
       WHEN t.Seniority = 5 THEN '5_Months'
       WHEN t.Seniority = 6 THEN '6_Months'
       WHEN t.Seniority = 7 THEN '7_Months'
       WHEN t.Seniority = 8 THEN '8_Months'
       WHEN t.Seniority = 9 THEN '9_Months'
       WHEN t.Seniority = 10 THEN '10_Months'
	   WHEN t.Seniority = 11 THEN '11_Months'
	    WHEN t.Seniority >= 12 AND t.Seniority <= 23 THEN '1-2Years'
        WHEN t.Seniority >= 24 AND t.Seniority <= 35 THEN '2-3Years'
        WHEN t.Seniority >= 36 AND t.Seniority <= 47 THEN '3-4Years'
        WHEN t.Seniority >= 48 AND t.Seniority <= 59 THEN '4-5Years'
	    WHEN t.Seniority >= 60 AND t.Seniority <= 71 THEN '6-7Years'
        WHEN t.Seniority >= 72 AND t.Seniority <= 83 THEN '7-8Years'
	    WHEN t.Seniority >= 84 AND t.Seniority <= 95 THEN '8-9Years'
		WHEN t.Seniority >= 96 THEN '9+Years'
        ELSE CAST(t.Seniority AS VARCHAR) END AS Seniority_Seg2 ,

CAST(YEAR(t.FTDdate) AS VARCHAR) AS FTDYear,
CASE WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) <= 24 THEN '18-24'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 25 AND 34 THEN '25-34'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 35 AND 44 THEN '35-44'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) BETWEEN 45 AND 54 THEN '45-54'  
                  WHEN FLOOR(DATEDIFF(DAY, bdcd.BirthDate, GETDATE()) / 365.25) >= 55 THEN '55+'  
                  ELSE NULL END AS Age_Group,
opt.ConsentStatusID as OptedIn,
codata.CO_Cluster

from BI_DB_dbo.[BI_DB_CID_MonthlyPanel_FullData] t with (nolock)
JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd with(nolock)ON t.CID = bdcd.CID 
JOIN DWH_dbo.Dim_Customer dc with (nolock)ON dc.RealCID= t.CID
JOIN DWH_dbo.Dim_Country dc1 with (nolock)ON dc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_Language ln with (nolock)ON dc.LanguageID= ln.LanguageID
LEFT JOIN  BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market nm ON nm.RealCID = dc.RealCID
LEFT JOIN #fakeftd AS f ON t.CID = f.CID
LEFT JOIN #optin as opt on t.CID = opt.CID
LEFT JOIN #codata2 as codata on t.CID = codata.CID
                           AND t.ActiveDate = codata.SOM_COcluster
						   

WHERE ActiveDate >= CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -13,GETDATE())), 0) AS DATE)
and ActiveDate <= CAST(Dateadd(Month,Datediff(Month, 0, DATEADD(m, -1,GETDATE())), 0) AS DATE)
AND dc.IsDepositor=1
and f.CID IS NULL