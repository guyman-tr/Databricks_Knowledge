# BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW

## 1. Overview

Daily **zero P&L and tree-size bucket** aggregates by hedge server, instrument, copy/mirror role, customer attributes, and settlement type. Rows combine **realized** flows (positions closed on the report date) and **change in unrealized** (open positions marked on that date) so that **TotalZero** reconciles daily zero exposure. **TreeSize_Units** and **TreeSize_USD** are categorical buckets derived from position or tree aggregate size for risk reporting.

**Row grain**: One row per combination of report **Date**, **HedgeServerID**, **Copy**, **InstrumentID**, tree-size buckets, **Leverage**, **IsCFD**, **Regulation**, **MifID**, instrument dimensions, **Country**, **PlayerLevel**, **GuruStatus**, **SettlementType**, **IsIslamic**, and **IsDLTUser** (after aggregation in the writer SP).

---

## 2. Business Context

Used for **risk management and P&L attribution** at the hedge-server level. The **zero** concept tracks daily reconciliation of position P&L and commissions versus prior-day **BI_DB_PositionPnL**. **TreeSize** buckets classify exposure by units and notional (USD) thresholds; stocks/ETFs are rolled to a synthetic instrument id **1000** and type/name **Stocks/ETF** in the pipeline feeding this table.

**Key business rules** (from `SP_DailyZero_TreeSize_NEW`):
- **Report date**: `@start` / `@RepDate` is the business day processed; prior day **DateID** is used for **PositionPnL** joins where noted in code.
- **RealizedZero**: Sum of **CalculatedZero** for rows tagged **Realized** (positions with **CloseDateID** = report **DateID**).
- **ChangeInUnrealizedZero**: Sum of **CalculatedZero** for **UnRealized** (open through the date or opened on the date).
- **RealizedCommission**: Sum of **TotalCommission** (full commission on close, or delta vs. by-units for partial closes).
- **TotalZero**: **RealizedZero** + **ChangeInUnrealizedZero** (same as sum of **CalculatedZero** across both indicators).
- **TicketFees**: Rolled from **Fact_CustomerAction** (ActionTypeID = 35, **IsFeeDividend** = 4) by **PositionID**, joined to the indicator set.
- **RiskIndex**, **RiskGroup**, **DepositGroup**: Populated as empty placeholders in the current SP (no dimensional assignment in insert).

