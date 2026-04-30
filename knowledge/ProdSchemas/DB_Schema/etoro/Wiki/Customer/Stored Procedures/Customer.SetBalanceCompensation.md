# Customer.SetBalanceCompensation

> Applies a compensation payment to a customer account: updates Credit, RealizedEquity, and TotalCash by the payment amount, logs CreditTypeID=6 (Compensation), triggers MIMO BSL recalculation with bonus check, sends offline customer notification, and reports to BackOffice.UpsertMIMOAggregation.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @Payment INT (cents), @CompensationReasonID INT, @MoveMoneyReasonID INT; @ErrOut OUTPUT, @CreditOut BIGINT OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalanceCompensation` is the entry point for awarding a compensation payment to a customer. Compensation events cover scenarios such as platform downtime credits, position adjustment corrections, interest payments, or manual goodwill credits authorized by a manager.

The procedure performs a full three-field balance restoration (Credit + RealizedEquity + TotalCash), logs a `CreditTypeID=6` (Compensation) credit record, and triggers the MIMO BSL recalculation pipeline with a special `CheckBonus="1"` flag - instructing `PostMIMOOperations` to also recalculate bonus credit as part of the BSL update.

Affiliate and PiggyBank tracking for compensation events was removed in August 2021. Since May 2022, the procedure also calls `BackOffice.UpsertMIMOAggregation` to ensure the compensation appears in BackOffice MIMO aggregate reporting.

If the customer is a real (non-demo) account currently offline (not in `Customer.Login`), a template-6 message notification is sent.

---

## 2. Business Logic

### 2.1 Cent-to-Dollar Conversion

**What**: @Payment (INT) in cents is converted to MONEY in dollars.

**Rules**:
- `@CreditChange = CAST(@Payment AS MONEY) / 100`
- All balance updates and the credit record use @CreditChange.

### 2.2 Three-Field Balance Update

**What**: Credit, RealizedEquity, and TotalCash are all increased by the compensation amount.

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`, `TotalCash`

**Rules**:
- `Credit += @CreditChange`
- `RealizedEquity += @CreditChange`
- `TotalCash += @CreditChange`
- ISNULL wrappers used for NULL safety.

### 2.3 MIMO BSL Recalculation with Bonus Check

**What**: Triggers asynchronous BSL recalculation AND bonus credit recalculation via the MIMO pipeline.

**Columns/Parameters Involved**: `Internal.ActionsToExecute_MIMOOperations`, `Trade.BSLUsersWhiteList`

**Rules**:
- XML format: `<Root><CreditID Value="{id}"/><CreditTypeID Value="6"/><CID Value="{cid}"/><CheckBonus Value="1"/></Root>`
- The `CheckBonus="1"` flag distinguishes compensation from other MIMO triggers - `PostMIMOOperations` will also recalculate and apply bonus credit on this event.
- Inserts `(CID, CreditID)` into `Trade.BSLUsersWhiteList`.
- BonusCredit update was removed from this procedure (2020-03-23) and is now performed asynchronously by `PostMIMOOperations`.

### 2.4 Offline Customer Notification

**What**: Sends a template-6 notification to real customers who are not currently logged in.

**Columns/Parameters Involved**: `Customer.Login`, `@IsReal`, `@CIDASSTR`, `@MsgParam`

**Rules**:
- Condition: `IsReal = 1 AND NOT EXISTS(SELECT 1 FROM Customer.Login WHERE CID = @CID)`.
- Message params: `"{CreditChange};compensation"`.
- `MessageTemplateID = 6` (financial update notification).
- Calls `Customer.SendMessage`.

### 2.5 BackOffice MIMO Aggregation

**What**: Reports the compensation event to the BackOffice MIMO aggregation table.

**Rules**:
- `EXEC BackOffice.UpsertMIMOAggregation @CID, @CreditTypeID=6, @Payment, @WithdrawID=NULL, @DepositID=NULL, ...`
- Added May 2022 to ensure compensation events appear in MIMO aggregate reporting dashboards.
- Called within the same transaction as the balance update.

### 2.6 Cursor Pattern (Historical Artifact)

**What**: SetBalanceInsertCredit_Native is called via a `CURSOR FAST_FORWARD FORWARD_ONLY LOCAL` over the @Output table variable.

**Rules**:
- In practice, @Output always contains exactly one row (the updated CID).
- The cursor pattern is a historical artifact from when multi-CID batch compensation was anticipated.
- Functionally equivalent to a single EXEC call.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID receiving the compensation. |
| 2 | @Payment | INT | NO | - | VERIFIED | Compensation amount in CENTS. Divided by 100 for dollars. |
| 3 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Human-readable description of the compensation reason, stored in the credit history record. |
| 4 | @ManagerID | INTEGER | YES | NULL | CODE-BACKED | Admin/manager who authorized the compensation. Stored in the credit record for audit traceability. |
| 5 | @CompensationReasonID | INTEGER | YES | NULL | CODE-BACKED | Reason code for the compensation (Dictionary.CompensationReason). Included in the payment queue message and credit record. |
| 6 | @MoveMoneyReasonID | INT | NO | - | CODE-BACKED | Internal money movement reason code (required). Additional classification for the compensation event type. |
| 7 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT parameter receiving error details on failure. Format: "SP - Schema.Proc | ERROR_NUMBER: ... ERROR_MESSAGE: ...". |
| 8 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | Optional position reference if compensation is tied to a specific trading position (e.g., interest compensation for a position). Passed to SetBalanceInsertCredit_Native. |
| 9 | @InterestMonthlyID | INT | YES | NULL | CODE-BACKED | Monthly interest record reference if this compensation is an interest payment. Passed to SetBalanceInsertCredit_Native. |
| 10 | @CreditOut | BIGINT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: CreditID of the newly created credit record. Available since 2022-09-18 (TRADEC-120). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE Credit, RealizedEquity, TotalCash += compensation amount |
| @CID | Customer.CustomerStatic | READ | Reads IsReal, ProviderID, CountryID, PlayerLevelID for notification logic |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=6 compensation credit record |
| @CID | Internal.ActionsToExecute_MIMOOperations | INSERT | Queues async BSL + bonus recalculation (ActionID=7, CheckBonus=1) |
| @CID, @Identity | Trade.BSLUsersWhiteList | INSERT | Suspends BSL enforcement during MIMO window |
| @CID | Customer.Login | READ | Checks if customer is currently logged in (for offline notification) |
| @CID | Customer.SendMessage | Caller (EXEC) | Sends template-6 offline notification (real customers only) |
| @CID | Customer.SendEvent | Caller (EXEC) | Sends event-9 (zero balance alert) if NewCredit <= 0 |
| - | svcPayment (Service Broker) | SEND | Notifies payment queue of compensation event |
| @CID | BackOffice.UpsertMIMOAggregation | Caller (EXEC) | Updates MIMO aggregate reporting in BackOffice |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=6 (Compensation) events here |
| BackOffice compensation tools | External | Callers | Called by manual compensation workflows and automated interest payment jobs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceCompensation (procedure)
+-- Customer.CustomerMoney (table) [UPDATE Credit, RealizedEquity, TotalCash]
+-- Customer.CustomerStatic (table) [READ IsReal, CountryID, tracking fields]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=6]
|     +-- History.ActiveCreditRecentMemoryBucket (table)
+-- Internal.ActionsToExecute_MIMOOperations (table) [INSERT MIMO+bonus trigger]
+-- Trade.BSLUsersWhiteList (table) [INSERT BSL whitelist entry]
+-- Customer.Login (table) [READ - offline check]
+-- Customer.SendMessage (procedure) [offline notification, conditional]
+-- Customer.SendEvent (procedure) [zero-balance alert, conditional]
+-- BackOffice.UpsertMIMOAggregation (procedure) [MIMO aggregate update]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - Credit, RealizedEquity, TotalCash |
| Customer.CustomerStatic | Table | SELECT - IsReal, ProviderID, CountryID, tracking fields |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=6 compensation record |
| Internal.ActionsToExecute_MIMOOperations | Table | INSERT - queues async MIMO + bonus recalculation |
| Trade.BSLUsersWhiteList | Table | INSERT - suspends BSL during MIMO window |
| Customer.Login | Table | SELECT - offline check for notification |
| Customer.SendMessage | Procedure | EXEC - offline notification (conditional) |
| Customer.SendEvent | Procedure | EXEC - zero balance alert (conditional) |
| BackOffice.UpsertMIMOAggregation | Procedure | EXEC - MIMO aggregate reporting update |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=6 (Compensation) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @Payment = INT (cents) | Unit convention | Divided by 100 for dollars |
| CheckBonus="1" in MIMO XML | Design | Compensation events trigger bonus recalculation in PostMIMOOperations - BonusCredit update is deferred to async pipeline |
| PiggyBank/Affiliate removed | Historical | Affiliate and PiggyBank tracking removed 2021-08-03 - compensation no longer reports to affiliate systems |
| CURSOR pattern | Historical artifact | CURSOR over @Output always yields one row - functionally equivalent to a single EXEC |
| BackOffice.UpsertMIMOAggregation added 2022 | Enhancement | Ensures compensation events appear in MIMO aggregate dashboards in BackOffice reporting |

---

## 8. Sample Queries

### 8.1 Find all compensation events for a customer

```sql
SELECT
    acb.CreditID,
    acb.Payment AS CompensationAmountUSD,
    acb.CompensationReasonID,
    cr.Name AS CompensationReason,
    acb.MoveMoneyReasonID,
    acb.PositionID,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
LEFT JOIN Dictionary.CompensationReason cr WITH (NOLOCK) ON cr.CompensationReasonID = acb.CompensationReasonID
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 6
ORDER BY acb.Occurred DESC
```

### 8.2 Check MIMO queue status for a compensation event

```sql
SELECT
    atm.ActionID,
    atm.Params,
    atm.Status,
    atm.CurrentTry,
    w.CreditID AS BSLWhitelistCreditID
FROM Internal.ActionsToExecute_MIMOOperations atm WITH (NOLOCK)
LEFT JOIN Trade.BSLUsersWhiteList w WITH (NOLOCK)
    ON w.CID = 12345
    AND atm.Params LIKE '%CreditID Value="' + CAST(w.CreditID AS VARCHAR) + '"%'
WHERE atm.Params LIKE '%CID Value="12345"%'
    AND atm.Params LIKE '%CreditTypeID Value="6"%'
ORDER BY atm.ActionID DESC
```

### 8.3 Total compensation paid by reason this month

```sql
SELECT
    acb.CompensationReasonID,
    cr.Name AS ReasonName,
    SUM(acb.Payment) AS TotalCompensationUSD,
    COUNT(*) AS EventCount
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
LEFT JOIN Dictionary.CompensationReason cr WITH (NOLOCK) ON cr.CompensationReasonID = acb.CompensationReasonID
WHERE acb.CreditTypeID = 6
    AND acb.Occurred >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETUTCDATE()), 0)
GROUP BY acb.CompensationReasonID, cr.Name
ORDER BY TotalCompensationUSD DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceCompensation | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceCompensation.sql*
