# Billing.UpdateRequestExecuteEntryMethod

> Batch-updates the request execution entry method on multiple WithdrawToFunding records, recording whether payment orders were triggered automatically or manually.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Ids (list of WithdrawToFunding IDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

In the payment processing pipeline, when a withdrawal is prepared and a payment order is ready for execution, a `ReadyForExecutionMessage` is published to the `ReadyForExecutionTopic` service bus. This message includes a `RequestExecuteEntryMethod` field indicating how the execution was initiated: automatically by the system (Auto=1) or manually by an operator (Manually=2).

`Billing.UpdateRequestExecuteEntryMethod` persists this execution method onto the `Billing.WithdrawToFunding` records. It accepts a list of WithdrawToFunding IDs and a single `@RequestExecuteEntryMethodId` value, then batch-applies the update through the standard TVP path (`Billing.UpdateWithdraw2Funding`).

The procedure was introduced on 28/07/2022 by Rita (PAYUA-3768) as part of the Straight-Through Processing (CO STP) flow, replacing a direct `UPDATE WHERE IN` approach with the TVP-based path to ensure history logging. Note: the `dbo.IdList` type uses a column named `CID` - despite the name, in this context it contains WithdrawToFunding IDs (not customer IDs), as noted in the procedure's own comment.

---

## 2. Business Logic

### 2.1 RequestExecuteEntryMethod - Payment Execution Mode

**What**: Records whether the payment order was auto-executed by the system or triggered manually by an operator.

**Columns/Parameters Involved**: `@RequestExecuteEntryMethodId`, `Billing.WithdrawToFunding.RequestExecuteEntryMethodId`

**Rules**:
- 0 = None: not set / initial state
- 1 = Auto: payment order was automatically triggered by the payout processing pipeline
- 2 = Manually: a human operator manually triggered the execution
- The value originates from the `ReadyForExecutionMessage.RequestExecuteEntryMethod` field consumed from the `ReadyForExecutionTopic` service bus
- Updated via consumer service when processing the ReadyForExecutionTopic message, alongside `CashoutStatusID` and `ManagerID`

**Diagram**:
```
Cash Out Service -> ReadyForExecutionTopic
  Message: { WithdrawId, PaymentOrderId, RequestExecuteEntryMethod: 0|1|2, ... }

Consumer Service processes message:
  --> Billing.UpdateRequestExecuteEntryMethod
        @Ids = [WTF_ID_1, WTF_ID_2, ...]
        @RequestExecuteEntryMethodId = 1 (Auto) or 2 (Manually)
        --> UpdateWithdraw2Funding (TVP)
            --> Billing.WithdrawToFunding.RequestExecuteEntryMethodId updated
```

### 2.2 Batch Update via IdList TVP

**What**: Multiple WithdrawToFunding records are updated in a single call using the `dbo.IdList` table type.

**Columns/Parameters Involved**: `@Ids (dbo.IdList)`, `@RequestExecuteEntryMethodId`

**Rules**:
- `dbo.IdList` is a table type with a column named `CID` - despite the name, in this procedure it carries WithdrawToFunding IDs (as noted in the code comment).
- `CashoutActionStatusID` is hardcoded to `1` (New) in the TVP. This is passed to `UpdateWithdraw2Funding` for the history record's action status - it does not change the `WithdrawToFunding.CashoutStatusID`.
- All IDs in the list receive the same `@RequestExecuteEntryMethodId` value.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | dbo.IdList READONLY | NO | - | CODE-BACKED | Table-valued parameter containing a list of WithdrawToFunding IDs to update. Despite the IdList type using a column named `CID`, these are WithdrawToFunding record IDs (as noted in the code: "Its actualli WTF_ID"). All records in this list receive the same `@RequestExecuteEntryMethodId`. |
| 2 | @RequestExecuteEntryMethodId | INT | NO | - | VERIFIED | How the payment order execution was initiated: 0=None (not set), 1=Auto (automatically by the payout pipeline), 2=Manually (triggered by a human operator). Comes from `ReadyForExecutionMessage.RequestExecuteEntryMethod` in the ReadyForExecutionTopic. (Source: Confluence - "Ready For Execution Topic") |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Ids | Billing.WithdrawToFunding | Batch UPDATE | Updates RequestExecuteEntryMethodId on all listed WTF records |
| (delegated) | Billing.UpdateWithdraw2Funding | EXEC | TVP-based update path ensuring history logging |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay (permission grant) | - | GRANT EXECUTE | Payment processing role |
| PayoutUser (permission grant) | - | GRANT EXECUTE | Payout processing service user |
| ReadyForExecutionTopic consumer | - | Application call | Called when processing ReadyForExecution messages from the service bus |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateRequestExecuteEntryMethod (procedure)
└── Billing.UpdateWithdraw2Funding (procedure)
      └── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.IdList | User Defined Type | READONLY TVP parameter - list of WTF IDs to update |
| Billing.TBL_Withdraw2Funding | User Defined Type | Internal TVP to carry the update payload to UpdateWithdraw2Funding |
| Billing.UpdateWithdraw2Funding | Stored Procedure | EXEC - applies the batch update to WithdrawToFunding with history logging |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ReadyForExecutionTopic consumer (application) | Application | Calls this procedure to record execution method after processing payment orders |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None explicit | - | No existence check; if an ID in @Ids does not match a WithdrawToFunding record, the row is silently skipped by UpdateWithdraw2Funding |

---

## 8. Sample Queries

### 8.1 Mark payment orders as auto-executed
```sql
DECLARE @ids dbo.IdList;
INSERT @ids (CID) VALUES (100001), (100002), (100003);  -- WTF IDs

EXEC Billing.UpdateRequestExecuteEntryMethod
    @Ids                        = @ids,
    @RequestExecuteEntryMethodId = 1;  -- Auto
```

### 8.2 Mark a payment order as manually triggered
```sql
DECLARE @ids dbo.IdList;
INSERT @ids (CID) VALUES (100004);  -- Single WTF ID

EXEC Billing.UpdateRequestExecuteEntryMethod
    @Ids                        = @ids,
    @RequestExecuteEntryMethodId = 2;  -- Manually
```

### 8.3 Check execution methods for recent payouts
```sql
SELECT
    wtf.ID                        AS WithdrawToFundingId,
    wtf.WithdrawID,
    wtf.RequestExecuteEntryMethodId,
    CASE wtf.RequestExecuteEntryMethodId
        WHEN 0 THEN 'None'
        WHEN 1 THEN 'Auto'
        WHEN 2 THEN 'Manually'
        ELSE 'Unknown'
    END                           AS ExecutionMethod,
    wtf.CashoutStatusID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.RequestExecuteEntryMethodId IS NOT NULL
ORDER BY wtf.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Ready For Execution Topic](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12087427198/Ready+For+Execution+Topic) | Confluence | RequestExecuteEntryMethod enum: 0=None, 1=Auto, 2=Manually; originates from ReadyForExecutionMessage; also updates CashoutStatusID and ManagerID on WithdrawToFunding |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.3/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 10, 10-Tier2)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpdateRequestExecuteEntryMethod | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateRequestExecuteEntryMethod.sql*
