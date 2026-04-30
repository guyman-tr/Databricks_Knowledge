# Billing.DepositUpdateRefundDetails

> Sets the ClearingHouseEffectiveDate and RefundVerificationCode on a specific deposit - records clearing house settlement date and refund verification code during the refund processing flow.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit.ClearingHouseEffectiveDate + RefundVerificationCode |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositUpdateRefundDetails` updates two refund-specific columns on a deposit: `ClearingHouseEffectiveDate` (the settlement date when the refund cleared through the ACH/banking clearing house) and `RefundVerificationCode` (a verification code from the payment processor confirming the refund). These fields are relevant for offline/ACH deposits where clearing house settlement is tracked separately from the deposit status change.

The SP is the write counterpart for refund verification data - typically called after a refund is initiated and the clearing house provides settlement confirmation. Note that `Billing.DepositRollback` clears both fields (sets to NULL) when a rollback is processed; this SP is used to initially populate them.

---

## 2. Business Logic

### 2.1 Refund Detail Update

**Rules**:
- `UPDATE Billing.Deposit SET ClearingHouseEffectiveDate=@ClearingHouseEffectiveDate, RefundVerificationCode=@RefundVerificationCode WHERE DepositID=@DepositID`.
- Both fields nullable - can be set to NULL to clear them.
- `@@ROWCOUNT = 0` -> RAISERROR(60025, 'Deposit does not exists') + RETURN 60025.
- CATCH: ROLLBACK if @@TRANCOUNT=1; COMMIT if >1. `EXEC Internal.CallRaiseError`.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | PK of the deposit to update. Validated via @@ROWCOUNT - error 60025 if not found. |
| 2 | @ClearingHouseEffectiveDate | DATETIME | YES | NULL | CODE-BACKED | Date the refund cleared through the ACH/banking clearing house. Written to Billing.Deposit.ClearingHouseEffectiveDate. Cleared to NULL by Billing.DepositRollback. |
| 3 | @RefundVerificationCode | VARCHAR(50) | YES | NULL | CODE-BACKED | Verification code from the payment processor confirming the refund transaction. Written to Billing.Deposit.RefundVerificationCode. Cleared to NULL by Billing.DepositRollback. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | MODIFIER (UPDATE) | Sets ClearingHouseEffectiveDate and RefundVerificationCode. |
| CATCH block | Internal.CallRaiseError | EXEC (cross-schema) | Standardized error handler. |

---

## 6. Dependencies

```
Billing.DepositUpdateRefundDetails (procedure)
+-- Billing.Deposit (table)
+-- Internal.CallRaiseError (procedure) [cross-schema, CATCH only]
```

---

## 7. Technical Details

Same pattern as `Billing.DepositUpdateProcessorValueDate` - @@ROWCOUNT validation, Internal.CallRaiseError in CATCH.

---

## 8. Sample Queries

```sql
EXEC [Billing].[DepositUpdateRefundDetails]
    @DepositID = 12345678,
    @ClearingHouseEffectiveDate = '2026-03-17 00:00:00',
    @RefundVerificationCode = 'ACH-CONF-20260317-001';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositUpdateRefundDetails | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositUpdateRefundDetails.sql*
