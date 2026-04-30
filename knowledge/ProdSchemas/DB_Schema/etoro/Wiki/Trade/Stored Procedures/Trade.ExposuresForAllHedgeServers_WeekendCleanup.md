# Trade.ExposuresForAllHedgeServers_WeekendCleanup

> Weekend-only maintenance job that deletes zero-exposure records from the hedge exposure table in batches of 4,000 rows to reclaim space.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Runs only on Saturday (day of week = 7) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a weekend housekeeping job for the `Trade.ExposuresForAllHedgeServers` table. Over time, the exposure table accumulates records where both `OpenedBuy` and `OpenedSell` have been decremented to zero (all positions for that customer/provider/instrument/hedge server combination have been closed). These zero-exposure records serve no purpose but consume space and slow down queries.

The procedure runs only on Saturdays (when markets are closed and no position activity occurs) to avoid contention with the real-time `_Update` and `_Check` procedures. It deletes zero-exposure records in batches of 4,000 rows to minimize lock duration and transaction log pressure.

The procedure was created in 2014 (FB 22184) as part of the optimization work that also switched `_Check` from table variables to temp tables.

---

## 2. Business Logic

### 2.1 Weekend-Only Guard

**What**: Prevents accidental execution during trading hours.

**Columns/Parameters Involved**: `DATEPART(dw, GETDATE())`

**Rules**:
- Checks if current day is Saturday (day of week = 7)
- If not Saturday: RETURN immediately without doing anything
- This prevents the DELETE operations from interfering with real-time exposure updates during market hours

### 2.2 Batched Zero-Exposure Deletion

**What**: Removes records where both buy and sell exposures are zero.

**Columns/Parameters Involved**: `OpenedBuy`, `OpenedSell`

**Rules**:
- Deletes records where OpenedBuy = 0 AND OpenedSell = 0
- Uses SET ROWCOUNT 4000 to limit each DELETE to 4,000 rows
- Loops until no more zero-exposure records remain (@@ROWCOUNT = 0)
- Batching prevents long-running transactions and excessive log growth

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No parameters. Deletes all zero-exposure records across the entire table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | Trade.ExposuresForAllHedgeServers | DELETER | Removes rows where OpenedBuy=0 AND OpenedSell=0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled (Saturday) | Job | Weekend maintenance job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExposuresForAllHedgeServers_WeekendCleanup (procedure)
+-- Trade.ExposuresForAllHedgeServers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExposuresForAllHedgeServers | Table | DELETE - removes zero-exposure records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Uses deprecated `SET ROWCOUNT` for batch control. Modern equivalent would be `DELETE TOP (4000)`.

---

## 8. Sample Queries

### 8.1 Run Weekend Cleanup (Must Be Saturday)

```sql
EXEC Trade.ExposuresForAllHedgeServers_WeekendCleanup
```

### 8.2 Preview Zero-Exposure Records That Would Be Deleted

```sql
SELECT COUNT(*) AS ZeroExposureCount
  FROM Trade.ExposuresForAllHedgeServers WITH (NOLOCK)
 WHERE OpenedBuy = 0 AND OpenedSell = 0
```

### 8.3 Check Exposure Table Size and Zero-Record Ratio

```sql
SELECT COUNT(*) AS TotalRows,
       SUM(CASE WHEN OpenedBuy = 0 AND OpenedSell = 0 THEN 1 ELSE 0 END) AS ZeroRows,
       CAST(SUM(CASE WHEN OpenedBuy = 0 AND OpenedSell = 0 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS ZeroPct
  FROM Trade.ExposuresForAllHedgeServers WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExposuresForAllHedgeServers_WeekendCleanup | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ExposuresForAllHedgeServers_WeekendCleanup.sql*
