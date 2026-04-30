# BackOffice.GetPaymentOrderHistory

> Returns the full audit trail of status changes for a specific payment order (WithdrawToFunding record), including who made each change, when, what status was set, and any remarks - backing the CashoutTool API endpoint GET /api/v2/cashout/paymentOrders/{id}/history.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID - the WithdrawToFunding (payment order) ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete action history for a payment order - answering "what happened to this withdrawal payment, and who changed its status at each step?" Each row represents one status change event in the lifecycle of a withdrawal-to-funding record, including the BackOffice manager who made the change and any remarks they recorded.

In eToro's withdrawal flow, a payment order (`Billing.WithdrawToFunding`) goes through multiple status transitions as BackOffice agents review, approve, reject, or send it for processing. This procedure exposes that audit trail to the CashoutTool UI so agents can see the history of any payment order.

**API integration** (from Confluence: "Get Payment order history Api", Jira MIMOPSA-6186):
- **Endpoint**: `GET /api/v2/cashout/paymentOrders/{id}/history` in the CashoutTool service
- **Input**: `int` - the payment order ID (maps to `@ID`)
- **Output**: `PaymentOrderHistoryResponse` (Nuget `eToro.BackOffice.CashOutService.Contract` v1.0.8.12+)
- **DTO contract**:
  ```csharp
  public class PaymentOrderHistoryResponse : ResponseBase<BusinessException>
  {
      public IEnumerable<PaymentOrderHistoryAction> PaymentOrderHistoryActions { get; set; }
  }
  public class PaymentOrderHistoryAction
  {
      public int Id { get; set; }
      public DateTime ModificationDate { get; set; }
      public string Status { get; set; }
      public string Comment { get; set; }
      public Manager.Manager Manager { get; set; }
  }
  ```

**Permission**: EXECUTE granted to CashoutTool service user.

---

## 2. Business Logic

### 2.1 Payment Order History Retrieval

**What**: Returns all recorded status-change events for a specific payment order, newest first.

**Columns/Parameters Involved**: HWFA.BW2F_ID, @ID, HWFA.ModificationDate

**Rules**:
- `HWFA.BW2F_ID = @ID`: Scopes to all history records for the given WithdrawToFunding record. `BW2F_ID` is the foreign key to `Billing.WithdrawToFunding` (the payment order).
- `ORDER BY HWFA.ModificationDate DESC`: Newest actions first - shows most recent state change at top of list.
- LEFT JOIN to `BackOffice.Manager`: Manager is optional per event (system-generated status changes may have no manager). NULL ManagerID produces NULL manager fields in output.
- LEFT JOIN to `Dictionary.CashoutStatus`: Maps CashoutStatusID to human-readable status name. All valid statuses are in the dictionary.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | INT | NO | - | CODE-BACKED | The payment order identifier. Maps to `History.WithdrawToFundingAction.BW2F_ID`, which is a FK to `Billing.WithdrawToFunding`. This is the "PaymentOrderId" in the CashoutTool API URL: `/api/v2/cashout/paymentOrders/{id}/history`. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | INT | NO | - | CODE-BACKED | Primary key of the history action record (`WithdrawToFundingActionID`). Unique identifier for this specific status-change event. Maps to `PaymentOrderHistoryAction.Id` in the API DTO. |
| 2 | ModificationDate | DATETIME | NO | - | CODE-BACKED | When this status change occurred. Result set ordered by this column descending. Maps to `PaymentOrderHistoryAction.ModificationDate` in the API DTO. |
| 3 | Status | NVARCHAR | YES | - | CODE-BACKED | Human-readable cashout status name from `Dictionary.CashoutStatus.Name` (e.g., "Pending Review", "Approved", "Rejected", "In Process"). Maps to `PaymentOrderHistoryAction.Status` in the API DTO. NULL if CashoutStatusID not in dictionary. |
| 4 | Comment | NVARCHAR | YES | - | CODE-BACKED | Remark entered by the BackOffice manager when recording this action. May be NULL if no comment was provided. Maps to `PaymentOrderHistoryAction.Comment` in the API DTO. |
| 5 | ManagerId | INT | YES | - | CODE-BACKED | BackOffice manager ID who performed this action. NULL for system-generated events. Maps to `Manager.id` in the API DTO. |
| 6 | FirstName | NVARCHAR | YES | - | CODE-BACKED | Manager's first name. NULL if no manager. Maps to `Manager.firstName` in the API DTO. |
| 7 | LastName | NVARCHAR | YES | - | CODE-BACKED | Manager's last name. NULL if no manager. Maps to `Manager.lastName` in the API DTO. |
| 8 | Username | NVARCHAR | YES | - | CODE-BACKED | Manager's login name (`BackOffice.Manager.Login`). NULL if no manager. Maps to `Manager.username` in the API DTO. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID / BW2F_ID | History.WithdrawToFundingAction | Read (FROM) | Primary data source. Each row = one status-change event for the payment order. |
| @ID | Billing.WithdrawToFunding | Implicit FK | BW2F_ID is the FK to the payment order table in Billing. |
| ManagerId | BackOffice.Manager | Lookup (LEFT JOIN) | Manager who recorded each action. Left join allows NULL (system events). |
| Status | Dictionary.CashoutStatus | Lookup (LEFT JOIN) | Maps CashoutStatusID to human-readable status name. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool service | GET /api/v2/cashout/paymentOrders/{id}/history | EXECUTE | BackOffice payment order audit trail endpoint. Jira: MIMOPSA-6186. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
CashoutTool API: GET /api/v2/cashout/paymentOrders/{id}/history
  -> BackOffice.GetPaymentOrderHistory (this SP)
     +-- History.WithdrawToFundingAction (table)
     +-- BackOffice.Manager (table)
     +-- Dictionary.CashoutStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.WithdrawToFundingAction | Table | FROM clause; all status-change event rows for the payment order |
