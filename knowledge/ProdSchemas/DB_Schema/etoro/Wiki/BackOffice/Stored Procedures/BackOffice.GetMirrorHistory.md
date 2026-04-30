# BackOffice.GetMirrorHistory

> Returns the chronological credit event history for a specific copy-trading mirror (customer + mirror ID), showing each financial event's action type, cash impact, mirror cash balance, and realized equity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @MirrorID - together identify the copy-trading relationship whose history is returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the full credit event history for a specific copy-trading mirror relationship - answering "what happened financially in this copy relationship?" for BackOffice review. A "mirror" in eToro terminology is a copy-trading subscription: one customer (the copier) replicates trades of another customer (the copied trader). Each financial event (position open, close, dividend, rollover fee, etc.) that occurs within the mirror generates a credit record.

The procedure is used for BackOffice agent investigation of copy-trading disputes, mirror performance review, and account reconciliation. By passing @CID (the copying customer) and @MirrorID (the specific copy relationship), an agent can see the complete timeline of what caused the mirror's cash balance and equity to change.

**Data source evolution** (from inline comments):
- Original (pre-2018): Queried `History.Credit` directly
- 2018-04-10: Updated by Geri Reshef (ticket 50557)
- 2020-11-24: Shay O. switched access to `HistoryGetUnifiedbyCID` function for unified credit history
- 2021-01-03: Shay Oren switched to in-memory `History.ActiveCreditRecentMemoryBucket`
- Current: Queries `History.ActiveCreditBucket_VW` - a view abstracting the in-memory credit bucket

**Permission**: Only VIEW DEFINITION granted to PROD\BIadmins. No active EXECUTE grants to application users - this procedure appears to be used for ad-hoc BI/BackOffice investigation rather than application-layer calls.

---

## 2. Business Logic

### 2.1 Mirror Credit History Retrieval

**What**: Returns all credit events for the given CID+MirrorID combination, ordered newest first.

**Columns/Parameters Involved**: @CID, @MirrorID, Credit.MirrorID, Credit.CID, Occurred

**Rules**:
- Dual filter: `Credit.MirrorID = @MirrorID AND Credit.CID = @CID` - both must match, ensuring the history belongs to this specific customer's specific copy relationship.
- INNER JOIN to `Dictionary.CreditType` - only credit types present in the dictionary are returned (orphaned CreditTypeIDs are excluded). Every valid credit event has a type name.
- ORDER BY Occurred DESC - most recent events first, matching the BackOffice UI pattern of showing latest activity at the top.

### 2.2 Cash Change Calculation

**What**: Computes the net cash impact attributable to the mirror for each credit event.

**Columns/Parameters Involved**: TotalCashChange, Payment, MirrorCashChange

**Rules**:
- `MirrorCashChange = CAST(ISNULL(TotalCashChange - Payment, 0) AS DECIMAL(16,2))`
- `TotalCashChange`: The total cash change for this credit event (positive = cash in, negative = cash out).
- `Payment`: The payment component (e.g., principal or fee amount). Subtracting Payment isolates the mirror-specific net cash change.
- ISNULL(..., 0): If either TotalCashChange or Payment is NULL, the result defaults to 0 rather than propagating NULL.
- CAST to DECIMAL(16,2): Standardizes precision to 2 decimal places for financial display.

### 2.3 History.Mirror LEFT JOIN (Orphaned)

**What**: A LEFT JOIN to `History.Mirror` on MirrorID + MirrorOperationID=2 is present but contributes no columns to the SELECT.

**Columns/Parameters Involved**: History.Mirror.MirrorID, History.Mirror.MirrorOperationID

