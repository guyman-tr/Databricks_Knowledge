# Billing.BadBinRemove

> Removes a BIN range from the blocked-card table Billing.BadBin using a 4-step interval-deletion algorithm: deletes fully-contained sub-ranges, trims partially-overlapping ranges, and splits any single existing range that fully contains the removal window into two residual ranges.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success) or 60000 (error); modifies Billing.BadBin |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BadBinRemove` is the removal counterpart to `Billing.BadBinAdd`. When a previously-blocked BIN range should be unblocked (e.g., a false positive was corrected, an issuer improved their fraud controls, or a range was incorrectly added), this procedure removes it from `Billing.BadBin`.

The removal is more complex than the addition because of how merged ranges work. If [411000-412000] was added and then [411100-411200] was added (merged into the first range), removing [411100-411200] must leave [411000-411099] and [411201-412000] as two separate ranges. The procedure handles this case using a cursor to find ranges that fully contain the removal window and splitting them.

Like `Billing.BadBinAdd`, it validates that all BINs are 6 digits and the range is valid. Invalid input is silently ignored.

---

## 2. Business Logic

### 2.1 Input Validation

**What**: Same 6-digit validation as BadBinAdd.

**Rules**:
- `IF @BinFrom BETWEEN 100000 AND 999999 AND @BinTo BETWEEN 100000 AND 999999 AND @BinFrom <= @BinTo`: must be true for any operations to execute.
- Invalid input: silent no-op, returns 0.

### 2.2 Step 1: Delete Fully-Contained Ranges

**What**: Removes any existing range that is entirely within the removal window.

**Parameters/Columns Involved**: `@BinFrom`, `@BinTo`

**Rules**:
- `DELETE FROM Billing.BadBin WHERE @BinFrom <= BinFrom AND @BinTo >= BinTo`
- Removes rows where the existing range [BinFrom, BinTo] is fully enclosed by [@BinFrom, @BinTo].
- Example: existing [411100-411150] is fully inside removal [411000-412000] -> deleted.

### 2.3 Step 2: Trim Left-Overlapping Ranges

**What**: For ranges that start inside the removal window but extend beyond it on the right, moves their start to just after the removal window's end.

**Parameters/Columns Involved**: `@BinFrom`, `@BinTo`

**Rules**:
- `UPDATE Billing.BadBin SET BinFrom = @BinTo + 1 WHERE @BinFrom <= BinFrom AND @BinTo BETWEEN BinFrom AND BinTo`
- Condition: the removal window's end (@BinTo) falls inside the existing range (between BinFrom and BinTo), AND the removal window starts at or before the existing range (so the existing range's left end is inside or at the removal window start).
- Effect: the left portion of the existing range that overlaps the removal window is trimmed away.
- Example: existing [411500-412000], removal [411000-411600] -> BinFrom moved to 411601. Result: [411601-412000].

### 2.4 Step 3: Trim Right-Overlapping Ranges

**What**: For ranges that end inside the removal window but start before it, moves their end to just before the removal window's start.

**Parameters/Columns Involved**: `@BinFrom`, `@BinTo`

**Rules**:
- `UPDATE Billing.BadBin SET BinTo = @BinFrom - 1 WHERE @BinTo >= BinTo AND @BinFrom BETWEEN BinFrom AND BinTo`
- Condition: the removal window's start (@BinFrom) falls inside the existing range, AND the removal window ends at or after the existing range's end.
- Effect: the right portion of the existing range that overlaps the removal window is trimmed away.
- Example: existing [410000-411500], removal [411200-412000] -> BinTo moved to 411199. Result: [410000-411199].

### 2.5 Step 4: Split Ranges that Fully Contain the Removal Window

**What**: Handles the case where a single existing range completely encloses the removal window. Such a range must be split into two residual ranges.

**Parameters/Columns Involved**: `@BinFrom`, `@BinTo`, cursor `BinList`

**Rules**:
- Cursor selects: `SELECT BinFrom, BinTo FROM Billing.BadBin WHERE @BinFrom > BinFrom AND @BinTo < BinTo` - finds existing ranges that strictly contain the removal window.
- For each such range [@FetchFrom, @FetchTo]:
  - INSERT left residual: (@FetchFrom, @BinFrom - 1) - the part before the removal window.
  - INSERT right residual: (@BinTo + 1, @FetchTo) - the part after the removal window.
- After cursor completes: `DELETE FROM Billing.BadBin WHERE @BinFrom > BinFrom AND @BinTo < BinTo` - removes the original rows that were just split.
- Example: existing [410000-412000], removal [411000-411500] -> after split: [410000-410999] and [411501-412000]. Original [410000-412000] is deleted.
- Cursor type: LOCAL READ_ONLY FORWARD_ONLY STATIC - safe for this use case.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinFrom | INTEGER | NO | - | VERIFIED | Lower bound (inclusive) of the BIN range to unblock. Must be a 6-digit integer (100000-999999). |
| 2 | @BinTo | INTEGER | NO | - | VERIFIED | Upper bound (inclusive) of the BIN range to unblock. Must be a 6-digit integer (100000-999999) and >= @BinFrom. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinFrom, @BinTo | Billing.BadBin | WRITER (DELETE + UPDATE + INSERT) | Deletes fully-contained ranges, trims partial overlaps, splits containing ranges into two residual rows. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from fraud prevention administration tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BadBinRemove (procedure)
+- Billing.BadBin (table)   [DELETE (fully contained), UPDATE (partial overlaps), INSERT (split residuals)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BadBin | Table | All 4 interval-deletion operations: DELETE, UPDATE x2, and INSERT x2 (for split). |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from fraud/risk administration. See also: Billing.BadBinAdd (the addition counterpart).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Cursor used for split case**: The split case (step 4) requires per-row handling since a single covering range must become two new rows. A cursor is the correct approach here. It is declared LOCAL FORWARD_ONLY STATIC READ_ONLY to minimize overhead.
- **Step ordering matters**: Steps 1-3 must run before step 4. Step 1 removes ranges fully inside the window (otherwise step 4 might find ranges that step 1 should have removed). Steps 2 and 3 handle partial overlaps before the cursor runs.
- **Silent on invalid input**: Like BadBinAdd, invalid input (@BinFrom or @BinTo outside 100000-999999) silently returns 0 with no action.
- **Legacy error handling**: Uses `SELECT @LocalError = @@ERROR` (old-style). Cursor cleanup (CLOSE + DEALLOCATE) is included in each error exit path within the cursor loop.

---

## 8. Sample Queries

### 8.1 Unblock a specific BIN range
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BadBinRemove
    @BinFrom = 411111,
    @BinTo   = 411199;
SELECT @Result AS ReturnCode;  -- 0 = success
```

### 8.2 Verify the range was removed
```sql
SELECT  BinFrom, BinTo
FROM    Billing.BadBin WITH (NOLOCK)
WHERE   BinFrom <= 411199
  AND   BinTo   >= 411111;
-- Should return 0 rows if fully removed, or residual ranges if partially removed
```

### 8.3 View all blocked BIN ranges (post-removal check)
```sql
SELECT  BinFrom,
        BinTo,
        BinTo - BinFrom + 1 AS BINsBlocked
FROM    Billing.BadBin WITH (NOLOCK)
ORDER BY BinFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BadBinRemove | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BadBinRemove.sql*
