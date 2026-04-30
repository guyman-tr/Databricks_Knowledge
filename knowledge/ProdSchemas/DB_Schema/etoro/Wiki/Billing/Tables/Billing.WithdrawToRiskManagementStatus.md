# Billing.WithdrawToRiskManagementStatus

> Audit table recording which risk management rules were evaluated (and whether each fired) for each withdrawal request, written by the Withdrawal Service as part of the risk assessment flow.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (WithdrawID, RiskManagementStatusID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on WithdrawID + RiskManagementStatusID) |

---

## 1. Business Meaning

Billing.WithdrawToRiskManagementStatus is the risk rule audit trail for withdrawal requests. Each row records one risk check result for one withdrawal: the withdrawal ID, which risk rule was evaluated (RiskManagementStatusID), and whether that rule was triggered (IsTriggered). Together, all rows for a given WithdrawID form the complete risk assessment record for that withdrawal.

This table exists to provide full auditability of the withdrawal risk engine's decisions. When a withdrawal is approved or declined, compliance teams, support agents, and automated systems can query this table to see exactly which rules fired - whether the customer triggered a velocity limit, failed a KYC check, had a blocked funding instrument, or passed all checks cleanly (Success). Without this audit trail, there is no post-hoc visibility into why a withdrawal was held or declined.

Data is written by the Withdrawal Service (application layer) via `Billing.WithdrawalService_RiskManagementStatus_Add`: when a customer submits a withdrawal request, the service evaluates all applicable risk rules in parallel, then bulk-inserts the full result set (using the TVP type `Billing.WithdrawRiskManagementResult`) in a single procedure call. One call = one withdrawal = N rows inserted (one per rule evaluated).

---

## 2. Business Logic

### 2.1 Risk Rule Evaluation Recording

**What**: Records the outcome of each risk management rule evaluated for a withdrawal request, creating a complete per-withdrawal audit trail.

**Columns/Parameters Involved**: `WithdrawID`, `RiskManagementStatusID`, `IsTriggered`

**Rules**:
- Every withdrawal that goes through the risk assessment process will have multiple rows in this table - one per rule evaluated.
- `IsTriggered = 1` means the rule fired (the condition was met - e.g., velocity limit exceeded, KYC not passed). This may or may not block the withdrawal depending on rule configuration in `Billing.RiskManagementConfiguration`.
- `IsTriggered = 0` means the rule was evaluated and the withdrawal passed that check.
- `RiskManagementStatusID = 1` (Success) with `IsTriggered = 1` typically indicates the withdrawal passed all checks.

**Diagram**:
```
Customer submits withdrawal
         |
Withdrawal Service evaluates rules:
  RiskManagementStatusID=4 (MemberLimit)     -> IsTriggered=0 (passed)
  RiskManagementStatusID=12 (OverTheLimit)   -> IsTriggered=0 (passed)
  RiskManagementStatusID=18 (LoginToRegCountryConflict) -> IsTriggered=1 (FIRED!)
  RiskManagementStatusID=1 (Success)         -> IsTriggered=0 (overall: blocked)
         |
Bulk insert all results via WithdrawRiskManagementResult TVP
-> WithdrawalService_RiskManagementStatus_Add inserts into this table
```

### 2.2 Risk Rule Taxonomy (Dictionary.RiskManagementStatus)

**What**: The 69 risk rule types cover four broad categories of withdrawal risk.

**Columns/Parameters Involved**: `RiskManagementStatusID`

**Rules**:
- **Account block rules (2-19)**: Specific instrument or account type is blocked (CardIsBlocked, BlockedPayPalAccount, BlockedMoneyBookersAccount, etc.)
- **Limit/velocity rules (12, 20, 22, 26-29, 50-51, 54)**: Transaction amounts or frequencies exceed configured thresholds (OverTheLimit, CreditCardVelocity, UserVelocity, FundingTypeVelocity, etc.)
- **KYC/compliance rules (32-35, 37, 41, 43-46)**: Customer has not completed required identity verification levels (KYCLevel0-3, FcaPendingVerification, AsicNoSuitabilityTest)
- **Fraud/AML rules (10-11, 18, 21, 25, 47-49, 58, 62-69)**: Geographic conflicts, fraud signals, money laundering indicators (DeclinedBlackListCountry, LoginToRegCountryConflict, ML, SiftWorkFlow, BusinessRuleRisk, etc.)

---

## 3. Data Overview

The table is empty in the current environment (0 rows). This may indicate data has been archived or the environment is a non-production instance. Logical data example based on procedure and UDT analysis:

