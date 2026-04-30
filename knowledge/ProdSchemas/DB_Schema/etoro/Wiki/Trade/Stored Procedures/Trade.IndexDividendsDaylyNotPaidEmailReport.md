# Trade.IndexDividendsDaylyNotPaidEmailReport

> Returns the list of index dividends scheduled for payment today that have not yet been processed (Status=1), used for daily operational monitoring of pending dividend payouts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input parameters; Reads: Trade.IndexDividends (Status=1, PaymentDate=today), Trade.InstrumentMetaData, Dictionary.Currency, Dictionary.PositionType |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IndexDividendsDaylyNotPaidEmailReport is a **daily dividend monitoring query** that returns all index dividend records scheduled to pay on the current calendar date but whose Status is still 1 (pending/not yet processed). It surfaces the "to-do list" of dividend payments that the dividend processing pipeline should handle today.

This SP exists as an operational health check. The companion SP `Trade.IndexDividends24HoursEmailReport` shows what WAS paid in the last 24 hours (Status=2, completed). This SP shows what SHOULD BE paid today but has not yet been processed - enabling operations/finance teams to identify and follow up on any unpaid dividends before end of day.

Data flows as follows: dividend records are created in `Trade.IndexDividends` with Status=1 (pending) and a target PaymentDate. This SP reads those records on the day they are due. Once the dividend processing pipeline runs (`Trade.IndexDividends_SetStatus` or related procs), Status moves to 2 (completed) and the record disappears from this SP's result set.

---

## 2. Business Logic

### 2.1 Today's Unpaid Dividends Filter

**What**: Identifies exactly which dividends are due today and still pending.

**Columns/Parameters Involved**: `d.Status`, `d.PaymentDate`

**Rules**:
- `WHERE d.Status = 1` - only pending dividends (not yet processed by the payment pipeline)
- `AND d.PaymentDate = CONVERT(date, GETDATE())` - exactly today's date (server local date, not UTC)
- This combination means: "scheduled to pay today but the pipeline has not yet run or failed to process"
- A non-empty result set at end of day indicates unpaid dividends requiring investigation

**Diagram**:
```
IndexDividends lifecycle:
  Status=1 (Pending) --> [This SP monitors] --> Payment pipeline runs
  Status=2 (Completed) --> [IndexDividends24HoursEmailReport monitors]

Time dimension:
  PaymentDate = today AND Status=1  ==> APPEARS in this SP's results
  PaymentDate = today AND Status=2  ==> Disappears (already paid)
  PaymentDate < today AND Status=1  ==> NOT in results (overdue - separate alert)
```

### 2.2 Enrichment JOINs

**What**: Resolves IDs to human-readable names for reporting.

**Columns/Parameters Involved**: `d.InstrumentID`, `d.DividendCurrencyID`, `d.PositionType`

