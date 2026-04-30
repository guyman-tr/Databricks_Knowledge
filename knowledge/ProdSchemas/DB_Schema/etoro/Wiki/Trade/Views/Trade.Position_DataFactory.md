# Trade.Position_DataFactory

> ETL-optimized variant of Trade.Position for data factory/CDC consumption, excluding markup columns and adding RowVersionIDByPosition for incremental loads.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.Position_DataFactory is a **variant of Trade.Position** tailored for data factory and ETL consumption. It exposes the same core open-position data (amounts, leverage, forex rates, tree settings, computed columns) but excludes markup, pricing, and audit columns that are not needed for data pipelines. It adds RowVersionIDByPosition, a BIGINT cast of RowVersionPosition, for change tracking and incremental loads (CDC).

This view exists because Azure Data Factory and similar ETL tools consume position data for analytics, reporting, and downstream systems. The full Trade.Position includes markup and fee columns (OpenMarkup, OpenEtoroPrice, OpenTotalTaxes, etc.) that add payload size without value for most pipelines. Position_DataFactory reduces the column set and provides a stable BIGINT version identifier for watermark-based incremental extraction.

The view uses the same JOIN pattern as Trade.Position: INNER JOIN PositionTbl with PositionTreeInfo on TreeID and partition-aligned condition ABS(TreeID%50) = PartitionCol, WHERE StatusID = 1.

---

## 2. Business Logic

**Filter**: WHERE TPOS.StatusID = 1. Only open positions.

**Join**: Same as Trade.Position - INNER JOIN Trade.PositionTreeInfo TPTI ON TPOS.TreeID = TPTI.TreeID AND ABS(TPOS.TreeID%50) = TPTI.PartitionCol.

**Exclusions** (vs Trade.Position): AdditionalParam, IsNoStopLoss, IsNoTakeProfit, OpenMarketSpread, PnLVersion, CloseMarkupOnOpen, EstimatedConversionMarkupRatio, EstimatedMarkupRatio, OpenMarkup, OpenEtoroPrice, OpenTotalTaxes, OpenTotalFees, OpenMarkupByUnits, InitialLotCount, CloseMarkup.

**Additions**: RowVersionIDByPosition = cast(TPOS.RowVersionPosition AS BIGINT) - used as watermark for CDC/incremental loads.

**Computed columns** (same as Trade.Position): InitialUnits, UnitsBaseValueCents, SettlementTypeID, CommissionByUnits, FullCommissionByUnits.

---

## 3. Data Overview

N/A - output mirrors Trade.Position minus excluded columns, plus RowVersionIDByPosition. See [Trade.PositionTbl](../Tables/Trade.PositionTbl.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Primary key. Unique identifier for the open position. |
| 2 | RowVersionIDByPosition | bigint | YES | - | CODE-BACKED | BIGINT cast of RowVersionPosition for CDC/incremental load watermark. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.Customer. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Instrument traded. FK to Trade.Instrument. |
| 5 | Amount | money | NO | - | CODE-BACKED | Position size in denomination currency. |
| 6 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. |
| 7 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | Computed: ISNULL(InitialUnits, AmountInUnitsDecimal). |
| 8 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Computed: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). |
| 9 | CommissionByUnits | money | YES | - | CODE-BACKED | Computed: Prorated commission for partial close. |
| 10 | FullCommissionByUnits | money | YES | - | CODE-BACKED | Computed: Prorated full commission for partial close. |
| 11-70+ | (Remaining columns) | various | - | - | CODE-BACKED | All other columns from Trade.Position except excluded markup/pricing columns. Includes ForexResultID, CurrencyID, ProviderID, GameServerID, HedgeID, HedgeServerID, OrderID, Leverage, UnitMargin, LotCountDecimal, NetProfit, InitForexRate, InitDateTime, LimitRate, StopRate, SpreadedPipBid, SpreadedPipAsk, IsBuy, CloseOnEndOfWeek, EndOfWeekFee, Commission, SpreadedCommission, FullCommission, SettlementTypeID, and tree/hierarchy/version columns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | FK | Customer who owns the position |
| InstrumentID | Trade.Instrument | FK | Instrument being traded |
| OrderID | Trade.Orders | FK | Originating order |
| ParentPositionID | Trade.PositionTbl | FK | Parent position in hierarchy |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionTbl
    |
Trade.PositionTreeInfo
    |
    +-- Trade.Position_DataFactory (INNER JOIN, StatusID=1)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Base table; JOIN key TreeID, filter StatusID=1 |
| Trade.PositionTreeInfo | Table | JOIN for LimitRate, StopRate, CloseOnEndOfWeek, IsTslEnabled, IsDiscounted, etc. |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Incremental load by RowVersionIDByPosition

```sql
SELECT PositionID, CID, InstrumentID, Amount, RowVersionIDByPosition
FROM Trade.Position_DataFactory WITH (NOLOCK)
WHERE RowVersionIDByPosition > @LastWatermark
ORDER BY RowVersionIDByPosition;
```

### 8.2 Full extract for data pipeline

```sql
SELECT *
FROM Trade.Position_DataFactory WITH (NOLOCK);
```

### 8.3 Open positions for ETL by customer

```sql
SELECT PositionID, CID, InstrumentID, Amount, Leverage, InitDateTime, RowVersionIDByPosition
FROM Trade.Position_DataFactory WITH (NOLOCK)
WHERE CID = @CustomerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 70 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Position_DataFactory | Type: View | Source: etoro/etoro/Trade/Views/Trade.Position_DataFactory.sql*
