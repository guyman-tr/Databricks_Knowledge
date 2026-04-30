# Billing.WithdrawalService_RiskManagementStatus_Add

> Bulk-inserts the risk management rule evaluation results for a withdrawal request into the audit table, recording which rules were triggered and which passed.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID INT - the withdrawal whose risk results are being recorded |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the write endpoint for eToro's withdrawal risk assessment audit trail. When the Withdrawal Service evaluates a customer's withdrawal request against the risk rule engine, it collects all rule results (which rules fired, which passed) and persists them in a single bulk call to this procedure. The result is a complete, per-withdrawal audit record in `Billing.WithdrawToRiskManagementStatus` showing every risk rule that was evaluated.

The procedure exists to separate the risk audit write from the withdrawal creation flow. The application risk engine runs rule checks asynchronously or in parallel, builds a TVP of results using the `Billing.WithdrawRiskManagementResult` type, then calls this procedure once to write all results atomically. This is more efficient than inserting rows individually and ensures the audit record is complete or absent - never partial.

Compliance teams, fraud analysts, and support agents use the resulting `Billing.WithdrawToRiskManagementStatus` rows to understand why a withdrawal was held, flagged, or approved. The procedure itself is called exclusively from application code - no SQL callers were found in the SSDT repo.

---

## 2. Business Logic

### 2.1 TVP Bulk Insert into Risk Audit Table

**What**: Expands the TVP rows into the risk audit table, pairing each rule result with the target withdrawal ID.

**Columns/Parameters Involved**: `@WithdrawID`, `@RiskManagementStatuses` (TVP), `WithdrawRiskManagementStatusID`, `IsTriggered`

**Rules**:
- One INSERT statement covers all rows in the TVP - no looping
- Each TVP row maps: `WithdrawRiskManagementStatusID` -> `RiskManagementStatusID`; `IsTriggered` -> `IsTriggered`
- `@WithdrawID` is applied as a constant to every inserted row - all results belong to the same withdrawal
- The TVP is declared READONLY - the SP cannot modify the input
- No error handling beyond default SQL error propagation; any insert failure (e.g., duplicate PK) will surface to the caller

**Diagram**:
```
Application risk engine runs checks for WithdrawID=X:
  Rule 4  (MemberLimit)                -> IsTriggered=0
  Rule 12 (OverTheLimit)               -> IsTriggered=0
  Rule 18 (LoginToRegCountryConflict)  -> IsTriggered=1
  Rule 1  (Success)                    -> IsTriggered=0

@RiskManagementStatuses TVP (Billing.WithdrawRiskManagementResult):
  | WithdrawRiskManagementStatusID | IsTriggered |
  | 4                              | 0           |
  | 12                             | 0           |
  | 18                             | 1           |
  | 1                              | 0           |

EXEC WithdrawalService_RiskManagementStatus_Add @WithdrawID=X, @RiskManagementStatuses=TVP

-> INSERT INTO Billing.WithdrawToRiskManagementStatus:
  (X, 4, 0), (X, 12, 0), (X, 18, 1), (X, 1, 0)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | Input parameter. The withdrawal identifier whose risk results are being persisted. Applied as a constant to every row inserted from the TVP into Billing.WithdrawToRiskManagementStatus. |
| 2 | @RiskManagementStatuses | Billing.WithdrawRiskManagementResult | NO | - | CODE-BACKED | Input TVP (READONLY). Table-valued parameter carrying the risk rule evaluation results. Each row contains WithdrawRiskManagementStatusID (the rule ID) and IsTriggered (1=rule fired, 0=passed). All rows are bulk-inserted in a single operation. See [Billing.WithdrawRiskManagementResult](../User Defined Types/Billing.WithdrawRiskManagementResult.md). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RiskManagementStatuses | Billing.WithdrawRiskManagementResult | TVP Type | Input type defining the per-rule result structure (WithdrawRiskManagementStatusID, IsTriggered) |
| (INSERT target) | Billing.WithdrawToRiskManagementStatus | Write | Destination table for all risk rule results; one row per rule per withdrawal |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called exclusively from application code (Withdrawal Service).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawalService_RiskManagementStatus_Add (procedure)
├── Billing.WithdrawRiskManagementResult (type)
└── Billing.WithdrawToRiskManagementStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawRiskManagementResult | User Defined Type | READONLY TVP parameter type - defines the structure of the input risk results |
| Billing.WithdrawToRiskManagementStatus | Table | INSERT target - receives all risk rule evaluation rows for the given WithdrawID |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by Withdrawal Service application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure (application-style TVP call pattern)

```sql
-- Declare and populate the TVP
DECLARE @Results AS [Billing].[WithdrawRiskManagementResult];
INSERT INTO @Results (WithdrawRiskManagementStatusID, IsTriggered)
VALUES (1, 0), (4, 0), (12, 0), (18, 1);

EXEC Billing.WithdrawalService_RiskManagementStatus_Add
    @WithdrawID = 12345,
    @RiskManagementStatuses = @Results;
```

### 8.2 Verify results written for a specific withdrawal

```sql
SELECT  WithdrawID,
        RiskManagementStatusID,
        IsTriggered
FROM    Billing.WithdrawToRiskManagementStatus WITH (NOLOCK)
WHERE   WithdrawID = 12345
ORDER BY RiskManagementStatusID;
```

### 8.3 Find withdrawals with triggered risk rules (flagged withdrawals)

```sql
SELECT  wtrms.WithdrawID,
        COUNT(*) AS TotalRulesEvaluated,
        SUM(CAST(wtrms.IsTriggered AS INT)) AS TriggeredCount,
        w.CashoutStatusID,
        w.RequestDate
FROM    Billing.WithdrawToRiskManagementStatus wtrms WITH (NOLOCK)
JOIN    Billing.Withdraw w WITH (NOLOCK)
        ON w.WithdrawID = wtrms.WithdrawID
WHERE   wtrms.IsTriggered = 1
GROUP BY wtrms.WithdrawID, w.CashoutStatusID, w.RequestDate
ORDER BY w.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawalService_RiskManagementStatus_Add | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawalService_RiskManagementStatus_Add.sql*
