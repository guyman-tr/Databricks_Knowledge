--- UNION ALL EVENTS ---
--POA--
SELECT 
       Event,
	   Month_,
       CountryName, 
       COUNT(CASE WHEN BeforeV0 = 1 THEN 1 END) AS 'BeforeV0',
       COUNT(CASE WHEN BetweenV0_V1 = 1 THEN 1 END) AS 'BetweenV0_V1',
       COUNT(CASE WHEN BetweenV1_V2 = 1 THEN 1 END) AS 'BetweenV1_V2',
       COUNT(CASE WHEN BetweenV2_V3 = 1 THEN 1 END) AS 'BetweenV2_V3',
       COUNT(CASE WHEN AfterV3 = 1 THEN 1 END) AS 'AfterV3'
	   FROM #poa 
	   GROUP BY CountryName,Event, Month_

	   UNION ALL 

--POI--
 SELECT 
       Event,
	   Month_,
       CountryName, 
       COUNT(CASE WHEN BeforeV0 = 1 THEN 1 END) AS 'BeforeV0',
       COUNT(CASE WHEN BetweenV0_V1 = 1 THEN 1 END) AS 'BetweenV0_V1',
       COUNT(CASE WHEN BetweenV1_V2 = 1 THEN 1 END) AS 'BetweenV1_V2',
       COUNT(CASE WHEN BetweenV2_V3 = 1 THEN 1 END) AS 'BetweenV2_V3',
       COUNT(CASE WHEN AfterV3 = 1 THEN 1 END) AS 'AfterV3'
	   FROM #poi 
	   GROUP BY CountryName,Event, Month_

	   UNION ALL 

--EV--
 SELECT 
       Event,
	   Month_,
       CountryName, 
       COUNT(CASE WHEN BeforeV0 = 1 THEN 1 END) AS 'BeforeV0',
       COUNT(CASE WHEN BetweenV0_V1 = 1 THEN 1 END) AS 'BetweenV0_V1',
       COUNT(CASE WHEN BetweenV1_V2 = 1 THEN 1 END) AS 'BetweenV1_V2',
       COUNT(CASE WHEN BetweenV2_V3 = 1 THEN 1 END) AS 'BetweenV2_V3',
       COUNT(CASE WHEN AfterV3 = 1 THEN 1 END) AS 'AfterV3'
	   FROM #ev 
	   GROUP BY CountryName,Event, Month_

	  UNION ALL 

--SCREENING--
 SELECT 
       Event,
	   Month_,
       CountryName, 
       COUNT(CASE WHEN BeforeV0 = 1 THEN 1 END) AS 'BeforeV0',
       COUNT(CASE WHEN BetweenV0_V1 = 1 THEN 1 END) AS 'BetweenV0_V1',
       COUNT(CASE WHEN BetweenV1_V2 = 1 THEN 1 END) AS 'BetweenV1_V2',
       COUNT(CASE WHEN BetweenV2_V3 = 1 THEN 1 END) AS 'BetweenV2_V3',
       COUNT(CASE WHEN AfterV3 = 1 THEN 1 END) AS 'AfterV3'
	   FROM #scrn
	   GROUP BY CountryName,Event, Month_