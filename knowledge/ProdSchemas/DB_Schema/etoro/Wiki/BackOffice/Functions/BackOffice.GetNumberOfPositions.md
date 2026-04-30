# BackOffice.GetNumberOfPositions

> Scalar function returning the total count of trading positions (all statuses) currently on record for a customer in the Trade schema.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INTEGER - total position count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetNumberOfPositions` returns the total number of trading positions associated with a customer (CID) in `Trade.Position`. The count includes ALL positions regardless of status - open, closed, cancelled, or any other state - providing a lifetime position count for the customer.

This function is used in BackOffice customer risk and profile reports to provide a quick indicator of a customer's trading activity level. A customer with many positions has a different risk profile than a new customer with zero positions. The count helps BackOffice agents assess customer engagement and trading history at a glance.

Note that `Trade.Position` is the view layer over `Trade.PositionTbl`. Unlike `BackOffice.GetUsedMargin` (which filters to StatusID=1 open positions only) and `BackOffice.GetUnrealizedPnL` (which reads open positions from a PnL view), this function intentionally counts all-time positions with no status filter.

---

## 2. Business Logic

### 2.1 All-Status Position Count

**What**: COUNT(*) with no status filter, capturing the customer's entire position history.

**Columns/Parameters Involved**: `@CID`, `@NumberOfPositions`

**Rules**:
- `SELECT @NumberOfPositions = COUNT(*) FROM Trade.Position WITH (NOLOCK) WHERE CID = @CID`
- No StatusID filter - counts ALL positions (open, closed, expired, etc.)
- Returns 0 (via SET @NumberOfPositions = 0 initialization) if the customer has no positions in Trade.Position.
- Reads via WITH (NOLOCK) for non-blocking access; position count is advisory, not transactional.

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the customer whose total position count to retrieve. Filters Trade.Position by CID. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfPositions | INTEGER | NO | 0 | CODE-BACKED | Total count of all positions (any status) in Trade.Position for the customer. Returns 0 if the customer has never opened a position. Does not distinguish between open and closed positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.Position | Table read | COUNT(*) query filtered by CID. Trade.Position is the view over Trade.PositionTbl exposing all positions. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used in BackOffice customer profile and risk reports.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetNumberOfPositions (function)
└── Trade.Position (view) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | COUNT(*) WHERE CID = @CID. No status filter - counts all positions. |

### 6.2 Objects That Depend On This

No dependents found in BackOffice stored procedures during search.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get total position count for a customer

```sql
SELECT BackOffice.GetNumberOfPositions(12345) AS TotalPositions;
```

### 8.2 Classify customers by trading activity level

```sql
SELECT
    CID,
    BackOffice.GetNumberOfPositions(CID) AS TotalPositions,
    CASE
        WHEN BackOffice.GetNumberOfPositions(CID) = 0 THEN 'Never Traded'
        WHEN BackOffice.GetNumberOfPositions(CID) < 10 THEN 'New Trader'
        WHEN BackOffice.GetNumberOfPositions(CID) < 100 THEN 'Active Trader'
        ELSE 'Power Trader'
    END AS TradingCategory
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID IN (12345, 67890);
```

### 8.3 Get position count directly from Trade.Position (avoids per-row scalar overhead)

```sql
SELECT CID, COUNT(*) AS TotalPositions
FROM Trade.Position WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetNumberOfPositions | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetNumberOfPositions.sql*
