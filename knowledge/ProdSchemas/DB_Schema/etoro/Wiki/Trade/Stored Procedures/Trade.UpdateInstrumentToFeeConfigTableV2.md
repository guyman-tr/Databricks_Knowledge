# Trade.UpdateInstrumentToFeeConfigTableV2

> Upserts instrument fee configurations (overnight and end-of-week fees for leveraged/non-leveraged, buy/sell) via MERGE, syncs the configuration changes for cache invalidation, and triggers rollover fee alerts when applicable.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID + SettlementTypeID (composite key for fee configuration) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentToFeeConfigTableV2 manages the configuration of overnight (rollover) and end-of-week fees for financial instruments. These fees are charged to positions held overnight or over weekends, with different rates for leveraged vs non-leveraged positions and buy vs sell directions. The procedure supports both updating existing configurations and inserting new ones via MERGE.

After updating the fee configuration, the procedure:
1. Inserts sync records into Trade.SyncConfiguration (ConfigurationUpdateTypeID=5) with full XML payloads for cache invalidation across trading servers
2. Triggers rollover fee alerts (Trade.RolloverFeesAlertIfNeeded) unless the update was triggered by a split process

---

## 2. Business Logic

### 2.1 Fee Configuration Upsert

**What**: Merges fee configuration values into Trade.InstrumentToFeeConfigV2.

**Columns/Parameters Involved**: All 8 fee columns, `InstrumentID`, `SettlementTypeID`, `FeeCalculationTypeID`

**Rules**:
- MERGE on InstrumentID + SettlementTypeID (composite key)
- WHEN MATCHED: updates all fee values, FeeCalculationTypeID, UpdatedByUser, and Occurred timestamp
- WHEN NOT MATCHED: inserts full new record
- Fee columns: NonLeveragedSellEndOfWeekFee, NonLeveragedBuyEndOfWeekFee, NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee, LeveragedSellEndOfWeekFee, LeveragedBuyEndOfWeekFee, LeveragedBuyOverNightFee, LeveragedSellOverNightFee

### 2.2 Configuration Synchronization

**What**: Inserts sync records for trading server cache invalidation.

**Columns/Parameters Involved**: `Trade.SyncConfiguration`, `ConfigurationUpdateTypeID=5`

**Rules**:
- One row per InstrumentID from the TVP
- Value column contains XML representation (FOR XML PATH + ROOT) of all fee settings
- Enables real-time propagation of fee changes to trading servers

### 2.3 Rollover Fee Alert

**What**: Triggers alert if fee changes warrant attention (unless triggered by split).

**Columns/Parameters Involved**: `@UpdatedByUser`, `@IsAlertTriggered`

**Rules**:
- Skipped when @UpdatedByUser = 'split' (automated split process)
- Calls Trade.RolloverFeesAlertIfNeeded
- Returns @IsAlertTriggered OUTPUT to caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FeeValuesTbl | Trade.InstrumentToFeeConfigTypeV2 | NO | - | CODE-BACKED | Table-Valued Parameter (TVP, READONLY) containing one or more fee configurations to upsert. Keyed by InstrumentID + SettlementTypeID. Contains 8 fee columns + FeeCalculationTypeID. |
| 2 | @UpdatedByUser | VARCHAR(50) | YES | NULL | CODE-BACKED | Username or identifier of who made the change. When 'split', skips alert triggering. |
| 3 | @IsAlertTriggered | BIT | YES | 0 | CODE-BACKED | OUTPUT: Set to 1 if the rollover fee alert was triggered by Trade.RolloverFeesAlertIfNeeded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID + SettlementTypeID | Trade.InstrumentToFeeConfigV2 | MERGE (UPSERT) | Target table for fee configurations |
| ConfigurationUpdateTypeID=5 | Trade.SyncConfiguration | INSERT | Sync records for cache invalidation with XML payload |
| @FeeValuesTbl | Trade.InstrumentToFeeConfigTypeV2 | Type | TVP type definition |
| - | Trade.RolloverFeesAlertIfNeeded | EXEC | Triggers alert when fee changes warrant attention |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Fee management UI / API | External | EXEC | Called when administrators update instrument fees |
| Split process | Internal | EXEC | Called with @UpdatedByUser='split' during stock splits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentToFeeConfigTableV2 (procedure)
+-- Trade.InstrumentToFeeConfigV2 (table)
+-- Trade.InstrumentToFeeConfigTypeV2 (type - TVP)
+-- Trade.SyncConfiguration (table)
+-- Trade.RolloverFeesAlertIfNeeded (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfigV2 | Table | MERGE - fee configuration target |
| Trade.InstrumentToFeeConfigTypeV2 | UDT (TVP) | Input parameter type |
| Trade.SyncConfiguration | Table | INSERT - configuration sync for cache invalidation |
| Trade.RolloverFeesAlertIfNeeded | Procedure | EXEC - triggers alert if needed |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Fee management application | External | EXEC - administrator fee updates |
| Split processing pipeline | Internal | EXEC - fee adjustments during splits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MERGE composite key | Uniqueness | InstrumentID + SettlementTypeID determines insert vs update |
| FOR XML PATH | Serialization | Fee configuration serialized to XML for sync propagation |
| 'split' bypass | Alert suppression | @UpdatedByUser='split' skips rollover alert |
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| TRY/CATCH with THROW | Error handling | Re-throws errors to caller |

---

## 8. Sample Queries

### 8.1 View current fee configuration for an instrument

```sql
SELECT InstrumentID, SettlementTypeID,
       NonLeveragedBuyOverNightFee, NonLeveragedSellOverNightFee,
       LeveragedBuyOverNightFee, LeveragedSellOverNightFee,
       NonLeveragedBuyEndOfWeekFee, NonLeveragedSellEndOfWeekFee,
       LeveragedBuyEndOfWeekFee, LeveragedSellEndOfWeekFee,
       FeeCalculationTypeID, UpdatedByUser, Occurred
FROM   Trade.InstrumentToFeeConfigV2 WITH (NOLOCK)
WHERE  InstrumentID = 1001;
```

### 8.2 View recent fee sync records

```sql
SELECT TOP 20 ConfigurationUpdateTypeID, InstrumentID, Value
FROM   Trade.SyncConfiguration WITH (NOLOCK)
WHERE  ConfigurationUpdateTypeID = 5
ORDER BY 1 DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (RolloverFeesAlertIfNeeded) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentToFeeConfigTableV2 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentToFeeConfigTableV2.sql*
