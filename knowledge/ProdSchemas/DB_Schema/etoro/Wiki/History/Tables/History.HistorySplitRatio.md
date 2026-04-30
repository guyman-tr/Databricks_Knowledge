# History.HistorySplitRatio

> SQL Server temporal history table storing prior row versions of History.SplitRatio, capturing every update and delete applied to stock-split processing records since September 2021.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.HistorySplitRatio is the SQL Server system-versioning history table for History.SplitRatio. It is declared as `HISTORY_TABLE = History.HistorySplitRatio` in the SplitRatio DDL. When SQL Server temporal versioning closes a row version in History.SplitRatio (i.e., any UPDATE or DELETE on a SplitRatio row), the old row values are automatically written here with the exact SysStartTime and SysEndTime validity window.

This table enables full audit and time-travel queries on stock-split processing records. Stock splits require adjusting prices, units, open positions, close positions, and orders for affected instruments. The SplitRatio table tracks which adjustments have been completed for each split event; the history table captures every state change in that multi-step process - allowing operators to reconstruct the exact state of split processing at any point in time.

Uniquely, History.SplitRatio has a trigger (Tr_T_SplitRatio_INSERT) that fires on INSERT and immediately performs a no-op UPDATE on the new row, forcing SQL Server temporal versioning to cut an immediate history record. This means every new SplitRatio row produces an immediate history entry with SysStartTime = SysEndTime - visible in the data as rows where both system time columns are identical. Subsequent updates produce additional history rows with non-zero validity windows.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server automatically moves superseded row versions from History.SplitRatio into this table whenever a SplitRatio row is updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- On UPDATE of a SplitRatio row: the previous version is written here with the old SysStartTime and the update timestamp as SysEndTime
- On DELETE of a SplitRatio row: the deleted version is written here with SysEndTime = deletion timestamp
- Rows in this table are immutable - SQL Server never modifies history table rows
- CLUSTERED INDEX on (SysEndTime ASC, SysStartTime ASC) optimizes FOR SYSTEM_TIME AS OF range scans

**Diagram**:
```
History.SplitRatio (live table)
  INSERT -> Tr_T_SplitRatio_INSERT fires -> no-op UPDATE
           -> immediate history row cut (SysStartTime = SysEndTime)
  UPDATE -> old version -> HistorySplitRatio (SysEndTime = update time)
  DELETE -> final version -> HistorySplitRatio (SysEndTime = delete time)
```

### 2.2 Trigger-Induced Insert Artifact

