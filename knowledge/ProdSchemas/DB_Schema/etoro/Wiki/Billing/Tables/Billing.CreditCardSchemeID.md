# Billing.CreditCardSchemeID

> Per-customer, per-card registry of the best available payment SchemeID (card-on-file token) with a 3DS promotion rule: once a 3DS-authenticated SchemeID is stored for a card, it can never be replaced by a non-3DS token.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CID, FundingID) - composite PK CLUSTERED |
| **Partition** | N/A - DICTIONARY filegroup |
| **Indexes** | 1 (composite PK) |

---

## 1. Business Meaning

`Billing.CreditCardSchemeID` stores the payment SchemeID (network token / card-on-file identifier) associated with each customer's registered credit card. The SchemeID is the key that payment processors (checkout.com) use to charge a saved card without requiring the customer to re-enter card details - enabling Merchant Initiated Transactions (MIT) for features like recurring deposits and auto-renewals.

The table holds 2,816,375 rows - one per customer + card combination. The composite PK (CID, FundingID) enforces uniqueness: each customer can have at most one SchemeID record per card, representing the current best-authentication-level token for that card. `GetSavedCreditCard` and `GetSavedCreditCards` use this table to retrieve SchemeIDs when rendering saved card options and checking recurring eligibility.

The table was created in April 2021 (PAYUS-2720, by Shay O.) to enable card-on-file recurring payments.

---

## 2. Business Logic

### 2.1 3DS Promotion Rule (One-Way Upgrade)

**What**: The MERGE upsert in `CreditCardSchemeIDInsert` enforces a one-way promotion: a 3DS-authenticated SchemeID permanently replaces a non-3DS SchemeID, but a non-3DS SchemeID can NEVER replace an existing 3DS SchemeID.

**Columns/Parameters Involved**: `IsThreeDs`, `SchemeID`, `DepositID`

**Rules**:
```
On upsert (CreditCardSchemeIDInsert):
  - NOT MATCHED (new card for this CID+FundingID):
      -> INSERT with any IsThreeDs value
  - MATCHED AND existing.IsThreeDs = 0 AND new.IsThreeDs = 1:
      -> UPDATE SchemeID, DepositID, IsThreeDs=1 (PROMOTE to 3DS)
  - MATCHED AND existing.IsThreeDs = 1:
      -> NO UPDATE (3DS status is permanent, never downgraded)
  - MATCHED AND existing.IsThreeDs = 0 AND new.IsThreeDs = 0:
      -> NO UPDATE (same tier, no change)
```

**Diagram**:
```
Customer deposits with card (non-3DS):
  CreditCardSchemeIDInsert(@IsThreeDs=0) -> INSERT row (IsThreeDs=0)

Customer deposits again with same card + 3DS authentication:
  CreditCardSchemeIDInsert(@IsThreeDs=1) -> UPDATE SchemeID, IsThreeDs=1

Future deposits with same card (non-3DS attempt):
  CreditCardSchemeIDInsert(@IsThreeDs=0) -> NO UPDATE (3DS is preserved)
```

### 2.2 SchemeID Placeholder Pattern

**What**: A large proportion of SchemeIDs are placeholder values, not real payment network tokens.

**Columns/Parameters Involved**: `SchemeID`

**Rules**:
- "060720116005060" appears in 1,199,457 rows (43%) - a placeholder SchemeID used when the payment provider did not return a real scheme token.
- "000000000000020005060720116005060" appears in 541,268 rows (19%) - a longer variant placeholder.
- Real unique SchemeIDs (e.g., "483297487231504") have much lower row counts.
- Placeholder SchemeIDs are typically used when a payment method is linked to a card-on-file account but doesn't have a specific recurring token.

---

## 3. Data Overview

