# Billing.UpdateExTransactionID

> Sets the external (provider) transaction ID on a Billing.Deposit record - a focused single-field UPDATE originally created for wire transfer reference recording in Back Office screens.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - targets Billing.Deposit.ExTransactionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateExTransactionID` is a focused single-column UPDATE that records the payment provider's external transaction ID on a deposit. Created in October 2016 (ticket 41085 - "Add wire details to BO screens"), its original purpose was to allow Back Office operators to enter the bank reference number from a wire transfer - so that wire deposits could be linked to their provider-side transaction for reconciliation and audit.

`ExTransactionID` on `Billing.Deposit` is the provider's reference for this transaction (SWIFT reference, bank transaction number, PSP confirmation code, or acquirer reference number). It is indexed (`BDEP_ExTransactionID`) and queried via `Billing.GetDepositByExTransactionID` for reconciliation lookups.

Note: `Billing.UpdateDepositData` also updates `ExTransactionID` as one of its 10 patched fields. Both procedures serve the Deposit service (DepositUser role). `UpdateExTransactionID` is the older, more focused variant - created before the general-purpose patch SP was built. It remains in use for callers that only need to set the external transaction ID.

---

## 2. Business Logic

### 2.1 External Transaction ID Recording

**What**: Sets the provider's external transaction ID on the deposit, enabling provider-side reconciliation and lookup by external reference.

**Columns/Parameters Involved**: `@DepositID`, `@ExTransactionID`, `Billing.Deposit.ExTransactionID`

**Rules**:
- `UPDATE Billing.Deposit SET ExTransactionID = @ExTransactionID WHERE DepositID = @DepositID`
- `@ExTransactionID` is NOT NULL - this SP unconditionally sets the value (no ISNULL pattern)
- Unlike `UpdateDepositData`, this SP can write NULL if the caller passes NULL explicitly (the parameter has no default)
- If `@DepositID` does not exist, the UPDATE silently affects 0 rows
- `ExTransactionID` is indexed by `BDEP_ExTransactionID` (NONCLUSTERED) - the UPDATE maintains this index

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | Primary key of the deposit to update. Maps to `Billing.Deposit.DepositID`. If DepositID does not exist, the UPDATE silently affects 0 rows. |
| 2 | @ExTransactionID | VARCHAR(50) | NO | - | CODE-BACKED | The payment provider's external transaction reference. Written to `Billing.Deposit.ExTransactionID`. For wire deposits: the bank reference/SWIFT number. For card deposits: the acquirer or PSP transaction ID. Indexed (BDEP_ExTransactionID) for external reference lookups via Billing.GetDepositByExTransactionID. Max 50 chars. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE DepositID | Billing.Deposit | UPDATE | Sets ExTransactionID on the target deposit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit service | @DepositID, @ExTransactionID | EXEC (DepositUser role) | Called to record the provider's transaction reference on a deposit; originally for wire transfer reference entry in Back Office |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateExTransactionID (procedure)
`- Billing.Deposit (table) - UPDATE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE - sets ExTransactionID WHERE DepositID=@DepositID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Deposit service (DepositUser role). See also Billing.UpdateDepositData which patches ExTransactionID alongside other fields. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Target column `ExTransactionID` is covered by `BDEP_ExTransactionID` (NONCLUSTERED, DATA_COMPRESSION=PAGE) on `Billing.Deposit` - this index is maintained by the UPDATE and supports subsequent lookups by external transaction ID.

### 7.2 Constraints

N/A for stored procedure. Unlike `Billing.UpdateDepositData` (which uses `ISNULL(@ExTransactionID, ExTransactionID)`), this SP does NOT use the ISNULL guard - passing NULL explicitly will overwrite an existing ExTransactionID with NULL. This is the original behavior from the 2016 wire details implementation.

---

## 8. Sample Queries

### 8.1 Set the wire transfer reference
```sql
-- Record SWIFT/bank reference for a wire deposit
EXEC Billing.UpdateExTransactionID @DepositID = 10780413, @ExTransactionID = 'SWIFT-REF-20260318-001';
```

### 8.2 Verify the ExTransactionID was set
```sql
SELECT DepositID, ExTransactionID, PaymentStatusID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 10780413;
```

### 8.3 Look up a deposit by its external transaction ID
```sql
-- Use Billing.GetDepositByExTransactionID for external reference lookups
EXEC Billing.GetDepositByExTransactionID @ExTransactionID = 'SWIFT-REF-20260318-001';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Internal code comment references ticket 41085 (October 2016) for the original wire details feature in Back Office screens.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (UpdateDepositData - related multi-field SP) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateExTransactionID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateExTransactionID.sql*
