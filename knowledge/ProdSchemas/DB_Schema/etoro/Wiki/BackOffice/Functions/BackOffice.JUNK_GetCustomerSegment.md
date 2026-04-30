# BackOffice.JUNK_GetCustomerSegment

> DEPRECATED scalar function classifying a customer into one of four trading activity segments (Active/Inactive/Recently Died/Dead) based on equity level and weeks since last position.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(15) segment label for @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetCustomerSegment` classifies a customer into one of four trading activity segments using two dimensions: current equity level and recency of last trading activity. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "What is customer @CID's current trading engagement segment?" The segmentation is a 2x2 matrix:
- **Equity threshold**: $2,500 (high equity vs. low equity)
- **Recency threshold**: < 2 weeks (recent trader) vs. >= 2 weeks (lapsed)

**Four segments**:
- **Active**: High equity (>= $2,500) AND traded recently (< 2 weeks ago). Premium engaged customer.
- **Inactive**: High equity (>= $2,500) BUT has not traded in >= 2 weeks. High-value but disengaged - retention priority.
- **Recently Died**: Low equity (< $2,500) AND traded in the last week (< 1 week ago). Low-value but recently active - may still re-engage.
- **Dead**: Low equity (< $2,500) AND has not traded in >= 1 week. Effectively churned. Default fallback if no equity data is found.
- **Unknown**: Default value if no positions are found and equity lookup fails (returns 'UnKnown' initial value).

**Business use case**: This segmentation drove customer retention campaigns, manager prioritisation lists, and re-engagement targeting. An "Inactive" customer (high equity, not trading) was the most valuable re-engagement target.

---

## 2. Business Logic

### 2.1 Customer Segment Classification Matrix

**What**: 2x2 decision tree based on equity level and trading recency.

**Columns/Parameters Involved**: `@CID`, `@Equity`, `@WeeksFromLastPos`, `@Segment`

**Rules**:
- Default: `@Segment = 'UnKnown'` (returned if no equity data or positions found).
- Step 1: `@WeeksFromLastPos = DATEDIFF(wk, BackOffice.JUNK_GetLastPositionDate(@CID), GETDATE())`.
  - If customer has no positions, `JUNK_GetLastPositionDate` returns epoch (1900-01-01), making WeeksFromLastPos a very large number (>= 6,000 weeks), effectively classifying as lapsed.
- Step 2: `SELECT @Equity = MAX(Equity) FROM Customer.GetCustomerCurrentInfo WHERE CID = @CID`.
  - Gets the customer's current equity from a real-time view.
- Step 3: Segmentation logic:
  ```
  IF @Equity >= 2500
    IF @WeeksFromLastPos < 2  -> 'Active'
    ELSE                      -> 'Inactive'
  ELSE
    IF @WeeksFromLastPos < 1  -> 'Recently Died'
    ELSE                      -> 'Dead'
  ```
- Note: `MAX(Equity)` is used against `Customer.GetCustomerCurrentInfo` - this view likely returns one row per customer, so MAX is a safety aggregate for any multi-row edge case.

**Diagram**:
```
@CID
  |
  v
BackOffice.JUNK_GetLastPositionDate(@CID)
  -> @WeeksFromLastPos = DATEDIFF(wk, result, GETDATE())
  |
  v
Customer.GetCustomerCurrentInfo
  WHERE CID = @CID
  -> @Equity = MAX(Equity)
  |
  v
IF @Equity >= 2500:
  WeeksFromLastPos < 2?   YES -> 'Active'
                          NO  -> 'Inactive'
ELSE (@Equity < 2500):
  WeeksFromLastPos < 1?   YES -> 'Recently Died'
                          NO  -> 'Dead'
```

### 2.2 Equity vs. Recency Threshold Design

**What**: The asymmetric recency thresholds (< 2 weeks for high equity, < 1 week for low equity) reflect different expectations for high and low value customers.

**Rules**:
- High-equity customers (>= $2,500): Considered "Active" if they traded within 2 weeks - a 2-week trading window is normal for longer-term investors.
- Low-equity customers (< $2,500): Must have traded within 1 week to be "Recently Died" - a tighter window reflecting that low-equity customers who stop trading quickly become inactive permanently.
- The $2,500 equity threshold is hard-coded - likely a legacy business decision about what constitutes a "valuable" customer account balance.
- Note: "Recently Died" uses the same equity threshold direction as "Dead" (low equity), suggesting "died" referred to account equity declining below the $2,500 threshold.

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used to look up last position date and current equity for segmentation. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return) | VARCHAR(15) | NO | 'UnKnown' | CODE-BACKED | Customer trading activity segment. One of: 'Active' (equity >= $2,500 AND traded < 2 weeks ago), 'Inactive' (equity >= $2,500 AND traded >= 2 weeks ago), 'Recently Died' (equity < $2,500 AND traded < 1 week ago), 'Dead' (equity < $2,500 AND traded >= 1 week ago), 'UnKnown' (no equity data found). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.JUNK_GetLastPositionDate | Function call | Returns the most recent InitDateTime across Trade.Position and History.Position. Used to compute WeeksFromLastPos. |
| @CID, Equity | Customer.GetCustomerCurrentInfo | View read | Real-time customer equity lookup. MAX(Equity) for the customer determines which equity tier (>= $2,500 or < $2,500). |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetCustomerSegment (function)
+-- BackOffice.JUNK_GetLastPositionDate (function)
|     +-- Trade.Position (table) [cross-schema]
|     +-- History.Position (table) [cross-schema]
+-- Customer.GetCustomerCurrentInfo (view) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.JUNK_GetLastPositionDate | Function | Returns most recent position date for @CID. Used to compute WeeksFromLastPos via DATEDIFF. |
| Customer.GetCustomerCurrentInfo | View | Real-time customer equity. MAX(Equity) compared to $2,500 threshold. |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function. JUNK_ prefix = deprecated. Hard-coded thresholds: $2,500 equity, 2-week and 1-week recency. 'UnKnown' typo (should be 'Unknown') is preserved in the return value - callers must handle this spelling.

---

## 8. Sample Queries

### 8.1 Get segment for a specific customer

```sql
SELECT BackOffice.JUNK_GetCustomerSegment(12345) AS Segment;
```

### 8.2 Segment distribution across all manager customers

```sql
SELECT
    BackOffice.JUNK_GetCustomerSegment(CID) AS Segment,
    COUNT(*) AS CustomerCount
FROM BackOffice.Customer WITH (NOLOCK)
WHERE ManagerID = 42
GROUP BY BackOffice.JUNK_GetCustomerSegment(CID)
ORDER BY CustomerCount DESC;
```

### 8.3 Find "Inactive" customers (high value, not trading - retention priority)

```sql
SELECT CID, ManagerID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE BackOffice.JUNK_GetCustomerSegment(CID) = 'Inactive'
  AND ManagerID = 42;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetCustomerSegment | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetCustomerSegment.sql*
