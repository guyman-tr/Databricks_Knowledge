# Customer.PlayerLevelGetRealizedEquityData

> Computes the effective maximum realized equity for each customer whose equity changed during a reference period, used by the automatic player level upgrade/downgrade engine to determine tier eligibility.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset: CID, GCID, PlayerLevelID, RealizedEquity, MaxRealizedEquity |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.PlayerLevelGetRealizedEquityData` is the data-gathering step of the automatic player-level assignment process. It identifies customers whose realized equity changed during a "first period" (recent observation window), then determines the highest realized equity they achieved across both the first period and a second period (a broader lookback). This maximum value is the equity figure used to assign the customer's tier.

The two-period design prevents immediate tier downgrades from short-term equity dips. If a customer hit a high-water mark in the broader lookback period but their equity dropped in the recent period, the higher value is still used - giving the upgrade logic a fair picture of the customer's sustained equity level.

The procedure was updated in January 2021 to use the BackOffice aggregation tables (`BackOffice.CustomerDTDAggregatedData_1`) after bugs were found with the previous data source. This is a batch/analytical procedure not called in real-time transactional flows - it serves a scheduled job that periodically re-evaluates customer tier assignments.

---

## 2. Business Logic

### 2.1 Two-Period Realized Equity Calculation

**What**: Determines each customer's effective equity by combining observations from two overlapping time windows.

**Columns/Parameters Involved**: `@BeginDateToCheckChanges`, `@EndDateToCheckChanges`, `@BeginDateToCheckMaxRealizedEquity`, `@EndDateToCheckMaxRealizedEquity`

**Rules**:
- **First period** (@BeginDateToCheckChanges to @EndDateToCheckChanges): Population selection. Only customers who have a `LastRealizedEquity` record in this window are included. The latest record per CID in this period defines the baseline.
- **Second period** (@BeginDateToCheckMaxRealizedEquity to @EndDateToCheckMaxRealizedEquity): The broader lookback. For each CID from the first period, finds their MAX LastRealizedEquity across this entire period.
- **Effective MaxRealizedEquity**: `IIF(FirstPeriod.LastRealizedEquity > SecondPeriod.MaxRealizedEquity OR SecondPeriod is NULL, FirstPeriod.LastRealizedEquity, SecondPeriod.MaxRealizedEquity)` - takes the higher of the two.
- Customers with no second-period data still appear: their first-period value is used.

```
First Period (recent):    Identify population - customers with equity changes
Second Period (lookback): Find peak equity for those customers
Result: MAX(FirstPeriod.LastRealizedEquity, SecondPeriod.MaxRealizedEquity)
```

### 2.2 Performance: Clustered Temp Table Indexes

**What**: Both intermediate temp tables get clustered indexes on CID for join performance.

**Rules**:
- `#CIDsWhichWereChangedInFirstPeriod`: clustered index on CID (built before second query).
- `#MaxRealizedEquityForCIDs`: clustered index on CID (built before final SELECT).
- This is critical for the large cross-join against BackOffice.CustomerDTDAggregatedData_1.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BeginDateToCheckChanges | DATETIME | NO | - | CODE-BACKED | Start of the first (recent) observation window. Customers with equity changes in [@BeginDateToCheckChanges, @EndDateToCheckChanges) are selected as the population for level recalculation. |
| 2 | @EndDateToCheckChanges | DATETIME | NO | - | CODE-BACKED | End of the first (recent) observation window (exclusive). |
| 3 | @BeginDateToCheckMaxRealizedEquity | DATETIME | NO | - | CODE-BACKED | Start of the second (broader lookback) window used to find each customer's peak realized equity. |
| 4 | @EndDateToCheckMaxRealizedEquity | DATETIME | NO | - | CODE-BACKED | End of the second (broader lookback) window (exclusive). |

**Returned Columns:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Customer.Customer | Customer ID |
| 2 | GCID | Customer.Customer | Global customer ID |
| 3 | PlayerLevelID | Customer.Customer | Current player level of the customer (before any recalculation) |
| 4 | RealizedEquity | Customer.Customer | Current realized equity stored on the customer record |
| 5 | MaxRealizedEquity | Computed | Effective maximum realized equity: MAX(FirstPeriod.LastRealizedEquity, SecondPeriod.MaxRealizedEquity). Used by the caller to determine tier eligibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | BackOffice.CustomerDTDAggregatedData_1 | READ | Daily aggregated customer data including LastRealizedEquity |
| (JOIN) | Customer.Customer | READ | Provides CID, GCID, PlayerLevelID, RealizedEquity for the output |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.PlayerLevelGetRealizedEquityData (procedure)
├── BackOffice.CustomerDTDAggregatedData_1 (table) [READ - daily aggregated equity data]
└── Customer.Customer (view) [JOIN - get CID details for output]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDTDAggregatedData_1 | Table | READ - source of LastRealizedEquity by CID and Date |
| Customer.Customer | View | JOIN - provides GCID, PlayerLevelID, current RealizedEquity |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (player level scheduling job) | External process | Calls this to get equity data for tier assignment |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table indexes | Performance | Clustered indexes on CID in both temp tables to support the large CID IN subquery and final join |

---

## 8. Sample Queries

### 8.1 Simulate the procedure logic for a specific date range

```sql
-- First period: find customers with equity changes
SELECT CID, LastRealizedEquity
FROM BackOffice.CustomerDTDAggregatedData_1 WITH (NOLOCK)
WHERE [Date] >= '2026-01-01'
  AND [Date] < '2026-01-08'
  AND LastRealizedEquity IS NOT NULL
ORDER BY CID, [Date] DESC
```

### 8.2 Check current player level distribution with realized equity

```sql
SELECT
    c.PlayerLevelID,
    pl.Name AS TierName,
    COUNT(*) AS CustomerCount,
    AVG(c.RealizedEquity) AS AvgRealizedEquity,
    MIN(c.RealizedEquity) AS MinRealizedEquity,
    MAX(c.RealizedEquity) AS MaxRealizedEquity
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON pl.PlayerLevelID = c.PlayerLevelID
WHERE c.PlayerLevelID <> 4 -- exclude Internal
GROUP BY c.PlayerLevelID, pl.Name
ORDER BY pl.Sort
```

### 8.3 Find customers whose current realized equity mismatches their tier

```sql
SELECT
    c.CID,
    c.PlayerLevelID,
    pl.Name AS CurrentTierName,
    c.RealizedEquity,
    correct_pl.PlayerLevelID AS CorrectTierID,
    correct_pl.Name AS CorrectTierName
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON pl.PlayerLevelID = c.PlayerLevelID
JOIN Dictionary.PlayerLevel correct_pl WITH (NOLOCK)
    ON c.RealizedEquity >= correct_pl.RealizedEquityFrom
    AND c.RealizedEquity < correct_pl.RealizedEquityTo
    AND correct_pl.RealizedEquityFrom IS NOT NULL
WHERE c.PlayerLevelID <> correct_pl.PlayerLevelID
  AND c.PlayerLevelID <> 4
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.PlayerLevelGetRealizedEquityData | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.PlayerLevelGetRealizedEquityData.sql*
