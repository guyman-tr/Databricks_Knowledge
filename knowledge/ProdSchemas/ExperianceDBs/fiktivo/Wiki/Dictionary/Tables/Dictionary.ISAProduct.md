# Dictionary.ISAProduct

> Lookup table defining Individual Savings Account (ISA) product types available on the platform, each linked to a sub-account type and a unique product identifier.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SubAccountTypeID + ProductID (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ISAProduct defines the UK tax-advantaged Individual Savings Account products offered on the platform. ISAs allow UK customers to invest with tax-free gains. Each product represents a distinct management style: cash savings, professionally managed portfolios, or self-directed investing. All products share SubAccountTypeID=4, linking them to the Moneyfarm account type in Dictionary.AccountType.

Without this table, the system could not differentiate between ISA product variants when configuring affiliate commission plans. ISA plan configurations in AffiliateConfiguration.ISAPlan reference these products to set product-specific commission rates.

This is static reference data. The composite primary key (SubAccountTypeID + ProductID) supports multi-dimensional lookups. Products are read by commission configuration and affiliate type management procedures.

---

## 2. Business Logic

### 2.1 ISA Product Classification

**What**: Three ISA management styles under the Moneyfarm account type, each with a unique string-based ProductID.

**Columns/Parameters Involved**: `SubAccountTypeID`, `ProductID`, `Name`

**Rules**:
- All products share SubAccountTypeID=4, linking to Dictionary.AccountType.Moneyfarm
- ProductID uses kebab-case string identifiers (not integer IDs) for API compatibility
- isa-cash: Cash savings ISA - funds held as cash with interest, no investment risk
- isa-discretionary: Professionally managed ISA - Moneyfarm manages the portfolio
- isa-execution-only: Self-directed ISA - customer selects their own investments

---

## 3. Data Overview

| SubAccountTypeID | ProductID | Name | Meaning |
|---|---|---|---|
| 4 | isa-cash | Cash ISA | Cash savings ISA where funds are held as cash earning interest. Lowest risk, lowest return potential. Ideal for customers seeking capital preservation with tax benefits |
| 4 | isa-discretionary | Managed ISA | Professionally managed ISA portfolio where Moneyfarm makes all investment decisions. Suitable for customers wanting hands-off investing with expert management |
| 4 | isa-execution-only | DIY ISA | Self-directed ISA where the customer chooses their own investments. Highest control but requires investment knowledge. Sometimes called "execution-only" because the platform only executes orders without advice |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SubAccountTypeID | int | NO | - | VERIFIED | Part of composite PK. Links to Dictionary.AccountType (value 4=Moneyfarm). All ISA products are sub-types of the Moneyfarm account. See [ISA Product](../../_glossary.md#isa-product) and [Account Type](../../_glossary.md#account-type). |
| 2 | ProductID | varchar(50) | NO | - | VERIFIED | Part of composite PK. String-based product identifier using kebab-case naming: "isa-cash", "isa-discretionary", "isa-execution-only". Used in API integrations and configuration lookups. |
| 3 | Name | varchar(50) | NO | - | VERIFIED | Human-readable product name: "Cash ISA", "Managed ISA", "DIY ISA". Displayed in admin UIs and commission plan configuration screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SubAccountTypeID | Dictionary.AccountType | Implicit FK | Links ISA products to the Moneyfarm account type (ID=4) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateConfiguration.ISAPlan | SubAccountTypeID | Implicit FK | ISA commission plan configuration references product type |
| AffiliateAdmin.UpdateInsertAffiliateType | JOIN | Lookup | Admin procedure for managing affiliate type ISA plan settings |
| AffiliateAdmin.GetAffiliateTypeData | JOIN | Lookup | Returns ISA product details for affiliate type configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateConfiguration.ISAPlan | Table | ISA plan config references SubAccountTypeID |
| AffiliateAdmin.UpdateInsertAffiliateType | Stored Procedure | MODIFIER - manages ISA plan settings |
| AffiliateAdmin.GetGeneralAffiliateTypeResource | Stored Procedure | READER - returns ISA products for admin UI |
| AffiliateAdmin.GetAffiliateTypeData | Stored Procedure | READER - returns ISA product configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ISAProduct | CLUSTERED PK | SubAccountTypeID ASC, ProductID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all ISA products
```sql
SELECT SubAccountTypeID, ProductID, Name
FROM Dictionary.ISAProduct WITH (NOLOCK)
ORDER BY ProductID
```

### 8.2 Show ISA products with their parent account type
```sql
SELECT ip.ProductID, ip.Name AS ProductName, at.Name AS AccountTypeName
FROM Dictionary.ISAProduct ip WITH (NOLOCK)
JOIN Dictionary.AccountType at WITH (NOLOCK) ON ip.SubAccountTypeID = at.AccountTypeID
```

### 8.3 Find ISA plans with product details
```sql
SELECT plan.*, ip.Name AS ProductName
FROM AffiliateConfiguration.ISAPlan plan WITH (NOLOCK)
JOIN Dictionary.ISAProduct ip WITH (NOLOCK) ON plan.SubAccountTypeID = ip.SubAccountTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ISAProduct | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.ISAProduct.sql*
