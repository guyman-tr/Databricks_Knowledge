# Billing.LastHourTotalTechnicalVsHistory

> Returns the raw count of technical deposit failures in the previous hour across all payment methods - an ops alerting indicator for detecting system-level payment processing errors.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar raw count (lastHourTechnical) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LastHourTotalTechnicalVsHistory` is an ops alerting probe that counts technical deposit failures in the previous hour. Unlike its sibling procedures which return a ratio vs historical baseline, this procedure returns the raw count of deposits with `PaymentStatusID=4` (Technical failure) - a status that indicates a system-level error during payment processing (as opposed to a customer-declined payment which would be PaymentStatusID=3).

Technical failures (PaymentStatusID=4) are abnormal outcomes that suggest infrastructure or integration problems: payment gateway timeouts, serialization errors, unexpected provider responses, or internal system exceptions. A spike in technical failures is an immediate alert signal regardless of historical trends - even a small number may warrant investigation. For this reason, the procedure returns a raw count rather than a historical ratio: ops teams apply their own static thresholds rather than comparing to a rolling average.

Data flows: called by the ops alerting/monitoring system alongside `LastHourTotalCreditCardApprovedDepositsVsHistory` and `LastHourTotalPayPalNewDepositsVsHistory` as a three-part payment health monitoring suite.

---

## 2. Business Logic

### 2.1 Technical Failure Count for Last Hour

**What**: Counts all deposits with PaymentStatusID=4 in the previous hour, across all payment methods.

**Columns/Parameters Involved**: `PaymentStatusID`, `PaymentDate`, `FundingID`

**Rules**:
- `@lastHour = DATEPART(hh, GETDATE()) - 1`: previous hour (0-23)
- `@currentDayOfWeek = DATEPART(DW, GETDATE())`: computed but NOT USED in the query (declared for consistency with sibling SPs but serves no function here)
- Live count filter: `PaymentStatusID=4` (Technical failure), `DATEPART(hh, PaymentDate) = @lastHour AND PaymentDate > DATEADD(hh, -2, GETDATE())`
- NO FundingTypeID filter: counts technical failures across ALL payment methods
- NO historical division: returns raw count as FLOAT (CAST(COUNT(*) AS float))
- Column alias: `lastHourTechnical`
- No SET NOCOUNT ON; no input parameters

**Diagram**:
```
Ops monitoring calls at hourly interval
        |
        v
@lastHour = current hour - 1
        |
        v
lastHourTechnical = COUNT(*) FROM Billing.Deposit JOIN Billing.Funding
  WHERE PaymentStatusID=4 (Technical)
  AND DATEPART(hh, PaymentDate)=@lastHour
  AND PaymentDate > GETDATE()-2h
  -- No FundingTypeID filter: ALL payment methods
        |
        v
Returns: lastHourTechnical (raw FLOAT count)
  0       = no technical failures (ideal)
  1-10    = low-level noise (investigate context)
  10+     = significant issue (alert ops immediately)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Column

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | lastHourTechnical | FLOAT | CODE-BACKED | Raw count of deposits with PaymentStatusID=4 (Technical failure) in the previous hour, across all payment methods. Returned as FLOAT (from CAST(COUNT(*) AS float)). Unlike sibling procedures, this is an absolute count not a percentage ratio - ops teams apply their own static alert thresholds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Live count | Billing.Deposit | READ | Counts technical failure (PaymentStatusID=4) deposits in previous hour across all payment types |
| JOIN | Billing.Funding | READ | JOINed on FundingID; no FundingTypeID filter applied (all payment methods counted) |

### 5.2 Referenced By (other objects point to this)

No stored procedure callers found in the Billing schema. Called from the ops alerting/monitoring system on a scheduled basis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LastHourTotalTechnicalVsHistory (procedure)
├── Billing.Deposit (table - technical failure count)
└── Billing.Funding (table - JOINed, no filter applied)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | COUNT of technical failure deposits (PaymentStatusID=4) in last hour; 2-hour PaymentDate window |
| Billing.Funding | Table | JOINed on FundingID; not filtered by FundingTypeID (all payment methods) |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- No `SET NOCOUNT ON`; no parameters
- `@currentDayOfWeek` is declared and set but never used in the SELECT - dead variable, included for structural consistency with the sibling SPs
- JOIN to Billing.Funding is present (consistent with siblings) but adds no filtering value - the Billing.Funding JOIN could be removed without changing the result if FundingTypeID filtering is not needed
- Unlike the sibling procedures, there is no reference to `Billing.DepositHourlyAverage` - this is intentional; technical failures are rare enough that absolute counts are more meaningful than ratios
- Midnight edge case: `DATEPART(hh, GETDATE()) - 1` produces -1 at midnight; no deposits will match, result will be 0
- Sibling procedures: `LastHourTotalCreditCardApprovedDepositsVsHistory` (CC approval ratio), `LastHourTotalPayPalNewDepositsVsHistory` (PayPal initiation ratio)

---

## 8. Sample Queries

### 8.1 Execute the alert check
```sql
EXEC Billing.LastHourTotalTechnicalVsHistory
-- Returns: lastHourTechnical FLOAT (raw count of technical failures)
```

### 8.2 Drill into technical failures from last hour
```sql
SELECT bd.DepositID, bd.CID, bd.FundingID, bf.FundingTypeID,
       bd.PaymentDate, bd.Amount, bd.ProcessCurrencyID
FROM Billing.Deposit bd WITH (NOLOCK)
JOIN Billing.Funding bf WITH (NOLOCK) ON bd.FundingID = bf.FundingID
WHERE bd.PaymentStatusID = 4
  AND DATEPART(hh, bd.PaymentDate) = DATEPART(hh, GETDATE()) - 1
  AND bd.PaymentDate > DATEADD(hh, -2, GETDATE())
ORDER BY bd.PaymentDate DESC
```

### 8.3 Technical failures by payment method last hour
```sql
SELECT bf.FundingTypeID, COUNT(*) AS TechnicalCount
FROM Billing.Deposit bd WITH (NOLOCK)
JOIN Billing.Funding bf WITH (NOLOCK) ON bd.FundingID = bf.FundingID
WHERE bd.PaymentStatusID = 4
  AND DATEPART(hh, bd.PaymentDate) = DATEPART(hh, GETDATE()) - 1
  AND bd.PaymentDate > DATEADD(hh, -2, GETDATE())
GROUP BY bf.FundingTypeID
ORDER BY TechnicalCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 siblings analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LastHourTotalTechnicalVsHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LastHourTotalTechnicalVsHistory.sql*
