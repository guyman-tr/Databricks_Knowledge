-- sp_executesql wrapper
EXEC sp_executesql N'ALTER PROC [BI_DB_dbo].[SP_DDR_Fact_Fact_MIMO_AllPlatforms] @date [DATE] AS 
     
/********************************************************************************************      
Author:      Guy Manova       
Date:        2024-07-02      
Description: creates a granular fact table of daily MIMO transactions on all platforms (currently
			eMoney and 
			Platform), and indicated whether an FTD is local to the platform 
			or global accross platforms
      
**************************      
** Change History      
**************************      

Date         Author       Description       
      
2025-03-17		Guy M			added isC2F		
2025-05-06		Guy M			added isrecurring
2025-06-16		Guy M			fixed the IsIBANTrade hardcoded 0, and added IsIBANQuickTransfer (moneymovereason = 6) - new feature called Internal Transfer in emoney 
								(internal transfer means something else in TP, so IsIBANQuickTransfer)
2025-09-04		Guy M			coalesced the new global FTD dim_customer data to override the current in cases they dont match. 
2025-09-30		Guy M			left over some hard coded date causing empty dataset
2025-10-06		Guy M			add the Options platform mimo. note - this is best effort, no dependencies, as this data is not reliably ready daily. also changed the final join 
								to global FTDs from depositid (RnD data removes C2F from FTD) and to deal with multiple identical timestamps where the Rownumber failed. 
								example CIDs: 45250268, 8264379
2025-10-23		Guy M			added update code to recover FTDs not showing properly from dim customer (came in later than run date) 
2025-10-30		Guy M			hot fix to solve the options string transactionid
2025-11-18		Guy M			add moneyfarm
2025-11-21		Guy M			hotfix for string join crap
2025-12-04		Guy M			added IsCryptoToFiat indicator for TP crypto2usd - for the whole population daily so we dont have to chase history	
2025-12-07		Guy M			replace nulls for merge keys to work in lake	
2025-12-22		Guy M			replace nulls for options platform - missed that one previously	
2026-06-01		Guy M			apply REMOVE_BAD_FTDS filter to both recovery UPDATEs (eMoney + TP) so they don''t re-introduce the $1 synthetic
								FTD cohort (2025-08-18/19/20 + 2026-05-22/23/25). Mirrors the predicate already in 
								Function_MIMO_First_Deposit_All_Platforms (PR #3850). Un-blacklist via HAVING COUNT > 1 kept identical.
----------    ----------   ------------------------------------*/      

-- exec BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms ''20251119''

Begin

-- DECLARE @date DATE = ''20251201''
DECLARE @dateID int =CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)

