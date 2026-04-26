# BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions

## 1. Business Meaning

Daily reconciliation table comparing **eToro omnibus (netting) balances** against **aggregated client-side (Trading Platform) positions** at the instrument x hedge-server x liquidity-account level. Each row represents one instrument on one date for a specific hedge server and liquidity account, showing omnibus units/value alongside client-side units/equity broken down by validity and settlement flags, plus EOD pricing data and a reconciliation-relevance flag.

**Row grain**: One InstrumentID x HedgeServerID x LiquidityAccountID per Date

---

## 2. Business Logic

Created as part of the non-US settlement reconciliation pipeline, originally authored by Guy Manova (2023) and substantially reworked by Inessa Kontorovich (2025) to replace the Duco data source with direct netting-balance tables. The table enables Finance/Middle Office to compare what the omnibus broker accounts report (eToro-side) against the aggregated client positions (TP-side) for stocks and ETFs.

**Key business rules**:
- **Real stocks and ETFs only**: InstrumentTypeID IN (5,6). CFDs and crypto are excluded from the population but CFD client units appear in dedicated breakdown columns.
- **Omnibus vs. client-side**: The eToro_Units column comes from netting-balance data (omnibus broker view), while TP_Units* columns come from aggregated BI_DB_PositionPnL positions (client view). Discrepancies between the two sides flag potential reconciliation issues.
- **Validity breakdowns**: Client-side units and equity are split four ways: IsValidCustomer x IsSettled (Real vs CFD) and IsCreditReportValidCB x IsSettled (Real vs CFD).
- **Provider mapping**: Three-tier fallback: (1) per-instrument mapping from Karen/Inessa's active_hs_mappings file, (2) single-LA-per-hedge mapping, (3) single-provider-per-hedge fallback. Bank names: BNYMellon, Apex, IB, JPM, Saxo, IG, etc.
- **IsRelevantForRecon**: Business logic flag that marks rows as irrelevant (0) when a provider-hedge combination has zero credit-valid real units, preventing noise in reconciliation reports.
- **+1h balance**: eToro_Units_Plus1h captures the omnibus balance one hour after EOD to handle the "midnight bug" price anomalies.
- **Multi-table SP**: `SP_Finance_Non_US_Settlement_2025` writes to both this table and `BI_DB_Finance_Non_US_Settlement_New_2025` in one execution.
- **TotalStockMarginLoanIsCreditReportValid**: Added Feb 2026 by Markos Chris. Sum of stock margin loan values for credit-report-valid customers.

**Consumers**: No downstream Synapse SPs consume this table. Primary consumers are Tableau dashboards and ad-hoc Finance queries for omnibus reconciliation.

---

