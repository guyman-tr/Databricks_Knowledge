# Billing.UpdateDepositPaymentStatusId

> Directly sets the PaymentStatusID on a Billing.Deposit record, bypassing state machine validation - used by the Business Rules engine to apply rule-driven deposit status changes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositId - targets Billing.Deposit.PaymentStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateDepositPaymentStatusId` is a direct status-override procedure used by the Business Rules engine to set a deposit's payment status based on automated rule evaluation results. Unlike `Billing.DepositProcess` (which validates transitions through `Dictionary.PaymentStatusStateMachine`) or `Billing.UpdateDepositData` (which is a multi-field patch), this procedure is a minimal single-statement UPDATE with no guards - it sets `PaymentStatusID` unconditionally.

The Business Rules engine evaluates conditions such as risk flags, compliance checks, and business logic rules against deposits and needs to write the resulting status decisions back to the deposit record. This dedicated procedure gives that engine a clean, narrow write interface without exposing the full multi-field patch surface of `UpdateDepositData`.

Called exclusively by `BusinessRuleUserForEtoro`, which also has access to `GetTotalDeposits`, `GetUserCountryRisk`, and withdrawal service read SPs - confirming the business rules context (risk assessment, deposit eligibility checks).

---

## 2. Business Logic

### 2.1 Direct Payment Status Override

**What**: Unconditionally sets the PaymentStatusID on the specified deposit, enabling the Business Rules engine to apply rule-driven status decisions.

**Columns/Parameters Involved**: `@DepositId`, `@PaymentStatusId`, `Billing.Deposit.PaymentStatusID`

**Rules**:
- `UPDATE Billing.Deposit SET PaymentStatusID = @PaymentStatusId WHERE DepositID = @DepositId`
- No prior-state check or state machine validation - unconditional assignment
- FK constraint `FK_DPMS_BDEP` on `Billing.Deposit.PaymentStatusID -> Dictionary.PaymentStatus` enforces that the target status must exist
- Invalid state transitions (e.g., from Approved to Pending) are not prevented at the procedure level - the FK only enforces that the status value exists
- If `@DepositId` does not exist, the UPDATE silently affects 0 rows
- `ModificationDate` on `Billing.Deposit` is NOT updated by this procedure (contrast with `DepositProcess` which updates it)

**PaymentStatusID values** (from Dictionary.PaymentStatus - key values):

| ID | Status | Category |
|----|--------|----------|
| 1 | Pending | In-progress |
| 2 | Approved | Terminal success |
| 3 | Declined | Terminal failure |
| 5 | InProcess | In-progress |
| 8-25 | Various decline codes | Terminal failure |
| 31-35 | Risk decline codes | Terminal failure |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositId | INT | NO | - | CODE-BACKED | Primary key of the deposit to update. Maps to `Billing.Deposit.DepositID`. If the deposit does not exist, the UPDATE silently affects 0 rows. |
| 2 | @PaymentStatusId | INT | NO | - | CODE-BACKED | Target payment status to set. Written to `Billing.Deposit.PaymentStatusID` (FK to `Dictionary.PaymentStatus`). Must be a valid PaymentStatusID; FK constraint enforces existence. State machine transition rules are NOT validated - the Business Rules engine is responsible for valid transition decisions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE DepositID | Billing.Deposit | UPDATE | Sets PaymentStatusID on the target deposit record |
| @PaymentStatusId | Dictionary.PaymentStatus | FK constraint (enforced) | Must be a valid PaymentStatusID; FK_DPMS_BDEP enforces existence |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Business Rules engine | @DepositId, @PaymentStatusId | EXEC (BusinessRuleUserForEtoro role) | Called when automated business rules evaluate and decide a deposit's payment status outcome |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateDepositPaymentStatusId (procedure)
`- Billing.Deposit (table) - UPDATE target
   `- Dictionary.PaymentStatus (FK FK_DPMS_BDEP) - enforces valid PaymentStatusID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE - sets PaymentStatusID WHERE DepositID=@DepositId |
| Dictionary.PaymentStatus | Table | FK constraint (FK_DPMS_BDEP) on PaymentStatusID - enforces that target status exists |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Business Rules engine (BusinessRuleUserForEtoro role). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. The UPDATE hits the clustered PK (`PK_BDEP` on `DepositID`). Multiple indexes on `PaymentStatusID` in `Billing.Deposit` will be maintained by SQL Server during the update (IX_BillingDeposit_PaymentStatusID, Idx_Billing_Deposit_CID_PaymentStatusID, etc.).

### 7.2 Constraints

N/A for stored procedure. Critical note: This procedure does NOT update `ModificationDate` - the change will not be detected by incremental ETL pipelines that query `BDEP_ModificationDate` index. Use `Billing.DepositProcess` (which updates `ModificationDate`) if downstream data pipeline pickup is required. Also note: unlike `DepositProcess`, this procedure does NOT trigger `Billing.AmountAdd` even if status is set to 2 (Approved) - the customer account balance is not credited by this SP alone.

---

## 8. Sample Queries

### 8.1 Set a deposit status via the Business Rules engine path
```sql
-- Mark deposit as declined by business rule evaluation
EXEC Billing.UpdateDepositPaymentStatusId @DepositId = 10780413, @PaymentStatusId = 3; -- 3=Declined
```

### 8.2 Check the current status before and after
```sql
SELECT DepositID, PaymentStatusID, ModificationDate
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 10780413;
-- Note: ModificationDate will NOT be updated by UpdateDepositPaymentStatusId
```

### 8.3 Verify the status exists before calling
```sql
SELECT PaymentStatusID, Name
FROM Dictionary.PaymentStatus WITH (NOLOCK)
WHERE PaymentStatusID = 3;
-- Confirm valid status before setting it
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateDepositPaymentStatusId | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateDepositPaymentStatusId.sql*