**Consumed by**: Finance and risk reporting consuming daily zero / tree-size cubes (confirm downstream reports as needed).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 35 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | NO | Report date for the daily run (equals **@RepDate** / **@start** in the SP). (Tier 2 -- SP_DailyZero_TreeSize_NEW, @RepDate) |
| 2 | HedgeServerID | int | NO | Hedge server from **Dim_Position**. Groups exposure by hedging infrastructure. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.HedgeServerID) |
| 3 | Copy | int | NO | Copy trade role: **1** if **MirrorID** > 0, **-1** if **OrigParentPositionID** > 0, else **0**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.MirrorID / OrigParentPositionID) |
| 4 | InstrumentID | int | NO | Instrument id; **1000** when **InstrumentTypeID** in (5,6) (stocks/ETF rollup). (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.InstrumentID / Dim_Instrument) |
| 5 | RiskIndex | int | NO | Placeholder in current ETL (inserted as empty string literal, effectively **0**). Reserved for future risk indexing. (Tier 2 -- SP_DailyZero_TreeSize_NEW, literal) |
| 6 | TreeSize_Units | varchar(50) | NO | Bucket label from **AmountInUnitsDecimal** or tree-aggregated units (e.g. **10K+**, **1M+**, **Smaller**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, computed bucket) |
| 7 | TreeSize_USD | varchar(50) | NO | Bucket label from **OpenPosition** (USD) or tree-aggregated USD size (e.g. **100K+**, **1000K+**, **Smaller**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, computed bucket) |
| 8 | Leverage | int | NO | Position leverage from **Dim_Position**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.Leverage) |
| 9 | RiskGroup | nvarchar(50) | YES | Placeholder; inserted as empty string in current SP. (Tier 2 -- SP_DailyZero_TreeSize_NEW, literal) |
| 10 | DepositGroup | nvarchar(50) | YES | Placeholder; inserted as empty string in current SP. (Tier 2 -- SP_DailyZero_TreeSize_NEW, literal) |
| 11 | RealizedCommission | money | YES | Sum of commission components (**FullCommissionOnClose** minus **FullCommissionByUnits** when applicable, or on-open close commission). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Realized / #UnRealized TotalCommission) |
| 12 | RealizedZero | money | YES | Portion of **CalculatedZero** from closed positions on the report date (**Indicator** = **Realized**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Realized.CalculatedZero) |
| 13 | ChangeInUnrealizedZero | money | YES | Portion of **CalculatedZero** from open / marked positions (**Indicator** = **UnRealized**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #UnRealized.CalculatedZero) |
| 14 | TotalZero | money | YES | **RealizedZero** + **ChangeInUnrealizedZero** (sum of **CalculatedZero**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, computed aggregate) |
| 15 | NOP | money | YES | Sum of net open position exposure (**NOP** from **BI_DB_PositionPnL** for the report **DateID**, signed by buy/sell). (Tier 2 -- SP_DailyZero_TreeSize_NEW, BI_DB_PositionPnL.NOP) |
| 16 | OpenPositions | money | YES | Sum of **OpenPosition** (directional NOP). (Tier 2 -- SP_DailyZero_TreeSize_NEW, BI_DB_PositionPnL.NOP x IsBuy) |
| 17 | Nop_Units | money | YES | Sum of **NOP_Units** (**AmountInUnitsDecimal** at mark from **PositionPnL** path). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Pos_with_Vol.NOP_Units) |
| 18 | VolumeAtOpen | money | YES | Trading volume for positions opened on the report **DateID**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.Volume) |
| 19 | VolumeAtClose | money | YES | Volume on close for positions closed on the report **DateID**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.VolumeOnClose) |
| 20 | UpdateDate | datetime | YES | Load timestamp. (Tier 3 -- SP_DailyZero_TreeSize_NEW, GETDATE()) |
| 21 | IsCFD | tinyint | YES | **1** when position is treated as CFD-like per **IsSettled** vs **BI_DB_PositionPnL.IsSettled** rules; **0** for **Real** cash-settled path. (Tier 2 -- SP_DailyZero_TreeSize_NEW, computed from Dim_Position / BI_DB_PositionPnL) |
| 22 | Regulation | varchar(50) | YES | Regulation name from **Dim_Regulation** via **Fact_SnapshotCustomer**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Regulation.Name) |
| 23 | MifID | int | YES | MiFID categorization id from snapshot customer (**MifidCategorizationID**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, Fact_SnapshotCustomer.MifidCategorizationID) |
| 24 | InstrumentType | varchar(50) | YES | Instrument type label; **Stocks/ETF** for instrument types 5 and 6. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Instrument.InstrumentType) |
| 25 | InstrumentName | varchar(50) | YES | Instrument name; **Stocks/ETF** for types 5 and 6. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Instrument.Name) |
| 26 | OpenPositionValue | money | YES | Sum of **Amount + PositionPnL** from **BI_DB_PositionPnL** (mark value). (Tier 2 -- SP_DailyZero_TreeSize_NEW, BI_DB_PositionPnL) |
| 27 | Country | varchar(50) | YES | Customer country from **Dim_Country** on snapshot **CountryID**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Country.Name) |
| 28 | PlayerLevel | varchar(100) | YES | Player level name from **Dim_PlayerLevel**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_PlayerLevel.Name) |
| 29 | GuruStatus | nvarchar(100) | YES | Guru program status from **Dim_GuruStatus**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_GuruStatus.GuruStatusName) |
| 30 | Long_OP | decimal(18,6) | YES | Aggregated long-side open position (NOP contribution). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Pos_with_Vol.Long_OP) |
| 31 | Short_OP | decimal(18,6) | YES | Aggregated short-side open position (NOP contribution). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Pos_with_Vol.Short_OP) |
| 32 | SettlementType | varchar(10) | YES | **Real** vs **CFD** / **TRS** / **CMT** from **SettlementTypeID** when not **Real** path. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.SettlementTypeID) |
| 33 | IsIslamic | varchar(50) | YES | **Islamic** when **WeekendFeePrecentage** = 0 on **Dim_Customer**, else **Not Islamic**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Customer.WeekendFeePrecentage) |
| 34 | IsDLTUser | int | YES | **1** when **DltStatusID** = 4 on customer, else **0**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Customer.DltStatusID) |
| 35 | TicketFees | money | YES | Sum of ticket-fee actions from **Fact_CustomerAction** (fee/dividend type 4) for the report **DateID**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Fact_CustomerAction.Amount) |

---

## 5. Relationships

### Source tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| Dim_Position | DWH_dbo | Open/close dates, mirror, tree, commission, rates, settlement |
| Fact_SnapshotCustomer | DWH_dbo | Valid customers, regulation, country, player level, guru, MiFID |
| Dim_Customer | DWH_dbo | Islamic / DLT flags |
| Dim_Range | DWH_dbo | Snapshot date range filter |
| Dim_Instrument | DWH_dbo | Instrument type/name; ETF/stock rollup |
| Dim_Regulation | DWH_dbo | Regulation label |
| Dim_Country | DWH_dbo | Country names (snapshot country) |
| Dim_PlayerLevel | DWH_dbo | Player tier name |
| Dim_GuruStatus | DWH_dbo | Guru status label |
| BI_DB_PositionPnL | BI_DB_dbo | Daily PnL, NOP, settled flags for report and prior dates |
| Fact_CustomerAction | DWH_dbo | Overnight fees / dividends / **TicketFees** (ActionTypeID 35) |

### Consumers

| Consumer | Purpose |
|----------|---------|
| Finance / risk reporting | Daily zero and tree-size analysis by hedge server |

---

## 6. ETL & lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DailyZero_TreeSize_NEW |
| **ETL pattern** | DELETE by **Date** then INSERT aggregated rows |
| **Schedule** | Daily, Priority 99 (FinanceReportSPS) |
| **Parameter** | **@start** (datetime -- business date processed) |
| **Delete scope** | `DELETE ... WHERE Date = @start` |

---

## 7. Query advisory

| Consideration | Guidance |
|---------------|----------|
| **Filter on Date** | Aligns with clustered index **Date**. |
| **Depends on PositionPnL** | Same-day and prior-day **BI_DB_PositionPnL** must be loaded before this SP. |
| **Placeholder columns** | **RiskIndex**, **RiskGroup**, **DepositGroup** are not populated with business keys in the current procedure. |
| **Stocks/ETF rollup** | Instrument **1000** groups multiple underlying instruments for bucket logic. |

---

## 8. Classification & status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Risk |
| **Sub-domain** | Daily zero & tree size |
| **Sensitivity** | Aggregated trading metrics -- internal use |
| **Owner** | Finance / Risk analytics |
| **Quality score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