| BackOffice.Manager | Table | LEFT JOIN on ManagerID; provides manager name and login for each action |
| Dictionary.CashoutStatus | Table | LEFT JOIN on CashoutStatusID; provides human-readable status name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CashoutTool service | External service | Calls via `GET /api/v2/cashout/paymentOrders/{id}/history`; EXECUTE grant in CashoutTool.sql |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) on all tables | Locking | Non-blocking reads; history table may be large |
| LEFT JOIN Manager | Nullable manager | System-generated events have no manager; left join preserves these rows |
| ORDER BY ModificationDate DESC | Presentation | Most recent status change first |

---

## 8. Sample Queries

### 8.1 Get history for a specific payment order

```sql
EXEC BackOffice.GetPaymentOrderHistory @ID = 207407
-- Sample output per Confluence:
-- Id=95534, ModificationDate=2022-03-24, Status='Pending Review', manager='Yaron Shmaria (yaronsh)'
```

### 8.2 Query the history table directly

```sql
SELECT
    hwfa.WithdrawToFundingActionID AS Id,
    hwfa.ModificationDate,
    dcs.Name AS Status,
    hwfa.Remark AS Comment,
    bman.ManagerID,
    bman.FirstName,
    bman.LastName,
    bman.Login AS Username
FROM History.WithdrawToFundingAction hwfa WITH (NOLOCK)
LEFT JOIN BackOffice.Manager bman WITH (NOLOCK) ON hwfa.ManagerID = bman.ManagerID
LEFT JOIN Dictionary.CashoutStatus dcs WITH (NOLOCK) ON dcs.CashoutStatusID = hwfa.CashoutStatusID
WHERE hwfa.BW2F_ID = 207407
ORDER BY hwfa.ModificationDate DESC;
```

### 8.3 Count actions per status for a payment order

```sql
SELECT dcs.Name AS Status, COUNT(*) AS EventCount
FROM History.WithdrawToFundingAction hwfa WITH (NOLOCK)
JOIN Dictionary.CashoutStatus dcs WITH (NOLOCK) ON dcs.CashoutStatusID = hwfa.CashoutStatusID
WHERE hwfa.BW2F_ID = 207407
GROUP BY dcs.Name
ORDER BY EventCount DESC;
```

---

## 9. Atlassian Knowledge Sources

- **Confluence**: "Get Payment order history Api" (page ID: 11898650807, space: MG) - documents the CashoutTool API endpoint `/api/v2/cashout/paymentOrders/{id}/history`, the `PaymentOrderHistoryResponse` DTO contract, NuGet package `eToro.BackOffice.CashOutService.Contract` v1.0.8.12+, and confirms this SP as the DB backing. Jira: MIMOPSA-6186 "Migration Funding and withdraw".

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.5/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 app service consumer | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPaymentOrderHistory | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPaymentOrderHistory.sql*
