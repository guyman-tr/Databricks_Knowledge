ALTER PROC [BI_DB_dbo].[SP_DDR_Customer_Daily_Status] @date [DATE] AS 
     
/********************************************************************************************      
Author:      Guy Manova       
Date:        2024-07-02      
Description: creates a daily full snapshot (not slowly changing) of the entire population and their relevant statuses to the DDR (and other) context
      
**************************      
** Change History      
**************************      

Date			Author			Description       
      
2025-08-06		Guy M			didn't have reason 14 (C2F) as possible deposit iban - was missing a CID in the total population. 
2025-08-20		Guy M			add first IOB date 		
2025-10-13		Guy M			add Options FTDs 
2025-11-02		Guy M			added code to deal with all the problems the global ftd contrasting data sources created. 
2025-11-11		Guy M			added code to handle FTDs from moneyfarm
2025-12-15		Guy M			added a deduplication at the end - Production bug (dual processing of withdraw) created 2 rows of data, inhibiting lake merge key (CID + Date). 
								so although the bug is real, must account for it here or it breaks the lake export. 
2026-06-01		Guy M			REQ-25250 - final demotion UPDATE for the bad $1 FTD cohort (Aug 2025 + May 2026):
								zero IsDepositor / IsDepositorGlobal / all FTD anchor columns / FirstDeposited flags
								for cohort RealCIDs on @dateID. Bug #2 of REQ-25250 - the long-running IsDepositor
								flag inherits from Dim_Customer (the $1 deposits are real data FTDs, just not 
								business FTDs) and was not filtered by any prior layer. Companion to the MIMO 
								demotion already added under the same REQ-25250.
----------    ----------   ------------------------------------*/      

-- exec BI_DB_dbo.SP_DDR_Customer_Daily_Status '20250831'

BEGIN 

-- DECLARE @date DATE = '20251120'
DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)


--- general population ----

IF OBJECT_ID('tempdb..#populationTP') IS NOT NULL DROP TABLE #populationTP -- select * from #populationTP where RealCID in (24322107, 45485159)
CREATE TABLE #populationTP
    WITH (HEAP, DISTRIBUTION = ROUND_ROBIN)
