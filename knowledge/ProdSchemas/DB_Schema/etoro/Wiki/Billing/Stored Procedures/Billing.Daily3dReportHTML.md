# Billing.Daily3dReportHTML

> Generates and emails a daily 3DS authentication HTML report for a date range to a hardcoded list of recipients via `msdb.dbo.sp_send_dbmail`; same CTE logic as `Billing.Daily3dReport` but formatted as an HTML table email.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate (date range filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.Daily3dReportHTML` is the email delivery wrapper for the 3DS daily report. It executes the same CTE logic as `Billing.Daily3dReport` to gather credit card deposit 3DS authentication data, formats the results as an HTML table, and sends it via SQL Server Database Mail (`msdb.dbo.sp_send_dbmail`) to a hardcoded list of eToro payment team recipients.

This procedure is designed to be called by a SQL Server Agent job or scheduled task to automatically deliver the 3DS monitoring report to the payment team each morning.

**Email recipients (hardcoded)**:
- adico@etoro.com
- shukyba@etoro.com
- yoniel@etoro.com
- dannyad@etoro.com
- maorbe@etoro.com

**Email subject**: `'DAILY 3Ds REPORT FOR {DD/MM/YYYY}'` (using CONVERT format 103).

---

## 2. Business Logic

### 2.1 CTE: Same 3DS Data as Daily3dReport

**What**: Identical CTE to `Billing.Daily3dReport` with minor differences:
- Uses `C.Name` (full currency name) instead of `C.Abbreviation`
- `UserRegulation` returns `DesignatedRegulationID` (integer) not the regulation name (no JOIN to Dictionary.Regulation)
- Wraps fields with `ISNULL(..., '')` for NULL safety in HTML rendering
- Does NOT aggregate with GROUP BY + MAX - directly queries the CTE rows (one row per deposit-per-event)

### 2.2 HTML Generation Pattern

**What**: Builds an HTML string using string concatenation and `FOR XML PATH('tr')`.

**HTML structure**:
```
<html>
  <body>
    <h2>DAILY 3Ds REPORT FOR {date}</h2>
    <table border="5" bordercolor="#F25022" ...>
      <tr><th>CID</th><th>Deposit ID</th>...<th>Finished 3Ds Process</th></tr>
      {data rows via FOR XML PATH('tr')}
    </table>
  </body>
</html>
```

**Data row generation**:
- `SELECT @tableHTML = CONVERT(nvarchar(max), (SELECT td=CID, '', td=DepositID, ... FROM MyCTE FOR XML PATH(N'tr'), TYPE))`
- The `td=column` pattern with `''` separator generates `<td>value</td>` cells in the XML PATH output

### 2.3 Email Delivery

**What**: Calls `msdb.dbo.sp_send_dbmail` with the constructed HTML.

**Parameters**:
- `@recipients`: hardcoded list (adico@, shukyba@, yoniel@, dannyad@, maorbe@etoro.com)
- `@subject`: 'DAILY 3Ds REPORT FOR {DD/MM/YYYY}'
- `@body`: the full HTML string
- `@body_format`: 'HTML'

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATE | NO | - | VERIFIED | Start of date range (inclusive): `PaymentDate >= @StartDate`. |
| 2 | @EndDate | DATE | NO | - | VERIFIED | End of date range (exclusive): `PaymentDate < @EndDate`. |

**Return value**: None. The procedure sends an email; it does not return a result set.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (CTE primary) | Billing.Deposit | Read | Date-range CC deposits |
| (CTE join) | Dictionary.Currency | Read | Currency name |
| (CTE join) | BackOffice.Customer | Read | Customer regulation ID |
| (CTE join) | Customer.CustomerStatic | Read | Customer country |
| (CTE join) | Dictionary.Country (x2) | Read | User country + BIN country names |
| (CTE join) | Billing.Depot | Read | Processor name |
| (CTE join) | Billing.Funding | Read | Card XML data |
| (CTE join) | Dictionary.CountryBin | Read | BIN details |
| (CTE join) | Dictionary.CardType | Read | Card brand name |
| (CTE join) | Billing.Trace | Read | 3DS event JSON messages |
| (email) | msdb.dbo.sp_send_dbmail | Call | SQL Server Database Mail for email delivery |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server Agent job | @StartDate, @EndDate | Caller | Scheduled daily execution to deliver 3DS report to payment team |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Daily3dReportHTML (procedure)
+-- Billing.Deposit (table) [READ]
+-- Billing.Funding (table) [READ]
+-- Billing.Trace (table) [READ]
+-- Billing.Depot (table) [READ]
+-- BackOffice.Customer (table) [READ]
+-- Customer.CustomerStatic (table) [READ]
+-- Dictionary.Currency (table) [READ]
+-- Dictionary.Country (table x2) [READ]
+-- Dictionary.CountryBin (view) [READ]
+-- Dictionary.CardType (table) [READ]
+-- msdb.dbo.sp_send_dbmail (procedure) [CALL: email delivery]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source |
| Billing.Funding | Table | Card XML data |
| Billing.Trace | Table | 3DS event JSON messages |
| Billing.Depot | Table | Processor name |
| BackOffice.Customer | Table | Regulation ID |
| Customer.CustomerStatic | Table | Customer country |
| Dictionary.Currency | Table | Currency name |
| Dictionary.Country | Table | Country names (x2) |
| Dictionary.CountryBin | View | BIN data |
| Dictionary.CardType | Table | Card brand |
| msdb.dbo.sp_send_dbmail | System SP | Email delivery |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server Agent job | External | Scheduled 3DS report delivery |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hardcoded recipient list**: The email addresses are embedded in the procedure code. Any change to the recipient list requires an ALTER PROCEDURE. This is a maintenance concern if team members change.

**Difference from Daily3dReport**:
- No GROUP BY/MAX aggregation - raw CTE rows sent to HTML (may have duplicate DepositID rows if multiple trace events exist)
- Currency uses Name (full name) instead of Abbreviation
- UserRegulation is the raw integer ID, not the name
- No date column in the output (PaymentDate not included)
- Missing JOIN to Dictionary.PaymentStatus (TransactionalFinalStatus is the raw integer)
- Missing JOIN to Dictionary.Regulation

**`--SELECT @HTML` commented out**: A debugging artifact left in the code that allows testing the HTML output directly without sending email (by uncommenting).

**`msdb.dbo.sp_send_dbmail` dependency**: Requires SQL Server Database Mail to be configured and a mail profile to be active on the server.

---

## 8. Sample Queries

### 8.1 Execute the email report for yesterday

```sql
EXEC Billing.Daily3dReportHTML
    @StartDate = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE),
    @EndDate = CAST(GETDATE() AS DATE)
-- Sends HTML email to hardcoded recipients
```

### 8.2 Preview the data without sending email (use Daily3dReport instead)

```sql
-- Use the tabular version for ad-hoc queries:
EXEC Billing.Daily3dReport '2026-03-17', '2026-03-18'
-- Returns the same data as a result set without sending email
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.Daily3dReportHTML | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.Daily3dReportHTML.sql*
