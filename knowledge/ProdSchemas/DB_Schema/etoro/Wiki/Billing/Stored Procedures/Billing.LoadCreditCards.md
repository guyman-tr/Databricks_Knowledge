# Billing.LoadCreditCards

> Returns all rows from Billing.CreditCard - a startup cache loader for the PCI-compliant credit card registry (~55,320 hashed card records across Visa, Mastercard, and Amex).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Billing.CreditCard |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadCreditCards` is a full reference data loader that returns the complete credit card registry. The billing service calls this at startup to populate an in-memory lookup cache of registered credit cards by CardID or card number hash, enabling fast local lookups during payment processing without database roundtrips.

`Billing.CreditCard` contains ~55,320 records storing PCI-compliant card number hashes (not actual PANs) with Dynamic Data Masking applied. Cards are distributed as: Visa (~66%, 36,588), Mastercard (~33%, 18,527), Amex (<1%, 205).

Note: Loading the full card registry (~55K rows) may be acceptable at startup but callers should consider the memory footprint and DDM implications - non-privileged users receive masked `CardNumber` values.

---

## 2. Business Logic

### 2.1 Full Credit Card Registry Load

**What**: SELECT * with no filter - returns all rows and all columns from Billing.CreditCard.

**Columns/Parameters Involved**: CardID, CardNumber (hash, DDM-masked), CardTypeID

**Rules**:
- No parameters; no filtering; returns entire registry
- WITH (NOLOCK) for non-blocking reads
- CardNumber column has DDM applied - non-privileged callers see masked values
- CardTypeID: 1=Visa, 2=Mastercard, 3=Amex (based on live distribution)
- RETURN 0 signals success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `Billing.CreditCard` WITH NOLOCK (~55,320 rows). Key columns: CardID (IDENTITY PK), CardNumber (hashed PAN, DDM-masked for non-privileged users), CardTypeID (1=Visa/2=Mastercard/3=Amex).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.CreditCard | READ | Returns full credit card registry; PCI-compliant hash storage, DDM on CardNumber |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup for credit card registry cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadCreditCards (procedure)
└── Billing.CreditCard (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCard | Table | Full credit card registry source (~55,320 rows; CardNumber is hashed PAN with DDM) |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`; `WITH (NOLOCK)`
- DDM on `CardNumber` column: callers without UNMASK permission receive masked values
- ~55,320 rows loaded at startup - reasonable for in-memory cache
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 Credit card distribution by type
```sql
SELECT CardTypeID, COUNT(*) AS Count
FROM Billing.CreditCard WITH (NOLOCK)
GROUP BY CardTypeID
ORDER BY Count DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadCreditCards | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadCreditCards.sql*