**Rules**:
- No columns from `HM` (History.Mirror alias) appear in the SELECT list. The LEFT JOIN is effectively a no-op for current output.
- This JOIN is likely a historical artifact from when mirror operation metadata (e.g., close date or stop-copy event) was included in the output and subsequently removed.
- MirrorOperationID=2 in the eToro mirror system typically corresponds to a "close" or "stop copying" operation.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The copying customer's account identifier. Combined with @MirrorID to identify a specific copy-trading relationship. Filters `History.ActiveCreditBucket_VW` on the CID column. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror (copy relationship) identifier. Combined with @CID to uniquely scope the credit history. Corresponds to `BackOffice.Mirror.MirrorID` / `History.Mirror.MirrorID`. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Action | NVARCHAR | NO | - | CODE-BACKED | The credit event type name from `Dictionary.CreditType.Name`. Examples: "Position Close", "Rollover Fee", "Dividend", "Mirror Open", "Mirror Close". Describes what financial event occurred in the mirror. |
| 2 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp of when the credit event occurred. Result set is ordered by this column descending - most recent events first. |
| 3 | MirrorCashChange | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Net cash change attributable to the mirror for this event. Calculated as `TotalCashChange - Payment`. Positive = cash gained in the mirror, negative = cash lost. Defaults to 0 if NULL. |
| 4 | MirrorCash | DECIMAL(16,2) | YES | - | CODE-BACKED | The mirror's cash balance at the time of this credit event. A running snapshot of mirror cash after applying this event. |
| 5 | PositionID | INT | YES | - | CODE-BACKED | The trading position associated with this credit event. NULL for non-position events (e.g., mirror open/close, fee charges not tied to a specific position). Links to `Trade.Position.PositionID`. |
| 6 | RealizedEquity | DECIMAL | YES | - | CODE-BACKED | The mirror's realized equity at the time of this credit event. Sourced from `Credit.MirrorEquity` in `History.ActiveCreditBucket_VW`. Represents the equity value locked in for completed events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Credit source | History.ActiveCreditBucket_VW | Read (FROM) | Primary data source for all credit event columns. View abstracting the in-memory credit bucket (History.ActiveCreditRecentMemoryBucket). |
| Action | Dictionary.CreditType | Lookup (INNER JOIN) | Maps CreditTypeID to human-readable credit type name (Action). |
| @MirrorID | History.Mirror | Left Join (orphaned) | Joined on MirrorID + MirrorOperationID=2 but no columns selected. Historical artifact. |
| @CID | Customer.CustomerStatic | Implicit | CID is the core customer identifier in the Customer schema. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found. Used for ad-hoc BI investigation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetMirrorHistory (procedure)
+-- History.ActiveCreditBucket_VW (view - wraps in-memory credit bucket)
+-- Dictionary.CreditType (table - credit event type names)
+-- History.Mirror (table - LEFT JOIN, orphaned)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditBucket_VW | View | FROM clause; provides all credit event rows including MirrorID, CID, CreditTypeID, TotalCashChange, Payment, MirrorCash, MirrorEquity, PositionID, Occurred |
| Dictionary.CreditType | Table | INNER JOIN on CreditTypeID; provides the human-readable credit event type name (Action) |
| History.Mirror | Table | LEFT JOIN on MirrorID + MirrorOperationID=2; no columns selected - orphaned historical join |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No EXECUTE grants; ad-hoc investigation use only |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dual-key filter | Query logic | `Credit.MirrorID = @MirrorID AND Credit.CID = @CID` - both parameters required for correct scoping |
| ISNULL(..., 0) | Null safety | Prevents NULL propagation in MirrorCashChange calculation |
| INNER JOIN CreditType | Data quality | Only credit events with valid dictionary entries are returned |
| ORDER BY Occurred DESC | Presentation | Latest events first |
| No NOLOCK on main view | Locking | History.ActiveCreditBucket_VW is queried without NOLOCK hint; individual joined tables use NOLOCK |

---

## 8. Sample Queries

### 8.1 Get mirror history for a specific customer and mirror

```sql
EXEC BackOffice.GetMirrorHistory
    @CID = 12345678,
    @MirrorID = 987654
```

### 8.2 Query the underlying data directly

```sql
SELECT
    ct.Name AS Action,
    c.Occurred,
    CAST(ISNULL(c.TotalCashChange - c.Payment, 0) AS DECIMAL(16,2)) AS MirrorCashChange,
    CAST(c.MirrorCash AS DECIMAL(16,2)) AS MirrorCash,
    c.PositionID,
    c.MirrorEquity AS RealizedEquity
FROM History.ActiveCreditBucket_VW c
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK) ON c.CreditTypeID = ct.CreditTypeID
WHERE c.MirrorID = 987654 AND c.CID = 12345678
ORDER BY c.Occurred DESC;
```

### 8.3 Count credit events per type for a mirror

```sql
SELECT ct.Name AS CreditType, COUNT(*) AS EventCount,
       SUM(CAST(ISNULL(c.TotalCashChange - c.Payment, 0) AS DECIMAL(16,2))) AS TotalNetCash
FROM History.ActiveCreditBucket_VW c
INNER JOIN Dictionary.CreditType ct WITH (NOLOCK) ON c.CreditTypeID = ct.CreditTypeID
WHERE c.MirrorID = 987654 AND c.CID = 12345678
GROUP BY ct.Name
ORDER BY EventCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetMirrorHistory | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetMirrorHistory.sql*