## 3. Query Advisory

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 37 |
| **Distribution** | HASH (InstrumentID) |
| **Clustered Index** | DateID ASC |

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date as YYYYMMDD integer, derived from SP @dt parameter via DateToDateID(). Clustered index column. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed from @dt) |
| 2 | Date | date | YES | Calendar date of the reconciliation snapshot, derived from SP @dt parameter. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, @date) |
| 3 | InstrumentID | int | YES | Instrument identifier. Distribution key. Resolved via ISNULL across client-side (#tp) and omnibus-side (#duco) to ensure coverage when one side has no data. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.InstrumentID) |
| 4 | InstrumentName | varchar(100) | YES | Internal instrument name with exchange suffix, e.g. "PHAR/USD", "FOX.RTH/USD", "MLX.ASX/AUD". From Dim_Instrument.Name. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.Name) |
| 5 | InstrumentDisplayName | varchar(200) | YES | Human-readable instrument display name, e.g. "Pharming Group NV", "Fox Corporation". From Dim_Instrument.InstrumentDisplayName. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.InstrumentDisplayName) |
| 6 | ISINCode | varchar(50) | YES | ISIN security identifier, e.g. "US71716E1055". From Dim_Instrument.ISINCode. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.ISINCode) |
| 7 | CUSIP | varchar(50) | YES | CUSIP security identifier for US instruments, e.g. "71716E105". NULL for non-US instruments. From Dim_Instrument.CUSIP. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.CUSIP) |
| 8 | Exchange | nvarchar(120) | YES | Exchange name, e.g. "Nasdaq", "NYSE", "Sydney", "Borsa Italiana". From Dim_Instrument.Exchange. Drives settlement-date logic (T+1 for NYSE/Nasdaq/TSX, T+2 for others). (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.Exchange) |
| 9 | HedgeServerID | int | YES | Hedge server identifier. Part of the row grain. Values include 12 (Apex), 500 (BNYMellon), 501 (BNYMellon EU), 503 (BNYMellon APAC), etc. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL.HedgeServerID) |
| 10 | Provider | nvarchar(120) | YES | Bank/broker provider name derived from three-tier mapping: (1) per-instrument Karen file, (2) single-LA-per-hedge, (3) single-provider-per-hedge. Values: BNYMellon, Apex, IB, JPM, Saxo, IG, VisionTraffix, UBS, Marex, GS, NA. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, #mapping.Provider) |
| 11 | LiquidityAccountID | nvarchar(64) | YES | Liquidity account identifier. Part of the row grain. Resolved via ISNULL across mapping sources and duco fallback. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, #mapping / #netting) |
| 12 | LiquidityAccountName | nvarchar(1200) | YES | Human-readable LA name, e.g. "Horizon OMS VIRTU1 - Unmanaged US Real 298393". From mapping tables or etoro_Trade_LiquidityAccounts. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, #mapping / etoro_Trade_LiquidityAccounts) |
| 13 | LiquidityProviderName | nvarchar(1200) | YES | Liquidity provider name from eToro hedge-server mapping, e.g. "OMS", "Trafix EXT", "Virtu". (Tier 2 -- SP_Finance_Non_US_Settlement_2025, etoro_Hedge_GetHedgeServerAccountMapping.LiquidityProviderName) |
| 14 | eToro_Units | float | YES | Omnibus-side EOD unit balance from netting table. ISNULL(Balance, 0). This is the broker/custodian view of how many units eToro holds. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, External_BI_OUTPUT_Finance_BI_DB_Hedge_NettingBalance.Balance) |
| 15 | eToroUSDAmount | float | YES | Legacy column from Duco integration. Now always NULL after the Oct 2025 switch to direct netting tables. Retained for schema compatibility. (Tier 3 -- SP_Finance_Non_US_Settlement_2025, hardcoded NULL) |
| 16 | eToroUSDByPriceUnspreaded | float | YES | Omnibus units valued in USD using the unspreaded EOD price. Computed: eToro_Units * Closing_Rate_Price_Unspreaded. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed) |
| 17 | TP_UnitsTotal | float | YES | Total client-side units across all validity/settlement segments. SUM(EOD_Units) from #output grouped by instrument x hedge server. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 18 | TP_UnitsIsValidCustomerReal | float | YES | Client-side units for valid customers with settled (real) positions. SUM where IsValidCustomer=1 AND IsSettled=1. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer) |
| 19 | TP_UnitsIsValidCustomerCFD | float | YES | Client-side units for valid customers with CFD (unsettled) positions. SUM where IsValidCustomer=1 AND IsSettled=0. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer) |
| 20 | TP_UnitsIsCreditReportValidReal | float | YES | Client-side units for credit-report-valid customers with settled (real) positions. SUM where IsCreditReportValidCB=1 AND IsSettled=1. Key column for reconciliation. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer) |
| 21 | TP_UnitsIsCreditReportValidCFD | float | YES | Client-side units for credit-report-valid customers with CFD (unsettled) positions. SUM where IsCreditReportValidCB=1 AND IsSettled=0. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer) |
| 22 | TP_EquityUSDTotal | float | YES | Total client-side equity in USD across all segments. SUM(EOD_Equity_USD) = SUM(Amount + PositionPnL). (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL.Amount + PositionPnL) |
| 23 | TP_EquityUSDIsValidCustomerReal | float | YES | Client-side equity USD for valid customers with real positions. SUM where IsValidCustomer=1 AND IsSettled=1. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer) |
| 24 | TP_EquityUSDIsValidCustomerCFD | float | YES | Client-side equity USD for valid customers with CFD positions. SUM where IsValidCustomer=1 AND IsSettled=0. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer) |
| 25 | TP_EquityUSDIsCreditReportValidReal | float | YES | Client-side equity USD for credit-report-valid customers with real positions. SUM where IsCreditReportValidCB=1 AND IsSettled=1. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer) |
| 26 | TP_EquityUSDIsCreditReportValidCFD | float | YES | Client-side equity USD for credit-report-valid customers with CFD positions. SUM where IsCreditReportValidCB=1 AND IsSettled=0. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Fact_SnapshotCustomer) |
| 27 | EOD_OrigCurr_BidSpreaded | float | YES | End-of-day bid price with spread in original instrument currency. MAX(BidSpreaded) from Fact_CurrencyPriceWithSplit for the date. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Fact_CurrencyPriceWithSplit.BidSpreaded) |
| 28 | EOD_OrigCurr_BidUnspreaded | float | YES | End-of-day bid price without spread in original instrument currency. MAX(Bid) from Fact_CurrencyPriceWithSplit for the date. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Fact_CurrencyPriceWithSplit.Bid) |
| 29 | USD_ConversionRate | float | YES | USD conversion rate for the instrument's sell currency. Most recent rate from Dim_GetSpreadedPriceUSDConversionRate. ISNULL(..., 1) defaults to 1 for USD-denominated instruments. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_GetSpreadedPriceUSDConversionRate.USD_ConversionRate) |
| 30 | EOD_PriceUSD_Spreaded | float | YES | EOD bid price with spread converted to USD. Computed: BidSpreaded * USD_ConversionRate. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed) |
| 31 | EOD_PriceUSD_Unspreaded | float | YES | EOD bid price without spread converted to USD. Computed: Bid * USD_ConversionRate. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed) |
| 32 | IsRelevantForRecon | int | YES | Reconciliation relevance flag. 0 when provider-hedge combination has zero credit-valid real units (noise suppression). 1 otherwise. CASE logic checks Provider IN (Saxo, Apex, BNYMellon, IB) against specific HedgeServerIDs. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed) |
| 33 | SellCurrency | varchar(50) | YES | Currency code of the instrument, e.g. "USD", "EUR", "GBP", "AUD". From Dim_Instrument.SellCurrency. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, Dim_Instrument.SellCurrency) |
| 34 | UpdateDate | datetime | NO | SP execution timestamp. GETDATE(). NOT NULL constraint in DDL. (Tier 3 -- SP_Finance_Non_US_Settlement_2025, GETDATE()) |
| 35 | eToro_Units_Plus1h | float | YES | Omnibus-side unit balance one hour after EOD. Added Oct 2025 to handle DailyLight / midnight-bug price anomalies. From NettingBalance.BalancePlus1h. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, External_BI_OUTPUT_Finance_BI_DB_Hedge_NettingBalance.BalancePlus1h) |
| 36 | eToroUSDPlus1hByPriceUnspreaded | float | YES | +1h omnibus units valued in USD using unspreaded EOD price. Computed: eToro_Units_Plus1h * Closing_Rate_Price_Unspreaded. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, computed) |
| 37 | TotalStockMarginLoanIsCreditReportValid | decimal(20,4) | YES | Total stock margin loan value for credit-report-valid customers. SUM where IsCreditReportValidCB=1. Added Feb 2026 by Markos Chris. Computed from InitForexRate * AmountInUnitsDecimal * CurrentConversionRate - Amount for leveraged settled positions. (Tier 2 -- SP_Finance_Non_US_Settlement_2025, BI_DB_PositionPnL / Dim_Position) |

