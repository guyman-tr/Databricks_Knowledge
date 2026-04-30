# Billing.WireTransferEdit

> Updates the TransactionID on a Billing.WireTransferToPayment record by WireTransferID - records the bank transaction reference number for a confirmed wire transfer payment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WireTransferID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WireTransferEdit` updates the `TransactionID` field on a `Billing.WireTransferToPayment` record. The TransactionID is the reference number assigned by the bank or wire transfer provider when the payment is confirmed - typically entered by a Back Office operator when reconciling incoming wire transfers against pending deposit records.

This is the write path for updating the bank's transaction reference for a wire transfer payment leg after it has been matched and confirmed.

---

## 2. Business Logic

### 2.1 Direct TransactionID Update

**What**: Single-column UPDATE on WireTransferToPayment.

**Rules**:
- `UPDATE Billing.WireTransferToPayment SET TransactionID = @TransactionID WHERE WireTransferID = @WireTransferID`
- No existence check; 0-row update if @WireTransferID not found
- `RETURN @@ERROR` - legacy error handling (returns 0 on success)
- No history logging, no transaction wrapper, no TRY/CATCH

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WireTransferID | INTEGER | NO | - | CODE-BACKED | PK of `Billing.WireTransferToPayment`. Identifies the wire transfer payment record to update. |
| 2 | @TransactionID | VARCHAR(20) | NO | - | CODE-BACKED | Bank transaction reference number assigned by the receiving bank or wire transfer provider when the payment is confirmed. Up to 20 characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WireTransferID | Billing.WireTransferToPayment | UPDATE | Sets TransactionID on the WireTransfer payment record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back Office (application) | Wire transfer reconciliation | Application call | Operators record bank transaction ID after confirming wire receipt |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WireTransferEdit (procedure)
+-- Billing.WireTransferToPayment (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WireTransferToPayment | Table | UPDATE target: sets TransactionID by WireTransferID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back Office (application) | Application | Called during wire transfer reconciliation to record bank reference |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No existence check | Design | 0-row update if @WireTransferID not found; no error raised |
| RETURN @@ERROR | Legacy | Returns SQL error code (0 = success) |
| No history logging | Design | Changes not audited in a history table |

---

## 8. Sample Queries

### 8.1 Record a bank transaction reference
```sql
EXEC Billing.WireTransferEdit
    @WireTransferID = 9876,
    @TransactionID  = 'TXN20260318001';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.WireTransferEdit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WireTransferEdit.sql*
