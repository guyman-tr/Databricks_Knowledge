# BackOffice.MirrorComulative

> Cumulative copy-trading statistics per customer, capturing total and current copy activity, invested amounts, and the identity of the original copied trader.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_MirrorComulative_CID: CID (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK on CID) |

---

## 1. Business Meaning

`BackOffice.MirrorComulative` stores aggregated lifetime copy-trading activity statistics for each customer who has used the CopyTrader feature. "Mirror" is eToro's internal term for the copy-trading relationship - when customer A copies customer B's trades, A's account mirrors B's positions. This table holds a single summary row per customer that accumulates over time: how many traders they have copied, how many they are currently copying, total invested amount, and who the original copied trader was.

This table exists to provide a denormalised performance-optimised view of a customer's copy-trading history without requiring complex aggregation across the Trade or History schemas. Back-office reports and tools can quickly determine the scale of a customer's copy-trading activity from a single row lookup.

Data is populated by a background job (note the `RunTime` and `UpdateTime` columns with `GETDATE()` defaults, indicating periodic snapshot runs). When a copy-trading event occurs, the job recalculates and updates the row for the affected customer. `OriginalCID` and `OriginalProviderID` record the first (or most significant) copied trader identity.

---

## 2. Business Logic

### 2.1 Cumulative vs Current Copy State

**What**: The table tracks two levels of copy activity - the current live state and the lifetime totals.

**Columns/Parameters Involved**: `NumOfCurrentCopies`, `NumOfTotalCopies`, `CurrentInvestedAmount`, `TotalInvestedAmount`, `DateOfFirstCopy`, `DateOfLastCopy`

**Rules**:
- `NumOfCurrentCopies` = number of traders currently being actively copied by this customer.
- `NumOfTotalCopies` = lifetime count of copy relationships (including closed ones).
- `CurrentInvestedAmount` = sum of money currently allocated to active copy relationships.
- `TotalInvestedAmount` = peak or lifetime sum of money ever invested through copying.
- `DateOfFirstCopy` tracks when the customer first started using CopyTrader.
- `DateOfLastCopy` tracks the most recent copy activity.

**Diagram**:
```
Customer lifecycle with CopyTrader:
  First copy -> DateOfFirstCopy set, NumOfTotalCopies=1, NumOfCurrentCopies=1
  Copies 4 more -> NumOfTotalCopies=5, NumOfCurrentCopies=5
  Stops copying 2 -> NumOfCurrentCopies=3 (still 5 total)
  New copy -> DateOfLastCopy updated, NumOfTotalCopies=6, NumOfCurrentCopies=4
```

### 2.2 Original Copied Trader Tracking

**What**: Records the identity of the first or primary trader this customer has copied.

**Columns/Parameters Involved**: `OriginalCID`, `OriginalProviderID`

**Rules**:
- `OriginalCID` is the customer ID of the original copied (Popular Investor/guru).
- `OriginalProviderID` identifies the trading provider/server context for that copied trader.
- Both can be NULL if the origin data is unavailable.

---

## 3. Data Overview

Table is currently empty in the connected environment. Based on schema design (likely populated in production):

| CID | DateOfFirstCopy | DateOfLastCopy | NumOfCurrentCopies | NumOfTotalCopies | NumOfUniqueCopiedTraders | CurrentInvestedAmount | Meaning |
|-----|----------------|----------------|-------------------|-----------------|------------------------|----------------------|---------|
| (example) | 2022-01-15 | 2025-11-10 | 3 | 12 | 8 | 5000.00 | Active copier: currently copying 3 traders with $5k invested, has used 8 distinct traders over lifetime |
| (example) | 2021-06-01 | 2023-03-22 | 0 | 5 | 5 | 0.00 | Dormant copier: stopped all copying, had 5 unique traders historically |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. Primary key. Identifies the customer who is copying other traders. One row per customer. References Customer.Customer.CID. |
| 2 | DateOfFirstCopy | datetime | YES | - | NAME-INFERRED | Timestamp of the first copy-trading relationship this customer ever opened. NULL if the customer has not yet copied anyone. |
| 3 | DateOfLastCopy | datetime | YES | - | NAME-INFERRED | Timestamp of the most recent copy-trading activity (open or close of a copy). NULL if no copy activity. |
| 4 | NumOfCurrentCopies | int | YES | - | NAME-INFERRED | Number of traders currently being actively copied by this customer. Zero when all copy relationships are closed. |
| 5 | NumOfTotalCopies | int | YES | - | NAME-INFERRED | Lifetime count of copy relationships this customer has ever opened, including closed ones. |
| 6 | NumOfUniqueCopiedTraders | int | YES | - | NAME-INFERRED | Count of distinct traders (Popular Investors / gurus) this customer has copied at any point. Lower than NumOfTotalCopies if the same trader was copied multiple times. |
| 7 | CurrentInvestedAmount | money | YES | - | NAME-INFERRED | Total monetary amount currently allocated across all active copy relationships. Zero when NumOfCurrentCopies is zero. In account currency. |
| 8 | TotalInvestedAmount | money | YES | - | NAME-INFERRED | Total monetary amount ever invested through copy-trading over the customer's lifetime. Includes closed allocations. In account currency. |
| 9 | OriginalCID | int | YES | - | NAME-INFERRED | Customer ID of the original / first copied trader (the Popular Investor this customer first chose to mirror). Points to another customer's CID. |
| 10 | OriginalProviderID | int | YES | - | NAME-INFERRED | Trading provider/server ID associated with the original copied trader. Identifies the trading infrastructure context. |
| 11 | RunTime | datetime | YES | GETDATE() | CODE-BACKED | Timestamp when the background aggregation job ran and created or last fully recalculated this row. |
| 12 | UpdateTime | datetime | YES | GETDATE() | CODE-BACKED | Timestamp when this row was last modified (incremental update by the aggregation job). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer.CID | Implicit | Identifies the copying customer |
| OriginalCID | Customer.Customer.CID | Implicit | References the first copied Popular Investor |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in BackOffice schema procedures or views.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorComulative_CID | CLUSTERED PK | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_MirrorComulative_RunTime | DEFAULT | RunTime defaults to GETDATE() |
| DF_MirrorComulative_UpdateTime | DEFAULT | UpdateTime defaults to GETDATE() |

---

## 8. Sample Queries

### 8.1 Find active copy traders with significant investment

```sql
SELECT CID, NumOfCurrentCopies, NumOfUniqueCopiedTraders, CurrentInvestedAmount, TotalInvestedAmount
FROM BackOffice.MirrorComulative WITH (NOLOCK)
WHERE NumOfCurrentCopies > 0
ORDER BY CurrentInvestedAmount DESC;
```

### 8.2 Find customers who copied many traders over their lifetime

```sql
SELECT CID, NumOfTotalCopies, NumOfUniqueCopiedTraders, DateOfFirstCopy, DateOfLastCopy
FROM BackOffice.MirrorComulative WITH (NOLOCK)
WHERE NumOfTotalCopies > 10
ORDER BY NumOfTotalCopies DESC;
```

### 8.3 Summary of the popular investor originally copied by a customer

```sql
SELECT mc.CID, mc.OriginalCID, mc.OriginalProviderID,
       mc.DateOfFirstCopy, mc.NumOfTotalCopies
FROM BackOffice.MirrorComulative mc WITH (NOLOCK)
WHERE mc.CID = 99999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 7.5/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 10 NAME-INFERRED | Phases: 4/11 (DDL, Live Data, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.MirrorComulative | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.MirrorComulative.sql*