---

## 5. Lineage

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary -- position amounts, units, PnL, hedge server (SQL-level dep) |
| Dim_Instrument | DWH_dbo | Instrument metadata, type filter, exchange, currency |
| Dim_Position | DWH_dbo | IsSettled, SettlementTypeID, leverage |
| Fact_SnapshotCustomer | DWH_dbo | IsValidCustomer, IsCreditReportValidCB, RegulationID |
| Fact_CurrencyPriceWithSplit | DWH_dbo | EOD bid prices (spreaded and unspreaded) |
| Dim_GetSpreadedPriceUSDConversionRate | DWH_dbo | USD conversion rates by currency |
| Dim_Regulation | DWH_dbo | Regulation name |
| Dim_Range | DWH_dbo | Date range resolution |
| Dim_Country | DWH_dbo | Country name |
| Dim_PlayerLevel | DWH_dbo | Player level |
| Dim_ExchangeInfo | DWH_dbo | Exchange description for calendar |
| External_bronze_calendardb_market_mergeddailyschedules | BI_DB_dbo | Exchange calendar (open days, close times) |
| External_BI_OUTPUT_Finance_BI_DB_Hedge_NettingBalance | BI_DB_dbo | Omnibus netting balances (EOD and +1h) |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LA name lookup |
| External_Fivetran_dealing_active_hs_mappings | Dealing_staging | LP-to-bank mapping |
| etoro_Hedge_GetHedgeServerAccountMapping | CopyFromLake | Hedge server to LA mapping |

