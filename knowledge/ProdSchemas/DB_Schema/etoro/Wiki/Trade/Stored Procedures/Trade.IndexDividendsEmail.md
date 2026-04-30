# Trade.IndexDividendsEmail

> Sends an HTML email notification summarizing tonight's index dividend payments to the configured operations recipients; called as the final step of the dividend processing pipeline in Trade.GetCIDsForIndexDividends.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input parameters; depends on #DividendIDs temp table pre-populated by caller; sends via msdb.dbo.sp_send_dbmail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IndexDividendsEmail is the **email notification step** at the end of the nightly index dividend processing pipeline. It sends an HTML-formatted table summarizing which index dividends were credited/charged that night, including the instrument name, position type (CFD/REAL), tax code, event type, ex-date, payment date, dividend value, currency, and buy/sell tax percentages.

This SP exists to provide operations and finance teams with immediate confirmation that the nightly dividend run completed and to communicate exactly which instruments processed dividends. It is the "done" notification for the automated dividend pipeline.

Data flow: `Trade.GetCIDsForIndexDividends` (the main dividend processor) calculates and credits dividends to customer positions, builds the `#DividendIDs` temp table (DISTINCT DividendIDs of all processed dividends), and then calls this SP with `EXEC Trade.IndexDividendsEmail` only when its `@SendEmail` parameter is greater than 0. This SP reads the temp table, enriches it from IndexDividends and supporting tables, and sends the final HTML summary email.

---

## 2. Business Logic

### 2.1 Temp Table Dependency - Pipeline Handshake

**What**: This SP is a helper called within a larger transaction; it depends on a pre-existing temp table.

**Columns/Parameters Involved**: `#DividendIDs.DividendID`

**Rules**:
- `#DividendIDs` must exist in the caller's session scope before EXEC Trade.IndexDividendsEmail
- Created by `Trade.GetCIDsForIndexDividends`: `SELECT DISTINCT DividendID INTO #DividendIDs FROM #CIDsToCharge`
- Only contains DividendIDs that were actually processed (customers charged/credited) in the current run
- If `#DividendIDs` is empty or does not exist, this SP will fail or send an empty email
- This SP is ONLY called when `@SendEmail > 0` in the parent SP - the caller controls email gating

**Diagram**:
```
Trade.GetCIDsForIndexDividends (@SendEmail, ...)
  |
  +--> Processes dividends --> populates #CIDsToCharge
  |
  +--> SELECT DISTINCT DividendID INTO #DividendIDs FROM #CIDsToCharge
  |
  +--> IF @SendEmail > 0
         +--> EXEC Trade.IndexDividendsEmail   <== This SP
                  Reads #DividendIDs
                  JOINs Trade.IndexDividends, InstrumentMetaData, Currency, PositionType
                  Builds HTML table
                  EXEC msdb.dbo.sp_send_dbmail
```

### 2.2 Recipient Configuration via Maintenance.Feature

**What**: Email recipients are configurable via the Feature table - no hardcoded email addresses.

**Columns/Parameters Involved**: `@EmailRecipients`, Maintenance.Feature.FeatureID=46, Maintenance.Feature.Value

**Rules**:
- `SELECT @EmailRecipients = CONVERT(varchar(max), Value) FROM Maintenance.Feature WHERE FeatureID=46`
- FeatureID=46 is the configured key for index dividend email recipients
- If no row with FeatureID=46 exists, `@EmailRecipients` is NULL and sp_send_dbmail may silently fail
- Multiple recipients can be specified in the Value field (semicolon-separated per Database Mail convention)
- This same FeatureID=46 is used by sibling SPs `Trade.IndexDividends24HoursEmailReport` and related dividend email procedures

### 2.3 HTML Email Construction

**What**: Builds a styled HTML table using SQL string concatenation and FOR XML PATH.

