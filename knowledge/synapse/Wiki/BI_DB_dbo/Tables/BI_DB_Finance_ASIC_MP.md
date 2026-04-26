# BI_DB_dbo.BI_DB_Finance_ASIC_MP

## 1. Business Meaning

Position-level daily snapshot of **ASIC-regulated** (Australian Securities and Investments Commission) trading positions for finance/regulatory reporting. Each row represents a single position event — open, close, or IsSettled status change — on a given date, with amounts converted to USD, GBP, and EUR. Covers only ASIC and ASIC & GAML regulations (RegulationID 4 and 10).

**Row grain**: One PositionID per Position_Phase (Open/Close/Change) per DateID

| Property | Value |
|----------|-------|
| **Production Source** | Synapse `BI_DB_dbo.BI_DB_Finance_ASIC_MP` |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **Distribution** | ROUND_ROBIN |
| **UC Target** | `_Not_Migrated` |

---

## 2. Business Logic

This table supports ASIC regulatory reporting by capturing every position lifecycle event (open, close, settlement-status change) for customers under ASIC or ASIC & GAML regulation. It enables the Finance team to report on trading volumes, notional values, and settlement status to the Australian regulator.

**Key business rules**:
- **ASIC regulations only**: Open positions filtered by `RegulationIDOnOpen IN (4, 10)`; close positions filtered via `Fact_SnapshotCustomer.RegulationID IN (4, 10)`.
- **Three position phases**: Open_Position (new positions opened on date), Close_Position (positions closed on date), and Open_Position for IsSettled changes (settlement status changed on date).
- **Multi-currency amounts**: Open amounts converted from USD to GBP and EUR using Fact_CurrencyPriceWithSplit Ask prices for InstrumentID 2 (GBP) and 1 (EUR). Close amounts follow the same logic.
- **Notional value**: Open phase uses `AmountInUnitsDecimal * InitForexRate`; close phase uses `AmountInUnitsDecimal * EndForexRate`.
- **Copy trading flag**: `Is_Copy = 1` when `MirrorID <> 0` on Dim_Position, identifying copied/social-trading positions.
- **IsSettled change detection**: Uses `External_etoro_History_PositionChangeLog_Yesterday` (ChangeTypeID = 13) to detect intra-day settlement status changes, taking the latest change per position (ROW_NUMBER DESC).
- **Valid customers only**: `IsCreditReportValidCB = 1` via Fact_SnapshotCustomer ensures only active, credit-validated customers are included.

**Consumers**: Finance team ASIC regulatory reporting dashboards.

---

