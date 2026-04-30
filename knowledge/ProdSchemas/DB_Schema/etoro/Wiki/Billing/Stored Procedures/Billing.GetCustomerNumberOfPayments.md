# Billing.GetCustomerNumberOfPayments

> Returns the total count of ALL records in Billing.Payment for a customer (no status filter) - counting pre-2011 historical payment records regardless of migration status. Always returns 0 for customers who registered after 2011.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (scalar COUNT output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerNumberOfPayments` counts all rows in `Billing.Payment` for a given customer. `Billing.Payment` is eToro's pre-2011 deposit archive (frozen since January 2011, 388,522 rows, all with PaymentStatusID=27/MigratedToDepositTable).

Practical interpretation:
- **Customer registered pre-2011**: Returns the count of that customer's historical payment records from the pre-migration era. A count of 3 means the customer made 3 deposits before 2011 (now also in Billing.Deposit with OldPaymentID set).
- **Customer registered post-2011**: Always returns 0 (no data in Payment table for post-2011 customers).

The count includes ALL Payment records regardless of status (no PaymentStatusID filter), so it counts migrated records as-is. Unlike `GetCustomerLastPayment` (which hardcodes status=2 and returns empty), this SP legitimately returns non-zero for pre-2011 customers.

Used by BILLING_MANAGER back-office tools, likely to quickly check whether a customer has pre-migration deposit history before querying the archive for details.

---

## 2. Business Logic

### 2.1 Scalar Count via Variable Assignment

**What**: Counts all Billing.Payment records for a CID and returns the count as a scalar SELECT.

**Columns/Parameters Involved**: `@CID`, `@NumberOfPayments`, `COUNT(*)`

**Rules**:
- `SET @NumberOfPayments = 0`: Initializes to 0 before counting (guards against NULL if COUNT fails).
- `SELECT @NumberOfPayments = COUNT(*) FROM Billing.Payment WITH (NOLOCK) WHERE CID = @CID`: Assigns the count to a local variable via SELECT assignment.
- `SELECT @NumberOfPayments`: Returns a single-column, single-row result set containing the count value. The column has no alias (results in a generated column name like "").
- No status filter - counts ALL records for the CID in Billing.Payment.
- NOLOCK: Dirty reads accepted (table is frozen - no concurrent writes possible, so NOLOCK has no practical effect).

**Pattern analysis**: The variable-assignment approach (`SELECT @var = COUNT(*)`) followed by `SELECT @var` is equivalent to `SELECT COUNT(*) FROM Billing.Payment WHERE CID = @CID`. The indirection through a variable with initialization to 0 is a defensive pattern used when you want to guarantee a non-NULL result from the outer SELECT.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters Billing.Payment.CID. |

**Returns**: Single-column, single-row scalar result:

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | (unnamed) | INTEGER | NO | CODE-BACKED | Count of ALL Billing.Payment records for this CID. 0 for post-2011 customers (no records in Payment table). Non-zero for pre-2011 customers whose deposits are archived here. No status filter - counts migrated (status=27) records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Billing.Payment | Direct read (COUNT) | Source of pre-2011 payment records - counts all rows for the CID regardless of status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | EXECUTE grant | Permission | Back-office billing management tool checks pre-2011 payment count |
| PROD_BIadmins | VIEW DEFINITION grant | Permission | BI admins can inspect the procedure definition |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerNumberOfPayments (procedure)
└── Billing.Payment (table - frozen archive, all records migrated 2010-2011)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | COUNT(*) WHERE CID = @CID - all records (no status filter) |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| Unnamed output column | SELECT @NumberOfPayments returns a column with no alias. Calling code must reference the result by position (column 0), not by name. |
| Always 0 for post-2011 | Billing.Payment has no records after 2011-01-16; all post-2011 customers will always see count=0. |
| No status filter | Unlike GetCustomerLastPayment (status=2), this counts ALL statuses - returns the true record count for pre-2011 customers. |

---

## 8. Sample Queries

### 8.1 Count pre-migration payments for a customer

```sql
-- Returns 0 for post-2011 customers; non-zero for pre-2011 customers
EXEC [Billing].[GetCustomerNumberOfPayments] @CID = 1234567
```

### 8.2 Direct equivalent query

```sql
-- Direct query equivalent to the SP (with named column):
SELECT COUNT(*) AS PaymentCount
FROM [Billing].[Payment] WITH (NOLOCK)
WHERE CID = 1234567
```

### 8.3 Check if any pre-2011 customers exist at all

```sql
-- Find customers with pre-2011 payment history:
SELECT CID, COUNT(*) AS PaymentCount
FROM [Billing].[Payment] WITH (NOLOCK)
GROUP BY CID
HAVING COUNT(*) > 0
ORDER BY PaymentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerNumberOfPayments | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerNumberOfPayments.sql*
