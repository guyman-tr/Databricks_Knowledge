# Billing.MerchantEntityFundsTransfer

> Configuration table mapping each eToro regulatory entity to its legal entity name and domestic country, used to resolve which eToro legal entity processes a customer's funds transfer based on regulation and card country.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on ID) |

---

## 1. Business Meaning

Billing.MerchantEntityFundsTransfer maps each regulatory framework under which eToro operates to the corresponding legal entity name and "domestic" country. When a customer processes a wire transfer or domestic funds transfer, the system uses this table to determine which eToro legal entity (eToro EU, eToro UK, eToro AU, eToro US, eToro ME, eToro SG) is the counterparty - ensuring the transfer is routed to the correct bank account and legal jurisdiction.

This table exists because eToro operates 12+ regulated entities across multiple jurisdictions. A customer regulated under CySEC (Cyprus) must send funds to eToro EU's Cyprus bank account; an FCA-regulated UK customer sends to eToro UK's UK account. The SupportedDomesticCountryID identifies the home country of each entity, enabling "domestic" transfer routing (e.g., a UK customer with a UK card under FCA regulation can use the domestic eToro UK account rather than a cross-border transfer).

Data is read by Billing.MerchantEntityFundsTransferGet which accepts a @regulationId and @binCountryId - it throws an error if the regulation isn't configured, then returns the matching entity for that regulation+country combination.

---

## 2. Business Logic

### 2.1 Regulation + Country Resolution

**What**: Each row represents a valid combination of regulatory entity and domestic country for funds transfer routing.

**Columns/Parameters Involved**: `RegulationID`, `SupportedDomesticCountryID`, `LegalEntity`

**Rules**:
- Billing.MerchantEntityFundsTransferGet filters by both @regulationId AND @binCountryId (the card-issuing country) to find the exact legal entity row.
- FCA (RegulationID=2) appears twice: once for UK (CountryID=218) and once for Singapore (CountryID=183), meaning FCA-regulated customers with Singapore-issued cards use the UK entity but are routed to the SG domestic option.
- ASIC (4) and "ASIC & GAML" (10) both map to "eToro AU" with Australia as domestic country - two regulatory variants of the same entity.
- US entities (eToroUS=6, FinCEN=7, FinCEN+FINRA=8, NYDFS+FINRA=14) all map to "eToro US" or "eToro NY" with USA as domestic.
- FSA Seychelles (9) maps to "eToro" with CountryID=250 ("eToro") - the offshore/global entity.

---

## 3. Data Overview

| ID | RegulationID | Regulation | LegalEntity | SupportedDomesticCountryID | Country | Meaning |
|---|---|---|---|---|---|---|
| 5 | 1 | CySEC | eToro EU | 54 | Cyprus | EU-regulated customers processed via eToro's Cyprus-based legal entity. Domestic transfers go to Cyprus bank account. |
| 31 | 2 | FCA | eToro UK | 218 | United Kingdom | UK-regulated customers with UK cards processed via eToro (UK) Ltd. Domestic UK bank transfer available. |
| 34 | 6 | eToroUS | eToro US | 219 | United States | US-regulated customers processed via eToro USA LLC. |
| 38 | 11 | FSRA | eToro ME | 217 | UAE | UAE/Middle East customers processed via eToro ME entity regulated by FSRA (Abu Dhabi). |
| 42 | 13 | MAS | eToro SG | 183 | Singapore | Singapore-regulated customers processed via eToro Singapore entity, licensed by MAS. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. Auto-incrementing. Note: IDs are non-sequential (5, 31, 32, 33, 34, 35, 36, 38, 40, 41, 42, 43) suggesting rows were deleted and re-inserted over time. |
| 2 | RegulationID | int | YES | - | CODE-BACKED | Regulatory framework identifier. Nullable - a NULL entry could serve as a fallback. Implicit FK to Dictionary.Regulation (no FK constraint declared). Values: 1=CySEC, 2=FCA, 4=ASIC, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC+GAML, 11=FSRA, 13=MAS, 14=NYDFS+FINRA. |
| 3 | LegalEntity | varchar(50) | YES | - | CODE-BACKED | Human-readable name of the eToro legal entity that processes funds for this regulation. Values: "eToro EU", "eToro UK", "eToro AU", "eToro US", "eToro ME", "eToro SG", "eToro NY", "eToro" (global/Seychelles). Displayed in BackOffice and used for wire transfer routing. |
| 4 | SupportedDomesticCountryID | int | YES | - | CODE-BACKED | The "home" country of this legal entity. Used in Billing.MerchantEntityFundsTransferGet to match against the customer's card country (@binCountryId). Implicit FK to Dictionary.Country. 54=Cyprus, 218=UK, 12=Australia, 219=USA, 217=UAE, 183=Singapore, 250=eToro (global). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegulationID | Dictionary.Regulation | Implicit | References the regulatory framework. No declared FK constraint. |
| SupportedDomesticCountryID | Dictionary.Country | Implicit | References the domestic country for this legal entity. No declared FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.MerchantEntityFundsTransferGet | RegulationID, SupportedDomesticCountryID | SELECT reader | Resolves legal entity for a given regulation+card country combination. Throws error 51445 if regulation not found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MerchantEntityFundsTransfer (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies (no FK constraints declared).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.MerchantEntityFundsTransferGet | Stored Procedure | SELECT reader - resolves legal entity for funds transfer routing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MerchantEntityFundsTransfer | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=100, PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MerchantEntityFundsTransfer | PRIMARY KEY | ID clustered |

---

## 8. Sample Queries

### 8.1 Get all legal entity mappings

```sql
SELECT
    meft.ID,
    r.Name AS Regulation,
    meft.LegalEntity,
    c.Name AS DomesticCountry
FROM Billing.MerchantEntityFundsTransfer meft WITH (NOLOCK)
LEFT JOIN Dictionary.Regulation r WITH (NOLOCK) ON meft.RegulationID = r.ID
LEFT JOIN Dictionary.Country c WITH (NOLOCK) ON meft.SupportedDomesticCountryID = c.CountryID
ORDER BY r.Name, c.Name
```

### 8.2 Look up legal entity for a specific regulation and card country

```sql
EXEC Billing.MerchantEntityFundsTransferGet
    @regulationId = 2,   -- FCA
    @binCountryId = 218  -- United Kingdom
```

### 8.3 Find all US entities

```sql
SELECT r.Name AS Regulation, meft.LegalEntity, c.Name AS Country
FROM Billing.MerchantEntityFundsTransfer meft WITH (NOLOCK)
LEFT JOIN Dictionary.Regulation r WITH (NOLOCK) ON meft.RegulationID = r.ID
LEFT JOIN Dictionary.Country c WITH (NOLOCK) ON meft.SupportedDomesticCountryID = c.CountryID
WHERE meft.SupportedDomesticCountryID = 219  -- United States
ORDER BY r.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8.5/10, Relationships: 7.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.MerchantEntityFundsTransfer | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.MerchantEntityFundsTransfer.sql*
