# AffiliateConfiguration.ISAPlan

> Configuration table defining ISA (Individual Savings Account) product commission amounts per affiliate type, enabling affiliates to earn different commissions for Cash ISA, Managed ISA, and DIY ISA customer signups.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateConfiguration |
| **Object Type** | Table |
| **Key Identifier** | AffiliateTypeID + SubAccountTypeID + ProductID (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered composite PK) |

---

## 1. Business Meaning

AffiliateConfiguration.ISAPlan defines per-product commission amounts for ISA (Individual Savings Account) affiliate commissions. ISAs are UK tax-advantaged investment accounts offered on the eToro platform via the Moneyfarm integration. Each row maps an affiliate type to a specific ISA product variant and the commission amount earned when a referred customer signs up for that product.

Without this table, affiliates could not earn product-specific commissions for ISA signups. The platform offers three ISA products with different management styles - Cash ISA, Managed ISA, and DIY ISA - and business teams need the flexibility to set different commission rates per product per affiliate type.

Plan entries are managed by [AffiliateAdmin.UpdateInsertAffiliateType](../../AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateType.md) using the [ISAPlanType TVP](../User Defined Types/AffiliateConfiguration.ISAPlanType.md). The procedure performs a compare-and-replace pattern: it aggregates old vs new rows (including ProductID), and only writes if changed. The commission pipeline reads this table via GetCreditTriggeredEvents as a LEFT JOIN - the existence of ISAPlan rows for an AffiliateTypeID signals that ISA commission model is available (similar to IOBPlan). Created as part of PART-5461 (Jan 2026).

---

## 2. Business Logic

### 2.1 Product-Level ISA Commission

**What**: Each ISA product variant can have a different commission rate, allowing the business to incentivize specific product adoption.

**Columns/Parameters Involved**: `AffiliateTypeID`, `SubAccountTypeID`, `ProductID`, `Commission`

**Rules**:
- SubAccountTypeID is always 4 (Moneyfarm) for all current ISA products
- ProductID matches Dictionary.ISAProduct: "isa-cash", "isa-discretionary", "isa-execution-only"
- An affiliate type can have 1 to 3 ISA product entries (one per product)
- Typical commission patterns: Cash ISA has highest commissions ($100-$600), Managed ISA mid-range ($7-$550), DIY ISA lowest ($4-$450)
- Some affiliate types only configure one or two products, not all three

**Diagram**:
```
ISAPlan for AffiliateType 4766:
  isa-cash           --> $15
  isa-discretionary  --> $20
  isa-execution-only --> $5

ISAPlan for AffiliateType 4602:
  isa-cash           --> $600
  (no other products configured)
```

### 2.2 ISA Eligibility Signal in Commission Pipeline

**What**: The existence of ISAPlan rows for an affiliate type serves as a configuration signal in the credit-triggered events pipeline.

**Columns/Parameters Involved**: `AffiliateTypeID`

**Rules**:
- GetCreditTriggeredEvents performs a LEFT JOIN to ISAPlan on AffiliateTypeID
- If `isa.AffiliateTypeID IS NOT NULL`, the ISA commission model is considered available for this affiliate
- This is used alongside IOBPlan existence check in the WHERE clause to determine commission eligibility routing
- Similar pattern to IOBPlan: presence of config rows = model is active

---

## 3. Data Overview

