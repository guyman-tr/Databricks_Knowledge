# Billing.DepositReport

> Daily scheduled email report for US Plaid (ACH) deposits - extracts XML payment data fields and sends an HTML-formatted summary to a configurable recipient list via database mail. Not called by the application; driven by a SQL Agent job.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate / @ToDate date range + FundingTypeID=29 (Plaid) filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositReport` is an operational reporting SP that generates a daily HTML email summarizing US Plaid (ACH bank-linked) deposits for a given date range. It is explicitly documented in the source code as being driven by a SQL Agent job - not called by any application service.

The report targets `FundingTypeID=29` (Plaid) exclusively, which is the US ACH integration using Plaid for bank account linking and balance verification. The Plaid integration stores rich XML metadata in `Billing.Deposit.PaymentData` (account holder names, response details, bank balances) and `Billing.Funding.FundingData` (bank name). This SP unwraps those XML fields using XQuery `.value()` calls to produce a readable row per deposit.

The report excludes `PlayerLevelID=4` accounts (demo/internal accounts) to show only real customer activity. It joins to `BackOffice.Customer` for the customer's risk status, and to `Dictionary.RiskManagementStatus` for the deposit-level risk management state.

A related SP `Billing.USADepositReport` likely provides an updated or parallel version of this report. `Billing.ACHDepositDetailedReport` covers ACH deposits with more detail.

---

## 2. Business Logic

### 2.1 Plaid Deposit Data Extraction

**What**: Extracts Plaid-specific XML fields from PaymentData and FundingData into a temp table.

**Columns/Parameters Involved**: `Billing.Deposit.PaymentData`, `Billing.Funding.FundingData`, `@FromDate`, `@ToDate`

**Rules**:
- Filter: `FundingTypeID = 29 (Plaid)` AND `PaymentDate >= @FromDate AND PaymentDate < @ToDate` (exclusive upper bound).
- Additional filter: `Customer.CustomerStatic.PlayerLevelID <> 4` - excludes demo/internal accounts.
- PaymentData XML fields extracted via XQuery `.value()`:
  - `PlaidNamesAsString` - account holder names as returned by Plaid.
  - `ResponseMessageAsString` - gateway response message/description.
  - `ResponseTimeAsString` - response latency or timestamp from gateway.
  - `AvailableBalanceAsDecimal` - bank account available balance at time of deposit (DECIMAL type).
  - `CurrentBalanceAsDecimal` - bank account current balance (DECIMAL type).
  - `AccountBalanceAsDecimal` - alias "CalculatedBalance" - bank account balance (VARCHAR(50) cast, despite "Decimal" in name).
  - `PlaidItemIDAsString` - Plaid Item ID identifying the specific bank connection.
- FundingData XML field: `BankNameAsString` - name of the linked bank institution.
- Results loaded into temp table `#T` for HTML generation.

### 2.2 HTML Email Construction

**What**: Builds an HTML table from the temp data and sends it via SQL Server Database Mail.

**Columns/Parameters Involved**: `@tableHTML`, `@EmailAdresses`, `msdb.dbo.sp_send_dbmail`