## 3. Query Advisory

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 32 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC |

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Position_Phase | varchar(50) | YES | Position lifecycle phase: 'Open_Position' for opens and settlement changes, 'Close_Position' for closes. Determines which amount columns are populated vs zero. (Tier 2 — SP_Finance_ASIC_MP, literal) |
| 2 | DateID | int | YES | Date key in YYYYMMDD format. Clustered index column. Equals OpenDateID for opens, CloseDateID for closes, ChangedDateID for settlement changes. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.OpenDateID/CloseDateID) |
| 3 | DateOccurred | date | YES | Calendar date of the position event, derived from OpenOccurred or CloseOccurred via CONVERT. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.OpenOccurred/CloseOccurred) |
| 4 | EOW | date | YES | End-of-week date (Saturday) for the position event. Computed: DATEADD(dd, -(DATEPART(dw, Occurred) - 7), Occurred). (Tier 2 — SP_Finance_ASIC_MP, computed) |
| 5 | EOM | date | YES | End-of-month date for the position event. Computed: EOMONTH(Occurred, 0). (Tier 2 — SP_Finance_ASIC_MP, computed) |
| 6 | HedgeServerID | int | YES | Hedge server identifier from Dim_Position. Indicates which trading server handled the position. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.HedgeServerID) |
| 7 | ISINCountryCode | varchar(50) | YES | Country code extracted from Dim_Instrument.ISINCode. First 2 chars if 3rd is numeric, first 3 chars otherwise; '-' when ISIN is null or empty. (Tier 2 — SP_Finance_ASIC_MP, Dim_Instrument.ISINCode) |
| 8 | InstrumentTypeID | int | YES | Instrument type identifier from Dim_Instrument. Values: 1=Currencies, 2=Commodities, 5=Stocks, etc. (Tier 2 — SP_Finance_ASIC_MP, Dim_Instrument.InstrumentTypeID) |
| 9 | InstrumentTypeName | varchar(50) | YES | Instrument type name from Dim_Instrument.InstrumentType. Values: 'Currencies', 'Commodities', 'Indices', 'Stocks', etc. (Tier 2 — SP_Finance_ASIC_MP, Dim_Instrument.InstrumentType) |
| 10 | InstrumentID | int | YES | Instrument identifier from Dim_Position / Dim_Instrument join. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.InstrumentID) |
| 11 | InstrumentName | varchar(50) | YES | Instrument display name from Dim_Instrument.Name. Format: 'XAU/USD', 'AUD/USD', etc. (Tier 2 — SP_Finance_ASIC_MP, Dim_Instrument.Name) |
| 12 | CID | int | YES | Customer identifier. Only customers with IsCreditReportValidCB = 1 from Fact_SnapshotCustomer. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.CID) |
| 13 | PositionID | bigint | YES | Unique position identifier from Dim_Position. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.PositionID) |
| 14 | IsSettled_OnOpen | int | YES | Settlement status at position open. From Fact_CustomerAction.IsSettled (ActionTypeID IN 1,2,3) for opens; -1 sentinel for closes. (Tier 2 — SP_Finance_ASIC_MP, Fact_CustomerAction.IsSettled) |
| 15 | IsSettled_OnClose | int | YES | Settlement status at position close. From Dim_Position.IsSettled for closes; -1 sentinel for opens. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.IsSettled) |
| 16 | Leverage | int | YES | Leverage multiplier applied to the position. From Dim_Position.Leverage. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.Leverage) |
| 17 | SellCurrencyID | int | YES | Sell currency identifier from Dim_Instrument. Used for GBP/EUR conversion logic: 666 or 3 = GBP path, 2 = EUR path. (Tier 2 — SP_Finance_ASIC_MP, Dim_Instrument.SellCurrencyID) |
| 18 | SellCurrency | varchar(50) | YES | Sell currency name from Dim_Instrument.SellCurrency. Values: 'USD', 'GBP', 'EUR', etc. (Tier 2 — SP_Finance_ASIC_MP, Dim_Instrument.SellCurrency) |
| 19 | Amount_OnOpen_USD | money | YES | Position open amount in USD. Open phase: InitialAmountCents / 100; Close phase: 0. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.InitialAmountCents) |
| 20 | Amount_OnOpen_GBP | money | YES | Position open amount in GBP. Computed: Amount_OnOpen_USD / GBP Ask price when SellCurrencyID IN (666, 3); else 0. (Tier 2 — SP_Finance_ASIC_MP, computed) |
| 21 | Amount_OnOpen_EUR | money | YES | Position open amount in EUR. Computed: Amount_OnOpen_USD / EUR Ask price when SellCurrencyID = 2; else 0. (Tier 2 — SP_Finance_ASIC_MP, computed) |
| 22 | Notional_Value | money | YES | Notional exposure value. Open phase: AmountInUnitsDecimal * InitForexRate; Close phase: AmountInUnitsDecimal * EndForexRate. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.AmountInUnitsDecimal) |
| 23 | Amount_OnClose_USD | money | YES | Position close amount in USD. Close phase: dp.Amount; Open phase: 0. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.Amount) |
| 24 | Amount_OnClose_GBP | money | YES | Position close amount in GBP. Computed: Amount / GBP Ask price when SellCurrencyID IN (666, 3); else 0. (Tier 2 — SP_Finance_ASIC_MP, computed) |
| 25 | Amount_OnClose_EUR | money | YES | Position close amount in EUR. Computed: Amount / EUR Ask price when SellCurrencyID = 2; else 0. (Tier 2 — SP_Finance_ASIC_MP, computed) |
| 26 | RegulationID_OnOpen | int | YES | Regulation ID at position open. Open phase: Dim_Position.RegulationIDOnOpen (filtered to 4, 10); Close phase: -1 sentinel. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.RegulationIDOnOpen) |
| 27 | RegulationName_OnOpen | varchar(50) | YES | Regulation name at open. Open phase: Dim_Regulation.Name via RegulationIDOnOpen; Close phase: 'N/A'. Values: 'ASIC', 'ASIC & GAML'. (Tier 2 — SP_Finance_ASIC_MP, Dim_Regulation.Name) |
| 28 | RegulationID_OnClose | int | YES | Regulation ID at position close. Close phase: Fact_SnapshotCustomer.RegulationID; Open phase: -1 sentinel. (Tier 2 — SP_Finance_ASIC_MP, Fact_SnapshotCustomer.RegulationID) |
| 29 | RegulationName_OnClose | varchar(50) | YES | Regulation name at close. Close phase: Dim_Regulation.Name via fsc.RegulationID; Open phase: 'N/A'. Values: 'ASIC', 'ASIC & GAML'. (Tier 2 — SP_Finance_ASIC_MP, Dim_Regulation.Name) |
| 30 | Is_Copy | int | YES | Copy-trading flag. 1 if Dim_Position.MirrorID <> 0 (position was copied via social trading), else 0. (Tier 2 — SP_Finance_ASIC_MP, Dim_Position.MirrorID) |
| 31 | Position_Quantity | int | YES | Always 1. Each row represents exactly one position event. (Tier 2 — SP_Finance_ASIC_MP, literal) |
| 32 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| Dim_Position | DWH_dbo | Primary — position attributes, amounts, dates, CID |
| Dim_Instrument | DWH_dbo | Instrument name, type, ISIN, sell currency |
| Fact_SnapshotCustomer | DWH_dbo | Customer credit validation, regulation for close phase |
| Dim_Range | DWH_dbo | Date range resolution for snapshot validity |
| Dim_Regulation | DWH_dbo | Regulation name lookup |
| Fact_CustomerAction | DWH_dbo | IsSettled status at open (ActionTypeID IN 1,2,3) |
| Fact_CurrencyPriceWithSplit | DWH_dbo | GBP and EUR Ask prices for currency conversion |
| External_etoro_History_PositionChangeLog_Yesterday | BI_DB_dbo | Settlement status changes (ChangeTypeID = 13) |