**What**: Every INSERT into History.SplitRatio produces an immediate history record where SysStartTime = SysEndTime because the trigger Tr_T_SplitRatio_INSERT performs a self-UPDATE immediately after insert.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ID`

**Rules**:
- Rows where SysStartTime = SysEndTime are not anomalies - they are the expected artifact of the insert trigger pattern
- This same trigger pattern appears on History.CEPRuleToPosition_Archive - it is a deliberate design to ensure every insert is captured in the temporal history
- The insert artifact row has all IsCompleted flags = 0 (initial state), showing the split record before any processing steps completed

### 2.3 Computed Columns Materialized in History

**What**: History.SplitRatio has DbLoginName, AppLoginName, and HostName as computed (non-persisted) columns. In this history table, they are stored as regular nullable columns containing the evaluated values at the time each row version was closed.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `HostName`

**Rules**:
- DbLoginName: SQL Server login at time of change (e.g., "DevTradingSTG", "TRAD\eladav")
- AppLoginName: Application context_info() - typically NULL in observed data
- HostName: Server or container hostname at time of change (e.g., "market-data-security-master-ops-api-5cc6cc6958-454lr")
- All three are NULL-able because the computed expressions may evaluate to NULL

---

## 3. Data Overview

12,224 rows. Range: 2021-09-13 to 2026-02-17. Active - new versions are being cut regularly.

| ID | InstrumentID | PriceRatio | AmountRatio | SysStartTime | SysEndTime | Meaning |
|----|-------------|-----------|------------|-------------|-----------|---------|
| 12036 | 1053988 | 1.0 | 1.0 | 2026-02-17 16:05:31 | 2026-02-17 16:05:31 | Insert artifact: Tr_T_SplitRatio_INSERT fired immediately after a new SplitRatio record was added for this stock. SysStart=SysEnd indicates the no-op UPDATE that triggers the first version cut. All IsCompleted=0 - split processing not yet started. |
| 11562 | 1048319 | 1.0 | 1.0 | 2025-11-20 09:46:25 | 2026-02-12 11:54:48 | SplitRatio record for stock 1048319 that was live from November 2025 until it was updated or deleted in February 2026. History captures the full set of processing flags at the moment it was superseded. |
| 11561 | 1048303 | 1.0 | 1.0 | 2025-11-20 09:46:24 | 2026-02-12 11:54:48 | Another split record updated/deleted together with 11562 in February 2026 - same SysEndTime suggests a batch update operation ran across multiple instruments simultaneously. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Auto-increment primary key of the SplitRatio row this history version belongs to. Matches History.SplitRatio.ID (IDENTITY). Not a PK in this history table - multiple versions of the same ID appear here as the split progresses. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The stock instrument for which the split is being processed. InstrumentID > 1000 enforced in source table (CHECK constraint CK_InstrumentIsStock). Implicit FK to Trade.Instrument. |
| 3 | MinDate | datetime | NO | '2000-01-01' | CODE-BACKED | Start of the date window during which this split ratio applies to price/amount calculations. Default '2000-01-01' in source table means "applies from the beginning of time" - used for open-ended historical coverage. |
| 4 | MaxDate | datetime | NO | '2100-01-01' | CODE-BACKED | End of the date window during which this split ratio applies. Default '2100-01-01' in source table means "applies indefinitely into the future." Together with MinDate defines the temporal scope of the split adjustment. |
| 5 | PriceRatio | decimal(16,8) | NO | 1 | CODE-BACKED | Price adjustment factor applied to historical prices for this instrument's split event. Must be > 0 (CHECK constraint). PriceRatio=1 means no net price change; values < 1 indicate a stock split (price per share decreases), values > 1 indicate a reverse split. |
| 6 | AmountRatio | decimal(16,8) | NO | 1 | CODE-BACKED | Units/quantity adjustment factor for this split. Must be > 0 (CHECK constraint). AmountRatio=1 means no unit change; values > 1 mean more units per share (stock split), values < 1 mean fewer units (reverse split). PriceRatio * AmountRatio = 1 for a neutral split. |
| 7 | IsCompletedOpenPositions | tinyint | NO | 0 | CODE-BACKED | Processing status flag: 0 = open positions not yet adjusted for this split, 1 = all open positions have been price/amount-adjusted. Part of the multi-step split execution pipeline. |
| 8 | IsCompletedClosePositions | tinyint | NO | 0 | CODE-BACKED | Processing status flag: 0 = closed positions not yet adjusted for this split, 1 = closed positions adjusted. Required to ensure P&L calculations on historical closed positions reflect the correct post-split values. |
| 9 | IsCompletedOpenOrders | tinyint | NO | 0 | CODE-BACKED | Processing status flag: 0 = open orders not yet adjusted, 1 = open orders (limit/stop orders) have had their rates updated to reflect the split ratio. |
| 10 | IsCompletedCloseOrders | tinyint | NO | 0 | CODE-BACKED | Processing status flag: 0 = close orders not yet adjusted, 1 = close orders adjusted for the split. |
| 11 | PriceRatioUnAdjusted | money | NO | - | CODE-BACKED | The raw, unadjusted price ratio as originally recorded before any cumulative adjustment calculations. Stored in money type (lower precision than PriceRatio decimal). Used to preserve the original ratio prior to any rounding or compounding adjustments. |
| 12 | AmountRatioUnAdjusted | money | NO | - | CODE-BACKED | The raw, unadjusted amount ratio as originally recorded. Stored in money type. Counterpart to PriceRatioUnAdjusted for the units dimension. |
| 13 | IsNotificationSent | tinyint | NO | 0 | CODE-BACKED | Flag indicating whether the post-split customer notification has been sent: 0 = notification pending, 1 = notification sent. Controls the notification dispatch step in split processing. |
| 14 | IsCurrencyPriceChanged | tinyint | NO | 0 | CODE-BACKED | Flag indicating whether the instrument's currency price (exchange rate data) has been updated in response to the split: 0 = not updated, 1 = updated. |
| 15 | IsRedisUpdated | tinyint | NO | 0 | CODE-BACKED | Flag indicating whether the Redis cache has been updated with the new post-split prices/ratios: 0 = cache not updated, 1 = Redis updated. Redis holds live price data used by trading engines. |
| 16 | IsNotificationStartSent | tinyint | YES | 0 | CODE-BACKED | Flag indicating whether the pre-split start notification has been sent to customers: 0 = not sent, 1 = sent. Distinct from IsNotificationSent (post-split); this covers the advance warning sent before the split executes. |
| 17 | IsCompletedPricAndAmount | tinyint | YES | 0 | CODE-BACKED | Composite completion flag: 0 = price and amount ratio adjustment not complete, 1 = both price and amount ratios have been applied. May represent a higher-level checkpoint after both PriceRatio and AmountRatio processing finish. |
| 18 | IsCompletedModifyPrice | tinyint | YES | 0 | CODE-BACKED | Flag indicating whether the instrument's displayed price has been modified to reflect the post-split value: 0 = not modified, 1 = price modification complete. Separate from position/order adjustment (IsCompletedOpenPositions etc.). |
| 19 | IsCompleteHoldingFees | tinyint | NO | 0 | CODE-BACKED | Flag indicating whether holding/overnight fee adjustments for the split instrument have been completed: 0 = pending, 1 = complete. Holding fees on leveraged stock positions must be recalculated post-split. |
| 20 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of suser_name() at the time this row version was closed. In source SplitRatio, this is a computed column; here it is stored. Observed values: "DevTradingSTG" (automated service), "TRAD\eladav" (developer/ops). |
| 21 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Materialized snapshot of context_info() at row version close time. Typically NULL in observed data, suggesting the split processing service does not set context_info before its writes. |
| 22 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this historical row version. Set by SQL Server temporal engine to the SysStartTime of the SplitRatio row at the moment the version was superseded. Used in FOR SYSTEM_TIME AS OF queries. |
| 23 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window for this historical row version. Set by SQL Server temporal engine to the timestamp of the UPDATE or DELETE that closed this version. When SysEndTime = SysStartTime, this is an insert artifact from Tr_T_SplitRatio_INSERT (see Section 2.2). CLUSTERED INDEX ordered by (SysEndTime, SysStartTime) for temporal range scan performance. |
| 24 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of host_name() at row version close time. Identifies the server or container that performed the write. Observed: Kubernetes pod names (market-data-security-master-ops-api-...) for automated processing, Windows hostnames (PF5L21F8) for manual operations. |
| 25 | UnitsBefore | decimal(19,12) | YES | - | CODE-BACKED | Unit count held by the instrument (or position) before the split ratio was applied. NULL in all observed history rows, suggesting this column was added after the initial bulk migration and is only populated by more recent writes. |
| 26 | UnitsAfter | decimal(19,12) | YES | - | CODE-BACKED | Unit count after the split ratio was applied. NULL in all observed history rows - same column age caveat as UnitsBefore. Together with UnitsBefore provides a per-row audit of the split's unit adjustment. |
| 27 | PriceRatioUnAdjustedFull | decimal(38,19) | YES | - | CODE-BACKED | High-precision version of PriceRatioUnAdjusted (38 digits, 19 decimal places vs money's 4 decimal places). Added for instruments where the standard money precision is insufficient (e.g., crypto-like sub-cent prices). NULL in all observed history rows - newer column. |
| 28 | AmountRatioUnAdjustedFull | decimal(38,19) | YES | - | CODE-BACKED | High-precision version of AmountRatioUnAdjusted. Same precision rationale as PriceRatioUnAdjustedFull. NULL in all observed history rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (materialized from source FK) | The stock instrument being split. Source table has FK_HistorySplitRatio_TradeInstrument with CHECK InstrumentID > 1000 (stocks only). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.SplitRatio | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | SQL Server temporal engine writes all closed row versions from SplitRatio into this table. Declared as HISTORY_TABLE = [History].[HistorySplitRatio] in SplitRatio DDL. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HistorySplitRatio (table)
  - leaf node: no code-level dependencies (auto-managed by SQL Server temporal engine)
```

