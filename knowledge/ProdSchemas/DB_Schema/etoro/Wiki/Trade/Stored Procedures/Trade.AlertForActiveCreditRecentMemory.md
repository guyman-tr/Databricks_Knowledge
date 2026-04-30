# Trade.AlertForActiveCreditRecentMemory

> Returns the row count of History.ActiveCreditRecentMemoryBucket via sp_spaceused for monitoring table growth.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters - returns row count) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a lightweight **monitoring check** that returns the row count of `History.ActiveCreditRecentMemoryBucket`. The ActiveCreditRecentMemory system tracks recent credit activity for customers, and this table can grow significantly. By exposing the row count, monitoring tools or scheduled jobs can detect abnormal growth.

The procedure uses `sp_spaceused` to get table statistics and returns just the `rows` column from the result. This approach avoids the overhead of `COUNT(*)` on a potentially large table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple monitoring utility that returns a single metric.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (none) | - | - | - | - | No input parameters. Returns a single-column result set with the row count of History.ActiveCreditRecentMemoryBucket. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | History.ActiveCreditRecentMemoryBucket | sp_spaceused | Reads table statistics to get row count |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertForActiveCreditRecentMemory (procedure)
+-- History.ActiveCreditRecentMemoryBucket (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditRecentMemoryBucket | Table | sp_spaceused reads table metadata |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check table row count directly

```sql
EXEC Trade.AlertForActiveCreditRecentMemory;
```

### 8.2 Alternative row count check

```sql
SELECT  SUM(p.rows) AS RowCount
FROM    sys.partitions p
WHERE   p.object_id = OBJECT_ID('History.ActiveCreditRecentMemoryBucket')
        AND p.index_id IN (0, 1);
```

### 8.3 Full space usage for the table

```sql
EXEC sp_spaceused '[History].[ActiveCreditRecentMemoryBucket]';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertForActiveCreditRecentMemory | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertForActiveCreditRecentMemory.sql*
