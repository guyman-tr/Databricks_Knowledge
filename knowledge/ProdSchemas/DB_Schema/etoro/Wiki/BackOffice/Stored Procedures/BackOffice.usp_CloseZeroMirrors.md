# BackOffice.usp_CloseZeroMirrors

> Scheduled maintenance job that closes copy-trade mirrors with negligible amounts (< $5), no open positions, no open stock orders, and no activity in 3 days - then notifies affected customers via message template 1431.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - identifies candidates via Trade.Mirror criteria |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.usp_CloseZeroMirrors` is a scheduled maintenance job that cleans up dormant copy-trade mirrors that have become effectively empty. A "zero mirror" is a mirror (copy-trading relationship) where the allocated amount has fallen below $5, the copy has no open positions or pending stock orders, and there has been no activity in the past 3 days.

The procedure exists to prevent accumulation of zombie mirrors that consume back-office resources and confuse risk systems. When a copied portfolio's value drops below $5 through losses or withdrawals, the copy-trading relationship is no longer economically meaningful, and the system closes it automatically.

For each qualifying mirror, the SP:
1. Deactivates the mirror state via `Trade.ChangeMirrorState @MirrorID, 0`
2. Unregisters the mirror via `Trade.UnRegisterMirror`
3. Sends a system notification to the customer (MessageTemplateID=1431) informing them the copy was closed

Errors are logged to `History.InsertLogErrorGeneral` per mirror - a per-mirror failure does not stop the batch (the cursor continues to the next mirror).

---

## 2. Business Logic

### 2.1 Candidate Selection

**What**: Identifies mirrors eligible for automatic closure.

**Columns/Parameters Involved**: `Trade.Mirror.Amount`, `Trade.Position.MirrorID`, `History.Credit.MirrorID`, `Stocks.GetOrders.MirrorID`

**Rules**:
- `Amount < 5.00` - allocated mirror amount below $5 threshold.
- `NOT EXISTS (Position WHERE MirrorID = TMIR.MirrorID AND ParentPositionID = OrigParentPositionID)` - no open connected positions (copy-traded positions still active).
- `NOT EXISTS (Stocks.GetOrders WHERE MirrorID = TMIR.MirrorID AND IsPending = 1)` - no pending stock orders linked to this mirror.
- `NOT EXISTS (History.Credit WHERE MirrorID = TMIR.MirrorID AND CID = TMIR.CID AND Payment = 0 AND Occurred >= DATEADD(DAY,-3,GETUTCDATE()))` - no credit activity in last 3 days (with Payment=0 filter, likely matching settlement or fee events).

### 2.2 Per-Mirror Closure (Cursor Loop)

**What**: For each qualifying mirror, performs a 2-step closure within a transaction.

**Rules**:
- `EXEC Trade.ChangeMirrorState @MirrorID, 0` - sets mirror state to inactive. RAISERROR if @Answer != 0.
- `EXEC Trade.UnRegisterMirror @CID, @MirrorID, 'Unregister mirror by System (CloseZeroMirrors Job)', @ParentUserName_Output OUTPUT, @ParentCID OUTPUT` - fully unregisters the mirror. RAISERROR if @Answer != 0.
- Both operations are within a `BEGIN TRAN / COMMIT` block.

### 2.3 Customer Notification

**What**: Sends a system message to the customer after successful mirror closure.

**Rules**:
- After COMMIT (outside transaction), `EXEC Customer.SendMessage @CustomerList=@CID, @MessageTemplateID=1431, @ParamList='@ParentUserName;@Amount'`
- @ParamsList format: `'<leader_username>;<amount_in_dollars>'` (AmountInCents/100)
- MessageTemplateID=1431 = the "copy trading closed automatically" notification template.

### 2.4 Per-Mirror Error Handling

**What**: Logs errors per mirror and continues the loop.

**Rules**:
- Per-mirror TRY/CATCH: on error, ROLLBACK if TranCount=1, COMMIT if TranCount>1.
- Logs error details via `History.InsertLogErrorGeneral 'BackOffice.usp_CloseZeroMirrors', @Param_XML, ...`.
- Raises error after logging but continues to next cursor row (cursor fetch continues after END CATCH).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | Fully automated maintenance job. All criteria (Amount < $5, 3-day inactivity, no open positions/orders) are hardcoded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Amount < 5 | Trade.Mirror | SELECT source | Identifies candidate mirrors for closure |
| MirrorID | Trade.Position | NOT EXISTS check | Verifies no open copy-trade positions |
| MirrorID | Stocks.GetOrders | NOT EXISTS check | Verifies no pending stock orders |
| MirrorID | History.Credit | NOT EXISTS check | Verifies no activity in last 3 days |
| @MirrorID | Trade.ChangeMirrorState | EXEC callee | Deactivates mirror state to 0 |
| @CID, @MirrorID | Trade.UnRegisterMirror | EXEC callee | Fully unregisters the mirror |
| @CID | Customer.SendMessage | EXEC callee | Notifies customer (template 1431) |
| Error details | History.InsertLogErrorGeneral | EXEC callee | Logs per-mirror errors |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent scheduled job | - | Caller | Executed on a recurring schedule to clean up dormant mirrors. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.usp_CloseZeroMirrors (procedure)
+-- Trade.Mirror (table) [SELECT: candidate mirrors with Amount < $5]
+-- Trade.Position (table) [NOT EXISTS: open positions check]
+-- Stocks.GetOrders (view/table) [NOT EXISTS: pending orders check]
+-- History.Credit (table) [NOT EXISTS: 3-day activity check]
+-- Trade.ChangeMirrorState (procedure) [EXEC: deactivate mirror]
+-- Trade.UnRegisterMirror (procedure) [EXEC: unregister mirror]
+-- Customer.SendMessage (procedure) [EXEC: customer notification]
+-- History.InsertLogErrorGeneral (procedure) [EXEC: error logging]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT: candidate mirrors, Amount, CID, ParentUserName |
| Trade.Position | Table | NOT EXISTS check for open copy-trade positions |
| Stocks.GetOrders | View/Table | NOT EXISTS check for pending stock orders (IsPending=1) |
| History.Credit | Table | NOT EXISTS check for recent activity (last 3 days, Payment=0) |
| Trade.ChangeMirrorState | Procedure | EXEC: set mirror state to inactive (0) |
| Trade.UnRegisterMirror | Procedure | EXEC: full mirror unregistration |
| Customer.SendMessage | Procedure | EXEC: customer notification (MessageTemplateID=1431) |
| History.InsertLogErrorGeneral | Procedure | EXEC: error logging per failed mirror |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent job | External | Scheduled recurring execution for mirror cleanup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Uses temp table `#MirrorsToClose` to snapshot candidates before cursor processing.

