# Billing.GetMedianDepositAmount

> Calculates the median deposit amount for a customer across all their successful deposits (PaymentStatusID=2) using the standard SQL row-numbering median algorithm.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - returns a single MedianDepositAmount value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetMedianDepositAmount` computes the statistical median of all successful deposit amounts for a given customer. Unlike the arithmetic mean (average), the median is resistant to outliers - a single very large deposit does not skew the result, making it a better representation of a customer's "typical" deposit size.

This metric is used for customer segmentation, risk profiling, or personalization: knowing that a customer typically deposits $200 (median) rather than $500 (mean, skewed by one large deposit) allows more accurate behavioral modeling. `PaymentStatusID=2` filters to only completed/approved deposits, excluding pending, failed, or reversed transactions.

The procedure returns NULL (via AVG of empty set) when the customer has no successful deposits, and a single numeric value when deposits exist.

---

## 2. Business Logic

### 2.1 Standard SQL Median Algorithm

**What**: Row-number each deposit by amount, then select the middle row(s) and average them - the standard SQL median calculation that handles both odd and even row counts.

**Columns/Parameters Involved**: `@CID`, `Amount`, `PaymentStatusID=2`, `ROW_NUMBER`, `COUNT`

**Rules**:
- Filter: `WHERE CID = @CID AND PaymentStatusID = 2` - only successful deposits
- `PaymentStatusID=2` = successful/approved deposits (consistent with other Billing procedures)
- `ROW_NUMBER() OVER (ORDER BY Amount)` - ranks deposits by amount low-to-high
- `COUNT(*)` - total deposit count
- Median rows: `RowNum IN ((Count + 1) / 2, (Count + 2) / 2)` - handles both odd and even counts
- `AVG(Amount)` of the selected middle rows - for odd count, both formulas produce the same RowNum; for even count they produce two consecutive RowNums and AVG returns their mean
- Returns `MedianDepositAmount` - a single nullable NUMERIC/FLOAT value (NULL if no deposits)

**Examples**:
```
Deposits: [100, 200, 300]          -> Count=3, RowNums=(2,2) -> median = 200
Deposits: [100, 200, 300, 400]     -> Count=4, RowNums=(2,3) -> median = AVG(200,300) = 250
Deposits: []  (none)               -> NULL
```

**Note**: `TOP 100 PERCENT ... ORDER BY Amount` in `SortedDeposits` CTE is a legacy SQL Server pattern to allow ORDER BY inside a CTE (required for the windowing function to produce a deterministic sort order). Modern SQL Server versions allow `ORDER BY` in `ROW_NUMBER()` directly, but this pattern preserves compatibility.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Restricts calculation to deposits for this customer only. FK to Customer.CustomerStatic.CID. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | MedianDepositAmount | numeric | YES | NULL | CODE-BACKED | The median deposit amount across all successful (PaymentStatusID=2) deposits for the customer. NULL if the customer has no successful deposits. Amount is in the same unit as Billing.Deposit.Amount (raw, not multiplied by 100). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM (SortedDeposits CTE) | Billing.Deposit | Direct Read | All successful deposits (PaymentStatusID=2) for the customer, used for median calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers found. Called from application or analytics code. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMedianDepositAmount (procedure)
└── Billing.Deposit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Read - Amount values for successful deposits (PaymentStatusID=2) for the customer |

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

### 8.1 Get median deposit amount for a customer

```sql
EXEC Billing.GetMedianDepositAmount @CID = 12345678
-- Returns: MedianDepositAmount (or NULL if no successful deposits)
```

### 8.2 Equivalent ad-hoc query

```sql
WITH SortedDeposits AS (
    SELECT TOP 100 PERCENT Amount, ROW_NUMBER() OVER (ORDER BY Amount) AS RowNum
    FROM Billing.Deposit WITH (NOLOCK)
    WHERE CID = 12345678
      AND PaymentStatusID = 2
    ORDER BY Amount
),
DepositCount AS (
    SELECT COUNT(*) AS Count FROM SortedDeposits
)
SELECT AVG(Amount) AS MedianDepositAmount
FROM (
    SELECT Amount
    FROM SortedDeposits, DepositCount
    WHERE RowNum IN ((Count + 1) / 2, (Count + 2) / 2)
) AS Median
```

### 8.3 Compare median vs average for a customer

```sql
-- Average (mean):
SELECT AVG(CAST(Amount AS FLOAT)) AS MeanDeposit
FROM Billing.Deposit WITH (NOLOCK)
WHERE CID = 12345678 AND PaymentStatusID = 2

-- Median (via proc):
EXEC Billing.GetMedianDepositAmount @CID = 12345678
-- If median << mean: customer made a few large deposits pulling the average up
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMedianDepositAmount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetMedianDepositAmount.sql*
