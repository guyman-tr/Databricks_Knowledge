# Billing.LoadNetellerToPayments

> Returns all rows from Billing.NetellerToPayment - a startup cache loader for the Neteller-to-legacy-payment link table (5,745 records associating Neteller accounts with historical Billing.Payment deposits).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Billing.NetellerToPayment |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadNetellerToPayments` is a startup cache loader for the Neteller payment link table. It loads all 5,745 records that associate Neteller e-wallet accounts (from `Billing.Neteller`) with their corresponding legacy `Billing.Payment` deposit records. The billing service caches this data to enable fast lookups when reconciling or resolving Neteller payment details without database queries.

`Billing.NetellerToPayment` stores the payer details returned by the Neteller gateway callback: TransactionID (Neteller's reference), FirstName, LastName, Email. These are populated in a two-step process: INSERT at payment creation, UPDATE on gateway callback. The table holds records for 1,687 unique Neteller accounts across 5,745 payment transactions.

---

## 2. Business Logic

### 2.1 Full Neteller-Payment Link Load

**What**: SELECT * with no filter - returns all rows and all columns from Billing.NetellerToPayment.

**Rules**:
- No parameters; no filtering; WITH (NOLOCK)
- 5,745 rows covering historical Neteller deposit history
- Columns include: (NetellerID, PaymentID) composite PK, TransactionID (Neteller reference), Email, FirstName, LastName
- RETURN 0 signals success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `Billing.NetellerToPayment` (5,745 rows): NetellerID + PaymentID (composite PK), TransactionID, FirstName, LastName, Email (populated on Neteller gateway callback).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.NetellerToPayment | READ | Neteller-to-legacy-payment link table (5,745 rows) |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup for Neteller payment detail cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadNetellerToPayments (procedure)
└── Billing.NetellerToPayment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.NetellerToPayment | Table | Neteller-to-payment link table; 5,745 historical Neteller deposit records |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`; `WITH (NOLOCK)`
- Companion to `LoadNetellers` (loads the Neteller account registry)
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 View Neteller payment history (joined)
```sql
SELECT n.AccountID, ntp.PaymentID, ntp.TransactionID, ntp.Email
FROM Billing.NetellerToPayment ntp WITH (NOLOCK)
JOIN Billing.Neteller n WITH (NOLOCK) ON ntp.NetellerID = n.NetellerID
ORDER BY ntp.PaymentID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 sibling analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadNetellerToPayments | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadNetellerToPayments.sql*
