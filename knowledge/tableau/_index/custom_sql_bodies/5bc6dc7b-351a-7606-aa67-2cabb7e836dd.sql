SELECT	COALESCE(a1.DATE, a2.DATE, a3.DATE,t.DATE, Trades.DATE, ftd.DATE, FA.DATE) DATE
		,COALESCE(a1.Region,a2.Region,a3.Region,t.Region, ftd.Region, Trades.Region,FA.Region) Region
		 ,COALESCE(a1.Country,a2.Country,a3.Country,t.Country, Trades.Country, ftd.Country, FA.Country) Country
		 ,COALESCE(a1.Regulation,a2.Regulation,a3.Regulation, t.Regulation, ftd.Regulation, Trades.Regulation,FA.Region) Regulation
		 ,COALESCE(a1.Language, a2.Language, a3.Language,t.Language,ftd.Language, Trades.Language,FA.Language) Language
		 ,COALESCE(a1.Source, a2.Source, a3.Source, t.Source,ftd.Source, Trades.Source,FA.Source) Source 
		 ,a1.V1
		 ,a2.V2
		 ,a3.V3
		 ,ftd.Total_FTD
		 ,ftd.Total_FTD_above100
		 ,t.Registrations
		 ,Trades.OpenTrades
		 ,FA.FirstAction


FROM   						 

--total_FTD_above100
				(
				SELECT		CAST(dc.RegisteredReal AS DATE) DATE
							,dc1.Name Country
							,dc1.Region
							,dr.Name Regulation
						--	,dp.Platform 
							,dl.Name Language
							,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END Source
							,COUNT(*)Registrations
				FROM		DWH..Dim_Customer dc 
							JOIN DWH..Dim_Country dc1 ON dc.CountryID = dc1.CountryID
							JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID 
							JOIN DWH..Dim_Language dl ON dc.LanguageID = dl.LanguageID
				WHERE		dc.AffiliateID = 11
				 AND YEAR(dc.RegisteredReal)>=2022	
				GROUP BY	CAST(dc.RegisteredReal AS DATE)
							,dc1.Name 
							,dc1.Region
							,dr.Name 
							--,dp.Platform 
							,dl.Name
							,CASE WHEN  dc.SubSerialID LIKE '%WS%' 
							THEN 'Organic' 
							WHEN dc.SubSerialID LIKE '%EMAIL%'
							THEN 'Email' 
							ELSE 'Other' 
							END) t 
--FTD
	FULL OUTER JOIN 

					(SELECT		CAST(dc.FirstDepositDate AS DATE) DATE
							,dc1.Name Country
							,dc1.Region
							,dr.Name Regulation
						--	,dp.Platform 
							,dl.Name Language
							,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END Source
							,COUNT(CASE WHEN dc.FirstDepositAmount >= 100  THEN dc.RealCID END) Total_FTD_above100
							,COUNT(dc.FirstDepositDate) Total_FTD
				FROM		DWH..Dim_Customer dc 
							JOIN DWH..Dim_Country dc1 ON dc.CountryID = dc1.CountryID
							JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID 
							JOIN DWH..Dim_Language dl ON dc.LanguageID = dl.LanguageID
				WHERE		dc.AffiliateID = 11
				 AND YEAR(dc.FirstDepositDate)>=2022	
				GROUP BY	CAST(dc.FirstDepositDate AS DATE)
							,dc1.Name 
							,dc1.Region
							,dr.Name 
							--,dp.Platform 
							,dl.Name
							,CASE WHEN  dc.SubSerialID LIKE '%WS%' 
							THEN 'Organic' 
							WHEN dc.SubSerialID LIKE '%EMAIL%'
							THEN 'Email' 
							ELSE 'Other' 
							END
							) AS ftd

							ON t.DATE = ftd.DATE
							AND t.Country = ftd.Country
							AND t.Regulation = ftd.Regulation
							AND t.Language = ftd.Language
							AND t.Source = ftd.Source 
					
--v1		
		FULL OUTER JOIN
				(
				SELECT		CAST(VerificationLevel1Date AS DATE)  DATE
							,a.Country
							,a.Region
							,dr.Name Regulation
							,a.Language
							,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END Source
							,COUNT(VerificationLevel1Date) V1
				FROM		 BI_DB..BI_DB_CIDFirstDates a 
				JOIN         DWH..Dim_Customer dc ON a.CID=dc.RealCID
				JOIN		 DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID
				WHERE		YEAR(VerificationLevel1Date)>=2022
							AND a.SerialID = 11
				GROUP BY	CAST(VerificationLevel1Date AS DATE)
							,a.Country
							,a.Region
							,dr.Name
							,Language
							,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END 
						) a1
							ON t.DATE = a1.DATE
							AND t.Country = a1.Country
							AND t.Regulation = a1.Regulation
							AND t.Language = a1.Language
							AND t.Source = a1.Source 

