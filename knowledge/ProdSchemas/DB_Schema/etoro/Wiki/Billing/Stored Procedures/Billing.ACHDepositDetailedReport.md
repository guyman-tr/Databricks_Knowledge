# Billing.ACHDepositDetailedReport

> Daily operational report stored procedure that returns detailed ACH deposit records for a date range, including Plaid-sourced bank data (names, balances, item IDs) and payment/risk status labels, used for ACH monitoring and compliance review.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate, @ToDate input; returns result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ACHDepositDetailedReport` produces a detailed operational report of ACH deposits within a specified date range. The report is described in the procedure comment as "sent on a daily basis by job" and is not used by the application directly - it is a scheduled reporting procedure.

ACH (Automated Clearing House) deposits use FundingTypeID=29 and are linked to Plaid (a bank connectivity service) via XML data stored in `Billing.Deposit.PaymentData`. The procedure extracts Plaid-specific data from this XML: customer names as returned by Plaid, Plaid item ID, request ID, and balance information (available, current, calculated) - all used for ACH verification and reconciliation against the bank's reported account state.

The report filters to real, non-demo customers (PlayerLevelID <> 4 excludes demo users) for the specified date range. It enriches each deposit with customer name, risk status, payment status, and risk management status for compliance and fraud monitoring teams reviewing ACH activity.

---

## 2. Business Logic

### 2.1 ACH-Specific Data Extraction via XML Shredding

**What**: The procedure extracts ACH/Plaid-specific data embedded in the XML `PaymentData` column of `Billing.Deposit`.

**Columns/Parameters Involved**: `D.PaymentData`

**Rules**:
- `PaymentData` is an XML column in `Billing.Deposit` with a `/Deposit[1]/` root structure.
- Extracted fields: `PlaidNamesAsString` (customer name(s) as returned by Plaid), `ResponseMessageAsString` (ACH response), `ResponseTimeAsString` (ACH processing time), `AvailableBalanceAsDecimal` (bank account available balance), `CurrentBalanceAsDecimal` (bank account current balance), `AccountBalanceAsDecimal` (calculated balance), `PlaidItemIDAsString` (Plaid's unique bank item identifier), `RequestIDAsString` (ACH request ID).
- Similarly, `Billing.Funding.FundingData` XML contains `BankNameAsString` (the bank name from Plaid).

**Diagram**:
```
Billing.Deposit.PaymentData (XML)
  /Deposit[1]/PlaidNamesAsString[1]   -> NamesFromPlaid
  /Deposit[1]/ResponseMessageAsString[1] -> ResponseMessage
  /Deposit[1]/ResponseTimeAsString[1]    -> ResponseTime
  /Deposit[1]/AvailableBalanceAsDecimal[1] -> AvailableBalance
  /Deposit[1]/CurrentBalanceAsDecimal[1]  -> CurrentBalance
  /Deposit[1]/AccountBalanceAsDecimal[1]  -> CalculatedBalance
  /Deposit[1]/PlaidItemIDAsString[1]      -> PlaidItemID
  /Deposit[1]/RequestIDAsString[1]        -> RequestID

Billing.Funding.FundingData (XML)
  /Funding[1]/BankNameAsString[1]         -> BankName
