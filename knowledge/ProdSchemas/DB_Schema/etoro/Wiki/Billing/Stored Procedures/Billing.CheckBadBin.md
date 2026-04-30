# Billing.CheckBadBin

> Checks whether a card's BIN (Bank Identification Number prefix) falls within any flagged range in Billing.BadBin, returning a result set with InBadBins=1 if blocked or InBadBins=0 if clean.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN @@ERROR; result set with InBadBins column (1=blocked, 0=clean) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckBadBin` is a card fraud prevention check that determines whether a credit or debit card's BIN (the first 6-8 digits) falls within any range marked as high-risk or fraudulent in `Billing.BadBin`. BIN ranges can be blocked because they are associated with prepaid cards, high-chargeback issuers, or jurisdictions restricted by compliance policy.

This procedure is called during deposit payment authorization to pre-screen cards before processing. The result set (not an OUTPUT parameter) allows callers to check the `InBadBins` value and reject the deposit if it equals 1.

See also `Billing.CheckInBadBins` which performs the same check using an OUTPUT parameter pattern instead of a result set.

---

## 2. Business Logic

### 2.1 BIN Range Lookup

**What**: Checks if @CardPrefix is covered by any BIN range in Billing.BadBin.

**Rules**:
- `SELECT @CheckResult = CASE WHEN EXISTS(...) THEN 1 ELSE 0 END`
- EXISTS subquery: `SELECT 1 FROM Billing.BadBin WHERE @CardPrefix BETWEEN BinFrom AND BinTo`
- `SELECT @CheckResult AS InBadBins` - returns result set with single column.
- RETURN @@ERROR.

**Result Set**:
| Column | Value | Meaning |
|--------|-------|---------|
| InBadBins | 1 | Card BIN is in a blocked range - reject the deposit |
| InBadBins | 0 | Card BIN is not blocked - BIN check passed |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardPrefix | VARCHAR(8) | NO | - | CODE-BACKED | The BIN prefix of the card to check - typically the first 6 digits (IIN/BIN standard) but may be 8 digits for extended BINs. Compared using BETWEEN against Billing.BadBin.BinFrom and BinFrom.BinTo. Must be a numeric string matching the format used in the BadBin table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardPrefix | Billing.BadBin | READER | BETWEEN range check against BinFrom/BinTo to determine if the BIN is blocked |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from payment authorization application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckBadBin (procedure)
+-- Billing.BadBin (table)   [READ - BETWEEN BinFrom/BinTo range check; ~4.95M rows]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BadBin | Table | READ - checks if @CardPrefix falls in any blocked BIN range |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Result set vs OUTPUT parameter**: CheckBadBin returns the check result as a result set (`SELECT @CheckResult AS InBadBins`). Its sibling `Billing.CheckInBadBins` uses an OUTPUT parameter instead. Both perform the identical BETWEEN check but differ in how they surface the result to the caller.
- **BETWEEN for BIN range matching**: Billing.BadBin stores ranges as BinFrom/BinTo string pairs (~4.95M rows). The BETWEEN operator does a string comparison - BIN values must be consistently formatted (same length, numeric) for correct range matching.
- **No transaction**: This is a read-only check with no data modifications; no transaction needed.
- **Performance**: Billing.BadBin has ~4.95M rows. The EXISTS subquery short-circuits on first match. Index on BinFrom/BinTo is important for performance at this row count.

---

## 8. Sample Queries

### 8.1 Check a card's BIN
```sql
EXEC Billing.CheckBadBin @CardPrefix = '411111';
-- Returns: InBadBins = 0 (clean) or 1 (blocked)
```

### 8.2 Verify the BIN range directly
```sql
SELECT TOP 5 BinFrom, BinTo
FROM Billing.BadBin WITH (NOLOCK)
WHERE '411111' BETWEEN BinFrom AND BinTo;
-- Returns matching ranges (if any)
```

### 8.3 Count blocked BIN ranges
```sql
SELECT COUNT(*) AS TotalBadBinRanges
FROM Billing.BadBin WITH (NOLOCK);
-- ~4.95M ranges
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckBadBin | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckBadBin.sql*
