# Hedge.SynCustomerOpenPositions_New

> Cross-database synonym providing access to the CustomerOpenPositions_New table in the Real (read replica) etoro database, used for replication-safe reads of open customer position data.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Synonym |
| **Key Identifier** | N/A (synonym - no own structure) |
| **Partition** | N/A |
| **Indexes** | N/A (target object indexes apply) |

---

## 1. Business Meaning

`Hedge.SynCustomerOpenPositions_New` is a SQL synonym that points to `[Real].[etoro].[Hedge].[CustomerOpenPositions_New]` - the `CustomerOpenPositions_New` table in the `etoro` database on the `Real` linked server (a read-only replica).

The `Real` linked server represents a read replica of the main etoro production database, used to offload read-heavy queries from the primary. By routing reads through this synonym, the hedge system avoids putting load on the primary `Hedge.CustomerOpenPositions` (or `_New` variant) when reading position data for processing.

The `_New` suffix indicates this is the newer version of the customer open positions table, presumably introduced alongside a data model change. The hedge system accesses this via synonym to abstract away the cross-DB and cross-server complexity.

This synonym is consumed by `Hedge.InsertOpenPosition`, which reads from the replica to reconcile or seed open position data.

---

## 2. Business Logic

### 2.1 Read-Replica Access for Open Position Data

**What**: Provides transparent access to the read replica's CustomerOpenPositions_New for position data reads.

**Columns/Parameters Involved**: N/A (synonym delegates to target object's schema)

**Rules**:
- All reads are served by the `Real` linked server (read replica). Queries benefit from replica offloading without changing SQL code.
- If the `Real` linked server or replication lag causes the replica to be behind, reads via this synonym may return slightly stale data. This is acceptable for the hedge system's position seeding/reconciliation use case.
- Only `Hedge.InsertOpenPosition` is known to reference this synonym in the SSDT project.
- The synonym name prefix `Syn` follows a convention for synonyms pointing to cross-DB objects in this codebase.

**Diagram**:
```
Hedge DB (etoro, primary)
  |
  | SELECT * FROM [Hedge].[SynCustomerOpenPositions_New]
  |
  v
Synonym resolves to:
  [Real] (linked server - read replica)
    -> [etoro] (database)
       -> [Hedge].[CustomerOpenPositions_New] (table)
```

---

## 3. Data Overview

N/A for Synonym.

---

## 4. Elements

N/A for Synonym. The column structure is defined by the target object `[Real].[etoro].[Hedge].[CustomerOpenPositions_New]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | [Real].[etoro].[Hedge].[CustomerOpenPositions_New] | Synonym target | Read replica table holding the new-format customer open positions data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InsertOpenPosition | FROM/JOIN clause | Synonym reference | Reads from the read replica's CustomerOpenPositions_New table via this synonym |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.SynCustomerOpenPositions_New (synonym)
└── [Real].[etoro].[Hedge].[CustomerOpenPositions_New] (external table - read replica)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Real].[etoro].[Hedge].[CustomerOpenPositions_New] | External Table (linked server - replica) | Target of the synonym; reads are routed to the read replica |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InsertOpenPosition | Stored Procedure | Reads customer open position data from the replica via this synonym |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query the read replica's open positions via synonym
```sql
SELECT TOP 100 *
FROM [Hedge].[SynCustomerOpenPositions_New] WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

### 8.2 Check synonym definition
```sql
SELECT name, base_object_name, type_desc
FROM sys.synonyms WITH (NOLOCK)
WHERE schema_id = SCHEMA_ID('Hedge')
  AND name = 'SynCustomerOpenPositions_New'
```

### 8.3 Compare replica vs. primary data freshness
```sql
SELECT MAX(OccurredAt) AS ReplicaMax
FROM [Hedge].[SynCustomerOpenPositions_New] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 7/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.SynCustomerOpenPositions_New | Type: Synonym | Source: etoro/etoro/Hedge/Synonyms/Hedge.SynCustomerOpenPositions_New.sql*
