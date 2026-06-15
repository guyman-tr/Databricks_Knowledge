USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_BI_DB_LTV_Conversions_Multipliers_Table(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

/********************************************************************************************
=============================================
Authors:     Jan Iablunovskey (Insights Team)
Create Date: 2024-09-24
Title:       Static Table for LTV Model with Conversion Matrix Multipliers
Description: This SP generates a static table for the LTV model, incorporating conversion fees into the revenue used in the model.

The table contains multipliers based on:
- Region (Current)
- First Cluster
- USD/Non-USD (checks the first month’s deposits to determine the most frequent currency).

All revenue is accumulated until 20240930, with FTDs from 2019-2021. 
Small groups (less then 100 clients) and NULLs will receive the value of their respective region.


**************************
** Change History
**************************
Date                 Author                   Description
2025-10-17           Guy M					  this proc is using the total revenew function which became unworkable. changed the underlying from all the functions to reading from the DDR 
											   table, much more efficient - but this changed some of the name conventions, so added case statement to handle. 
----------           -----------              -------------------------------------
----------           -----------              -------------------------------------
*********************************************************************************************/

IF CAST(current_timestamp() AS DATE) <= '2024-10-30'--- Making sure that SP will not run daily

THEN
/********** Accumulated Revenue **********/

 
DROP VIEW IF EXISTS TEMP_TABLE_Revenue;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Revenue
    
AS
SELECT
	frt.RealCID  AS CID
   , CASE WHEN frt.Metric = 'FullCommission' THEN 'TotalFullCommission' ELSE  frt.Metric END AS Metric
   ,SUM(frt.Amount) AS Amount
FROM dwh_daily_process.migration_tables.Function_Revenue_Total(20190101,20241027, 1) frt
WHERE frt.Metric IN ('TotalFullCommission','RolloverFee','ConversionFee') 
GROUP BY 
    frt.RealCID  
    ,frt.Metric;

/********** Flat Revenue Table **********/

DROP VIEW IF EXISTS TEMP_TABLE_Flat_Revenue;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Flat_Revenue
    
AS
SELECT pr.CID
      ,dc.VerificationLevelID
      ,CAST(dc.FirstDepositDate AS DATE) AS FirstDepositDate
	  ,DATEADD(DAY, 30, dc.FirstDepositDate) AS First_Month_Date
	  ,dc1.MarketingRegionManualName AS Region
      ,SUM(CASE WHEN pr.Metric = 'TotalFullCommission' THEN pr.Amount ELSE 0 END) AS TotalFullCommission
	  ,SUM(CASE WHEN pr.Metric = 'RolloverFee' THEN pr.Amount ELSE 0 END) AS RolloverFee
	  ,SUM(CASE WHEN pr.Metric = 'ConversionFee' THEN pr.Amount ELSE 0 END) AS ConversionFee
	  ,SUM(CASE WHEN pr.Metric = 'TotalFullCommission' THEN pr.Amount ELSE 0 END)+SUM(CASE WHEN pr.Metric = 'RolloverFee' THEN pr.Amount ELSE 0 END) AS Revenue_LTV_WO_Conversions
	  ,SUM(CASE WHEN pr.Metric = 'TotalFullCommission' THEN pr.Amount ELSE 0 END)+SUM(CASE WHEN pr.Metric = 'RolloverFee' THEN pr.Amount ELSE 0 END)+SUM(CASE WHEN pr.Metric = 'ConversionFee' THEN pr.Amount ELSE 0 END) AS Revenue_LTV_Incl_Conversions
FROM TEMP_TABLE_Revenue pr
INNER JOIN dwh_daily_process.migration_tables.Dim_Customer dc  ON dc.RealCID=pr.CID AND YEAR(dc.FirstDepositDate) IN (2019,2020,2021) AND dc.IsDepositor=1
INNER JOIN dwh_daily_process.migration_tables.Dim_Country dc1  ON dc.CountryID = dc1.CountryID
GROUP BY pr.CID
      ,CAST(dc.FirstDepositDate AS DATE) 
	  ,DATEADD(DAY, 30, dc.FirstDepositDate) 
	  ,dc1.MarketingRegionManualName
	  ,dc.VerificationLevelID;

   
/********** First Cluster (Seniority 1) **********/

DROP VIEW IF EXISTS TEMP_TABLE_First_Cluster;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_First_Cluster
    
AS
SELECT fr.*
      , CASE
	    WHEN bdcmpfd.ClusterDetail IS NOT NULL THEN bdcmpfd.ClusterDetail
	    WHEN bdcmpfd.FirstAction IS NOT NULL AND
		fr.VerificationLevelID = 3 THEN 'No Cluster - Active'
	    ELSE 'No Cluster - Inactive'
        END AS First_Cluster
FROM TEMP_TABLE_Flat_Revenue fr
LEFT JOIN dwh_daily_process.migration_tables.BI_DB_CID_MonthlyPanel_FullData bdcmpfd 
ON fr.CID = bdcmpfd.CID
AND bdcmpfd.Seniority = 1;

/********** First Month Currency Preference Deposits **********/

DROP VIEW IF EXISTS TEMP_TABLE_Currency;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Currency

AS
SELECT c.*
       ,CASE WHEN c.CurrencyID = 1 THEN 'USD' ELSE 'Non_USD' END AS Currency
FROM (
SELECT b.CID
      ,b.CurrencyID
      ,ROW_NUMBER() OVER (PARTITION BY b.CID ORDER BY b.AmountUSD DESC) AS Row_Num
FROM (
SELECT fbd.CID
      ,fbd.CurrencyID
	  ,SUM(fbd.AmountUSD) AS AmountUSD
FROM dwh_daily_process.migration_tables.Fact_BillingDeposit fbd 
INNER JOIN TEMP_TABLE_Flat_Revenue fr ON fbd.CID = fr.CID AND fbd.ModificationDate>=fr.FirstDepositDate AND fbd.ModificationDate<=fr.First_Month_Date 
WHERE fbd.PaymentStatusID=2 
GROUP BY 
       fbd.CID
      ,fbd.CurrencyID ) b)c
WHERE c.Row_Num=1;

/********** Region/Currency Revenue Change Percentage **********/

DROP VIEW IF EXISTS TEMP_TABLE_Region;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Region

AS
SELECT  fr.Region
       ,c.Currency
	   ,CASE WHEN SUM(fr.Revenue_LTV_WO_Conversions)=0 THEN 0 
	    ELSE SUM(fr.Revenue_LTV_Incl_Conversions)/SUM(fr.Revenue_LTV_WO_Conversions)-1 END  AS Revenue_Change_Percentage
FROM TEMP_TABLE_Flat_Revenue fr
LEFT JOIN TEMP_TABLE_Currency c ON c.CID=fr.CID
GROUP BY fr.Region
        ,c.Currency;

/********** Region/Cluster Revenue Change Percentage **********/

DROP VIEW IF EXISTS TEMP_TABLE_Region2;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Region2

AS
SELECT  fr.Region
       ,fc.First_Cluster
	   ,CASE WHEN SUM(fr.Revenue_LTV_WO_Conversions)=0 THEN 0 
	    ELSE SUM(fr.Revenue_LTV_Incl_Conversions)/SUM(fr.Revenue_LTV_WO_Conversions)-1 END  AS Revenue_Change_Percentage
FROM TEMP_TABLE_Flat_Revenue fr
LEFT JOIN TEMP_TABLE_First_Cluster fc ON fr.CID=fc.CID
GROUP BY fr.Region
       ,fc.First_Cluster;

/********** Region Revenue Change Percentage **********/

DROP VIEW IF EXISTS TEMP_TABLE_Region3;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Region3

AS
SELECT  fr.Region
	   ,CASE WHEN SUM(fr.Revenue_LTV_WO_Conversions)=0 THEN 0 
	    ELSE SUM(fr.Revenue_LTV_Incl_Conversions)/SUM(fr.Revenue_LTV_WO_Conversions)-1 END  AS Revenue_Change_Percentage
FROM TEMP_TABLE_Flat_Revenue fr
GROUP BY fr.Region;

/********** Create a table of all combintaions for Region, Cluster, Curency Type **********/

DROP VIEW IF EXISTS TEMP_TABLE_Combinations;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Combinations

AS
-- Combine regions, clusters, and currencies
SELECT 
    region.Region,
    cluster.First_Cluster, 
    currency.Currency 

FROM 
    -- Get distinct regions and append NULL
    (SELECT DISTINCT r.Region FROM TEMP_TABLE_Region r  UNION ALL SELECT NULL) region

CROSS JOIN 
    -- Get distinct clusters and append NULL
    (SELECT DISTINCT fc.First_Cluster FROM TEMP_TABLE_First_Cluster fc ) cluster

CROSS JOIN
    -- Get distinct currencies and append NULL
    (SELECT DISTINCT c.Currency FROM TEMP_TABLE_Currency c UNION ALL SELECT NULL) currency 

WHERE region.Region IS NOT NULL;

/********* Pre Final **********/

DROP VIEW IF EXISTS TEMP_TABLE_PreFinal;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_PreFinal

AS
SELECT fr.Region
      ,fc.First_Cluster
	  ,c.Currency
	  ,SUM(fr.TotalFullCommission) AS TotalFullCommission
	  ,SUM(fr.RolloverFee) AS RolloverFee
	  ,SUM(fr.ConversionFee) AS ConversionFee
	  ,SUM(fr.Revenue_LTV_WO_Conversions) AS Revenue_LTV_WO_Conversions
	  ,SUM(fr.Revenue_LTV_Incl_Conversions) AS Revenue_LTV_Incl_Conversions
	  ,CASE WHEN SUM(fr.Revenue_LTV_WO_Conversions)=0 THEN 0 
	   ELSE SUM(fr.Revenue_LTV_Incl_Conversions)/SUM(fr.Revenue_LTV_WO_Conversions)-1 END  AS Revenue_Change_Percentage
	  ,COUNT(*) AS Clients
FROM TEMP_TABLE_Flat_Revenue fr
LEFT JOIN TEMP_TABLE_First_Cluster fc ON fr.CID=fc.CID
LEFT JOIN TEMP_TABLE_Currency c ON c.CID=fr.CID
GROUP BY fr.Region
      ,fc.First_Cluster
	  ,c.Currency;

/********* Final **********/

DROP VIEW IF EXISTS TEMP_TABLE_Final1;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Final1

AS
SELECT c.*
      ,CASE WHEN c.Revenue_Change_Percentage >0.1 THEN 0.1---Avoid Extreme increase
	        WHEN c.Region='USA' THEN 0 --- No conversion fees in USA
	        WHEN c.Clients <100  THEN r2.Revenue_Change_Percentage --- Fix to small groups 
			WHEN c.First_Cluster IS NOT NULL AND c.Currency IS NULL THEN r1.Revenue_Change_Percentage---NULL logic
			WHEN c.First_Cluster IS NULL AND c.Currency IS NOT NULL THEN r.Revenue_Change_Percentage---NULL logic
			WHEN c.First_Cluster IS NULL AND c.Currency IS NULL THEN r2.Revenue_Change_Percentage---NULL logic
			WHEN c.TotalFullCommission IS NULL THEN r2.Revenue_Change_Percentage---NULL logic
		    ELSE c.Revenue_Change_Percentage 
		    END AS Revenue_Change_Percentage_Fixed
FROM (
SELECT cb.*
      ,pf.TotalFullCommission
	  ,pf.RolloverFee
	  ,pf.ConversionFee
	  ,pf.Revenue_LTV_WO_Conversions
	  ,pf.Revenue_LTV_Incl_Conversions
	  ,pf.Revenue_Change_Percentage
	  ,COALESCE(pf.Clients, 0) AS Clients
FROM TEMP_TABLE_Combinations cb
LEFT JOIN TEMP_TABLE_PreFinal pf 
    ON COALESCE(cb.Region, 'N/A') = COALESCE(pf.Region, 'N/A')
   AND COALESCE(cb.First_Cluster, 'N/A') = COALESCE(pf.First_Cluster, 'N/A')
   AND COALESCE(cb.Currency, 'N/A') = COALESCE(pf.Currency, 'N/A')) c
LEFT JOIN TEMP_TABLE_Region r ON r.Region=c.Region AND r.Currency=c.Currency
LEFT JOIN TEMP_TABLE_Region3 r2 ON r2.Region=c.Region
LEFT JOIN TEMP_TABLE_Region2 r1 ON r1.Region=c.Region AND r1.First_Cluster=c.First_Cluster

;
TRUNCATE TABLE dwh_daily_process.migration_tables.LTV_Conversions_Multipliers_Table;
INSERT INTO dwh_daily_process.migration_tables.LTV_Conversions_Multipliers_Table
(
`Region`,
`First_Cluster`,
`Currency`,
`TotalFullCommission`,
`RolloverFee`,
`ConversionFee`,
`Revenue_LTV_WO_Conversions`,
`Revenue_LTV_Incl_Conversions`,
`Revenue_Change_Percentage`,
`Clients`,
`Revenue_Change_Percentage_Fixed`,
`UpdateDate`
)
SELECT
`Region`,
`First_Cluster`,
`Currency`,
`TotalFullCommission`,
`RolloverFee`,
`ConversionFee`,
`Revenue_LTV_WO_Conversions`,
`Revenue_LTV_Incl_Conversions`,
`Revenue_Change_Percentage`,
`Clients`,
`Revenue_Change_Percentage_Fixed`,
current_timestamp() AS UpdateDate
FROM TEMP_TABLE_Final1 

;

END IF; 


-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_Combinations;
DROP VIEW IF EXISTS TEMP_TABLE_Currency;
DROP VIEW IF EXISTS TEMP_TABLE_Final1;
DROP VIEW IF EXISTS TEMP_TABLE_First_Cluster;
DROP VIEW IF EXISTS TEMP_TABLE_Flat_Revenue;
DROP VIEW IF EXISTS TEMP_TABLE_PreFinal;
DROP VIEW IF EXISTS TEMP_TABLE_Region;
DROP VIEW IF EXISTS TEMP_TABLE_Region2;
DROP VIEW IF EXISTS TEMP_TABLE_Region3;
DROP VIEW IF EXISTS TEMP_TABLE_Revenue;
END;