**Rules**:
- HTML title includes date range: `U.S.A Deposits between {FromDate} to {ToDate}`.
- Table styled with border=5, orange border color (#F25022), cell padding=5, light blue background (#E8F2F7).
- 17 columns in report: CID, DepositID, FirstName, LastName, NamesFromPlaid, CustomerRiskStatus, PaymentDate, Amount, ResponseMessage, ResponseTime, PaymentStatus, RiskManagementStatus, AvailableBalance, CurrentBalance, CalculatedBalance, BankName, PlaidItemID.
- `FOR XML PATH('tr')` technique generates HTML rows from the SELECT.
- `msdb.dbo.sp_send_dbmail` called with: `@recipients=@EmailAdresses`, `@subject='USA Deposits'`, `@body=@tableHTML`, `@body_format='HTML'`.
- Note: a commented-out @query alternative exists, suggesting the SP was originally tested with a direct query before switching to the HTML approach.

```
@FromDate, @ToDate, @EmailAdresses
  -> SELECT XML fields + joins -> #T temp table
  -> Build HTML: title + styled table via FOR XML PATH('tr')
  -> EXEC msdb.dbo.sp_send_dbmail (subject='USA Deposits', HTML body)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATE | NO | - | CODE-BACKED | Start of the deposit PaymentDate range (inclusive: `PaymentDate >= @FromDate`). DATE type (no time component). Typically yesterday's date when called by the daily job. |
| 2 | @ToDate | DATE | NO | - | CODE-BACKED | End of the deposit PaymentDate range (exclusive: `PaymentDate < @ToDate`). DATE type. Typically today's date when called by the daily job, giving a full prior-day window. |
| 3 | @EmailAdresses | VARCHAR(350) | NO | - | CODE-BACKED | Semicolon-delimited list of email recipients. Passed directly to `msdb.dbo.sp_send_dbmail @recipients`. Max 350 chars supports several email addresses. Typically configured in the SQL Agent job step. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FromDate / @ToDate | Billing.Deposit | READ (SELECT) | Primary data source. Filtered by PaymentDate range AND FundingTypeID=29 (Plaid). PaymentData XML fields extracted via XQuery. |
| FundingID | Billing.Funding | INNER JOIN | Provides FundingTypeID filter (=29 Plaid) and FundingData XML (BankNameAsString). |
| CID | Customer.CustomerStatic | INNER JOIN (cross-schema) | Provides FirstName, LastName. Also filters PlayerLevelID <> 4. |
| CID | BackOffice.Customer | INNER JOIN (cross-schema) | Provides RiskStatusID for CustomerRiskStatus label. |
| PaymentStatusID | Dictionary.PaymentStatus | LEFT JOIN | Resolves payment status name. |
| RiskManagementStatusID | Dictionary.RiskManagementStatus | LEFT JOIN | Resolves deposit risk management status name. |
| RiskStatusID | Dictionary.RiskStatus | LEFT JOIN | Resolves customer-level risk status name from BackOffice.Customer. |
| @tableHTML | msdb.dbo.sp_send_dbmail | EXEC (cross-db) | Sends the HTML email to @EmailAdresses. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent job (scheduled) | @FromDate, @ToDate, @EmailAdresses | EXEC | Called daily by a job. Source code comment: "A report that is being sent on a daily basis by job. The application is not using this procedure." |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositReport (procedure)
+-- Billing.Deposit (table)
+-- Billing.Funding (table)
+-- Customer.CustomerStatic (table) [cross-schema]
+-- BackOffice.Customer (table) [cross-schema]
+-- Dictionary.PaymentStatus (table) [cross-schema]
+-- Dictionary.RiskManagementStatus (table) [cross-schema]
+-- Dictionary.RiskStatus (table) [cross-schema]
+-- msdb.dbo.sp_send_dbmail (procedure) [cross-database]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ - main data source, filtered by date range and FundingTypeID=29. |
| Billing.Funding | Table | INNER JOIN - resolves FundingTypeID and provides FundingData XML. |
| Customer.CustomerStatic | Table (cross-schema) | INNER JOIN - FirstName, LastName, PlayerLevelID filter. |
| BackOffice.Customer | Table (cross-schema) | INNER JOIN - RiskStatusID for customer risk label. |
| Dictionary.PaymentStatus | Table (cross-schema) | LEFT JOIN - payment status name. |
| Dictionary.RiskManagementStatus | Table (cross-schema) | LEFT JOIN - deposit risk management status name. |
| Dictionary.RiskStatus | Table (cross-schema) | LEFT JOIN - customer risk status name from BackOffice.Customer. |
| msdb.dbo.sp_send_dbmail | System procedure (cross-db) | EXEC - sends HTML email. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent daily job | Job | EXEC - scheduled daily execution with prior-day date range and configured recipient list. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Plaid XML structure** (FundingTypeID=29 PaymentData fields):
- `/Deposit[1]/PlaidNamesAsString[1]` - account holder name(s) verified by Plaid
- `/Deposit[1]/ResponseMessageAsString[1]` - gateway response description
- `/Deposit[1]/ResponseTimeAsString[1]` - response latency
- `/Deposit[1]/AvailableBalanceAsDecimal[1]` - available balance DECIMAL
- `/Deposit[1]/CurrentBalanceAsDecimal[1]` - current balance DECIMAL
- `/Deposit[1]/AccountBalanceAsDecimal[1]` - calculated balance (cast to VARCHAR(50) despite name)
- `/Deposit[1]/PlaidItemIDAsString[1]` - Plaid Item ID (bank connection identifier)

**FundingData XML**: `/Funding[1]/BankNameAsString[1]` - bank institution name.

**Related SPs**: `Billing.USADepositReport` and `Billing.ACHDepositDetailedReport` are sibling procedures covering US ACH/Plaid deposits with potentially different scope or detail level.

**Note**: SQL Agent job configuration (schedule, recipient list) is held outside the SSDT repo in msdb.

---

## 8. Sample Queries

### 8.1 Execute the report for yesterday

```sql
EXEC [Billing].[DepositReport]
    @FromDate = CAST(DATEADD(d, -1, GETDATE()) AS DATE),
    @ToDate   = CAST(GETDATE() AS DATE),
    @EmailAdresses = 'payments-ops@etoro.com';
```

### 8.2 Preview what the report would contain (dry run)

```sql
SELECT D.CID, D.DepositID,
    D.PaymentData.value('(/Deposit[1]/PlaidNamesAsString[1])', 'varchar(100)') AS NamesFromPlaid,
    D.PaymentData.value('(/Deposit[1]/AvailableBalanceAsDecimal[1])', 'decimal') AS AvailableBalance,
    F.FundingData.value('(/Funding[1]/BankNameAsString[1])', 'varchar(50)') AS BankName,
    PS.Name AS PaymentStatus
FROM [Billing].[Deposit] D WITH (NOLOCK)
JOIN [Billing].[Funding] F WITH (NOLOCK) ON F.FundingID = D.FundingID
JOIN [Customer].[CustomerStatic] C WITH (NOLOCK) ON D.CID = C.CID
LEFT JOIN [Dictionary].[PaymentStatus] PS WITH (NOLOCK) ON D.PaymentStatusID = PS.PaymentStatusID
WHERE F.FundingTypeID = 29
  AND C.PlayerLevelID <> 4
  AND D.PaymentDate >= DATEADD(d, -1, CAST(GETDATE() AS DATE))
  AND D.PaymentDate < CAST(GETDATE() AS DATE);
```

### 8.3 Count Plaid deposits by status for a date range

```sql
SELECT PS.Name AS PaymentStatus, COUNT(*) AS DepositCount, SUM(D.Amount) AS TotalAmount
FROM [Billing].[Deposit] D WITH (NOLOCK)
JOIN [Billing].[Funding] F WITH (NOLOCK) ON F.FundingID = D.FundingID
JOIN [Customer].[CustomerStatic] C WITH (NOLOCK) ON D.CID = C.CID
LEFT JOIN [Dictionary].[PaymentStatus] PS WITH (NOLOCK) ON D.PaymentStatusID = PS.PaymentStatusID
WHERE F.FundingTypeID = 29
  AND C.PlayerLevelID <> 4
  AND D.PaymentDate >= '2026-03-17'
  AND D.PaymentDate < '2026-03-18'
GROUP BY PS.Name
ORDER BY DepositCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositReport | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositReport.sql*