| CID | FundingID | SchemeID | IsThreeDs | DepositID | Meaning |
|-----|-----------|----------|-----------|-----------|---------|
| 692008 | 591084 | 060720116005060 | false | 8720859 | Placeholder SchemeID - card registered but no real network token returned. Non-3DS deposit D8720859 was the first/last to set this. |
| 692008 | 2426052 | 060720116005060 | false | 9324634 | Same customer, different card, same placeholder SchemeID. Two cards for CID 692008. |
| 2942607 | 930135 | 982717148216908 | false | 3973931 | Real-looking unique SchemeID - likely a genuine payment network token. Non-3DS. |
| - | - | (various) | true | - | 17,811 rows (0.6%) have IsThreeDs=1 - cards that went through 3DS authentication. These SchemeIDs are permanently locked as the best available token. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. Part of composite PK. Implicit FK to Customer.CustomerStatic(CID). One record per customer per card. |
| 2 | FundingID | int | NO | - | VERIFIED | The registered card (payment instrument). Part of composite PK. Implicit FK to Billing.Funding(FundingID). Combined with CID creates the one-record-per-card-per-customer guarantee. |
| 3 | SchemeID | nvarchar(255) | NO | - | VERIFIED | The payment network token / scheme identifier for this card. Set by the payment provider (checkout.com) during deposit or card authentication. Two common placeholder values: "060720116005060" (43% of rows) and "000000000000020005060720116005060" (19%). Real unique tokens have the 3DS promotion rule applied. |
| 4 | IsThreeDs | bit | NO | - | VERIFIED | Whether this SchemeID was obtained through 3DS authentication: 1=3DS-authenticated (17,811 rows, 0.6%), 0=non-3DS (99.4%). Once set to 1, NEVER reset to 0 (3DS promotion rule in CreditCardSchemeIDInsert MERGE). 3DS tokens are preferred for recurring payments and merchant-initiated transactions. |
| 5 | DepositID | int | NO | - | VERIFIED | ID of the deposit (Billing.Deposit) that last wrote or updated this SchemeID. On 3DS upgrade, updated to the deposit that triggered the 3DS authentication. Implicit FK to Billing.Deposit(DepositID). Provides audit trail - which deposit established the current SchemeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer whose card scheme is stored |
| FundingID | Billing.Funding | Implicit | The registered card linked to this SchemeID |
| DepositID | Billing.Deposit | Implicit | The deposit that established/last updated this SchemeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CreditCardSchemeIDInsert | CID, FundingID | WRITER (MERGE) | Upsert with 3DS promotion rule |
| Billing.GetCreditCardSchemeID | CID, FundingID | READER | Point lookup by customer + card |
| Billing.GetSavedCreditCard | (via JOIN) | READER | Retrieves SchemeID when showing saved card options |
| Billing.GetSavedCreditCards | (via JOIN) | READER | Lists all saved cards with SchemeIDs for a customer |
| Billing.GetFundingRecurringData | (via JOIN) | READER | Checks SchemeID for recurring payment eligibility |
| Billing.GetRecurringEligibility | (via JOIN) | READER | Determines if a card is eligible for recurring deposits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCardSchemeID (table)
  (no FK constraints in DDL - all relationships implicit)
```

### 6.1 Objects This Depends On

No dependencies (no FK constraints in DDL).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardSchemeIDInsert | Stored Procedure | WRITER - MERGE upsert with 3DS promotion rule |
| Billing.GetCreditCardSchemeID | Stored Procedure | READER - point lookup |
| Billing.GetSavedCreditCard | Stored Procedure | READER - saved card retrieval |
| Billing.GetSavedCreditCards | Stored Procedure | READER - multi-card listing |
| Billing.GetFundingRecurringData | Stored Procedure | READER - recurring data |
| Billing.GetRecurringEligibility | Stored Procedure | READER - eligibility check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CreditCardSchemeID | CLUSTERED PK | CID ASC, FundingID ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CreditCardSchemeID | PRIMARY KEY CLUSTERED | Unique (CID, FundingID) - one SchemeID record per customer per card |

---

## 8. Sample Queries

### 8.1 Get SchemeID for a specific customer and card
```sql
SELECT  CID, FundingID, SchemeID, IsThreeDs, DepositID
FROM    Billing.CreditCardSchemeID WITH (NOLOCK)
WHERE   CID = 692008
        AND FundingID = 591084;
```

### 8.2 Count cards by 3DS status for a customer
```sql
SELECT  CCSI.IsThreeDs,
        COUNT(*)    AS CardCount
FROM    Billing.CreditCardSchemeID CCSI WITH (NOLOCK)
WHERE   CCSI.CID = 692008
GROUP BY CCSI.IsThreeDs;
```

### 8.3 Find all customers with 3DS-authenticated SchemeIDs (recurring-ready cards)
```sql
SELECT  CCSI.CID,
        CCSI.FundingID,
        CCSI.SchemeID,
        CCSI.DepositID
FROM    Billing.CreditCardSchemeID CCSI WITH (NOLOCK)
WHERE   CCSI.IsThreeDs = 1
ORDER BY CCSI.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table. See related table [Billing.CreditCardAuthentication](Billing.CreditCardAuthentication.md) which has Confluence documentation for the Zero Auth / recurring payments flow that uses SchemeIDs.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CreditCardSchemeID | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CreditCardSchemeID.sql*