### 7.2 Constraints

- CURSOR READ_ONLY FORWARD_ONLY for sequential processing.
- Per-mirror BEGIN TRAN / COMMIT - each mirror closure is independently committed.
- TranCount logic: ROLLBACK if TranCount=1, COMMIT if TranCount>1 (handles nested transaction scenarios).
- $5 threshold and 3-day inactivity period are hardcoded.
- AmountInCents is Amount*100 (Trade.Mirror.Amount is in dollars; notification message receives cents for formatting).

---

## 8. Sample Queries

### 8.1 Preview mirrors that would be closed

```sql
SELECT TMIR.MirrorID, TMIR.CID, TMIR.ParentUserName, TMIR.Amount
FROM Trade.Mirror TMIR WITH (NOLOCK)
WHERE TMIR.Amount < 5.00
  AND NOT EXISTS (SELECT 1 FROM Trade.[Position] p WITH (NOLOCK)
    WHERE p.MirrorID = TMIR.MirrorID AND p.ParentPositionID = p.OrigParentPositionID)
  AND NOT EXISTS (SELECT 1 FROM Stocks.GetOrders o WITH (NOLOCK)
    WHERE o.MirrorID = TMIR.MirrorID AND o.IsPending = 1)
  AND NOT EXISTS (SELECT 1 FROM History.Credit c WITH (NOLOCK)
    WHERE c.MirrorID = TMIR.MirrorID AND c.CID = TMIR.CID
      AND c.Payment = 0 AND c.Occurred >= DATEADD(DAY,-3,GETUTCDATE()));
```

### 8.2 Run the cleanup job manually

```sql
EXEC BackOffice.usp_CloseZeroMirrors;
-- Closes all qualifying mirrors and notifies affected customers.
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 callees analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.usp_CloseZeroMirrors | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.usp_CloseZeroMirrors.sql*
