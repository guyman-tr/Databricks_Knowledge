# Billing.GetCustomerLastPayment

> Legacy procedure that queries the pre-2011 Billing.Payment archive for the most recent approved payment by FundingType and PaymentType - currently always returns zero rows because all Payment records were migrated to Billing.Deposit with PaymentStatusID=27, making the PaymentStatusID=2 filter unmatchable.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingTypeID + @PaymentTypeID (PaymentStatusID=2 hardcoded - unmatchable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerLastPayment` was designed to retrieve the most recent approved payment from `Billing.Payment` (eToro's pre-2011 deposit ledger). It is the Payment-table equivalent of `GetCustomerLastDeposit` (which queries the modern `Billing.Deposit` table).

**Important**: This procedure currently returns zero rows for ALL customers. The `Billing.Payment` table contains 388,522 records all with `PaymentStatusID=27` (MigratedToDepositTable). The SP filters `PaymentStatusID = 2` (Approved), which matches no records in the table. The data was migrated to `Billing.Deposit` during the 2010-2011 payment system consolidation, after which `Payment` became a frozen historical archive.

The procedure was likely used pre-migration when Payment records still held active statuses. After migration, it became a dead code path. It is retained in the codebase and BILLING_MANAGER still has EXECUTE access - suggesting some back-office tooling may still call it for completeness, even though it always returns an empty result set.

For current deposit history, use `GetCustomerLastDeposit` (from Billing.Deposit). For the full pre-2011 history, query `Billing.Payment` directly without the PaymentStatusID=2 filter.

---

## 2. Business Logic

### 2.1 Approved-Only Payment Lookup (Dead Code Path)

**What**: Returns TOP 1 approved payment from Billing.Payment with optional FundingType and PaymentType filters.

**Columns/Parameters Involved**: `@CID`, `@FundingTypeID`, `@PaymentTypeID`, hardcoded `PaymentStatusID = 2`

**Rules**:
- `WHERE CID = @CID AND PaymentStatusID = 2`: The status=2 (Approved) filter matches ZERO records in Billing.Payment, because all 388,522 records have PaymentStatusID=27 (MigratedToDepositTable). Result is always empty.
- `(PaymentTypeID = @PaymentTypeID OR @PaymentTypeID = 0)`: When @PaymentTypeID=0, no PaymentType filter applied (wildcard). All Payment records have PaymentTypeID=1 (Deposit).
- `(FundingTypeID = @FundingTypeID OR @FundingTypeID = 0)`: When @FundingTypeID=0, no FundingType filter applied (wildcard).
- `TOP 1 ... ORDER BY PaymentDate DESC`: Returns most recent matching record - but since result is always empty, TOP 1 is never reached.
- `NOLOCK` hint consistent with other read SPs.

**Effective behavior**: This SP is semantically equivalent to `SELECT TOP 1 * FROM Billing.Payment WHERE 1=0` - it never returns any rows.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters Billing.Payment.CID. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method type filter (1=CreditCard, 2=Wire, 3=PayPal, etc.). When @FundingTypeID=0, no filter applied. Filters Billing.Payment.FundingTypeID. |
| 3 | @PaymentTypeID | INTEGER | NO | - | CODE-BACKED | Payment type filter. All Payment records have PaymentTypeID=1 (Deposit). When @PaymentTypeID=0, no filter applied. |

**Returns**: All columns from Billing.Payment (SELECT * expansion); always 0 rows due to PaymentStatusID=2 filter matching no records.

Key Billing.Payment columns (reference only - never returned):

| # | Element | Type | Notes |
|---|---------|------|-------|
| PaymentID | INTEGER | PK, IDENTITY(1,1) - pre-2011 deposit ID |
| CID | INTEGER | Customer ID |
| Amount | INT | Amount in integer cents (not MONEY) |
| CurrencyID | INT | Currency of the deposit |
| FundingTypeID | INT | 1=CC (63%), 3=PayPal (28%), 2=Wire (5%) |
| PaymentTypeID | INT | Always 1=Deposit for all 388K records |
| PaymentStatusID | INT | Always 27=MigratedToDepositTable |
| PaymentDate | DATETIME | Original deposit date (2007-2011) |
| TerminalID | INT | Pre-2011 routing configuration |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentStatusID, FundingTypeID, PaymentTypeID | Billing.Payment | Direct read (SELECT TOP 1) | Source of pre-2011 deposit records - filter matches no records (all are status=27) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | EXECUTE grant | Permission | Back-office billing management tool; may still call this SP although it always returns empty results |
| PROD_BIadmins | VIEW DEFINITION grant | Permission | BI admins can inspect the procedure definition |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerLastPayment (procedure)
└── Billing.Payment (table - frozen archive, all records migrated 2010-2011)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | SELECT TOP 1 WHERE CID + PaymentStatusID=2 - matches zero rows (all records are status=27) |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| Always empty result | PaymentStatusID=2 filter matches zero records in Billing.Payment (all are 27/Migrated). This is a permanently inactive code path. |
| Zero-value wildcards | @FundingTypeID=0 and @PaymentTypeID=0 act as "no filter" wildcards via OR conditions. |
| Comment typo | `-- Approves` in the DDL is a misspelling of "Approved", mirroring the same typo in GetCustomerLastDeposit. |

---

## 8. Sample Queries

### 8.1 Confirm this always returns empty (verify dead code)

```sql
-- Expected: 0 rows for any CID and FundingTypeID
EXEC [Billing].[GetCustomerLastPayment]
    @CID = 1234567,
    @FundingTypeID = 1,
    @PaymentTypeID = 1

-- Direct verification - why it returns empty:
SELECT COUNT(*) AS RecordCount,
    MIN(PaymentStatusID) AS MinStatus,
    MAX(PaymentStatusID) AS MaxStatus
FROM [Billing].[Payment] WITH (NOLOCK)
WHERE CID = 1234567
-- Expected: all records have StatusID=27; none have StatusID=2
```

### 8.2 Modern equivalent (use Billing.Deposit instead)

```sql
-- For current deposit history, use GetCustomerLastDeposit:
EXEC [Billing].[GetCustomerLastDeposit]
    @CID = 1234567,
    @FundingTypeID = 1
-- Returns last approved Billing.Deposit record (the migrated and current table)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerLastPayment | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerLastPayment.sql*
