# Billing.BadBinAdd

> Inserts a new blocked BIN range into Billing.BadBin using an interval-merge algorithm: adjacent or overlapping existing ranges are extended to absorb the new range, and a new row is inserted only if the range is not already fully covered by an existing entry.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success) or 60000 (error); modifies Billing.BadBin |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BadBinAdd` maintains the blocked Bank Identification Number (BIN) range table used for payment fraud prevention. A BIN is the first 6 digits of a card number (e.g., 411111 to 411199 for a specific card issuer's product). When a BIN range is associated with fraud - chargebacks, stolen card usage, or high-risk issuers - it is added to `Billing.BadBin` and subsequent deposit attempts using cards from those BINs are blocked.

The procedure implements an interval-merge algorithm to keep the BadBin table efficient. Rather than accumulating many small overlapping or adjacent ranges, it merges new ranges with existing ones. For example, if the table contains [410000-420000] and the caller adds [415000-425000], the result is a single extended range [410000-425000] rather than two overlapping rows.

The procedure validates that all BINs are exactly 6 digits (100000-999999) and that the range is valid (@BinFrom <= @BinTo).

The counterpart deletion procedure is `Billing.BadBinRemove`.

---

## 2. Business Logic

### 2.1 Input Validation

**What**: Validates BIN ranges before any database operations.

**Parameters/Columns Involved**: `@BinFrom`, `@BinTo`

**Rules**:
- `IF @BinFrom BETWEEN 100000 AND 999999 AND @BinTo BETWEEN 100000 AND 999999 AND @BinFrom <= @BinTo`: all three conditions must be true.
- If validation fails: no error is raised - the entire IF block (including INSERT) is skipped silently. COMMIT is still executed. RETURN 0.
- Callers must check that a valid range was actually inserted (e.g., query BadBin after the call) since invalid input returns 0 with no action.

### 2.2 Interval Merge - Step 1: Extend Right Boundaries of Overlapping Ranges

**What**: For any existing range that overlaps or is adjacent to the NEW range on the right side, extends its BinTo to cover the new range's upper bound.

**Parameters/Columns Involved**: `@BinFrom`, `@BinTo`, `Billing.BadBin.BinTo`

**Rules**:
- `UPDATE Billing.BadBin SET BinTo = @BinTo WHERE @BinFrom <= BinTo + 1 AND @BinTo > BinTo`
- Condition `@BinFrom <= BinTo + 1`: the new range starts at or before this range's end + 1 (overlaps or adjacent).
- Condition `@BinTo > BinTo`: the new range extends further right than the existing range.
- Effect: existing ranges that "touch or overlap" on the right are extended to the new @BinTo.

### 2.3 Interval Merge - Step 2: Extend Left Boundaries of Overlapping Ranges

**What**: For any existing range that overlaps or is adjacent to the NEW range on the left side, extends its BinFrom to cover the new range's lower bound.

**Parameters/Columns Involved**: `@BinFrom`, `@BinTo`, `Billing.BadBin.BinFrom`

**Rules**:
- `UPDATE Billing.BadBin SET BinFrom = @BinFrom WHERE @BinTo >= BinFrom - 1 AND @BinFrom < BinFrom`
- Condition `@BinTo >= BinFrom - 1`: the new range ends at or after this range's start - 1 (overlaps or adjacent).
- Condition `@BinFrom < BinFrom`: the new range starts further left than the existing range.
- Effect: existing ranges that "touch or overlap" on the left are extended to the new @BinFrom.

### 2.4 Conditional INSERT - Only If Not Already Covered

**What**: Inserts the new range as a new row only if it is not already fully contained within an existing range.

**Parameters/Columns Involved**: `@BinFrom`, `@BinTo`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Billing.BadBin WHERE @BinFrom >= BinFrom AND @BinTo <= BinTo)`: check if the new range is a subset of any existing range.
- If fully covered: no INSERT (the new range is already blocked by an existing entry).
- If not covered (or after merge operations changed existing ranges): INSERT (@BinFrom, @BinTo).
- Note: After the merge UPDATEs in steps 1 and 2, the NOT EXISTS check is re-evaluated. The merge may have already created a covering range, in which case the INSERT is still skipped.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BinFrom | INTEGER | NO | - | VERIFIED | Lower bound (inclusive) of the BIN range to block. Must be a 6-digit integer (100000-999999). Represents the first 6 digits of the card number at the range start. |
| 2 | @BinTo | INT | NO | - | VERIFIED | Upper bound (inclusive) of the BIN range to block. Must be a 6-digit integer (100000-999999) and >= @BinFrom. Represents the first 6 digits of the card number at the range end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BinFrom, @BinTo | Billing.BadBin | WRITER (UPDATE + INSERT) | Extends existing ranges (2 UPDATE operations) and inserts new range if not already covered. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from fraud prevention administration tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BadBinAdd (procedure)
+- Billing.BadBin (table)   [UPDATE (merge adjacent/overlapping ranges) + INSERT (new range)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BadBin | Table | UPDATE existing ranges for interval merging; INSERT new blocked BIN range |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from fraud/risk administration. See also: Billing.BadBinRemove (the deletion counterpart).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Silent on invalid input**: If @BinFrom or @BinTo are outside 100000-999999, or @BinFrom > @BinTo, the procedure returns 0 without error and without any database modification. Callers that don't validate input will not know the call was a no-op.
- **Legacy error handling**: Uses `SELECT @LocalError = @@ERROR` (old-style) rather than TRY-CATCH. RAISERROR(60000,...) is used on error, not THROW.
- **Merge algorithm correctness**: The two UPDATE steps run sequentially. In rare cases involving complex overlaps, the ordering matters. The left-extension (step 2) runs after right-extension (step 1), which is correct for most scenarios. However, if multiple existing ranges overlap the new range in complex ways, not all merges may complete in one call (multiple rows could independently satisfy the conditions).
- **Transaction**: Full BEGIN/COMMIT TRANSACTION with ROLLBACK on each error check.

---

## 8. Sample Queries

### 8.1 Block a new BIN range
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BadBinAdd
    @BinFrom = 411111,
    @BinTo   = 411199;
SELECT @Result AS ReturnCode;  -- 0 = success (or no-op if invalid)
```

### 8.2 Verify the blocked range was added
```sql
SELECT  BinFrom, BinTo, BinTo - BinFrom + 1 AS RangeSize
FROM    Billing.BadBin WITH (NOLOCK)
WHERE   BinFrom <= 411199
  AND   BinTo   >= 411111
ORDER BY BinFrom;
```

### 8.3 View all blocked BIN ranges
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
*Object: Billing.BadBinAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BadBinAdd.sql*
