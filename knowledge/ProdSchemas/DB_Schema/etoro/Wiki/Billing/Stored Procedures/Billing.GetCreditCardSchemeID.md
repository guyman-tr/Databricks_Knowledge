# Billing.GetCreditCardSchemeID

> Returns the SchemeID (card-on-file network token), 3DS status, and associated deposit for a specific customer-card combination, enabling the deposit service to retrieve the best available payment token for recurring charges.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID composite lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCreditCardSchemeID` retrieves the stored card-on-file network token (SchemeID) for a specific customer's credit card. A SchemeID is the identifier that payment processors like checkout.com use to charge a saved card without requiring the customer to re-enter card details - it is the key that enables Merchant Initiated Transactions (MIT), recurring deposits, and auto-renewals on eToro.

The procedure exists as the read-side counterpart to `CreditCardSchemeIDInsert` (the upsert that creates/upgrades tokens). When the deposit service needs to process a recurring or MIT charge for a customer, it calls this procedure to retrieve the current best-quality SchemeID for the specified card. The "best quality" is determined by the 3DS promotion rule maintained during inserts: a 3DS-authenticated token permanently supersedes a non-3DS token.

Data flow: The deposit service calls this procedure with a customer ID and funding instrument ID. If a SchemeID row exists (created by a previous deposit that returned a network token), the procedure returns it with the 3DS flag and the reference deposit that established this token. The caller then uses the SchemeID to initiate a new charge with the payment processor. If no row exists (new card or payment processor never returned a token), the procedure returns no rows and the service falls back to a standard card charge.

---

## 2. Business Logic

### 2.1 3DS Status as Token Quality Indicator

**What**: The `IsThreeDs` flag indicates whether the stored SchemeID was obtained through a 3DS-authenticated transaction, which affects its eligibility for higher-value recurring charges.

**Columns/Parameters Involved**: `IsThreeDs`, `SchemeID`

**Rules**:
- `IsThreeDs = 1`: Token obtained via 3DS authentication. Eligible for higher-value recurring charges and considered the highest-quality token for this card. Once set to 1, never reverted (one-way promotion via `CreditCardSchemeIDInsert`).
- `IsThreeDs = 0`: Token obtained without 3DS. Valid for standard recurring charges but may be subject to lower transaction limits depending on payment processor rules.
- Only 0.6% of records (17,811 of 2.8M) have IsThreeDs=1 - 3DS authentication is the exception, not the rule.
- The deposit service uses this flag to decide whether to attempt an MIT directly or require a new 3DS challenge.

### 2.2 SchemeID Placeholder Pattern

**What**: A large proportion of SchemeIDs are placeholder values, not real network tokens.

**Columns/Parameters Involved**: `SchemeID`

**Rules**:
- "060720116005060" (43% of rows) and "000000000000020005060720116005060" (19% of rows) are placeholder values - returned when the payment processor did not issue a real recurring token.
- The caller must handle placeholder SchemeIDs differently from real tokens - a placeholder typically means the card cannot be used for MIT and requires a fresh customer-initiated transaction.
- Real unique SchemeIDs have low row counts and are typically 15-digit values from the card network.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | The credit card payment instrument to look up. References Billing.Funding.FundingID. Combined with @CID to form the composite key lookup - same card registered by different customers gets separate rows. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the card owner. Part of the composite key (CID, FundingID) in Billing.CreditCardSchemeID. Ensures each customer's token is retrieved independently even if the same physical card is shared. |

**Returns** (SELECT output columns):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | FundingID | INT | NO | VERIFIED | Echo of the input @FundingID. Identifies which payment instrument this SchemeID belongs to. Part of the composite PK (CID, FundingID). Inherited from Billing.CreditCardSchemeID. |
| 2 | CID | INT | NO | VERIFIED | Echo of the input @CID. Customer who registered this card. Part of the composite PK. Inherited from Billing.CreditCardSchemeID. |
| 3 | SchemeID | VARCHAR | NO | VERIFIED | Card-on-file network token issued by the payment processor (checkout.com). Used to initiate MIT/recurring charges without requiring the customer to re-enter card details. 43% of rows contain placeholder "060720116005060"; 19% contain "000000000000020005060720116005060" - callers must check for placeholder values. Inherited from Billing.CreditCardSchemeID. |
| 4 | IsThreeDs | BIT | NO | VERIFIED | Whether the stored SchemeID was obtained via a 3DS-authenticated transaction. 1 = 3DS authenticated (highest quality, eligible for higher-value MIT); 0 = non-3DS (standard quality). One-way upgrade: once set to 1 by CreditCardSchemeIDInsert, never reverted. 0.6% of records are 3DS. Inherited from Billing.CreditCardSchemeID. |
| 5 | DepositID | INT | YES | VERIFIED | The DepositID of the transaction that established or last upgraded this SchemeID. Allows the deposit service to trace which deposit originally tokenized this card and whether the 3DS status was set during a specific deposit flow. Inherited from Billing.CreditCardSchemeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID + @CID | Billing.CreditCardSchemeID | Direct read (SELECT) | Composite key lookup - retrieves the token row for this customer-card pair |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser | EXECUTE grant | Permission | Deposit service SQL user - primary caller when processing recurring or MIT credit card charges |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCreditCardSchemeID (procedure)
└── Billing.CreditCardSchemeID (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardSchemeID | Table | Direct SELECT with NOLOCK - returns all columns where CID = @CID AND FundingID = @FundingID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called directly by deposit application service (DepositUser); no stored procedures call this procedure. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Look up the SchemeID for a specific customer's card

```sql
-- Returns the card-on-file token (if any) for customer 692008 with card 591084
EXEC [Billing].[GetCreditCardSchemeID]
    @FundingID = 591084,
    @CID = 692008
```

### 8.2 Check SchemeID status directly in the table

```sql
-- Inspect the token record for a specific customer-card combination
SELECT FundingID, CID, SchemeID, IsThreeDs, DepositID
FROM [Billing].[CreditCardSchemeID] WITH (NOLOCK)
WHERE CID = 692008
  AND FundingID = 591084
```

### 8.3 Find all cards with real (non-placeholder) 3DS tokens

```sql
-- Identify customers with the highest-quality tokens (3DS + real SchemeID)
SELECT TOP 20 CID, FundingID, SchemeID, DepositID
FROM [Billing].[CreditCardSchemeID] WITH (NOLOCK)
WHERE IsThreeDs = 1
  AND SchemeID NOT IN ('060720116005060', '000000000000020005060720116005060')
ORDER BY DepositID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Payments - HLD + recurring investment updates](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1757904914) | Confluence | Page found referencing SchemeID in MIT/recurring payments context (MG space - content not fully accessible) |
| [Deposit service changes for CC](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11276224275) | Confluence | Deposit service CC changes referencing SchemeID usage (MG space - content not fully accessible) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped - no repos; 11 complete)*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCreditCardSchemeID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCreditCardSchemeID.sql*
