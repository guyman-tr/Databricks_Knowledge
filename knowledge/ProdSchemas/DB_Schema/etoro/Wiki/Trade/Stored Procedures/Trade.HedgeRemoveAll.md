# Trade.HedgeRemoveAll

> Cursor loop that calls Trade.HedgeRemove for every hedge in Trade.Hedge UNION Trade.HedgeRequest. Used for mass hedge cleanup, typically during system resets or failover scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @FailTypeID, @FailReason; Iterates: Trade.Hedge UNION Trade.HedgeRequest; Calls: Trade.HedgeRemove per hedge |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeRemoveAll is a **mass hedge cleanup procedure** that removes every hedge in the system - both live hedges (Trade.Hedge) and pending requests (Trade.HedgeRequest). It calls Trade.HedgeRemove for each HedgeID in sequence, continuing with the next ID if any one fails ("if fail continue with next hedge" comment in source).

This is a **destructive, wide-scope operation**. It is intended for system-level scenarios such as: broker disconnect requiring all hedges to be cleaned up, test environment reset, or disaster recovery. It is NOT the normal lifecycle (that uses HedgeClose/HedgeOpen).

**Important quirk**: This SP calls Trade.HedgeRemove with only 3 arguments (@HedgeID, @FailTypeID, @FailReason) but the current Trade.HedgeRemove signature requires 4 parameters (@FailReasonID has no default). This SP would fail at runtime due to the missing @FailReasonID parameter, suggesting it was not updated when @FailReasonID was added to HedgeRemove.

---

## 2. Business Logic

### 2.1 Full Hedge Enumeration

**What**: UNION of all HedgeIDs from both tables to ensure complete coverage.

**Rules**:
- Cursor: `SELECT HedgeID FROM Trade.Hedge UNION SELECT HedgeID FROM Trade.HedgeRequest` (DISTINCT)
- For each HedgeID: `EXEC Trade.HedgeRemove @HedgeID, @FailTypeID, @FailReason`
- Failures are silently ignored; loop continues with next HedgeID.
- Returns 0 always.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FailTypeID | INTEGER | NO | - | CODE-BACKED | Failure type code passed through to Trade.HedgeRemove for each hedge. Categorizes the mass removal. |
| 2 | @FailReason | VARCHAR(MAX) | NO | - | CODE-BACKED | Human-readable reason passed through to Trade.HedgeRemove for each hedge logged to History.HedgeFail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (cursor source) | Trade.Hedge | SELECT (cursor) | Enumerates live hedges |
| (cursor source) | Trade.HedgeRequest | SELECT (cursor) | Enumerates pending requests |
| @HedgeID | Trade.HedgeRemove | EXEC per cursor row | Delegates removal to core procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Mass cleanup during system resets or failover |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeRemoveAll (procedure)
+-- Trade.Hedge (table) [cursor SELECT]
+-- Trade.HedgeRequest (table) [cursor SELECT]
+-- Trade.HedgeRemove (procedure) [EXEC per HedgeID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | Cursor source - live hedges |
| Trade.HedgeRequest | Table | Cursor source - pending requests |
| Trade.HedgeRemove | Procedure | Called for each HedgeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | System-level mass cleanup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Uses CURSOR (READ_ONLY FORWARD_ONLY STATIC). No transaction around the loop - each HedgeRemove call has its own transaction. Known defect: calls HedgeRemove with 3 args but current signature requires 4 (@FailReasonID is mandatory).

---

## 8. Sample Queries

### 8.1 Remove all hedges (CAUTION: destructive)

```sql
EXEC Trade.HedgeRemoveAll
    @FailTypeID = 99,
    @FailReason = 'System reset - all hedges removed';
```

### 8.2 Count before removal

```sql
SELECT
    (SELECT COUNT(*) FROM Trade.Hedge) AS LiveHedges,
    (SELECT COUNT(*) FROM Trade.HedgeRequest) AS PendingRequests;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 7/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.HedgeRemove) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeRemoveAll | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeRemoveAll.sql*
