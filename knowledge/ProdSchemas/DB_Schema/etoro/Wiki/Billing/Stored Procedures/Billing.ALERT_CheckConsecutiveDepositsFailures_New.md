# Billing.ALERT_CheckConsecutiveDepositsFailures_New

> Updated version of the consecutive deposit failures monitor that adds PaymentGeneration support (distinguishing old vs. new payment infrastructure), uses temp tables with clustered indexes for performance, and returns a result set instead of sending an email - acting as a probe SP rather than an emailer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxFailuresAllowedNew INT=NULL; returns result set with failure counts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ALERT_CheckConsecutiveDepositsFailures_New` is the successor to `Billing.ALERT_CheckConsecutiveDepositsFailures`, adding support for eToro's dual payment infrastructure. The billing system operates two payment generation pathways: the legacy system (PaymentGeneration=0) and the new generation system (PaymentGeneration=1). Each pathway may have different acceptable failure thresholds.

Key behavioral differences from the original version:

1. **PaymentGeneration awareness**: Splits analysis by `PaymentGeneration` (0=old, 1=new) so providers can be monitored separately per pathway.
2. **Configurable new-gen threshold**: @MaxFailuresAllowedNew overrides the threshold for new-generation failures; old-gen still uses `Billing.ConfigAlertForConsecutiveDepositFailures`.
3. **Returns result set instead of email**: This is a **probe** SP, not an alerter. The caller (application or SQL Agent job) decides what to do with the result set.
4. **Broader failure definition**: Excludes only PaymentStatusID=6 (rather than only including 0,1,2,5,7 as "success") - this means more statuses are treated as failures.
5. **Performance-optimized**: Uses indexed temp tables instead of CTEs alone.

---

## 2. Business Logic

### 2.1 PaymentGeneration-Split Failure Detection

**What**: Detects consecutive deposit failures split by old vs. new payment generation pathway.

**Columns/Parameters Involved**: `@MaxFailuresAllowedNew`, `PaymentGeneration`, `FundingTypeID`, `PaymentStatusID`, `DepositID`, `CID`

**Rules**:
- **Last success baseline**: MAX(DepositID) per (FundingTypeID, PaymentGeneration) where PaymentStatusID NOT IN (6) AND status represents success within the last 14 days.
- **Failure count**: COUNT(DISTINCT CID) with DepositID > last success DepositID, excluding PaymentStatusID=6 (cancelled/voided).
- **Old generation (PaymentGeneration=0)**: Threshold from `Billing.ConfigAlertForConsecutiveDepositFailures.Threshold`.
- **New generation (PaymentGeneration=1)**: Threshold from @MaxFailuresAllowedNew parameter (if NULL, defaults to table threshold or skips).
- Result set includes: FundingTypeID, PaymentGeneration, FailureCount, Threshold, ProviderName.
- **No email**: Returns result set directly. Caller handles alerting logic.

**Diagram**:
```
Billing.Deposit (last 14 days)
  |
  +-- Split by PaymentGeneration (0=old, 1=new)
  |
  v
Per (FundingTypeID, PaymentGeneration):
  LastSuccess = MAX(DepositID) where status != 6 (success approximation)
  FailureCount = COUNT(DISTINCT CID) where DepositID > LastSuccess AND status != 6
  |
  +-- PaymentGeneration=0: threshold from ConfigAlertForConsecutiveDepositFailures
  +-- PaymentGeneration=1: threshold from @MaxFailuresAllowedNew
  |
  v
