# Trade.InstrumentsIDListSetParamsTbl

> TVP for bulk updates of trading parameters per instrument: margins, leverage, stop-loss, take-profit, and rate-diff settings.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries a wide set of trading parameters per instrument: leverage/maintenance margin, max/default stop-loss and take-profit percentages, margins in asset currency, and allowed rate-diff percentages (including upside). It models the full parameter set for instrument-level trading configuration.

The type exists to support bulk updates from ops tools (SetInstrumentsDataForOpsAPI) and event batching (BatchInsertEventsToSbrInstrumentsUpdates). When config changes need to be pushed to SBR or the ops API, services populate this TVP and pass it to the procedures.

Services build the table, pass it as READONLY, and the procedures JOIN or process it to apply or publish the new parameters.

---

## 2. Business Logic

InstrumentID + multi-column parameter group for bulk instrument trading configuration. Each row carries leverage, stop-loss, take-profit, margin, and rate-diff settings; procedures apply only non-null columns.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument; identifies which instrument receives the config. |
| 2 | Leverage1MaintenanceMargin | decimal(5,2) | YES | - | CODE-BACKED | Maintenance margin percentage at 1x leverage. |
| 3 | MaxStopLossPercentage | decimal(5,2) | YES | - | CODE-BACKED | Maximum allowed stop-loss percentage. |
| 4 | StopLossMarginInAssetCurrency | dbo.dtPrice | YES | - | CODE-BACKED | Stop-loss margin in asset currency. dtPrice is a scalar alias (likely decimal). |
| 5 | InitialMarginInAssetCurrency | dbo.dtPrice | YES | - | CODE-BACKED | Initial margin in asset currency. dtPrice is a scalar alias (likely decimal). |
| 6 | DefaultStopLossPercentage | decimal(5,2) | YES | - | CODE-BACKED | Default stop-loss percentage when opening. |
| 7 | DefaultTakeProfitPercentage | decimal(7,2) | YES | - | CODE-BACKED | Default take-profit percentage when opening. |
| 8 | AllowedRateDiffPercentage | decimal(5,2) | YES | - | CODE-BACKED | Allowed rate difference percentage (slippage tolerance). |
| 9 | AllowedRateDiffPercentageUpside | decimal(8,2) | YES | - | CODE-BACKED | Allowed rate difference percentage on upside (asymmetric slippage). |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetInstrumentsDataForOpsAPI | @Instruments_NewParams | Parameter (TVP) | Sets instrument params for ops API. |
| Trade.BatchInsertEventsToSbrInstrumentsUpdates | @InstrumentsToSendUpdates | Parameter (TVP) | Batches instrument update events for SBR. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

Uses dbo.dtPrice (scalar type alias). No table dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SetInstrumentsDataForOpsAPI | Stored Procedure | READONLY parameter for ops API instrument config |
| Trade.BatchInsertEventsToSbrInstrumentsUpdates | Stored Procedure | READONLY parameter for SBR instrument event batching |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass to SetInstrumentsDataForOpsAPI
```sql
DECLARE @Params Trade.InstrumentsIDListSetParamsTbl;
INSERT INTO @Params (InstrumentID, MaxStopLossPercentage, DefaultStopLossPercentage, DefaultTakeProfitPercentage)
VALUES (12345, 50.00, 10.00, 20.00);
EXEC Trade.SetInstrumentsDataForOpsAPI @Instruments_NewParams = @Params;
```

### 8.2 Pass to BatchInsertEventsToSbrInstrumentsUpdates
```sql
DECLARE @Updates Trade.InstrumentsIDListSetParamsTbl;
INSERT INTO @Updates (InstrumentID, Leverage1MaintenanceMargin, InitialMarginInAssetCurrency)
SELECT InstrumentID, 5.00, 1000.00 FROM Trade.Instrument WHERE IndustryID = 1;
EXEC Trade.BatchInsertEventsToSbrInstrumentsUpdates @InstrumentsToSendUpdates = @Updates;
```

### 8.3 Full row with margins and rate-diff
```sql
DECLARE @Params Trade.InstrumentsIDListSetParamsTbl;
INSERT INTO @Params (InstrumentID, Leverage1MaintenanceMargin, MaxStopLossPercentage, StopLossMarginInAssetCurrency,
  InitialMarginInAssetCurrency, DefaultStopLossPercentage, DefaultTakeProfitPercentage, AllowedRateDiffPercentage, AllowedRateDiffPercentageUpside)
VALUES (99999, 2.50, 75.00, 500.00, 1000.00, 10.00, 25.00, 0.50, 0.25);
EXEC Trade.SetInstrumentsDataForOpsAPI @Instruments_NewParams = @Params;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsIDListSetParamsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsIDListSetParamsTbl.sql*
