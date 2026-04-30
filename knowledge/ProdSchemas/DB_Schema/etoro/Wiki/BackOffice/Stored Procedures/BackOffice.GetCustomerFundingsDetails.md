# BackOffice.GetCustomerFundingsDetails

> Returns FundingID, FundingTypeID, and email/account identifiers for a customer's PayPal, Skrill, and Neteller payment methods only.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - single customer; FundingTypeID IN (3, 8, 6) only |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This minimal procedure returns the identifying details (email addresses and account IDs) for a customer's e-wallet payment methods: PayPal (3), Skrill (8), and Neteller (6). It is used in BackOffice workflows where agents need to quickly see which digital wallet accounts a customer has on file without loading the full creditable MOP list.

Unlike `GetCustomerCrediableMOP`, this procedure returns all linked fundings regardless of whether there are approved deposits, and it does not compute exchange rates or totals.

---

## 2. Business Logic

### 2.1 E-Wallet Types Only

**What**: Filtered strictly to FundingTypeIDs 3, 8, and 6.

**Rules**:
- `WHERE BFUN.FundingTypeID IN (3, 8, 6)` - excludes all other funding types (wire, credit card, etc.)
- FundingTypeID 3 = PayPal, 8 = Skrill, 6 = Neteller

### 2.2 Payment Details by Type

**Rules**:
- FundingTypeID IN (3,8): `FundingData/EmailAsString` - the email registered with PayPal or Skrill
- FundingTypeID 6: `'AccountID: ' + AccountIDAsDecimal + '; email: ' + EmailAsString` - Neteller shows both the numeric account ID and the linked email

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose e-wallet funding details to return. |
| **Output Columns** | | | | | | |
| 2 | FundingID | INT | NO | - | CODE-BACKED | Unique ID of the funding record. FK to Billing.Funding.FundingID. |
| 3 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type: 3=PayPal, 8=Skrill, 6=Neteller. |
| 4 | PaymentDetails | VARCHAR | YES | NULL | CODE-BACKED | Key identifier for the payment method. For PayPal/Skrill: email address. For Neteller: "AccountID: {id}; email: {email}". Parsed from Billing.Funding.FundingData XML. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID / FundingID | Billing.CustomerToFunding | Primary JOIN | Customer's payment method associations |
| FundingID | Billing.Funding | Lookup / INNER JOIN | FundingData XML and FundingTypeID; filtered to types 3/8/6 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | E-wallet details display in customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerFundingsDetails (procedure)
|- Billing.CustomerToFunding (customer-funding links)
+-- Billing.Funding (FundingData XML, FundingTypeID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Customer's payment method associations |
| Billing.Funding | Table | FundingData XML for PaymentDetails; FundingTypeID filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | E-wallet account details in customer profile |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`; `SELECT DISTINCT` to deduplicate.
- `WITH(NOLOCK)` on both tables.

---

## 8. Sample Queries

### 8.1 Get e-wallet details for a customer

```sql
EXEC BackOffice.GetCustomerFundingsDetails @CID = 12345678;
```

### 8.2 Direct base-table query

```sql
SELECT DISTINCT BC.FundingID, BFUN.FundingTypeID,
    CASE
        WHEN BFUN.FundingTypeID IN (3,8) THEN BFUN.FundingData.value('/Funding[1]/EmailAsString[1]', 'VARCHAR(MAX)')
        WHEN BFUN.FundingTypeID = 6 THEN 'AccountID: ' + BFUN.FundingData.value('/Funding[1]/AccountIDAsDecimal[1]', 'VARCHAR(MAX)')
            + '; email: ' + BFUN.FundingData.value('/Funding[1]/EmailAsString[1]', 'VARCHAR(MAX)')
    END AS PaymentDetails
FROM Billing.CustomerToFunding BC WITH(NOLOCK)
INNER JOIN Billing.Funding BFUN WITH(NOLOCK) ON BC.FundingID = BFUN.FundingID
WHERE BC.CID = 12345678 AND BFUN.FundingTypeID IN (3, 8, 6);
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerFundingsDetails | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerFundingsDetails.sql*