### 5.2 ETL Pipeline

```
 @Date parameter
      │
      ▼
 ┌─────────────────────────────────────────────┐
 │  SP_Create_External_etoro_History_           │
 │    PositionChangeLog (@Date, 'Yesterday')    │
 │  → stages External_...ChangeLog_Yesterday    │
 └──────────────────┬──────────────────────────┘
                    │
      ┌─────────────┼─────────────────┐
      ▼             ▼                 ▼
 ┌─────────┐  ┌──────────┐  ┌──────────────────┐
 │ #Prices │  │#IsSettled │  │ External_etoro_  │
 │ (GBP,   │  │ _OnOpen   │  │ History_Position │
 │  EUR)   │  │ (fca)     │  │ ChangeLog_       │
 └────┬────┘  └─────┬─────┘  │ Yesterday        │
      │             │        └────────┬─────────┘
      ▼             ▼                 ▼
 ┌──────────────────────┐   ┌─────────────────────┐
 │ #Open_Positions_Phase│   │ #IsSettled_Changes   │
 │ (Dim_Position +      │   │ (RN=1 per PositionID│
 │  joins, OpenDateID)  │   │  ChangeTypeID=13)   │
 └──────────┬───────────┘   └─────────┬───────────┘
            │                         ▼
            │               ┌─────────────────────┐
            │               │#IsSettled_Changes_   │
            │               │ Final (+ fca + di)   │
            │               └─────────┬───────────┘
            │                         ▼
            │               ┌─────────────────────┐
 ┌──────────────────────┐   │#Change_Positions_    │
 │#Close_Positions_Phase│   │ Phase                │
 │(Dim_Position +       │   │(settlement changes)  │
 │ joins, CloseDateID)  │   └─────────┬───────────┘
 └──────────┬───────────┘             │
            │                         │
            └────────┬────────────────┘
                     ▼
          DELETE WHERE DateID = @DateID
                     ▼
          INSERT (UNION ALL of 3 phases)
                     ▼
          BI_DB_Finance_ASIC_MP
```

---

## 6. Relationships

### Upstream Dependencies (OpsDB)

| Dependency SP | Target Table | Priority | Note |
|--------------|-------------|----------|------|
| SP_User_Segment_Snapshot | BI_DB_DepositSnapshots | 20 | Must complete before this SP |
| SP_User_Segment_Snapshot | BI_DB_EquitySnapshots | 20 | Must complete before this SP |
| SP_User_Segment_Snapshot | BI_DB_STDSnapshots | 20 | Must complete before this SP |
| SP_User_Segment_Snapshot | BI_DB_User_Segment_Snapshot | 20 | Must complete before this SP |

### Downstream Consumers

No known downstream BI_DB SPs consume this table. Primary consumers are external reporting dashboards (Tableau / Excel).

---

## 7. Sample Queries

| Consideration | Guidance |
|--------------|---------|
| **Always filter on DateID** | Clustered index on DateID. Without a date filter, full table scan of 334M+ rows. |
| **Position_Phase filter** | Use Position_Phase = 'Open_Position' or 'Close_Position' to isolate lifecycle events. |
| **Sentinel values** | -1 in IsSettled_OnOpen/IsSettled_OnClose and RegulationID columns indicates the value is not applicable for that phase. Filter accordingly. |
| **Currency amounts** | Amount_OnOpen_* columns are zero for Close_Position rows and vice versa. Do not sum across phases without phase filtering. |
| **ROUND_ROBIN distribution** | No colocation benefit. For heavy joins, pre-filter by DateID. |
| **Row count** | ~334M rows as of April 2026. Always use date range filters for analytical queries. |

---

## 8. Atlassian Knowledge Sources

| Property | Value |
|----------|-------|
| **Domain** | Finance / Regulatory Reporting |
| **Sub-domain** | ASIC Position Reporting |
| **Sensitivity** | Contains CID, financial amounts — PII-adjacent |
| **Owner** | Finance team |
| **Quality Score** | 8.5 |

---

*Generated: 2026-04-26 | Quality: 8/10 | Phases: 14/14*
