# Billing.DepositUpdateProcessorValueDate

> Sets the ProcessorValueDate on a specific deposit - updates the settlement value date from the payment processor for offline/wire deposits.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit.ProcessorValueDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositUpdateProcessorValueDate` updates the `ProcessorValueDate` column on a deposit. `ProcessorValueDate` is the settlement value date provided by the payment processor - the date the funds are considered settled at the bank/clearing house level. This date is particularly relevant for offline payment methods (wire transfers, local bank wires) where settlement occurs asynchronously.

The SP validates that the deposit exists (@@ROWCOUNT must be 1) and uses `Internal.CallRaiseError` for standardized error propagation in the CATCH block.

---

## 2. Business Logic

### 2.1 ProcessorValueDate Update

**Rules**:
- `UPDATE Billing.Deposit SET ProcessorValueDate = @ProcessorValueDate WHERE DepositID = @DepositID`.
- `@@ROWCOUNT` check: if 0 rows affected -> @error_num = 60025, RAISERROR(60025, 'Deposit does not exists').
- Allows NULL for @ProcessorValueDate (can clear the date).
- CATCH: ROLLBACK if @@TRANCOUNT=1; COMMIT if >1 (nested). `EXEC Internal.CallRaiseError` for standardized error logging/re-raise.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | PK of the deposit to update. Validated via @@ROWCOUNT - error 60025 if deposit not found. |
| 2 | @ProcessorValueDate | DATETIME | YES | NULL | CODE-BACKED | Settlement value date from the payment processor. Nullable - can be cleared. Written to Billing.Deposit.ProcessorValueDate. For offline deposits, this records the actual bank settlement date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | MODIFIER (UPDATE) | Sets ProcessorValueDate. Validates existence via @@ROWCOUNT. |
| CATCH block | Internal.CallRaiseError | EXEC (cross-schema) | Standardized error re-raise/logging on unexpected failures. |

---

## 6. Dependencies

```
Billing.DepositUpdateProcessorValueDate (procedure)
+-- Billing.Deposit (table)
+-- Internal.CallRaiseError (procedure) [cross-schema, CATCH only]
```

---

## 7. Technical Details

Uses `@@ROWCOUNT = 1` validation for existence check (more reliable than EXISTS SELECT for single-row updates). `Internal.CallRaiseError` is a standardized error handler used across Billing SPs.

---

## 8. Sample Queries

```sql
EXEC [Billing].[DepositUpdateProcessorValueDate]
    @DepositID = 12345678,
    @ProcessorValueDate = '2026-03-17 00:00:00';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositUpdateProcessorValueDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositUpdateProcessorValueDate.sql*
