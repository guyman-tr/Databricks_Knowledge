# Billing.WithdrawRiskManagementResult

> Table-valued parameter type carrying risk management rule evaluation results for a withdrawal, passed to `Billing.WithdrawalService_RiskManagementStatus_Add` to bulk-insert into `Billing.WithdrawToRiskManagementStatus`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | WithdrawRiskManagementStatusID (risk rule identifier) |
| **Partition** | N/A |
| **Indexes** | N/A - inline table type, no persistent indexes |

---

## 1. Business Meaning

`Billing.WithdrawRiskManagementResult` is a table-valued parameter (TVP) type that carries the results of risk management rule evaluations for a single withdrawal request. Each row represents one risk rule (identified by `WithdrawRiskManagementStatusID`) and whether that rule was triggered (`IsTriggered`) for the withdrawal being assessed.

This type exists to enable bulk insertion of risk check results: the application-side risk engine evaluates all applicable rules for a withdrawal in parallel, then passes the full result set to `Billing.WithdrawalService_RiskManagementStatus_Add` in a single call, which bulk-inserts them into `Billing.WithdrawToRiskManagementStatus`.

Data flows from the Withdrawal Service: when a customer submits a withdrawal request, the service runs it through a set of risk management checks (AML rules, fraud detection, velocity limits, etc.), aggregates the results as `WithdrawRiskManagementResult` rows, and persists them by calling `WithdrawalService_RiskManagementStatus_Add @WithdrawID, @RiskManagementStatuses`.

---

## 2. Business Logic

### 2.1 Risk Rule Evaluation Recording

**What**: Records which risk management rules fired (IsTriggered=1) and which passed (IsTriggered=0) for a specific withdrawal, providing a complete audit trail of the risk assessment.

**Columns/Parameters Involved**: `WithdrawRiskManagementStatusID`, `IsTriggered`

**Rules**:
- One row per risk rule evaluated
- `IsTriggered=1` means the rule detected a risk condition that may block or flag the withdrawal
- `IsTriggered=0` means the rule was evaluated but no risk was detected (the check passed)
- The consuming SP inserts all rows for `@WithdrawID` into `Billing.WithdrawToRiskManagementStatus`
- The full risk picture = all rows where `WithdrawID = @WithdrawID` (both triggered and not)

**Diagram**:
```
Withdrawal Service evaluates rules:
  Rule 1 (Velocity check)         -> IsTriggered=0 (passed)
  Rule 2 (Amount threshold)       -> IsTriggered=1 (FLAGGED)
  Rule 3 (High-risk country)      -> IsTriggered=0 (passed)
  Rule 4 (New account + large amt)-> IsTriggered=1 (FLAGGED)

EXEC Billing.WithdrawalService_RiskManagementStatus_Add
    @WithdrawID = 12345,
    @RiskManagementStatuses = {the TVP with 4 rows}

-> INSERT INTO Billing.WithdrawToRiskManagementStatus:
   (12345, 1, 0), (12345, 2, 1), (12345, 3, 0), (12345, 4, 1)
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawRiskManagementStatusID | int | NO | - | CODE-BACKED | Identifier of the risk management rule or check being evaluated. Inserted as `RiskManagementStatusID` into `Billing.WithdrawToRiskManagementStatus`. References the risk rule catalog in the application. |
| 2 | IsTriggered | bit | NO | - | CODE-BACKED | Whether this risk rule detected a risk condition for the withdrawal: 1 = rule triggered (risk detected, may block or flag the withdrawal); 0 = rule passed (no risk detected). Inserted directly into `Billing.WithdrawToRiskManagementStatus.IsTriggered`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawRiskManagementStatusID | Billing.WithdrawToRiskManagementStatus | Implicit | Stored as RiskManagementStatusID in the target table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawalService_RiskManagementStatus_Add | @RiskManagementStatuses | TVP Parameter | Sole consumer - bulk-inserts all rows into Billing.WithdrawToRiskManagementStatus |
| Billing.WithdrawToFundingProcess | (referenced) | Related | WithdrawToFundingProcess also reads WithdrawToRiskManagementStatus implicitly through the risk check flow |
| Billing.WithdrawToFundingProcess_v2 | (referenced) | Related | V2 variant also reads risk management results |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawalService_RiskManagementStatus_Add | Stored Procedure | Receives as READONLY TVP; inserts all rows into Billing.WithdrawToRiskManagementStatus for the given WithdrawID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View risk management check results for a withdrawal

```sql
SELECT
    w.WithdrawID,
    wtrms.RiskManagementStatusID,
    wtrms.IsTriggered,
    w.CashoutStatusID,
    w.RequestDate
FROM Billing.WithdrawToRiskManagementStatus wtrms WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON w.WithdrawID = wtrms.WithdrawID
-- WHERE wtrms.WithdrawID = @WithdrawID
ORDER BY wtrms.WithdrawID, wtrms.RiskManagementStatusID
```

### 8.2 Count triggered risk rules per withdrawal

```sql
SELECT TOP 20
    WithdrawID,
    COUNT(*) AS TotalRulesEvaluated,
    SUM(CAST(IsTriggered AS INT)) AS TriggeredCount,
    COUNT(*) - SUM(CAST(IsTriggered AS INT)) AS PassedCount
FROM Billing.WithdrawToRiskManagementStatus WITH (NOLOCK)
GROUP BY WithdrawID
HAVING SUM(CAST(IsTriggered AS INT)) > 0
ORDER BY TriggeredCount DESC
```

### 8.3 Find which risk rules are most frequently triggered

```sql
SELECT
    RiskManagementStatusID,
    COUNT(*) AS TotalEvaluations,
    SUM(CAST(IsTriggered AS INT)) AS TriggerCount,
    CAST(100.0 * SUM(CAST(IsTriggered AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS TriggerRate_Pct
FROM Billing.WithdrawToRiskManagementStatus WITH (NOLOCK)
GROUP BY RiskManagementStatusID
ORDER BY TriggerRate_Pct DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawRiskManagementResult | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.WithdrawRiskManagementResult.sql*