Return result set: rows where FailureCount > Threshold
```

### 2.2 Failure Status Definition (Changed from Original)

Original SP uses `PaymentStatusID IN (0,1,2,5,7)` for success (whitelist approach).

This SP uses `PaymentStatusID NOT IN (6)` for non-cancelled (blacklist approach):
- PaymentStatusID=6: Cancelled/voided - excluded entirely from both success and failure counts.
- All other statuses (including 0,1,2,3,4,5,7,...) can be either baseline-setters or failure contributors.

This wider inclusion means more status codes contribute to the consecutive failure count compared to the original.

### 2.3 Indexed Temp Tables for Performance

Uses indexed temp tables (vs. CTEs in the original):
```sql
CREATE TABLE #LastSuccess (FundingTypeID INT, PaymentGeneration BIT, LastSuccessDepositID BIGINT)
CREATE CLUSTERED INDEX IX_#LastSuccess ON #LastSuccess (FundingTypeID, PaymentGeneration)
```
This pattern improves performance when Billing.Deposit is large (multi-million rows) by enabling indexed seeks in the failure count join.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxFailuresAllowedNew | INT | YES | NULL | CODE-BACKED | Threshold for new-generation payment pathway (PaymentGeneration=1). If NULL: uses the threshold from Billing.ConfigAlertForConsecutiveDepositFailures (same as old-gen). If provided: overrides the config threshold for new-gen providers only. Allows tuning new-gen alerting independently without changing the config table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Success baseline + failure count | Billing.Deposit | READER | Source of DepositID, PaymentStatusID, PaymentGeneration, FundingTypeID, CID |
| Old-gen threshold | Billing.ConfigAlertForConsecutiveDepositFailures | READER | Per-provider threshold for PaymentGeneration=0 failures |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT. Called by application monitoring service or SQL Agent job that handles result-set-based alerting logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ALERT_CheckConsecutiveDepositsFailures_New (procedure)
|- Billing.Deposit (table) [leaf - failure analysis source]
|- Billing.ConfigAlertForConsecutiveDepositFailures (table) [leaf - old-gen threshold]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Source of DepositID, FundingTypeID, PaymentGeneration, PaymentStatusID, CID |
| Billing.ConfigAlertForConsecutiveDepositFailures | Table | Per-provider threshold for old-generation (PaymentGeneration=0) failures |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses internal clustered temp table indexes for performance.

### 7.2 Constraints

No SET NOCOUNT. Returns result set (not email). @MaxFailuresAllowedNew defaults to NULL (falls back to config table). PaymentStatusID=6 excluded from both success and failure. 14-day lookback hardcoded. The PaymentGeneration split requires the Billing.Deposit table to have a `PaymentGeneration` column (BIT).

**Comparison with original**:
| Aspect | Original | New |
|--------|----------|-----|
| Output | HTML email | Result set |
| PaymentGeneration | Not split | Split (0=old, 1=new) |
| New-gen threshold | N/A | @MaxFailuresAllowedNew |
| Success definition | IN (0,1,2,5,7) | NOT IN (6) |
| Performance | CTEs | Indexed temp tables |

---

## 8. Sample Queries

### 8.1 Run with default thresholds

```sql
EXEC Billing.ALERT_CheckConsecutiveDepositsFailures_New
    @MaxFailuresAllowedNew = NULL
```

### 8.2 Run with custom new-gen threshold

```sql
-- Alert if new payment generation has >= 3 consecutive failures per provider
EXEC Billing.ALERT_CheckConsecutiveDepositsFailures_New
    @MaxFailuresAllowedNew = 3
```

### 8.3 Check old vs new generation deposit failure counts manually

```sql
SELECT
    d.FundingTypeID,
    d.PaymentGeneration,
    COUNT(DISTINCT d.CID) AS UniqueFailingCIDs,
    COUNT(*) AS TotalFailures
FROM Billing.Deposit WITH (NOLOCK) AS d
WHERE d.PaymentStatusID NOT IN (6)
  AND d.CreationDate >= DATEADD(DAY, -14, GETUTCDATE())
GROUP BY d.FundingTypeID, d.PaymentGeneration
ORDER BY UniqueFailingCIDs DESC
```

### 8.4 Check config thresholds

```sql
SELECT
    cfg.FundingTypeID,
    cfg.Threshold,
    cfg.IsActive
FROM Billing.ConfigAlertForConsecutiveDepositFailures WITH (NOLOCK) AS cfg
WHERE cfg.IsActive = 1
ORDER BY cfg.FundingTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ALERT_CheckConsecutiveDepositsFailures_New | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ALERT_CheckConsecutiveDepositsFailures_New.sql*
