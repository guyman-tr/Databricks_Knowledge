# Billing.MSSQL_TemporalHistoryFor_941102989

> Temporal history table automatically maintained by SQL Server for Billing.RedeemFeeSettings, capturing all historical states of copy-trade redemption fee configurations for audit and point-in-time queries.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table (Temporal History for Billing.RedeemFeeSettings) |
| **Key Identifier** | No PK - clustered index on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

Billing.MSSQL_TemporalHistoryFor_941102989 is the SQL Server system-versioned temporal history table for Billing.RedeemFeeSettings. SQL Server automatically writes to this table whenever a row in RedeemFeeSettings is updated or deleted - the old row values are archived here with the timestamps (SysStartTime, SysEndTime) recording the period when that configuration was active.

This table exists because RedeemFeeSettings stores financial fee configuration (redemption fees for copy-trading positions) that may change over time. The temporal history allows compliance teams to query "what fee was in effect for this instrument/player level/redeem type on this date?" - essential for auditing fee calculations on historical redemption transactions. Without this history, fee changes would overwrite the old configuration with no audit trail.

The table is never written to directly - SQL Server's SYSTEM_VERSIONING engine manages it automatically when RedeemFeeSettings rows change. To query historical RedeemFeeSettings, use the `FOR SYSTEM_TIME AS OF` syntax against the main table rather than querying this history table directly.

---

## 2. Business Logic

### 2.1 Temporal Period Coverage

**What**: Each row in this table represents one historical state of a RedeemFeeSettings row, with SysStartTime/SysEndTime marking the validity window.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `InstrumentID`, `PlayerLevelID`, `RedeemTypeID`

**Rules**:
- When a RedeemFeeSettings row is updated: the old values are inserted here with SysStartTime = the row's original SysStartTime, SysEndTime = the current UTC time.
- When a RedeemFeeSettings row is deleted: the row is moved here with SysEndTime = deletion timestamp.
- No SysEndTime = 9999-12-31 rows exist here (those live in the main table as the current state).
- The combination (InstrumentID, PlayerLevelID, RedeemTypeID) + SysStartTime uniquely identifies a historical state.
- To reconstruct the fee that was charged for a specific redemption: join to this table with `WHERE SysStartTime <= @TransactionDate AND SysEndTime > @TransactionDate`.

---

## 3. Data Overview

Temporal history tables store raw point-in-time snapshots. Query the main table Billing.RedeemFeeSettings using `FOR SYSTEM_TIME AS OF` for point-in-time queries, which automatically includes this history table in its query plan.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Trading instrument (asset) for which the redemption fee applied. Part of the natural key (InstrumentID, PlayerLevelID, RedeemTypeID). Implicit FK to Dictionary.Currency (instrument registry). |
| 2 | PlayerLevelID | int | NO | - | CODE-BACKED | eToro Club loyalty tier for which this fee applied. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Implicit FK to Dictionary.PlayerLevel. |
| 3 | MinimumFee | decimal(18,2) | YES | - | CODE-BACKED | Minimum fee charged for a redemption transaction, in USD. NULL means no minimum floor. Inherited from RedeemFeeSettings column definition. |
| 4 | MaximumFee | decimal(18,2) | YES | - | CODE-BACKED | Maximum fee cap for a redemption transaction, in USD. NULL means no maximum cap. Inherited from RedeemFeeSettings column definition. |
| 5 | FeeInPercentage | decimal(18,2) | NO | - | CODE-BACKED | The percentage-based fee charged for redemption (e.g., 0.50 = 0.5%). The operative fee - MinimumFee and MaximumFee are applied as floor/ceiling on the percentage-computed amount. |
| 6 | ModificationDate | datetime | YES | - | CODE-BACKED | UTC timestamp when the original RedeemFeeSettings row was last manually modified before this history record was created. DEFAULT GETUTCDATE() on the main table. |
| 7 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row became the active configuration in RedeemFeeSettings. Set by SQL Server's system-versioning engine. Used for temporal range queries. |
| 8 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row was superseded (by an UPDATE or DELETE on RedeemFeeSettings). Clustered index lead column for efficient temporal lookup. |
| 9 | RedeemTypeID | int | NO | - | CODE-BACKED | Type of redemption operation. DEFAULT (0) on main table. Part of the PK (InstrumentID, PlayerLevelID, RedeemTypeID) on RedeemFeeSettings. Likely an enum distinguishing types of copy-trade redemption scenarios. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (main table) | Billing.RedeemFeeSettings | Temporal History | This table is the SYSTEM_VERSIONING history table for Billing.RedeemFeeSettings. SQL Server writes to it automatically on UPDATE/DELETE of RedeemFeeSettings rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server Engine | - | Auto-write | Writes here automatically when RedeemFeeSettings rows are changed. Never written to directly. |
| Billing.RedeemFeeSettings | HISTORY_TABLE | Temporal link | Declared as `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Billing].[MSSQL_TemporalHistoryFor_941102989])` |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MSSQL_TemporalHistoryFor_941102989 (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies (temporal history tables have no FK constraints by design).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemFeeSettings | Table | Temporal main table - writes to this history table automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MSSQL_TemporalHistoryFor_941102989 | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compressed, DICTIONARY filegroup) |

### 7.2 Constraints

None (temporal history tables have no PK or FK constraints by SQL Server design).

---

## 8. Sample Queries

### 8.1 Get fee configuration that was active on a specific date (preferred - via main table)

```sql
-- Use FOR SYSTEM_TIME AS OF to query RedeemFeeSettings at a point in time
-- SQL Server automatically includes this history table in the query plan
SELECT *
FROM Billing.RedeemFeeSettings
FOR SYSTEM_TIME AS OF '2024-01-15 12:00:00'
WHERE InstrumentID = 123   -- specific instrument
ORDER BY PlayerLevelID
```

### 8.2 View raw history rows for a specific instrument

```sql
SELECT
    h.InstrumentID,
    h.PlayerLevelID,
    h.RedeemTypeID,
    h.FeeInPercentage,
    h.MinimumFee,
    h.MaximumFee,
    h.SysStartTime AS ActiveFrom,
    h.SysEndTime AS ActiveTo
FROM Billing.MSSQL_TemporalHistoryFor_941102989 h WITH (NOLOCK)
WHERE h.InstrumentID = 123
ORDER BY h.SysStartTime DESC
```

### 8.3 Get full fee history including current config (UNION with main table)

```sql
SELECT InstrumentID, PlayerLevelID, RedeemTypeID, FeeInPercentage, SysStartTime, SysEndTime
FROM Billing.RedeemFeeSettings FOR SYSTEM_TIME ALL
WHERE InstrumentID = 123
ORDER BY SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.5/10, Logic: 8.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.MSSQL_TemporalHistoryFor_941102989 | Type: Table (Temporal History) | Source: etoro/etoro/Billing/Tables/Billing.MSSQL_TemporalHistoryFor_941102989.sql*
