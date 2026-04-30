# Trade.PositionsHedgeServerChangeLog_DP

> Data-pipeline view that combines legacy pre-2022 hedge server change history (TOP 1 sample) with current PositionsHedgeServerChangeLog for analytics and migration reporting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | OperationSummaryID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.PositionsHedgeServerChangeLog_DP provides a unified history of position hedge server migrations for data pipeline and analytics consumption. Each row represents a single migration event: a position moved from one hedge server to another, with timestamps, rule context, and root hedge server identifiers. The view exists because the platform historically stored pre-2022 migration data in a separate junk table (PositionsHedgeServerChangeLog_INT_2021Junk), and consumers need one access point for the full migration history.

Without this view, analytics and data pipelines would need to query two tables and handle the INT vs BIGINT PositionID type difference. The _DP suffix indicates Data Platform (or Pipeline) usage. The legacy branch is limited to TOP 1 to minimize impact from the junk table - a pragmatic compromise to include some pre-2022 data without full legacy scan.

The view performs a UNION ALL. The first branch selects TOP 1 from the junk table where ADM_DATE < 2022-01-01, converting PositionID to BIGINT for schema compatibility. The second branch selects all rows from the current PositionsHedgeServerChangeLog table.

---

## 2. Business Logic

UNION ALL of two sources. Legacy branch: TOP 1 from PositionsHedgeServerChangeLog_INT_2021Junk where ADM_DATE < '20220101', with CONVERT(BIGINT, PositionID) to normalize INT to BIGINT. Current branch: full select from PositionsHedgeServerChangeLog. Both expose OperationSummaryID, PositionID, ADM_DATE, FromHedgeServerID, ToHedgeServerID, FromRootHedgeServerID, ToRootHedgeServerID, RuleID.

---

## 3. Data Overview

N/A - output combines Trade.PositionsHedgeServerChangeLog_INT_2021Junk (legacy, TOP 1) and Trade.PositionsHedgeServerChangeLog. See base tables for column semantics and data patterns.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationSummaryID | int/bigint | NO | - | CODE-BACKED | Unique identifier for the migration operation. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | Position that was migrated. CONVERT(BIGINT,...) in legacy branch for type alignment. |
| 3 | ADM_DATE | datetime | YES | - | CODE-BACKED | When the migration occurred (admin date). |
| 4 | FromHedgeServerID | int | YES | - | CODE-BACKED | Source hedge server before migration. |
| 5 | ToHedgeServerID | int | YES | - | CODE-BACKED | Target hedge server after migration. |
| 6 | FromRootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server of the source. |
| 7 | ToRootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server of the target. |
| 8 | RuleID | int | YES | - | CODE-BACKED | Rule or policy that triggered the migration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit FK | Position that was migrated |
| FromHedgeServerID, ToHedgeServerID | (HedgeServer) | Implicit FK | Hedge server identifiers |
| RuleID | (Rule dictionary) | Implicit FK | Migration rule reference |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionsHedgeServerChangeLog_DP (view)
    |
    +-- Trade.PositionsHedgeServerChangeLog_INT_2021Junk (table)
    |
    +-- Trade.PositionsHedgeServerChangeLog (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsHedgeServerChangeLog_INT_2021Junk | Table | FROM - legacy pre-2022 data, TOP 1, first branch of UNION ALL |
| Trade.PositionsHedgeServerChangeLog | Table | FROM - current change log, second branch of UNION ALL |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Recent hedge server migrations

```sql
SELECT OperationSummaryID, PositionID, ADM_DATE, FromHedgeServerID, ToHedgeServerID, RuleID
FROM Trade.PositionsHedgeServerChangeLog_DP WITH (NOLOCK)
WHERE ADM_DATE >= DATEADD(day, -30, GETDATE())
ORDER BY ADM_DATE DESC;
```

### 8.2 Migrations by RuleID

```sql
SELECT RuleID, COUNT(*) AS Cnt
FROM Trade.PositionsHedgeServerChangeLog_DP WITH (NOLOCK)
GROUP BY RuleID;
```

### 8.3 Migration volume by date

```sql
SELECT CAST(ADM_DATE AS date) AS MigrationDate, COUNT(*) AS Cnt
FROM Trade.PositionsHedgeServerChangeLog_DP WITH (NOLOCK)
GROUP BY CAST(ADM_DATE AS date)
ORDER BY MigrationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 7.4/10, Relationships: 7.4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsHedgeServerChangeLog_DP | Type: View | Source: etoro/etoro/Trade/Views/Trade.PositionsHedgeServerChangeLog_DP.sql*
