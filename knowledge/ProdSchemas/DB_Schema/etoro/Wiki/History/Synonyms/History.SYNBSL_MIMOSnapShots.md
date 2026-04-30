# History.SYNBSL_MIMOSnapShots

> Synonym aliasing the BslLogs database table that stores MIMO (Market Impact Model Operations) snapshots captured by the BSL (Business Services Layer or Bulk Stock Ledger) system, providing History-schema access to cross-database BSL/MIMO state snapshot data.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [BslLogs].[History].[BSL_MIMOSnapShots] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.SYNBSL_MIMOSnapShots` is a synonym pointing to `[BslLogs].[History].[BSL_MIMOSnapShots]` in the `BslLogs` database. The "SYN" prefix marks this as a synonym (consistent with `History.SYNCurrencyPriceMaxDate` and `History.SYN_MoveRecsFromDagSyncTslToPass_BCP`).

**BSL** likely refers to the Bulk Stock Ledger or Business Services Layer - a component that manages aggregate stock positions and the associated pricing/market-impact calculations. **MIMO** likely refers to "Market Impact Model Operations" - the calculations that determine how large bulk stock positions affect market prices (market impact modeling).

`MIMOSnapShots` captures periodic state snapshots of the MIMO system: the current state of large position calculations, market impact estimates, and related metrics at a point in time. These snapshots are stored in `BslLogs` as the authoritative log database for BSL operations, and the History-schema synonym provides access for cross-schema reporting and reconciliation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym (pointer object). See `[BslLogs].[History].[BSL_MIMOSnapShots]` for the snapshot data structure.

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[BslLogs].[History].[BSL_MIMOSnapShots]`.

---

## 4. Elements

N/A for Synonym. All elements are defined on the target table in BslLogs.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [BslLogs].[History].[BSL_MIMOSnapShots] | Synonym | Points to the BSL/MIMO snapshot log in BslLogs database |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SYNBSL_MIMOSnapShots (synonym)
+-- [BslLogs].[History].[BSL_MIMOSnapShots] (external table - BslLogs database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BslLogs].[History].[BSL_MIMOSnapShots] | External Table | Target in BslLogs database |

### 6.2 Objects That Depend On This

No dependents found in local schema analysis.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query MIMO snapshots

```sql
SELECT TOP 10 *
FROM History.SYNBSL_MIMOSnapShots WITH (NOLOCK)
```

### 8.2 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'SYNBSL_MIMOSnapShots'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.3 List all SYN-prefixed synonyms in History schema

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.name LIKE 'SYN%'
ORDER BY s.name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SYNBSL_MIMOSnapShots | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.SYNBSL_MIMOSnapShots.sql*