**Rules**:
- JOIN `Trade.InstrumentMetaData` ON InstrumentID -> provides `InstrumentDisplayName` (human-readable instrument name)
- JOIN `Dictionary.Currency` ON DividendCurrencyID -> provides `Abbreviation` (e.g., "USD", "EUR")
- JOIN `Dictionary.PositionType` ON d.PositionType = t.ID -> provides `Value` (e.g., "BUY" or "SELL", or CFD/REAL type label)
- All JOINs use `INNER JOIN` so any dividend with an unresolvable InstrumentID, Currency, or PositionType will be excluded from results

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | (output column) | - | - | CODE-BACKED | Primary key of the dividend record from Trade.IndexDividends. Identifies which dividend event is pending payment today. |
| 2 | PaymentDate | (output column) | - | - | CODE-BACKED | The scheduled payment date for this dividend. Always equals today's date (CONVERT(date, GETDATE())) because of the WHERE filter. Confirms the dividend was scheduled for today. |
| 3 | Status | (output column) | - | - | CODE-BACKED | Dividend processing status. Always 1 (pending/not paid) in this result set - that is the WHERE filter condition. Status=2 = completed/paid (handled by IndexDividends24HoursEmailReport). |
| 4 | InstrumentDisplayName | (output column) | - | - | CODE-BACKED | Human-readable instrument name from Trade.InstrumentMetaData. The display name shown to users and in reports (e.g., "Apple Inc.", "S&P 500"). |
| 5 | Value | (output column) | - | - | CODE-BACKED | Position type label from Dictionary.PositionType (joined on d.PositionType = t.ID). Indicates whether the dividend applies to BUY/SELL or CFD/REAL positions. |
| 6 | TaxCode | (output column) | - | - | NAME-INFERRED | Tax classification code for this dividend event from Trade.IndexDividends. Used by operations/finance to apply the correct tax treatment to the dividend payment. |
| 7 | EventType | (output column) | - | - | NAME-INFERRED | Dividend event classification from Trade.IndexDividends (e.g., regular dividend, special dividend, etc.). Determines the type of corporate action being processed. |
| 8 | ExDate | (output column) | - | - | CODE-BACKED | Ex-dividend date from Trade.IndexDividends. The date on which a buyer of the instrument is no longer entitled to the dividend. Positions opened before this date qualify for the dividend. |
| 9 | DividendValueInCurrency | (output column) | - | - | CODE-BACKED | The dividend amount expressed in the dividend's currency (DividendCurrencyID). The monetary value per unit/lot that eligible positions will receive. |
| 10 | Abbreviation | (output column) | - | - | CODE-BACKED | Currency abbreviation from Dictionary.Currency (e.g., "USD", "EUR", "GBP"). Identifies the currency denomination of DividendValueInCurrency for this dividend payout. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| d.InstrumentID | Trade.InstrumentMetaData | Lookup (INNER JOIN) | Resolves instrument ID to display name for reporting |
| d.DividendCurrencyID | Dictionary.Currency | Lookup (INNER JOIN) | Resolves currency ID to abbreviation (e.g., USD, EUR) |
| d.PositionType | Dictionary.PositionType | Lookup (INNER JOIN) | Resolves position type integer to label (BUY/SELL/CFD/REAL) |
| (reads) | Trade.IndexDividends | READER | Primary data source - pending dividends due today |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Nagios monitoring | permission grant | EXEC permission | Nagios monitoring user has EXECUTE permission - this SP is called by an external monitoring/alerting system |
| SplunkUser | permission grant | EXEC permission | Splunk log aggregation user has EXECUTE permission - results may be ingested into Splunk for alerting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IndexDividendsDaylyNotPaidEmailReport (procedure)
├── Trade.IndexDividends (table)
├── Trade.InstrumentMetaData (table)
├── Dictionary.Currency (table)
└── Dictionary.PositionType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | Primary source - filtered for Status=1 AND PaymentDate=today |
| Trade.InstrumentMetaData | Table | INNER JOIN on InstrumentID to get InstrumentDisplayName |
| Dictionary.Currency | Table | INNER JOIN on DividendCurrencyID to get currency Abbreviation |
| Dictionary.PositionType | Table | INNER JOIN on PositionType=ID to get position type Value label |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Nagios monitoring system | External | EXEC permission granted - called by external monitoring/alerting |
| SplunkUser | External | EXEC permission granted - results may be ingested for alerting dashboards |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Status = 1 filter | WHERE clause | Only returns pending dividends; completed (Status=2) and future dividends are excluded |
| PaymentDate = today filter | WHERE clause | Uses CONVERT(date, GETDATE()) - server local date; only dividends due on current calendar day |
| INNER JOINs | Join type | Dividends with missing InstrumentMetaData, Currency, or PositionType records are silently excluded from results |

---

## 8. Sample Queries

### 8.1 Check today's unpaid dividends

```sql
EXEC Trade.IndexDividendsDaylyNotPaidEmailReport
```

### 8.2 Manual equivalent query - today's pending dividends with context

```sql
SELECT
    d.DividendID,
    d.PaymentDate,
    d.Status,
    m.InstrumentDisplayName,
    t.Value AS PositionType,
    d.TaxCode,
    d.EventType,
    d.ExDate,
    d.DividendValueInCurrency,
    c.Abbreviation AS Currency
FROM Trade.IndexDividends d WITH (NOLOCK)
    INNER JOIN Trade.InstrumentMetaData m WITH (NOLOCK) ON d.InstrumentID = m.InstrumentID
    INNER JOIN Dictionary.Currency c WITH (NOLOCK) ON d.DividendCurrencyID = c.CurrencyID
    INNER JOIN Dictionary.PositionType t WITH (NOLOCK) ON d.PositionType = t.ID
WHERE d.Status = 1
    AND d.PaymentDate = CONVERT(date, GETDATE())
```

### 8.3 Compare pending vs paid dividends for today

```sql
-- Pending (should appear in this SP's output)
SELECT COUNT(*) AS PendingToday, 1 AS Status
FROM Trade.IndexDividends WITH (NOLOCK)
WHERE Status = 1 AND PaymentDate = CONVERT(date, GETDATE())

UNION ALL

-- Completed today (appears in IndexDividends24HoursEmailReport)
SELECT COUNT(*) AS CompletedToday, 2 AS Status
FROM Trade.IndexDividends WITH (NOLOCK)
WHERE Status = 2 AND PaymentDate = CONVERT(date, GETDATE())
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Readme](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13794639922/Readme) | Confluence | Trading Execution Services DB documentation overview - general context for Trade schema dividend procedures |

No dedicated Confluence page or Jira ticket found specifically for Trade.IndexDividendsDaylyNotPaidEmailReport.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IndexDividendsDaylyNotPaidEmailReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IndexDividendsDaylyNotPaidEmailReport.sql*
