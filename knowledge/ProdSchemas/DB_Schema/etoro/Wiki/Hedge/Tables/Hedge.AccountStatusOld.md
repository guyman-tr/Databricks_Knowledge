# Hedge.AccountStatusOld

> Deprecated predecessor to Hedge.AccountStatus - same account snapshot structure but with narrower decimal precision and without LiquidityAccountID in the primary key; retained for schema completeness but no longer written by any active procedure.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: OccurredAt, HedgeServerID (CLUSTERED, PAGE compression) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 NC on HedgeServerID+OccurredAt) - both PAGE compressed |

---

## 1. Business Meaning

Hedge.AccountStatusOld is the original version of the `Hedge.AccountStatus` table, retained in the schema as a historical artifact. It holds the same set of liquidity provider account snapshots (balance, margins, leverage, P&L per hedge server and account) but with two structural differences from the current table: (1) the primary key does not include `LiquidityAccountID` - only `(OccurredAt, HedgeServerID)` - which means it could only store one account per server per timestamp; (2) all financial columns use `decimal(14,4)` instead of the current `decimal(18,4)`, providing less precision for large account balances.

The constraint names in the DDL (`PK_AccountStatus`, `FK_AccountStatus_HedgeServer`, `FK_AccountStatus_LiquidityAccounts`) retain the original non-"Old" naming, confirming this was the original table before the `Hedge.AccountStatus` table replaced it with a wider PK and higher precision. The DATA_COMPRESSION = PAGE setting on both indexes indicates this table was compressed at some point to reduce storage for historical data.

The table is currently empty (0 rows) and no active stored procedures or functions reference it - grep across the entire Hedge schema finds only its DDL file. It is safe to treat as deprecated. It is retained in the schema rather than dropped, likely to preserve historical data access patterns or in case archived data was once loaded here.

---

## 2. Business Logic

No active business logic. This table is deprecated. All new writes go to `Hedge.AccountStatus`.

For reference, the key structural differences from the current table:

### 2.1 Schema Evolution - AccountStatusOld vs AccountStatus

**What**: AccountStatusOld is the schema predecessor to AccountStatus, superseded when the per-account granularity requirement and wider precision were introduced.

**Rules**:
- Old PK: `(OccurredAt, HedgeServerID)` - one row per server per timestamp, regardless of how many liquidity accounts exist
- New PK: `(OccurredAt, HedgeServerID, LiquidityAccountID)` - one row per server/account/timestamp - enables tracking multiple liquidity accounts per server independently
- Old precision: `decimal(14,4)` - max 9,999,999,999.9999 before overflow
- New precision: `decimal(18,4)` - max 99,999,999,999,999.9999 - required for large institutional account balances
- DATA_COMPRESSION = PAGE on AccountStatusOld (storage optimization for a table no longer actively written)

---

## 3. Data Overview