### Sibling Tables (same SP writes)

| Table | Scope |
|-------|-------|
| BI_DB_Finance_Non_US_Settlement_New_2025 | Position-level settlement data with regulation, settlement date, close/current pricing |

### 5.2 ETL Pipeline

```
BI_DB_PositionPnL ──┐
Dim_Instrument ─────┤──→ #oneDayPnL ──→ #relPos2 ──→ #final
Dim_Position ───────┤                       ↑
Fact_SnapshotCustomer ──────────────────────┘
                                 ↓
                    #T1and2Open (T+1/T+2 settlement dates)
                                 ↓
                    #output (+ Provider/LA mapping)
                       ↓                     ↓
                    INSERT INTO           #tp (client agg)
                    BI_DB_Finance_            ↓
                    Non_US_Settlement   FULL OUTER JOIN
                    _New_2025               ↓
                                       #duco (omnibus)
                                            ↓
                                       #tp_omni
                                            ↓
                          #tp_omniprice (+ prices + recon flag)
                                            ↓
                          INSERT INTO BI_DB_Finance_eToro_vs_Positions
```

---

## 6. Relationships

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Finance_Non_US_Settlement_2025 |
| **ETL Pattern** | DELETE-INSERT by DateID |
| **Grain** | One InstrumentID x HedgeServerID x LiquidityAccountID per Date |
| **Schedule** | Daily (SB_Daily, Priority 0) |
| **Parameter** | @dt (date) |
| **Delete Scope** | `DELETE WHERE DateID = @dateID` |
| **History** | Accumulating daily snapshot |
| **Row Count** | ~10.4M rows (359 distinct dates, 2024-12-31 to 2026-04-11) |
| **UC Target** | _Not_Migrated |
| **Note** | SP also writes to BI_DB_Finance_Non_US_Settlement_New_2025. Execution logged via SP_ProcessStatusLog. |

---

## 7. Sample Queries

| Consideration | Guidance |
|--------------|---------|
| **Filter on DateID** | Clustered index on DateID ASC. Always include date filter for performance. |
| **Distribution on InstrumentID** | HASH distributed. Joins on InstrumentID will colocate; joins on HedgeServerID or Date will require data movement. |
| **eToro_Units vs TP_Units comparison** | The core reconciliation: compare eToro_Units (omnibus) against TP_UnitsIsCreditReportValidReal (client, credit-valid, real). Differences indicate reconciliation breaks. |
| **IsRelevantForRecon = 1 filter** | Apply to exclude noise rows where provider-hedge combinations have no credit-valid real positions. |
| **eToroUSDAmount is NULL** | Legacy Duco column. Use eToroUSDByPriceUnspreaded for USD valuation of omnibus units. |
| **+1h columns** | Use eToro_Units_Plus1h / eToroUSDPlus1hByPriceUnspreaded when investigating midnight-bug price anomalies. |

---

## 8. Atlassian Knowledge Sources

| Property | Value |
|----------|-------|
| **Domain** | Finance / Settlement Reconciliation |
| **Sub-domain** | Omnibus vs Client Position Reconciliation |
| **Sensitivity** | Financial position data -- no PII but commercially sensitive |
| **Owner** | Finance team (Guy Manova, Inessa Kontorovich) |
| **Quality Score** | 8.5 |

---

*Generated: 2026-04-26 | Quality: 8/10 | Phases: 14/14*
