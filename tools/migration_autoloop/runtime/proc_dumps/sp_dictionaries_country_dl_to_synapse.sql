BEGIN

-- =============================================
-- Author:      <Boris Slutski>
-- Create Date: <2021-09-13>
-- Description: SP intended to transfer data from DataLake to synapse
-- Fixed: 2026-06-11 - Replaced MERGE ON 1=1 with proper join keys (Delta Lake compatibility)
-- =============================================

TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_Country;

INSERT INTO dwh_daily_process.migration_tables.Dim_Country
           (CountryID, DWHCountryID, Abbreviation, LongAbbreviation, Name,
            MarketingRegionID, Region, IsHighRiskCountry, UpdateDate, InsertDate,
            StatusID, RiskGroupID, IsEligibleForRAFBonusCountry)
SELECT x.CountryID, x.CountryID AS DWHCountryID, x.Abbreviation, x.LongAbbreviation, x.Name,
       y.MarketingRegionID, y.Name AS Region,
       CASE WHEN x.RiskGroupID IN (0, 4) THEN 0 ELSE 1 END AS IsHighRiskCountry,
       current_timestamp() AS UpdateDate, current_timestamp() AS InsertDate,
       1 AS StatusID, x.RiskGroupID,
       CAST(x.IsEligibleForRAFBonusCountry AS INT) AS IsEligibleForRAFBonusCountry
FROM dwh_daily_process.daily_snapshot.etoro_Dictionary_Country x
JOIN dwh_daily_process.daily_snapshot.etoro_Dictionary_MarketingRegion y
  ON x.MarketingRegionID = y.MarketingRegionID;

-- UPDATE #1: EU flags from Ext_Dim_Country
MERGE INTO dwh_daily_process.migration_tables.Dim_Country A_TGT
USING dwh_daily_process.migration_tables.Ext_Dim_Country b
ON A_TGT.CountryID = b.CountryID
WHEN MATCHED THEN UPDATE SET
  EU = b.EU,
  IsEuropeanCountry = b.IsEuropeanCountry,
  MarketingRegionManualName = b.MarketingRegionManualName;

-- UPDATE #2: CFKey/Desk from Ext_Dim_Country_Region_Desk
MERGE INTO dwh_daily_process.migration_tables.Dim_Country A_TGT
USING dwh_daily_process.migration_tables.Ext_Dim_Country_Region_Desk b
ON A_TGT.MarketingRegionID = b.RegionID
WHEN MATCHED THEN UPDATE SET
  CFKey = b.CFKey,
  Desk = b.Desk;

-- Regulation
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Country_Regulation;

INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Country_Regulation (CountryID, RegulationID)
SELECT CountryID, RegulationID
FROM dwh_daily_process.daily_snapshot.ComplianceStateDB_Compliance_RegulationCountry;

-- UPDATE #3: RegulationID
MERGE INTO dwh_daily_process.migration_tables.Dim_Country A_TGT
USING dwh_daily_process.migration_tables.Ext_Dim_Country_Regulation b
ON A_TGT.CountryID = b.CountryID
WHEN MATCHED THEN UPDATE SET
  RegulationID = b.RegulationID;

-- IP Anonymous
TRUNCATE TABLE dwh_daily_process.migration_tables.Dim_CountryIPAnonymous;

INSERT INTO dwh_daily_process.migration_tables.Dim_CountryIPAnonymous
  (IPFrom, IPTo, ProxyType, CountryCode, CountryName, UpdateDate)
SELECT ip_from, ip_to, proxy_type, COALESCE(country_code, 'NA'), country_name,
       current_timestamp() AS UpdateDate
FROM dwh_daily_process.daily_snapshot.IP2Location;

-- UPDATE #4: CountryID from Dim_Country
MERGE INTO dwh_daily_process.migration_tables.Dim_CountryIPAnonymous A_TGT
USING dwh_daily_process.migration_tables.Dim_Country b
ON A_TGT.CountryCode = b.Abbreviation
WHEN MATCHED THEN UPDATE SET
  CountryID = b.CountryID;

END