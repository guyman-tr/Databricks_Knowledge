# BI_DB_dbo.BI_DB_M_SB_Fiktive_Table

> 0-row placeholder (fiktive) table that serves as a Service Broker scheduling anchor for `SP_M_Notifications_by_LifeStage`. The writer SP is a no-op stub (`print('1')`), and the table contains only a single `tmp_column` that is never populated. This table exists solely to satisfy OpsDB's SP-to-table mapping requirement.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | None — `SP_M_Notifications_by_LifeStage` is a no-op stub |
| **Refresh** | Monthly (OpsDB: SB_Daily, Priority 0) — but no data is written |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This is a **fiktive (placeholder) table** — it does not contain business data and is not used for analytics.

The OpsDB Service Broker orchestration system requires every scheduled stored procedure to be mapped to a target table. When a scheduled SP does not write to a real table (e.g., it sends notifications, triggers external processes, or is a deprecated stub), a fiktive table is created as a mapping anchor.

`SP_M_Notifications_by_LifeStage` is currently a **no-op stub** — its entire body is `print('1')`. It appears to have been a notification SP that was decommissioned but retained in the OpsDB schedule to maintain the SB_Daily execution chain. The fiktive table allows OpsDB to track execution without a real target.

The "SB" prefix in the table name refers to "Service Broker" — the OpsDB scheduling mechanism. Other objects with this pattern may have downstream dependencies that rely on OpsDB tracking the SP's completion status.

---

## 2. Business Logic

### 2.1 No-Op Execution

**What**: The writer SP executes without performing any data operations.
**Rules**:
- SP body: `print('1')` — outputs a message and exits
- No INSERT, UPDATE, DELETE, or SELECT operations
- No temp tables, no JOINs, no data transformation
- The SP likely existed as a real notification procedure at some point and was later gutted

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED COLUMNSTORE INDEX. Irrelevant — the table has 0 rows and is never written to.

### 3.2 Common Query Patterns

No useful queries — the table is empty and will remain empty as long as the SP is a stub.

### 3.3 Common JOINs

None.

### 3.4 Gotchas

- **Do not query this table expecting data**: It is always empty. If it contains data, something unexpected has changed
- **Do not delete this table**: OpsDB maps SP_M_Notifications_by_LifeStage to it. Removing the table may break the SB_Daily execution chain
- **OpsDB dependency**: Other SPs may depend on SP_M_Notifications_by_LifeStage's completion in the OpsDB schedule. The fiktive table ensures OpsDB can track it

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB docs) | Highest — verified against source system documentation |
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 3 | Live data observation | Medium — inferred from data patterns |
| Tier 4 | Contextual inference | Lower — best available knowledge |
| Tier 5 | Standard ETL column | Canonical — well-known ETL metadata pattern |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | tmp_column | varchar(1) | YES | Placeholder column with no business meaning. Never populated. Exists only because Synapse requires at least one column in a table definition. (Tier 2 — SP_M_Notifications_by_LifeStage) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| tmp_column | N/A | N/A | Placeholder — never written |

### 5.2 ETL Pipeline

```
SP_M_Notifications_by_LifeStage (no-op: print('1'))
  |-- No data operations
  v
BI_DB_dbo.BI_DB_M_SB_Fiktive_Table (0 rows — never populated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None.

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|---|---|
| OpsDB Service Broker | SP_M_Notifications_by_LifeStage execution tracking |

---

## 7. Sample Queries

No useful sample queries — the table is always empty.

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 6/14 (stub table — most phases N/A)*
*Tiers: 0 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 1/1, Logic: N/A, Lineage: N/A*
*Object: BI_DB_dbo.BI_DB_M_SB_Fiktive_Table | Type: Table | Production Source: SP_M_Notifications_by_LifeStage (no-op)*
