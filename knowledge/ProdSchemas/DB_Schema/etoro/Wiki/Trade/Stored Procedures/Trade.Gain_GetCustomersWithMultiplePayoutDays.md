# Trade.Gain_GetCustomersWithMultiplePayoutDays

> Identifies customers who received withdrawal payouts across multiple distinct dates for the same withdrawal ID within the current month, flagging potential split-payment anomalies for the Gain system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - scans current month |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure detects an anomalous payment pattern where a single withdrawal is paid out across multiple calendar dates. In the normal flow, a withdrawal request results in a single payout on one date. When the Gain system detects multiple payout dates for the same WithdrawID, it may indicate a split payment, retry, or processing error that affects gain calculation accuracy.

The procedure scans the current month's credit history for a specific pattern: a compensation credit (CreditTypeID=6, CompensationReasonID=41) that occurs within 24 hours of a cashout request (CreditTypeID=9). For each such pair, it checks whether the approved cashout payments (CreditTypeID=2) occurred on more than one distinct date.

---

## 2. Business Logic

### 2.1 Compensation-to-Cashout Correlation

**What**: Links compensation credits to their associated cashout requests by time proximity.

**Columns/Parameters Involved**: `CreditTypeID`, `CompensationReasonID`, `WithdrawID`, `Occurred`

**Rules**:
- Start from CreditTypeID=6 (compensation) with CompensationReasonID=41 (specific compensation type) in the current month
- Find matching CreditTypeID=9 (cashout request) for the same CID within 24 hours after the compensation
- For each matched WithdrawID, check CreditTypeID=2 (cashout approved) records
- Flag if the approved cashout has payments on > 1 distinct calendar date (HAVING COUNT(DISTINCT PaymentDate) > 1)

### 2.2 Current Month Scope

**What**: Only examines the current calendar month.

**Columns/Parameters Involved**: `@StartOfMonth`

**Rules**:
- @StartOfMonth calculated dynamically as first day of current month from GETUTCDATE()
- Only compensation credits after @StartOfMonth are considered
- This keeps the scan window manageable and aligned with monthly gain processing cycles

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No parameters. Scans current month automatically. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer with multi-day payout anomaly. |
| 2 | WithdrawID | int | NO | - | CODE-BACKED | Withdrawal that was paid out across multiple dates. |
| 3 | (count) | int | NO | - | CODE-BACKED | Number of distinct payment dates for this withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/JOIN | History.Credit | READER | Reads credit records for compensation (6), cashout request (9), and cashout approved (2) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Anomaly detection for multi-day payouts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_GetCustomersWithMultiplePayoutDays (procedure)
+-- History.Credit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | Self-JOIN (3x) for compensation-request-approval chain |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Credit Types Referenced**: 6 = Compensation, 9 = Cashout Request, 2 = Cashout Approved, CompensationReasonID 41 = specific compensation reason.

---

## 8. Sample Queries

### 8.1 Run Multi-Payout Day Detection

```sql
EXEC Trade.Gain_GetCustomersWithMultiplePayoutDays
```

### 8.2 View Current Month Compensations

```sql
SELECT CID, CreditID, Occurred, TotalCashChange, CompensationReasonID
  FROM History.Credit WITH (NOLOCK)
 WHERE CreditTypeID = 6
   AND CompensationReasonID = 41
   AND Occurred > DATEFROMPARTS(YEAR(GETUTCDATE()), MONTH(GETUTCDATE()), 1)
 ORDER BY Occurred DESC
```

### 8.3 Check Payout Dates for a Specific Withdrawal

```sql
SELECT WithdrawID,
       CAST(Occurred AS DATE) AS PaymentDate,
       CreditTypeID,
       TotalCashChange
  FROM History.Credit WITH (NOLOCK)
 WHERE WithdrawID = 12345
 ORDER BY Occurred
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_GetCustomersWithMultiplePayoutDays | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_GetCustomersWithMultiplePayoutDays.sql*
