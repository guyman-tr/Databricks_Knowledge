# BI_DB_dbo.BI_DB_DDR_Fact_AUM — Column Lineage

> Source-to-target column mapping from **`BI_DB_dbo.SP_DDR_Fact_AUM`** (@date DATE). Tier assignment in `.md` follows this file + upstream Synapse wikis (`Dim_Customer`, `BI_DB_Client_Balance_CID_Level_New`, `V_Liabilities`).

---

## PHASE 9 VERBATIM — Core SUM / Aggregations (#ClientBalance)

Taken verbatim from **`SP_DDR_Fact_AUM`** (temp table `#ClientBalance`):

```sql
SELECT cb.CID
     , cb.DateID
     , SUM(ISNULL(cb.Bonus,0)) Bonus
     , SUM(ISNULL(cb.realizedEquity ,0)) realizedEquity
     , SUM(ISNULL(cb.TotalLiability,0)) TotalLiability
     , SUM(ISNULL(cb.InProcessCashout,0)) InProcessCashout
     , SUM(ISNULL(cb.NOP ,0)) NOP
     , SUM(ISNULL(cb.NOPCrypto ,0)) NOPCrypto
     , SUM(ISNULL(cb.NOPCryptoCFD ,0)) NOPCryptoCFD
     , SUM(ISNULL(cb.NOPStocks ,0)) NOPStocks
     , SUM(ISNULL(cb.NOPStocksCFD ,0)) NOPStocksCFD
     , SUM(ISNULL(cb.TotalRealCryptoLoan ,0)) TotalRealCryptoLoan
     , SUM(ISNULL(cb.PositionPNL,0)) PositionPNL
     , SUM(ISNULL(cb.PositionAmount ,0)) PositionAmount
     , sum(ISNULL(TotalLiability,0) + ISNULL(cb.actualNWA,0)) AS TotalEquity
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New cb WITH (NOLOCK)
WHERE cb.DateID = @dateID
GROUP BY cb.CID, cb.DateID
```

---

## PHASE 9 VERBATIM — IBAN Balance (USD)

```sql
SELECT
	mcb.CID
  , sum(mcb.ClosingBalanceBO * mcb.USDApproxRate) AS USDBalance
FROM eMoney_dbo.eMoneyClientBalance mcb
WHERE mcb.BalanceDateID = @dateID
AND mcb.GCID IS NOT NULL
AND mcb.GCID <> 0
GROUP BY mcb.CID
```

---

## PHASE 9 VERBATIM — Copy / Stock / Crypto Compartments (#vl from V_Liabilities)

Taken verbatim from **`SP_DDR_Fact_AUM`** (temp table `#vl` sourcing `DWH_dbo.V_Liabilities vl`):

```sql
SELECT
   vl.CID  
 , isnull(vl.TotalMirrorCash				,0) as CashInCopy			
 , isnull(vl.TotalMirrorPositionsAmount		,0) as CopyInvestedAmount	
 , isnull(vl.TotalMirrorStockOrders			,0) as CopyStockOrders		
 , isnull(vl.CopyPositionPnL				,0) as CopyPositionPnL
 , isnull(vl.TotalMirrorCash				,0) 		
	+ isnull(vl.TotalMirrorPositionsAmount	,0) 
	+ isnull(vl.TotalMirrorStockOrders		,0) 		
	+ isnull(vl.CopyPositionPnL				,0) 	
	AS EquityCopy
 , isnull(vl.TotalMirrorPositionsAmount		,0) 
	+ isnull(vl.TotalMirrorStockOrders		,0) 		
	+ isnull(vl.CopyPositionPnL				,0) 	
	AS InvestedAmountCopy
 , isnull(vl.TotalStockPositionAmount				,0) as StockInvestedAmount			
 , isnull(vl.TotalStockOrders						,0) as StockOrders					
 , isnull(vl.StocksPositionPnL						,0) as StocksPositionPnL					
 , isnull(vl.TotalMirrorStockPositionAmount			,0) as MirrorStockInvestedAmount		
 , isnull(vl.MirrorStocksPositionPnL				,0) as MirrorStocksPositionPnL
 , isnull(vl.TotalStockPositionAmount				,0) 		
	+ isnull(vl.TotalStockOrders					,0) 				
	+ isnull(vl.StocksPositionPnL					,0) 				
	- isnull(vl.TotalMirrorStockPositionAmount		,0) 		
	- isnull(vl.MirrorStocksPositionPnL				,0) 
  AS EquityStocksManual
 , isnull(vl.TotalStockPositionAmount				,0) 		
	+ isnull(vl.TotalStockOrders					,0) 				
	- isnull(vl.TotalMirrorStockPositionAmount		,0) 		
  AS InvestedAmountStocksManual
 , isnull(vl.TotalCryptoManualPosition				,0) as CryptoManualInvestedAmount
 , isnull(vl.ManualCryptoPositionPnL				,0) as CryptoManualPositionPnL
 , isnull(vl.TotalCryptoManualPosition				,0) 
	+ isnull(vl.ManualCryptoPositionPnL				,0) 
  AS EquityCryptoManual
 , vl.TotalRealCrypto  
 , vl.TotalRealStocks  
 , vl.Credit  
 , vl.ActualNWA
FROM DWH_dbo.V_Liabilities vl WITH (NOLOCK)  
WHERE vl.DateID = @dateID
```