| WithdrawID | RiskManagementStatusID | IsTriggered | Meaning |
|-----------|----------------------|-------------|---------|
| 1234567 | 4 (MemberLimit) | 0 | Withdrawal passed the member-level daily/monthly limit check. |
| 1234567 | 18 (LoginToRegCountryConflict) | 1 | Rule fired - customer's login IP country differs from registration country, flagging potential fraud. |
| 1234567 | 12 (OverTheLimit) | 0 | Withdrawal amount is within the absolute limit for this funding type. |
| 1234567 | 1 (Success) | 0 | Overall assessment: not successful - at least one blocking rule fired. |
| 9876543 | 1 (Success) | 1 | All risk rules passed for this withdrawal - cleared for processing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | Foreign key to Billing.Withdraw (WithdrawID). Identifies the withdrawal request being risk-assessed. Groups all risk rule results for one withdrawal. Inherited from `Billing.WithdrawRiskManagementResult` TVP via `WithdrawalService_RiskManagementStatus_Add`. |
| 2 | RiskManagementStatusID | int | NO | - | CODE-BACKED | Identifies the specific risk rule evaluated. FK (implicit) to Dictionary.RiskManagementStatus (69 values). Key values: 1=Success, 2=CardIsBlocked, 4=MemberLimit, 10=DeclinedBlackListCountry, 12=OverTheLimit, 18=LoginToRegCountryConflict, 27=UserVelocity, 32-35=KYCLevel0-3, 47=ML, 67=SiftWorkFlow, 69=BusinessRuleRisk. Full list in Dictionary.RiskManagementStatus. |
| 3 | IsTriggered | bit | NO | - | CODE-BACKED | Whether this risk rule fired for the withdrawal. 1=rule triggered (condition met - potential risk detected), 0=rule evaluated and withdrawal passed this check. A value of 1 on RiskManagementStatusID=1 (Success) means all checks passed overall; a value of 0 on Success combined with any other triggered rule indicates the withdrawal was flagged. Sourced from `IsTriggered` column in `Billing.WithdrawRiskManagementResult` TVP. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit | Links risk rule results back to the parent withdrawal request. |
| RiskManagementStatusID | Dictionary.RiskManagementStatus | Implicit | Resolves the numeric rule ID to the rule name (Success, CardIsBlocked, KYCLevel1, etc.). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawalService_RiskManagementStatus_Add | @WithdrawID, @RiskManagementStatuses | Writer | Bulk-inserts risk rule evaluation results from the WithdrawRiskManagementResult TVP after the Withdrawal Service completes risk assessment. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (table with no computed columns or FK constraints).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawalService_RiskManagementStatus_Add | Stored Procedure | Writer - bulk-inserts rows from the WithdrawRiskManagementResult TVP for one withdrawal. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingWithdrawToRiskManagementStatus | CLUSTERED PK | WithdrawID ASC, RiskManagementStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingWithdrawToRiskManagementStatus | PRIMARY KEY | Enforces that each (WithdrawID, RiskManagementStatusID) combination is unique - one row per rule per withdrawal. Prevents duplicate risk check records for the same withdrawal/rule pair. |

---

## 8. Sample Queries

### 8.1 Get all risk rule results for a specific withdrawal

```sql
SELECT
    w.WithdrawID,
    rms.Name AS RuleName,
    w.IsTriggered
FROM Billing.WithdrawToRiskManagementStatus w WITH (NOLOCK)
JOIN Dictionary.RiskManagementStatus rms WITH (NOLOCK) ON rms.RiskManagementStatusID = w.RiskManagementStatusID
WHERE w.WithdrawID = 1234567
ORDER BY w.RiskManagementStatusID;
```

### 8.2 Find withdrawals that triggered a specific risk rule

```sql
SELECT TOP 100
    w.WithdrawID,
    wd.CID,
    wd.Amount,
    wd.CreateDate
FROM Billing.WithdrawToRiskManagementStatus w WITH (NOLOCK)
JOIN Billing.Withdraw wd WITH (NOLOCK) ON wd.WithdrawID = w.WithdrawID
WHERE w.RiskManagementStatusID = 18  -- LoginToRegCountryConflict
  AND w.IsTriggered = 1
ORDER BY wd.CreateDate DESC;
```

### 8.3 Summarize triggered rules across recent withdrawals

```sql
SELECT
    rms.Name AS RuleName,
    COUNT(*) AS TimesTriggered
FROM Billing.WithdrawToRiskManagementStatus w WITH (NOLOCK)
JOIN Dictionary.RiskManagementStatus rms WITH (NOLOCK) ON rms.RiskManagementStatusID = w.RiskManagementStatusID
WHERE w.IsTriggered = 1
GROUP BY rms.Name
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToRiskManagementStatus | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WithdrawToRiskManagementStatus.sql*
