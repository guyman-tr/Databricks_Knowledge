# Trade.IndexDividends24HoursEmailReport

> Sends an HTML email report of all dividend payments processed in the last 24 hours. Recipients are read from Maintenance.Feature (FeatureID=46). Only sends if there are completed dividends (Status=2) with positions processed in the window.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input parameters; Reads: Trade.IndexDividends (Status=2), Trade.PositionsProcessedForIndexDividnds; Sends email via msdb.dbo.sp_send_dbmail |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IndexDividends24HoursEmailReport is a **nightly email notification** SP that summarizes dividend payments that were processed in the preceding 24 hours. It generates an HTML table report and sends it to recipients configured in Maintenance.Feature (FeatureID=46).

The email covers: which instruments paid dividends, the dividend value and currency, tax rates (BuyTax, SellTax), event type, ex-date, payment date, and whether they were CFD or REAL position type. The report is intended for operations/finance teams to confirm successful nightly dividend processing.

The SP only runs the email send path if there are matching rows - an empty result silently exits without sending an empty report.

Recipients are configurable via `Maintenance.Feature WHERE FeatureID=46`. If this feature row is missing or has a NULL value, @EmailRecipients will be NULL and sp_send_dbmail will fail or send to no recipients.

---

## 2. Business Logic

### 2.1 Data Collection - Last 24 Hours Completed Dividends

**What**: Collect dividend payment records completed in the last 24 hours.

**Rules**:
- @affectedDate = `DATEADD(HOUR, -24, GETUTCDATE())` - 24-hour lookback from now (UTC)
- `SELECT into #DividendIDs FROM Trade.IndexDividends D JOIN Trade.InstrumentMetaData M ON D.InstrumentID JOIN Dictionary.Currency C ON D.DividendCurrencyID JOIN Dictionary.PositionType T ON D.PositionType JOIN Trade.PositionsProcessedForIndexDividnds P ON P.DividendID`
- WHERE D.Status=2 (completed only) AND P.ProcessTime >= @affectedDate

### 2.2 Email Generation and Send

**What**: Build HTML table and send via Database Mail.

**Rules**:
- `IF EXISTS (SELECT 1 FROM #DividendIDs)` - only send if there are rows
- HTML table built with string concatenation + `FOR XML PATH('tr')` for per-row HTML
- Grouped by: InstrumentID, InstrumentDisplayName, Value, TaxCode, EventType, ExDate, PaymentDate, DividendValueInCurrency, Abbreviation, BuyTax, SellTax (deduplicates per position)
- Subject: `'Dividend Payments : ' + CONVERT(varchar, GETDATE(), 106)` (e.g., "Dividend Payments : 17 Mar 2026")
- `EXEC msdb.dbo.sp_send_dbmail @recipients=@EmailRecipients, @body=@tableHTML, @body_format='HTML'`
- Note: @blind_copy_recipients=NULL explicitly

### 2.3 Recipient Configuration

**What**: Email recipients come from Maintenance.Feature configuration.

**Rules**:
- `SELECT @EmailRecipients = CONVERT(varchar(max), Value) FROM Maintenance.Feature WHERE FeatureID=46`
- Feature 46 = dividend email recipients. Comma-separated email addresses.
- If not configured (NULL/missing): sp_send_dbmail receives NULL recipients and may fail or skip.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. The SP has no parameters - it always queries the last 24 hours window.

**Output**: Email sent to recipients in Maintenance.Feature FeatureID=46.

