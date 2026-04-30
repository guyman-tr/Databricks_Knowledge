# Billing.WithdrawToFundingUpdateMerchantAccountID

> Sets the MerchantAccountID on a WithdrawToFunding leg by ID with no pre-flight guards; delegates entirely to UpdateWithdraw2Funding with CashoutActionStatusID=0 (metadata-only update).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID INT - the Billing.WithdrawToFunding.ID to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure assigns a `MerchantAccountID` to a WithdrawToFunding leg. The `MerchantAccountID` identifies which merchant account (payment processor account) should be used to process the payment leg. It is set after routing decisions have been made - typically by the payment routing engine after analyzing the customer's funding instrument, geography, and processor availability.

The procedure is a thin wrapper over `Billing.UpdateWithdraw2Funding` with no validation or state checks. This design reflects that merchant account assignment is a metadata operation: it can be applied to any WTF leg regardless of its current status, and should not be blocked by state guards. The absence of an existence check means calling with a non-existent `@ID` will silently succeed (UpdateWithdraw2Funding will perform zero updates).

A notable difference from other update SPs: `CashoutActionStatusID=0` is passed (not 2=processed). This signals to the history logging in `UpdateWithdraw2Funding` that this is a metadata-only change, not a status action.

Created December 2021 (PAYIL-3501, Naftali Hershler).

---

## 2. Business Logic

### 2.1 Merchant Account Assignment (No Guards)

**What**: Sets MerchantAccountID on the WTF record via UpdateWithdraw2Funding.

**Columns/Parameters Involved**: `@ID`, `@MerchantAccountID`, `CashoutActionStatusID=0`

**Rules**:
- No existence check - if `@ID` doesn't exist, `UpdateWithdraw2Funding` affects 0 rows (no error)
- No status guard - works on any CashoutStatusID
- No IB guard, no parent Withdraw check
- `CashoutActionStatusID=0` - metadata update (not a status change action)
- `@MerchantAccountID = 0` default - zero may indicate "no merchant account" or "default routing"
- Return value from `UpdateWithdraw2Funding` is captured and returned via `RETURN @ret`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID` - the WTF leg to assign a merchant account to. No existence validation; silent no-op if not found. |
| 2 | @MerchantAccountID | int | YES | 0 | CODE-BACKED | Input parameter. The merchant account identifier to assign. Default 0 may represent "no specific merchant account" or "default routing". Written directly to `Billing.WithdrawToFunding.MerchantAccountID`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (write target) | Billing.WithdrawToFunding | Write (via TVP) | MerchantAccountID update via UpdateWithdraw2Funding |
| (EXEC) | Billing.UpdateWithdraw2Funding | Procedure call | Applies the MerchantAccountID field update and logs history |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code (payment routing engine).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingUpdateMerchantAccountID (procedure)
+-- Billing.UpdateWithdraw2Funding (procedure) -- field write + history
      +-- Billing.WithdrawToFunding (table) -- update target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.UpdateWithdraw2Funding | Stored Procedure | Writes MerchantAccountID to WTF record and logs history |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the update

```sql
EXEC Billing.WithdrawToFundingUpdateMerchantAccountID
    @ID               = 12345,
    @MerchantAccountID = 7;
```

### 8.2 Verify the assignment

```sql
SELECT ID, MerchantAccountID, ModificationDate
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE ID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingUpdateMerchantAccountID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingUpdateMerchantAccountID.sql*
