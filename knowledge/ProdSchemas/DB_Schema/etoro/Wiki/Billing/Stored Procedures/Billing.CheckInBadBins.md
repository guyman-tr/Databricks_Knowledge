# Billing.CheckInBadBins

> Checks whether a card's BIN prefix falls within any flagged range in Billing.BadBin, setting @CheckResult OUTPUT to 1 (blocked) or 0 (clean); the OUTPUT-parameter sibling of Billing.CheckBadBin.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CheckResult OUTPUT: 0=clean, 1=BIN is in bad bins list; RETURN @@ERROR |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckInBadBins` performs the same BIN fraud check as `Billing.CheckBadBin` - determining whether a credit card's Bank Identification Number falls within a blocked BIN range in `Billing.BadBin`. The difference is the calling convention: this procedure returns the result via an OUTPUT parameter rather than a result set, making it suitable for callers that prefer parameter-based integration over result set consumption.

Used in payment authorization flows to reject deposits from blocked card ranges (prepaid cards, high-chargeback issuers, restricted jurisdictions). Billing.BadBin contains ~4.95 million BIN ranges.

---

## 2. Business Logic

### 2.1 BIN Range Check (OUTPUT Pattern)

**What**: Checks if @CardPrefix falls in any Billing.BadBin range; returns result via OUTPUT parameter.

**Rules**:
- `SET @CheckResult = CASE WHEN EXISTS(...) THEN 1 ELSE 0 END`
- EXISTS subquery: `SELECT 1 FROM Billing.BadBin WHERE @CardPrefix BETWEEN BinFrom AND BinTo`
- @CheckResult=1: BIN is in a blocked range - reject.
- @CheckResult=0: BIN is clean - proceed.
- RETURN @@ERROR.

**@CheckResult Values**:
| Value | Meaning |
|-------|---------|
| 0 | BIN is not blocked - card passes BIN check |
| 1 | BIN is in a bad bin range - reject the deposit |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardPrefix | VARCHAR(8) | NO | - | CODE-BACKED | The BIN prefix (first 6 or 8 digits) of the card to check. Compared using BETWEEN against Billing.BadBin.BinFrom and BinTo ranges. Must be numeric string in the same format as the BadBin table values. |
| 2 | @CheckResult | INTEGER | YES | - | CODE-BACKED | OUTPUT parameter. Set to 1 if the BIN is within any blocked range in Billing.BadBin; 0 if clean. Not set on error (caller should check RETURN value for @@ERROR). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardPrefix | Billing.BadBin | READER | BETWEEN range check against BinFrom/BinTo (~4.95M rows) |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from payment authorization application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckInBadBins (procedure)
+-- Billing.BadBin (table)   [READ - BETWEEN BinFrom/BinTo range check; ~4.95M rows]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BadBin | Table | READ - BETWEEN range check to determine if @CardPrefix is in a blocked BIN range |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **OUTPUT vs result set**: CheckInBadBins uses @CheckResult OUTPUT; `Billing.CheckBadBin` returns a result set (`SELECT @CheckResult AS InBadBins`). Both perform the identical BETWEEN EXISTS check against Billing.BadBin. Choice of which to call depends on the caller's preferred integration pattern.
- **Consistent naming with other Check* SPs**: The "CheckIn*" naming convention matches `Billing.CheckInBlockedCards` and `Billing.CheckInBlockedPayPals` - all three use OUTPUT parameters.
- **EXISTS short-circuit**: With ~4.95M rows in Billing.BadBin, EXISTS stops at the first match. Index coverage on BinFrom/BinTo is critical for performance.

---

## 8. Sample Queries

### 8.1 Check a card BIN via OUTPUT parameter
```sql
DECLARE @CheckResult INT;
EXEC Billing.CheckInBadBins
    @CardPrefix  = '411111',
    @CheckResult = @CheckResult OUTPUT;
SELECT @CheckResult AS CheckResult,
    CASE @CheckResult
        WHEN 0 THEN 'Clean - BIN not blocked'
        WHEN 1 THEN 'Blocked - BIN in bad bins list'
    END AS Description;
```

### 8.2 Verify the BIN range directly
```sql
SELECT TOP 5 BinFrom, BinTo
FROM Billing.BadBin WITH (NOLOCK)
WHERE '411111' BETWEEN BinFrom AND BinTo;
```

### 8.3 Compare with CheckBadBin result-set variant
```sql
-- This returns the same result as CheckInBadBins but as a result set:
EXEC Billing.CheckBadBin @CardPrefix = '411111';
-- Returns: InBadBins = 0 or 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckInBadBins | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckInBadBins.sql*
