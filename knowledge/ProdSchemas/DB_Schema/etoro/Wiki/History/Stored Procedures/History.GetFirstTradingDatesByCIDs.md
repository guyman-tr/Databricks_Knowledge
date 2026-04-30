# History.GetFirstTradingDatesByCIDs

> Returns the first trading date for each customer in a batch by finding the earliest Open Position or Start Copy (Register Mirror) credit, used by the PeriodicRanking system for leaderboard calculations.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CustomerIds TVP (batch of CIDs); result: CID + MIN(Occurred) as FirstTradingDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the **first trading activity date** for each customer in a given batch. A customer's "first trading date" is defined as the earliest time they either opened a manual position (CreditTypeID=3) or registered a new copy relationship (CreditTypeID=20, "Start Copy"). It is called by the `PeriodicRanking` system to calculate leaderboard metrics that depend on how long a customer has been actively trading.

The dual-CreditType filter captures both manual traders (first position open) and copy-traders (first time they started copying someone), so that "first trading date" is meaningful for all customer profiles.

---

## 2. Business Logic

### 2.1 First Trading Date Definition

**What**: `MIN(Occurred)` from `History.Credit` filtered to trading-initiation credit types.

**CreditTypeID filter**:
- `3` = Open Position (manual trade opened - first real position ever opened by this customer)
- `20` = Register new mirror / "Start Copy" (first time customer started copying a leader)

**Rules**: GROUP BY CID, MIN(Occurred) per CID. No date range filter - searches the entire History.Credit history.

**Note**: Customers who never traded (no CreditTypeID 3 or 20 records) will not appear in the result set.

### 2.2 Batch Processing via TVP

**What**: Accepts multiple customer IDs in a single call via `dbo.IdIntList` TVP.

**Rules**:
- `@CustomerIds dbo.IdIntList READONLY` - TVP with single `ID INT` column (NULL allowed)
- `WHERE CID IN (SELECT ID FROM @CustomerIds)` - batch lookup
- No temp table materialization (simple IN subquery sufficient for small-medium batches)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerIds | dbo.IdIntList READONLY | NO | - | CODE-BACKED | Table-Valued Parameter containing ID (INT) values for batch customer lookup. Type defined in dbo schema as single-column INT table. |

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| CID | History.Credit.CID | Customer ID |
| FirstTradingDate | MIN(History.Credit.Occurred) | Earliest timestamp of an Open Position (type 3) or Start Copy (type 20) credit for this customer |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Credit | Read | Full history scan for CreditTypeID IN (3,20) filtered to input CIDs. |
| TVP type | dbo.IdIntList | Type dependency | @CustomerIds uses this dbo-schema user-defined table type. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PeriodicRanking | EXEC | Direct call | Leaderboard / periodic ranking calculations that require customers' first trading dates. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetFirstTradingDatesByCIDs (procedure)
├── History.Credit (view) [main data source]
└── dbo.IdIntList (user defined type) [TVP parameter type]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | View | Full-history scan for earliest Open Position or Start Copy credit per CID. |
| dbo.IdIntList | User Defined Type | TVP parameter type for @CustomerIds batch input. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PeriodicRanking (application) | External | First-trading-date lookup for leaderboard ranking calculations. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CreditTypeID IN (3,20) only | Scope | Only position opens and copy-start events define "first trading date". Other trading-related credits (e.g., Mirror Hierarchical Open=23) are excluded. |
| No date filter | Full history | Searches all of History.Credit for the MIN - queries can be slow for large batches against a large Credit view. |
| NULL ID in TVP | Edge case | dbo.IdIntList allows NULL IDs; NULL would match no CIDs but does not cause errors. |

---

## 8. Sample Queries

### 8.1 Get first trading dates for a batch of customers

```sql
DECLARE @ids dbo.IdIntList;
INSERT INTO @ids VALUES (12345), (67890), (11111);

EXEC History.GetFirstTradingDatesByCIDs @CustomerIds = @ids;
```

### 8.2 Verify first trading date directly

```sql
SELECT CID, MIN(Occurred) AS FirstTradingDate
FROM History.Credit WITH (NOLOCK)
WHERE CID = 12345
  AND CreditTypeID IN (3, 20)
GROUP BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetFirstTradingDatesByCIDs | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetFirstTradingDatesByCIDs.sql*
