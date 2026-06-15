USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dictionaries_Country_DL_To_Synapse(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

-- =============================================
-- Author:      <Boris Slutski>
-- Create Date: <2021-09-13>
-- Description: SP intended to transfer data from DataLake to synapse
-- =============================================
-----

TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Country

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Country
           (CountryID
		,DWHCountryID
		,Abbreviation
		,LongAbbreviation
		,Name
        ,MarketingRegionID
		,Region
		,IsHighRiskCountry
		,UpdateDate
		,InsertDate
		,StatusID
,RiskGroupID
,IsEligibleForRAFBonusCountry)
SELECT x.CountryID
		,x.CountryID AS DWHCountryID
		,x.Abbreviation
		,x.LongAbbreviation
		,x.Name
        ,y.MarketingRegionID
		,y.Name AS Region
		,case when x.RiskGroupID in (0, 4) then 0 else 1 end as IsHighRiskCountry
		,current_timestamp() AS UpdateDate
		,current_timestamp() AS InsertDate
		,1 AS StatusID
, x.RiskGroupID
, cast(x.IsEligibleForRAFBonusCountry as int) as IsEligibleForRAFBonusCountry
FROM  dwh_daily_process.daily_snapshot.etoro_Dictionary_Country x 
	JOIN 
dwh_daily_process.daily_snapshot.etoro_Dictionary_MarketingRegion y
	  ON x.MarketingRegionID=y.MarketingRegionID
;
  MERGE INTO dwh_daily_process.migration_tables.Dim_Country A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Country a
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Country b on a.CountryID = b.CountryID
)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
EU = b.EU ,
IsEuropeanCountry = b.IsEuropeanCountry ,
MarketingRegionManualName = b.MarketingRegionManualName;
  MERGE INTO dwh_daily_process.migration_tables.Dim_Country A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Country a
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Country_Region_Desk b on a.MarketingRegionID = b.RegionID
)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
CFKey = b.CFKey ,
Desk = b.Desk;
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Country_Regulation

;
INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Country_Regulation
          (`CountryID`
          ,`RegulationID`)
SELECT `CountryID`
    ,`RegulationID`
FROM dwh_daily_process.daily_snapshot.ComplianceStateDB_Compliance_RegulationCountry
;
   MERGE INTO dwh_daily_process.migration_tables.Dim_Country A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_Country a
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Country_Regulation b on a.CountryID = b.CountryID ------------------------

)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
RegulationID = b.RegulationID;
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CountryIPAnonymous

;
INSERT INTO dwh_daily_process.migration_tables.Dim_CountryIPAnonymous
           (`IPFrom`
           ,`IPTo`
           ,`ProxyType`
           ,`CountryCode`
           ,`CountryName`
           ,`UpdateDate`)
SELECT `ip_from`
      ,`ip_to`
      ,`proxy_type`
      ,COALESCE(`country_code`, 'NA') --Namibia
      ,`country_name`
	  ,current_timestamp() as UpdateDate
  FROM dwh_daily_process.daily_snapshot.IP2Location


;
MERGE INTO dwh_daily_process.migration_tables.Dim_CountryIPAnonymous A_TGT USING (
SELECT * 
from dwh_daily_process.migration_tables.Dim_CountryIPAnonymous a
INNER JOIN dwh_daily_process.migration_tables.Dim_Country b on b.`Abbreviation` = a.`CountryCode`
)
ON 1 = 1
WHEN MATCHED THEN UPDATE SET
`CountryID` = b.`CountryID`;
END;
