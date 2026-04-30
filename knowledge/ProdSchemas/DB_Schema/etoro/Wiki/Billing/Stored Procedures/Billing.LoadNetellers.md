# Billing.LoadNetellers

> Returns all rows from Billing.Neteller - a startup cache loader for the Neteller e-wallet account registry (~1,687 registered Neteller accounts).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Billing.Neteller |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadNetellers` is a startup cache loader for the Neteller e-wallet account registry. The billing service loads this at startup to enable fast local lookups of registered Neteller accounts by NetellerID or AccountID, supporting payment processing and reconciliation for legacy Neteller transactions.

`Billing.Neteller` holds ~1,687 rows representing customer Neteller accounts (AccountID + SecureID pairs). Neteller is an older e-wallet payment method with limited but historically significant usage on the eToro platform. The registry is loaded as part of the legacy payment instrument startup sequence alongside `LoadNetellers` companion `LoadNetellerToPayments`.

---

## 2. Business Logic

### 2.1 Full Neteller Registry Load

**What**: SELECT * with no filter - returns all rows and all columns from Billing.Neteller.

**Rules**:
- No parameters; no filtering; WITH (NOLOCK)
- Returns NetellerID (IDENTITY PK), AccountID (Neteller's public account number, UNIQUE), SecureID (Neteller auth credential)
- ~1,687 rows
- RETURN 0 signals success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `Billing.Neteller` (~1,687 rows): NetellerID (IDENTITY PK), AccountID (UNIQUE - Neteller account number), SecureID (6-digit Neteller security credential).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.Neteller | READ | Neteller e-wallet account registry (~1,687 rows) |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup for Neteller account cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadNetellers (procedure)
└── Billing.Neteller (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Neteller | Table | Neteller account registry; ~1,687 registered Neteller e-wallet accounts |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`; `WITH (NOLOCK)`
- Companion to `LoadNetellerToPayments` (loads the Neteller-to-payment link table)
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 View all registered Neteller accounts
```sql
SELECT NetellerID, AccountID FROM Billing.Neteller WITH (NOLOCK)
ORDER BY NetellerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 sibling analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadNetellers | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadNetellers.sql*
