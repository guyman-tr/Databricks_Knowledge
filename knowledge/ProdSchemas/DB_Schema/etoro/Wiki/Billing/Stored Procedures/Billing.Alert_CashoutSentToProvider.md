# Billing.Alert_CashoutSentToProvider

> Monitoring alert procedure (PAYUS-3420) that detects withdrawal payment legs stuck in "Sent to Provider" status (CashoutStatusID=10) within a configurable time window, returning the affected WithdrawIDs and a 0/1 alert signal for monitoring systems.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset of WithdrawIDs + RETURN value (0=no stuck records, 1=alert triggered) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.Alert_CashoutSentToProvider` is an operational monitoring procedure that detects cashout (withdrawal) payment legs that have been stuck in the "Sent to Provider" status (CashoutStatusID=10) for an abnormally long time. When a withdrawal is sent to a payment provider for processing, the expected outcome is a relatively quick update back to either "Processed" or "Rejected". Legs that remain at status 10 beyond a threshold window indicate a potential problem: the provider may have processed the payment but not sent a response, or the payment may be hanging.

The procedure is designed to be called by a monitoring/alerting system (introduced in PAYUS-3420 on 14/07/2021). It returns the list of affected WithdrawIDs and signals to the caller whether any stuck records were found (RETURN 1=yes, RETURN 0=no). The calling system then triggers an alert (email, Slack, PagerDuty, etc.) based on the non-zero return value.

Data flows: the monitoring scheduler calls this procedure periodically (e.g., hourly), passing a time window. The procedure queries `Billing.WithdrawToFunding` for records in the stuck state within that window and returns results to the monitoring tool.

---

## 2. Business Logic

### 2.1 Stuck Payment Detection Window

**What**: The procedure uses a date window (via ModificationDate) to find payment legs modified during a lookback period while still in the "Sent to Provider" status.

**Parameters/Columns Involved**: `@FromDate`, `@ToDate`, `Billing.WithdrawToFunding.CashoutStatusID`, `Billing.WithdrawToFunding.ModificationDate`

**Rules**:
- `CashoutStatusID = 10` filters for "Sent to Provider" status only.
- Default window: `ModificationDate > DATEADD(MONTH, -1, GETDATE())` (lower bound - 1 month ago) AND `ModificationDate < DATEADD(WEEK, -2, GETUTCDATE())` (upper bound - 2 weeks ago).
- The default window finds records last modified between 1 month ago and 2 weeks ago that are STILL at status 10 - these have been stuck for at least 2 weeks but no more than 1 month.

**IMPORTANT - Inverted Parameter Naming**:
- `@FromDate` acts as the **upper bound** (ModificationDate < @FromDate), defaulting to 2 weeks ago.
- `@ToDate` acts as the **lower bound** (ModificationDate > @ToDate), defaulting to 1 month ago.
- This is counter-intuitive: the parameter named "From" is the newer/recent date and "To" is the older date. The logic reads as "from [2 weeks ago] to [1 month ago]" scanned backwards in time.

**Diagram**:
```
Time axis:
  <older>                            <newer>
  |-------1 month ago---|---2 weeks ago---|---NOW
                        ^--- @ToDate (lower bound, default)
                                    ^--- @FromDate (upper bound, default)
                        [   ALERT WINDOW   ]
  Records in CashoutStatusID=10 with ModificationDate in this window are returned.
```

### 2.2 Alert Signal Return Value

**What**: The procedure returns 0 (no issue) or 1 (alert - stuck records found) to the calling monitoring system.

**Parameters/Columns Involved**: RETURN value, @@ROWCOUNT

**Rules**:
- `RETURN(CASE @@ROWCOUNT WHEN 0 THEN 0 ELSE 1 END)` - returns 0 if the SELECT produced zero rows, 1 if any stuck records were found.
- This allows the monitoring caller to check the return code without parsing the resultset to determine if an alert should be triggered.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | YES | NULL | CODE-BACKED | Upper bound of the stuck-payment detection window. Records with ModificationDate < @FromDate are included. When NULL, defaults to DATEADD(WEEK, -2, GETUTCDATE()) - 2 weeks ago. IMPORTANT: Despite the "From" name, this is the NEWER/upper date boundary. (See Section 2.1 for the inverted naming explanation.) |
| 2 | @ToDate | DATETIME | YES | NULL | CODE-BACKED | Lower bound of the stuck-payment detection window. Records with ModificationDate > @ToDate are included. When NULL, defaults to DATEADD(MONTH, -1, GETDATE()) - 1 month ago. IMPORTANT: Despite the "To" name, this is the OLDER/lower date boundary. (See Section 2.1.) |

**Return value**: INT (0 = no stuck records in window; 1 = one or more stuck records found - alert should be triggered)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | Billing.WithdrawToFunding | READER | Queries for payment legs in CashoutStatusID=10 within the time window. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from monitoring/alerting systems on a scheduled basis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Alert_CashoutSentToProvider (procedure)
+- Billing.WithdrawToFunding (table)   [SELECT - stuck payment leg detection]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | SELECT for CashoutStatusID=10 records within the ModificationDate window |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from monitoring/alerting tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Run with default window (find records stuck 2 weeks to 1 month)
```sql
DECLARE @AlertStatus INT;
EXEC @AlertStatus = Billing.Alert_CashoutSentToProvider;
SELECT @AlertStatus AS AlertTriggered; -- 0 = no issue, 1 = stuck records found
```

### 8.2 Run with custom window
```sql
DECLARE @AlertStatus INT;
EXEC @AlertStatus = Billing.Alert_CashoutSentToProvider
    @FromDate = '2026-02-01',  -- upper bound: records modified before Feb 1
    @ToDate   = '2026-01-01';  -- lower bound: records modified after Jan 1
SELECT @AlertStatus AS AlertTriggered;
```

### 8.3 Direct query to see stuck payments (equivalent to what the proc returns)
```sql
SELECT  WTF.WithdrawID,
        WTF.ID              AS WithdrawToFundingID,
        WTF.CashoutStatusID,
        WTF.ModificationDate,
        DATEDIFF(DAY, WTF.ModificationDate, GETUTCDATE()) AS DaysStuck
FROM    Billing.WithdrawToFunding WTF WITH (NOLOCK)
WHERE   WTF.CashoutStatusID = 10
  AND   WTF.ModificationDate < DATEADD(WEEK, -2, GETUTCDATE())
  AND   WTF.ModificationDate > DATEADD(MONTH, -1, GETDATE())
ORDER BY WTF.WithdrawID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 10/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.Alert_CashoutSentToProvider | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.Alert_CashoutSentToProvider.sql*
