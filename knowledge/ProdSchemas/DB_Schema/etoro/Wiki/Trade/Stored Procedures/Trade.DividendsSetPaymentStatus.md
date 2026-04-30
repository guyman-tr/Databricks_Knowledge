# Trade.DividendsSetPaymentStatus

> Generic dividend status transition procedure — updates Trade.IndexDividends status from one specified state to another for a batch of dividends.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DividendIDs, @NewStatus, @UpdateWhen |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

While `Trade.DividendsSetPaymentIsComplete` and `Trade.DividendsSetSnapshotIsReady` handle specific hardcoded transitions, this procedure is the **generic state machine driver** for the dividend lifecycle. It allows the dividend service to transition dividend records from any status (@UpdateWhen) to any new status (@NewStatus), providing flexibility for custom or future state transitions without requiring new stored procedures.

This is useful for transitions not covered by the specialized procedures, such as moving dividends to error states, resetting states for reprocessing, or handling edge-case workflows.

---

## 2. Business Logic

### 2.1 Generic Status Transition

**What**: Updates dividend status from @UpdateWhen to @NewStatus.

**Columns/Parameters Involved**: `Trade.IndexDividends.Status`, `@NewStatus`, `@UpdateWhen`

**Rules**:
- UPDATE Trade.IndexDividends SET Status = @NewStatus
- JOIN @DividendIDs TVP on DividendID = ID
- WHERE Status = @UpdateWhen (only transitions from expected state)
- Guard clause prevents unintended transitions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NewStatus | INT | NO | - | CODE-BACKED | Target status value to set on matching dividend records. |
| 2 | @UpdateWhen | INT | NO | - | CODE-BACKED | Required current status — only records at this status will be updated (guard clause). |
| 3 | @DividendIDs | dbo.IdIntList (TVP) | READONLY | - | CODE-BACKED | List of DividendID values to transition. Note: uses dbo.IdIntList (not Trade.IdIntList like sibling procedures). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DividendIDs | Trade.IndexDividends | Write | Updates Status column |
| @DividendIDs | dbo.IdIntList | UDT (TVP) | Integer list table type (different schema than sibling procs) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Dividends service) | N/A | Application caller | Generic status transitions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendsSetPaymentStatus (procedure)
+-- Trade.IndexDividends (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | Dividend state tracking |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Unlike sibling procedures that use `Trade.IdIntList`, this procedure uses `dbo.IdIntList` — a subtle inconsistency that may indicate it was written by a different developer or at a different time. Functionally equivalent for INT ID lists.

---

## 8. Sample Queries

### 8.1 Review dividend status distribution

```sql
SELECT  Status, COUNT(*) AS Cnt
FROM    Trade.IndexDividends WITH (NOLOCK)
GROUP BY Status
ORDER BY Status;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DividendsSetPaymentStatus | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DividendsSetPaymentStatus.sql*
