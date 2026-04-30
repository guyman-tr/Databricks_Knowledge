# Dictionary.Regulation

> Reference table defining the financial regulatory jurisdictions under which eToro operates, determining compliance requirements, product access, and user protections.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.Regulation is one of the most consequential lookup tables in UserApiDB. It defines the 12 regulatory jurisdictions under which eToro operates globally. A user's regulation determines virtually everything about their platform experience: available instruments, leverage limits, KYC requirements, payment methods, compliance workflows, risk disclosures, and consumer protections.

This table exists because eToro is a globally regulated platform operating under multiple financial regulators simultaneously. Each regulation represents a distinct legal framework with different rules. CySEC (EU) enforces MiFID II with leverage caps and negative balance protection. FCA (UK) has its own consumer duty requirements. ASIC (Australia) has sophisticated/wholesale investor categories. US regulations (FinCEN, FINRA) restrict to crypto and securities respectively.

Regulation is assigned to users during registration based on their country of residence and the legal entity serving them. It is stored on the user profile and referenced by nearly every compliance-related procedure and configuration table. The dbo.Dictionary_Regulation synonym (used by Dictionary.GetAllRegulations) provides cross-schema access.

---

## 2. Business Logic

### 2.1 Multi-Regulatory Architecture

**What**: Global platform operating under 12 distinct regulatory frameworks simultaneously.

**Columns/Parameters Involved**: `ID`, `Name`, `IsUSA`, `JurisdictionName`, `BankID`

**Rules**:
- Each user is assigned exactly one regulation based on country of residence
- IsUSA=1 (IDs 6,7,8) enables US-specific compliance workflows (FATCA, W-8BEN)
- JurisdictionName maps to the eToro legal entity (eToro EU, eToro UK, eToro AUS)
- BankID links to payment processing configuration per jurisdiction
- Active jurisdictions: CySEC, FCA, ASIC, FinCEN, FinCEN+FINRA, FSA Seychelles, FSRA
- Legacy/inactive: NFA (3), BVI (5), eToroUS (6)

**Diagram**:
```
User Country -> Regulation Assignment:
  EU countries     -> CySEC (1)
  United Kingdom   -> FCA (2)
  Australia        -> ASIC (4) or ASIC & GAML (10)
  USA (crypto)     -> FinCEN (7)
  USA (securities) -> FinCEN+FINRA (8)
  Seychelles tier  -> FSA Seychelles (9)
  Abu Dhabi        -> FSRA (11)
  Unassigned       -> None (0)
```

---

## 3. Data Overview

| ID | Name | JurisdictionName | IsUSA | Meaning |
|---|---|---|---|---|
| 0 | None | - | 0 | No regulation assigned - pre-registration or unclassified |
| 1 | CySEC | eToro EU | 0 | Cyprus Securities Exchange Commission - primary EU regulator, MiFID II |
| 2 | FCA | eToro UK | 0 | Financial Conduct Authority - UK regulator, post-Brexit standalone |
| 4 | ASIC | eToro AUS | 0 | Australian Securities and Investments Commission |
| 7 | FinCEN | - | 1 | US Money Services Business - crypto trading under applicable US laws |

*5 of 12 rows shown - selected to represent major active jurisdictions.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key. Regulation identifier: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA. See [Regulation](_glossary.md#regulation). |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Short regulation name/abbreviation used in internal systems and reports. |
| 3 | IsUSA | tinyint | NO | 0 | CODE-BACKED | US regulation flag. 1 for US jurisdictions (6,7,8), 0 for all others. Enables US-specific compliance (FATCA, W-8BEN, tax reporting). Default: 0. |
| 4 | JurisdictionName | varchar(30) | YES | - | CODE-BACKED | eToro legal entity name for this jurisdiction. NULL for legacy/partner regulations. Examples: "eToro EU", "eToro UK", "eToro AUS". |
| 5 | BankID | int | YES | - | CODE-BACKED | Payment processing configuration ID linking to banking/cashier setup. NULL for legacy regulations. Different BankIDs route to different payment providers. |
| 6 | RegulationLongName | varchar(100) | YES | - | CODE-BACKED | Full official name of the regulatory body. Used in legal disclosures and Terms & Conditions. |
| 7 | RegulationShortName | varchar(50) | YES | - | CODE-BACKED | Abbreviated name for UI display and compliance reports. May differ from Name (e.g., FinCEN Name="FinCEN" but ShortName="MSB"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user/risk tables | RegulationID | Lookup | Stores user's assigned regulation |
| KYC configuration tables | RegulationID | Lookup | Regulation-specific KYC field requirements |
| Dictionary.GetAllRegulations | - | Stored Procedure | Returns all regulations via dbo synonym |
| dbo.Dictionary_Regulation | - | Synonym/View | Cross-schema access to regulation data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.GetAllRegulations | Stored Procedure | Reads from dbo.Dictionary_Regulation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Regulation_ID | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_DictionaryRegulation_IsUSA | DEFAULT | (0) - non-US regulation by default |

---

## 8. Sample Queries

### 8.1 List all regulations
```sql
SELECT ID, Name, JurisdictionName, IsUSA, RegulationLongName
FROM Dictionary.Regulation WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find users by regulation
```sql
SELECT r.Name AS Regulation, COUNT(*) AS UserCount
FROM Customer.RiskUserInfo ri WITH (NOLOCK)
JOIN Dictionary.Regulation r WITH (NOLOCK) ON ri.RegulationID = r.ID
GROUP BY r.Name
ORDER BY UserCount DESC
```

### 8.3 Get US-regulated users
```sql
SELECT ri.CustomerID, r.Name AS Regulation
FROM Customer.RiskUserInfo ri WITH (NOLOCK)
JOIN Dictionary.Regulation r WITH (NOLOCK) ON ri.RegulationID = r.ID
WHERE r.IsUSA = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Regulation | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.Regulation.sql*