IF OBJECT_ID(''tempdb..#ibans'') IS NOT NULL DROP TABLE #ibans 
CREATE TABLE #ibans
    WITH (HEAP,DISTRIBUTION = ROUND_ROBIN)
AS
SELECT RealCID FROM DWH_dbo.Dim_Customer dc WHERE dc.FirstDepositDate between @date AND dateadd(DAY,1,@date) AND dc.FTDPlatformID = 3 


-- global FTDs

IF OBJECT_ID(''tempdb..#globalFTDs'') IS NOT NULL DROP TABLE #globalFTDs 
CREATE TABLE #globalFTDs												
    WITH (HEAP,DISTRIBUTION = HASH (DepositID))
AS
SELECT *
FROM BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0) fmfdap




-- Trading Platform MIMO

IF OBJECT_ID(''tempdb..#TP_Mimo'') IS NOT NULL DROP TABLE  #TP_Mimo
CREATE TABLE #TP_Mimo												
    WITH (HEAP,DISTRIBUTION = ROUND_ROBIN)
as
SELECT *, 1 AS FTDPlatformID
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform bddfmtp
WHERE bddfmtp.DateID = @dateID


-- eMoney Platform MIMO


IF OBJECT_ID(''tempdb..#IBAN_Mimo'') IS NOT NULL DROP TABLE #IBAN_Mimo 
CREATE TABLE #IBAN_Mimo
    WITH (HEAP,DISTRIBUTION = ROUND_ROBIN)
as
SELECT *, 3 AS FTDPlatformID 
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform bddfmi 
WHERE bddfmi.DateID = @dateID




-- unified mimo

IF OBJECT_ID(''tempdb..#globalMIMO'') IS NOT NULL DROP TABLE #globalMIMO  -- select * from #globalMIMO where MIMOPlatform = ''eMoney''
CREATE TABLE #globalMIMO												
    WITH (HEAP,DISTRIBUTION = HASH(TransactionID))						
AS																		
SELECT tm.DateID
	 , tm.RealCID
	 , tm.MIMOAction
	 , tm.OrigIdentifier
	 , tm.TransactionID
	 , tm.AmountUSD
	 , tm.AmountOrigCurrency
	 , tm.FundingTypeID
	 , tm.CurrencyID
	 , tm.Currency
	 , tm.IsFTD
	 , tm.IsInternalTransfer
	 , tm.IsRedeem
	 , tm.IsIBANTrade
	 , ''TradingPlatform'' AS MIMOPlatform
	 , tm.IsCryptoToFiat
	 , tm.IsRecurring
	 , tm.IsIBANQuickTransfer
	 , tm.FTDPlatformID
FROM #TP_Mimo tm 
UNION ALL									
SELECT im.DateID							
	 , im.RealCID							
	 , im.MIMOAction						
	 , im.OrigIdentifier					
	 , im.TransactionID
	 , im.AmountUSD
	 , im.AmountOrigCurrency
	 , im.FundingTypeID
	 , im.CurrencyID
	 , im.Currency
	 , im.IsFTD
	 , im.IsInternalTransfer
	 , im.IsRedeem
	 , im.IsTradeFromIBAN
	 , ''eMoney'' AS MIMOPlatform
	 , im.IsCryptoToFiat
	 , im.IsRecurring
	 , im.IsIBANQuickTransfer
	 , im.FTDPlatformID
FROM #IBAN_Mimo im


-- add global FTD

IF OBJECT_ID(''tempdb..#final'') IS NOT NULL DROP TABLE #final -- select * from #final where TransactionID like ''%O%''
CREATE TABLE #final
    WITH (HEAP,DISTRIBUTION = ROUND_ROBIN)
AS
SELECT m.DateID
	 , m.RealCID
	 , m.MIMOAction
	 , m.OrigIdentifier
	 , m.TransactionID
	 , m.AmountUSD
	 , m.AmountOrigCurrency
	 , m.FundingTypeID
	 , m.CurrencyID
	 , m.Currency
	 , m.IsFTD AS IsPlatformFTD
	 , m.IsInternalTransfer
	 , m.IsRedeem
	 , m.IsIBANTrade
	 , m.MIMOPlatform
	 , CASE WHEN f.RealCID IS NOT NULL THEN 1 ELSE 0 END AS IsGlobalFTD
	 , m.IsCryptoToFiat
	 , m.IsRecurring
	 , m.IsIBANQuickTransfer
	 , f.DepositID
FROM #globalMIMO m 
	LEFT JOIN #globalFTDs f 
		ON m.MIMOAction = ''Deposit''
			 AND m.RealCID = f.RealCID AND m.IsFTD = 1 
			 AND m.FTDPlatformID = f.FTDPlatformID

UPDATE #final
SET TransactionID = NULL 
WHERE MIMOPlatform = ''Options''

DECLARE @updatedate DATETIME = GETDATE()

DELETE FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms WHERE DateID = @dateID 

INSERT INTO BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms (
	   DateID
	 , [Date]
	 , RealCID
	 , MIMOAction
	 , OrigIdentifier
	 , TransactionID
	 , AmountUSD
	 , AmountOrigCurrency
	 , FundingTypeID
	 , CurrencyID
	 , Currency
	 , IsPlatformFTD
	 , IsInternalTransfer
	 , IsRedeem
	 , IsTradeFromIBAN
	 , MIMOPlatform
	 , IsGlobalFTD
	 , UpdateDate
	 , IsCryptoToFiat
	 , IsRecurring
	 , IsIBANQuickTransfer
)
SELECT f.DateID
     , @date AS [Date]
	 , f.RealCID
	 , f.MIMOAction
	 , f.OrigIdentifier
	 , cast(f.TransactionID AS VARCHAR (50)) AS TransactionID
	 , f.AmountUSD
	 , f.AmountOrigCurrency
	 , f.FundingTypeID
	 , f.CurrencyID
	 , f.Currency
	 , ISNULL(f.IsPlatformFTD,0)
	 , ISNULL(f.IsInternalTransfer,0)
	 , ISNULL(f.IsRedeem,0)
	 , ISNULL(f.IsIBANTrade,0)
	 , f.MIMOPlatform
	 , ISNULL(f.IsGlobalFTD,0)
	 , @updatedate AS UpdateDate
	 , ISNULL(f.IsCryptoToFiat,0)
	 , ISNULL(f.IsRecurring,0)
	 , ISNULL(f.IsIBANQuickTransfer,0)
FROM #final f -- select * from #final where MIMOPlatform = ''eMoney''

/*----------------------------------------------------------------------------------
add Options (Gatsby) MIMO - this data is not reliably ready every day at DDR send times
so its deleted and added daily in its entirety - its a small dataset. 
------------------------------------------------------------------------------------*/



DELETE FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms WHERE MIMOPlatform = ''Options''

INSERT INTO BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms (
	   DateID
	 , [Date]
	 , RealCID
	 , MIMOAction
	 , OrigIdentifier
	 , TransactionID
	 , AmountUSD
	 , AmountOrigCurrency
	 , FundingTypeID
	 , CurrencyID
	 , Currency
	 , IsPlatformFTD
	 , IsInternalTransfer
	 , IsRedeem
	 , IsTradeFromIBAN
	 , MIMOPlatform
	 , IsGlobalFTD
	 , UpdateDate
	 , IsCryptoToFiat
	 , IsRecurring
	 , IsIBANQuickTransfer

) 
SELECT bddfmop.DateID
	 , bddfmop.Date
	 , bddfmop.RealCID
	 , bddfmop.MIMOAction
	 , bddfmop.OrigIdentifier
	 , 0 AS TransactionID -- cannot use the varchar it will break current schemas on move to lake. 
	 , bddfmop.AmountUSD
	 , bddfmop.AmountOrigCurrency
	 , bddfmop.FundingTypeID
	 , bddfmop.CurrencyID
	 , bddfmop.Currency
	 , bddfmop.IsFTD AS IsPlatformFTD
	 , bddfmop.IsInternalTransfer
	 , 0
	 , 0 
	 , ''Options'' AS MIMOPlatform
	 , bddfmop.IsGlobalFTD
	 , @updatedate AS UpdateDate
	 , 0
	 , 0 
	 , 0
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform bddfmop

/*----------------------------------------------------------------------------------
add moneyfarm - only for the purpose of counting FTDS from this table
non FTD mimo is not here at present. 
------------------------------------------------------------------------------------*/

IF OBJECT_ID(''tempdb..#moneyfarmFTDs'') IS NOT NULL DROP TABLE #moneyfarmFTDs
CREATE TABLE #moneyfarmFTDs
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT CAST(FORMAT(CAST(gf.FirstDepositDate AS DATE),''yyyyMMdd'') as INT) as DateID
	 , cast(gf.FirstDepositDate AS DATE) as [Date]
	 , gf.RealCID
	 , ''Deposit'' AS MIMOAction
	 , ''DepositID'' AS OrigIdentifier
	 , 0 AS TransactionID -- cannot use the varchar it will break current schemas on move to lake. 
	 , gf.FirstDepositAmount AS AmountUSD
	 , -1 AS AmountOrigCurrency
	 , -1 AS FundingTypeID
	 , 3 AS CurrencyID
	 , ''GBP'' AS Currency
	 , 1 AS IsPlatformFTD
	 , 0 AS IsInternalTransfer
	 , 0 AS IsRedeem
	 , 0 IsTradeFromIBAN
	 , ''MoneyFarm'' AS MIMOPlatform
	 , 1 AS IsGlobalFTD
	 , @updatedate AS UpdateDate
	 , 0 AS IsCryptoToFiat
	 , 0 AS IsRecurring 
	 , 0 AS IsIBANQuickTransfer
FROM #globalFTDs gf
WHERE gf.FTDPlatform = ''MoneyFarm''

DELETE FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms WHERE MIMOPlatform = ''MoneyFarm''

INSERT INTO BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms (
 DateID
	 , [Date]
	 , RealCID
	 , MIMOAction
	 , OrigIdentifier
	 , TransactionID
	 , AmountUSD
	 , AmountOrigCurrency
	 , FundingTypeID
	 , CurrencyID
	 , Currency
	 , IsPlatformFTD
	 , IsInternalTransfer
	 , IsRedeem
	 , IsTradeFromIBAN
	 , MIMOPlatform
	 , IsGlobalFTD
	 , UpdateDate
	 , IsCryptoToFiat
	 , IsRecurring
	 , IsIBANQuickTransfer
) 
SELECT  DateID
	 , [Date]
	 , RealCID
	 , MIMOAction
	 , OrigIdentifier
	 , isnull(TransactionID			,-1) 
	 , AmountUSD
	 , AmountOrigCurrency
	 , FundingTypeID
	 , CurrencyID
	 , Currency
	 , isnull(IsPlatformFTD			,0) 
	 , isnull(IsInternalTransfer	,0) 
	 , isnull(IsRedeem				,0) 
	 , isnull(IsTradeFromIBAN		,0) 
	 , MIMOPlatform
	 , isnull(IsGlobalFTD			,0) 
	 , UpdateDate
	 , isnull(IsCryptoToFiat		,0) 
	 , isnull(IsRecurring			,0) 
	 , isnull(IsIBANQuickTransfer	,0) 
FROM #moneyfarmFTDs


/*----------------------------------------------------------------
one time update of recovered FTDs from dimcustomer which 
do not appear as FTDs in the mimo table (this is due 
to the move to global FTD which do not always appear same day
as the transaction actually took place
-----------------------------------------------------------------*/



-- eMoney recovery UPDATE: re-flag IsPlatformFTD/IsGlobalFTD for late-arriving DimCustomer-driven FTDs.
-- 2026-06-01: added REMOVE_BAD_FTDS filter to prevent $1 synthetic cohort (2025-08-18/19/20 + 2026-05-22/23/25)
-- from being re-introduced after the TVF already excluded them. Un-blacklist via HAVING COUNT > 1 preserved.
 UPDATE  t1
 SET 
 t1.IsPlatformFTD = 1,
 IsGlobalFTD = 1
 FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms t1
 INNER JOIN eMoney_dbo.eMoney_Fact_Transaction_Status t2
	ON t1.RealCID = t2.CID
		AND t1.TransactionID = t2.TransactionID AND t2.TxTypeID IN (7,14) AND t2.TxStatusID = 2
 INNER JOIN DWH_dbo.Dim_Customer t3
	 ON t2.CID = t3.RealCID
		AND t3.FTDPlatformID = 3
		AND cast(t2.SourceCugTransactionID AS VARCHAR(100)) = t3.FTDTransactionID
WHERE (t1.IsPlatformFTD = 0 OR t1.IsGlobalFTD = 0)
AND t1.MIMOPlatform = ''eMoney''
AND t1.MIMOAction = ''Deposit''
AND t1.DateID >= 20250901
AND t3.FTDPlatformID = 3
AND t3.RealCID NOT IN (
    SELECT dc.RealCID
    FROM DWH_dbo.Dim_Customer dc
    WHERE CAST(dc.FirstDepositDate AS DATE) IN (
              CONVERT(DATE, ''20250818'', 112),
              CONVERT(DATE, ''20250819'', 112),
              CONVERT(DATE, ''20250820'', 112),
              CONVERT(DATE, ''20260522'', 112),
              CONVERT(DATE, ''20260523'', 112),
              CONVERT(DATE, ''20260525'', 112)
          )
      AND dc.FirstDepositAmount = 1
      AND dc.RealCID NOT IN (
              SELECT map.RealCID
              FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
              WHERE map.MIMOAction = ''Deposit''
              GROUP BY map.RealCID
              HAVING COUNT(map.RealCID) > 1
          )
)


-- TP recovery UPDATE: same fix as the eMoney leg above.
-- This is the leg that re-introduced the 17,236 5/22 cohort rows after the TVF was patched in PR #3850.
 UPDATE  t1
 SET 
 t1.IsPlatformFTD = 1,
 IsGlobalFTD = 1
 FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms t1
 INNER JOIN 
	(SELECT RealCID, dc.FTDTransactionID
	FROM  DWH_dbo.Dim_Customer dc
	 WHERE dc.FTDPlatformID = 1
	) t3
		on cast(t1.TransactionID AS VARCHAR(100)) = t3.FTDTransactionID
WHERE (t1.IsPlatformFTD = 0 OR t1.IsGlobalFTD = 0)
AND t1.MIMOPlatform = ''TradingPlatform''
AND t1.MIMOAction = ''Deposit''
AND t1.DateID >= 20250901
AND t3.RealCID NOT IN (
    SELECT dc.RealCID
    FROM DWH_dbo.Dim_Customer dc
    WHERE CAST(dc.FirstDepositDate AS DATE) IN (
              CONVERT(DATE, ''20250818'', 112),
              CONVERT(DATE, ''20250819'', 112),
              CONVERT(DATE, ''20250820'', 112),
              CONVERT(DATE, ''20260522'', 112),
              CONVERT(DATE, ''20260523'', 112),
              CONVERT(DATE, ''20260525'', 112)
          )
      AND dc.FirstDepositAmount = 1
      AND dc.RealCID NOT IN (
              SELECT map.RealCID
              FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms map
              WHERE map.MIMOAction = ''Deposit''
              GROUP BY map.RealCID
              HAVING COUNT(map.RealCID) > 1
          )
)

-- update C2USD

UPDATE BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms
SET IsCryptoToFiat = 1
WHERE DateID >= 20250701
AND MIMOPlatform = ''TradingPlatform''
AND MIMOAction = ''Deposit''
AND FundingTypeID = 27

------------------------------------------------------------------

END 

'