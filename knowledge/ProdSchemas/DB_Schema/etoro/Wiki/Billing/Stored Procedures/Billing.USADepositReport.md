# Billing.USADepositReport

> Daily email report for US ACH/Plaid deposits (FundingTypeID=29): selects deposits for a date range, extracts Plaid XML metadata fields, builds an HTML table, and sends it via sp_send_dbmail to specified recipients. Run by SQL Agent job only - not called by the application.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate, @ToDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.USADepositReport` is a scheduled reporting procedure that produces a daily HTML email summarizing ACH/Plaid deposits made by US customers. It is executed by a SQL Server Agent job - the DDL comment explicitly states "A report that is being sent on a daily basis by job. The application is not using this procedure."

Plaid is the bank-link service used for ACH deposits in the United States (FundingTypeID=29). The report includes Plaid-specific metadata extracted from the `PaymentData` XML column on `Billing.Deposit`, such as the bank account holder names returned by Plaid (`PlaidNamesAsString`), Plaid's account balance readings, and the Plaid Item ID which identifies the linked bank account.

The report filters to non-demo customers (`CustomerStatic.PlayerLevelID <> 4`) and joins to `BackOffice.Customer` for risk status. The email is sent via `msdb.dbo.sp_send_dbmail` with HTML formatting.

---

## 2. Business Logic

### 2.1 Plaid Deposit Filter

**What**: Selects only ACH/Plaid deposits (FundingTypeID=29) within the date window, excluding demo accounts.

**Rules**:
- `BF.FundingTypeID = 2` ... actually `F.FundingTypeID = 29` (Plaid/ACH) - verified in WHERE clause
- `C.PlayerLevelID <> 4` - excludes demo accounts (PlayerLevelID=4 = Demo)
- `D.PaymentDate >= @FromDate AND D.PaymentDate < @ToDate` - date range filter (exclusive ToDate)
- Joins: `Customer.CustomerStatic` (name, PlayerLevel), `BackOffice.Customer` (risk status), `Billing.Funding` (FundingTypeID + FundingData XML), `Dictionary.PaymentStatus`, `Dictionary.RiskManagementStatus`, `Dictionary.RiskStatus`

### 2.2 Plaid XML Field Extraction

**What**: Extracts Plaid-specific and payment-response fields from XML columns on Billing.Deposit and Billing.Funding.

**Rules - Billing.Deposit.PaymentData XML fields**:

| Field | XPath | Description |
|-------|-------|-------------|
| NamesFromPlaid | /Deposit/PlaidNamesAsString | Account holder names returned by Plaid identity verification |
| ResponseMessage | /Deposit/ResponseMessageAsString | Plaid API response message (success/failure) |
| ResponseTime | /Deposit/ResponseTimeAsString | Plaid API call response time |
| AvailableBalance | /Deposit/AvailableBalanceAsDecimal | Bank account available balance at deposit time |
| CurrentBalance | /Deposit/CurrentBalanceAsDecimal | Bank account current balance at deposit time |
| CalculatedBalance | /Deposit/AccountBalanceAsDecimal | Calculated account balance |
| PlaidItemID | /Deposit/PlaidItemIDAsString | Plaid item ID - uniquely identifies the linked bank connection |

**Rules - Billing.Funding.FundingData XML fields**:

| Field | XPath | Description |
|-------|-------|-------------|
| BankName | /Funding/BankNameAsString | Name of the linked bank |

### 2.3 HTML Email Generation

**What**: Builds an HTML table from the temp table results and sends via database mail.

**Rules**:
- `FOR XML PATH('tr')` with `TYPE` converts rows to HTML `<tr>` elements
- HTML table has `border="5"` with eToro orange header color (`bordercolor="#F25022"`)
- Email subject: 'ACH Deposits report'
- `@recipients` = @EmailAdresses parameter (note: parameter name has typo - "Adresses" not "Addresses")
- Sent via `msdb.dbo.sp_send_dbmail`
- If no rows match the filter, the email is still sent with an empty table

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATE | NO | - | CODE-BACKED | Start of the deposit date range (inclusive). Compared against `Billing.Deposit.PaymentDate`. For daily job, this is yesterday's date. |
| 2 | @ToDate | DATE | NO | - | CODE-BACKED | End of the deposit date range (exclusive: `PaymentDate < @ToDate`). For daily job, this is today's date. |
| 3 | @EmailAdresses | VARCHAR(350) | NO | - | CODE-BACKED | Semicolon-delimited list of recipient email addresses passed to sp_send_dbmail. Note: typo in parameter name ("Adresses" not "Addresses"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| D.DepositID | Billing.Deposit | SELECT | Source of deposit records with PaymentData XML |
| D.FundingID | Billing.Funding | JOIN | Source of FundingData XML (BankName) and FundingTypeID=29 filter |
| D.CID | Customer.CustomerStatic | JOIN | Customer name and PlayerLevelID (demo filter) |
| D.CID | BackOffice.Customer | JOIN | Customer risk status (RiskStatusID) |
| D.PaymentStatusID | Dictionary.PaymentStatus | JOIN | Payment status name |
| D.RiskManagementStatusID | Dictionary.RiskManagementStatus | JOIN | Risk management status name |
| CB.RiskStatusID | Dictionary.RiskStatus | JOIN | Customer risk status name |
| - | msdb.dbo.sp_send_dbmail | EXEC | Sends the HTML report email |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server Agent job (operations) | Scheduled job | Scheduled call | Runs daily to send ACH deposit summary email |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.USADepositReport (procedure)
+-- Billing.Deposit (table) [SELECT with XML extraction]
+-- Billing.Funding (table) [JOIN - FundingTypeID=29, FundingData XML]
+-- Customer.CustomerStatic (table) [JOIN - name, PlayerLevelID]
+-- BackOffice.Customer (table) [JOIN - RiskStatusID]
+-- Dictionary.PaymentStatus (table) [JOIN - status name]
+-- Dictionary.RiskManagementStatus (table) [JOIN - RM status name]
+-- Dictionary.RiskStatus (table) [JOIN - customer risk name]
+-- msdb.dbo.sp_send_dbmail (system procedure) [EXEC - email]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source; PaymentData XML provides Plaid fields |
| Billing.Funding | Table | Provides FundingTypeID=29 filter and BankName from FundingData XML |
| Customer.CustomerStatic | Table | FirstName, LastName, PlayerLevelID (exclude demo) |
| BackOffice.Customer | Table | RiskStatusID |
| Dictionary.PaymentStatus | Table | PaymentStatus.Name label |
| Dictionary.RiskManagementStatus | Table | RiskManagementStatus.Name label |
| Dictionary.RiskStatus | Table | Customer risk status label |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent job (operations) | Scheduled job | Calls daily to email ACH deposit report |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Application-excluded | Design | DDL comment states "The application is not using this procedure" - job-only |
| No explicit transaction | Design | Read-only SELECT + email send; no writes to etoro DB |
| @ToDate exclusive | Logic | `PaymentDate < @ToDate` means ToDate is not included in the range |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Run report for a specific date range
```sql
EXEC Billing.USADepositReport
    @FromDate      = '2026-03-17',
    @ToDate        = '2026-03-18',
    @EmailAdresses = 'ops-team@etoro.com;compliance@etoro.com';
```

### 8.2 Ad-hoc query version (without email sending)
```sql
SELECT D.CID, D.DepositID,
    D.PaymentData.value('(/Deposit[1]/PlaidNamesAsString[1])', 'varchar(100)') AS NamesFromPlaid,
    D.PaymentDate, D.Amount,
    D.PaymentData.value('(/Deposit[1]/ResponseMessageAsString[1])', 'varchar(50)') AS ResponseMessage,
    F.FundingData.value('(/Funding[1]/BankNameAsString[1])', 'varchar(50)') AS BankName
FROM Billing.Deposit D WITH (NOLOCK)
INNER JOIN Billing.Funding F WITH (NOLOCK) ON F.FundingID = D.FundingID
WHERE F.FundingTypeID = 29
  AND D.PaymentDate >= '2026-03-17'
  AND D.PaymentDate < '2026-03-18'
ORDER BY D.PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.USADepositReport | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.USADepositReport.sql*
