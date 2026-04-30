# Billing.DD_Alert_CashoutSentToProvider

> DataDog monitoring check that counts withdrawal records stuck in "SentToProvider" status (CashoutStatusID=10) for longer than 2 weeks, alerting the payments team to cashouts that have been dispatched to a provider but not confirmed or resolved.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (count of stuck withdrawals) + List (comma-separated WithdrawIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_Alert_CashoutSentToProvider` is a DataDog synthetic monitor procedure (DBAD-11). It finds withdrawal payment legs in `Billing.WithdrawToFunding` that are stuck in `CashoutStatusID=10` (SentToProvider) - meaning they were sent to the payment provider but have not received a final status update for more than 2 weeks.

`CashoutStatusID=10` (SentToProvider) is a non-final intermediate state in the withdrawal lifecycle: the payment instruction has been transmitted to the provider (bank, card network, e-wallet) but the provider's confirmation has not yet come back. Under normal operation, this state resolves within hours or a few days. Records lingering in this state for over 2 weeks indicate stalled transactions requiring manual investigation.

The procedure returns the COUNT of stalled records as `value` (rather than a 0/1 flag like other DD_ monitors), allowing DataDog to use it as a numeric metric and chart trends over time. The comma-separated `List` of `WithdrawIDs` enables the payments team to drill into the specific affected records immediately.

This procedure is closely related to `DD_CashoutSentToProvider`, which has the same detection logic but returns a boolean 0/1 instead of a count. The two serve different DataDog use cases: this one feeds metric charts, the other feeds alert conditions.

---

## 2. Business Logic

### 2.1 Stuck Cashout Detection Window

**What**: Identifies withdrawal payment legs that have been in "SentToProvider" state within a specific age window (2 weeks to 1 month old).

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`, `Billing.WithdrawToFunding.CashoutStatusID`, `Billing.WithdrawToFunding.ModificationDate`

**Rules**:
- Default window: `ModificationDate < DATEADD(WEEK, -2, GETUTCDATE())` AND `ModificationDate > DATEADD(MONTH, -1, GETDATE())`
- Lower bound (older than 2 weeks): records modified less recently than 2 weeks ago are "stuck"
- Upper bound (newer than 1 month): limits scope to the recent month, excluding records that have already been identified or resolved
- Window can be overridden by passing explicit @FromDate / @ToDate for targeted investigation
- Only CashoutStatusID=10 (SentToProvider) records are included - this is a non-final intermediate state per the `Dictionary.CashoutStatus` state machine

**Diagram**:
```
Timeline:
  [1 month ago]  [2 weeks ago]       [now]
       |               |                |
       |<--- window -->|   (excluded)   |
       |               |
  ModificationDate > 1mo  AND  ModificationDate < 2w
  AND CashoutStatusID = 10 (SentToProvider)
          |
   COUNT(*) = [value]
   STRING_AGG(WithdrawID) = [List]
```

### 2.2 Numeric Alert Output (vs. Boolean in DD_CashoutSentToProvider)

**What**: Returns the actual count of stuck records (not just 0/1), enabling DataDog to monitor trends over time.

**Rules**:
- `value` = COUNT(*) of matching records. Zero means no stuck cashouts; any positive number means an issue.
- DataDog can use this count to trigger threshold-based alerts (e.g., alert if > 5 stuck cashouts) AND to plot metrics
- `List` = comma-separated WithdrawIDs for all matching records, enabling rapid identification
- If no records match, `value=0` and `List=NULL`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | YES | NULL (2 weeks ago) | CODE-BACKED | Upper boundary for ModificationDate filter (records must be older than this). When NULL, defaults to DATEADD(WEEK, -2, GETUTCDATE()) - i.e., identifies cashouts stuck for more than 2 weeks. Override for targeted investigation of a specific window. |
| 2 | @ToDate | DATETIME | YES | NULL (1 month ago) | CODE-BACKED | Lower boundary for ModificationDate filter (records must be newer than this). When NULL, defaults to DATEADD(MONTH, -1, GETDATE()) - limits scope to the past month. Override to expand or contract the detection window. |
| 3 | value (output) | INT | NO | - | CODE-BACKED | Count of withdrawal payment legs stuck in CashoutStatusID=10 (SentToProvider) within the detection window. Zero means no stalled cashouts. DataDog plots this as a metric and can alert on threshold breaches. |
| 4 | List (output) | VARCHAR | YES | - | CODE-BACKED | Comma-separated string of WithdrawID values for all stalled records. Enables the payments team to identify and investigate specific transactions. NULL when value=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CashoutStatusID=10 | Billing.WithdrawToFunding | Read | Reads WithdrawToFunding filtering on CashoutStatusID=10 (SentToProvider) and ModificationDate. See [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_Alert_CashoutSentToProvider (procedure)
└── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Direct read; filters on CashoutStatusID=10 and ModificationDate to identify stalled withdrawal payment legs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule; uses value as a numeric metric for trend monitoring and alerting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run with default 2-week detection window

```sql
EXEC Billing.DD_Alert_CashoutSentToProvider;
```

### 8.2 Check a specific custom date range

```sql
EXEC Billing.DD_Alert_CashoutSentToProvider
    @FromDate = '2026-02-01',
    @ToDate = '2026-01-01';
```

### 8.3 Investigate individual stuck cashouts returned in the alert

```sql
SELECT wtf.WithdrawID,
       wtf.CashoutStatusID,
       wtf.ModificationDate,
       wtf.FundingID,
       wtf.Amount,
       wtf.CashoutTypeID
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.CashoutStatusID = 10
  AND wtf.ModificationDate < DATEADD(WEEK, -2, GETUTCDATE())
  AND wtf.ModificationDate > DATEADD(MONTH, -1, GETDATE())
ORDER BY wtf.ModificationDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_Alert_CashoutSentToProvider | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_Alert_CashoutSentToProvider.sql*