AS
SELECT DISTINCT bdcbcln.CID AS RealCID
	, dc.FirstDepositDate
	, CAST(FORMAT(CAST(FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS FirstDepositDateID 
	, dc.FirstDepositAmount
	, df.FTDPlatformName
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
	LEFT JOIN DWH_dbo.Dim_Customer dc
		ON bdcbcln.CID = dc.RealCID
	LEFT JOIN DWH_dbo.Dim_FTDPlatform df
		ON dc.FTDPlatformID = df.FTDPlatformID
WHERE bdcbcln.DateID = @dateID


-- add IBAN Only users who are not in the TP population base (CB)

IF OBJECT_ID('tempdb..#ibanPrep') IS NOT NULL DROP TABLE #ibanPrep -- select * from #ibanPrep  where  RealCID in (24322107, 45485159)
CREATE TABLE #ibanPrep
    WITH (HEAP,DISTRIBUTION = ROUND_ROBIN)
as
SELECT *
FROM 
	(
	SELECT
		mfts.CID AS RealCID
	  , mfts.TxStatusModificationTime
	  , mfts.USDAmountApprox
	  , ROW_NUMBER () OVER (PARTITION BY CID ORDER BY mfts.TxStatusModificationTime) AS RN
	  , df.FTDPlatformName
	FROM eMoney_dbo.eMoney_Fact_Transaction_Status mfts
		JOIN DWH_dbo.Dim_Customer dc
			ON mfts.CID = dc.RealCID
		LEFT JOIN DWH_dbo.Dim_FTDPlatform df
			ON dc.FTDPlatformID = df.FTDPlatformID
	WHERE 1 = 1
	AND mfts.TxStatusID = 2 -- settled
	AND mfts.TxTypeID IN (7,14)
	AND mfts.TxStatusModificationDateID <= @dateID
	) a
WHERE RN = 1
AND a.RealCID NOT IN (SELECT t.RealCID FROM #populationTP t)


IF OBJECT_ID('tempdb..#populationOptions') IS NOT NULL DROP TABLE #populationOptions -- select * from #populationOptions  where  RealCID in (24322107, 45485159)
CREATE TABLE #populationOptions
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT dc.RealCID
	, dc.FirstDepositDate
	, dc.FirstDepositAmount
	, NULL AS RN
	, df.FTDPlatformName
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN DWH_dbo.Dim_FTDPlatform df
	ON dc.FTDPlatformID = df.FTDPlatformID
WHERE dc.FTDPlatformID = 2
AND dc.RealCID NOT IN (SELECT RealCID FROM #populationTP t) AND dc.RealCID NOT IN (SELECT RealCID FROM #ibanPrep p)


IF OBJECT_ID('tempdb..#populationOptionsMIMO') IS NOT NULL DROP TABLE #populationOptionsMIMO -- select * from #populationOptionsMIMO  where  RealCID in (24322107, 45485159)
CREATE TABLE #populationOptionsMIMO
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT DISTINCT bddfmop.RealCID 
	, dc.FirstDepositDate
	, dc.FirstDepositAmount
	, NULL AS RN 
	, df.FTDPlatformName
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform bddfmop
	JOIN DWH_dbo.Dim_Customer dc
		ON bddfmop.RealCID = dc.RealCID
	LEFT JOIN DWH_dbo.Dim_FTDPlatform df
		ON dc.FTDPlatformID = df.FTDPlatformID
WHERE bddfmop.RealCID NOT IN (SELECT RealCID FROM #populationTP)
AND bddfmop.RealCID NOT IN (SELECT RealCID FROM #ibanPrep)
AND bddfmop.RealCID NOT IN (SELECT RealCID FROM #populationOptions)

IF OBJECT_ID('tempdb..#populationMoneyFarm') IS NOT NULL DROP TABLE #populationMoneyFarm -- select * from #populationMoneyFarm
CREATE TABLE #populationMoneyFarm
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT dc.RealCID
	, dc.FirstDepositDate
	, dc.FirstDepositAmount
	, NULL AS RN
	, df.FTDPlatformName
FROM DWH_dbo.Dim_Customer dc
	LEFT JOIN DWH_dbo.Dim_FTDPlatform df
		ON dc.FTDPlatformID = df.FTDPlatformID
WHERE dc.FTDPlatformID = 4
	AND dc.RealCID NOT IN (SELECT RealCID FROM #populationTP t)
	AND dc.RealCID NOT IN (SELECT RealCID FROM #ibanPrep t)
	AND dc.RealCID NOT IN (SELECT RealCID FROM #populationOptions t)
	AND dc.RealCID NOT IN (SELECT RealCID FROM #populationOptionsMIMO t)



IF OBJECT_ID('tempdb..#population') IS NOT NULL DROP TABLE #population -- select * from #population  where  RealCID in (24322107, 45485159)
CREATE TABLE #population
    WITH (CLUSTERED INDEX (RealCID),DISTRIBUTION = HASH(RealCID))
as
SELECT t.RealCID
	 , t.FirstDepositDate
	 , t.FirstDepositDateID
	 , t.FirstDepositAmount
	 , t.FTDPlatformName
FROM #populationTP t
UNION ALL 
SELECT ipr.RealCID
	 , ipr.TxStatusModificationTime AS FirstDepositDate
	 , CAST(FORMAT(CAST(TxStatusModificationTime AS DATE),'yyyyMMdd') as INT) AS FirstDepositDateID
	 , ipr.USDAmountApprox AS FirstDepositAmount
	 , ipr.FTDPlatformName
FROM #ibanPrep ipr
UNION ALL 
SELECT o.RealCID
	 , o.FirstDepositDate
	 , CAST(FORMAT(CAST(o.FirstDepositDate AS DATE),'yyyyMMdd') as INT)
	 , o.FirstDepositAmount
	 , o.FTDPlatformName
FROM #populationOptions o
union all 
SELECT o.RealCID
	 , o.FirstDepositDate
	 , CAST(FORMAT(CAST(o.FirstDepositDate AS DATE),'yyyyMMdd') as INT)
	 , o.FirstDepositAmount
	 , o.FTDPlatformName
FROM #populationOptionsMIMO o
UNION ALL 
SELECT mf.RealCID
	 , mf.FirstDepositDate
	 , CAST(FORMAT(CAST(mf.FirstDepositDate AS DATE),'yyyyMMdd') as INT)
	 , mf.FirstDepositAmount
	 , mf.FTDPlatformName
FROM #populationMoneyFarm mf

PRINT '#population' + ' ' + cast(getdate() AS VARCHAR (20))


---- general user statuses from fact snapshot



IF OBJECT_ID('tempdb..#fsc') IS NOT NULL DROP TABLE #fsc --  select * from #fsc where RealCID = 45494976
CREATE TABLE #fsc
    WITH (CLUSTERED INDEX (RealCID),DISTRIBUTION = HASH(RealCID))
AS
SELECT fsc.RealCID 
	, fsc.RegulationID
	, fsc.DesignatedRegulationID
	, fsc.PlayerStatusID
	, fsc.IsCreditReportValidCB
	, fsc.IsValidCustomer
	, fsc.AccountTypeID
	, fsc.CountryID
	, fsc.MifidCategorizationID
	, fsc.PlayerLevelID
	, fsc.IsDepositor
	, p.FTDPlatformName
FROM DWH_dbo.Fact_SnapshotCustomer fsc
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND @dateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN #population p
		ON fsc.RealCID = p.RealCID


PRINT '#fsc' + ' ' + cast(getdate() AS VARCHAR (20))


---- funded accounts -----


IF OBJECT_ID('tempdb..#funded') IS NOT NULL DROP TABLE #funded -- select * from #funded
CREATE TABLE #funded
    WITH (CLUSTERED INDEX (RealCID),DISTRIBUTION = HASH(RealCID))
as
SELECT fpf.DateID, fpf.RealCID, fpf.Equity
FROM BI_DB_dbo.Function_Population_Funded (@dateID) fpf


---- first time funded -----


IF OBJECT_ID('tempdb..#firstTimeFunded') IS NOT NULL DROP TABLE #firstTimeFunded -- select * from #firstTimeFunded where RealCID = 32736095
CREATE TABLE #firstTimeFunded
    WITH (CLUSTERED INDEX (RealCID),DISTRIBUTION = HASH(RealCID))
as
SELECT fpftf.RealCID, fpftf.FirstFundedDateID, fpftf.FirstIOBDateID, fpftf.FirstIOBTime
FROM BI_DB_dbo.Function_Population_First_Time_Funded() fpftf


--- first trading action ----


IF OBJECT_ID('tempdb..#FirstActions') IS NOT NULL DROP TABLE #FirstActions --  select * from #FirstActions 
CREATE TABLE #FirstActions
    WITH (CLUSTERED INDEX (RealCID),DISTRIBUTION = HASH(RealCID))
AS SELECT *
FROM BI_DB_dbo.Function_Population_First_Trading_Action(1) fa


PRINT '#FirstActions' + ' ' + cast(getdate() AS VARCHAR (20))

--- dim ddr status ---



IF OBJECT_ID('tempdb..#basicStatuses') IS NOT NULL DROP TABLE #basicStatuses --  select * from #basicStatuses where RealCID = 45494976
CREATE TABLE #basicStatuses
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT
	p.RealCID
  , p.FirstDepositDate 
  , p.FirstDepositDateID
  , p.FirstDepositAmount
  , f.RegulationID
  , f.DesignatedRegulationID
  , f.PlayerStatusID
  , f.IsCreditReportValidCB
  , f.IsValidCustomer
  , f.AccountTypeID
  , f.CountryID
  , f.MifidCategorizationID
  , f.PlayerLevelID
  , f.IsDepositor
  , CASE WHEN f1.RealCID IS NOT NULL THEN 1 ELSE 0 END AS IsFunded
  , case WHEN tf.FirstFundedDateID = @dateID THEN 1 ELSE 0 END AS FirstTimeFunded
  , tf.FirstFundedDateID
  , CASE WHEN fa.FirstTradeDateID > @dateID OR fa.FirstTradeDateID IS NULL THEN 'NoAction' else fa.FirstActionType END AS FirstActionType
  , fa.FirstTradeDateID 
  , tf.FirstIOBDateID
  , tf.FirstIOBTime
FROM #population p
	LEFT JOIN #fsc f
		ON p.RealCID = f.RealCID
	LEFT JOIN #funded f1
		ON p.RealCID = f1.RealCID
	LEFT JOIN #firstTimeFunded tf
		ON p.RealCID = tf.RealCID
	LEFT JOIN #FirstActions fa
		ON p.RealCID = fa.RealCID


--- user main segmentation 
--- balance only accounts

IF OBJECT_ID('tempdb..#balanceOnly') IS NOT NULL DROP TABLE #balanceOnly -- select top 10 * from #balanceOnly where RealCID = 45494976
CREATE TABLE #balanceOnly
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT *
FROM BI_DB_dbo.Function_Population_Balance_Only_Accounts(@dateID, @dateID) fpboa

--- portfolio only accounts

IF OBJECT_ID('tempdb..#portfolioOnly') IS NOT NULL DROP TABLE #portfolioOnly -- select top 10 * from #portfolioOnly where RealCID = 45494976
CREATE TABLE #portfolioOnly
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT * FROM BI_DB_dbo.Function_Population_Portfolio_Only(@dateID, @dateID) fppo  

--- active trading only accounts

IF OBJECT_ID('tempdb..#activeTraders') IS NOT NULL DROP TABLE #activeTraders -- select top 10 * from #activeTraders where RealCID = 45494976
CREATE TABLE #activeTraders
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT * FROM BI_DB_dbo.Function_Population_Active_Traders(@dateID, @dateID) fpat

PRINT '#activeTraders' + ' ' + cast(getdate() AS VARCHAR (20))

--- completely inactive accounts

IF OBJECT_ID('tempdb..#inactive') IS NOT NULL DROP TABLE #inactive
CREATE TABLE #inactive
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT s.RealCID
FROM #basicStatuses s
EXCEPT SELECT RealCID FROM #portfolioOnly 
EXCEPT SELECT RealCID FROM #balanceOnly 
EXCEPT SELECT RealCID FROM #activeTraders 



--- depositors global
-- trading platform


IF OBJECT_ID('tempdb..#globalFTDs') IS NOT NULL DROP TABLE #globalFTDs -- select * from #globalFTDs where RealCID = 16846400
CREATE TABLE #globalFTDs
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT dc.RealCID, dc.FTDTransactionID AS DepositID, dc.FirstDepositDate, dc.FirstDepositAmount, df.FTDPlatformName AS FTDPlatform, dc.FTDPlatformID 
FROM DWH_dbo.Dim_Customer dc 
	JOIN DWH_dbo.Dim_FTDPlatform df
		ON dc.FTDPlatformID = df.FTDPlatformID


IF OBJECT_ID('tempdb..#TPFTDs') IS NOT NULL DROP TABLE #TPFTDs -- select * from #TPFTDs where RealCID = 32736095
CREATE TABLE #TPFTDs
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT dc.RealCID
	, CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS FirstDepositDateIDTP
	, dc.FirstDepositDate AS FirstDepositDateTP
	, dc.FirstDepositAmount AS FirstDepositAmountTP
FROM #globalFTDs dc
WHERE dc.FTDPlatform = 'TradingPlatform'
AND CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) <= @dateID

-- eMoney


IF OBJECT_ID('tempdb..#IbanFTDs') IS NOT NULL DROP TABLE #IbanFTDs -- select * from #IbanFTDs where RealCID = 32736095
CREATE TABLE #IbanFTDs
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT dc.RealCID
	, CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS FirstDepositDateIDIBAN
	, dc.FirstDepositDate AS FirstDepositDateIBAN
	, dc.FirstDepositAmount AS FirstDepositAmountIBAN
FROM #globalFTDs dc
WHERE dc.FTDPlatform = 'eMoney'
AND CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) <= @dateID

PRINT '#IbanFTDs' + ' ' + cast(getdate() AS VARCHAR (20))


IF OBJECT_ID('tempdb..#OptionsFTDs') IS NOT NULL DROP TABLE #OptionsFTDs -- select * from #OptionsFTDs
CREATE TABLE #OptionsFTDs
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT dc.RealCID
	, CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS FirstDepositDateIDOptions
	, dc.FirstDepositDate AS FirstDepositDateOptions
	, dc.FirstDepositAmount AS FirstDepositAmountOptions
FROM #globalFTDs dc
WHERE dc.FTDPlatform = 'Options'
AND CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) <= @dateID


IF OBJECT_ID('tempdb..#MoneyFarmFTD') IS NOT NULL DROP TABLE #MoneyFarmFTD -- select * from #MoneyFarmFTD where RealCID = 16846400
CREATE TABLE #MoneyFarmFTD
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT dc.RealCID
	, CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS FirstDepositDateIDMoneyFarm
	, dc.FirstDepositDate AS FirstDepositDateMoneyFarm
	, dc.FirstDepositAmount AS FirstDepositAmountMoneyFarm
FROM #globalFTDs dc
WHERE dc.FTDPlatform = 'MoneyFarm'
AND CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) <= @dateID

/*------------------------------------
this section is not really needed, but to keep the schemas in tact from previous versions
its generating the expected schema of the old deprecated code
------------------------------------*/

IF OBJECT_ID('tempdb..#globalDepositorsAlltime') IS NOT NULL DROP TABLE #globalDepositorsAlltime; -- select * from #globalDepositorsAlltime where RealCID = 16846400
CREATE TABLE #globalDepositorsAlltime
    WITH (HEAP, DISTRIBUTION = ROUND_ROBIN)
AS
SELECT f.RealCID
        -- TP
	, CASE WHEN f.FTDPlatformID = 1 THEN CAST(FORMAT(CAST(f.FirstDepositDate AS DATE),'yyyyMMdd') as INT) end AS FirstDepositDateIDTP
	, CASE WHEN f.FTDPlatformID = 1 THEN f.FirstDepositDate end AS FirstDepositDateTP
	, CASE WHEN f.FTDPlatformID = 1 THEN f.FirstDepositAmount end AS FirstDepositAmountTP
        -- IBAN
	, CASE WHEN f.FTDPlatformID = 3 THEN CAST(FORMAT(CAST(f.FirstDepositDate AS DATE),'yyyyMMdd') as INT) end AS FirstDepositDateIDIBAN
	, CASE WHEN f.FTDPlatformID = 3 THEN f.FirstDepositDate end AS FirstDepositDateIBAN
	, CASE WHEN f.FTDPlatformID = 3 THEN f.FirstDepositAmount end AS FirstDepositAmountIBAN
        -- Options
	, CASE WHEN f.FTDPlatformID = 2 THEN CAST(FORMAT(CAST(f.FirstDepositDate AS DATE),'yyyyMMdd') as INT) end AS FirstDepositDateIDOptions
	, CASE WHEN f.FTDPlatformID = 2 THEN f.FirstDepositDate end AS FirstDepositDateOptions
	, CASE WHEN f.FTDPlatformID = 2 THEN f.FirstDepositAmount end AS FirstDepositAmountOptions
        -- MoneyFarm
	, CASE WHEN f.FTDPlatformID = 4 THEN CAST(FORMAT(CAST(f.FirstDepositDate AS DATE),'yyyyMMdd') as INT) end AS FirstDepositDateIDMoneyFarm
	, CASE WHEN f.FTDPlatformID = 4 THEN f.FirstDepositDate end AS FirstDepositDateMoneyFarm
	, CASE WHEN f.FTDPlatformID = 4 THEN f.FirstDepositAmount end AS FirstDepositAmountMoneyFarm
---------------------------------------------------------------------------------------------------
	, CAST(FORMAT(CAST(f.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS MinFirstDepositDateID
	, cast(f.FirstDepositDate AS Date) AS MinFirstDepositDate
	, f.FirstDepositAmount
	, CASE WHEN f.FirstDepositDate > '1900-01-01' THEN 1 ELSE 0 END AS IsDepositorGlobal
FROM #globalFTDs f


/* deprecated not needed after Global FTD

IF OBJECT_ID('tempdb..#globalDepositorsAlltime') IS NOT NULL DROP TABLE #globalDepositorsAlltime; -- select * from #globalDepositorsAlltime
CREATE TABLE #globalDepositorsAlltime
    WITH (HEAP, DISTRIBUTION = ROUND_ROBIN)
AS
WITH GLOBALDEPOSITORSPREP AS
(
    SELECT
        COALESCE(tpf.RealCID, ibf.RealCID, opt.RealCID) AS RealCID,
        -- TP
        tpf.FirstDepositDateIDTP,
        tpf.FirstDepositDateTP,
        tpf.FirstDepositAmountTP,
        -- IBAN
        ibf.FirstDepositDateIDIBAN,
        ibf.FirstDepositDateIBAN,
        ibf.FirstDepositAmountIBAN,
        -- Options
        opt.FirstDepositDateIDOptions,
        opt.FirstDepositDateOptions,
        opt.FirstDepositAmountOptions,
        -- Min ID: force INT and guard NULLs
        LEAST(
           ISNULL(CONVERT(INT, tpf.FirstDepositDateIDTP),      30000101),
           ISNULL(CONVERT(INT, ibf.FirstDepositDateIDIBAN),    30000101),
           ISNULL(CONVERT(INT, opt.FirstDepositDateIDOptions), 30000101)
        ) AS MinFirstDepositDateID,
        -- Min DATE: force DATE and guard NULLs
        LEAST(
           ISNULL(CONVERT(DATE, tpf.FirstDepositDateTP),       '3000-01-01'),
           ISNULL(CONVERT(DATE, ibf.FirstDepositDateIBAN),     '3000-01-01'),
           ISNULL(CONVERT(DATE, opt.FirstDepositDateOptions),  '3000-01-01')
        ) AS MinFirstDepositDate,
        -- Amount corresponding to the min date (tie priority: TP > IBAN > Options)
        CASE 
            WHEN ISNULL(CONVERT(DATE, tpf.FirstDepositDateTP),      '3000-01-01')
                 = LEAST(
                      ISNULL(CONVERT(DATE, tpf.FirstDepositDateTP),      '3000-01-01'),
                      ISNULL(CONVERT(DATE, ibf.FirstDepositDateIBAN),    '3000-01-01'),
                      ISNULL(CONVERT(DATE, opt.FirstDepositDateOptions), '3000-01-01')
                   )
                THEN tpf.FirstDepositAmountTP
            WHEN ISNULL(CONVERT(DATE, ibf.FirstDepositDateIBAN),    '3000-01-01')
                 = LEAST(
                      ISNULL(CONVERT(DATE, tpf.FirstDepositDateTP),      '3000-01-01'),
                      ISNULL(CONVERT(DATE, ibf.FirstDepositDateIBAN),    '3000-01-01'),
                      ISNULL(CONVERT(DATE, opt.FirstDepositDateOptions), '3000-01-01')
                   )
                THEN ibf.FirstDepositAmountIBAN
            ELSE opt.FirstDepositAmountOptions
        END AS FirstDepositAmount
    FROM #TPFTDs tpf
    FULL OUTER JOIN #IbanFTDs ibf
        ON tpf.RealCID = ibf.RealCID
    FULL OUTER JOIN #OptionsFTDs opt
        ON COALESCE(tpf.RealCID, ibf.RealCID) = opt.RealCID
)
SELECT gp.*,
       CASE WHEN gp.MinFirstDepositDateID <= @dateID THEN 1 ELSE 0 END AS IsDepositorGlobal
FROM GLOBALDEPOSITORSPREP gp;

*/

--- mimo data

/*----------------------------------------------------------------------
there is a timing issue between the recovery date of the global FTD 
(example: cid 45398632 FTDs on 20251019 but is seen there as 20251020)
need to coerce the transaction date from the mimo_allplatforms to 
the (false) date from dim_customer
-----------------------------------------------------------------------*/


IF OBJECT_ID('tempdb..#ibanTID') IS NOT NULL DROP TABLE #ibanTID -- select * from #ibanTID where RealCID = 32736095
CREATE TABLE #ibanTID
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT mfts.CID AS RealCID
	, mfts.TransactionID AS TransactionID
	, mfts.SourceCugTransactionID
	, mfts.TxStatusModificationTime
	, mfts.TxCreatedDate
FROM eMoney_dbo.eMoney_Fact_Transaction_Status mfts
WHERE mfts.TxStatusID = 2 
	AND mfts.TxTypeID IN (7,14)

/*----------------------------------------------------------------------
there is a a design flaw inherent to the mimo model - it relies on 
the AllPlatforms mimo table as source for left joins - which means it 
will not have FTDs from MoneyFarm and future new platforms which dont
have CID data available to DWH import. need to artificailly create these
and add them 
-----------------------------------------------------------------------*/
/*
IF OBJECT_ID('tempdb..#mimoAllPlatforms') IS NOT NULL DROP TABLE #mimoAllPlatforms
CREATE TABLE #mimoAllPlatforms
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT bddfmap.DateID
	 , bddfmap.Date
	 , bddfmap.RealCID
	 , bddfmap.MIMOAction
	 , bddfmap.OrigIdentifier
	 , bddfmap.TransactionID
	 , bddfmap.AmountUSD
	 , bddfmap.AmountOrigCurrency
	 , bddfmap.FundingTypeID
	 , bddfmap.CurrencyID
	 , bddfmap.Currency
	 , bddfmap.IsPlatformFTD
	 , bddfmap.IsInternalTransfer
	 , bddfmap.IsRedeem
	 , bddfmap.IsTradeFromIBAN
	 , bddfmap.MIMOPlatform
	 , bddfmap.IsGlobalFTD
	 , bddfmap.UpdateDate
	 , bddfmap.IsCryptoToFiat
	 , bddfmap.IsRecurring
	 , bddfmap.IsIBANQuickTransfer
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms bddfmap
UNION ALL 
SELECT 
	   CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS DateID
	 , cast(dc.FirstDepositDate AS DATE) AS Date
	 , dc.RealCID
	 , 'Deposit' as MIMOAction
	 , 'DepositID' as OrigIdentifier
	 , NULL as TransactionID
	 , dc.FirstDepositAmount as AmountUSD
	 , NULL as AmountOrigCurrency
	 , NULL as FundingTypeID
	 , NULL as CurrencyID
	 , NULL as Currency
	 , 1 as IsPlatformFTD
	 , 0 as IsInternalTransfer
	 , 0 as IsRedeem
	 , 0 as IsTradeFromIBAN
	 , 'MoneyFarm' as MIMOPlatform
	 , 1 as IsGlobalFTD
	 , dc.FirstDepositDate as UpdateDate
	 , 0 as IsCryptoToFiat
	 , 0 as IsRecurring
	 , 0 as IsIBANQuickTransfer
FROM DWH_dbo.Dim_Customer dc
WHERE dc.FTDPlatformID = 4
*/


IF OBJECT_ID('tempdb..#mimo_coerced') IS NOT NULL DROP TABLE #mimo_coerced -- select * from #mimo_coerced where RealCID = 45503828
CREATE TABLE #mimo_coerced
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS DateID
	 , CAST(dc.FirstDepositDate AS DATE) AS Date
	 , ac.SourceCugTransactionID
	 , dc.FTDTransactionID AS DimCustFTDTransactionID
	 , ap.RealCID
	 , ap.MIMOAction
	 , ap.OrigIdentifier
	 , ap.TransactionID
	 , ap.AmountUSD
	 , ap.AmountOrigCurrency
	 , ap.FundingTypeID
	 , ap.CurrencyID
	 , ap.Currency
	 , 1 AS IsPlatformFTD
	 , ap.IsInternalTransfer
	 , ap.IsRedeem
	 , ap.IsTradeFromIBAN
	 , ap.MIMOPlatform
	 , 1 AS IsGlobalFTD
	 , ap.UpdateDate
	 , ap.IsCryptoToFiat
	 , ap.IsRecurring
	 , ap.IsIBANQuickTransfer
	 , dc.FTDPlatformID
	 , dc.FirstDepositAmount AS GlobalFTA
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms ap 
 JOIN #ibanTID ac
	ON ap.TransactionID = ac.TransactionID  
 JOIN DWH_dbo.Dim_Customer dc
	ON ac.SourceCugTransactionID = dc.FTDTransactionID AND dc.FTDPlatformID = 3
WHERE ap.MIMOPlatform = 'eMoney'
AND ap.MIMOAction = 'Deposit'
AND cast(ac.TxStatusModificationTime AS DATE) <> cast(dc.FirstDepositDate AS Date)
AND dc.FirstDepositDate >= '20250901'
UNION all 
SELECT CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS DateID
	 , CAST(dc.FirstDepositDate AS DATE) AS Date
	 , NULL AS SourceCugTransactionID
	 , dc.FTDTransactionID AS DimCustFTDTransactionID
	 , ap.RealCID
	 , ap.MIMOAction
	 , ap.OrigIdentifier
	 , ap.TransactionID
	 , ap.AmountUSD
	 , ap.AmountOrigCurrency
	 , ap.FundingTypeID
	 , ap.CurrencyID
	 , ap.Currency
	 , 1 AS IsPlatformFTD
	 , ap.IsInternalTransfer
	 , ap.IsRedeem
	 , ap.IsTradeFromIBAN
	 , ap.MIMOPlatform
	 , 1 AS IsGlobalFTD
	 , ap.UpdateDate
	 , ap.IsCryptoToFiat
	 , ap.IsRecurring
	 , ap.IsIBANQuickTransfer
	 , dc.FTDPlatformID
	 , dc.FirstDepositAmount AS GlobalFTA
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms ap 
 JOIN DWH_dbo.Dim_Customer dc
	ON ap.TransactionID = dc.FTDTransactionID AND dc.FTDPlatformID = 1
WHERE ap.MIMOPlatform = 'TradingPlatform'
AND ap.MIMOAction = 'Deposit'
AND cast( ap.Date AS DATE) <> cast(dc.FirstDepositDate AS Date)
AND dc.FTDRecoveryDate IS NOT null
AND dc.FirstDepositDate >= '20250901'

-- add withdraws for these

IF OBJECT_ID('tempdb..#mimo_coerced_withdraw') IS NOT NULL DROP TABLE #mimo_coerced_withdraw -- SELECT * FROM #mimo_coerced_withdraw WHERE RealCID = 45503828
CREATE TABLE #mimo_coerced_withdraw
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT CAST(FORMAT(CAST(dc.FirstDepositDate AS DATE),'yyyyMMdd') as INT) AS DateID
	 , CAST(dc.FirstDepositDate AS DATE) AS Date
	 , NULL AS SourceCugTransactionID
	 , dc.FTDTransactionID AS DimCustFTDTransactionID
	 , ap.RealCID
	 , ap.MIMOAction
	 , ap.OrigIdentifier
	 , ap.TransactionID
	 , ap.AmountUSD
	 , ap.AmountOrigCurrency
	 , ap.FundingTypeID
	 , ap.CurrencyID
	 , ap.Currency
	 , 0 AS IsPlatformFTD
	 , ap.IsInternalTransfer
	 , ap.IsRedeem
	 , ap.IsTradeFromIBAN
	 , ap.MIMOPlatform
	 , 0 AS IsGlobalFTD
	 , ap.UpdateDate
	 , ap.IsCryptoToFiat
	 , ap.IsRecurring
	 , ap.IsIBANQuickTransfer
	 , dc.FTDPlatformID
	 , dc.FirstDepositAmount AS GlobalFTA
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms ap 
 JOIN DWH_dbo.Dim_Customer dc
	ON ap.RealCID = dc.RealCID 
WHERE 1 = 1
AND ap.DateID = @dateID
AND ap.MIMOAction = 'Withdraw'
AND ap.RealCID IN (SELECT RealCID FROM #mimo_coerced mc)
AND ap.IsInternalTransfer = 0


IF OBJECT_ID('tempdb..#mimoUsersPrep') IS NOT NULL DROP TABLE #mimoUsersPrep --  select * from #mimoUsersPrep where RealCID = 45503828
CREATE TABLE #mimoUsersPrep
    WITH (HEAP,DISTRIBUTION = ROUND_ROBIN)
AS
SELECT map.RealCID
	, map.DateID
	, @dateID AS TodayDateInt
	, map.MIMOAction 
	, map.TransactionID
	, map.FundingTypeID
	, map.IsGlobalFTD
	, CASE WHEN map.IsGlobalFTD = 1 THEN map.AmountUSD ELSE 0 end AS GlobalFTDA
	, map.IsPlatformFTD
	, map.MIMOPlatform
	, map.IsInternalTransfer
	, map.IsTradeFromIBAN
	, map.IsRedeem
	, CASE WHEN map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'TradingPlatform' AND map.IsPlatformFTD = 1 THEN 1 ELSE 0 END AS IsTPFTD
	, CASE WHEN map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'TradingPlatform' AND map.IsPlatformFTD = 1 THEN map.AmountUSD ELSE 0 END AS TPFTDA
	, CASE WHEN map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'eMoney' AND map.IsPlatformFTD = 1 THEN 1 ELSE 0 END AS IsIBANFTD
	, CASE WHEN map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'eMoney' AND map.IsPlatformFTD = 1 THEN map.AmountUSD ELSE 0 END AS IBANFTDA
	, CASE WHEN map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'TradingPlatform' AND map.IsPlatformFTD = 1 AND map.IsInternalTransfer = 0 THEN 1 ELSE 0 END AS IsTPExternalFTD
	, CASE WHEN map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'TradingPlatform' AND map.IsPlatformFTD = 1 AND map.IsInternalTransfer = 0 THEN map.AmountUSD ELSE 0 END AS TPExternalFTDA
	, CASE WHEN map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'Options' AND map.IsPlatformFTD = 2 THEN 1 ELSE 0 END AS IsOptionsFTD
	, CASE WHEN map.MIMOAction = 'Deposit' AND map.MIMOPlatform = 'Options' AND map.IsPlatformFTD = 2 THEN map.AmountUSD ELSE 0 END AS OptionsFTDA
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map  -- 1893309
WHERE map.DateID = @dateID

------------------------------------------------------------
-- mitigate the recovery date FTD problem in All Mimo data
------------------------------------------------------------

DELETE FROM #mimoUsersPrep 
WHERE MIMOAction = 'Deposit' AND MIMOPlatform = 'TradingPlatform' AND TransactionID in (SELECT mc.TransactionID FROM #mimo_coerced mc WHERE mc.FTDPlatformID = 1)

DELETE FROM #mimoUsersPrep 
WHERE MIMOAction = 'Deposit' AND MIMOPlatform = 'eMoney' AND TransactionID in (SELECT mc.TransactionID FROM #mimo_coerced mc WHERE mc.FTDPlatformID = 3)

INSERT INTO #mimoUsersPrep
	   SELECT
		   mc.RealCID
		 , mc.DateID
		 , @dateID AS TodayDateID
		 , mc.MIMOAction
		 , mc.TransactionID
		 , mc.FundingTypeID
		 , mc.IsGlobalFTD
		 , mc.GlobalFTA
		 , mc.IsPlatformFTD
		 , mc.MIMOPlatform
		 , mc.IsInternalTransfer
		 , mc.IsTradeFromIBAN
		 , mc.IsRedeem
		 , CASE WHEN mc.MIMOPlatform = 'TradingPlatform' THEN 1 ELSE 0 END AS IsTPFTD
		 , CASE WHEN mc.MIMOPlatform = 'TradingPlatform' THEN mc.GlobalFTA ELSE 0 END AS TPFTDA
		 , CASE WHEN mc.MIMOPlatform = 'eMoney' THEN 1 ELSE 0 END AS IsIBANFTD
		 , CASE WHEN mc.MIMOPlatform = 'eMoney' THEN mc.GlobalFTA ELSE 0 END AS IBANFTDA
		 , CASE WHEN mc.MIMOPlatform = 'TradingPlatform' THEN 1 ELSE 0 END AS IsTPExternalFTD
		 , CASE WHEN mc.MIMOPlatform = 'TradingPlatform' THEN mc.GlobalFTA ELSE 0 END AS TPExternalFTDA
		 , CASE WHEN mc.MIMOPlatform = 'Options' THEN 1 ELSE 0 END AS IsOptionsFTD
		 , CASE WHEN mc.MIMOPlatform = 'Options' THEN mc.GlobalFTA ELSE 0 END AS OptionsFTDA
	   FROM #mimo_coerced mc -- select * from #mimo_coerced where RealCID = 45503380


PRINT '#mimoUsersPrep' + ' ' + cast(getdate() AS VARCHAR (20))

------------------------------------------------------------


IF OBJECT_ID('tempdb..#mimoUsersNonCoerced') IS NOT NULL DROP TABLE #mimoUsersNonCoerced -- select * from #mimoUsersNonCoerced where RealCID = 16846400
CREATE TABLE #mimoUsersNonCoerced
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT a.RealCID
	 , a.DateID
	 , a.TodayDateInt
	 , max(a.GlobalDeposited		) as GlobalDeposited		
	 , max(a.GlobalFirstDeposited	) as GlobalFirstDeposited	
	 , min(a.GlobalFirstDepositDate	) as GlobalFirstDepositDate	
	 , max(a.GlobalRedeposited		) as GlobalRedeposited		
	 , max(a.GlobalFTDA				) as GlobalFTDA				
	 , max(a.GlobalCashedOut		) as GlobalCashedOut		
	 , max(a.Redeemed				) as Redeemed	
	 ------------
	 , max(a.DepositedTP			) as DepositedTP	
	 , max(a.DepositedIBAN			) as DepositedIBAN	
	 , max(a.DepositedOptions		) as DepositedOptions
	 , max(a.ReDepositedTP			) as ReDepositedTP	
	 , max(a.ReDepositedIBAN		) as ReDepositedIBAN	
	 , max(a.ReDepositedOptions		) as ReDepositedOptions	
	 , max(a.TPFirstDeposited		) as TPFirstDeposited	
	 , max(a.IBANFirstDeposited		) as IBANFirstDeposited	
	 , max(a.OptionsFirstDeposited	) as OptionsFirstDeposited	
	 , max(a.TPExternalFirstDeposited		) as TPExternalFirstDeposited	
	 , max(a.TPFTDA					) as TPFTDA	
	 , max(a.IBANFTDA				) as IBANFTDA	
	 , max(a.IBANFTDA				) as OptionsFTDA	
	 , max(a.TPExternalFTDA			) as TPExternalFTDA
FROM 
(
	SELECT
		p.RealCID
	  , p.DateID
	  , p.TodayDateInt
	  , p.IsGlobalFTD
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 AND p.DateID = p.TodayDateInt THEN 1 ELSE 0 END) AS GlobalDeposited
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsGlobalFTD = 1 AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS GlobalFirstDeposited
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsGlobalFTD = 1 AND p.DateID = p.TodayDateInt THEN @date ELSE CONVERT(DATE, CONVERT(VARCHAR(8), DateID), 112) END) AS GlobalFirstDepositDate
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsGlobalFTD = 0 AND p.IsInternalTransfer = 0 AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS GlobalRedeposited
	  , max(p.GlobalFTDA) AS GlobalFTDA
	  , max(CASE WHEN p.MIMOAction = 'Withdraw' AND p.IsInternalTransfer = 0 AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS GlobalCashedOut
	  , max(CASE WHEN p.MIMOAction = 'Withdraw' AND p.IsRedeem = 1 AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS Redeemed
	  -------------------------
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 AND p.MIMOPlatform = 'TradingPlatform' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS DepositedTP
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 AND p.MIMOPlatform = 'eMoney' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS DepositedIBAN
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 AND p.MIMOPlatform = 'Options'  AND p.DateID = p.TodayDateInt THEN 1 ELSE 0 END) AS DepositedOptions
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 and IsPlatformFTD = 0 AND p.MIMOPlatform = 'TradingPlatform' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS ReDepositedTP
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 and IsPlatformFTD = 0 AND p.MIMOPlatform = 'eMoney' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS ReDepositedIBAN
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 and IsPlatformFTD = 0 AND p.MIMOPlatform = 'Options' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS ReDepositedOptions
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsPlatformFTD = 1 AND p.MIMOPlatform = 'TradingPlatform' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS TPFirstDeposited
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsPlatformFTD = 1 AND p.MIMOPlatform = 'eMoney' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS IBANFirstDeposited
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsPlatformFTD = 1 AND p.MIMOPlatform = 'Options' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS OptionsFirstDeposited
	  ---------------------------
	  , max(CASE WHEN p.IsTPExternalFTD = 1 AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS TPExternalFirstDeposited
	  , max(p.TPFTDA) AS TPFTDA
	  , max(p.IBANFTDA) AS IBANFTDA
	  , max(p.OptionsFTDA) AS OptionsFTDA
	  , max(p.TPExternalFTDA) AS TPExternalFTDA
	FROM #mimoUsersPrep p 
	WHERE p.RealCID NOT IN (SELECT RealCID FROM #mimo_coerced mc)
	GROUP BY 	
		p.RealCID
	  , p.DateID
	  , p.IsGlobalFTD
	  , p.TodayDateInt
) a
GROUP BY 
	   a.RealCID
	 , a.DateID
	 , a.TodayDateInt


IF OBJECT_ID('tempdb..#mimoUsersCoerced') IS NOT NULL DROP TABLE #mimoUsersCoerced -- select *  from #mimoUsersCoerced where RealCID = 19108068
CREATE TABLE #mimoUsersCoerced														
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT a.RealCID
	 , @dateID AS DateID
	 --, a.TodayDateInt
	 , max(a.GlobalDeposited		) as GlobalDeposited		
	 , max(a.GlobalFirstDeposited	) as GlobalFirstDeposited	
	 , min(a.GlobalFirstDepositDate	) as GlobalFirstDepositDate	
	 , max(a.GlobalRedeposited		) as GlobalRedeposited		
	 , max(a.GlobalFTDA				) as GlobalFTDA				
	 , max(a.GlobalCashedOut		) as GlobalCashedOut		
	 , max(a.Redeemed				) as Redeemed	
	 ------------
	 , max(a.DepositedTP			) as DepositedTP	
	 , max(a.DepositedIBAN			) as DepositedIBAN	
	 , max(a.DepositedOptions		) as DepositedOptions
	 , max(a.ReDepositedTP			) as ReDepositedTP	
	 , max(a.ReDepositedIBAN		) as ReDepositedIBAN	
	 , max(a.ReDepositedOptions		) as ReDepositedOptions	
	 , max(a.TPFirstDeposited		) as TPFirstDeposited	
	 , max(a.IBANFirstDeposited		) as IBANFirstDeposited	
	 , max(a.OptionsFirstDeposited	) as OptionsFirstDeposited	
	 , max(a.TPExternalFirstDeposited		) as TPExternalFirstDeposited	
	 , max(a.TPFTDA					) as TPFTDA	
	 , max(a.IBANFTDA				) as IBANFTDA	
	 , max(a.IBANFTDA				) as OptionsFTDA	
	 , max(a.TPExternalFTDA			) as TPExternalFTDA
FROM 
(
	SELECT
		p.RealCID
	  , p.DateID
	  , p.TodayDateInt
	  , p.IsGlobalFTD
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 AND p.DateID = p.TodayDateInt THEN 1 ELSE 0 END) AS GlobalDeposited
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsGlobalFTD = 1 AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS GlobalFirstDeposited
	  , max(ut.Date) AS GlobalFirstDepositDate
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsGlobalFTD = 0 AND p.IsInternalTransfer = 0 AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS GlobalRedeposited
	  , max(ut.GlobalFTA) AS GlobalFTDA
	  , max(CASE WHEN mcw.RealCID IS NOT NULL THEN 1 ELSE 0 END) AS GlobalCashedOut
	  , max(CASE WHEN mcw.IsRedeem = 1 THEN 1 ELSE 0 END) AS Redeemed
	  -------------------------
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 AND p.MIMOPlatform = 'TradingPlatform' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS DepositedTP
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 AND p.MIMOPlatform = 'eMoney' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS DepositedIBAN
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 AND p.MIMOPlatform = 'Options'  AND p.DateID = p.TodayDateInt THEN 1 ELSE 0 END) AS DepositedOptions
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 and p.IsPlatformFTD = 0 AND p.MIMOPlatform = 'TradingPlatform' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS ReDepositedTP
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 and p.IsPlatformFTD = 0 AND p.MIMOPlatform = 'eMoney' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS ReDepositedIBAN
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsInternalTransfer = 0 and p.IsPlatformFTD = 0 AND p.MIMOPlatform = 'Options' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS ReDepositedOptions
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsPlatformFTD = 1 AND p.MIMOPlatform = 'TradingPlatform' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS TPFirstDeposited
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsPlatformFTD = 1 AND p.MIMOPlatform = 'eMoney' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS IBANFirstDeposited
	  , max(CASE WHEN p.MIMOAction = 'Deposit' AND p.IsPlatformFTD = 1 AND p.MIMOPlatform = 'Options' AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS OptionsFirstDeposited
	  , max(CASE WHEN p.IsTPExternalFTD = 1 AND p.DateID = p.TodayDateInt  THEN 1 ELSE 0 END) AS TPExternalFirstDeposited
	  , max(CASE WHEN ut.MIMOPlatform = 'TradingPlatform' THEN ut.GlobalFTA ELSE 0 END) AS TPFTDA
	  , max(CASE WHEN ut.MIMOPlatform = 'eMoney' THEN ut.GlobalFTA ELSE 0 END) AS IBANFTDA
	  , max(CASE WHEN ut.MIMOPlatform = 'Options' THEN ut.GlobalFTA ELSE 0 END) AS OptionsFTDA
	  , max(CASE WHEN ut.MIMOPlatform = 'TradingPlatform' THEN ut.GlobalFTA ELSE 0 END) AS TPExternalFTDA
	FROM #mimoUsersPrep p 
		LEFT JOIN (SELECT * FROM #mimo_coerced  uc WHERE uc.DateID < @dateID AND uc.IsGlobalFTD = 1) ut 
			ON p.RealCID = ut.RealCID
		LEFT JOIN (SELECT RealCID, max(IsRedeem) AS IsRedeem FROM #mimo_coerced_withdraw GROUP BY RealCID) mcw
			ON p.RealCID = mcw.RealCID
	WHERE 1 = 1
		AND p.RealCID IN (SELECT RealCID FROM #mimo_coerced mc)
	GROUP BY 	
		p.RealCID
	  , p.DateID
	  , p.IsGlobalFTD
	  , p.TodayDateInt
) a
GROUP BY 
	   a.RealCID


IF OBJECT_ID('tempdb..#mimoUsers') IS NOT NULL DROP TABLE #mimoUsers -- select * from #mimoUsers where RealCID = 32736095
CREATE TABLE #mimoUsers
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT uc.RealCID
	 , uc.DateID
	 , uc.GlobalDeposited
	 , uc.GlobalFirstDeposited
	 , uc.GlobalFirstDepositDate
	 , uc.GlobalRedeposited
	 , uc.GlobalFTDA
	 , uc.GlobalCashedOut
	 , uc.Redeemed
	 , uc.DepositedTP
	 , uc.DepositedIBAN
	 , uc.DepositedOptions
	 , uc.ReDepositedTP
	 , uc.ReDepositedIBAN
	 , uc.ReDepositedOptions
	 , uc.TPFirstDeposited
	 , uc.IBANFirstDeposited
	 , uc.OptionsFirstDeposited
	 , uc.TPExternalFirstDeposited
	 , uc.TPFTDA
	 , uc.IBANFTDA
	 , uc.OptionsFTDA
	 , uc.TPExternalFTDA 
FROM #mimoUsersCoerced uc
UNION ALL 
SELECT unc.RealCID
	 , unc.DateID
	 , unc.GlobalDeposited
	 , unc.GlobalFirstDeposited
	 , unc.GlobalFirstDepositDate
	 , unc.GlobalRedeposited
	 , unc.GlobalFTDA
	 , unc.GlobalCashedOut
	 , unc.Redeemed
	 , unc.DepositedTP
	 , unc.DepositedIBAN
	 , unc.DepositedOptions
	 , unc.ReDepositedTP
	 , unc.ReDepositedIBAN
	 , unc.ReDepositedOptions
	 , unc.TPFirstDeposited
	 , unc.IBANFirstDeposited
	 , unc.OptionsFirstDeposited
	 , unc.TPExternalFirstDeposited
	 , unc.TPFTDA
	 , unc.IBANFTDA
	 , unc.OptionsFTDA
	 , unc.TPExternalFTDA 
FROM #mimoUsersNonCoerced unc



--- logged in data


IF OBJECT_ID('tempdb..#loggedIn') IS NOT NULL DROP TABLE #loggedIn -- select count(distinct RealCID) from #loggedIn where RealCID = 36187165 
CREATE TABLE #loggedIn
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT fca.RealCID
	, 1 AS LoggedIn
FROM DWH_dbo.Fact_CustomerAction fca
WHERE fca.DateID = @dateID
AND fca.ActionTypeID in (14)
GROUP BY fca.RealCID


--- depositors logged in

IF OBJECT_ID('tempdb..#depositorsLoggedIn') IS NOT NULL DROP TABLE #depositorsLoggedIn
CREATE TABLE #depositorsLoggedIn
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT
	li.RealCID
  , li.LoggedIn
  , CASE WHEN da.FirstDepositDateIDTP IS NOT NULL THEN 1 ELSE 0 END AS TPDepositor
  , CASE WHEN da.FirstDepositDateIDIBAN IS NOT NULL THEN 1 ELSE 0 END AS IBANDepositor
  , CASE WHEN da.RealCID IS NOT NULL THEN 1 ELSE 0 END as GlobalDepositor
FROM #loggedIn li
	LEFT JOIN #globalDepositorsAlltime da
		ON li.RealCID = da.RealCID


PRINT '#depositorsLoggedIn' + ' ' + cast(getdate() AS VARCHAR (20))

--- enrich with action based statuses


IF OBJECT_ID('tempdb..#enrichStatusActions') IS NOT NULL DROP TABLE #enrichStatusActions -- select * from #enrichStatusActions where RealCID = 45503380
CREATE TABLE #enrichStatusActions
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
as
SELECT
	s.RealCID
  , da.FirstDepositDateIDTP AS TP_FTD_DateID
  , da.FirstDepositDateTP AS TP_FTD_Date
  , da.FirstDepositAmountTP AS TP_FTDA
  , da.FirstDepositDateIDIBAN AS IBAN_FTD_DateID
  , da.FirstDepositDateIBAN AS IBAN_FTD_Date
  , da.FirstDepositAmountIBAN AS IBAN_FTDA
  , da.FirstDepositDateIDOptions AS Options_FTD_DateID
  , da.FirstDepositDateOptions AS Options_FTD_Date
  , da.FirstDepositAmountOptions AS Options_FTDA
  , da.FirstDepositDateIDMoneyFarm AS MoneyFarm_FTD_DateID
  , da.FirstDepositDateMoneyFarm AS MoneyFarm_FTD_Date
  , da.FirstDepositAmountMoneyFarm AS MoneyFarm_FTDA
  , da.MinFirstDepositDateID AS Global_FTD_DateID
  , da.MinFirstDepositDate  AS Global_FTD_Date
  , da.FirstDepositAmount AS Global_FTDA
  , da.IsDepositorGlobal
  , mu.GlobalDeposited
  , mu.GlobalFirstDeposited
  , mu.GlobalFirstDepositDate
  , mu.GlobalRedeposited
  , mu.GlobalCashedOut
  , mu.Redeemed
  , mu.DepositedTP
  , mu.DepositedIBAN
  , mu.DepositedOptions
  , mu.ReDepositedTP
  , mu.ReDepositedIBAN
  , mu.ReDepositedOptions
  , mu.TPFirstDeposited
  , mu.IBANFirstDeposited
  , mu.OptionsFirstDeposited
  , mu.TPExternalFirstDeposited
  , mu.TPFTDA
  , mu.IBANFTDA
  , mu.OptionsFTDA
  , mu.TPExternalFTDA AS TP_External_FTDA
----- trades etc
  , ISNULL (atr.ActiveTraded, 0) AS ActiveTraded
  , CASE WHEN bo.RealCID IS NOT NULL THEN 1 ELSE 0 END AS BalanceOnlyAccount
  , ISNULL (po.Portfolio_Only, 0) AS Portfolio_Only
  , CASE WHEN ISNULL (atr.ActiveTraded, 0)=1 OR ISNULL (po.Portfolio_Only, 0)=1 THEN 1 ELSE 0 END AS AccountActive
  , CASE WHEN i.RealCID IS NOT NULL THEN 1 ELSE 0 END AS AccountInActive
  , s.RegulationID
  , s.DesignatedRegulationID
  , s.PlayerStatusID
  , s.IsCreditReportValidCB
  , s.IsValidCustomer
  , s.AccountTypeID
  , s.CountryID
  , s.MifidCategorizationID
  , s.PlayerLevelID
  , s.IsDepositor
  , s.IsFunded
  , s.FirstTimeFunded
  , s.FirstFundedDateID
  , s.FirstActionType
  , s.FirstTradeDateID as FirstActionDateID
  , CASE WHEN li.RealCID IS NOT NULL THEN 1 ELSE 0 END AS LoggedIn
  , CASE WHEN isnull(li.TPDepositor,0) = 1 THEN 1 ELSE 0 END AS LoggedInTPDepositor
  , CASE WHEN isnull(li.IBANDepositor,0) = 1 THEN 1 ELSE 0 END AS LoggedInIBANDepositor
  , CASE WHEN isnull(li.GlobalDepositor,0) = 1 THEN 1 ELSE 0 END AS LoggedInGlobalDepositor
  , s.FirstIOBDateID 
  , s.FirstIOBTime
  , ROW_NUMBER () OVER (PARTITION BY s.RealCID ORDER BY s.RealCID) AS RN
FROM #basicStatuses s
	LEFT JOIN #activeTraders atr
		ON s.RealCID = atr.RealCID
	LEFT JOIN #balanceOnly bo
		ON s.RealCID = bo.RealCID
	LEFT JOIN #portfolioOnly po
		ON s.RealCID = po.RealCID
	LEFT JOIN #inactive i
		ON s.RealCID = i.RealCID
	LEFT JOIN #mimoUsers mu 
		ON s.RealCID = mu.RealCID
	LEFT JOIN #depositorsLoggedIn li
		ON s.RealCID = li.RealCID
	LEFT JOIN #globalDepositorsAlltime da
		ON s.RealCID = da.RealCID

PRINT '#enrichStatusActions' + ' ' + cast(getdate() AS VARCHAR (20))



/*----------------------------------------------------------
another manual intervention: since there are not always 
transactions in All MIMO (Apex data not arriving) only 
in GlobalFTD, need to coerce the OptionsFTD data here as well
----------------------------------------------------------*/


UPDATE #enrichStatusActions
SET GlobalDeposited = 1,
	GlobalFirstDeposited = 1, 
	GlobalFirstDepositDate = Options_FTD_Date,
	DepositedOptions = 1,
	OptionsFirstDeposited = 1,
	OptionsFTDA = Options_FTDA
WHERE Options_FTD_DateID = @dateID

DELETE FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status  WHERE DateID = @dateID -- select top 1 * from BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status where DateID = 20251109 and RealCID = 16846400

INSERT INTO BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status (
[Date]
,[DateID]
,[RealCID]
,[TP_FTD_DateID]
,[TP_FTD_Date]
,[TP_FTDA]
,[IBAN_FTD_DateID]
,[IBAN_FTD_Date]
,[IBAN_FTDA]
,[TP_External_FTDA]
,[Global_FTD_DateID]
,[Global_FTD_Date]
,[Global_FTDA]
,[IsDepositorGlobal]
,[GlobalDeposited]
,[GlobalFirstDeposited]
,[GlobalRedeposited]
,[GlobalCashedOut]
,[Redeemed]
,[DepositedTP]
,[DepositedIBAN]
,[ReDepositedTP]
,[ReDepositedIBAN]
,[TPFirstDeposited]
,[IBANFirstDeposited]
,[TPExternalFirstDeposited]
,[ActiveTraded]
,[BalanceOnlyAccount]
,[Portfolio_Only]
,[AccountActive]
,[AccountInActive]
,[RegulationID]
,[DesignatedRegulationID]
,[PlayerStatusID]
,[IsCreditReportValidCB]
,[IsValidCustomer]
,[AccountTypeID]
,[CountryID]
,[MarketingRegion]
,[MifidCategorizationID]
,[PlayerLevelID]
,[IsDepositor]
,[IsFunded]
,[FirstTimeFunded]
,[FirstFundedDateID]
,[FirstActionType]
,[FirstActionDateID]
,[LoggedIn]
,[LoggedInTPDepositor]
,[LoggedInIBANDepositor]
,[LoggedInGlobalDepositor]
,[UpdateDate]
,[FirstIOBDateID]
,[FirstIOBTime]
,[Options_FTD_DateID] 
,[Options_FTD_Date] 
,[Options_FTDA]
,[OptionsFirstDeposited]
,[DepositedOptions]
,[ReDepositedOptions] 
,[MoneyFarm_FTD_DateID]
,[MoneyFarm_FTD_Date]
,[MoneyFarm_FTDA]
,[MoneyFarmFirstDeposited]
)
--DECLARE @date DATE = '20250903'
--DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)
SELECT
    @date                                     AS [Date],
    @dateID                                   AS [DateID],
    sa.[RealCID]                              AS RealCID,
    sa.[TP_FTD_DateID]                        AS TP_FTD_DateID,
    sa.[TP_FTD_Date]                          AS TP_FTD_Date,
    sa.[TP_FTDA]                              AS TP_FTDA,
    sa.[IBAN_FTD_DateID]                      AS IBAN_FTD_DateID,
    sa.[IBAN_FTD_Date]                        AS IBAN_FTD_Date,
    sa.[IBAN_FTDA]                            AS IBAN_FTDA,
    sa.[TP_External_FTDA]                     AS TP_External_FTDA,
    sa.[Global_FTD_DateID]                    AS Global_FTD_DateID,
    sa.[Global_FTD_Date]                      AS Global_FTD_Date,
    sa.[Global_FTDA]                          AS Global_FTDA,
    ISNULL(sa.[IsDepositorGlobal],0)          AS IsDepositorGlobal,
    ISNULL(sa.[GlobalDeposited],0)            AS GlobalDeposited,
    ISNULL(sa.[GlobalFirstDeposited],0)       AS GlobalFirstDeposited,
    ISNULL(sa.[GlobalRedeposited],0)          AS GlobalRedeposited,
    ISNULL(sa.[GlobalCashedOut],0)            AS GlobalCashedOut,
    ISNULL(sa.[Redeemed],0)                   AS Redeemed,
    ISNULL(sa.[DepositedTP],0)                AS DepositedTP,
    ISNULL(sa.[DepositedIBAN],0)              AS DepositedIBAN,
    ISNULL(sa.[ReDepositedTP],0)              AS ReDepositedTP,
    ISNULL(sa.[ReDepositedIBAN],0)            AS ReDepositedIBAN,
    ISNULL(sa.[TPFirstDeposited],0)           AS TPFirstDeposited,
    ISNULL(sa.[IBANFirstDeposited],0)         AS IBANFirstDeposited,
    ISNULL(sa.[TPExternalFirstDeposited],0)   AS TPExternalFirstDeposited,
    ISNULL(sa.[ActiveTraded],0)               AS ActiveTraded,
    ISNULL(sa.[BalanceOnlyAccount],0)         AS BalanceOnlyAccount,
    ISNULL(sa.[Portfolio_Only],0)             AS Portfolio_Only,
    ISNULL(sa.[AccountActive],0)              AS AccountActive,
    ISNULL(sa.[AccountInActive],0)            AS AccountInActive,
    sa.[RegulationID]                         AS RegulationID,
    sa.[DesignatedRegulationID]               AS DesignatedRegulationID,
    sa.[PlayerStatusID]                       AS PlayerStatusID,
    sa.[IsCreditReportValidCB]                AS IsCreditReportValidCB,
    sa.[IsValidCustomer]                      AS IsValidCustomer,
    sa.[AccountTypeID]                        AS AccountTypeID,
    sa.[CountryID]                            AS CountryID,
    dc.MarketingRegionManualName              AS MarketingRegion,
    sa.[MifidCategorizationID]                AS MifidCategorizationID,
    sa.[PlayerLevelID]                        AS PlayerLevelID,
    ISNULL(sa.[IsDepositor],0)                AS IsDepositor,
    ISNULL(sa.[IsFunded],0)                   AS IsFunded,
    ISNULL(sa.[FirstTimeFunded],0)            AS FirstTimeFunded,
    ISNULL(sa.[FirstFundedDateID],30000101)   AS FirstFundedDateID,
    ISNULL(sa.[FirstActionType],'NoAction')   AS FirstActionType,
    ISNULL(sa.[FirstActionDateID],30000101)   AS FirstActionDateID,
    ISNULL(sa.[LoggedIn],0)                   AS LoggedIn,
    ISNULL(sa.[LoggedInTPDepositor],0)        AS LoggedInTPDepositor,
    ISNULL(sa.[LoggedInIBANDepositor],0)      AS LoggedInIBANDepositor,
    ISNULL(sa.[LoggedInGlobalDepositor],0)    AS LoggedInGlobalDepositor,
    GETDATE()                                 AS UpdateDate,
    sa.[FirstIOBDateID]                       AS FirstIOBDateID,
    sa.[FirstIOBTime]                         AS FirstIOBTime,
	[Options_FTD_DateID] ,
	[Options_FTD_Date] ,
	[Options_FTDA],
	ISNULL([OptionsFirstDeposited],0),
	ISNULL([DepositedOptions],0),
	ISNULL([ReDepositedOptions],0) ,
	[MoneyFarm_FTD_DateID],
	[MoneyFarm_FTD_Date],
	[MoneyFarm_FTDA],
	CASE WHEN [MoneyFarm_FTD_DateID] = @dateID THEN 1 ELSE 0 END AS [MoneyFarmFirstDeposited]
FROM #enrichStatusActions sa
JOIN DWH_dbo.Dim_Country dc
    ON sa.CountryID = dc.CountryID
WHERE RN = 1 -- rare production bugs can produce duplicate rows. 


/*----------------------------------------------------------------------
REQ-25250 - bad $1 FTD cohort depositor demotion
These RealCIDs made real $1 deposits so Dim_Customer.IsDepositor = 1, 
but business semantics say they are not depositors. Zero IsDepositor, 
IsDepositorGlobal, all FTD anchor columns and FirstDeposited flags on 
today's row (@dateID). Companion to the MIMO demotion already added 
under the same REQ-25250 in SP_DDR_Fact_Fact_MIMO_AllPlatforms.
The cohort definition mirrors the REMOVE_BAD_FTDS CTE in 
Function_MIMO_First_Deposit_All_Platforms and DBX's v_bad_ftd_cohort.
----------------------------------------------------------------------*/

IF OBJECT_ID('tempdb..#bad_ftd_cohort') IS NOT NULL DROP TABLE #bad_ftd_cohort
CREATE TABLE #bad_ftd_cohort
    WITH (HEAP, DISTRIBUTION = ROUND_ROBIN)
AS
WITH cohort_dates AS (
    SELECT CONVERT(DATE,'20250818',112) AS d UNION ALL
    SELECT CONVERT(DATE,'20250819',112)      UNION ALL
    SELECT CONVERT(DATE,'20250820',112)      UNION ALL
    SELECT CONVERT(DATE,'20260522',112)      UNION ALL
    SELECT CONVERT(DATE,'20260523',112)      UNION ALL
    SELECT CONVERT(DATE,'20260525',112)
),
upstream_deposits AS (
    SELECT fca.RealCID
    FROM   DWH_dbo.Fact_CustomerAction fca
    WHERE  fca.ActionTypeID IN (7, 44)
      AND  fca.RealCID IS NOT NULL
    UNION ALL
    SELECT mfts.CID AS RealCID
    FROM   eMoney_dbo.eMoney_Fact_Transaction_Status mfts
    WHERE  mfts.MoneyMoveDirection = 'MoneyIn'
      AND  mfts.TxStatusID = 2
      AND  mfts.TxTypeID IN (7, 14)
      AND  mfts.CID IS NOT NULL
),
multi_deposit_cids AS (
    SELECT RealCID FROM upstream_deposits GROUP BY RealCID HAVING COUNT(*) > 1
)
SELECT dc.RealCID
FROM   DWH_dbo.Dim_Customer dc
WHERE  CAST(dc.FirstDepositDate AS DATE) IN (SELECT d FROM cohort_dates)
  AND  dc.FirstDepositAmount = 1
  AND  NOT EXISTS (SELECT 1 FROM multi_deposit_cids m WHERE m.RealCID = dc.RealCID)

UPDATE cs
SET    IsDepositor              = 0,
       IsDepositorGlobal        = 0,

       IsFunded                 = 0,
       FirstTimeFunded          = 0,
       FirstFundedDateID        = NULL,

       TP_FTD_DateID            = NULL,
       TP_FTD_Date              = NULL,
       TP_FTDA                  = 0,
       TP_External_FTDA         = 0,
       IBAN_FTD_DateID          = NULL,
       IBAN_FTD_Date            = NULL,
       IBAN_FTDA                = 0,
       Options_FTD_DateID       = NULL,
       Options_FTD_Date         = NULL,
       Options_FTDA             = 0,
       MoneyFarm_FTD_DateID     = NULL,
       MoneyFarm_FTD_Date       = NULL,
       MoneyFarm_FTDA           = 0,
       Global_FTD_DateID        = 30000101,
       Global_FTD_Date          = NULL,
       Global_FTDA              = 0,
       GlobalFirstDeposited     = 0,
       TPFirstDeposited         = 0,
       IBANFirstDeposited       = 0,
       OptionsFirstDeposited    = 0,
       MoneyFarmFirstDeposited  = 0,
       TPExternalFirstDeposited = 0,
       LoggedInTPDepositor      = 0,
       LoggedInIBANDepositor    = 0,
       LoggedInGlobalDepositor  = 0,
       UpdateDate               = GETUTCDATE()
FROM   BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cs
INNER JOIN #bad_ftd_cohort bc ON cs.RealCID = bc.RealCID
WHERE  cs.DateID = @dateID

IF OBJECT_ID('tempdb..#bad_ftd_cohort') IS NOT NULL DROP TABLE #bad_ftd_cohort


END 