# History.Position_DataFactory

> Data Factory pipeline feed view - selects 119 core position columns from History.PositionForExternalUse for Azure Data Factory consumption, omitting the DLT tracking columns (DLTOpen, DLTClose, CommissionVersion) and other internal columns.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (int, from History.PositionForExternalUse) |
| **Partition** | N/A (view - inherits from History.PositionForExternalUse) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

`History.Position_DataFactory` is the Azure Data Factory (ADF) feed view for closed position data. It selects 119 columns from `History.PositionForExternalUse` with an explicit column list, omitting the DLT-specific tracking columns (`DLTOpen`, `DLTClose`, `CommissionVersion`) and a few other internal columns (`AdditionalParam` and others). The view has no WHERE clause - it exposes the full position archive.

The naming pattern `*_DataFactory` indicates this view is consumed by an Azure Data Factory pipeline that extracts closed position data to a data lake or downstream data warehouse. The companion stored procedure `History.P_Position_DataFactory` is the ADF-facing stored procedure that uses this view (or related logic) to materialize the extract.

Confluence documentation confirms ADF usage: "Experience Building Azure Data Factory(ADF) step by step" and "Datalake directory to business domain mapping" pages mention position data flows to the eToro data lake.

**Column omissions from PositionForExternalUse**:
- `DLTOpen`, `DLTClose`, `CommissionVersion` - the 3 computed columns added by PositionForExternalUse for DLT tracking - are NOT included
- `AdditionalParam` (suppressed to NULL in PositionForExternalUse) - NOT included
- Other internal columns added in recent schema versions

**Important**: Several columns in this view are NULL for all rows because `History.PositionForExternalUse` suppresses them. Columns like `ForexResultID`, `HedgeID`, `GameServerID`, `SpreadGroupID`, `OrderPriceRateID`, `StocksOrderID`, `OpenExposureID`, `CloseExposureID`, and all `*UnAdjusted` rate variants will always be NULL. The ADF pipeline or downstream consumers should be aware of these always-null columns.

---

## 2. Business Logic

### 2.1 Column Projection from PositionForExternalUse

**What**: Direct SELECT of 119 explicitly named columns - no WHERE clause, no JOIN, no aggregation.

**Rules**:
- `SELECT [119 columns] FROM History.PositionForExternalUse`
- No WHERE clause -> full history since the archive goes back
- No aggregation -> one output row per closed position
- Column list is static and explicit - protects ADF pipeline from schema changes in the base view

### 2.2 Columns Always NULL (Suppressed by PositionForExternalUse)

**What**: These columns appear in the SELECT list but are always NULL:

| Column | Suppressed Because |
|--------|-------------------|
| ForexResultID | Legacy game platform link - suppressed for external use |
| GameServerID | Legacy game server - suppressed |
| HedgeID | Internal hedge ID - suppressed |
| SpreadGroupID | Internal spread group - suppressed |
| LotCountGroupID | Internal lot count group - suppressed |
| OrderPriceRateID | Suppressed |
| OrderPriceRate | Suppressed |
| StocksOrderID | Internal stocks order - suppressed |
| OpenExposureID / CloseExposureID | Internal exposure IDs - suppressed |
| EntryHedgeQuery / EndHedgeQuery | Internal hedge queries - suppressed |
| AmountInUnitsDecimalUnAdjusted (and all other *UnAdjusted) | Suppressed for external use |
| CloseOnEndOfWeek | Always CAST(0 AS BIT) from PositionForExternalUse |

---

## 3. Data Overview

Direct query blocked (routes to EtoroArchive). Based on History.Position documentation: millions of rows from 2007-present, all closed positions in the platform history.

---

## 4. Elements

All 119 selected columns come from `History.PositionForExternalUse`. See that document for full column descriptions. The columns are a strict subset of PositionForExternalUse - all metadata (DLTOpen, DLTClose, CommissionVersion) is excluded.

Key columns included:
- PositionID, CID, InstrumentID, HedgeServerID, OrderID
- Leverage, Amount, AmountInUnitsDecimal, LotCountDecimal
- InitForexRate, EndForexRate, MarketPriceRate
- NetProfit, Commission, CommissionOnClose
- OpenOccurred/CloseOccurred, ActionType
- IsBuy, IsSettled, IsTslEnabled, IsDiscounted
- PnLVersion, OpenMarkup, CloseMarkup, OpenMarketSpread, CloseMarketSpread
- CloseTotalFees, OpenTotalFees, InitialLotCount, InitialUnits
- All fee/revenue columns

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (119 columns) | History.PositionForExternalUse | View dependency | Direct SELECT source - all data flows from this view |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| History.P_Position_DataFactory | Stored Procedure | ACTIVE - ADF-facing stored procedure that reads from this view for data lake extract |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Position_DataFactory (view)
+--> History.PositionForExternalUse (view)
        |--> History.Position (view -> EtoroArchive)
        +--> Trade.PositionOpenInDLT (table, cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionForExternalUse | View | Direct SELECT source - 119 of 126 columns |

### 6.2 Objects That Depend On This

| Object | Active? |
|--------|---------|
| History.P_Position_DataFactory | YES - ADF pipeline extract |

---

## 7. Technical Details

### 7.1 No Performance Filter

Unlike `History.ClosePositionEndOfDay` (30-day filter), this view has no WHERE clause. Querying it without a date filter will trigger a full scan of all EtoroArchive History.Position branches. ADF pipelines typically use incremental load patterns with date filters applied at the SP or pipeline level.

### 7.2 DLT Column Exclusion

The view intentionally omits `DLTOpen`, `DLTClose`, and `CommissionVersion` - the three computed columns added by `History.PositionForExternalUse` for DLT (Distributed Ledger Technology) tracking. This keeps the ADF output schema focused on core position data without internal DLT infrastructure details.

---

## 8. Sample Queries

### 8.1 Extract positions closed in a date range (ADF incremental load pattern)

```sql
SELECT
    pf.PositionID,
    pf.CID,
    pf.InstrumentID,
    pf.IsBuy,
    pf.OpenOccurred,
    pf.CloseOccurred,
    pf.NetProfit,
    pf.AmountInUnitsDecimal,
    pf.IsSettled
FROM History.Position_DataFactory pf WITH(NOLOCK)
WHERE pf.CloseOccurred >= '2024-01-01'
  AND pf.CloseOccurred < '2024-02-01'
ORDER BY pf.CloseOccurred
```

---

## 9. Atlassian Knowledge Sources

Confluence mentions Azure Data Factory usage for position data in:
- "Experience Building Azure Data Factory(ADF) step by step"
- "Datalake directory to business domain mapping"
These pages reference ADF pipelines for position/PnL data but do not specifically name this view.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 8.8/10, Relationships: 8.8/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - EtoroArchive blocked*
*Sources: Atlassian: 3 Confluence (ADF context, indirect) + 0 Jira | Procedures: 1 direct consumer | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Position_DataFactory | Type: View | Source: etoro/etoro/History/Views/History.Position_DataFactory.sql*
