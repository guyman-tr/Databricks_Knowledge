# Billing.WithdrawToFundingUpdateAdditionalInformation

> Sets the AdditionalInformation field on a WithdrawToFunding leg by ID and logs the change in history; simple existence check, no status guard.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID INT - the Billing.WithdrawToFunding.ID to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates the `AdditionalInformation` field on a WithdrawToFunding leg. `AdditionalInformation` is a free-text NVARCHAR(250) field on `Billing.WithdrawToFunding` used to store supplementary data about a payment leg - such as provider-specific metadata, routing notes, or compliance annotations that don't fit into the structured fields.

The procedure is intentionally minimal: it only validates that the WTF record exists, then writes the new value and logs the update via `UpdateWithdraw2Funding`. No status guard is applied - the `AdditionalInformation` field can be updated regardless of the WTF leg's current CashoutStatusID. This makes it appropriate for annotating records at any stage of the withdrawal lifecycle.

Created September 2021 as part of the DBA-648 refactoring (Shay Oren), which introduced the TVP abstraction pattern for WTF updates.

---

## 2. Business Logic

### 2.1 Existence Guard

**What**: Ensures the WTF record exists before writing.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding.ID`, `@ID`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Billing.WithdrawToFunding WHERE ID=@ID)` -> RAISERROR('Withdraw to funding does not exists', 16, 1) + RETURN
- No status guard - any CashoutStatusID is allowed
- No IB check, no parent Withdraw check

### 2.2 AdditionalInformation Write

**What**: Sets the AdditionalInformation field and logs the update in WTF history.

**Columns/Parameters Involved**: `AdditionalInformation`, `CashoutActionStatusID=2`, `ModificationDate`

**Rules**:
- Populates `@InfoWTF` with: ID, AdditionalInformation, ModificationDate=GETUTCDATE(), CashoutActionStatusID=2 (processed), ManagerID
- `EXECUTE @ID = Billing.UpdateWithdraw2Funding @InfoWTF` -> updates `Billing.WithdrawToFunding.AdditionalInformation` and writes history
- Note: The return value from `UpdateWithdraw2Funding` is captured in `@ID` (same variable as the input `@ID` parameter - this overwrites the local variable but it's not used after the EXEC)
- No update to `Billing.Withdraw` (only WTF record)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID` - the WTF leg to annotate. Must exist (existence guard). |
| 2 | @ManagerID | int | NO | - | CODE-BACKED | Input parameter. Manager or service writing the annotation. Written to `History.WithdrawToFundingAction.ManagerID`. |
| 3 | @AdditionalInformation | nvarchar(250) | YES | - | CODE-BACKED | Input parameter. The supplementary text to store on the WTF leg. Replaces any existing value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Guard + write target) | Billing.WithdrawToFunding | Read + Write | Existence check; UPDATE AdditionalInformation field via UpdateWithdraw2Funding |
| (EXEC) | Billing.UpdateWithdraw2Funding | Procedure call | Writes AdditionalInformation + ModificationDate to WTF + history |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingUpdateAdditionalInformation (procedure)
|- Billing.WithdrawToFunding (table) -- existence guard + update target
+-- Billing.UpdateWithdraw2Funding (procedure) -- field write + history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Existence guard + UPDATE target via UpdateWithdraw2Funding |
| Billing.UpdateWithdraw2Funding | Stored Procedure | Writes AdditionalInformation and logs WTF history |

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
EXEC Billing.WithdrawToFundingUpdateAdditionalInformation
    @ID                    = 12345,
    @ManagerID             = -1,
    @AdditionalInformation = N'Provider ref: TXN-ABC-789; Routing: SEPA-EUR';
```

### 8.2 Verify the update

```sql
SELECT ID, AdditionalInformation, ModificationDate
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE ID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingUpdateAdditionalInformation | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingUpdateAdditionalInformation.sql*
