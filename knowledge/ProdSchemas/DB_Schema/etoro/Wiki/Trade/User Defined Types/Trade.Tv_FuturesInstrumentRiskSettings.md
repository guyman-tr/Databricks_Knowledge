# Trade.Tv_FuturesInstrumentRiskSettings

> TVP for bulk upsert of futures instrument risk settings - stop-loss and take-profit percentage buffers per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Tv_FuturesInstrumentRiskSettings carries risk buffer percentages per futures instrument. StopLossPercentageBuffer and TakeProfitPercentageBuffer define the allowed percentage buffer above/below the configured stop-loss and take-profit levels. This supports futures-specific risk management rules.

The type exists because futures instruments need distinct risk buffer settings. Admin or ops procedures pass batches of (InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer) to Trade.UpsertFuturesInstrumentRiskSettings and Trade.UpdateFuturesOpsConfigurations for bulk upsert.

The type flows from configuration services into the upsert/update procedures. Procedures JOIN the TVP against existing risk settings and INSERT/UPDATE as needed.

---

## 2. Business Logic

InstrumentID + StopLossPercentageBuffer + TakeProfitPercentageBuffer triplet. Each row is one instrument's risk buffer configuration; both buffers can be NULL.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Futures instrument identifier |
| 2 | StopLossPercentageBuffer | decimal(10,2) | YES | - | CODE-BACKED | Allowed percentage buffer for stop-loss |
| 3 | TakeProfitPercentageBuffer | decimal(10,2) | YES | - | CODE-BACKED | Allowed percentage buffer for take-profit |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpsertFuturesInstrumentRiskSettings | @FuturesInstrumentRiskSettings | Parameter (TVP) | Upserts futures instrument risk buffer settings |
| Trade.UpdateFuturesOpsConfigurations | @FuturesInstrumentRiskSettings | Parameter (TVP) | Updates futures ops configurations with risk settings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpsertFuturesInstrumentRiskSettings | Stored Procedure | READONLY parameter for risk settings upsert |
| Trade.UpdateFuturesOpsConfigurations | Stored Procedure | READONLY parameter for futures ops config update |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and upsert single instrument
```sql
DECLARE @FuturesInstrumentRiskSettings Trade.Tv_FuturesInstrumentRiskSettings;
INSERT INTO @FuturesInstrumentRiskSettings (InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer)
VALUES (12345, 0.50, 0.75);
EXEC Trade.UpsertFuturesInstrumentRiskSettings @FuturesInstrumentRiskSettings = @FuturesInstrumentRiskSettings;
```

### 8.2 Batch upsert multiple instruments
```sql
DECLARE @FuturesInstrumentRiskSettings Trade.Tv_FuturesInstrumentRiskSettings;
INSERT INTO @FuturesInstrumentRiskSettings (InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer)
VALUES (100, 0.25, 0.50), (101, 0.50, 0.75), (102, NULL, 1.00);
EXEC Trade.UpsertFuturesInstrumentRiskSettings @FuturesInstrumentRiskSettings = @FuturesInstrumentRiskSettings;
```

### 8.3 Update via UpdateFuturesOpsConfigurations
```sql
DECLARE @FuturesInstrumentRiskSettings Trade.Tv_FuturesInstrumentRiskSettings;
INSERT INTO @FuturesInstrumentRiskSettings (InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer)
VALUES (12345, 1.00, 1.25);
EXEC Trade.UpdateFuturesOpsConfigurations @FuturesInstrumentRiskSettings = @FuturesInstrumentRiskSettings;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.8/10 (Elements: 10/10, Logic: 3/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Tv_FuturesInstrumentRiskSettings | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Tv_FuturesInstrumentRiskSettings.sql*
