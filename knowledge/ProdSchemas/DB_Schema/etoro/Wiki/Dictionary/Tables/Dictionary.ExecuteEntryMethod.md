# Dictionary.ExecuteEntryMethod

## 1. Business Meaning

### What It Is
A lookup table defining how a withdrawal-to-funding (payout) request was processed — whether it was executed automatically by the system, manually by an operator, or has a manually-updated/special status.

### Why It Exists
The payout system can process withdrawal requests through different execution channels: automated processing, manual operator intervention, or initial manual setup. Tracking the execution method enables audit trails, operational reporting, and reconciliation between auto-processed and manually-handled payouts.

### How It's Used
Referenced by `Billing.WithdrawToFunding.ExecuteEntryMethodID` which tracks how each payout request was executed. Set during payout processing by procedures like `Billing.UpdateRequestExecuteEntryMethod`, `Billing.PayoutProcess_FinalizeRequest`, `Billing.WithdrawToFundingProcess`, and read by BackOffice reporting procedures.

---

## 2. Business Logic

### Execution Methods

| ID | Name | DisplayName | Meaning |
|----|------|-------------|---------|
| 0 | None | Manually Updated | Default/initial state, or manually updated outside normal flow |
| 1 | Auto | Auto Execute | System processed the payout automatically |
| 2 | Manual | Manual Execute | Operator manually processed the payout |

### Payout Processing Flow
```
Request Created (ExecuteEntryMethodID = 0, "None")
        │
        ├── Auto-processing → ExecuteEntryMethodID = 1 ("Auto Execute")
        │
        └── Manual processing → ExecuteEntryMethodID = 2 ("Manual Execute")
```

---

## 3. Data Overview

| ExecuteEntryMethodID | Name | DisplayName |
|---------------------|------|-------------|
| 0 | None | Manually Updated |
| 1 | Auto | Auto Execute |
| 2 | Manual | Manual Execute |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **ExecuteEntryMethodID** | `int` | NO | Entry method identifier (0=None/Manual Update, 1=Auto, 2=Manual). No PK constraint. | `MCP` |
| **Name** | `varchar(255)` | NO | Short code name (None, Auto, Manual). | `MCP` |
| **DisplayName** | `varchar(255)` | YES | User-facing display name (Manually Updated, Auto Execute, Manual Execute). | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | Relationship |
|-------|--------|-------------|
| Billing.WithdrawToFunding | ExecuteEntryMethodID | Implicit FK — how the payout request was processed |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `Billing.WithdrawToFunding` — stores execution method per payout request
- `Billing.vWithdrawToFunding` — view exposing payout data with execution method
- `Billing.UpdateRequestExecuteEntryMethod` — sets the execution method
- `Billing.PayoutProcess_FinalizeRequest` / `_v2` — finalizes payout with execution method
- `Billing.WithdrawToFundingProcess` / `ProcessBatch` — batch payout processing
- `Billing.InsertWithdraw2Funding` — creates payout requests
- `Billing.UpdateWithdraw2Funding` — updates payout records
- `Billing.WithdrawAndWithdrawToFundingAdd` — combined withdrawal + payout creation
- `Billing.WithdrawToFundingChangePaymentStatus` — status changes track method
- `BackOffice.GetProcessedWithdrawPCIVersion` — BackOffice payout reporting

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | None defined (heap table) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 3 |
| **Identity** | No |
| **Temporal** | No |

> **Note**: No PK constraint despite being a lookup table. The `ExecuteEntryMethodID` values (0, 1, 2) serve as de facto keys.

---

## 8. Sample Queries

```sql
-- Get all execution methods
SELECT  ExecuteEntryMethodID,
        Name,
        DisplayName
FROM    Dictionary.ExecuteEntryMethod WITH (NOLOCK)
ORDER BY ExecuteEntryMethodID;

-- Count payout requests by execution method
SELECT  em.DisplayName       AS ExecutionMethod,
        COUNT(*)             AS RequestCount
FROM    Billing.WithdrawToFunding wf WITH (NOLOCK)
JOIN    Dictionary.ExecuteEntryMethod em WITH (NOLOCK)
        ON wf.ExecuteEntryMethodID = em.ExecuteEntryMethodID
GROUP BY em.DisplayName
ORDER BY RequestCount DESC;

-- Find manually processed payouts
SELECT  wf.WithdrawToFundingID,
        wf.CustomerID
FROM    Billing.WithdrawToFunding wf WITH (NOLOCK)
WHERE   wf.ExecuteEntryMethodID = 2;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