--v2

		FULL OUTER JOIN ( 
				SELECT CAST(VerificationLevel2Date AS DATE)  DATE
							,a.Country
							,a.Region
							,dr.Name Regulation
							,a.Language
							,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END Source
							,COUNT(VerificationLevel2Date) V2
				FROM		 BI_DB..BI_DB_CIDFirstDates a 
				JOIN         DWH..Dim_Customer dc ON a.CID=dc.RealCID
				JOIN		 DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID
				WHERE		YEAR(VerificationLevel2Date)>=2022
							AND a.SerialID = 11
				GROUP BY	CAST(VerificationLevel2Date AS DATE)
							,a.Country
							,a.Region
							,dr.Name
							,Language
							,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END 
						) AS  a2 
							ON t.DATE = a2.DATE
							AND t.Country = a2.Country
							AND t.Regulation = a2.Regulation
							AND t.Language = a2.Language
							AND t.Source = a2.Source 
--v3
		FULL OUTER JOIN (
				SELECT		CAST(VerificationLevel3Date AS DATE)  DATE
							,a.Country
							,a.Region
							,dr.Name Regulation
							,a.Language
							,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END Source
							,COUNT(VerificationLevel3Date) V3

				FROM		 BI_DB..BI_DB_CIDFirstDates a 
				JOIN         DWH..Dim_Customer dc ON a.CID=dc.RealCID
				JOIN		 DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID
				WHERE		YEAR(VerificationLevel3Date)>=2022
							AND a.SerialID = 11
				GROUP BY	CAST(VerificationLevel3Date AS DATE)
							,a.Country
							,a.Region
							,dr.Name
							,Language
							,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END 
					) AS  a3 
							ON t.DATE  = a3.DATE
							AND t.Country = a3.Country
							AND t.Regulation = a3.Regulation
							AND t.Language = a3.Language
							AND t.Source = a3.Source 
					FULL OUTER JOIN 
-- open trades
					(SELECT CAST(dp.OpenOccurred AS DATE) DATE,
					        dc1.Name Country,
							dc1.Region,
							dr.Name Regulation,
							dl.Name Language,
							CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END Source,
							COUNT(dp.PositionID) OpenTrades
					 FROM DWH..Dim_Position dp
					 JOIN DWH..Dim_Customer dc ON dc.RealCID=dp.CID AND YEAR(dc.RegisteredReal)>=2022 AND dc.AffiliateID=11 AND dc.IsValidCustomer=1
					 JOIN DWH..Dim_Country dc1 ON dc.CountryID = dc1.CountryID
					 JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID
					 JOIN DWH..Dim_Language dl ON dc.LanguageID = dl.LanguageID
					 GROUP BY CAST(dp.OpenOccurred AS DATE) ,
					        dc1.Name ,
							dc1.Region,
							dr.Name ,
							dl.Name ,
							CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								  WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END) Trades
					ON t.DATE=Trades.DATE
					AND t.Country=Trades.Country
					AND t.Regulation=Trades.Regulation
					AND t.Language=Trades.Language
					AND t.Source=Trades.Source
/**--Invites
			FULL OUTER JOIN (
				SELECT  CAST(Occurred AS DATE) date 
						,a.Country
						,a.Region
						,dr.Name Regulation
						,a.Language
						,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END Source
						,COUNT(*) Invites
				FROM	BI_DB..BI_DB_CIDFirstDates a 
						JOIN DWH..Dim_Customer dc ON a.CID=dc.RealCID
						JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID
						JOIN [AZR-W-REAL-DB-2-BIDBUser].[etoro].History.Credit tt  with (NOLOCK) ON dc.RealCID = tt.CID
				WHERE	CompensationReasonID IN (53) 
						AND YEAR(Occurred) >= 2022
						AND dc.AffiliateID = 11
				GROUP BY CAST(Occurred AS DATE) 
						,a.Country
						,a.Region
						,dr.Name
						,Language
						,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
								WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END 
				) AS  I 
				ON 	t.DATE=I.date
					AND t.Country=I.Country
					AND t.Regulation=I.Regulation
					AND t.Language=I.Language
					AND t.Source=I.Source**/
-- First Action 
FULL OUTER JOIN (
					SELECT		CAST(bdfa.FirstActionDate AS DATE) DATE	,dc1.Name Country
								,dc1.Region
								,dr.Name Regulation
								,dl.Name Language
								,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
										WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END Source
								,COUNT(bdfa.FirstAction) FirstAction
					FROM		DWH..Dim_Customer dc 
								JOIN DWH..Dim_Country dc1 ON dc.CountryID = dc1.CountryID
								JOIN DWH..Dim_Regulation dr ON dc.RegulationID = dr.ID 
								JOIN DWH..Dim_Language dl ON dc.LanguageID = dl.LanguageID
								JOIN BI_DB..BI_DB_First5Actions bdfa ON bdfa.CID = dc.RealCID
					WHERE		dc.AffiliateID = 11
								AND YEAR(bdfa.FirstActionDate)>=2022	
				   GROUP BY		CAST(bdfa.FirstActionDate AS DATE) 	
								,dc1.Name 
								,dc1.Region
								,dr.Name 
								,dl.Name 
								,CASE WHEN  dc.SubSerialID LIKE '%WS%'  THEN 'Organic' 
										WHEN dc.SubSerialID LIKE '%EMAIL%' THEN 'Email'  ELSE 'Other'  END 
						) AS FA
					ON 	t.DATE=FA.DATE
						AND t.Country=FA.Country
						AND t.Regulation=FA.Regulation
						AND t.Language=FA.Language
						AND t.Source=FA.Source