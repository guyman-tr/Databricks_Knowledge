# Trade.BatchInsertEventsToSbrInstrumentsUpdates

> Inserts instrument configuration update events into the SBR (Service Bus Relay) queue and sync configuration tables when instrument futures values are changed, enabling downstream systems to pick up the changes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentsToSendUpdates (Trade.InstrumentsIDListSetParamsTbl READONLY) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is called when instrument configuration parameters (maintenance margins, stop loss settings, rate diff percentages) are updated. It inserts notification events into `Trade.SbrEventsQueueTable` and `Trade.SyncConfiguration` so that downstream services (risk engine, trading UI, mobile apps) can pick up the changes without polling the configuration tables directly.

Without this procedure, instrument configuration changes would only be reflected in the database tables, and downstream consumers would need to periodically re-read configuration - causing delays and stale data. The SBR event queue enables push-style notification.

The procedure performs two distinct inserts: (1) EventTypeID=4 (InstrumentFuturesValuesUpdatedNotifications) with a JSON payload containing all margin/SL/rate-diff fields - only for rows where at least one field is non-NULL, and (2) ConfigurationUpdateTypeID=27 (DefaultTakeProfitPercentage) into Trade.SyncConfiguration for instruments with updated TakeProfit defaults.

---

## 2. Business Logic

### 2.1 SBR Event Queue Insert (Margin/SL Parameters)

**What**: Inserts JSON-formatted events for instrument margin and stop loss parameter changes.

**Columns/Parameters Involved**: `Leverage1MaintenanceMargin`, `MaxStopLossPercentage`, `StopLossMarginInAssetCurrency`, `InitialMarginInAssetCurrency`, `DefaultStopLossPercentage`, `AllowedRateDiffPercentage`, `AllowedRateDiffPercentageUpside`

**Rules**:
- EventTypeID = 4 identifies these as instrument futures value update notifications
- EventData is JSON (FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) containing InstrumentID + all changed fields
- Only inserts if at least one of the 7 fields is non-NULL (OR chain in WHERE)
- Does NOT insert if all fields are NULL (no actual change to propagate)

### 2.2 Sync Configuration Insert (TakeProfit Default)

**What**: Separately syncs the DefaultTakeProfitPercentage through the sync configuration mechanism.

**Rules**:
- ConfigurationUpdateTypeID = 27 identifies this as a DefaultTakeProfitPercentage update
- Only inserts where DefaultTakeProfitPercentage IS NOT NULL
- Value column contains the new percentage

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentsToSendUpdates | Trade.InstrumentsIDListSetParamsTbl READONLY | NO | - | CODE-BACKED | TVP containing instrument IDs and their updated parameter values. Includes InstrumentID, Leverage1MaintenanceMargin, MaxStopLossPercentage, StopLossMarginInAssetCurrency, InitialMarginInAssetCurrency, DefaultStopLossPercentage, AllowedRateDiffPercentage, AllowedRateDiffPercentageUpside, DefaultTakeProfitPercentage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | Trade.SbrEventsQueueTable | WRITER | Queues EventTypeID=4 notifications with JSON payload |
| INSERT | Trade.SyncConfiguration | WRITER | Syncs DefaultTakeProfitPercentage (TypeID=27) |
| @InstrumentsToSendUpdates | Trade.InstrumentsIDListSetParamsTbl | UDT Parameter | TVP containing instrument parameter updates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetInstrumentsDataForOpsAPI | - | Caller | Called after instrument data is updated |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.BatchInsertEventsToSbrInstrumentsUpdates (procedure)
+-- Trade.SbrEventsQueueTable (table)
+-- Trade.SyncConfiguration (table)
+-- Trade.InstrumentsIDListSetParamsTbl (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SbrEventsQueueTable | Table | WRITER - instrument update event queue |
| Trade.SyncConfiguration | Table | WRITER - DefaultTakeProfitPercentage sync |
| Trade.InstrumentsIDListSetParamsTbl | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

No SQL-level dependents found. Called by Trade.SetInstrumentsDataForOpsAPI.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| QUOTED_IDENTIFIER OFF | JSON compatibility | Required for JSON generation |

---

## 8. Sample Queries

### 8.1 Check recent SBR events for instrument updates

```sql
SELECT  TOP 10 EventTypeID, EventData, InsertDate
FROM    Trade.SbrEventsQueueTable WITH (NOLOCK)
WHERE   EventTypeID = 4
ORDER BY InsertDate DESC;
```

### 8.2 Check sync configuration entries for TakeProfit

```sql
SELECT  TOP 10 InstrumentID, ConfigurationUpdateTypeID, Value
FROM    Trade.SyncConfiguration WITH (NOLOCK)
WHERE   ConfigurationUpdateTypeID = 27
ORDER BY InstrumentID;
```

### 8.3 Parse a JSON event payload

```sql
SELECT  j.*
FROM    Trade.SbrEventsQueueTable e WITH (NOLOCK)
CROSS APPLY OPENJSON(e.EventData) WITH (
    InstrumentID INT,
    Leverage1MaintenanceMargin DECIMAL(18,8),
    MaxStopLossPercentage DECIMAL(18,8)
) j
WHERE   e.EventTypeID = 4;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BatchInsertEventsToSbrInstrumentsUpdates | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.BatchInsertEventsToSbrInstrumentsUpdates.sql*
