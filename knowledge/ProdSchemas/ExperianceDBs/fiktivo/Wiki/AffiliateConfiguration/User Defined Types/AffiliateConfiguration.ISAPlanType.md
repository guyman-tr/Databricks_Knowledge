# AffiliateConfiguration.ISAPlanType

> Table-valued parameter type for bulk-inserting or replacing ISA (Individual Savings Account) product commission plan entries for an affiliate type.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateConfiguration |
| **Object Type** | User Defined Type |
| **Key Identifier** | TVP (Table-Valued Parameter) - no primary key |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateConfiguration.ISAPlanType is a table-valued parameter (TVP) that carries ISA product commission plan data from the application layer into SQL Server stored procedures. It defines the commission amounts affiliates earn for each ISA product variant when a referred UK customer opens an ISA account.

Without this TVP, the admin system would need to issue individual INSERT statements for each ISA product commission entry. The TVP enables atomic, set-based bulk operations - the entire ISA plan is passed as a single parameter and applied transactionally.

This TVP is consumed exclusively by [AffiliateAdmin.UpdateInsertAffiliateType](../../AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateType.md) as the `@ISAPlan` parameter. The procedure performs a compare-and-replace: it aggregates old and new ISA plan rows, and only writes if the plan has changed. Changes are audit-logged with the ISAPlan section ID from Dictionary.ChangedSections. Created as part of PART-5461.

---

## 2. Business Logic

### 2.1 ISA Product Commission Configuration

**What**: Defines per-product commission amounts for ISA plans, supporting different rates for Cash ISA, Managed ISA, and DIY ISA.

**Columns/Parameters Involved**: `SubAccountTypeID`, `ProductID`, `Commission`

**Rules**:
- SubAccountTypeID is always 4 (Moneyfarm account type) for all current ISA products
- ProductID uses string identifiers matching Dictionary.ISAProduct: "isa-cash", "isa-discretionary", "isa-execution-only"
- Commission is the flat amount paid to the affiliate per ISA sign-up for that product
- The consuming procedure uses STRING_AGG to compare old and new plan states, only writing if changed
- Collation is Latin1_General_BIN on ProductID for case-sensitive binary comparison

**Diagram**:
```
Admin UI -> @ISAPlan TVP
              |
              v
  UpdateInsertAffiliateType
    1. Aggregate existing ISAPlan rows (STRING_AGG)
    2. Aggregate new TVP rows (STRING_AGG)
    3. If different:
       a. DELETE existing ISAPlan for AffiliateTypeID
       b. INSERT new rows from TVP
       c. Audit log (SectionID from Dictionary.ChangedSections 'ISAPlan')
```

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter shape definition, not a persisted data store. See [AffiliateConfiguration.ISAPlan](../Tables/AffiliateConfiguration.ISAPlan.md) for live data examples.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SubAccountTypeID | int | NO | - | CODE-BACKED | ISA sub-account type. Currently always 4 (Moneyfarm). Links to [Dictionary.AccountType](../../Dictionary/Tables/Dictionary.AccountType.md): 1=Trading, 2=Options, 3=IBAN, 4=Moneyfarm. See [Account Type](../../_glossary.md#account-type). Part of the composite key with ProductID in the target ISAPlan table. |
| 2 | ProductID | varchar(50) | NO | - | CODE-BACKED | ISA product identifier using kebab-case strings. References [Dictionary.ISAProduct](../../Dictionary/Tables/Dictionary.ISAProduct.md): "isa-cash" (Cash ISA), "isa-discretionary" (Managed ISA), "isa-execution-only" (DIY ISA). See [ISA Product](../../_glossary.md#isa-product). Uses Latin1_General_BIN collation for case-sensitive binary comparison. |
| 3 | Commission | float | NO | - | CODE-BACKED | Flat commission amount paid to the affiliate when a referred customer opens this ISA product. Expressed in the platform's base currency. Typical values range from 4-600 depending on product and affiliate tier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SubAccountTypeID | Dictionary.AccountType | Implicit | Account type classification for the ISA product |
| ProductID | Dictionary.ISAProduct | Implicit | ISA product variant identifier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.UpdateInsertAffiliateType | @ISAPlan | Parameter Type | TVP parameter carrying ISA plan entries for bulk insert into ISAPlan table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is a type definition with no executable SQL.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.UpdateInsertAffiliateType | Stored Procedure | Accepts this TVP as the @ISAPlan parameter for bulk ISA commission plan configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ProductID collation | COLLATE | Latin1_General_BIN - enforces case-sensitive binary comparison for product ID matching |

---

## 8. Sample Queries

### 8.1 Declare and populate the TVP for an ISA plan

```sql
DECLARE @isaPlan AffiliateConfiguration.ISAPlanType;

INSERT INTO @isaPlan (SubAccountTypeID, ProductID, Commission)
VALUES
  (4, 'isa-cash', 600),             -- Cash ISA: 600 commission
  (4, 'isa-discretionary', 550),    -- Managed ISA: 550 commission
  (4, 'isa-execution-only', 450);   -- DIY ISA: 450 commission

EXEC AffiliateAdmin.UpdateInsertAffiliateType
  @AffiliateTypeID = 4602,
  @ISAPlan = @isaPlan,
  -- ... other parameters ...
```

### 8.2 View current ISA plan to reconstruct TVP contents

```sql
SELECT SubAccountTypeID, ProductID, Commission
FROM AffiliateConfiguration.ISAPlan WITH (NOLOCK)
WHERE AffiliateTypeID = 4766
ORDER BY SubAccountTypeID, ProductID;
```

### 8.3 Join TVP data with product names for validation

```sql
DECLARE @isaPlan AffiliateConfiguration.ISAPlanType;
-- (populate @isaPlan)

SELECT p.SubAccountTypeID, p.ProductID, p.Commission, ip.Name AS ProductName
FROM @isaPlan p
INNER JOIN Dictionary.ISAProduct ip WITH (NOLOCK)
  ON p.SubAccountTypeID = ip.SubAccountTypeID AND p.ProductID = ip.ProductID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CPA New Compensation Plan - DB design](https://etoro-jira.atlassian.net/wiki/x/PLACEHOLDER) | Confluence | Broader context of the compensation plan architecture that ISA plans extend |

PART-5461 (Jira): ISA plan feature - the ticket that introduced ISAPlanType and ISAPlan table (referenced in procedure header comments, Jan 2026).

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateConfiguration.ISAPlanType | Type: User Defined Type | Source: fiktivo/AffiliateConfiguration/User Defined Types/AffiliateConfiguration.ISAPlanType.sql*