```

### 2.2 Report Scope and Filters

**What**: The report is scoped to ACH deposits from real (non-demo) customers within the date range.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `F.FundingTypeID`, `C.PlayerLevelID`

**Rules**:
- `F.FundingTypeID = 29`: Restricts to ACH funding type only (bank transfers via Plaid/ACH network).
- `C.PlayerLevelID <> 4`: Excludes player level 4 (demo accounts).
- `D.PaymentDate >= @FromDate AND D.PaymentDate < @ToDate`: Inclusive-start, exclusive-end date range filter.
- Intended to run daily (from comment): @FromDate and @ToDate are typically consecutive days in the daily job.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATE | NO | - | CODE-BACKED | Start date of the reporting period (inclusive). Used as `D.PaymentDate >= @FromDate`. Designed for daily job use - typically set to yesterday's date. |
| 2 | @ToDate | DATE | NO | - | CODE-BACKED | End date of the reporting period (exclusive). Used as `D.PaymentDate < @ToDate`. Typically set to today's date for a daily report. |

**Result Set Columns:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Billing.Deposit.CID | Customer identifier |
| 2 | DepositID | Billing.Deposit.DepositID | Unique deposit record identifier |
| 3 | FirstName | Customer.CustomerStatic.FirstName | Customer first name |
| 4 | LastName | Customer.CustomerStatic.LastName | Customer last name |
| 5 | NamesFromPlaid | Billing.Deposit.PaymentData XML | Names returned by Plaid identity verification for the bank account holder(s) |
| 6 | CustomerRiskStatus | Dictionary.RiskStatus.Name | Risk status label for the customer from BackOffice.Customer.RiskStatusID |
| 7 | PaymentDate | Billing.Deposit.PaymentDate | Date/time the payment was processed |
| 8 | Amount | Billing.Deposit.Amount | Deposit amount (currency per FundingData context) |
| 9 | ResponseMessage | Billing.Deposit.PaymentData XML | ACH/Plaid response message string |
| 10 | ResponseTime | Billing.Deposit.PaymentData XML | ACH/Plaid response processing time |
| 11 | PaymentStatus | Dictionary.PaymentStatus.Name | Current payment status label (e.g., Approved, Pending, Failed) |
| 12 | RiskManagementStatus | Dictionary.RiskManagementStatus.Name | Risk management decision label for this deposit |
| 13 | AvailableBalance | Billing.Deposit.PaymentData XML | Bank account available balance as reported by Plaid at time of deposit |
| 14 | CurrentBalance | Billing.Deposit.PaymentData XML | Bank account current balance as reported by Plaid |
| 15 | CalculatedBalance | Billing.Deposit.PaymentData XML | Calculated/adjusted balance (varchar - may contain formatted values) |
| 16 | BankName | Billing.Funding.FundingData XML | Bank name as reported by Plaid for the linked ACH account |
| 17 | PlaidItemID | Billing.Deposit.PaymentData XML | Plaid's unique identifier for the bank account item link |
| 18 | RequestID | Billing.Deposit.PaymentData XML | ACH request identifier for tracing in Plaid/ACH network |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| D.CID | Customer.CustomerStatic | JOIN | Gets FirstName, LastName; excludes PlayerLevelID=4 |
| D.CID | BackOffice.Customer | JOIN | Gets RiskStatusID for customer risk status |
| D.FundingID | Billing.Funding | JOIN | Gets FundingTypeID (filtered to 29=ACH) and FundingData XML for BankName |
| D.PaymentStatusID | Dictionary.PaymentStatus | LEFT JOIN | Resolves payment status ID to name |
| D.RiskManagementStatusID | Dictionary.RiskManagementStatus | LEFT JOIN | Resolves risk management status ID to name |
| CB.RiskStatusID | Dictionary.RiskStatus | LEFT JOIN | Resolves customer risk status ID to name |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT codebase. Called by an external scheduled job (per comment: "sent on a daily basis by job").

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ACHDepositDetailedReport (procedure)
|- Billing.Deposit (table) [leaf]
|- Customer.CustomerStatic (table) [cross-schema leaf]
|- BackOffice.Customer (table) [cross-schema leaf]
|- Billing.Funding (table) [leaf]
|- Dictionary.PaymentStatus (table) [cross-schema leaf]
|- Dictionary.RiskManagementStatus (table) [cross-schema leaf]
|- Dictionary.RiskStatus (table) [cross-schema leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary table: reads deposit records filtered by date and FundingTypeID (via Billing.Funding JOIN); extracts XML PaymentData |
| Customer.CustomerStatic | Table | JOINed for customer FirstName, LastName; WHERE PlayerLevelID <> 4 filters out demo accounts |
| BackOffice.Customer | Table | JOINed for RiskStatusID |
| Billing.Funding | Table | JOINed to filter FundingTypeID=29 (ACH) and extract BankName from FundingData XML |
| Dictionary.PaymentStatus | Table | LEFT JOINed to resolve PaymentStatusID to Name |
| Dictionary.RiskManagementStatus | Table | LEFT JOINed to resolve RiskManagementStatusID to Name |
| Dictionary.RiskStatus | Table | LEFT JOINed to resolve RiskStatusID to Name |

### 6.2 Objects That Depend On This

No dependents found in SSDT. Called by an external scheduled job.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. Read-only (SELECT only). No transactions. All JOINs use WITH(NOLOCK) implicitly via the main tables; however the JOINs to Customer/Dictionary tables do not specify WITH(NOLOCK) explicitly. FundingTypeID=29 hardcoded (ACH). PlayerLevelID=4 exclusion hardcoded.

---

## 8. Sample Queries

### 8.1 Run the report for a specific date

```sql
EXEC Billing.ACHDepositDetailedReport
    @FromDate = '2026-03-16',
    @ToDate   = '2026-03-17'
```

### 8.2 Preview ACH deposit XML structure directly

```sql
SELECT TOP 5
    d.DepositID,
    d.PaymentData
FROM Billing.Deposit WITH (NOLOCK) AS d
INNER JOIN Billing.Funding WITH (NOLOCK) AS f ON f.FundingID = d.FundingID
WHERE f.FundingTypeID = 29
  AND d.PaymentData IS NOT NULL
ORDER BY d.DepositID DESC
```

### 8.3 Find ACH deposits with balance mismatch (Plaid available vs current)

```sql
SELECT
    d.DepositID,
    d.CID,
    d.Amount,
    d.PaymentData.value('(/Deposit[1]/AvailableBalanceAsDecimal[1])', 'decimal') AS AvailBal,
    d.PaymentData.value('(/Deposit[1]/CurrentBalanceAsDecimal[1])', 'decimal') AS CurrBal
FROM Billing.Deposit WITH (NOLOCK) AS d
INNER JOIN Billing.Funding WITH (NOLOCK) AS f ON f.FundingID = d.FundingID
WHERE f.FundingTypeID = 29
  AND d.PaymentDate >= '2026-03-01'
  AND d.PaymentData.value('(/Deposit[1]/AvailableBalanceAsDecimal[1])', 'decimal')
    <> d.PaymentData.value('(/Deposit[1]/CurrentBalanceAsDecimal[1])', 'decimal')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHDepositDetailedReport | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ACHDepositDetailedReport.sql*