| AffiliateTypeID | SubAccountTypeID | ProductID | Commission | DateModified | Meaning |
|---|---|---|---|---|---|
| 2 | 4 | isa-execution-only | 5 | 2026-02-18 | Base affiliate type with minimal ISA commission: $5 for DIY ISA only. Likely a default or test plan |
| 4602 | 4 | isa-cash | 600 | 2026-02-17 | Cash ISA only at premium $600 commission. This plan aggressively incentivizes cash ISA signups |
| 4707 | 4 | isa-discretionary | 550 | 2026-02-17 | Managed ISA at $550 - high-value commission for professionally managed portfolios |
| 4766 | 4 | isa-cash | 15 | 2026-02-18 | Low-tier Cash ISA commission for a specific affiliate type. Multi-product plan with all three ISA variants |
| 4766 | 4 | isa-execution-only | 5 | 2026-02-18 | Same affiliate type, DIY ISA at $5. Shows the range: cash ($15) > discretionary ($20) > execution-only ($5) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateTypeID | int | NO | - | VERIFIED | Commission plan template this ISA entry belongs to. Part of composite PK. Implicit FK to [dbo.tblaff_AffiliateTypes](../../dbo/Tables/dbo.tblaff_AffiliateTypes.md). Each affiliate type can have up to 3 ISA entries (one per product). The existence of ISAPlan rows for an AffiliateTypeID signals ISA commission model availability in the commission pipeline (LEFT JOIN check in GetCreditTriggeredEvents). |
| 2 | SubAccountTypeID | int | NO | - | VERIFIED | ISA sub-account classification. Part of composite PK. Currently always 4 (Moneyfarm). Implicit FK to [Dictionary.AccountType](../../Dictionary/Tables/Dictionary.AccountType.md). See [Account Type](../../_glossary.md#account-type): 1=Trading, 2=Options, 3=IBAN, 4=Moneyfarm. All ISA products are under the Moneyfarm account type. |
| 3 | ProductID | varchar(50) | NO | - | VERIFIED | ISA product identifier. Part of composite PK. Implicit FK to [Dictionary.ISAProduct](../../Dictionary/Tables/Dictionary.ISAProduct.md). String values: "isa-cash" (Cash ISA - savings), "isa-discretionary" (Managed ISA - professionally managed), "isa-execution-only" (DIY ISA - self-directed). See [ISA Product](../../_glossary.md#isa-product). |
| 4 | Commission | float | NO | - | CODE-BACKED | Flat commission amount paid to the affiliate when a referred customer signs up for this ISA product. Expressed in platform base currency. Live range: $4-$600. Different products typically have different commission levels within the same affiliate type. |
| 5 | DateModified | datetime | NO | GETUTCDATE() | CODE-BACKED | Timestamp of the last update to this entry (UTC). Default: GETUTCDATE(). Set on insert by UpdateInsertAffiliateType during the compare-and-replace flow. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit FK | Commission plan template this ISA entry belongs to |
| SubAccountTypeID | Dictionary.AccountType | Implicit FK | Account type classification (always 4=Moneyfarm for ISA) |
| SubAccountTypeID + ProductID | Dictionary.ISAProduct | Implicit FK | Composite reference to the ISA product definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.UpdateInsertAffiliateType | Direct INSERT/DELETE | WRITER | Creates and replaces ISA plan entries using ISAPlanType TVP |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId | Direct SELECT | READER | Reads ISA plan for commission pipeline |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateId | Direct SELECT | READER | Reads ISA plan for commission pipeline by affiliate |
| AffiliateCommission.GetCreditTriggeredEvents | LEFT JOIN | READER | Checks ISA plan existence as eligibility signal in credit-triggered commission evaluation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. Tables are always leaf nodes.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.UpdateInsertAffiliateType | Stored Procedure | WRITER - INSERT/DELETE ISA plan entries |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId | Stored Procedure | READER - commission pipeline |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateId | Stored Procedure | READER - commission pipeline |
| AffiliateCommission.GetCreditTriggeredEvents | Stored Procedure | READER - ISA eligibility check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ISAPlan_AffiliateTypeID_SubAccountTypeID_ProductID | CLUSTERED | AffiliateTypeID ASC, SubAccountTypeID ASC, ProductID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ISAPlan_AffiliateTypeID_SubAccountTypeID_ProductID | PRIMARY KEY | Composite clustered PK. Ensures one commission entry per affiliate type per ISA product |
| DF_ISAPlan_DateModified | DEFAULT | GETUTCDATE() for DateModified. Automatically timestamps on insert |

---

## 8. Sample Queries

### 8.1 View ISA plan with resolved product names

```sql
SELECT ip.AffiliateTypeID, at.Description AS PlanName,
       ip.SubAccountTypeID, ip.ProductID, isp.Name AS ProductName,
       ip.Commission, ip.DateModified
FROM AffiliateConfiguration.ISAPlan ip WITH (NOLOCK)
INNER JOIN Dictionary.ISAProduct isp WITH (NOLOCK)
  ON ip.SubAccountTypeID = isp.SubAccountTypeID AND ip.ProductID = isp.ProductID
LEFT JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON ip.AffiliateTypeID = at.AffiliateTypeID
WHERE ip.AffiliateTypeID = 4766
ORDER BY ip.ProductID;
```

### 8.2 Find affiliate types with ISA plans and their product coverage

```sql
SELECT ip.AffiliateTypeID, at.Description,
       COUNT(*) AS ProductCount,
       STRING_AGG(ip.ProductID, ', ') WITHIN GROUP (ORDER BY ip.ProductID) AS Products,
       SUM(ip.Commission) AS TotalCommission
FROM AffiliateConfiguration.ISAPlan ip WITH (NOLOCK)
INNER JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON ip.AffiliateTypeID = at.AffiliateTypeID
GROUP BY ip.AffiliateTypeID, at.Description
ORDER BY ProductCount DESC;
```

### 8.3 Compare ISA commissions across all three product types

```sql
SELECT ip.AffiliateTypeID,
       MAX(CASE WHEN ip.ProductID = 'isa-cash' THEN ip.Commission END) AS CashISA,
       MAX(CASE WHEN ip.ProductID = 'isa-discretionary' THEN ip.Commission END) AS ManagedISA,
       MAX(CASE WHEN ip.ProductID = 'isa-execution-only' THEN ip.Commission END) AS DiyISA
FROM AffiliateConfiguration.ISAPlan ip WITH (NOLOCK)
GROUP BY ip.AffiliateTypeID
ORDER BY ip.AffiliateTypeID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [IOB](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13304168449/IOB) | Confluence | ISAPlan mentioned alongside IOBPlan in the commission pipeline architecture. ISA plan existence is checked as eligibility signal similar to IOBPlan |

PART-5461 (Jira): ISA plan feature - original creation ticket (Jan 2026, referenced in UpdateInsertAffiliateType header comments).

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateConfiguration.ISAPlan | Type: Table | Source: fiktivo/AffiliateConfiguration/Tables/AffiliateConfiguration.ISAPlan.sql*