### 6.1 Objects This Depends On

No dependencies. This table is created with no foreign keys, computed columns, or UDT references. It is managed entirely by SQL Server temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | Declares this as its HISTORY_TABLE via SYSTEM_VERSIONING. All temporal version rows flow here. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_HistorySplitRatio | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage option | Page-level compression on all data and index pages. Matches the source SplitRatio table compression setting. |

---

## 8. Sample Queries

### 8.1 Retrieve the full version history for a specific split record
```sql
SELECT ID, InstrumentID, PriceRatio, AmountRatio,
       IsCompletedOpenPositions, IsCompletedClosePositions,
       IsNotificationSent, SysStartTime, SysEndTime,
       DbLoginName, HostName
FROM History.HistorySplitRatio WITH (NOLOCK)
WHERE ID = 12036
ORDER BY SysStartTime;
```

### 8.2 Use FOR SYSTEM_TIME ALL to see all versions of a SplitRatio record (live + history)
```sql
SELECT ID, InstrumentID, PriceRatio, AmountRatio,
       IsCompletedOpenPositions, IsNotificationSent,
       SysStartTime, SysEndTime
FROM History.SplitRatio WITH (NOLOCK)
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1048319
ORDER BY SysStartTime;
```

### 8.3 Find insert artifacts vs genuine update history rows
```sql
-- Insert artifacts have SysStartTime = SysEndTime (Tr_T_SplitRatio_INSERT effect)
-- Genuine updates have SysEndTime > SysStartTime
SELECT
    CASE WHEN SysStartTime = SysEndTime THEN 'Insert artifact (trigger)'
         ELSE 'Genuine update version' END AS VersionType,
    COUNT(*) AS RowCount
FROM History.HistorySplitRatio WITH (NOLOCK)
GROUP BY CASE WHEN SysStartTime = SysEndTime THEN 'Insert artifact (trigger)'
              ELSE 'Genuine update version' END;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [History.SplitRatio](https://etoro-jira.atlassian.net/wiki/spaces/TR/pages/2089091204/History.SplitRatio) | Confluence | SplitRatio schema documentation confirming stock split processing step tracking purpose. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed (trigger on SplitRatio analyzed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HistorySplitRatio | Type: Table | Source: etoro/etoro/History/Tables/History.HistorySplitRatio.sql*
