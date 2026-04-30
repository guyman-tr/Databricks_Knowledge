# Billing.REPORT_IdealDeposits

> Reporting procedure that returns iDEAL deposit records (FundingTypeID=34) for a date range, with customer details, bank data from XML, and client type from session history.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set ordered by PaymentDate DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

iDEAL is a Dutch online banking payment method widely used in the Netherlands for deposits. `Billing.REPORT_IdealDeposits` is a reporting query for the Finance or Compliance team to review all iDEAL deposit activity within a date range. It surfaces bank-level data (bank name, account holder name, BIC, IBAN) extracted from the XML `PaymentData` field of `Billing.Deposit`, along with customer KYC status and regulatory context.

The procedure was built by Adi on 10/06/2020 with the `ApplicationIdentifierFrom` column added at management's request (despite the developer's note that the STS_History data is unreliable) to show which client application (web, mobile, etc.) submitted the deposit.

Note: `REPORT_IdealDeposits2` is essentially identical in the current codebase - both procedures have the same SQL logic. The original differentiation (a per-day cap filter) appears to have been removed from v1, resulting in identical procedures.

---

## 2. Business Logic

### 2.1 iDEAL-Specific Deposit Extraction

**What**: Filters deposits to only iDEAL payment method and extracts bank-specific XML data.

**Columns/Parameters Involved**: `FundingTypeID = 34`, `PaymentData` XML fields

**Rules**:
- `f.FundingTypeID = 34` is the core filter: only iDEAL deposits (Dutch bank transfer).
- Bank data extracted from `Billing.Deposit.PaymentData` XML:
  - `/Deposit/BankNameAsString` -> BankName
  - `/Deposit/AccountHolderNameAsString` -> AccountHolderName
  - `/Deposit/BicCodeAsString` -> BIC (SWIFT/BIC code)
  - `/Deposit/IbanCodeAsString` -> IBAN (account number)
- `DISTINCT` on the full row set prevents duplicates from the OUTER APPLY.
- Date filter: `d.PaymentDate >= @StartDate AND d.PaymentDate < @EndDate`.

### 2.2 Client Type from Session History

**What**: Identifies which eToro application (web, mobile, desktop) submitted the deposit.

**Columns/Parameters Involved**: `ClientType`, `SessionID`, `STS_AuditLoginHistoryActive.ApplicationIdentifierFrom`

