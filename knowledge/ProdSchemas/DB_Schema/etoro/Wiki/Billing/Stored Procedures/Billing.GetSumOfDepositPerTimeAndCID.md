# Billing.GetSumOfDepositPerTimeAndCID

> Returns the USD-equivalent sum of a customer's deposits within a rolling time window for a specific funding type and set of payment statuses: used for risk/fraud deposit velocity checks (e.g., "how much has this customer deposited via credit card in the last 5 hours?").

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingType + @NumberOfHours; returns scalar SUM |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetSumOfDepositPerTimeAndCID calculates the total deposit amount (in USD-equivalent) that a customer has deposited via a specific payment method within a rolling N-hour window, filtered to a caller-supplied set of payment statuses. This is a deposit velocity check: the caller determines whether the result exceeds a threshold to enforce deposit limits, detect suspicious activity, or apply risk-based routing rules.

Key design choices:
- **Rolling window**: `PaymentDate >= GETUTCDATE() - @NumberOfHours` (UTC-based, default 5 hours)
- **Multi-status filter**: `@PaymentStatusIDs` is a comma-delimited string of integers parsed into a temp table via a WHILE loop (legacy pattern; works but has performance implications on repeated calls)
- **Exchange rate normalization**: `SUM(Amount * ExchangeRate)` converts local-currency deposits to USD-equivalent before summing
- Returns a single scalar: the total sum, or NULL if no qualifying deposits exist

---

## 2. Business Logic

### 2.1 Comma-Delimited Status ID Parsing

**What**: @PaymentStatusIDs is parsed from a VARCHAR comma-list into a temp table for use in an IN clause.

**Columns/Parameters Involved**: `@PaymentStatusIDs`, `#IDs.ID`

**Rules**:
- Ensures string ends with comma: `IF @PaymentStatusIDs NOT LIKE '%,' SET @PaymentStatusIDs = @PaymentStatusIDs + ','`
- WHILE loop extracts each token: `SUBSTRING(@PaymentStatusIDs, 1, CHARINDEX(',', @PaymentStatusIDs)-1)` -> inserts into #IDs
- Loop continues while `CHARINDEX(',', @PaymentStatusIDs) > 1` (more commas exist)
- Allows callers to supply multiple statuses (e.g., '2,4,' for Approved + Pending)

### 2.2 USD-Equivalent Deposit Sum

**What**: Computes the total deposit value in USD using each deposit's stored exchange rate.

**Columns/Parameters Involved**: `Billing.Deposit.Amount`, `Billing.Deposit.ExchangeRate`, `Amount` (result)

**Rules**:
- `SUM(Amount * BD.ExchangeRate)` - each deposit is converted to USD at the rate stored at deposit time
- ExchangeRate is from Billing.Deposit (stored at time of deposit, not a live rate)
- Result is NULL if no matching deposits exist (SUM of empty set)
- No currency label is returned - caller assumes USD-equivalent

### 2.3 Deposit Velocity Filter

**What**: Restricts to deposits within the rolling time window for the specific customer and payment type.

**Columns/Parameters Involved**: `@CID`, `@NumberOfHours`, `@FundingType`, `Billing.Deposit.PaymentDate`

**Rules**:
- `WHERE CID = @CID` - single customer
- `PaymentDate >= DATEADD(Hour, 0-@NumberOfHours, GETUTCDATE())` - rolling window; 0-@NumberOfHours is equivalent to -@NumberOfHours
- `AND FundingTypeID = @FundingType` - single payment method type (e.g., 1=CreditCard)
- `AND PaymentStatusID IN (SELECT ID FROM #IDs)` - filtered to caller-supplied statuses

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to check. Filters Billing.Deposit to this customer only. |
| 2 | @NumberOfHours | INT | YES | 5 | CODE-BACKED | Rolling time window in hours. Default 5 hours. Deposits with PaymentDate within this window are included. |
| 3 | @FundingType | INT | NO | - | CODE-BACKED | FundingTypeID to filter by. Joined from Billing.Funding via FundingID. Examples: 1=CreditCard, 3=PayPal, 22=UnionPay. |
| 4 | @PaymentStatusIDs | VARCHAR(100) | NO | - | CODE-BACKED | Comma-delimited list of PaymentStatusID values to include (e.g., '2,' for Approved only, or '2,4,' for Approved + Pending). Parsed into temp table #IDs. |
| - | Amount | DECIMAL | YES | - | CODE-BACKED | Scalar result: sum of (Deposit.Amount * Deposit.ExchangeRate) for qualifying deposits. NULL if no deposits match. Represents USD-equivalent total. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentDate, PaymentStatusID, Amount, ExchangeRate | Billing.Deposit | SELECT + SUM | Primary data source; rolling window + status filter |
| FundingID, FundingTypeID | Billing.Funding | INNER JOIN | Joins to filter by FundingTypeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Risk / fraud checking service | @CID, @FundingType, @NumberOfHours | EXEC | Deposit velocity check for rate limiting and risk scoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetSumOfDepositPerTimeAndCID (procedure)
+-- Billing.Deposit (table) [rolling window sum with exchange rate]
+-- Billing.Funding (table) [FundingTypeID filter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Source of Amount, ExchangeRate, PaymentDate, CID, PaymentStatusID; rolling window aggregate |
| Billing.Funding | Table | Joined via FundingID to apply FundingTypeID filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Risk/fraud checking service | External | Deposit velocity checks by payment type and time window |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UTC time window | Design | Uses GETUTCDATE() for the rolling window - consistent with PaymentDate being stored in UTC |
| WHILE loop parsing | Performance | Comma-split via WHILE loop; acceptable for short lists (few statuses) but less efficient than STRING_SPLIT or TVP for long lists |
| Exchange rate point-in-time | Business rule | Uses ExchangeRate from Billing.Deposit (rate at deposit time), not a live rate - ensures historical consistency |
| NULL result on no match | Behavior | SUM of empty set returns NULL, not 0; callers must handle ISNULL(@result, 0) |
| No NOLOCK | Concurrency | No WITH (NOLOCK) hint - reads committed data; may block briefly on active Deposit inserts |

---

## 8. Sample Queries

### 8.1 Check credit card deposit velocity for a customer (last 5 hours)

```sql
-- Sum of approved credit card deposits in last 5 hours
EXEC [Billing].[GetSumOfDepositPerTimeAndCID]
    @CID = 12345,
    @NumberOfHours = 5,
    @FundingType = 1,     -- 1 = Credit Card
    @PaymentStatusIDs = '2,'  -- 2 = Approved
-- Returns: single scalar (USD-equivalent sum), or NULL if none
```

### 8.2 Check across multiple payment statuses

```sql
-- Sum of approved + pending deposits in last 24 hours
EXEC [Billing].[GetSumOfDepositPerTimeAndCID]
    @CID = 12345,
    @NumberOfHours = 24,
    @FundingType = 1,
    @PaymentStatusIDs = '2,3,'  -- 2=Approved, 3=Pending
```

### 8.3 Equivalent direct query

```sql
SELECT SUM(d.Amount * d.ExchangeRate) AS TotalUSD
FROM [Billing].[Deposit] d WITH (NOLOCK)
INNER JOIN [Billing].[Funding] f WITH (NOLOCK) ON d.FundingID = f.FundingID
WHERE d.CID = 12345
  AND d.PaymentDate >= DATEADD(HOUR, -5, GETUTCDATE())
  AND d.PaymentStatusID IN (2)
  AND f.FundingTypeID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetSumOfDepositPerTimeAndCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetSumOfDepositPerTimeAndCID.sql*
