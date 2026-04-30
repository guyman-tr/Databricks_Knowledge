# BackOffice.JUNK_GetLastPositionDate

> DEPRECATED scalar function returning the date of a customer's most recent position open across both live (Trade.Position) and historical (History.Position) tables, returning the later of the two MAX(InitDateTime) values.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DATETIME (latest position open date for @CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetLastPositionDate` returns the most recent position open timestamp for a given customer ID, searching both the live trade table (`Trade.Position`) and the historical archive (`History.Position`). The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure, but IS still used as a dependency by the also-deprecated `JUNK_GetCustomerSegment`.

The function answers: "When did customer @CID most recently open a trading position (considering both open and closed positions)?" It checks both tables because open positions reside in `Trade.Position` while closed/archived positions are in `History.Position`.

**Two-table design rationale**: Positions start in `Trade.Position` (open) and are moved to `History.Position` upon close. A customer's most recent activity could be in either table - an active trader with open positions will show up in `Trade.Position`, while a dormant customer's last activity will be in `History.Position`. Checking only one table would miss the other.

The function uses ISNULL with CAST(0 AS DATETIME) as a sentinel value so that NULL dates (customer has no positions in one table) compare as the epoch (1900-01-01), ensuring the non-NULL date always wins the comparison.

---

## 2. Business Logic

### 2.1 Two-Table Last Position Date Resolution

**What**: Queries both Trade.Position (open) and History.Position (closed) to find the true latest activity date.

**Columns/Parameters Involved**: `@CID`, `@TradePositionDate`, `@HistoryPositionDate`, `@LastPosDate`, `InitDateTime`

**Rules**:
- Step 1: `SELECT @TradePositionDate = ISNULL(MAX(InitDateTime), CAST(0 AS DATETIME)) FROM Trade.Position WHERE CID = @CID`
  - Gets latest open position initiation. ISNULL coalesces NULL to epoch date.
- Step 2: `SELECT @HistoryPositionDate = ISNULL(MAX(InitDateTime), CAST(0 AS DATETIME)) FROM History.Position WHERE CID = @CID`
  - Gets latest closed position initiation. ISNULL coalesces NULL to epoch date.
- Step 3: Comparison: IF @HistoryPositionDate > @TradePositionDate THEN use @HistoryPositionDate, ELSE use @TradePositionDate.
- Returns the later of the two dates.
- If the customer has no positions in either table, returns CAST(0 AS DATETIME) = 1900-01-01 00:00:00.

**Diagram**:
```
@CID
  |
  +-> Trade.Position (open positions)
  |     MAX(InitDateTime) -> @TradePositionDate (or epoch if none)
  |
  +-> History.Position (closed positions)
  |     MAX(InitDateTime) -> @HistoryPositionDate (or epoch if none)
  |
  v
IF @HistoryPositionDate > @TradePositionDate
  RETURN @HistoryPositionDate
ELSE
  RETURN @TradePositionDate

Note: Returns epoch (1900-01-01) if customer has no positions anywhere.
```

### 2.2 Usage in Customer Segmentation

**What**: This function is the key data point for `JUNK_GetCustomerSegment` which classifies customers based on recency and equity.

**Rules**:
- `JUNK_GetCustomerSegment` calls this function and computes `DATEDIFF(wk, result, GETDATE())` as @WeeksFromLastPos.
- Active: Equity >= 2500 AND WeeksFromLastPos < 2.
- Inactive: Equity >= 2500 AND WeeksFromLastPos >= 2.
- Recently Died: Equity < 2500 AND WeeksFromLastPos < 1.
- Dead: Equity < 2500 AND WeeksFromLastPos >= 1.
- The epoch return value (no positions) means DATEDIFF will return a very large number of weeks, resulting in classification as "Dead" or "Inactive".

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used to filter both Trade.Position and History.Position to this customer's records. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return) | DATETIME | NO | CAST(0 AS DATETIME) = 1900-01-01 | CODE-BACKED | The most recent InitDateTime across Trade.Position and History.Position for this customer. Returns epoch date (1900-01-01) if the customer has never opened a position in either table, enabling safe date arithmetic without NULL checks by callers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, InitDateTime | Trade.Position | Table read | Live open positions. MAX(InitDateTime) for active positions. |
| @CID, InitDateTime | History.Position | Table read | Archived closed positions. MAX(InitDateTime) for completed positions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.JUNK_GetCustomerSegment | @CID | Function call | Calls this function to get last position date, then computes weeks elapsed for segment classification. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetLastPositionDate (function)
+-- Trade.Position (table) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | Queried for MAX(InitDateTime) WHERE CID = @CID (open positions). |
| History.Position | Table | Queried for MAX(InitDateTime) WHERE CID = @CID (closed/archived positions). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.JUNK_GetCustomerSegment | Function | Calls this to get last position date for customer activity recency calculation. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function. JUNK_ prefix = deprecated. Uses WITH (NOLOCK) on both source tables. Uses epoch sentinel (CAST(0 AS DATETIME)) to avoid NULL comparison issues.

---

## 8. Sample Queries

### 8.1 Get last position date for a specific customer

```sql
SELECT BackOffice.JUNK_GetLastPositionDate(12345) AS LastPositionDate;
```

### 8.2 Weeks since last position (activity recency)

```sql
SELECT
    CID,
    BackOffice.JUNK_GetLastPositionDate(CID) AS LastPosition,
    DATEDIFF(WEEK, BackOffice.JUNK_GetLastPositionDate(CID), GETDATE()) AS WeeksSinceLastPos
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Customers who have never traded (epoch return)

```sql
SELECT CID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE BackOffice.JUNK_GetLastPositionDate(CID) = CAST(0 AS DATETIME);
-- Returns customers with no entries in Trade.Position or History.Position
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetLastPositionDate | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetLastPositionDate.sql*
