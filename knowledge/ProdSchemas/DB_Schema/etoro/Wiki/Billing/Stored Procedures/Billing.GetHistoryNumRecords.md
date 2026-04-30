# Billing.GetHistoryNumRecords

> Returns the total transaction count for a customer in a date range via an OUTPUT parameter, summing deposits, withdrawals, and bonus/compensation credits - the pagination count companion to Billing.GetHistory.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumOfRecords OUTPUT - the total record count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetHistoryNumRecords` is the count query that powers the pagination header for the customer transaction history view. Before displaying a page of results from `Billing.GetHistory`, the UI calls this procedure to know the total number of records available - so it can render the total page count and navigation controls.

The procedure uses the same three-branch logic and identical filters as `Billing.GetHistory` (same tables, same CID, DateFrom, DateTo, and CreditTypeID=6/7 constraint), ensuring that the count is always consistent with the actual data returned by GetHistory. The count is returned as an OUTPUT parameter rather than a result set.

Data flows outward only via the OUTPUT parameter - no result set is returned. No SQL-layer callers were found; it is consumed directly by the customer portal application alongside GetHistory.

---

## 2. Business Logic

### 2.1 Three-Branch Count Matching GetHistory

**What**: The total count is the sum of three independent COUNT queries, each matching exactly one UNION branch in GetHistory.

**Columns/Parameters Involved**: `@NumOfRecords` OUTPUT, `@CID`, `@DateFrom`, `@DateTo`

**Rules**:
- **Deposits**: `COUNT(*) FROM Billing.Deposit LEFT JOIN Billing.Funding WHERE PaymentDate BETWEEN @DateFrom AND @DateTo AND CID=@CID`
- **Withdrawals**: `COUNT(*) FROM Billing.Withdraw WHERE CID=@CID AND RequestDate BETWEEN @DateFrom AND @DateTo`
- **Credits**: `COUNT(*) FROM History.Credit WHERE CID=@CID AND CreditTypeID IN (6,7) AND Occurred BETWEEN @DateFrom AND @DateTo`
- Sum is assigned to `@NumOfRecords OUTPUT`
- The commented-out PaymentStatusID filters in deposits branch mirror GetHistory's commented-out filters (both procedures retain the same disabled filters for symmetry)

**Diagram**:
```
@NumOfRecords =
  COUNT(Deposits in date range for @CID)
  + COUNT(Withdrawals in date range for @CID)
  + COUNT(Credits CreditTypeID IN(6,7) in date range for @CID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Applied as the primary filter across all three COUNT queries. |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Date range start. Applied to PaymentDate (deposits), RequestDate (withdrawals), Occurred (credits). |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | Date range end. Applied to same columns as @DateFrom. |

### Output Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | @NumOfRecords | INT | NO | - | CODE-BACKED | OUTPUT parameter. Total count of transactions matching the filters: deposits + withdrawals + credits (CreditTypeID 6 and 7). Used by the UI to calculate total page count for pagination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit COUNT (FROM) | Billing.Deposit | Direct Read | Counts deposit records for the customer in the date range |
| Deposit COUNT (LEFT JOIN) | Billing.Funding | Direct Read | Joined to match GetHistory's deposit branch structure |
| Withdraw COUNT (FROM) | Billing.Withdraw | Direct Read | Counts withdrawal requests for the customer |
| Credit COUNT (FROM) | History.Credit | Direct Read | Counts bonus/compensation credits (CreditTypeID IN 6,7) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers. Called from application code alongside Billing.GetHistory for pagination header. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetHistoryNumRecords (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.Withdraw (table)
└── History.Credit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | COUNT - deposits in date range for customer |
| Billing.Funding | Table | LEFT JOIN - mirrors GetHistory deposit branch structure |
| Billing.Withdraw | Table | COUNT - withdrawal requests in date range |
| History.Credit | Table | COUNT - bonus/compensation credits (CreditTypeID IN 6,7) |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get total transaction count for customer history

```sql
DECLARE @Total INT
EXEC Billing.GetHistoryNumRecords
    @CID          = 12345678,
    @DateFrom     = '2026-02-17',
    @DateTo       = '2026-03-18',
    @NumOfRecords = @Total OUTPUT
SELECT @Total AS TotalTransactions
```

### 8.2 Calculate page count for 25 rows per page

```sql
DECLARE @Total INT
EXEC Billing.GetHistoryNumRecords
    @CID          = 12345678,
    @DateFrom     = '2026-02-17',
    @DateTo       = '2026-03-18',
    @NumOfRecords = @Total OUTPUT
SELECT
    @Total AS TotalRecords,
    CEILING(@Total / 25.0) AS TotalPages
```

### 8.3 Equivalent ad-hoc count query

```sql
SELECT
    (SELECT COUNT(*) FROM Billing.Deposit WITH (NOLOCK)
     LEFT JOIN Billing.Funding WITH (NOLOCK) ON Deposit.FundingID = Funding.FundingID
     WHERE PaymentDate BETWEEN '2026-02-17' AND '2026-03-18' AND CID = 12345678)
  + (SELECT COUNT(*) FROM Billing.Withdraw WITH (NOLOCK)
     WHERE CID = 12345678 AND RequestDate BETWEEN '2026-02-17' AND '2026-03-18')
  + (SELECT COUNT(*) FROM History.Credit WITH (NOLOCK)
     WHERE CID = 12345678 AND CreditTypeID IN (6,7) AND Occurred BETWEEN '2026-02-17' AND '2026-03-18')
  AS TotalRecords
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetHistoryNumRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetHistoryNumRecords.sql*
