# Billing.PayPalBillingAgreementGet

> Returns all PayPal Billing Agreement records for a given customer, providing the agreement IDs, linked funding instruments, and associated deposit references for PayPal recurring payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer whose agreements are returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayPalBillingAgreementGet` is the read procedure for `Billing.PayPalBillingAgreement`. When the PayPal integration or billing service needs to know which recurring payment agreements exist for a customer, it calls this procedure. The returned rows provide all the linking information needed to process a PayPal recurring charge: the provider's BillingAgreementID token, the customer's FundingID (which payment instrument to charge), and the DepositID (the originating deposit that established this agreement).

Created as part of PAYUSOLA-4629 (PayPal Billing Agreement feature).

---

## 2. Business Logic

### 2.1 Customer Agreement Lookup

**What**: Returns all active billing agreements for a customer.

**Columns Involved**: `Billing.PayPalBillingAgreement.CID`

**Rules**:
- SELECT * (all columns) FROM Billing.PayPalBillingAgreement WHERE CID=@CID.
- Returns all rows for the customer - a customer may have 0, 1, or multiple agreements.
- No status filter: returns all rows regardless of state.
- Since the table is system-versioned temporal, this query targets the current (live) table only - does not include deleted/historical agreements.

**Diagram**:
```
@CID (customer)
  |
  SELECT PayPalBillingAgreementID, CID, FundingID, BillingAgreementID, DepositID
  FROM Billing.PayPalBillingAgreement
  WHERE CID = @CID
  |
  Returns: 0..N agreement rows (current, not historical)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | The customer ID to query. Matched against `Billing.PayPalBillingAgreement.CID`. |

**Result Set Columns**:

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | PayPalBillingAgreementID | Billing.PayPalBillingAgreement.PayPalBillingAgreementID | Surrogate PK - internal agreement record ID |
| 2 | CID | Billing.PayPalBillingAgreement.CID | Customer ID - always equals @CID |
| 3 | FundingID | Billing.PayPalBillingAgreement.FundingID | The Billing.Funding instrument linked to this agreement |
| 4 | BillingAgreementID | Billing.PayPalBillingAgreement.BillingAgreementID | PayPal's agreement token (e.g., 'B-1AB23456...') - used to charge the customer via PayPal API |
| 5 | DepositID | Billing.PayPalBillingAgreement.DepositID | The deposit that created/activated this agreement |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | [Billing.PayPalBillingAgreement](../Tables/Billing.PayPalBillingAgreement.md) | Read (SELECT) | Returns all current billing agreements for the customer. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayPal billing application | - | EXEC | Called to retrieve existing agreements before processing a recurring PayPal payment. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayPalBillingAgreementGet (procedure)
└── Billing.PayPalBillingAgreement (system-versioned temporal table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.PayPalBillingAgreement](../Tables/Billing.PayPalBillingAgreement.md) | Table | SELECT - reads current (non-historical) billing agreements for a customer. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PayPal application | Application | Retrieves billing agreements for recurring payment processing. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The WHERE CID=@CID filter benefits from an index on the CID column in `Billing.PayPalBillingAgreement`. As a temporal table, the query targets only the current table (system period SysEndTime = '9999-12-31...').

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all billing agreements for a customer

```sql
EXEC Billing.PayPalBillingAgreementGet
    @CID = 12345;
-- Returns all PayPal billing agreements for customer 12345
```

### 8.2 Direct query equivalent

```sql
SELECT
    PayPalBillingAgreementID,
    CID,
    FundingID,
    BillingAgreementID,
    DepositID
FROM Billing.PayPalBillingAgreement WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Check if a customer has any active agreements

```sql
SELECT COUNT(*) AS AgreementCount
FROM Billing.PayPalBillingAgreement WITH (NOLOCK)
WHERE CID = 12345;
-- 0 = no agreements, >0 = has agreements
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUSOLA-4629 | Jira (referenced in code comment) | PayPal Billing Agreement feature - this procedure is the read accessor for agreement records |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 1 Jira (code comment) | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayPalBillingAgreementGet | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayPalBillingAgreementGet.sql*