**Rules**:
- Uses OUTER APPLY TOP 1 from `STS_AuditLoginHistoryActive` matching `SessionIdentifier = d.SessionID AND ApplicationIdentifierFrom IS NOT NULL`.
- If no session match: ClientType is NULL.
- Developer note: the data quality from this source is unreliable per the code comment.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATE | YES | NULL (= today UTC) | CODE-BACKED | Start date for PaymentDate filter (inclusive). NULL defaults to GETUTCDATE(). Note: default logic appears inverted - @StartDate defaults to today and @EndDate to today-1, so the default range may be empty without explicit dates. |
| 2 | @EndDate | DATE | YES | NULL (= yesterday UTC) | CODE-BACKED | End date for PaymentDate filter (exclusive). NULL defaults to GETUTCDATE()-1. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | DepositID | INT | NO | - | CODE-BACKED | Unique identifier of the iDEAL deposit. |
| 4 | PaymentDate | DATETIME | NO | - | CODE-BACKED | Timestamp when the deposit was submitted. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID of the depositor. |
| 6 | UserName | VARCHAR | NO | - | CODE-BACKED | Customer's eToro username from Customer.CustomerStatic. |
| 7 | FundingType | VARCHAR | NO | - | CODE-BACKED | Funding method name from Dictionary.FundingType. Should be 'iDEAL' for all rows (FundingTypeID=34). |
| 8 | Status | VARCHAR | NO | - | CODE-BACKED | Payment status name from Dictionary.PaymentStatus (e.g., 'Pending', 'Approved', 'Declined'). |
| 9 | Amount | MONEY | NO | - | CODE-BACKED | Deposit amount in the transaction currency. |
| 10 | Currency | VARCHAR | NO | - | CODE-BACKED | ISO currency abbreviation from Dictionary.Currency. |
| 11 | Depot | VARCHAR | YES | - | CODE-BACKED | Processing entity from Billing.Depot. NULL when not assigned. |
| 12 | RiskManagementStatus | VARCHAR | YES | - | CODE-BACKED | AML/risk status name from Dictionary.RiskManagementStatus. NULL when not set. |
| 13 | CustomerCountry | VARCHAR | NO | - | CODE-BACKED | Customer's country of residence from Dictionary.Country. |
| 14 | Regulation | VARCHAR | NO | - | CODE-BACKED | Regulatory jurisdiction name from Dictionary.Regulation (e.g., 'ASIC', 'FCA'). |
| 15 | VerificationLevelID | INT | NO | - | CODE-BACKED | KYC verification level from BackOffice.Customer. |
| 16 | FirstName | VARCHAR | YES | - | CODE-BACKED | Customer first name from Customer.CustomerStatic. |
| 17 | MiddleName | VARCHAR | YES | - | CODE-BACKED | Customer middle name from Customer.CustomerStatic. |
| 18 | LastName | VARCHAR | YES | - | CODE-BACKED | Customer last name from Customer.CustomerStatic. |
| 19 | BankName | VARCHAR(70) | YES | - | CODE-BACKED | Extracted from PaymentData XML: the issuing bank name for the iDEAL transaction. |
| 20 | AccountHolderName | VARCHAR(70) | YES | - | CODE-BACKED | Extracted from PaymentData XML: account holder name at the bank. Used for compliance matching. |
| 21 | BIC | VARCHAR(70) | YES | - | CODE-BACKED | Bank Identifier Code (SWIFT BIC) extracted from PaymentData XML. Identifies the specific bank. |
| 22 | IBAN | VARCHAR(70) | YES | - | CODE-BACKED | International Bank Account Number extracted from PaymentData XML. The source bank account. |
| 23 | ClientType | VARCHAR | YES | - | CODE-BACKED | Application platform used to submit the deposit (e.g., web, mobile). From STS_AuditLoginHistoryActive. Data quality may be unreliable (developer note in code). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit data | Billing.Deposit | READ | Source of iDEAL deposits (FundingTypeID=34 filter) |
| Customer data | Customer.CustomerStatic | READ | Username, names, country |
| Funding data | Billing.Funding | READ | FundingTypeID for filter |
| Depot | Billing.Depot | READ | Processing entity |
| Session data | STS_AuditLoginHistoryActive | READ | Client type / application identifier |
| Lookups | Dictionary.FundingType, Dictionary.PaymentStatus, Dictionary.Currency, Dictionary.RiskManagementStatus, Dictionary.Country, Dictionary.Regulation | READ | Decode IDs to names |
| Verification | BackOffice.Customer | READ | VerificationLevelID |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Used directly by Finance/Compliance teams for iDEAL reporting.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.REPORT_IdealDeposits (procedure)
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

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary source; PaymentData XML extraction |
| Customer.CustomerStatic | Table | Customer name and username |
| Billing.Funding | Table | FundingTypeID=34 filter |
| Billing.Depot | Table | Processing entity name |
| BackOffice.Customer | Table | VerificationLevelID |
| STS_AuditLoginHistoryActive | Table | Client application type via SessionIdentifier |
| Dictionary.FundingType | Table | Funding method name |
| Dictionary.PaymentStatus | Table | Payment status name |
| Dictionary.Currency | Table | Currency abbreviation |
| Dictionary.RiskManagementStatus | Table | AML/risk status name |
| Dictionary.Country | Table | Customer country name |
| Dictionary.Regulation | Table | Regulatory jurisdiction |

### 6.2 Objects That Depend On This

No SQL dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingTypeID = 34 | Business filter | Restricts to iDEAL deposits only. |
| DISTINCT | Deduplication | Prevents duplicate rows from OUTER APPLY session join. |

---

## 8. Sample Queries

### 8.1 Get iDEAL deposits for a specific date

```sql
EXEC Billing.REPORT_IdealDeposits
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-02'
```

### 8.2 Get iDEAL deposits for last 7 days

```sql
EXEC Billing.REPORT_IdealDeposits
    @StartDate = CAST(DATEADD(DAY, -7, GETUTCDATE()) AS DATE),
    @EndDate = CAST(GETUTCDATE() AS DATE)
```

### 8.3 Search for a specific bank account in iDEAL deposits

```sql
SELECT d.DepositID, d.CID, d.Amount, d.PaymentDate,
       d.PaymentData.value('(/Deposit/IbanCodeAsString)[1]', 'varchar(70)') AS IBAN,
       d.PaymentData.value('(/Deposit/AccountHolderNameAsString)[1]', 'varchar(70)') AS AccountHolder
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = d.FundingID
WHERE f.FundingTypeID = 34
AND d.PaymentData.value('(/Deposit/IbanCodeAsString)[1]', 'varchar(70)') = 'NL91ABNA0417164300'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.REPORT_IdealDeposits | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.REPORT_IdealDeposits.sql*
