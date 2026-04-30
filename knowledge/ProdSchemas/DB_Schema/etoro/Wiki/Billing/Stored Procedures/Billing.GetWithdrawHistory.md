# Billing.GetWithdrawHistory

> Paginated withdrawal history for a customer in a date range: returns withdrawal records with approval count, XML-encoded funding details (WithdrawToFunding), cashout fee from History.Credit, and server-side pagination via @From/@To position range; outputs total count via @NumberOfPayments OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @DateFrom + @DateTo + @From/@To (page window); OUTPUT @NumberOfPayments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetWithdrawHistory is a legacy paginated withdrawal history procedure used to display withdrawal records in a customer-facing account history view. It supports server-side pagination, returns total count via an OUTPUT parameter, and enriches each withdrawal record with:
- **Approval action count** (`DeclarationInWithdarwApproval` - typo for "WithdrawApproval"): number of approval workflow events
- **Effective date**: the latest approved withdrawal action date (not the original request date, if approved)
- **Funding detail XML** (`WithdrawDetail`): XML blob of all associated WithdrawToFunding records (funding method, amount, exchange rate)
- **Cashout fee** (`CashoutFee`): the fee charged, sourced from History.Credit (CreditTypeID=15)
- **Amounts in cents**: Amount and CashoutFee are multiplied by 100 and cast to INTEGER (cents/minor currency units)

The procedure uses a server-side pagination pattern with an `IDENTITY(0,1)` position column in a table variable, allowing the caller to request window `[@From, @To]` from a zero-based position sequence.

---

## 2. Business Logic

### 2.1 Server-Side Pagination Pattern

**What**: Uses a table variable with IDENTITY(0,1) to assign 0-based position numbers, then pages by position range.

**Columns/Parameters Involved**: `@From`, `@To`, `@NumberOfPayments`, `@Results.Position`

**Rules**:
- `@Results.Position INTEGER IDENTITY(0,1)` - auto-assigned 0-based sequence as rows are inserted
- Insertion order is: ORDER of the SELECT query from Billing.Withdraw (by RequestDate BETWEEN range - no explicit ORDER BY in INSERT, so order is SQL engine dependent)
- `SELECT @NumberOfPayments = COUNT(*) FROM @Results` - total matching rows (before pagination)
- `SELECT * FROM @Results WHERE Position BETWEEN @From AND @To ORDER BY Position` - page window

### 2.2 Effective Date Substitution

**What**: RequestDate is overridden with the latest approval date (if the withdrawal was approved).

**Columns/Parameters Involved**: `BackOffice.WithdrawApproval.Occurred`, `Billing.Withdraw.RequestDate`

**Rules**:
- `COALESCE((SELECT MAX(Occurred) FROM BackOffice.WithdrawApproval WHERE WithdrawID = BWDR.WithdrawID AND Approved = 1), BWDR.RequestDate)`
- If an approved action exists: returns the latest approved action date (settlement/approval date)
- If no approved action: falls back to the original request date
- This means the `RequestDate` column in the result is actually the "effective date" (approval date if approved)

### 2.3 WithdrawDetail XML Generation

