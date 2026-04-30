# Billing.CFTWhiteListForAllProtocols_20082022

> Point-in-time archive snapshot of Billing.CFTWhiteListForAllProtocols taken on 20 August 2022 - preserved for historical reference; not deployed in the current production database.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY, no explicit PK constraint) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | None |

---

## 1. Business Meaning

`Billing.CFTWhiteListForAllProtocols_20082022` is a dated archive snapshot of `Billing.CFTWhiteListForAllProtocols`, captured on 20 August 2022 (date encoded in the table name: 20/08/2022). It preserves the CFT BIN-to-protocol whitelist as it existed at that point in time.

The table is structurally identical to `Billing.CFTWhiteListForAllProtocols` except: (1) `SixDigitsBin` is a stored `int` column rather than a computed column, and (2) there is no PK constraint, no indexes, and it resides on the DICTIONARY filegroup rather than PRIMARY. The absence of constraints and indexes confirms this is a one-time data copy for audit/rollback purposes, not an active table.

The table does NOT exist in the current production database (query returns "Invalid object name") - it exists only as a DDL definition in the SSDT repo. It may have been created for a migration or investigation and subsequently dropped from production.

---

## 2. Business Logic

No active business logic. This is an archive snapshot table. See `Billing.CFTWhiteListForAllProtocols` for the active CFT BIN whitelist and its logic.

---

## 3. Data Overview

Table not deployed in current production database - no live data available.

Structure mirrors `Billing.CFTWhiteListForAllProtocols` as of August 20, 2022. At that time, the table would have contained the CFT-eligible BIN ranges and their authorized payment protocols.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Sequential row identifier, auto-incremented. No NOT FOR REPLICATION flag (unlike the live table). No PK constraint. |
| 2 | BIN | bigint | NO | - | CODE-BACKED | Card BIN prefix. Same semantics as Billing.CFTWhiteListForAllProtocols.BIN. |
| 3 | ProtocolID | int | NO | - | CODE-BACKED | Payment protocol authorized for CFT on this BIN. Same semantics as Billing.CFTWhiteListForAllProtocols.ProtocolID. |
| 4 | SixDigitsBin | int | YES | - | CODE-BACKED | 6-digit normalized BIN. In the archive, this is a stored int (NOT a computed column, unlike the live table where it is computed). Was populated with LEFT(BIN,6) at snapshot time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | Implicit FK | Same relationship as in the live CFTWhiteListForAllProtocols. |

### 5.2 Referenced By (other objects point to this)

No dependents found. This archive table is not referenced by any stored procedure or view.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None. Archive snapshot table - no indexes defined.

### 7.2 Constraints

None. No PK or FK constraints defined.

Filegroup: DICTIONARY. Stored on the same filegroup as dictionary/lookup data.

---

## 8. Sample Queries

### 8.1 Check if table exists in current environment

```sql
SELECT OBJECT_ID('Billing.CFTWhiteListForAllProtocols_20082022') AS ObjectID;
-- Returns NULL if not deployed (as is the case in current production)
```

### 8.2 Compare archive snapshot to current live table (if deployed)

```sql
SELECT 'Live' AS Source, BIN, ProtocolID FROM [Billing].[CFTWhiteListForAllProtocols] WITH (NOLOCK)
WHERE BIN NOT IN (SELECT BIN FROM [Billing].[CFTWhiteListForAllProtocols_20082022] WITH (NOLOCK))
UNION ALL
SELECT 'Archive' AS Source, BIN, ProtocolID FROM [Billing].[CFTWhiteListForAllProtocols_20082022] WITH (NOLOCK)
WHERE BIN NOT IN (SELECT BIN FROM [Billing].[CFTWhiteListForAllProtocols] WITH (NOLOCK));
```

### 8.3 View archive data

```sql
SELECT TOP 10 ID, BIN, ProtocolID, SixDigitsBin
FROM [Billing].[CFTWhiteListForAllProtocols_20082022] WITH (NOLOCK)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CFTWhiteListForAllProtocols_20082022 | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CFTWhiteListForAllProtocols_20082022.sql*