**Rules**:
- Table columns: Instrument Name, CFD/REAL (PositionType.Value), Tax Code, Event Type, EX Date, Payment Date, Dividend Value, Dividend Currency, Tax% BUY, Tax% SELL
- `FOR XML PATH('tr')` generates one `<tr>` per dividend row - standard T-SQL HTML generation pattern
- `ISNULL(CAST(...) AS NVARCHAR(MAX)), '')` handles NULL values gracefully
- Subject format: `'Dividend Payments : ' + CONVERT(varchar, GETDATE(), 106)` (e.g., "Dividend Payments : 17 Mar 2026")
- `@blind_copy_recipients=NULL` explicitly disables BCC

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EmailRecipients | VARCHAR(MAX) internal | YES | NULL | CODE-BACKED | Populated from Maintenance.Feature WHERE FeatureID=46. Semicolon-separated list of email addresses. NULL if FeatureID=46 row is missing - in that case sp_send_dbmail receives no recipients. |
| 2 | @tableHTML | VARCHAR(MAX) internal | YES | NULL | CODE-BACKED | HTML string assembled from the dividend data. Contains styled HTML table (green border, bgcolor #99cb51) with one row per dividend from #DividendIDs. Generated via FOR XML PATH('tr') on the enriched dividend JOIN query. |
| 3 | @subjectWithDate | VARCHAR(100) internal | NO | - | CODE-BACKED | Email subject line: 'Dividend Payments : ' + CONVERT(varchar, GETDATE(), 106). Date formatted as DD Mon YYYY (e.g., "17 Mar 2026"). Fixed prefix "Dividend Payments : " identifies these emails in recipients' inboxes. |

**Output columns in the HTML email body (from the JOIN query inside @tableHTML):**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 4 | InstrumentDisplayName | Trade.InstrumentMetaData | CODE-BACKED | Human-readable instrument name (e.g., "Apple Inc.", "S&P 500 Index") for the dividend's underlying asset. |
| 5 | Value (CFD/REAL) | Dictionary.PositionType | CODE-BACKED | Position type label identifying whether the dividend was for CFD or REAL (physically settled) positions. Joins on I.PositionType = T.ID. |
| 6 | TaxCode | Trade.IndexDividends | NAME-INFERRED | Tax classification code for the dividend event. Used by finance to apply appropriate tax treatment. |
| 7 | EventType | Trade.IndexDividends | NAME-INFERRED | Corporate action event type (e.g., regular dividend, special dividend). Identifies the nature of the dividend event. |
| 8 | ExDate | Trade.IndexDividends | CODE-BACKED | Ex-dividend date - positions opened before this date qualify for the dividend. |
| 9 | PaymentDate | Trade.IndexDividends | CODE-BACKED | The date the dividend was scheduled for payment. |
| 10 | DividendValueInCurrency | Trade.IndexDividends | CODE-BACKED | Monetary dividend amount per unit in the dividend currency. |
| 11 | Abbreviation (Currency) | Dictionary.Currency | CODE-BACKED | Currency code for the dividend amount (e.g., USD, EUR). Joins on I.DividendCurrencyID = C.CurrencyID. |
| 12 | BuyTax | Trade.IndexDividends | NAME-INFERRED | Tax percentage applied to BUY (long) positions for this dividend. Shown in the email for ops/finance review. |
| 13 | SellTax | Trade.IndexDividends | NAME-INFERRED | Tax percentage applied to SELL (short) positions for this dividend. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| #DividendIDs.DividendID | Trade.GetCIDsForIndexDividends (#DividendIDs) | Temp Table (session scope) | Depends on this temp table created by the calling SP before EXEC |
| I.DividendID | Trade.IndexDividends | READER (via #DividendIDs JOIN) | Reads full dividend record for enrichment |
| I.InstrumentID | Trade.InstrumentMetaData | Lookup (INNER JOIN) | Gets InstrumentDisplayName for email |
| I.DividendCurrencyID | Dictionary.Currency | Lookup (INNER JOIN) | Gets currency Abbreviation for email |
| I.PositionType | Dictionary.PositionType | Lookup (INNER JOIN) | Gets position type Value label (CFD/REAL) for email |
| @EmailRecipients | Maintenance.Feature (FeatureID=46) | Config Lookup | Gets the list of email recipients |
| (sends via) | msdb.dbo.sp_send_dbmail | External call | Database Mail system SP for sending HTML email |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCIDsForIndexDividends | EXEC Trade.IndexDividendsEmail | Callee | Called at end of dividend processing run when @SendEmail > 0 (since 2014-10-01, FB: 23971) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IndexDividendsEmail (procedure)
|- #DividendIDs (session temp table - created by caller)
|   └-- Trade.GetCIDsForIndexDividends (procedure - creates #DividendIDs)
├── Trade.IndexDividends (table)
├── Trade.InstrumentMetaData (table)
├── Dictionary.Currency (table)
├── Dictionary.PositionType (table)
├── Maintenance.Feature (table - cross-schema)
└── msdb.dbo.sp_send_dbmail (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| #DividendIDs | Session temp table | Provides the set of DividendIDs to include in the email - must exist before this SP runs |
| Trade.IndexDividends | Table | INNER JOIN via #DividendIDs to get full dividend details |
| Trade.InstrumentMetaData | Table | INNER JOIN on InstrumentID to get InstrumentDisplayName |
| Dictionary.Currency | Table | INNER JOIN on DividendCurrencyID to get Abbreviation |
| Dictionary.PositionType | Table | INNER JOIN on PositionType=ID to get Value label |
| Maintenance.Feature | Table (cross-schema) | Reads FeatureID=46 to get email recipients list |
| msdb.dbo.sp_send_dbmail | System SP | Sends the HTML email via SQL Server Database Mail |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCIDsForIndexDividends | Procedure | Calls this SP as final step when @SendEmail > 0; creates #DividendIDs before calling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| #DividendIDs dependency | Session temp table | Fails if #DividendIDs does not exist in session scope when SP executes |
| FeatureID=46 | Config dependency | If Maintenance.Feature row for FeatureID=46 is missing, @EmailRecipients=NULL and email fails silently |
| INNER JOINs | Join type | Dividends in #DividendIDs with unresolvable instrument/currency/positiontype are silently excluded from email body |

---

## 8. Sample Queries

### 8.1 Check current email recipients for dividend notifications

```sql
SELECT Value AS EmailRecipients
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 46
```

### 8.2 Preview what the email would contain for a specific dividend run

```sql
-- Simulates the JOIN used inside IndexDividendsEmail to preview email content
SELECT
    m.InstrumentDisplayName,
    t.Value AS CFD_REAL,
    i.TaxCode,
    i.EventType,
    i.ExDate,
    i.PaymentDate,
    i.DividendValueInCurrency,
    c.Abbreviation AS Currency,
    i.BuyTax,
    i.SellTax
FROM Trade.IndexDividends i WITH (NOLOCK)
    INNER JOIN Trade.InstrumentMetaData m WITH (NOLOCK) ON i.InstrumentID = m.InstrumentID
    INNER JOIN Dictionary.Currency c WITH (NOLOCK) ON i.DividendCurrencyID = c.CurrencyID
    INNER JOIN Dictionary.PositionType t WITH (NOLOCK) ON i.PositionType = t.ID
WHERE i.DividendID IN (
    -- Replace with actual DividendIDs from a recent processing run
    SELECT DividendID FROM Trade.IndexDividends WITH (NOLOCK)
    WHERE PaymentDate = CONVERT(date, GETDATE())
)
```

### 8.3 Verify dividend email was triggered - check GetCIDsForIndexDividends call history

```sql
-- Check which dividends processed today and whether email was sent
SELECT TOP 10
    d.DividendID,
    d.PaymentDate,
    d.Status,
    d.InstrumentID,
    d.DividendValueInCurrency
FROM Trade.IndexDividends d WITH (NOLOCK)
WHERE d.PaymentDate = CONVERT(date, GETDATE())
ORDER BY d.DividendID DESC
```

---

## 9. Atlassian Knowledge Sources

No dedicated Confluence page or Jira ticket found for Trade.IndexDividendsEmail. Code comment in Trade.GetCIDsForIndexDividends attributes the introduction of this call to FB: 23971 (2014-10-01).

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Readme](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13794639922/Readme) | Confluence | Trading Execution Services DB documentation overview - general context for Trade schema dividend procedures |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 7/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed (GetCIDsForIndexDividends) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IndexDividendsEmail | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IndexDividendsEmail.sql*
