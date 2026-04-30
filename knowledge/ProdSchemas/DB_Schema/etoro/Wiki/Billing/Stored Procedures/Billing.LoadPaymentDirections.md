# Billing.LoadPaymentDirections

> Returns all rows from Dictionary.PaymentDirection - a startup cache loader for the payment direction reference table (Deposit/Withdrawal classifications).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Dictionary.PaymentDirection |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadPaymentDirections` is a startup cache loader for the payment direction reference table. The billing service loads this tiny lookup table at startup to resolve PaymentDirectionID values to their display labels (e.g., 1=Deposit, 2=Withdrawal or equivalent). Payment direction categorizes whether a given financial transaction is money coming in or going out.

---

## 2. Business Logic

### 2.1 Full Payment Direction Load

**What**: SELECT * with no filter - returns all rows and all columns from Dictionary.PaymentDirection.

**Rules**:
- No parameters; no filtering
- **No WITH (NOLOCK)** (like LoadFundingTypes and LoadPaymentDirections - consistent for small Dictionary tables)
- RETURN 0 signals success
- Very small table (typically 2-3 rows: Deposit + Withdrawal + possibly Refund)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `Dictionary.PaymentDirection`. Typically: PaymentDirectionID (PK), PaymentDirectionName (display label). Values likely: 1=Deposit, 2=Withdrawal (and possibly 3=Refund or similar).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Dictionary.PaymentDirection | READ | Returns complete payment direction lookup (no NOLOCK hint) |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup for payment direction lookup cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPaymentDirections (procedure)
└── Dictionary.PaymentDirection (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentDirection | Table | Payment direction reference table (Deposit/Withdrawal); no NOLOCK |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`
- No WITH (NOLOCK) - consistent with LoadFundingTypes pattern for Dictionary schema tables called without NOLOCK
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 View all payment directions
```sql
SELECT * FROM Dictionary.PaymentDirection WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.8/10 (Elements: 6/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPaymentDirections | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPaymentDirections.sql*
