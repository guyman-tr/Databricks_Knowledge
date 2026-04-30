# Trade.FunPositionCloseWithTimeout

> Table-valued function that returns position close failures caused by database execution timeouts, with XML notification payload for alerting and retry flows.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with Notificationtosend, CID, FailOccurred, PositionFailID, PositionID, InstrumentID, FailReason, Status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunPositionCloseWithTimeout identifies position close attempts that failed due to SQL execution timeouts. It joins History.PositionFail (FailTypeID=4, "Execution Timeout Expired" in FailReason) with History.PositionChangeLog_Active (ChangeTypeID=6) to correlate failed closes with the originating change log entry. For each match, it builds an XML notification payload from History.PositionSlim for downstream alerting or retry systems.

This function exists to surface timeout-related close failures for operations monitoring and automated retry. The notification XML contains full position context (CID, PositionID, InstrumentID, leverage, rates, PnL) so alert handlers can route and retry without re-querying.

Data flows: the function is invoked with @startTime and @Endtime to scope the failure window. Failures must match "Error closing position - DB failure%" and "%Execution Timeout Expired%". Referenced by Trade.PositionOpenWithTimeout (comment) and used for timeout alerting.

---

## 2. Business Logic

### 2.1 Timeout Failure Correlation

**What**: Join PositionFail to PositionChangeLog_Active on CID, ClientRequestGuid, PositionID.

**Columns/Parameters Involved**: `@startTime`, `@Endtime`, `hpf.FailOccurred`, `pcl.Occurred`, `hpf.ClientRequestGuid`, `pcl.ClientRequestGuid`

**Rules**:
- FailTypeID=4 (close failure), ChangeTypeID=6 (position close change)
- FailReason must match both: "Error closing position - DB failure%" AND "%Execution Timeout Expired%"
- Both timestamps must fall within @startTime and @Endtime
- ClientRequestGuid match OR (when ClientRequestGuid is all-zero) timestamps within ±1 minute

### 2.2 FailReason Extraction

**What**: SUBSTRING extracts the message portion between "Message:" and the following ".".

**Columns/Parameters Involved**: `hpf.FailReason`

**Rules**: FailReason = substring from CHARINDEX('Message:',...) to CHARINDEX('.',...) - CHARINDEX('Message:',...)

### 2.3 Notification XML

**What**: OUTER APPLY builds TradingDbPositionNotification XML from History.PositionSlim, Customer.CustomerStatic, Trade.Mirror, Trade.CurrencyPrice.

**Columns/Parameters Involved**: `cte.PositionID`, History.PositionSlim columns

**Rules**: OperationTypeId=1 (PositionClose). XML includes CID, PositionID, InstrumentID, HedgeServerID, Leverage, InitForexRate, EndForexRate, NetProfit, Amount, IsBuy, SkewValue, etc.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of the failure window. Only failures with FailOccurred >= @startTime are returned. |
| 2 | @Endtime | DATETIME | NO | - | CODE-BACKED | End of the failure window. Only failures with FailOccurred <= @Endtime are returned. |
| 3 | Notificationtosend (return) | VARCHAR(8000) | YES | - | CODE-BACKED | XML payload for notification: TradingDbPositionNotification containing TradingData with position details for alert/retry. |
| 4 | CID (return) | INT | YES | - | CODE-BACKED | Customer ID of the failed close. From History.PositionFail. |
| 5 | FailOccurred (return) | datetime | YES | - | CODE-BACKED | When the failure was logged. |
| 6 | PositionFailID (return) | bigint | YES | - | CODE-BACKED | Primary key of History.PositionFail. |
| 7 | PositionID (return) | bigint | YES | - | CODE-BACKED | Position that failed to close. |
| 8 | InstrumentID (return) | INT | YES | - | CODE-BACKED | Instrument of the position. |
| 9 | FailReason (return) | nvarchar | YES | - | CODE-BACKED | Extracted portion between "Message:" and "." from the full FailReason. |
| 10 | Status (return) | INT | NO | 0 | CODE-BACKED | Fixed 0. Placeholder for downstream status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CTE | History.PositionFail | JOIN | Source of timeout failures |
| CTE | History.PositionChangeLog_Active | JOIN | Correlates with change log |
| OUTER APPLY | History.PositionSlim | Query | Position snapshot for XML |
| OUTER APPLY | Customer.CustomerStatic | JOIN | CID to Apex/GCID |
| OUTER APPLY | Trade.Mirror | LEFT JOIN | Mirror active flag |
| OUTER APPLY | Trade.CurrencyPrice | JOIN | Skew values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpenWithTimeout | Comment/DROP | Procedure reference | Related timeout procedure |
| BI/Operations | - | Query | Timeout alert reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunPositionCloseWithTimeout (function)
├── History.PositionFail (table)
├── History.PositionChangeLog_Active (table)
├── History.PositionSlim (table)
├── Customer.CustomerStatic (table)
├── Trade.Mirror (table)
└── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFail | Table | Source of close failures, filtered by FailTypeID=4 and FailReason |
| History.PositionChangeLog_Active | Table | JOIN to correlate failure with change |
| History.PositionSlim | Table | OUTER APPLY for notification XML |
| Customer.CustomerStatic | Table | JOIN for GCID, CountryID |
| Trade.Mirror | Table | LEFT JOIN for IsMirrorActive |
| Trade.CurrencyPrice | Table | JOIN for SkewValueBid/SkewValueAsk |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionOpenWithTimeout | Procedure | Referenced in comment (related timeout handling) |
| BIReader | Role | SELECT granted (per BIReader.sql pattern for similar functions) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF with 8 output columns |
| FOR XML RAW/PATH | XML generation | BINARY BASE64, ELEMENTS, TYPE for notification payload |
| FailTypeID=4 | Filter | Close failure type |
| ChangeTypeID=6 | Filter | Position close change type |

---

## 8. Sample Queries

### 8.1 Get close timeouts for the last 24 hours

```sql
SELECT  Notificationtosend, CID, PositionID, InstrumentID, FailReason, FailOccurred
FROM    Trade.FunPositionCloseWithTimeout(
            DATEADD(HOUR, -24, GETUTCDATE()),
            GETUTCDATE()
        ) f WITH (NOLOCK);
```

### 8.2 Count timeout failures by instrument

```sql
SELECT  InstrumentID, COUNT(*) AS FailCnt
FROM    Trade.FunPositionCloseWithTimeout(
            '2026-03-01 00:00:00',
            '2026-03-15 23:59:59'
        ) f WITH (NOLOCK)
GROUP BY InstrumentID;
```

### 8.3 Get timeouts for a specific customer

```sql
SELECT  f.CID, f.PositionID, f.InstrumentID, f.FailOccurred, f.FailReason
FROM    Trade.FunPositionCloseWithTimeout(
            DATEADD(DAY, -7, GETUTCDATE()),
            GETUTCDATE()
        ) f WITH (NOLOCK)
WHERE   f.CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Code analysis*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 referenced | Corrections: 0 applied*
*Object: Trade.FunPositionCloseWithTimeout | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunPositionCloseWithTimeout.sql*
