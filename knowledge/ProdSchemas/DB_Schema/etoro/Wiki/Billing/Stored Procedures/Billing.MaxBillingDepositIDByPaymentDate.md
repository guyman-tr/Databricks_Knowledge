# Billing.MaxBillingDepositIDByPaymentDate

> Utility procedure used by the DepositAlert service to find the minimum DepositID with a PaymentDate falling within a recent time window - returns the ID via an OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @periodSec INT (time offset in seconds), @ret INT OUTPUT (returned DepositID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.MaxBillingDepositIDByPaymentDate returns the smallest DepositID from Billing.Deposit where the PaymentDate falls within the time window defined by @periodSec. The result is returned as an OUTPUT parameter (@ret), not as a resultset.

This procedure was created on 11/07/2017 by Geri Reshef (change ref: 46780) specifically for the "DepositAlert service" - an internal monitoring or alerting service that tracks recent deposit activity. The DepositAlert service uses this DepositID as a cursor marker: by finding the first DepositID in the recent window, it can scan forward from that point to process or alert on new deposits.

The name "MaxBillingDepositIDByPaymentDate" is misleading: the query actually returns the MINIMUM DepositID (ORDER BY DepositID ASC, TOP 1) within the time window, not the maximum. The "Max" in the name likely refers to the time boundary: deposits with PaymentDate >= the maximum acceptable age cutoff.

Typical usage: @periodSec is a negative value (e.g., -300 for "last 5 minutes"), so DATEADD(Second, -300, GETUTCDATE()) = 5 minutes ago. The procedure finds the first deposit paid in the last N seconds.

---

## 2. Business Logic

### 2.1 Time-Window Cursor Lookup

**What**: Finds the earliest DepositID within a time window defined by @periodSec.

**Columns/Parameters Involved**: `@periodSec`, `@ret`

**Rules**:
- Logic: `SELECT TOP(1) DepositID FROM Billing.Deposit WITH(NoLock) WHERE PaymentDate >= DATEADD(Second, @periodSec, GETUTCDATE()) ORDER BY DepositID ASC`
- @periodSec is an offset in seconds applied to GETUTCDATE(). Typically negative (e.g., -300 = last 5 minutes, -3600 = last hour).
- Returns the MINIMUM DepositID in the window (ORDER BY 1 ASC = ORDER BY DepositID ASC).
- If no deposits found in the window: @ret = NULL (TOP(1) on empty set returns no rows; SET @ret = NULL by default).
- No RETURN value - result is via OUTPUT parameter.
- No TRY/CATCH - errors propagate unhandled.
- Uses NOLOCK hint - reads Billing.Deposit without acquiring shared locks (tolerates dirty reads).

**Diagram**:
```
DepositAlert service
    |
    v
Billing.MaxBillingDepositIDByPaymentDate(@periodSec = -300, @ret OUTPUT)
    |
    v
SELECT TOP(1) DepositID FROM Billing.Deposit
    WHERE PaymentDate >= DATEADD(Second, -300, GETUTCDATE())  -- last 5 minutes
    ORDER BY DepositID ASC
    |
    v
@ret = smallest DepositID paid in last 5 minutes
    (NULL if no deposits in window)
    |
    v
DepositAlert service scans forward from that DepositID for alerts
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @periodSec | INT | NO | - | CODE-BACKED | Time offset in seconds added to GETUTCDATE() to define the start of the time window. Typically negative (e.g., -300 = look back 5 minutes). Positive values would look forward into the future - an unusual but valid usage. |
| 2 | @ret | INT | YES | - | CODE-BACKED | OUTPUT parameter receiving the result. Set to the TOP 1 DepositID (ascending - minimum ID) where PaymentDate >= the computed cutoff. NULL if no deposits exist in the window. The "Max" in the procedure name is misleading - this is actually the minimum DepositID in the window. |
| RETURN | (void) | - | - | CODE-BACKED | No explicit RETURN. Result returned via @ret OUTPUT parameter only. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Billing.Deposit | READ | Reads DepositID and PaymentDate to find the time-window cursor position. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositAlert service | @periodSec, @ret | EXEC | Internal monitoring service (created 2017) that uses the returned DepositID as a scan cursor. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MaxBillingDepositIDByPaymentDate (procedure)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT TOP(1) DepositID WHERE PaymentDate >= time window. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositAlert service | Application | EXEC - uses returned DepositID as a cursor to scan for recent deposits. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get the first DepositID from the last 5 minutes
```sql
DECLARE @ret INT;
EXEC Billing.MaxBillingDepositIDByPaymentDate
    @periodSec = -300,
    @ret = @ret OUTPUT;
SELECT @ret AS FirstDepositIDInLastFiveMinutes;
-- NULL if no deposits in the last 5 minutes
```

### 8.2 Get the first DepositID from the last hour
```sql
DECLARE @ret INT;
EXEC Billing.MaxBillingDepositIDByPaymentDate
    @periodSec = -3600,
    @ret = @ret OUTPUT;
SELECT @ret AS FirstDepositIDInLastHour;
```

### 8.3 Equivalent direct query
```sql
-- Equivalent to calling the procedure with @periodSec = -300
SELECT TOP(1) DepositID
FROM Billing.Deposit WITH (NOLOCK)
WHERE PaymentDate >= DATEADD(Second, -300, GETUTCDATE())
ORDER BY DepositID ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.MaxBillingDepositIDByPaymentDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.MaxBillingDepositIDByPaymentDate.sql*
