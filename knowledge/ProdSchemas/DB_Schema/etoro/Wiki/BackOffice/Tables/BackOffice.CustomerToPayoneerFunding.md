# BackOffice.CustomerToPayoneerFunding

> One-to-one mapping of customer CIDs to their Payoneer prepaid card numbers, used for Payoneer-channel payouts. CardNumber is masked with dynamic data masking. Effectively empty in production (1 test row).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, NC PK) |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 NC PK on CID) |

---

## 1. Business Meaning

BackOffice.CustomerToPayoneerFunding stores the association between a customer and their Payoneer prepaid card, enabling eToro to process payouts via the Payoneer payment network. Payoneer is a global mass-payout platform commonly used for cross-border payments - eToro would use it to credit a customer's Payoneer prepaid card as an alternative to bank transfer or standard payment methods.

The table enforces a one-per-customer constraint (CID is the PK): each customer can have at most one Payoneer card registered. The optional FundingID links to a Billing.Funding record representing the payment method on the eToro side, though the single current row has FundingID=NULL.

The CardNumber column is protected by SQL Server dynamic data masking (`MASKED WITH (FUNCTION = 'default()')`), returning an empty string to users without the UNMASK privilege - consistent with PCI DSS requirements for protecting payment card data.

As of 2026-03-17, the table has 1 row with a test card number (4444333322221111) for CID=125456 and no FundingID. The feature appears to be lightly deployed or in an early/inactive state.

---

## 2. Business Logic

### 2.1 One-Row-Per-Customer Insert Guard

**What**: CustomerToPayoneerFundingAdd uses an existence check to prevent duplicate registrations.

**Columns Involved**: `CID`, `CardNumber`, `FundingID`

**Rules**:
- CustomerToPayoneerFundingAdd: IF NOT EXISTS (SELECT 1 WHERE CID=@CID) -> INSERT. Only inserts if no row exists for that CID.
- CustomerToPayoneerFundingDelete: simple DELETE by CID - removes the customer's Payoneer card registration.
- No UPDATE procedure exists - to change a card, the agent deletes and re-adds.

---

## 3. Data Overview

1 row as of 2026-03-17:

| CID | CardNumber | FundingID | Note |
|-----|-----------|-----------|------|
| 125456 | 4444333322221111 | NULL | Test card number. Standard test PAN used in development environments. FundingID not linked. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. NC PK - one Payoneer card per customer maximum. No declared FK to BackOffice.Customer or Customer.CustomerStatic, though CID semantics are identical. |
| 2 | CardNumber | varchar(50) | NO | - | VERIFIED | The customer's Payoneer prepaid card number (payment card number). **MASKED WITH (FUNCTION = 'default()')**: users without UNMASK privilege see empty string. Protected under PCI DSS card data handling rules. Max 50 chars (standard card numbers are 16 digits but some Payoneer formats may differ). |
| 3 | FundingID | int | YES | NULL | CODE-BACKED | Optional FK to Billing.Funding - links this Payoneer card to a specific funding/payment method record in the Billing system. NULL in the only current row. When populated, allows reconciliation between the Payoneer payout channel and eToro's internal funding records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | Implicit | Customer whose Payoneer card is registered (no FK constraint) |
| FundingID | Billing.Funding | Implicit | Payment method record (no FK constraint; nullable) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerToPayoneerFundingAdd | CID, CardNumber, FundingID | WRITER | Inserts a new customer-Payoneer association (if none exists) |
| BackOffice.CustomerToPayoneerFundingDelete | CID | DELETER | Removes a customer's Payoneer card registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerToPayoneerFunding (table)
- No declared FK targets
- Written by: BackOffice.CustomerToPayoneerFundingAdd
- Deleted by: BackOffice.CustomerToPayoneerFundingDelete
```

### 6.1 Objects This Depends On

No FK constraints declared.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerToPayoneerFundingAdd | Procedure | WRITER - insert with existence guard |
| BackOffice.CustomerToPayoneerFundingDelete | Procedure | DELETER - remove by CID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Customer | NC PK | CID ASC | - | - | Active (ON [PRIMARY]) |

Note: PK is NONCLUSTERED on PRIMARY filegroup. No clustered index exists - heap table with a NC PK. This is unusual; for a small lookup table it has no performance impact.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Customer | PK | CID uniqueness - one Payoneer card per customer |

### 7.3 Dynamic Data Masking

CardNumber: `MASKED WITH (FUNCTION = 'default()')` returns empty string `""` for users without UNMASK privilege. Protects card numbers from unauthorized exposure. Consistent with PCI DSS requirements for payment card data.

---

## 8. Sample Queries

### 8.1 Get a customer's Payoneer card registration
```sql
SELECT CID, CardNumber, FundingID
FROM BackOffice.CustomerToPayoneerFunding WITH (NOLOCK)
WHERE CID = @CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerToPayoneerFunding | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerToPayoneerFunding.sql*
