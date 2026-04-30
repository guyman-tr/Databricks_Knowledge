# Billing.ALERT_CheckConsecutiveDepositsFailures

> Monitoring stored procedure that detects payment providers experiencing consecutive deposit failures (CIDs failing after the provider's last success) and sends an HTML alert email to PagerDuty and NOC if any provider exceeds its configured failure threshold.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; alert fires via email only |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ALERT_CheckConsecutiveDepositsFailures` is a proactive monitoring procedure that identifies payment providers degrading into a consecutive failure pattern. "Consecutive failures" means: after the last known successful deposit attempt through a given provider (FundingTypeID), how many distinct customers have subsequently failed? If that count exceeds the provider-specific threshold defined in `Billing.ConfigAlertForConsecutiveDepositFailures`, the system fires an alert.

The procedure looks back 14 days for the last success baseline and counts failures after that point. This approach catches providers that may have a high absolute failure count but were recently working (i.e., not degraded) vs. providers that have been failing without any success since a distant point in the past.

Alert recipients: `billing-services-production@etoro.pagerduty.com` and `noc-isr@etoro.com`. The email is only sent if at least one provider exceeds its threshold - silent execution on healthy days.

This is the **original version**. See `Billing.ALERT_CheckConsecutiveDepositsFailures_New` for the updated version that also covers the new payment generation infrastructure.

---

## 2. Business Logic

### 2.1 Consecutive Failure Detection Algorithm

**What**: Two-CTE pipeline computing per-provider consecutive failure counts since last success.

**Columns/Parameters Involved**: `FundingTypeID`, `PaymentStatusID`, `DepositID`, `CID`

**Rules**:
- **CTE LastSuccess**: For each FundingTypeID, finds the MAX(DepositID) where PaymentStatusID IN (0, 1, 2, 5, 7) within the last 14 days. PaymentStatusIDs 0,1,2,5,7 represent non-failed outcomes (pending, processing, approved, etc.).
- **CTE NumOfConsecutivesFailures**: Counts distinct CIDs that have at least one deposit with DepositID GREATER THAN the LastSuccess DepositID for that FundingTypeID. These are customers who attempted the provider AFTER the last success - implying the failures are consecutive (no success has occurred since).
- Results stored in temp table `#T` joined with `Billing.ConfigAlertForConsecutiveDepositFailures` to apply per-provider threshold.
- Only providers where `COUNT > Threshold` are kept in `#T`.
- `IF EXISTS (SELECT 1 FROM #T)`: email is sent ONLY if at least one provider exceeds threshold.

**Diagram**:
```
Billing.Deposit (last 14 days)
  |
  v
CTE LastSuccess: MAX(DepositID) per FundingTypeID where PaymentStatus = success
  |
  v
CTE NumOfConsecutiveFailures: COUNT(DISTINCT CID) where DepositID > last success DepositID
  |
  v
JOIN ConfigAlertForConsecutiveDepositFailures -> filter where count > threshold
  |
  v
IF EXISTS(#T) -> send HTML email to PagerDuty + NOC-ISR
  ELSE        -> silent exit (no alert, no result set)
```

### 2.2 Success Status Set

PaymentStatusID values treated as "success" (baseline reset):
- 0: Pending (not a failure)
- 1: Processing
- 2: Approved (confirmed success)
- 5: (provider-specific success variant)
- 7: (provider-specific success variant)

Any status NOT in this set contributes to the failure count if it occurs after the last success DepositID.

### 2.3 Email Output

HTML table email with per-provider consecutive failure counts vs. threshold, sent to:
- `billing-services-production@etoro.pagerduty.com` (PagerDuty integration)
- `noc-isr@etoro.com` (NOC on-call)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no parameters) | - | - | - | - | CODE-BACKED | Procedure takes no parameters. The 14-day lookback window and per-provider thresholds are configured in Billing.ConfigAlertForConsecutiveDepositFailures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Success baseline | Billing.Deposit | READER | Reads DepositID and PaymentStatusID for last 14 days to compute last success per provider |
| Threshold config | Billing.ConfigAlertForConsecutiveDepositFailures | READER | Per-provider alert threshold; joined to filter providers over threshold |
| Email dispatch | msdb.dbo.sp_send_dbmail | CALLER | Sends HTML alert email to PagerDuty and NOC recipients |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT. Invoked by a SQL Agent job or external scheduler on a recurring basis (likely every 15-60 minutes for production monitoring).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ALERT_CheckConsecutiveDepositsFailures (procedure)
|- Billing.Deposit (table) [leaf - success baseline query]
|- Billing.ConfigAlertForConsecutiveDepositFailures (table) [leaf - threshold config]
|- msdb.dbo.sp_send_dbmail (system SP) [email dispatch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Source of DepositID, FundingTypeID, PaymentStatusID, CID for consecutive failure analysis |
| Billing.ConfigAlertForConsecutiveDepositFailures | Table | Per-FundingTypeID alert threshold configuration |
| msdb.dbo.sp_send_dbmail | System SP | HTML email dispatch to PagerDuty and NOC |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

No SET NOCOUNT. Uses temp table `#T` to hold over-threshold results. The `IF EXISTS` gate ensures zero emails on healthy runs. 14-day lookback is hardcoded. No transaction wrapping. The success PaymentStatusID set (0,1,2,5,7) is hardcoded.

**Design note**: Using MAX(DepositID) as the "last success" proxy rather than a timestamp assumes DepositID is monotonically increasing (which is typical for IDENTITY columns). If DepositID is not strictly ordered by time, this assumption could produce incorrect baselines.

---

## 8. Sample Queries

### 8.1 Manually compute consecutive failures (replicate CTE logic)

```sql
WITH LastSuccess AS (
    SELECT
        d.FundingTypeID,
        MAX(d.DepositID) AS LastSuccessDepositID
    FROM Billing.Deposit WITH (NOLOCK) AS d
    WHERE d.PaymentStatusID IN (0, 1, 2, 5, 7)
      AND d.CreationDate >= DATEADD(DAY, -14, GETUTCDATE())
    GROUP BY d.FundingTypeID
),
NumOfConsecutiveFailures AS (
    SELECT
        d.FundingTypeID,
        COUNT(DISTINCT d.CID) AS FailureCount
    FROM Billing.Deposit WITH (NOLOCK) AS d
    INNER JOIN LastSuccess AS ls ON ls.FundingTypeID = d.FundingTypeID
    WHERE d.DepositID > ls.LastSuccessDepositID
      AND d.PaymentStatusID NOT IN (0, 1, 2, 5, 7)
    GROUP BY d.FundingTypeID
)
SELECT
    ncf.FundingTypeID,
    ncf.FailureCount,
    cfg.Threshold,
    ls.LastSuccessDepositID
FROM NumOfConsecutiveFailures AS ncf
INNER JOIN Billing.ConfigAlertForConsecutiveDepositFailures WITH (NOLOCK) AS cfg
    ON cfg.FundingTypeID = ncf.FundingTypeID
INNER JOIN LastSuccess AS ls ON ls.FundingTypeID = ncf.FundingTypeID
ORDER BY ncf.FailureCount DESC
```

### 8.2 View per-provider thresholds

```sql
SELECT
    cfg.FundingTypeID,
    cfg.Threshold,
    cfg.IsActive
FROM Billing.ConfigAlertForConsecutiveDepositFailures WITH (NOLOCK) AS cfg
ORDER BY cfg.FundingTypeID
```

### 8.3 Current providers with consecutive failures (quick check)

```sql
SELECT
    d.FundingTypeID,
    COUNT(DISTINCT d.CID) AS CIDsFailingConsecutively
FROM Billing.Deposit WITH (NOLOCK) AS d
WHERE d.PaymentStatusID NOT IN (0, 1, 2, 5, 7)
  AND d.CreationDate >= DATEADD(DAY, -1, GETUTCDATE())
GROUP BY d.FundingTypeID
ORDER BY CIDsFailingConsecutively DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ALERT_CheckConsecutiveDepositsFailures | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ALERT_CheckConsecutiveDepositsFailures.sql*
