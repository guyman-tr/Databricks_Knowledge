# History.GetCreditIDByOccurred

> Scalar function that returns the first CreditID in History.Credit at or after a given datetime - used to determine the lower-bound CreditID for a time window boundary, supporting incremental loads into History.ActiveCredit.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetCreditIDByOccurred(@Occurred datetime) RETURNS int` |
| **Author** | Geri Reshef, 28/11/2016 |
| **Purpose** | Time-to-CreditID boundary lookup |

---

## 1. Business Meaning

`History.GetCreditIDByOccurred` answers the question: *"What is the first CreditID in the credit ledger at or after this datetime?"* It queries `History.Credit WITH(NOLOCK)` for `TOP 1 CreditID WHERE Occurred >= @Occurred ORDER BY Occurred ASC`, returning the lowest CreditID whose event timestamp falls on or after the input date.

The function's comment says "Max CreditID Real DB Changes (History.ActiveCredit)" - this describes its primary use case: establishing the CreditID boundary that separates the "active" (recent, in-memory) window from the archived window. When refreshing `History.ActiveCredit` (a memory-optimized table holding recent credit events), the caller needs to know the starting CreditID for the target time window. This function converts a datetime threshold into that boundary CreditID.

**Note on return type mismatch**: The function is declared `RETURNS int` but internally uses a `BigInt` variable. Since `CreditID` in `History.Credit` is `bigint`, this creates a potential silent truncation for CreditIDs exceeding 2,147,483,647. All modern CreditIDs are in the bigint range, making this a latent bug - callers expecting an `int` return may receive incorrect values for high-volume periods.

---

## 2. Business Logic

### 2.1 Time-to-CreditID Boundary Resolution

**What**: Converts a datetime parameter into the smallest CreditID whose Occurred timestamp is >= that datetime.

**Columns/Parameters Involved**: `@Occurred` (input), `CreditID` (output), `Occurred` (filter/sort column in History.Credit)

**Rules**:
- `SELECT TOP 1 CreditID FROM History.Credit WITH(NOLOCK) WHERE Occurred >= @Occurred ORDER BY Occurred ASC`
- Returns NULL if no credit event exists at or after `@Occurred` (i.e., the date is beyond the last credit record)
- Uses NOLOCK hint - result is non-transactional; acceptable for boundary estimation where precision to the exact row is not critical
- Since CreditID is not guaranteed to be monotonically increasing with Occurred (credits from multiple archive branches are UNION ALL'd), ordering by Occurred ASC and taking TOP 1 finds the earliest event at or after the threshold, not necessarily the smallest CreditID

### 2.2 ActiveCredit Partition Support

**What**: The function was built specifically to support incremental loading of History.ActiveCredit (memory-optimized table for recent credits).

**Rules**:
- `History.ActiveCredit` and related tables (History.ActiveCredit_BIGINT, History.ActiveCreditRecentMemoryBucket) are populated from History.Credit by date-range slices
- This function provides the starting CreditID for such a slice given a date boundary
- Callers pass a date (e.g., 90 days ago) and use the returned CreditID as a WHERE CreditID >= boundary filter

---

## 3. Data Overview

Direct execution blocked (EXECUTE permission not granted to McpUserRO; History.Credit routes to EtoroArchive). Based on History.Credit documentation:

| @Occurred Input | Expected Output | Meaning |
|----------------|-----------------|---------|
| '2024-01-01' | ~high bigint value | First credit event of 2024 |
| '2020-01-01' | ~mid bigint value | First credit event of 2020 |
| '2007-01-01' | ~small value (1 or low) | Oldest credit event |
| Future date beyond last record | NULL | No credits at or after that date |

---

## 4. Elements

### Parameters

| # | Parameter | Type | Direction | Description |
|---|-----------|------|-----------|-------------|
| 1 | @Occurred | datetime | IN | The datetime threshold. Returns the first CreditID at or after this timestamp. |

### Return Value

| Type (declared) | Actual variable type | Description |
|-----------------|----------------------|-------------|
| int | BIGINT (internal) | The first CreditID in History.Credit with Occurred >= @Occurred, ordered by Occurred ASC. Returns NULL if no credit exists at or after the threshold. NOTE: declared as int but CreditID is bigint - potential truncation for large CreditIDs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| History.Credit | History.Credit | Query source | TOP 1 CreditID WHERE Occurred >= @Occurred - the function reads the credit ledger to resolve the boundary |

### 5.2 Referenced By (other objects point to this)

No stored procedures in the etoro SSDT repo directly reference History.GetCreditIDByOccurred. Based on the comment ("Max CreditID Real DB Changes (History.ActiveCredit)"), callers are likely:
- Application or maintenance scripts that refresh History.ActiveCredit
- External SQL scripts or jobs that manage the ActiveCredit partition boundaries

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetCreditIDByOccurred (scalar function)
+-- History.Credit (view - 78-source UNION ALL over EtoroArchive credit branches)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | View | Source of CreditID/Occurred data - TOP 1 WHERE Occurred >= @Occurred ORDER BY Occurred ASC |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repo.

---

## 7. Technical Details

### 7.1 Performance Notes

- History.Credit is a 78-branch UNION ALL view routed to EtoroArchive. A query with `WHERE Occurred >= @Occurred ORDER BY Occurred ASC TOP 1` requires scanning/filtering across all branches.
- NOLOCK is applied - non-blocking but may read uncommitted data.
- No index on Occurred in the underlying archive tables is guaranteed - performance depends on EtoroArchive table structure.

### 7.2 Known Issues

- **Return type mismatch**: Declared `RETURNS int` but internal variable is `BIGINT`. For CreditIDs > 2,147,483,647 the implicit cast silently truncates. This is a latent bug.
- **Non-monotonic CreditID ordering**: CreditID sequence is not strictly monotonic with Occurred across all archive branches, so TOP 1 BY Occurred is not equivalent to MIN(CreditID) in the time window.

---

## 8. Sample Queries

### 8.1 Find the boundary CreditID for a 90-day active window

```sql
-- Get the first CreditID from 90 days ago onwards (for ActiveCredit refresh)
DECLARE @Boundary datetime = DATEADD(DAY, -90, GETDATE())
DECLARE @StartCreditID int
SET @StartCreditID = History.GetCreditIDByOccurred(@Boundary)
SELECT @StartCreditID AS BoundaryCreditID
```

### 8.2 Use boundary to query recent credits

```sql
-- Get all credit events from the boundary forward
DECLARE @StartCreditID int = History.GetCreditIDByOccurred(DATEADD(DAY, -90, GETDATE()))
SELECT CreditID, CID, Amount, CreditTypeID, Occurred
FROM History.Credit WITH(NOLOCK)
WHERE CreditID >= @StartCreditID
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - live data blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetCreditIDByOccurred | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetCreditIDByOccurred.sql*
