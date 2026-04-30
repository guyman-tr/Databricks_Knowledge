# Trade.CurrencyPriceDifferencesAlert

> Monitors the currency price feed differences table and sends email alerts to the dealing team when instruments show persistent price discrepancies between primary and secondary market data feeds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sends sp_send_dbmail alert |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CurrencyPriceDifferencesAlert is the alerting component of the price feed integrity monitoring pipeline. After Trade.CollectCurrencyPriceDifferencesBetweenFeeds detects and logs price discrepancies, this procedure checks whether the divergence is persistent (exceeds a configurable fault count threshold within a 2-minute window) and sends email notifications to the dealing/trading operations team.

This procedure is critical for operational monitoring. Persistent price feed differences may indicate a broken feed, network issues with a data provider, or market data quality problems that could lead to incorrect trading prices. The alert enables the dealing desk to investigate and potentially switch feeds or halt trading on affected instruments.

The procedure also supports a delay mechanism via DBA_ExposureBreakDown_Alert, allowing operations teams to suppress alerts during known maintenance windows.

---

## 2. Business Logic

### 2.1 Alert Threshold and Timing

**What**: Alerts fire only when price differences persist beyond a configurable fault count within a recent time window.

**Columns/Parameters Involved**: `@FaultCountBeforeAlert`, `CurrencyPriceFeedDifferences.CollectionTime`

**Rules**:
- First checks if alert is delayed (DBA_ExposureBreakDown_Alert.DelayUntil > current time) - if so, returns immediately
- Counts differences per InstrumentID in the last 2 minutes
- Alert triggers only if COUNT(*) > @FaultCountBeforeAlert for any instrument
- Alert message includes all affected InstrumentIDs
- Email sent via msdb.dbo.sp_send_dbmail

**Diagram**:
```
CurrencyPriceFeedDifferences (last 2 min)
    |
    +-- GROUP BY InstrumentID
    |     +-- HAVING COUNT(*) > @FaultCountBeforeAlert
    |
    +-- If threshold exceeded:
          +-- Build instrument list message
          +-- sp_send_dbmail to @Recipients
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FaultCountBeforeAlert | INT | NO | - | CODE-BACKED | Number of price difference records per instrument within 2 minutes before triggering an alert. Higher values reduce false positives but delay real alerts. |
| 2 | @Recipients | VARCHAR(MAX) | YES | 'Dealing-RND@etoro.com;dotanva@etoro.com' | CODE-BACKED | Semicolon-separated email recipients for the alert. Defaults to the Dealing R&D team. |
| 3 | @Copy_Recipients | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Optional CC recipients for the alert email. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Threshold check | Trade.CurrencyPriceFeedDifferences | Reader | Reads recent price difference records to count per-instrument fault frequency |
| Delay check | DBA_ExposureBreakDown_Alert | Reader | Checks if alerting is suppressed during maintenance windows |
| Email send | msdb.dbo.sp_send_dbmail | Caller | Sends the alert email via Database Mail |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled | Caller | Typically called on a recurring schedule (every few minutes) by a SQL Agent job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CurrencyPriceDifferencesAlert (procedure)
+-- Trade.CurrencyPriceFeedDifferences (table)
+-- DBA_ExposureBreakDown_Alert (table)
+-- msdb.dbo.sp_send_dbmail (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPriceFeedDifferences | Table | Read to count recent price differences per instrument |
| DBA_ExposureBreakDown_Alert | Table | Read to check alert delay status |
| msdb.dbo.sp_send_dbmail | System Procedure | Called to send alert emails |

### 6.2 Objects That Depend On This

No dependents found. This is a terminal alerting procedure called by scheduled jobs.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check recent feed differences
```sql
SELECT InstrumentID, COUNT(*) AS DiffCount, MAX(CollectionTime) AS LastOccurrence
FROM   Trade.CurrencyPriceFeedDifferences WITH (NOLOCK)
WHERE  CollectionTime >= DATEADD(MINUTE, -2, GETDATE())
GROUP BY InstrumentID
ORDER BY DiffCount DESC
```

### 8.2 Check alert delay status
```sql
SELECT SP_Name, DelayUntil
FROM   DBA_ExposureBreakDown_Alert WITH (NOLOCK)
WHERE  SP_Name = 'CurrencyPriceDifferencesAlert'
```

### 8.3 View recent alert history via Database Mail
```sql
SELECT TOP 5 subject, send_request_date, sent_status
FROM   msdb.dbo.sysmail_allitems WITH (NOLOCK)
WHERE  subject LIKE '%different%Bid or Ask%'
ORDER BY send_request_date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CurrencyPriceDifferencesAlert | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CurrencyPriceDifferencesAlert.sql*
