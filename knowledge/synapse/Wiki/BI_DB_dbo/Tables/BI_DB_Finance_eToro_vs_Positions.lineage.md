# Column Lineage — BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions

**Writer SP**: `BI_DB_dbo.SP_Finance_Non_US_Settlement_2025` (Priority 0 — SB_Daily)
**ETL Pattern**: DELETE-INSERT by DateID (daily incremental)
**Population Filter**: InstrumentTypeID IN (5,6) = Real stocks & ETFs. Combines client-side position aggregation (#tp) with omnibus/netting-side balance (#duco) via FULL OUTER JOIN, then enriches with EOD prices and liquidity-provider mapping.

**Note**: This SP writes to 2 tables in one execution: `BI_DB_Finance_Non_US_Settlement_New_2025` (position-level settlement) and `BI_DB_Finance_eToro_vs_Positions` (omnibus-vs-client reconciliation).

---

## 5.2 ETL Pipeline

```
BI_DB_PositionPnL (bdppl) ──┐
Dim_Instrument (di) ────────┤──→ #oneDayPnL (position-level, stocks only)
                            ↓
Fact_SnapshotCustomer ──────┤
Dim_Position (dp) ──────────┤
Dim_Range (dr) ─────────────┤──→ #relPos2 (enriched with regulation, validity flags)
Dim_Country (dc) ───────────┤
Dim_PlayerLevel (dpl) ──────┤
Dim_Regulation (dr1) ───────┘
           ↓
   #final (GROUP BY InstrumentID × HedgeServerID, SUM units/equity)
           ↓
   #T1_US_Stocks (T+1 for NYSE/Nasdaq/TSX) ─────────┐
   #T2Open (T+2 for other exchanges) ───────────────┤──→ #T1and2Open (UNION ALL)
   External_bronze_calendardb (exchange calendar) ───┘
           ↓
   #output (enriched with Provider/LA mapping)
           ↓
   #tp (GROUP BY InstrumentID × HedgeServerID — client-side aggregation)
           ↓                                              ↓
External_BI_OUTPUT_Finance_BI_DB_Hedge_NettingBalance ──→ #netting ──→ #duco (omnibus-side)
etoro_Trade_LiquidityAccounts ──→ #LA_Name                ↓
External_Fivetran_dealing_active_hs_mappings ──→ #mapping  ↓
etoro_Hedge_GetHedgeServerAccountMapping ──→ #la ──→ #mapping
           ↓                                              ↓
   #tp_omni (FULL OUTER JOIN #tp × #duco)
           ↓
   #tp_omniprice (enriched with EOD prices, Provider fallback, IsRelevantForRecon)
           ↓
   INSERT INTO BI_DB_Finance_eToro_vs_Positions
```

---

## Source Tables

| Source | Schema | Role |
|--------|--------|------|
| BI_DB_PositionPnL | BI_DB_dbo | Position PnL, units, amounts, hedge server |
| Dim_Instrument | DWH_dbo | Instrument name, display name, ISIN, CUSIP, exchange, type filter, SellCurrency |
| Dim_Position | DWH_dbo | IsSettled, SettlementTypeID |
| Fact_SnapshotCustomer | DWH_dbo | Regulation, credit-report validity, IsValidCustomer |
| Dim_Regulation | DWH_dbo | Regulation name |
| Dim_Range | DWH_dbo | Date range resolution for snapshot |
| Dim_Country | DWH_dbo | Country (used in upstream filtering) |
| Dim_PlayerLevel | DWH_dbo | Player level (used in upstream filtering) |
| Fact_CurrencyPriceWithSplit | DWH_dbo | EOD bid prices (spreaded/unspreaded) |
| Dim_GetSpreadedPriceUSDConversionRate | DWH_dbo | USD conversion rates |
| External_bronze_calendardb_market_mergeddailyschedules | BI_DB_dbo | Exchange calendar for settlement date |
| Dim_ExchangeInfo | DWH_dbo | Exchange description for calendar join |
| External_BI_OUTPUT_Finance_BI_DB_Hedge_NettingBalance | BI_DB_dbo | Omnibus netting balance (EOD and +1h) |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LA name lookup |
| External_Fivetran_dealing_active_hs_mappings | Dealing_staging | LP-to-bank mapping (Karen/Inessa file) |
| etoro_Hedge_GetHedgeServerAccountMapping | CopyFromLake | Hedge-server-to-LA mapping from eToro DB |

---

## Column-Level Lineage

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| DateID | computed | @dateID | BI_DB_dbo.DateToDateID(@date). YYYYMMDD integer |
| Date | computed | @date | DATEADD(DAY,0,@dt) — SP input parameter |
| InstrumentID | Dim_Instrument (di) | InstrumentID | ISNULL(#tp.InstrumentID, #duco.InstrumentID). Grain key |
| InstrumentName | Dim_Instrument (di) | Name | Direct via #duco join. Format: "PHAR/USD", "FOX.RTH/USD" |
| InstrumentDisplayName | Dim_Instrument (di) | InstrumentDisplayName | Direct. Human-friendly name |
| ISINCode | Dim_Instrument (di) | ISINCode | Direct. ISIN standard identifier |
| CUSIP | Dim_Instrument (di) | CUSIP | Direct. US security identifier |
| Exchange | Dim_Instrument (di) / #tp_omni | Exchange | ISNULL(#tp.Exchange, #duco.Exchange). NYSE, Nasdaq, etc. |
| HedgeServerID | BI_DB_PositionPnL / #netting | HedgeServerID | ISNULL(#tp.HedgeServerID, #duco.HedgeServerID). Grain key |
| Provider | #mapping / #maphedge / #mappingonehedge | Provider | COALESCE(#mapping.Provider, #mappingoneLA.Provider, #mappingonehedge.Provider). Bank name: BNYMellon, Apex, IB, JPM, Saxo, etc. Fallback to ProviderDuco when NULL |
| LiquidityAccountID | #mapping / #la / #duco | LiquidityAccountID | ISNULL(#mapping.LiquidityAccountID, #mappingoneLA.LiquidityAccountID) with duco fallback |
| LiquidityAccountName | #mapping / #la / #duco | LiquidityAccountName | ISNULL(#mapping.LiquidityAccountName, #mappingoneLA.LiquidityAccountName) with duco fallback |
| LiquidityProviderName | #mapping / #la | LiquidityProviderName | ISNULL(#mapping.LiquidityProviderName, #mappingoneLA.LiquidityProviderName) |
| eToro_Units | #netting (NettingBalance) | Balance | ISNULL(#duco.eToro_Units, 0). Omnibus-side EOD unit balance |
| eToroUSDAmount | removed | NULL | Previously from Duco; now always NULL after netting table replacement |
| eToroUSDByPriceUnspreaded | computed | eToro_Units * Closing_Rate_Price_Unspreaded | Omnibus units valued at unspreaded EOD price in USD |
| TP_UnitsTotal | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM(EOD_Units) from #output grouped by instrument × hedge server |
| TP_UnitsIsValidCustomerReal | BI_DB_PositionPnL / Fact_SnapshotCustomer | EOD_Units | SUM where IsValidCustomer=1 AND IsSettled=1 |
| TP_UnitsIsValidCustomerCFD | BI_DB_PositionPnL / Fact_SnapshotCustomer | EOD_Units | SUM where IsValidCustomer=1 AND IsSettled=0 |
| TP_UnitsIsCreditReportValidReal | BI_DB_PositionPnL / Fact_SnapshotCustomer | EOD_Units | SUM where IsCreditReportValidCB=1 AND IsSettled=1 |
| TP_UnitsIsCreditReportValidCFD | BI_DB_PositionPnL / Fact_SnapshotCustomer | EOD_Units | SUM where IsCreditReportValidCB=1 AND IsSettled=0 |
| TP_EquityUSDTotal | BI_DB_PositionPnL | Amount + PositionPnL | SUM(EOD_Equity_USD) = SUM(Amount + PositionPnL) |
| TP_EquityUSDIsValidCustomerReal | BI_DB_PositionPnL / Fact_SnapshotCustomer | EOD_Equity_USD | SUM where IsValidCustomer=1 AND IsSettled=1 |
| TP_EquityUSDIsValidCustomerCFD | BI_DB_PositionPnL / Fact_SnapshotCustomer | EOD_Equity_USD | SUM where IsValidCustomer=1 AND IsSettled=0 |
| TP_EquityUSDIsCreditReportValidReal | BI_DB_PositionPnL / Fact_SnapshotCustomer | EOD_Equity_USD | SUM where IsCreditReportValidCB=1 AND IsSettled=1 |
| TP_EquityUSDIsCreditReportValidCFD | BI_DB_PositionPnL / Fact_SnapshotCustomer | EOD_Equity_USD | SUM where IsCreditReportValidCB=1 AND IsSettled=0 |
| EOD_OrigCurr_BidSpreaded | Fact_CurrencyPriceWithSplit | BidSpreaded | MAX(fcpws.BidSpreaded) for the OccurredDateID. Original currency |
| EOD_OrigCurr_BidUnspreaded | Fact_CurrencyPriceWithSplit | Bid | MAX(fcpws.Bid) for the OccurredDateID. Original currency |
| USD_ConversionRate | Dim_GetSpreadedPriceUSDConversionRate | USD_ConversionRate | Most recent conversion rate for the instrument's SellCurrencyID. ISNULL(...,1) |
| EOD_PriceUSD_Spreaded | computed | BidSpreaded * USD_ConversionRate | EOD spreaded price converted to USD |
| EOD_PriceUSD_Unspreaded | computed | Bid * USD_ConversionRate | EOD unspreaded price converted to USD |
| IsRelevantForRecon | computed | Provider + HedgeServerID logic | CASE: 0 when provider not in (Saxo,Apex,BNYMellon,IB) and no valid-customer real units; 0 for specific provider×hedge combos with no units; 1 otherwise |
| SellCurrency | Dim_Instrument (di) | SellCurrency | Direct. Currency code: USD, EUR, GBP, AUD, etc. |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| eToro_Units_Plus1h | #netting (NettingBalance) | BalancePlus1h | ISNULL(#duco.eToro_Units_Plus1h, 0). EOD+1h omnibus balance to handle DailyLight price anomalies |
| eToroUSDPlus1hByPriceUnspreaded | computed | eToro_Units_Plus1h * Closing_Rate_Price_Unspreaded | +1h omnibus units valued at unspreaded EOD price |
| TotalStockMarginLoanIsCreditReportValid | BI_DB_PositionPnL | TotalStockMarginLoan | SUM where IsCreditReportValidCB=1. Margin loan component for credit-valid customers. Added 2026-02 |