---

## PHASE 9 VERBATIM — Options TVF Invocation

```sql
DECLARE @OptionsMaxDate DATE = (SELECT max(cast(ProcessDate as DATE)) FROM BI_DB_dbo.External_Sodreconciliation_apex_EXT981_BuyPowerSummary)
DECLARE @OptionsMaxDateID INT = CAST(FORMAT(CAST(@OptionsMaxDate AS DATE),'yyyyMMdd') as INT)

SELECT distinct 
	   faop.RealCID
	 , ...
	 , faop.OptionsTotalEquity
FROM BI_DB_dbo.Function_AUM_OptionsPlatform(@OptionsMaxDateID, 0) faop
```

---

## PHASE 9 VERBATIM — Merge Keys & JOIN Shape (#equityPrep)

```sql
SELECT @dateID AS DateID
	 , COALESCE(cb.CID, i.CID, ob.RealCID) AS CID
	 ...
FROM #ClientBalance cb
LEFT JOIN #vl vl
	ON cb.CID = vl.CID
FULL OUTER JOIN #IBANbalance i
	ON cb.CID = i.CID
FULL outer JOIN #OptionsBalance ob
	ON COALESCE(cb.CID, i.CID) = ob.RealCID
```

---

## PHASE 9 VERBATIM — Global Totals (#final → target columns)

```sql
 , p.realizedEquity + p.IBANBalance AS RealizedEquityGlobal
 , p.TotalLiability + p.IBANBalance + p.OptionsTotalEquity AS TotalLiabilityGlobal
 , p.TotalEquity + p.IBANBalance + p.OptionsTotalEquity AS EquityGlobal
 , p.CreditTP + p.IBANBalance + p.OptionsCashEquity AS CreditGlobal
```

---

## PHASE 9 VERBATIM — Row Filter And UNION Supplement

Primary insert subset:

```sql
FROM #final f
WHERE NOT (f.EquityGlobal = 0)
```

Supplement UNION (deduplicates non-ALL):

```sql
FROM #final f
WHERE ISNULL(f.TotalLiabilityTP, 0) = 0 
   AND NOT (
		ISNULL(NOP,0) = 0 
		AND ISNULL(f.TotalPositionPNL,0) = 0 
		AND ISNULL(f.RealizedEquityTP,0) = 0 
		AND ISNULL(f.TotalLiabilityTP,0) = 0 
		AND ISNULL(f.InProcessCashout,0) = 0 
		AND ISNULL(f.TotalInvestedAmount,0) = 0 
		AND ISNULL(f.ActualNWA,0) = 0
		)
```

Post-insert cleanup:

```sql
DELETE FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM  WHERE DateID = @dateID AND RealCID IS null
```

---

## Source Objects

| Source | Type | Role in SP |
|--------|------|-------------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Table | `#ClientBalance` — TP balance, NOP, PnL, liability, bonuses (GROUP BY CID/DateID) |
| DWH_dbo.V_Liabilities | View | `#vl` — copy/manual stock/crypto compartments, Credit, ActualNWA, totals |
| eMoney_dbo.eMoneyClientBalance | Table | `#IBANbalance` — IBAN ClosingBalance × USDApproxRate |
| BI_DB_dbo.External_Sodreconciliation_apex_EXT981_BuyPowerSummary | External | MAX(ProcessDate) driver for `@OptionsMaxDateID` |
| BI_DB_dbo.Function_AUM_OptionsPlatform | TVF | `#OptionsBalance` — OptionsTotalEquity, OptionsCashEquity, OptionsPositionMarketValue |

---

## Column Lineage

