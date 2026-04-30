# Billing.CheckPayoutStatus

> Returns the count of withdrawal records in Billing.WithdrawToFunding that match a specific depot and cashout status and are older than 2 hours (as a stuck/stale payout health check); defaults to DepotID=92 and CashoutStatusID=11.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN @@ERROR; result set with single count column |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CheckPayoutStatus` is an operational health check procedure that detects stalled or stuck payout records. It counts records in `Billing.WithdrawToFunding` that:
1. Are associated with a specific payment depot (DepotID=92 by default)
2. Have a specific cashout status (CashoutStatusID=11 by default - likely "In Processing" or "Pending at Provider")
3. Have not been updated for more than 2 hours (`ModificationDate < GETUTCDATE() - 2 hours`)

A non-zero count indicates payouts that have been stuck in a processing state for too long, suggesting a potential integration failure with the payment provider. This procedure is used by monitoring/alerting systems to detect and alert on payout processing delays.

---

## 2. Business Logic

### 2.1 Stale Payout Count

**What**: Counts WithdrawToFunding records stuck in a given status for more than 2 hours.

**Rules**:
- `SELECT COUNT(*) FROM Billing.WithdrawToFunding WITH (NOLOCK) WHERE DepotID = @DepotID AND CashoutStatusID = @CashoutStatusID AND ModificationDate < DATEADD(HOUR, -2, GETUTCDATE())`
- Uses GETUTCDATE() (not GETDATE()) - all time comparisons are in UTC.
- WITH (NOLOCK) - monitoring read; does not block operational writes.
- Returns the count as a result set.
- RETURN @@ERROR.

**Count Interpretation**:
| Count | Meaning |
|-------|---------|
| 0 | All payouts for this depot/status have been updated within 2 hours - healthy |
| > 0 | N payouts are stuck (not updated for 2+ hours) - operational alert warranted |

**Defaults**:
- @DepotID = 92: The default payment depot (likely a specific payment provider's depot in Billing.Depot)
- @CashoutStatusID = 11: The specific status being monitored (likely "In Processing at Provider" or equivalent pending state)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepotID | INTEGER | YES | 92 | CODE-BACKED | The payment depot (provider/gateway) to check. Defaults to 92, which is the primary monitored depot. References a depot/provider record in Billing.Depot or equivalent. Allows overriding to check other depots if needed. |
| 2 | @CashoutStatusID | INTEGER | YES | 11 | CODE-BACKED | The withdrawal status to monitor for staleness. Defaults to 11, which is a processing/pending state where records are expected to be updated within 2 hours. If a record remains in this status beyond the threshold, it is considered stuck. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepotID + @CashoutStatusID | Billing.WithdrawToFunding | READER | COUNT of stuck records (status=@CashoutStatusID, modified >2h ago, for @DepotID) |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from monitoring/alerting systems or operational health check scripts.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CheckPayoutStatus (procedure)
+-- Billing.WithdrawToFunding (table)   [READ - COUNT of stale records for depot+status+age filter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | READ - counts payout records matching DepotID, CashoutStatusID, and >2h staleness |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **UTC time comparison**: Uses GETUTCDATE() for the 2-hour threshold. ModificationDate in Billing.WithdrawToFunding must also be stored in UTC for this to be correct. This is consistent with eToro's standard of storing timestamps in UTC.
- **NOLOCK for monitoring**: WITH (NOLOCK) prevents the monitoring check from blocking payment processing writes. Monitoring reads don't need transaction consistency.
- **Default parameters**: Both parameters have defaults (@DepotID=92, @CashoutStatusID=11), making this callable without arguments for the standard monitoring case: `EXEC Billing.CheckPayoutStatus`.
- **2-hour threshold**: The hardcoded 2-hour staleness threshold represents the SLA for a payout to be updated by the payment provider integration. Payouts not updated within this window are considered stuck and need investigation.
- **Monitoring pattern**: This is a health check/monitoring procedure, not a transactional business procedure. It reads only (no writes) and is designed to be called frequently by automated systems.
- **WithdrawToFunding vs Cashout**: Operates on the modern `Billing.WithdrawToFunding` table (linked to `Billing.Withdraw` with 1.66M rows), not the legacy `Billing.Cashout` system.

---

## 8. Sample Queries

### 8.1 Check payout status with defaults
```sql
EXEC Billing.CheckPayoutStatus;
-- Returns count of stuck payouts for DepotID=92, CashoutStatusID=11, older than 2 hours
```

### 8.2 Check a specific depot and status
```sql
EXEC Billing.CheckPayoutStatus
    @DepotID        = 105,
    @CashoutStatusID = 11;
```

### 8.3 Direct query to see the stuck payouts
```sql
SELECT WithdrawToFundingID, DepotID, CashoutStatusID, ModificationDate,
       DATEDIFF(MINUTE, ModificationDate, GETUTCDATE()) AS MinutesStuck
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE DepotID = 92
  AND CashoutStatusID = 11
  AND ModificationDate < DATEADD(HOUR, -2, GETUTCDATE())
ORDER BY ModificationDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 8.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CheckPayoutStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CheckPayoutStatus.sql*
