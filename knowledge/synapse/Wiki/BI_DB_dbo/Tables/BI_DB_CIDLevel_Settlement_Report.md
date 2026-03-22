# BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report

## 1. Overview

CID-level aggregation of **settled real stock positions** for non-US regulations. Each row represents one customer's settled holdings in one instrument on one settlement date, showing the number of units held, the total USD value, and the effective end-of-day price. This is a derivative of `BI_DB_PositionPnL` aggregated at the CID × Instrument level for settlement reconciliation.

**Row grain**: One CID × InstrumentID per SettlementDate

---

## 2. Business Context

Created March 2020 by Guy Manova as part of the non-US settlement reconciliation report. Originally used SettlementDB_Real for LP-side reconciliation, but as of April 2022, the LP side was removed — the table now purely tracks client-side settled real stock positions.

**Key business rules**:
- **Settled real stocks only**: InstrumentTypeID IN (5,6) AND IsSettled = 1. CFD positions and unsettled positions are excluded.
- **Non-US regulations**: RegulationID NOT IN (6,7,8) — eToro US, FinCEN, and FINRA regulations are excluded.
- **EffectiveEODPrice**: Computed as Total_Open_$ / Units — the effective per-unit value at end of day. Not a market quote but a portfolio-derived price.
- **Source is BI_DB_PositionPnL**: The primary data source is the already-processed PositionPnL table (another P99 BI_DB object), not raw position data.
- **Multi-table SP**: `SP_Finance_Non_US_Settlement_Report` writes to 4 tables in one execution: this table, BI_DB_Finance_Non_US_Settlement_Report (aggregated), and two GAML position tables.

**Consumers**: Used by Tableau settlement dashboards for reconciliation against LP (Liquidity Provider) statements.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 10 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | SettlementDate ASC, Regulation ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Instrument identifier from BI_DB_PositionPnL, resolved via Dim_Instrument. Filtered to InstrumentTypeID IN (5,6) = Real stocks and ETFs only. (Tier 2 — SP_Finance_Non_US_Settlement_Report, BI_DB_PositionPnL.InstrumentID) |
| 2 | InstrumentName | nvarchar(1000) | YES | Instrument name from Dim_Instrument.Name. Format includes exchange suffix: "OLED/USD", "GRG/GBX", "TTE.PA/EUR". (Tier 2 — SP_Finance_Non_US_Settlement_Report, Dim_Instrument.Name) |
| 3 | SettlementDate | int | YES | Settlement date as YYYYMMDD integer. Clustered index leading column. Equals the SP @dt parameter date. (Tier 2 — SP_Finance_Non_US_Settlement_Report, @dateID) |
| 4 | EffectiveEODPrice | money | YES | Effective end-of-day price per unit in USD. Computed: CAST(Total_Open_$ / Units AS DECIMAL(18,4)). This is a portfolio-derived price, not a market quote — it reflects the actual mark-to-market value divided by units held. (Tier 2 — SP_Finance_Non_US_Settlement_Report, computed) |
| 5 | CID | bigint | YES | Customer ID from BI_DB_PositionPnL. Only settled, non-US, real-stock customers with IsCreditReportValidCB = 1. (Tier 2 — SP_Finance_Non_US_Settlement_Report, BI_DB_PositionPnL.CID) |
| 6 | Regulation | nvarchar(100) | YES | Regulation name from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. Non-US only (excludes eToro US, FinCEN, FINRA). Values: "CySEC", "FCA", "ASIC", "ASIC & GAML", "FSA", etc. Clustered index component. (Tier 2 — SP_Finance_Non_US_Settlement_Report, Dim_Regulation.Name) |
| 7 | SettledInUnits | money | YES | Total units of the instrument held by this CID on this date. SUM of BI_DB_PositionPnL.AmountInUnitsDecimal aggregated at CID × Instrument level. (Tier 2 — SP_Finance_Non_US_Settlement_Report, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 8 | SettledIn$ | money | YES | Total mark-to-market value in USD of the instrument held by this CID. SUM of (Amount + PositionPnL) from BI_DB_PositionPnL. Represents the full settled value including unrealized PnL. (Tier 2 — SP_Finance_Non_US_Settlement_Report, BI_DB_PositionPnL.Amount + PositionPnL) |
| 9 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 — SP_Finance_Non_US_Settlement_Report, GETDATE()) |
| 10 | IsGermanBaFin | int | YES | German BaFin regulatory flag. 1 if CID exists in V_GermanBaFin for this date. Added Nov 2020. (Tier 2 — SP_Finance_Non_US_Settlement_Report, V_GermanBaFin) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary — position amounts, units, CID (SQL-level dep, same SP priority) |
| Dim_Instrument | DWH_dbo | Instrument name, type filter |
| Fact_SnapshotCustomer | DWH_dbo | Regulation, credit report validity |
| Dim_Regulation | DWH_dbo | Regulation name |
| Dim_Position | DWH_dbo | Open/close dates, initial amount |
| Dim_Range | DWH_dbo | Date range resolution |
| Dim_Country | DWH_dbo | Country name (used in upstream aggregation) |
| Dim_PlayerLevel | DWH_dbo | Player level (used in upstream aggregation) |
| V_GermanBaFin | BI_DB_dbo | German BaFin indicator |

### Sibling Tables (same SP writes)

| Table | Scope |
|-------|-------|
| BI_DB_Finance_Non_US_Settlement_Report | Instrument-level aggregation (main settlement report) |
| BI_DB_GAML_Real_Positions_Report_Opened_2022 | GAML-only opened positions |
| BI_DB_GAML_Real_Positions_Report_Closed | GAML-only closed positions |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Finance_Non_US_Settlement_Report |
| **ETL Pattern** | DELETE-INSERT by SettlementDate |
| **Grain** | One CID × InstrumentID per SettlementDate |
| **Schedule** | Daily (SB_Daily, Priority 99 — FinanceReportSPS) |
| **Parameter** | @dt (date) |
| **Delete Scope** | `DELETE WHERE SettlementDate = @dateID` |
| **History** | Accumulating daily snapshot |
| **Note** | SP also writes to 3 other tables in the same execution. The CID-level data is built from `#relPos1` which is a GROUP BY aggregation of `#relPos2` (position-level). |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Filter on SettlementDate** | Clustered index leads with SettlementDate. Always include date filter. |
| **Add Regulation filter** | Secondary clustered index column. Combine with SettlementDate for optimal performance. |
| **EffectiveEODPrice interpretation** | This is NOT a market price. It's SUM(value) / SUM(units) at CID×Instrument level. For actual market prices, query Fact_CurrencyPriceWithSplit. |
| **ROUND_ROBIN** | No colocation benefit. For heavy CID joins, filter by date first. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Settlement Reconciliation |
| **Sub-domain** | Non-US Real Stock Settlement |
| **Sensitivity** | Contains CID, financial values — PII-adjacent |
| **Owner** | Finance team (Guy Manova) |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline — Batch 3, Object #4*
*Phases: P1 ✓ P2 ✓ P8 ✓ P9 ✓ P10 ✓ | Skipped: P3, P4, P5, P6, P7, P9B, P10.5*