| DWH Column | Source Table | Source Column / Expression | Transform | Notes |
|-----------|--------------|----------------------------|-----------|-------|
| RealCID | #equityPrep | COALESCE(cb.CID, i.CID, ob.RealCID) renamed in #final → RealCID | COALESCE/FULL OUTER merges | Matches `Dim_Customer.RealCID` semantics |
| DateID | SP | `@dateID` | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | Delete/reinsert partition key |
| Date | SP | `@date` | Literal pass-through on INSERT |
| RealizedEquityTP | BI_DB_Client_Balance_CID_Level_New | realizedEquity | SUM | Client Balance may carry 2 regulation rows/CID/date — summed here |
| TotalLiabilityTP | BI_DB_Client_Balance_CID_Level_New | TotalLiability | SUM | |
| InProcessCashout | BI_DB_Client_Balance_CID_Level_New | InProcessCashout | SUM | |
| NOP | BI_DB_Client_Balance_CID_Level_New | NOP | SUM | |
| NOPCrypto | BI_DB_Client_Balance_CID_Level_New | NOPCrypto | SUM | |
| NOPCryptoCFD | BI_DB_Client_Balance_CID_Level_New | NOPCryptoCFD | SUM | |
| NOPStocks | BI_DB_Client_Balance_CID_Level_New | NOPStocks | SUM | |
| NOPStocksCFD | BI_DB_Client_Balance_CID_Level_New | NOPStocksCFD | SUM | |
| TotalRealCryptoLoan | BI_DB_Client_Balance_CID_Level_New | TotalRealCryptoLoan | SUM | |
| TotalPositionPNL | BI_DB_Client_Balance_CID_Level_New | PositionPNL | SUM, rename alias | SP column PositionPNL → TotalPositionPNL |
| TotalInvestedAmount | BI_DB_Client_Balance_CID_Level_New | PositionAmount | SUM, rename alias | PositionAmount → TotalInvestedAmount |
| TotalEquityTP | BI_DB_Client_Balance_CID_Level_New | TotalLiability + actualNWA | SUM of per-row (TotalLiability+actualNWA) in `#ClientBalance` | Not the same formula as EquityGlobal |
| Bonus | BI_DB_Client_Balance_CID_Level_New | Bonus | SUM | |
| CashInCopy | DWH_dbo.V_Liabilities | TotalMirrorCash | Via #vl | |
| CopyInvestedAmount | DWH_dbo.V_Liabilities | TotalMirrorPositionsAmount | Via #vl | |
| CopyStockOrders | DWH_dbo.V_Liabilities | TotalMirrorStockOrders | Via #vl | |
| CopyPositionPnL | DWH_dbo.V_Liabilities | CopyPositionPnL | Via #vl | |
| EquityCopy | DWH_dbo.V_Liabilities | (see verbatim #vl SUM block) | ETL-defined in DDR SP | |
| InvestedAmountCopy | DWH_dbo.V_Liabilities | (see verbatim #vl SUM block) | ETL-defined in DDR SP | |
| StockInvestedAmount | DWH_dbo.V_Liabilities | TotalStockPositionAmount | Via #vl | |
| StockOrders | DWH_dbo.V_Liabilities | TotalStockOrders | Via #vl | Legacy often zero |
| StocksPositionPnL | DWH_dbo.V_Liabilities | StocksPositionPnL | Via #vl | |
| MirrorStockInvestedAmount | DWH_dbo.V_Liabilities | TotalMirrorStockPositionAmount | Via #vl | |
| MirrorStocksPositionPnL | DWH_dbo.V_Liabilities | MirrorStocksPositionPnL | Via #vl | |
| EquityStocksManual | DWH_dbo.V_Liabilities | (see verbatim #vl CASE/SUM expression) | ETL-defined in DDR SP | |
| InvestedAmountStocksManual | DWH_dbo.V_Liabilities | (see verbatim #vl SUM block) | ETL-defined in DDR SP | |
| InvestedAmountCryptoManual | DWH_dbo.V_Liabilities | TotalCryptoManualPosition | Via #vl, rename | VL: TotalCryptoPositionAmount − TotalMirrorCryptoPositionAmount |
| CryptoManualPositionPnL | DWH_dbo.V_Liabilities | ManualCryptoPositionPnL | Via #vl | |
| EquityCryptoManual | DWH_dbo.V_Liabilities | (see verbatim #vl SUM block) | ETL-defined in DDR SP | |
| TotalRealCrypto | DWH_dbo.V_Liabilities | TotalRealCrypto | Via #vl | |
| TotalRealStocks | DWH_dbo.V_Liabilities | TotalRealStocks | Via #vl | |
| CreditTP | DWH_dbo.V_Liabilities | Credit | Via #vl, rename Credit → CreditTP | |
| ActualNWA | DWH_dbo.V_Liabilities | ActualNWA | Via #vl — view-computed CASE on NetEquity vs BonusCredit | See `V_Liabilities.md §2.2` |
| IBANBalance | eMoneyClientBalance | ClosingBalanceBO * USDApproxRate | SUM grouped by CID | USD-approx FX |
| RealizedEquityGlobal | Multi | realizedEquity + IBANBalance | Verbatim `#final` | SP comment excludes Options split |
| TotalLiabilityGlobal | Multi | TotalLiability + IBANBalance + OptionsTotalEquity | Verbatim `#final` | |
| EquityGlobal | Multi | TotalEquity + IBANBalance + OptionsTotalEquity | Verbatim `#final` | Primary **DDR AUM rollup** denominator for filters |
| CreditGlobal | Multi | CreditTP + IBANBalance + OptionsCashEquity | Verbatim `#final` | Options **cash** leg only |
| UpdateDate | SP | GETDATE() | Snapshot at INSERT | |
| OptionsTotalEquity | Function_AUM_OptionsPlatform | OptionsTotalEquity | TVF @ `@OptionsMaxDateID` — not `@dateID` directly | Apex buy-power lineage inside function |

---

## Lineage Chain (Abbreviated)

```
BI_DB_Client_Balance_CID_Level_New + V_Liabilities + eMoneyClientBalance
  → SP_DDR_Fact_AUM(#ClientBalance #vl #IBANbalance)
  → FULL OUTER + Function_AUM_OptionsPlatform
  → #final global USD measures
  → DELETE/INSERT BI_DB_DDR_Fact_AUM
Generic Pipeline (+ lake export)
  → main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum (UC Gold)
```
