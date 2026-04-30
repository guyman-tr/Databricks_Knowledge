# Billing.GetPaymentsBy

> Flexible payment search procedure using dynamic SQL to filter Billing.Payment by any combination of status, type, funding type, date, and amount range - returns a paginated result set identified by row position.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated rows from Billing.Payment matching the supplied filter combination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPaymentsBy` is an older multi-criteria payment search procedure that uses dynamic SQL to build a flexible WHERE clause. The caller can pass -1 for any integer filter (or NULL for @DateFrom) to skip that condition, allowing open-ended searches over `Billing.Payment` by status, type, funding method, date range, and amount comparison.

The procedure exists to support billing manager and BI analyst queries where the search criteria are not known in advance - for example, "find all credit card payments above $500 in the last week" or "find all declined PayPal payments". The dynamic SQL approach allows any combination of filters without combinatorial CASE branching.

Data flows as follows: the caller provides filter values (-1 meaning "no filter" for integer parameters). The procedure builds a dynamic INSERT...SELECT into a temp table #TMP, populates it via `sp_executesql`, then returns a positional slice using `Position BETWEEN @From AND @To`. Note that `@DateFrom IS NOT NULL` check for the dynamic SQL and `@SQL = @SQL + ' AND PaymentDate >= @DateFrom'` are both appended unconditionally at the end - this creates a bug where `PaymentDate >= @DateFrom` is always added to the query even when @DateFrom is already included via the conditional block.

---

## 2. Business Logic

### 2.1 Dynamic Filter Construction (-1 as No-Filter Sentinel)

**What**: Integer parameters use -1 as the "skip this filter" sentinel. The procedure only appends each condition if the parameter is not -1 (or not NULL for datetime).

**Columns/Parameters Involved**: `@PaymentStatus`, `@PaymentType`, `@FundingType`, `@Amount`, `@AmountSign`, `@DateFrom`

**Rules**:
- `@PaymentStatus != -1` -> adds `AND PaymentStatusID = @PaymentStatus`
- `@DateFrom IS NOT NULL` -> adds `AND PaymentDate >= @DateFrom`
- `@PaymentType != -1` -> adds `AND PaymentTypeID = @PaymentType`
- `@FundingType != -1` -> adds `AND FundingTypeID = @FundingType`
- `@AmountSign != '-1'` -> adds `AND Amount {sign} @Amount` (sign can be `=`, `<=`, `>=`)
- Date filter is ALWAYS appended a second time at the end (code defect - duplicate condition, benign but inefficient)
- Base query is always `SELECT * FROM Billing.Payment WHERE 1=1`

### 2.2 Positional Pagination via Temp Table

**What**: Results are staged in a temp table with an IDENTITY(0,1) Position column, then sliced with `WHERE Position BETWEEN @From AND @To`.

**Rules**:
- Position starts at 0 (IDENTITY(0,1)), so first row is position 0
- `@From` and `@To` define the 0-based position range (inclusive on both ends)
- Caller computes page boundaries externally (e.g., page 1 = 0 to 99 for page size 100)
- This is an older pagination pattern; newer procedures use OFFSET/FETCH

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Amount | INTEGER | NO | - | CODE-BACKED | Amount threshold for the amount comparison filter. Used with @AmountSign. Pass any value if @AmountSign = '-1' (filter skipped). |
| 2 | @AmountSign | VARCHAR(2) | NO | '-1' | CODE-BACKED | Comparison operator for amount filter: `=`, `<=`, or `>=`. Pass `-1` (default) to skip the amount filter entirely. The value is concatenated directly into the SQL string - not a parameterized input. |
| 3 | @PaymentStatus | INTEGER | NO | - | CODE-BACKED | PaymentStatusID filter. Pass -1 to skip. FK to Dictionary.PaymentStatus (2=Approved, 3=Declined, etc.). |
| 4 | @PaymentType | INTEGER | NO | - | CODE-BACKED | PaymentTypeID filter. Pass -1 to skip. FK to Dictionary.PaymentType (deposit vs withdrawal direction). |
| 5 | @FundingType | INTEGER | NO | - | CODE-BACKED | FundingTypeID filter. Pass -1 to skip. FK to Dictionary.FundingType (1=CreditCard, 2=Wire, etc.). |
| 6 | @DateFrom | DATETIME | YES | - | CODE-BACKED | Minimum PaymentDate threshold. Pass NULL to skip (though the final unconditional append makes this partially ineffective - a known code defect). When non-NULL, filters `PaymentDate >= @DateFrom`. |
| 7 | @From | INTEGER | NO | - | CODE-BACKED | Start of the positional range (0-based) for pagination. Corresponds to IDENTITY(0,1) position in the temp table. |
| 8 | @To | INTEGER | NO | - | CODE-BACKED | End of the positional range (inclusive) for pagination. |

**Return columns (all columns from Billing.Payment plus Position):**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 9 | Position | IDENTITY(0,1) | CODE-BACKED | 0-based row position within the full result set. Used for pagination. Not from Billing.Payment. |
| 10 | PaymentID | Billing.Payment.PaymentID | CODE-BACKED | PK of the payment record. |
| 11 | CurrencyID | Billing.Payment.CurrencyID | CODE-BACKED | Payment currency. FK to Dictionary.Currency. |
| 12 | CID | Billing.Payment.CID | CODE-BACKED | Customer identifier. |
| 13 | PaymentStatusID | Billing.Payment.PaymentStatusID | CODE-BACKED | Payment status. FK to Dictionary.PaymentStatus. |
| 14 | PaymentTypeID | Billing.Payment.PaymentTypeID | CODE-BACKED | Payment type (deposit/withdrawal). FK to Dictionary.PaymentType. |
| 15 | FundingTypeID | Billing.Payment.FundingTypeID | CODE-BACKED | Payment method type. FK to Dictionary.FundingType. |
| 16 | TerminalID | Billing.Payment.TerminalID | CODE-BACKED | Processing terminal/MID. FK to Billing.Terminal. |
| 17 | Amount | Billing.Payment.Amount | CODE-BACKED | Payment amount. |
| 18 | PaymentDate | Billing.Payment.PaymentDate | CODE-BACKED | Payment submission timestamp. |
| 19 | TransactionId | Billing.Payment.TransactionId | CODE-BACKED | External provider transaction reference (CHAR 6). |
| 20 | IPAddress | Billing.Payment.IPAddress | CODE-BACKED | Customer IP at payment submission. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source) | Billing.Payment | SELECT | All matching payment records read from this table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | GRANT EXECUTE | Permission | Billing management role - ad-hoc payment searches |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role - reporting queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPaymentsBy (procedure)
└── Billing.Payment (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | Source of all returned data; dynamically filtered via sp_executesql |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILLING_MANAGER | DB Security Principal | EXECUTE permission |
| PROD_BIadmins | DB Security Principal | EXECUTE permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: @AmountSign is concatenated directly into the SQL string (not parameterized). Callers must ensure only valid operators (`=`, `<=`, `>=`) are passed. The `PaymentDate >= @DateFrom` condition is appended both conditionally (if @DateFrom IS NOT NULL) and unconditionally at the end - a legacy code defect resulting in a duplicate predicate when @DateFrom is provided, and an always-true predicate when it is NULL. The procedure uses `sp_executesql` with named parameters for all other inputs, which is safe.

---

## 8. Sample Queries

### 8.1 Find all approved credit card payments from a date onwards
```sql
-- PaymentStatus=2 (Approved), PaymentType=-1 (any), FundingType=1 (CC), DateFrom=last month
-- @AmountSign='-1' skips amount filter; @From=0, @To=99 returns first 100 rows
EXEC [Billing].[GetPaymentsBy]
    @Amount = 0,
    @AmountSign = '-1',
    @PaymentStatus = 2,
    @PaymentType = -1,
    @FundingType = 1,
    @DateFrom = '2026-03-01',
    @From = 0,
    @To = 99
```

### 8.2 Find all payments over $1000 regardless of status, type, or date
```sql
EXEC [Billing].[GetPaymentsBy]
    @Amount = 1000,
    @AmountSign = '>=',
    @PaymentStatus = -1,
    @PaymentType = -1,
    @FundingType = -1,
    @DateFrom = NULL,
    @From = 0,
    @To = 499
```

### 8.3 Equivalent direct query for a specific status + funding type
```sql
SELECT
    PaymentID, CID, Amount, PaymentDate, PaymentStatusID, FundingTypeID
FROM Billing.Payment WITH (NOLOCK)
WHERE PaymentStatusID = 2
  AND FundingTypeID = 1
  AND PaymentDate >= '2026-03-01'
ORDER BY PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPaymentsBy | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPaymentsBy.sql*
