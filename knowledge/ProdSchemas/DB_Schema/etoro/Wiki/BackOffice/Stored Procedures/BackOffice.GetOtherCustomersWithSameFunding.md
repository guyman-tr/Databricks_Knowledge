# BackOffice.GetOtherCustomersWithSameFunding

> Returns the CIDs of all other customers who share the same funding instrument (payment method) as the specified customer - a fraud and risk detection lookup for identifying linked accounts through shared payment methods.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure answers the fraud/risk investigation question: "Are there other customers using the same payment method as this customer?" By querying `Billing.CustomerToFunding`, it finds all customers linked to a given FundingID other than the customer under review.

A FundingID represents a specific payment instrument - a credit card, bank account, e-wallet, or other funding source stored in the Billing system. When multiple customers share the same FundingID, it may indicate:
- Linked accounts (family members, business partners)
- Fraudulent account duplication (one person operating multiple accounts)
- Chargeback/refund fraud coordination
- Money mule networks

This procedure is used by BackOffice fraud analysts and risk teams when investigating chargebacks, suspicious deposits, or multi-account violations. The result CIDs can then be cross-referenced against other risk signals.

**Created**: 2021-05-30 by Ran (Jira ticket MIMOPS-4187).
**Permission**: No active EXECUTE grants found in permission files. Likely used for ad-hoc BI/fraud investigation queries.

---

## 2. Business Logic

### 2.1 Shared Funding Lookup (Excluding Self)

**What**: Returns all customers linked to a specific funding instrument, excluding the customer being investigated.

**Columns/Parameters Involved**: Billing.CustomerToFunding.CID, Billing.CustomerToFunding.FundingID, @CID, @FundingID

**Rules**:
- `FundingID = @FundingID`: Scopes to the specific payment instrument of interest.
- `CID <> @CID`: Excludes the customer being investigated from their own results - only returns OTHER customers sharing the same funding.
- Returns only the CID column - callers join to other tables for additional customer details.
- No TOP limit - returns all matching customers regardless of count.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The customer under investigation. Excluded from results via CID <> @CID. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | The funding instrument identifier (from Billing.Funding) to search for shared usage. Represents a specific payment method (credit card, bank account, e-wallet, etc.). |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID of another customer who has used or is linked to the same FundingID. Each row represents one customer account sharing the payment instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID, CID | Billing.CustomerToFunding | Read (FROM) | Many-to-many junction table linking customers to their funding instruments. Filtered by FundingID to find shared payment methods. |
| @FundingID | Billing.Funding | Implicit | FundingID is the PK of Billing.Funding, which stores the payment instrument details (card hash, bank account info, etc.). |
| Output CID | Customer.CustomerStatic | Implicit | Returned CIDs link to the Customer schema for further investigation. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetOtherCustomersWithSameFunding (procedure)
+-- Billing.CustomerToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | FROM clause; links customers to funding instruments; filtered by FundingID, excluding @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No EXECUTE grants; ad-hoc fraud/risk investigation use |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CID <> @CID | Self-exclusion | Prevents the investigated customer from appearing in their own results |
| No NOLOCK | Locking | Unlike many BackOffice SPs, no NOLOCK hint - reads current committed data |
| No TOP | No limit | Returns all matching customers; callers should handle large result sets |

---

## 8. Sample Queries

### 8.1 Find other customers sharing a specific funding

```sql
EXEC BackOffice.GetOtherCustomersWithSameFunding
    @CID = 12345678,
    @FundingID = 98765
```

### 8.2 Look up the funding instrument details first

```sql
-- Find all FundingIDs for a customer, then investigate each
SELECT ctf.FundingID, f.FundingTypeID, f.MaskedPAN, f.BankName
FROM Billing.CustomerToFunding ctf WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = ctf.FundingID
WHERE ctf.CID = 12345678;
```

### 8.3 Find customers sharing any funding with a given customer

```sql
SELECT DISTINCT ctf2.CID
FROM Billing.CustomerToFunding ctf1 WITH (NOLOCK)
JOIN Billing.CustomerToFunding ctf2 WITH (NOLOCK)
    ON ctf2.FundingID = ctf1.FundingID
    AND ctf2.CID <> ctf1.CID
WHERE ctf1.CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetOtherCustomersWithSameFunding | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetOtherCustomersWithSameFunding.sql*
