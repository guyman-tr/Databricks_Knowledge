# BI_DB_dbo.BI_DB_Dummy

> 0-row placeholder table used exclusively for Service Broker (SB) infrastructure and migration purposes. The associated `SP_Dummy` does nothing (PRINT 'Hello World') — this table exists only to satisfy the OpsDB SB_Daily orchestration framework requirement that every SP has a target table.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `SP_Dummy` — no-op placeholder SP |
| **Refresh** | SB_Daily (SP runs but does nothing) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Eyal Boas (2023-05-08) |

---

## 1. Business Meaning

This is an infrastructure placeholder table with no business content. It exists solely to satisfy the OpsDB Service Broker (SB) orchestration framework, which requires that every registered stored procedure has a corresponding target table entry. The SP_Dummy procedure runs daily as part of SB_Daily but performs no data operations — it only prints "Hello World".

The table has 0 rows and has never been populated. It has no analytical or business purpose.

---

## 2. Business Logic

### 2.1 No-Op Execution

**What**: SP_Dummy is a placeholder that performs no data operations.
**Columns Involved**: None
**Rules**:
- SP body contains only `PRINT 'Hello World'`
- No INSERT, UPDATE, DELETE, or SELECT statements
- Registered in OpsDB at Priority 0, SB_Daily, ProcessType 1

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no optimization needed for a 0-row table.

### 3.2 Common Query Patterns

No queries are expected against this table. It contains no data.

### 3.3 Common JOINs

None.

### 3.4 Gotchas

- **Always empty**: This table has 0 rows and is never populated by SP_Dummy
- **Infrastructure-only**: Exists solely for SB orchestration framework compliance
- **Do not delete**: Removing this table or SP would break the OpsDB SB_Daily registration

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki documentation |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / propagation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Placeholder column. Never populated — table has 0 rows. Column exists to give the table a minimal schema. (Tier 3 — DDL, no data evidence) |

---

## 5. Lineage

### 5.1 Production Sources

No production sources. SP_Dummy does not read from or write to any tables.

### 5.2 ETL Pipeline

```
(no data sources)
  |
  |-- SP_Dummy (PRINT 'Hello World') --|
  |   No INSERT/UPDATE/DELETE          |
  v
BI_DB_dbo.BI_DB_Dummy (0 rows, always empty)
  |
  (UC: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None.

### 6.2 Referenced By (other objects point to this)

None.

---

## 7. Sample Queries

No sample queries — this table contains no data and serves no analytical purpose.

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 6/14*
*Tiers: 0 T1, 0 T2, 1 T3, 0 T4, 0 T5 | Elements: 1/1, Logic: N/A, Completeness: 7/10*
*Object: BI_DB_dbo.BI_DB_Dummy | Type: Table | Production Source: SP_Dummy (no-op placeholder)*
