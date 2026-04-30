# Trade.ValidateCorrectionDividendId

> Multi-statement table-valued function that validates a correction dividend ID by verifying that the provided ExDate and DividendCurrencyID match the original dividend record in Trade.IndexDividends.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Parameters** | @CorrectionDividendID INT, @CorrectionExDate DATE, @CorrectionDividendCurrencyID INT |
| **Returns** | @tblResult TABLE (isValid BIT) |
| **Status** | Active |

---

## 1. Business Meaning

Trade.ValidateCorrectionDividendId is a validation function used during dividend correction operations. When a dividend payment is being corrected (e.g., wrong amount, adjustment after ex-date), this function ensures that the correction references a valid original dividend by verifying that the correction's ExDate and DividendCurrencyID match the original dividend record in `Trade.IndexDividends`.

This prevents data integrity issues where a correction could accidentally reference the wrong dividend, potentially causing incorrect financial adjustments.

---

## 2. Business Logic

### 2.1 Dividend Correction Validation

**What**: Validates that a correction dividend's key attributes match the original.

**Parameters**:
- `@CorrectionDividendID INT` - The DividendID being corrected (nullable)
- `@CorrectionExDate DATE` - The ex-date claimed by the correction
- `@CorrectionDividendCurrencyID INT` - The currency ID claimed by the correction

**Rules**:
1. If `@CorrectionDividendID IS NULL`, the function returns `isValid = 1` (no correction = valid by default)
2. If `@CorrectionDividendID IS NOT NULL`:
   a. Look up the original dividend in `Trade.IndexDividends` by DividendID
   b. Compare `ExDate` and `DividendCurrencyID` from the original record with the provided values
   c. If EITHER `ExDate <> @CorrectionExDate` OR `DividendCurrencyID <> @CorrectionDividendCurrencyID`, return `isValid = 0`
   d. If both match, return `isValid = 1`
3. If the DividendID doesn't exist in Trade.IndexDividends, the variables remain NULL and the comparison fails, returning `isValid = 0`

---

## 3. Data Overview

Returns a single row with a single BIT column (isValid: 0 or 1).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | isValid | bit | NO | 1 | CODE-BACKED | 1 if correction is valid or no correction needed, 0 if mismatch. |

### 4.1 Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CorrectionDividendID | int | DividendID to validate (NULL = no correction). |
| 2 | @CorrectionExDate | date | Expected ex-date of the dividend. |
| 3 | @CorrectionDividendCurrencyID | int | Expected currency of the dividend. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DividendID | Trade.IndexDividends | SELECT | Validates against original dividend record |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertIndexDividend | Stored Procedure | Validates correction before inserting new dividend |
| Trade.GetInvalidDividendsByCorrection | Stored Procedure | Identifies invalid corrections in batch |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateCorrectionDividendId (function)
+-- Trade.IndexDividends (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | SELECT - ExDate, DividendCurrencyID lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertIndexDividend | Stored Procedure | Correction validation |
| Trade.GetInvalidDividendsByCorrection | Stored Procedure | Batch correction validation |

---

## 7. Technical Details

### 7.1 Function Type

Multi-statement TVF (RETURNS @tblResult TABLE ... BEGIN ... END). Unlike inline TVFs, this cannot be inlined by the optimizer, which may have performance implications if called at high frequency. However, since dividend corrections are rare operations, this is not a practical concern.

### 7.2 Default Behavior

The function defaults `@isValid = 1`, so it only sets to 0 when an explicit mismatch is found. If `@CorrectionDividendID IS NULL`, the INSERT fires immediately with the default value of 1.

---

## 8. Sample Queries

### 8.1 Validate a specific correction
```sql
SELECT  isValid
FROM    Trade.ValidateCorrectionDividendId(12345, '2025-06-15', 1);
```

### 8.2 Use in a dividend insert validation
```sql
IF EXISTS (SELECT 1 FROM Trade.ValidateCorrectionDividendId(@CorrectionDivID, @ExDate, @CurrID) WHERE isValid = 0)
BEGIN
    RAISERROR('Correction dividend validation failed', 16, 1);
    RETURN;
END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 referencing | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateCorrectionDividendId | Type: Function | Source: etoro/etoro/Trade/Functions/Trade.ValidateCorrectionDividendId.sql*
