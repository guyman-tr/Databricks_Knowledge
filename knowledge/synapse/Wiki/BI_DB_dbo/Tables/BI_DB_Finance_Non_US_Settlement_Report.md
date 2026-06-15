# BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_Report

## 1. Overview

Instrument- and hedge-server-level **non-US settled real stock** snapshot for finance reconciliation. Each row is one instrument on one report date for one liquidity-provider (hedge server) bucket, with client holdings in units and USD split by regulator (ASIC, CySEC, FCA, GAML, Seychelles, FinCEN/FINRA). Custodian-side measures are retained in the schema but are populated as zero after LP-side logic was removed (April 2022).

**Row grain**: One InstrumentID × ProviderID (HedgeServerID) × ReportDate × IsSettled slice (with Country, PlayerLevel, IsGermanBaFin carried for Tableau filters)

---

## 2. Business Context

Authored by Guy Manova (March 2020). Originally de-aggregated SettlementDB_Real for custodian vs client comparison; as of **2022-04-06** all LP (custodian) sourcing was removed -- the pipeline now builds entirely from `BI_DB_PositionPnL` and related dimensions, while preserving the legacy column layout for downstream dashboards.

**Key business rules**:
- **Real stocks only**: `InstrumentTypeID IN (5,6)` and `pl.IsSettled = 1` in `#relPos2`.
- **Non-US customers**: `Fact_SnapshotCustomer.RegulationID NOT IN (6,7,8)` and `IsCreditReportValidCB = 1`.
- **Gap_Type**: In the current procedure, set to literal `'NA'` in `#finalPrep` (placeholder after custodian gap logic was retired).
- **Custodian columns** (`Total_Custodian_*`, `Custodian_vs_Client_*`): Inserted as **0** in `#dailyV_ClientsPositions_HistoryCurrency` -- kept for Tableau compatibility, not live LP data.
- **Prices**: Bid from `Fact_CurrencyPriceWithSplit`, converted to USD using `#usdConversion` from `Dim_GetSpreadedPriceUSDConversionRate`.
- **Multi-table SP**: Same execution as `BI_DB_CIDLevel_Settlement_Report` and the two GAML position reports.