**Report columns** (HTML table):
| Column | Source | Description |
|--------|--------|-------------|
| InstrumentID | Trade.IndexDividends | Instrument paying the dividend |
| Instrument Name | Trade.InstrumentMetaData.InstrumentDisplayName | Display name |
| CFD/REAL | Dictionary.PositionType.Value | Position type label |
| Tax Code | Trade.IndexDividends.TaxCode | Tax identifier |
| Event Type | Trade.IndexDividends.EventType | Dividend event category |
| EX Date | Trade.IndexDividends.ExDate | Qualifying ex-dividend date |
| Payment Date | Trade.IndexDividends.PaymentDate | When dividend was paid |
| Dividend Value | Trade.IndexDividends.DividendValueInCurrency | Amount per share/unit |
| Dividend Currency | Dictionary.Currency.Abbreviation | Currency of dividend value |
| Tax% BUY | Trade.PositionsProcessedForIndexDividnds.BuyTax | Tax rate for long positions |
| Tax% SELL | Trade.PositionsProcessedForIndexDividnds.SellTax | Tax rate for short positions |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=46 | Maintenance.Feature | SELECT | Email recipients configuration |
| Status=2, last 24h | Trade.IndexDividends | SELECT | Completed dividend events |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Instrument display name |
| DividendCurrencyID | Dictionary.Currency | JOIN | Currency abbreviation |
| PositionType | Dictionary.PositionType | JOIN | CFD/REAL label |
| DividendID | Trade.PositionsProcessedForIndexDividnds | JOIN | Tax rates and ProcessTime filter |
| (email send) | msdb.dbo.sp_send_dbmail | EXEC | SQL Server Database Mail |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp | GRANT EXECUTE | Application | Dividend processing application triggers nightly email |
| SQL Agent Job (likely) | - | Scheduled | Typically called by a nightly SQL Agent job after dividend processing completes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IndexDividends24HoursEmailReport (procedure)
+-- Maintenance.Feature (x-schema table) [FeatureID=46 - recipients]
+-- Trade.IndexDividends (table) [Status=2 completed dividends]
+-- Trade.InstrumentMetaData (table) [display name]
+-- Dictionary.Currency (x-schema table) [currency abbreviation]
+-- Dictionary.PositionType (x-schema table) [CFD/REAL label]
+-- Trade.PositionsProcessedForIndexDividnds (table) [tax rates + 24h filter]
+-- msdb.dbo.sp_send_dbmail (system procedure) [email send]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | FeatureID=46: email recipients |
| Trade.IndexDividends | Table | Completed dividends (Status=2) in last 24h |
| Trade.InstrumentMetaData | Table | Instrument display name |
| Dictionary.Currency | Table | Dividend currency abbreviation |
| Dictionary.PositionType | Table | Position type label (CFD/REAL) |
| Trade.PositionsProcessedForIndexDividnds | Table | ProcessTime 24h filter; BuyTax, SellTax |
| msdb.dbo.sp_send_dbmail | System Procedure | HTML email delivery |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp | Application | Triggers nightly after dividend processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

No error handling around sp_send_dbmail - if Database Mail is disabled or misconfigured, the SP will fail silently or raise an error. FeatureID=46 must be configured for email to be sent. The GROUP BY in the XML FOR PATH deduplicates per instrument/event combination, not per individual position (PositionID appears in the initial SELECT but is excluded from the GROUP BY, so multiple positions for the same dividend are aggregated into one report row).

---

## 8. Sample Queries

### 8.1 Run the email report

```sql
EXEC Trade.IndexDividends24HoursEmailReport;
```

### 8.2 Preview what would be emailed (without sending)

```sql
DECLARE @affectedDate DATETIME = DATEADD(HOUR, -24, GETUTCDATE());

SELECT D.InstrumentID,
       M.InstrumentDisplayName,
       T.Value AS PositionTypeLabel,
       D.TaxCode,
       D.EventType,
       D.ExDate,
       D.PaymentDate,
       D.DividendValueInCurrency,
       C.Abbreviation AS Currency,
       P.BuyTax,
       P.SellTax,
       COUNT(P.PositionID) AS ProcessedPositions
FROM Trade.IndexDividends D WITH (NOLOCK)
     JOIN Trade.InstrumentMetaData M WITH (NOLOCK) ON D.InstrumentID = M.InstrumentID
     JOIN Dictionary.Currency C WITH (NOLOCK) ON D.DividendCurrencyID = C.CurrencyID
     JOIN Dictionary.PositionType T WITH (NOLOCK) ON D.PositionType = T.ID
     JOIN Trade.PositionsProcessedForIndexDividnds P WITH (NOLOCK) ON P.DividendID = D.DividendID
WHERE D.Status = 2
  AND P.ProcessTime >= @affectedDate
GROUP BY D.InstrumentID, M.InstrumentDisplayName, T.Value, D.TaxCode, D.EventType,
         D.ExDate, D.PaymentDate, D.DividendValueInCurrency, C.Abbreviation, P.BuyTax, P.SellTax
ORDER BY D.InstrumentID;
```

### 8.3 Check configured email recipients

```sql
SELECT FeatureID, FeatureName, Value
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 46;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: callers found, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.IndexDividends24HoursEmailReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IndexDividends24HoursEmailReport.sql*
