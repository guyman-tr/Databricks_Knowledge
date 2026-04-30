# Billing.GetTotalDeposits

> Returns the USD-equivalent total of all approved deposits for a customer within a date range: COALESCE(SUM(Amount * ExchangeRate), 0) from Billing.Deposit where PaymentStatusID=2 and PaymentDate BETWEEN @FromDate AND @ToDate.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FromDate + @ToDate; returns scalar YearlyDeposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetTotalDeposits calculates the total approved deposit amount (in USD-equivalent) for a specific customer over a caller-defined date range. Created per PAYIL-8347 ("Select SUM of deposits between dates for specific CID"), it is named "GetTotalDeposits" but is date-range parameterized - the "Yearly" label on the output column (`YearlyDeposit`) reflects the original use case of summing annual deposits, likely for AML/regulatory annual deposit limit checks or customer financial profile reporting.

Key characteristics:
- **Approved only**: `PaymentStatusID = 2` (Approved) - excludes pending, rejected, refunded
- **USD normalization**: `Amount * ExchangeRate` converts deposits to USD at the exchange rate stored at deposit time
- **Zero instead of NULL**: `COALESCE(..., 0)` returns 0 if no deposits found (safe for threshold comparisons)
- **Date-only range**: `@FromDate DATE`, `@ToDate DATE` - time-of-day is ignored; BETWEEN is inclusive on both ends

---

## 2. Business Logic

### 2.1 Approved Deposit Aggregation

**What**: Sums all approved deposits for a customer in the given date range.

**Columns/Parameters Involved**: `@CID`, `@FromDate`, `@ToDate`, `Billing.Deposit.Amount`, `Billing.Deposit.ExchangeRate`, `Billing.Deposit.PaymentStatusID`, `Billing.Deposit.PaymentDate`

**Rules**:
- `WHERE CID = @CID` - single customer
- `AND PaymentStatusID = 2` - approved only (2 = Approved)
- `AND PaymentDate BETWEEN @FromDate AND @ToDate` - inclusive date range; @FromDate and @ToDate are DATE type so time component is 00:00:00
- `COALESCE(SUM(Amount * ExchangeRate), 0)` - returns 0 if no qualifying deposits

### 2.2 USD-Equivalent Normalization

**What**: Converts each deposit's local-currency amount to USD using the exchange rate stored at deposit time.

**Columns/Parameters Involved**: `Billing.Deposit.Amount`, `Billing.Deposit.ExchangeRate`

**Rules**:
- `Amount * ExchangeRate` = USD-equivalent value at time of deposit
- ExchangeRate in Billing.Deposit is stored at the moment of deposit creation (not a live rate)
- Result column named `YearlyDeposit` (reflecting original use case for annual period aggregation)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters Billing.Deposit to this customer only. |
| 2 | @FromDate | DATE | NO | - | CODE-BACKED | Start of the date range (inclusive). DATE type - time component treated as 00:00:00. |
| 3 | @ToDate | DATE | NO | - | CODE-BACKED | End of the date range (inclusive). DATE type - time component treated as 23:59:59 effective due to BETWEEN semantics with DATE. |
| - | YearlyDeposit | DECIMAL | NO | 0 | CODE-BACKED | USD-equivalent sum of approved deposits in the date range. COALESCE ensures 0 is returned (not NULL) when no deposits match. Despite the name, period is caller-defined by @FromDate/@ToDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentDate, PaymentStatusID, Amount, ExchangeRate | Billing.Deposit | SELECT + SUM | Source of all deposit data; filtered to approved deposits in date range |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Compliance / AML service | @CID, @FromDate, @ToDate | EXEC | Annual deposit limit checks and customer financial profile reporting (PAYIL-8347) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetTotalDeposits (procedure)
+-- Billing.Deposit (table) [approved deposits in date range, USD-normalized sum]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SUM(Amount * ExchangeRate) for CID, PaymentStatusID=2, PaymentDate in range |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Compliance / AML service | External | Yearly (or period) deposit totals for regulatory reporting and limit enforcement |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PaymentStatusID=2 hardcoded | Design | Only approved deposits counted; no way to include other statuses via parameter |
| COALESCE to 0 | Behavior | Returns 0 not NULL when customer has no approved deposits in range; safe for threshold comparisons |
| DATE type parameters | Design | No time-of-day precision; BETWEEN on DATE columns matches entire start and end days |
| NOLOCK | Concurrency | Uses WITH (NOLOCK) - dirty reads acceptable; designed for analytical/compliance queries not real-time processing |
| "YearlyDeposit" misnomer | Naming | Column name reflects original use case (annual check per PAYIL-8347) but the window is actually caller-defined |

---

## 8. Sample Queries

### 8.1 Get total approved deposits for a customer in the current year

```sql
EXEC [Billing].[GetTotalDeposits]
    @CID = 12345,
    @FromDate = '2026-01-01',
    @ToDate = '2026-12-31'
-- Returns: YearlyDeposit (USD-equivalent sum, 0 if none)
```

### 8.2 Equivalent direct query

```sql
SELECT COALESCE(SUM(Amount * ExchangeRate), 0) AS YearlyDeposit
FROM [Billing].[Deposit] WITH (NOLOCK)
WHERE CID = 12345
  AND PaymentStatusID = 2
  AND PaymentDate BETWEEN '2026-01-01' AND '2026-12-31'
```

---

## 9. Atlassian Knowledge Sources

**Confluence**: "Deposit Info Current Structure and Data" (/spaces/MG) - related to deposit data context.

**Jira**: PAYIL-8347 - original requirement for this procedure ("Select SUM of deposits between dates for specific CID").

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 1 Confluence + 1 Jira (PAYIL-8347) | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetTotalDeposits | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetTotalDeposits.sql*