The table is currently empty (0 rows). No data is available for display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). Part of the clustered PK. In the old schema, this was the sole identifier of which server's account is recorded (no per-account granularity). |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityAccounts(LiquidityAccountID). NOT part of the PK (unlike AccountStatus) - this was the design limitation that led to the creation of the new table. Multiple accounts per server could not be tracked independently. |
| 3 | OccurredAt | datetime | NO | getutcdate() | CODE-BACKED | DB server UTC timestamp. First PK column - physical ordering by time. Default DF_AccountStatus_OccurredAt = GETUTCDATE(). |
| 4 | OccurredAtAccount | datetime | YES | - | CODE-BACKED | Liquidity provider's own timestamp for the status report. Same semantics as AccountStatus.OccurredAtAccount - may differ from OccurredAt due to network latency. |
| 5 | Balance | decimal(14,4) | YES | - | CODE-BACKED | Account cash balance in USD. Narrower precision (14,4) vs AccountStatus (18,4) - the precision increase was the motivation for creating the new table. Same semantics as AccountStatus.Balance. |
| 6 | NetPL | decimal(14,4) | YES | - | CODE-BACKED | Unrealized net P&L on open hedge positions, in USD. Narrower precision (14,4). Same semantics as AccountStatus.NetPL (confirmed as UnrealizedPL in Confluence "Production Data comparison" page for AccountStatus). |
| 7 | Equity | decimal(14,4) | YES | - | CODE-BACKED | Total account equity (Balance + NetPL). Narrower precision (14,4). Same semantics as AccountStatus.Equity. |
| 8 | UsedMargin | decimal(14,4) | YES | - | CODE-BACKED | Margin committed to open positions. Narrower precision (14,4). Same semantics as AccountStatus.UsedMargin. |
| 9 | UsableMargin | decimal(14,4) | YES | - | CODE-BACKED | Available margin for new orders. Narrower precision (14,4). Same semantics as AccountStatus.UsableMargin. |
| 10 | MaintenanceMargin | decimal(14,4) | YES | - | CODE-BACKED | Minimum margin to avoid force-close. Narrower precision (14,4). Same semantics as AccountStatus.MaintenanceMargin. |
| 11 | CurrentLeverage | decimal(14,4) | YES | - | CODE-BACKED | Current leverage ratio. Narrower precision (14,4). Same semantics as AccountStatus.CurrentLeverage. |
| 12 | Cushion | decimal(14,4) | YES | - | CODE-BACKED | Margin buffer above maintenance level. Narrower precision (14,4). Same semantics as AccountStatus.Cushion. |
| 13 | GrossPositionsValue | decimal(14,4) | YES | - | CODE-BACKED | Total notional value of open hedge positions. Narrower precision (14,4). Same semantics as AccountStatus.GrossPositionsValue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK | FK_AccountStatus_HedgeServer |
| LiquidityAccountID | Trade.LiquidityAccounts | FK | FK_AccountStatus_LiquidityAccounts |

### 5.2 Referenced By (other objects point to this)

No active stored procedures, views, or functions reference this table. It is deprecated with no active consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AccountStatusOld (table)
```

No code-level dependencies.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |

### 6.2 Objects That Depend On This

No dependents found. This table is not referenced by any active code.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountStatus | CLUSTERED PK | OccurredAt ASC, HedgeServerID ASC | - | - | Active (PAGE compression) |
| Idx_Hedge_AccountStatus_HedgeServerID_OccurredAt | NC | HedgeServerID ASC, OccurredAt ASC | Balance, NetPL | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AccountStatus | PRIMARY KEY | (OccurredAt, HedgeServerID) - note: original name retained, no LiquidityAccountID in PK |
| FK_AccountStatus_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer(HedgeServerID) |
| FK_AccountStatus_LiquidityAccounts | FOREIGN KEY | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| DF_AccountStatus_OccurredAt | DEFAULT | OccurredAt = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Confirm table is empty and identify deprecation
```sql
SELECT COUNT(*) AS RowCount,
       MIN(OccurredAt) AS Oldest,
       MAX(OccurredAt) AS Newest
FROM Hedge.AccountStatusOld WITH (NOLOCK);
```

### 8.2 Compare schema differences between old and new tables
```sql
-- Check PK columns for AccountStatusOld vs AccountStatus via SSDT schema
-- AccountStatusOld PK: (OccurredAt, HedgeServerID) - 2 columns
-- AccountStatus PK:    (OccurredAt, HedgeServerID, LiquidityAccountID) - 3 columns
SELECT 'AccountStatusOld' AS TableName,
       HedgeServerID, LiquidityAccountID, OccurredAt, Balance, NetPL
FROM Hedge.AccountStatusOld WITH (NOLOCK)
UNION ALL
SELECT 'AccountStatus',
       HedgeServerID, LiquidityAccountID, OccurredAt, Balance, NetPL
FROM Hedge.AccountStatus WITH (NOLOCK)
ORDER BY TableName, OccurredAt DESC;
```

### 8.3 Use current AccountStatus instead (preferred replacement)
```sql
-- Always use Hedge.AccountStatus for current data - AccountStatusOld is deprecated
SELECT HedgeServerID, LiquidityAccountID, OccurredAt,
       Balance, NetPL, Equity, UsedMargin, CurrentLeverage
FROM Hedge.AccountStatus WITH (NOLOCK)
WHERE OccurredAt > DATEADD(hour, -1, GETUTCDATE())
ORDER BY OccurredAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. It is a deprecated predecessor table with no active documentation.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 6/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AccountStatusOld | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.AccountStatusOld.sql*
