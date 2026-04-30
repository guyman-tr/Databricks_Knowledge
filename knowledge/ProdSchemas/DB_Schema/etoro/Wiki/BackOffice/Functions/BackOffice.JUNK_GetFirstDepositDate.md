# BackOffice.JUNK_GetFirstDepositDate

> DEPRECATED scalar function returning the date of a customer's first-ever deposit (MIN Occurred from History.Credit WHERE CreditTypeID=1).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DATETIME (first deposit date for @CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetFirstDepositDate` returns the timestamp of the earliest deposit event for a given customer ID. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "When did customer @CID make their very first deposit?" It queries `History.Credit` filtering to `CreditTypeID=1` (Deposit) and returns `MIN(Occurred)`. If the customer has never deposited, the function returns NULL (the DECLARE initialises @DepositDate to NULL and no assignment occurs if no rows match).

This is the companion to `JUNK_GetLastDepositDate` which returns the most recent deposit date. Together they define the customer's deposit activity window.

**Business use case**: First deposit date is a key customer lifecycle milestone - it marks conversion from registered to funded customer, triggers FTD (First Time Depositor) bonuses, and is used in sales performance reporting.

---

## 2. Business Logic

### 2.1 First Deposit Date Lookup

**What**: Simple MIN aggregate over History.Credit filtered to a single customer and deposit credit type.

**Columns/Parameters Involved**: `@CID`, `@DepositDate`, `CID`, `CreditTypeID`, `Occurred`

**Rules**:
- Filters `History.Credit` WHERE `CID = @CID` AND `CreditTypeID = 1` (deposit only - from DDL comment).
- Returns `MIN(Occurred)` - the earliest deposit timestamp.
- Uses `WITH (NOLOCK)` - dirty read allowed for reporting performance.
- Returns NULL if customer @CID has no deposit records in History.Credit.
- Returns a DATETIME value (includes time component, not just date).

**Diagram**:
```
@CID
  |
  v
History.Credit WITH (NOLOCK)
  WHERE CID = @CID AND CreditTypeID = 1 (deposit)
  |
  v
MIN(Occurred)
  |
  v
Returns: DATETIME (or NULL if no deposits)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used to filter History.Credit to a single customer's deposit records. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return) | DATETIME | YES | NULL | CODE-BACKED | Timestamp of the customer's earliest deposit (MIN Occurred from History.Credit WHERE CreditTypeID=1). Returns NULL if the customer has never deposited. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, CreditTypeID, Occurred | History.Credit | Table read | Source of deposit records. Filtered to CreditTypeID=1 (deposit). Returns MIN(Occurred). |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetFirstDepositDate (function)
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | Queried for MIN(Occurred) WHERE CID = @CID AND CreditTypeID = 1. |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function. JUNK_ prefix = deprecated. Uses WITH (NOLOCK).

---

## 8. Sample Queries

### 8.1 Get first deposit date for a specific customer

```sql
SELECT BackOffice.JUNK_GetFirstDepositDate(12345) AS FirstDepositDate;
```

### 8.2 Days since first deposit for a customer

```sql
SELECT
    CID,
    BackOffice.JUNK_GetFirstDepositDate(CID) AS FirstDeposit,
    DATEDIFF(DAY, BackOffice.JUNK_GetFirstDepositDate(CID), GETDATE()) AS DaysSinceFirstDeposit
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Compare first and last deposit dates

```sql
SELECT
    CID,
    BackOffice.JUNK_GetFirstDepositDate(CID) AS FirstDeposit,
    BackOffice.JUNK_GetLastDepositDate(CID) AS LastDeposit,
    DATEDIFF(DAY,
        BackOffice.JUNK_GetFirstDepositDate(CID),
        BackOffice.JUNK_GetLastDepositDate(CID)) AS DepositSpanDays
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetFirstDepositDate | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetFirstDepositDate.sql*