**Consumers**: Tableau finance settlement / reconciliation workbooks.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 33 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | ReportDate ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Gap_Type | nvarchar | YES | Settlement gap category. Current SP assigns constant `'NA'` in `#finalPrep` after removal of LP-side gap detection. (Tier 2 -SP_Finance_Non_US_Settlement_Report, #finalPrep.Gap_Type) |
| 2 | ProviderID | int | YES | Hedge server identifier carried as provider key from `#relPos2` aggregation (`HedgeServerID` as `ProviderID` in `#dailyV_ClientsPositions_HistoryCurrency`). (Tier 2 -SP_Finance_Non_US_Settlement_Report, #relPos1.HedgeServerID) |
| 3 | Provider | varchar(100) | YES | Provider label from static `#hedgeServers` mapping (e.g. IG, BNYMellon, Saxo, IB, Apex, JPM). (Tier 2 -SP_Finance_Non_US_Settlement_Report, #hedgeServers.Provider) |
| 4 | InstrumentID | int | YES | Instrument key from position data. (Tier 2 -SP_Finance_Non_US_Settlement_Report, #relPos2.InstrumentID) |
| 5 | Instrument_Name | nvarchar | YES | Display name from `Dim_Instrument.InstrumentDisplayName` in `#joined`. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Instrument.InstrumentDisplayName) |
| 6 | ReportDate | int | YES | Report date as YYYYMMDD `DateID`; matches SP `@dateID`. Clustered index leading column. (Tier 2 -SP_Finance_Non_US_Settlement_Report, @dateID) |
| 7 | ISINCode | nvarchar | YES | ISIN from `Dim_Instrument`. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Instrument.ISINCode) |
| 8 | Symbol | nvarchar | YES | Trading symbol from `Dim_Instrument`. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Instrument.Symbol) |
| 9 | Closing_Rate_Price_Unspreaded | money | YES | End-of-day bid in USD (unspreaded), from `#prices`: `Fact_CurrencyPriceWithSplit.Bid` × USD conversion. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Fact_CurrencyPriceWithSplit.Bid) |
| 10 | Closing_Rate_Price_Spreaded | money | YES | End-of-day bid in USD (spreaded), from `#prices`: `BidSpreaded` × USD conversion. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Fact_CurrencyPriceWithSplit.BidSpreaded) |
| 11 | Total_Client_Holdings_In_Units | money | YES | Sum of client units (`Units`) for the instrument × hedge server × date from `#relPos` (named `InstrumentInventory` in temp pipeline). (Tier 2 -SP_Finance_Non_US_Settlement_Report, SUM(#relPos1.Units)) |
| 12 | Total_Custodian_Settled_Positions_In_Units | money | YES | Legacy custodian units; **0** in current build (LP path removed). (Tier 2 -SP_Finance_Non_US_Settlement_Report, literal 0) |
| 13 | Custodian_vs_Client_Holdings_Difference_In_units | money | YES | Legacy unit difference; **0** in current build. (Tier 2 -SP_Finance_Non_US_Settlement_Report, literal 0) |
| 14 | Total_Clients_Holdings_in_$ | money | YES | Total client USD value: SUM of `Total_Open_$` (Amount + PositionPnL) for the bucket. (Tier 2 -SP_Finance_Non_US_Settlement_Report, SUM(#relPos1.Total_Open_$)) |
| 15 | Total_Custodian_Settled_Positions_in_$ | money | YES | Legacy custodian USD; **0** in current build. (Tier 2 -SP_Finance_Non_US_Settlement_Report, literal 0) |
| 16 | Custodian_vs_Client_Holdings_Difference_In_$ | money | YES | Legacy USD difference; **0** in current build. (Tier 2 -SP_Finance_Non_US_Settlement_Report, literal 0) |
| 17 | ASIC_Client_Holdings_In_Units | money | YES | Units where `RegulationID = 4` (ASIC). (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 18 | CySEC_Client_Holdings_In_Units | money | YES | Units where `RegulationID IN (1,5)` (CySEC). (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 19 | FCA_Client_Holdings_In_Units | money | YES | Units where `RegulationID = 2` (FCA). (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 20 | GAML_Client_Holdings_In_Units | money | YES | Units where `RegulationID = 10` (GAML). (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 21 | ASIC_Client_Holdings_In_$ | money | YES | USD holdings for ASIC clients in the bucket. (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 22 | CySEC_Client_Holdings_In_$ | money | YES | USD holdings for CySEC clients in the bucket. (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 23 | FCA_Client_Holdings_In_$ | money | YES | USD holdings for FCA clients in the bucket. (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 24 | GAML_Client_Holdings_In_$ | money | YES | USD holdings for GAML clients in the bucket. (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 25 | UpdateDate | datetime | YES | Row load timestamp. (Tier 3 -SP_Finance_Non_US_Settlement_Report, GETDATE()) |
| 26 | Actual_Avg_Price | money | YES | Implied average price: `Total_Clients_Holdings_In_$ / InstrumentInventory` when inventory is non-zero, else NULL. (Tier 2 -SP_Finance_Non_US_Settlement_Report, computed) |
| 27 | IsGermanBaFin | int | YES | 1 if customer appears in `V_GermanBaFin` for the report date. (Tier 2 -SP_Finance_Non_US_Settlement_Report, V_GermanBaFin) |
| 28 | Seychelles_Client_Holdings_In_Units | money | YES | Units where `RegulationID = 9`. Added Apr 2021. (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 29 | Seychelles_Client_Holdings_In_$ | money | YES | USD holdings for Seychelles regulation in the bucket. (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 30 | Country | nvarchar | YES | Customer country name from `Dim_Country` via snapshot. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Country.Name) |
| 31 | PlayerLevel | nvarchar | YES | Player level name from `Dim_PlayerLevel` for Tableau filters. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_PlayerLevel.Name) |
| 32 | FinCENFINRA_Client_Holdings_In_Units | money | YES | Units where `RegulationID IN (8)` in aggregation temp table; source `#relPos2` excludes regulation 8, so values are **0** in practice (column retained for schema). (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |
| 33 | FinCENFINRA_Client_Holdings_In_$ | money | YES | USD for regulation 8 bucket; **0** in practice for same reason as units. (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE RegulationID) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary fact -- units and open USD per position |
| Dim_Instrument | DWH_dbo | Type filter, ISIN, symbol, display name, exchange |
| Fact_SnapshotCustomer | DWH_dbo | Regulation, country, player level, credit flag |
| Dim_Range | DWH_dbo | Snapshot date range join |
| Dim_Country | DWH_dbo | Country name |
| Dim_PlayerLevel | DWH_dbo | Player level name |
| Dim_Regulation | DWH_dbo | Regulation name on position rows |
| Dim_Position | DWH_dbo | Open/close metadata feeding GAML siblings |
| Fact_CurrencyPriceWithSplit | DWH_dbo | EOD bid / spreaded bid |
| Dim_GetSpreadedPriceUSDConversionRate | DWH_dbo | USD conversion for prices |
| V_GermanBaFin | BI_DB_dbo | German BaFin flag |

### Sibling Tables (same SP writes)

| Table | Scope |
|-------|-------|
| BI_DB_CIDLevel_Settlement_Report | CID × instrument settled snapshot |
| BI_DB_GAML_Real_Positions_Report_Opened_2022 | GAML regulation, positions opened on date |
| BI_DB_GAML_Real_Positions_Report_Closed | GAML regulation, positions closed on date |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Finance_Non_US_Settlement_Report |
| **ETL Pattern** | DELETE-INSERT by report date |
| **Schedule** | Daily (Priority 99 -- FinanceReportSPS) |
| **Parameter** | @dt (date) |
| **Delete Scope** | `DELETE WHERE ReportDate = @dateID` |
| **Pre-step** | `UPDATE STATISTICS BI_DB_dbo.BI_DB_PositionPnL` |
| **History** | Daily snapshot per report date |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|----------|
| **Filter on ReportDate** | Clustered on `ReportDate`; always constrain date. |
| **Custodian columns** | Treat as zero / non-populated unless LP logic is reintroduced. |
| **ROUND_ROBIN** | No hash colocation; filter early on date and instrument. |
| **Provider rollups** | Provider labels come from a static map in the SP; new hedge servers need SP updates. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Settlement |
| **Sub-domain** | Non-US real stock reconciliation |
| **Sensitivity** | Aggregated holdings -- finance confidential |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
