# Billing.LoadCreditCardToPayment

> Returns all rows from Billing.CreditCardToPayment - a startup cache loader for the legacy credit card payment billing detail store (currently 0 rows; the legacy payment flow has been retired).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Billing.CreditCardToPayment |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadCreditCardToPayment` is a startup cache loader for the legacy credit card payment billing detail store. `Billing.CreditCardToPayment` held cardholder billing address and contact snapshots for credit card payments made through the legacy `Billing.Payment` system (the three-table pattern: CreditCard + Payment + CreditCardToPayment).

**Legacy status**: `Billing.CreditCardToPayment` currently has 0 rows. The modern deposit system uses `Billing.Deposit` + `Billing.Funding` and does not populate this table. This procedure will return an empty result set when called. It is retained for backward compatibility (callers that expect this data structure at startup) or historical reference.

---

## 2. Business Logic

### 2.1 Full Legacy Payment Detail Load

**What**: SELECT * with no filter - returns all rows and all columns from Billing.CreditCardToPayment.

**Rules**:
- No parameters; no filtering; WITH (NOLOCK)
- Currently returns 0 rows (table empty - legacy system retired)
- Five PII columns are DDM-masked: CardHolderFirstName, CardHolderLastName, CardHolderEmail, CardHolderPhoneNumber, ZipCode
- RETURN 0 signals success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `Billing.CreditCardToPayment` (0 rows in live system). Includes (CardID, PaymentID) composite PK plus cardholder billing details (5 DDM-masked PII columns).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.CreditCardToPayment | READ | Legacy cardholder billing detail store; currently 0 rows; 5 DDM-masked PII columns |

### 5.2 Referenced By (other objects point to this)

Called from the legacy billing application startup for credit card payment detail cache (returns empty in modern deployment).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadCreditCardToPayment (procedure)
└── Billing.CreditCardToPayment (table - legacy, 0 rows)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardToPayment | Table | Legacy billing detail store; SELECT * returns empty result set in current production state |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`; `WITH (NOLOCK)`
- Returns 0 rows (table empty); legacy procedure retained for backward compatibility
- DDM applies to 5 PII columns even in an empty result
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 Confirm table is empty
```sql
SELECT COUNT(*) FROM Billing.CreditCardToPayment WITH (NOLOCK)
-- Expected: 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadCreditCardToPayment | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadCreditCardToPayment.sql*