**What**: Correlated subquery generates XML of all associated WithdrawToFunding funding details per withdrawal.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding`, `Billing.Funding`, `WithdrawDetail XML`

**Rules**:
- `FOR XML RAW('WithdrawDetail'), BINARY BASE64, ELEMENTS, TYPE, ROOT('WithdrawDetailList')`
- Subquery selects FundingID, FundingTypeID, ProcessCurrencyID, ExchangeRate, Amount (x100), WithdrawData, ID
- One XML document per withdrawal row, wrapped in `<WithdrawDetailList>`
- Joins WithdrawToFunding to Funding via FundingID
- Amount in XML also multiplied by 100 (cents)

### 2.4 Cashout Fee from History.Credit

**What**: Retrieves the cashout fee charged for the withdrawal from the credit history.

**Columns/Parameters Involved**: `History.Credit.CreditTypeID`, `History.Credit.Payment`, `History.Credit.CreditID`

**Rules**:
- Subquery: `SELECT WithdrawID, MAX(CreditID) AS MaxCreditID FROM History.Credit WHERE CreditTypeID = 15 GROUP BY WithdrawID`
- `CreditTypeID=15` = Cashout fee credit type
- `MAX(CreditID)` = latest fee record (in case multiple fee entries exist)
- `ISNULL(ABS(HICR.Payment), 0) * 100` - fee amount in cents; ABS because fee may be stored as negative credit

### 2.5 Amount in Cents

**What**: All monetary amounts are returned multiplied by 100 (minor currency units / cents).

**Rules**:
- `CAST(BWDR.Amount * 100 AS INTEGER)` - main withdrawal amount
- `CAST(BW2F.Amount * 100 AS INTEGER)` - funding detail amounts in XML
- `ISNULL(ABS(HICR.Payment), 0) * 100` - cashout fee
- Legacy pattern; callers divide by 100 to get the decimal amount

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters Billing.Withdraw to this customer. |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of date range (inclusive via BETWEEN). Applied to Billing.Withdraw.RequestDate. |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of date range (inclusive via BETWEEN). Applied to Billing.Withdraw.RequestDate. |
| 4 | @From | INTEGER | NO | - | CODE-BACKED | Start position of the page window (0-based, inclusive). |
| 5 | @To | INTEGER | NO | - | CODE-BACKED | End position of the page window (0-based, inclusive). |
| 6 | @NumberOfPayments | INTEGER | NO | - (OUTPUT) | CODE-BACKED | OUTPUT parameter: total count of matching withdrawals before pagination. Caller uses to determine total pages. |
| - | Position | INTEGER | NO | - | CODE-BACKED | 0-based sequence number assigned during result assembly. Used for pagination (not returned conceptually but exposed via SELECT *). |
| - | WithdrawID | INTEGER | NO | - | CODE-BACKED | Primary key of the withdrawal. |
| - | FundingTypeID | INTEGER | YES | - | CODE-BACKED | Payment method type for the withdrawal. |
| - | Approved | BIT | YES | - | CODE-BACKED | Whether the withdrawal has been approved. |
| - | DeclarationInWithdarwApproval | INTEGER | NO | - | CODE-BACKED | Count of all approval actions in BackOffice.WithdrawApproval for this withdrawal. Column name has typo ("Withdarw" instead of "Withdraw"). |
| - | ManagerID | INTEGER | YES | - | CODE-BACKED | ID of the manager who last acted on this withdrawal. |
| - | CashoutStatusID | INTEGER | YES | - | CODE-BACKED | Current cashout processing status. |
| - | CurrencyID | INTEGER | YES | - | CODE-BACKED | Currency of the withdrawal. |
| - | CID | INTEGER | NO | - | CODE-BACKED | Customer ID (echoed from the withdrawal record). |
| - | RequestDate | DATETIME | YES | - | CODE-BACKED | Effective date: MAX(WithdrawApproval.Occurred WHERE Approved=1), falling back to Billing.Withdraw.RequestDate. Despite the name, this is the approval date when approved. |
| - | Amount | INTEGER | YES | - | CODE-BACKED | Withdrawal amount in minor currency units (cents). CAST(Amount * 100 AS INTEGER). |
| - | WithdrawDetail | XML | YES | - | CODE-BACKED | XML document containing all WithdrawToFunding records for this withdrawal. Root element: WithdrawDetailList. Each child: WithdrawDetail with FundingID, FundingTypeID, ProcessCurrencyID, ExchangeRate, Amount (cents), WithdrawData, ID. |
| - | IPAddress | NUMERIC | YES | - | CODE-BACKED | IP address of the customer when the withdrawal was created. Stored as numeric. |
| - | Remark | VARCHAR(500) | YES | - | CODE-BACKED | Customer comment/note on the withdrawal. |
| - | CashoutFee | MONEY | NO | 0 | CODE-BACKED | Cashout fee in minor currency units (cents). From History.Credit CreditTypeID=15 (latest entry). ISNULL to 0 if no fee record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, all columns | Billing.Withdraw | SELECT | Primary source of withdrawal data |
| WithdrawID | BackOffice.WithdrawApproval | Correlated subquery (count) + COALESCE subquery (max date) | Approval count and effective date override |
| WithdrawID | Billing.WithdrawToFunding | Correlated subquery (FOR XML) | Funding detail XML per withdrawal |
| FundingID | Billing.Funding | JOIN within XML subquery | FundingTypeID for each WithdrawToFunding record |
| WithdrawID, CreditTypeID=15 | History.Credit | LEFT JOIN (subquery for MAX CreditID) | Cashout fee amount |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Withdrawal history UI / PaymentHistoryAPI | @CID, @DateFrom, @DateTo, @From, @To | EXEC | Paginated withdrawal history for customer account dashboard |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetWithdrawHistory (procedure)
+-- Billing.Withdraw (table) [withdrawal records]
+-- BackOffice.WithdrawApproval (table) [approval count + effective date]
+-- Billing.WithdrawToFunding (table) [funding details XML]
+-- Billing.Funding (table) [FundingTypeID in XML]
+-- History.Credit (table) [CreditTypeID=15 cashout fee]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary source; filtered by CID + RequestDate range |
| BackOffice.WithdrawApproval | Table | Count of approval actions; MAX approved date for effective date |
| Billing.WithdrawToFunding | Table | Correlated XML subquery for funding details |
| Billing.Funding | Table | JOIN in XML subquery for FundingTypeID |
| History.Credit | Table | LEFT JOIN for cashout fee (CreditTypeID=15, MAX CreditID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Withdrawal history service / PaymentHistoryAPI | External | Paginated withdrawal display with funding details and fees |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IDENTITY(0,1) pagination | Design | Zero-based position; @From=0, @To=9 returns first 10 records |
| Amount in cents | Compatibility | Amounts multiplied by 100 and cast to INTEGER; callers must divide by 100 |
| RequestDate override | Naming mislead | RequestDate column shows approval date when approved, original request date otherwise |
| DeclarationInWithdarwApproval typo | Naming | Column name has "Withdarw" instead of "Withdraw" - cannot be renamed without changing callers |
| Correlated subqueries | Performance | Two correlated subqueries (approval count + approval date) execute per row; may be slow for large result sets |
| NOLOCK throughout | Concurrency | All base table reads use WITH (NOLOCK) |
| BETWEEN on RequestDate | Design | Both @DateFrom and @DateTo are inclusive; time precision matters |

---

## 8. Sample Queries

### 8.1 Get first page of withdrawals (10 per page)

```sql
DECLARE @total INT
EXEC [Billing].[GetWithdrawHistory]
    @CID = 12345,
    @DateFrom = '2026-01-01',
    @DateTo = '2026-12-31',
    @From = 0,
    @To = 9,
    @NumberOfPayments = @total OUTPUT
SELECT @total AS TotalWithdrawals
-- Returns: positions 0-9 (first 10), @total = total matching count
```

### 8.2 Get subsequent pages

```sql
DECLARE @total INT
-- Page 2 (positions 10-19)
EXEC [Billing].[GetWithdrawHistory]
    @CID = 12345,
    @DateFrom = '2026-01-01',
    @DateTo = '2026-12-31',
    @From = 10,
    @To = 19,
    @NumberOfPayments = @total OUTPUT
```

---

## 9. Atlassian Knowledge Sources

**Confluence**: "MIMOPSB-929- Approval dependencies on etoro db" (/spaces/MG) - withdrawal approval workflow dependencies including BackOffice.WithdrawApproval usage patterns relevant to this procedure.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 1 Confluence (MIMOPSB-929) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetWithdrawHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetWithdrawHistory.sql*
