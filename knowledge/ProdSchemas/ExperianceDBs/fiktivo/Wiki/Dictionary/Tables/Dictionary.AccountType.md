# Dictionary.AccountType

> Lookup table classifying the types of trading or financial accounts a customer can hold, determining available instruments and product features.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AccountTypeID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AccountType defines the classification of customer accounts on the platform. Each type represents a fundamentally different product offering - standard CFD/stock trading, options trading, IBAN-based money services, or managed investments via Moneyfarm. This distinction drives which instruments are available, which commission plans apply, and how revenue is calculated for affiliates.

This table is critical to the affiliate commission system. Affiliate commission plans, credit mappings, and reporting are all segmented by account type. Without it, the system could not differentiate between trading revenue and managed investment revenue when calculating affiliate payouts.

AccountType is a static reference table read by virtually every affiliate-facing procedure. It is referenced by the core Affiliates table (dbo.tblaff_Affiliates), commission credit mappings (AffiliateCommission.CreditAccountMapping), ISA plan configuration (AffiliateConfiguration.ISAPlan), and numerous reporting and admin procedures.

---

## 2. Business Logic

### 2.1 Account Type Classification

**What**: Four distinct product types that determine the customer's experience and the affiliate's commission structure.

**Columns/Parameters Involved**: `AccountTypeID`, `Name`

**Rules**:
- ID=1 (Trading) is the standard account for CFDs, stocks, and other tradeable instruments - the primary revenue driver
- ID=2 (Options) is a dedicated options trading account with its own instrument set and risk model
- ID=3 (IBAN) is a bank-style account for money services (deposits, transfers) without active trading
- ID=4 (Moneyfarm) is a managed investment portfolio - the customer delegates investment decisions to Moneyfarm. ISA products (Cash ISA, Managed ISA, DIY ISA) are linked to this account type via Dictionary.ISAProduct.SubAccountTypeID

**Diagram**:
```
Customer Account Types:
  [Trading (1)] -- Standard CFD/stock trading
  [Options (2)] -- Options contracts trading
  [IBAN (3)]    -- Bank-style money services
  [Moneyfarm (4)] -- Managed investments
                      |
                      +-- ISA Products (Dictionary.ISAProduct)
                           |-- Cash ISA (isa-cash)
                           |-- Managed ISA (isa-discretionary)
                           |-- DIY ISA (isa-execution-only)
```

---

## 3. Data Overview

| AccountTypeID | Name | Meaning |
|---|---|---|
| 1 | Traiding | Standard trading account for CFDs, stocks, ETFs, and other instruments. This is the default and most common account type. Note: the "Traiding" spelling is a legacy data entry - the business term is "Trading" |
| 2 | Options | Dedicated options trading account with its own instrument universe, margin requirements, and risk calculations |
| 3 | IBAN | International Bank Account Number - a bank-style account used for money services (deposits, withdrawals, transfers) without active trading activity |
| 4 | Moneyfarm | Managed investment portfolio via Moneyfarm integration. Customers delegate investment decisions. ISA (Individual Savings Account) products are sub-types of this account type |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountTypeID | int | NO | - | VERIFIED | Primary key identifying the account type. Values: 1=Trading, 2=Options, 3=IBAN, 4=Moneyfarm. See [Account Type](../../_glossary.md#account-type) for full business definitions. Referenced as a foreign key by affiliate tables, commission mappings, and ISA plans. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label for the account type. Used in admin UIs, reporting displays, and API responses. Note: ID=1 is stored as "Traiding" (legacy spelling). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | AccountTypeID | Implicit FK | Core affiliate table stores the account type associated with each affiliate relationship |
| History.tblaff_Affiliates | AccountTypeID | Implicit FK | Historical snapshot of affiliate records including account type |
| AffiliateCommission.CreditAccountMapping | AccountTypeID | Implicit FK | Maps credit types to account types for commission calculation routing |
| AffiliateConfiguration.ISAPlan | AccountTypeID | Implicit FK | ISA plan configuration filtered by account type (Moneyfarm) |
| Dictionary.ISAProduct | SubAccountTypeID | Implicit FK | ISA products linked to Moneyfarm account type (SubAccountTypeID=4) |
| AffiliateAdmin.GetGeneralAffiliateTypeResource | SELECT | Lookup | Returns account types for admin UI resource loading |
| AffiliateAdmin.UpdateInsertAffiliate | Parameter | Lookup | Uses AccountTypeID when creating or updating affiliate records |
| Affiliate.GetAffiliates | JOIN/WHERE | Lookup | Filters and displays affiliate data by account type |
| AffiliateCommission.InsertCredit | JOIN | Lookup | Commission credit insertion references account type for routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | Stores AccountTypeID as implicit FK |
| History.tblaff_Affiliates | Table | Historical records include AccountTypeID |
| AffiliateCommission.CreditAccountMapping | Table | Maps credits to account types |
| AffiliateConfiguration.ISAPlan | Table | ISA plan config references account type |
| Dictionary.ISAProduct | Table | ISA products linked via SubAccountTypeID |
| AffiliateAdmin.UpdateInsertAffiliate | Stored Procedure | WRITER/MODIFIER - uses AccountTypeID in affiliate upsert |
| Affiliate.GetAffiliates | Stored Procedure | READER - filters/displays by account type |
| AffiliateCommission.InsertCredit | Stored Procedure | READER - references account type for credit routing |
| AffiliateAdmin.GetGeneralAffiliateTypeResource | Stored Procedure | READER - returns all account types for admin UI |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AccountType | CLUSTERED PK | AccountTypeID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all account types
```sql
SELECT AccountTypeID, Name
FROM Dictionary.AccountType WITH (NOLOCK)
ORDER BY AccountTypeID
```

### 8.2 Find affiliates by account type with type name
```sql
SELECT a.AffiliateID, a.AccountTypeID, at.Name AS AccountTypeName
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN Dictionary.AccountType at WITH (NOLOCK) ON a.AccountTypeID = at.AccountTypeID
ORDER BY a.AffiliateID
```

### 8.3 Show ISA products linked to Moneyfarm account type
```sql
SELECT at.Name AS AccountType, ip.ProductID, ip.Name AS ProductName
FROM Dictionary.ISAProduct ip WITH (NOLOCK)
JOIN Dictionary.AccountType at WITH (NOLOCK) ON ip.SubAccountTypeID = at.AccountTypeID
WHERE ip.SubAccountTypeID = 4
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly documenting this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountType | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.AccountType.sql*
