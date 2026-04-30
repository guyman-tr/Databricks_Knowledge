# Billing.REPORT_IdealDeposits2

> Reporting procedure for iDEAL deposits (FundingTypeID=34) - functionally identical to Billing.REPORT_IdealDeposits in the current codebase; originally intended as a v2 variant.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set ordered by PaymentDate DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.REPORT_IdealDeposits2` was originally created as a v2 of `Billing.REPORT_IdealDeposits` - according to the batch plan, the original differentiation was removal of a per-day cap filter. However, in the current codebase, both procedures contain **identical SQL logic**. The procedures converged to the same implementation over time (v1 was likely updated to match v2, or both were modified identically).

Both procedures return iDEAL deposit records (FundingTypeID=34) for a date range with customer details, bank XML data, KYC status, and client type. See `Billing.REPORT_IdealDeposits` for full documentation of the shared logic.

---

## 2. Business Logic

### 2.1 Identical to REPORT_IdealDeposits

**What**: Same 4 business rules as REPORT_IdealDeposits.

**Rules**:
- FundingTypeID = 34 (iDEAL only).
- XML extraction of BankName, AccountHolderName, BIC, IBAN from Billing.Deposit.PaymentData.
- DISTINCT to prevent duplicates from OUTER APPLY session join.
- OUTER APPLY on STS_AuditLoginHistoryActive for ClientType.

See `Billing.REPORT_IdealDeposits` Section 2 for full business logic detail.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATE | YES | NULL (= today UTC) | CODE-BACKED | Start date for PaymentDate filter (inclusive). Same default logic as v1. |
| 2 | @EndDate | DATE | YES | NULL (= yesterday UTC) | CODE-BACKED | End date for PaymentDate filter (exclusive). Same default logic as v1. |

**Output Columns**: Identical to Billing.REPORT_IdealDeposits (23 columns: DepositID, PaymentDate, CID, UserName, FundingType, Status, Amount, Currency, Depot, RiskManagementStatus, CustomerCountry, Regulation, VerificationLevelID, FirstName, MiddleName, LastName, BankName, AccountHolderName, BIC, IBAN, ClientType). See `Billing.REPORT_IdealDeposits` Section 4 for full descriptions.

---

## 5. Relationships

### 5.1 References To (this object points to)

Identical to `Billing.REPORT_IdealDeposits`. See that document for full relationship list.

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit data | Billing.Deposit | READ | Source of iDEAL deposits |
| Customer data | Customer.CustomerStatic | READ | Username, names |
| Funding data | Billing.Funding | READ | FundingTypeID=34 filter |
| Lookups | Dictionary.*, BackOffice.Customer | READ | Decode IDs to names |

### 5.2 Referenced By (other objects point to this)

No SQL callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.REPORT_IdealDeposits2 (procedure)
├── Billing.Deposit (table)
├── Customer.CustomerStatic (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── BackOffice.Customer (table)
├── STS_AuditLoginHistoryActive (table)
├── Dictionary.FundingType (table)
├── Dictionary.PaymentStatus (table)
├── Dictionary.Currency (table)
├── Dictionary.RiskManagementStatus (table)
├── Dictionary.Country (table)
└── Dictionary.Regulation (table)
```

### 6.1 Objects This Depends On

Same as Billing.REPORT_IdealDeposits. See that document.

### 6.2 Objects That Depend On This

No SQL dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Same as Billing.REPORT_IdealDeposits: FundingTypeID=34 filter, DISTINCT deduplication.

---

## 8. Sample Queries

### 8.1 Get iDEAL deposits (same usage as v1)

```sql
EXEC Billing.REPORT_IdealDeposits2
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-02'
```

### 8.2 Compare v1 and v2 output (should be identical in current codebase)

```sql
-- Both should return identical results
EXEC Billing.REPORT_IdealDeposits  @StartDate = '2026-03-01', @EndDate = '2026-03-02'
EXEC Billing.REPORT_IdealDeposits2 @StartDate = '2026-03-01', @EndDate = '2026-03-02'
```

### 8.3 Find iDEAL deposits with IBAN filtering

```sql
SELECT d.DepositID, d.CID, d.Amount, d.PaymentDate,
       d.PaymentData.value('(/Deposit/IbanCodeAsString)[1]', 'varchar(70)') AS IBAN
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = d.FundingID
WHERE f.FundingTypeID = 34
AND d.PaymentDate >= '2026-03-01' AND d.PaymentDate < '2026-03-02'
ORDER BY d.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 6/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related analyzed (REPORT_IdealDeposits v1) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.REPORT_IdealDeposits2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.REPORT_IdealDeposits2.sql*
