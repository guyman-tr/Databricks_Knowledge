# BackOffice.DepositUpdateApproval

> Approves or rejects a deposit in BackOffice, assigning the reviewing manager and calculating their sales commission when approving.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - the deposit to approve/reject |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.DepositUpdateApproval is used by BackOffice agents to approve or reject a pending deposit. When a deposit is approved with a manager assigned, the procedure also calculates the sales agent's commission on that deposit using `BackOffice.GetSaleCommission`. Both the approval state and the commission are written atomically to `Billing.Deposit`.

The procedure previously sent commission notifications to a Customer Support Service Broker queue (two Service Broker XML blocks), but this entire section has been commented out - the commission notification system has been decommissioned, and only the core Billing.Deposit UPDATE remains active.

---

## 2. Business Logic

### 2.1 Approval with Commission Calculation

**What**: When a manager approves a deposit, their commission is calculated and recorded simultaneously.

**Columns/Parameters Involved**: `@ManagerID`, `@Approved`, `@Commission`, `Billing.Deposit.Approved`, `Billing.Deposit.ManagerID`, `Billing.Deposit.Commission`

**Rules**:
- Commission is calculated ONLY when both: `@ManagerID IS NOT NULL` AND `@Approved = 1`.
- `SELECT @Commission = BackOffice.GetSaleCommission(CAST(Amount * ExchangeRate AS MONEY)) FROM Billing.Deposit WHERE DepositID = @DepositID` - commission is a function of the deposit's USD value.
- Commission defaults to `ISNULL(@Commission, 0)` - if GetSaleCommission returns NULL (no commission tier applies), 0 is stored.
- When rejecting (@Approved = 0) or when no manager: Commission = 0.
- OUTPUT clause captures the prior state (DELETED.*) into @Info table for the now-commented commission notification logic.

### 2.2 Legacy Service Broker Commission Notification (Decommissioned)

**What**: A large commented-out block that previously sent commission events to a Service Broker queue.

**Columns/Parameters Involved**: `@XMLData`, `@Handle` (both local variables, no longer used)

**Rules**:
- The entire XML generation + Service Broker send block is wrapped in `/* ... */` comments.
- Previously sent two events: (1) debit the old manager's commission, (2) credit the new manager's commission.
- Service Broker services `svcInitiator` / `svcCustomerSupport` may no longer exist.
- The `@Info` table still has a `PlayerLevelID INT` column from this legacy code path (now unused since the Service Broker block is commented out).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | The deposit to approve or reject. PK of Billing.Deposit. |
| 2 | @ManagerID | INTEGER | YES | - | CODE-BACKED | The BackOffice manager reviewing this deposit. Written to Billing.Deposit.ManagerID. When combined with @Approved=1, triggers commission calculation. NULL = no manager assigned (commission = 0). |
| 3 | @Approved | BIT | NO | - | CODE-BACKED | Approval decision: 1 = deposit approved, 0 = rejected. Written to Billing.Deposit.Approved. Drives commission calculation - commission only computed on approval. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | Modifier | UPDATE target - sets Approved, ManagerID, Commission. Uses OUTPUT to capture prior state. |
| Amount * ExchangeRate | BackOffice.GetSaleCommission | Function call | Called to compute the sales commission on the deposit's USD value when approving with a manager. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice deposit review workflow | EXEC | Caller | Called by BackOffice agents when reviewing and deciding on pending deposits. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DepositUpdateApproval (procedure)
├── Billing.Deposit (table) - UPDATE Approved/ManagerID/Commission
└── BackOffice.GetSaleCommission (function) - calculates commission on deposit amount
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE Approved, ManagerID, Commission WHERE DepositID = @DepositID; SELECT Amount*ExchangeRate for commission calc |
| BackOffice.GetSaleCommission | Function | Scalar call - computes sales commission on deposit USD amount (only when @ManagerID IS NOT NULL AND @Approved=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice deposit review UI/API | External | EXEC - approve/reject workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Commission only on approval | Logic | GetSaleCommission is called only when @ManagerID IS NOT NULL AND @Approved=1. Rejection always results in Commission=0. |
| ISNULL(@Commission, 0) | Safety | If GetSaleCommission returns NULL (no commission tier), 0 is stored - prevents NULL in Commission column. |
| Legacy Service Broker | Decommissioned | XML + Service Broker commission notification is fully commented out. The @XMLData, @Handle variables are declared but never used in active code. |
| @@ERROR return | Convention | Returns SQL error code. 0 = success. No TRY/CATCH wrapper. |

---

## 8. Sample Queries

### 8.1 Approve a deposit with manager assignment
```sql
EXEC BackOffice.DepositUpdateApproval
    @DepositID = 987654,
    @ManagerID = 42,
    @Approved = 1
```

### 8.2 Reject a deposit
```sql
EXEC BackOffice.DepositUpdateApproval
    @DepositID = 987654,
    @ManagerID = 42,
    @Approved = 0
```

### 8.3 Check approval status and commission for a deposit
```sql
SELECT
    d.DepositID,
    d.Approved,
    d.ManagerID,
    d.Commission,
    CAST(d.Amount * d.ExchangeRate AS MONEY) AS USDAmount
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.DepositID = 987654
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DepositUpdateApproval | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.DepositUpdateApproval.sql*
