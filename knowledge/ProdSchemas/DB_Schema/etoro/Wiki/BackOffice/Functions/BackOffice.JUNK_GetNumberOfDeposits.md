# BackOffice.JUNK_GetNumberOfDeposits

> DEPRECATED scalar function returning the total count of deposit events for a customer (COUNT(*) from History.Credit WHERE CreditTypeID=1).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INTEGER (deposit count for @CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetNumberOfDeposits` returns the total number of deposit transactions ever made by a customer. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "How many times has customer @CID deposited money?" It counts all `History.Credit` rows where `CreditTypeID=1` (Deposit) for the given customer. Returns 0 if the customer has never deposited (guaranteed by initialising the variable to 0).

**Business use case**: Deposit count is a key customer quality metric - multi-depositor customers are more valuable and committed than one-time depositors. Used in customer lifecycle analysis, LTV calculations, and segmentation (e.g., FTD vs. repeat depositor vs. frequent depositor).

**Note**: This counts deposit events (credit records), not funding methods. A customer who deposited $100 three times would return 3, even if all three used the same credit card.

---

## 2. Business Logic

### 2.1 Deposit Count Lookup

**What**: Simple COUNT aggregate over History.Credit filtered to a single customer and deposit credit type.

**Columns/Parameters Involved**: `@CID`, `@NumberOfDeposits`, `CID`, `CreditTypeID`

**Rules**:
- Initialises `@NumberOfDeposits = 0` to guarantee a non-NULL return even if no deposits exist.
- Queries `History.Credit` WHERE `CID = @CID` AND `CreditTypeID = 1` (deposit - from DDL comment).
- Returns `COUNT(*)` - total number of matching rows.
- Uses `WITH (NOLOCK)` for read performance.
- Return type is INTEGER. Very high deposit counts (unlikely in practice) would not overflow.

**Diagram**:
```
@CID
  |
  v
@NumberOfDeposits = 0 (safe default)
  |
  v
History.Credit WITH (NOLOCK)
  WHERE CID = @CID AND CreditTypeID = 1 (deposit)
  COUNT(*) -> @NumberOfDeposits
  |
  v
Returns: INTEGER (0 if no deposits, N if N deposit events exist)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used to filter History.Credit to this customer's deposit records. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return) | INTEGER | NO | 0 | CODE-BACKED | Total number of deposit credit events (CreditTypeID=1) for this customer in History.Credit. Returns 0 if the customer has never deposited. Always non-NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, CreditTypeID | History.Credit | Table read | Source of deposit records. COUNT(*) WHERE CID = @CID AND CreditTypeID = 1. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetNumberOfDeposits (function)
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | Queried for COUNT(*) WHERE CID = @CID AND CreditTypeID = 1. |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function. JUNK_ prefix = deprecated. Uses WITH (NOLOCK). Always returns non-NULL (initialised to 0).

---

## 8. Sample Queries

### 8.1 Get number of deposits for a specific customer

```sql
SELECT BackOffice.JUNK_GetNumberOfDeposits(12345) AS NumberOfDeposits;
```

### 8.2 Customer deposit count with first/last deposit dates

```sql
SELECT
    CID,
    BackOffice.JUNK_GetNumberOfDeposits(CID) AS DepositCount,
    BackOffice.JUNK_GetFirstDepositDate(CID) AS FirstDeposit,
    BackOffice.JUNK_GetLastDepositDate(CID) AS LastDeposit
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Check if customer has ever deposited

```sql
SELECT
    CASE
        WHEN BackOffice.JUNK_GetNumberOfDeposits(12345) = 0 THEN 'Never Deposited'
        WHEN BackOffice.JUNK_GetNumberOfDeposits(12345) = 1 THEN 'FTD Only'
        ELSE 'Repeat Depositor'
    END AS DepositCategory;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetNumberOfDeposits | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetNumberOfDeposits.sql*
