# Dictionary.Regulation

> Lookup table defining the financial regulatory authorities under which eToro entities operate, controlling compliance rules, leverage limits, instrument availability, and legal jurisdiction.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Regulation defines the 15 regulatory jurisdictions under which eToro operates globally. Each regulation represents a financial authority (CySEC, FCA, ASIC, FinCEN, etc.) and maps to an eToro legal entity that holds the corresponding license. This classification is the cornerstone of multi-jurisdiction compliance — it determines which rules apply to each user, what instruments they can trade, what leverage limits are enforced, how their funds are segregated, and what documentation is required.

This table is essential because eToro operates simultaneously under multiple regulatory frameworks. A user in the UK falls under FCA rules (ID=2), a user in Germany under CySEC (ID=1), and a US user under FinCEN/FINRA (ID=7/8). Without this table, the platform cannot correctly route users to the appropriate legal entity, apply the right leverage caps, enforce jurisdiction-specific trading restrictions, or generate compliant tax/regulatory reports.

RegulationID is assigned to users at registration time (stored in Customer.CustomerStatic) and propagated through every subsequent operation — deposits (Billing.Deposit), trading (Trade procedures), copy-trading (Trade.GetMirrorRegisterData), risk classification (RiskCalculation), and compliance (Compliance schema). It is one of the most frequently joined columns in the entire database.

---

## 2. Business Logic

### 2.1 US vs Non-US Regulatory Split

**What**: The platform fundamentally splits its regulatory treatment between US and non-US jurisdictions.

**Columns/Parameters Involved**: `ID`, `IsUSA`

**Rules**:
- **Non-US regulations** (IsUSA=0): CySEC (1), FCA (2), NFA (3), ASIC (4), BVI (5), FSA Seychelles (9), ASIC & GAML (10), FSRA (11), MAS (13). DefaultRegulationID=5 (BVI fallback)
- **US regulations** (IsUSA=1): eToroUS (6), FinCEN (7), FinCEN+FINRA (8), FINRAONLY (12), NYDFS+FINRA (14). DefaultRegulationID=6 (eToroUS fallback)
- US regulations have completely different instrument availability (no CFDs, securities-only under FINRA)
- US regulations require different KYC (SSN, W-9 forms) and tax reporting (1099)
- The IsUSA flag is used as a top-level branch in many business logic decisions

**Diagram**:
```
Dictionary.Regulation
├── Non-US (IsUSA=0, DefaultRegulation=5/BVI)
│   ├── 1: CySEC (EU - Cyprus) ──► JurisdictionName: "eToro EU"
│   ├── 2: FCA (UK) ──► JurisdictionName: "eToro UK"
│   ├── 4: ASIC (Australia) ──► JurisdictionName: "eToro AUS"
│   ├── 9: FSA Seychelles
│   ├── 10: ASIC & GAML (Australia + AML)
│   ├── 11: FSRA (Abu Dhabi)
│   └── 13: MAS (Singapore)
│
└── US (IsUSA=1, DefaultRegulation=6/eToroUS)
    ├── 7: FinCEN (crypto-only, MSB license)
    ├── 8: FinCEN+FINRA (crypto + securities)
    ├── 12: FINRAONLY (securities-only)
    └── 14: NYDFS+FINRA (NY + securities)
```

### 2.2 Regulation-to-Bank Custody Mapping

**What**: Each regulation maps to a specific banking partner for client fund segregation.

**Columns/Parameters Involved**: `ID`, `BankID`

**Rules**:
- CySEC (1) and FCA (2) → BankID=7 (LeumiCard, now inactive — likely migrated)
- ASIC (4) and ASIC & GAML (10) and FSRA (11) → BankID=8 (B&S, now inactive)
- FinCEN (7) → BankID=9 (GCS, now inactive)
- Many regulations have NULL BankID, indicating either no dedicated custodian or custodian managed externally
- Billing.GetBankIDByRegulationAndCountry resolves the actual active bank at transaction time

### 2.3 Default Regulation Fallback

**What**: Regulations have a fallback/default regulation for edge cases.

**Columns/Parameters Involved**: `ID`, `DefaultRegulationID`

**Rules**:
- Non-US regulations default to BVI (ID=5) — the least restrictive jurisdiction
- US regulations default to eToroUS (ID=6)
- BVI (5) and eToroUS (6) have NULL DefaultRegulationID — they are the terminal fallback

---

## 3. Data Overview

| ID | Name | IsUSA | JurisdictionName | Meaning |
|---|---|---|---|---|
| 1 | CySEC | 0 | eToro EU | Cyprus Securities Exchange Commission — the primary EU regulation. Governs most European users. Subject to ESMA leverage caps (30x forex, 5x stocks). Administered by eToro (Europe) Ltd. |
| 2 | FCA | 0 | eToro UK | Financial Conduct Authority — UK regulation. Post-Brexit separation from CySEC. Subject to FCA leverage and marketing rules. Administered by eToro (UK) Ltd. |
| 7 | FinCEN | 1 | - | Financial Crimes Enforcement Network — US crypto regulation under Money Services Business (MSB) license. Users can only trade crypto, not securities. |
| 8 | FinCEN+FINRA | 1 | - | Dual US regulation combining crypto (FinCEN/MSB) and securities (FINRA). Users can trade both crypto and US stocks. |
| 5 | BVI | 0 | - | British Virgin Islands — the default fallback regulation for users in jurisdictions without a specific eToro entity. Least restrictive rules. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in Customer.CustomerStatic.RegulationID. See [Regulation](_glossary.md#regulation). (Dictionary.Regulation) |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Short code for the regulation. Used in code branching (`CASE WHEN RegulationName = 'CySEC'`), logging, and API responses. |
| 3 | IsUSA | tinyint | NO | (0) | VERIFIED | Whether this regulation governs US users. 1=US jurisdiction (affects instrument availability, tax forms, leverage), 0=non-US. Used as a primary branch in business logic across Trading, Billing, and Compliance schemas. |
| 4 | JurisdictionName | varchar(30) | YES | - | CODE-BACKED | The eToro legal entity name for this jurisdiction (e.g., "eToro EU", "eToro UK", "eToro AUS"). NULL for regulations without a dedicated legal entity. Used in legal documents, terms & conditions, and regulatory disclosures. |
| 5 | BankID | int | YES | - | CODE-BACKED | FK to Dictionary.Bank — the banking partner for client fund custody under this regulation. NULL when the custodian is managed externally or not yet assigned. See [Dictionary.Bank](Dictionary.Bank.md). |
| 6 | RegulationLongName | varchar(100) | YES | - | CODE-BACKED | Full formal name of the regulatory authority (e.g., "Cyprus Securities Exchange Commission (CySEC)"). Used in legal disclosures, terms & conditions, and regulatory filings. |
| 7 | RegulationShortName | varchar(50) | YES | - | CODE-BACKED | Abbreviated regulatory name for compact display (e.g., "CySEC", "FCA", "MSB"). Used in UI badges, compliance dashboards, and compact reporting. |
| 8 | DefaultRegulationID | int | YES | - | CODE-BACKED | Self-reference to Dictionary.Regulation — the fallback regulation when this regulation cannot process a specific operation. Non-US → BVI (5), US → eToroUS (6). Used in edge cases where the primary regulation has restrictions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BankID | Dictionary.Bank | FK | Maps this regulation to its custodian banking partner |
| DefaultRegulationID | Dictionary.Regulation | Self-Reference | Fallback regulation for edge cases |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | RegulationID | Implicit Lookup | Every customer is assigned a regulation at registration |
| Billing.Deposit | RegulationID | Implicit Lookup | Deposits track the regulation for routing and compliance |
| Billing.ExcludedCurrenciesByCountryAndRegulation | RegulationID | Implicit Lookup | Currency exclusions per regulation |
| Email.MarketingEmailFooter | RegulationID | Implicit Lookup | Legal footer text varies by regulation |
| Dictionary.RiskClassificationRegulation | RegulationID | Implicit Lookup | Risk classification rules per regulation |
| Trade.GetMirrorRegisterData | RegulationID | Read | Copy-trading registration checks regulation |
| Trade.GetMirrorEquityData | RegulationID | Read | Copy equity calculations per regulation |
| Billing.DepositAdd | RegulationID | Read | Deposit processing routes by regulation |
| Billing.GetBankIDByRegulationAndCountry | RegulationID | Read | Resolves bank for deposit processing |
| BackOffice.GetCustomerByCID | RegulationID | Read | Customer lookup includes regulation |
| Compliance.AddNewRegulation | RegulationID | Write | Adds new regulation entries |
| Compliance.GetQuestionsExpirationPopulation | @RegulationID | Read (filter) | @RegulationID parameter scopes the KYC reconfirmation population to a specific regulatory jurisdiction (e.g., 1=CySEC, 2=FCA) |
| Compliance.GetQuestionsExpirationPopulationNew | @RegulationID | Read (filter) | Same @RegulationID regulation filter as the original SP (performance-optimized variant; has a known @questions.CID column bug) |
| RiskCalculation.SetRiskClassificationForCySec | RegulationID | Read | CySEC-specific risk classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Regulation (table)
└── Dictionary.Bank (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Bank | Table | FK: BankID references custodian bank |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Stores RegulationID per customer |
| Billing.Deposit | Table | Regulation for deposit routing |
| Billing.ExcludedCurrenciesByCountryAndRegulation | Table | Currency exclusions per regulation |
| Email.MarketingEmailFooter | Table | Legal footer per regulation |
| Dictionary.RiskClassificationRegulation | Table | Risk rules per regulation |
| Trade.GetMirrorRegisterData | Stored Procedure | Copy-trading regulation check |
| Billing.DepositAdd | Stored Procedure | Deposit routing by regulation |
| Billing.GetBankIDByRegulationAndCountry | Stored Procedure | Bank resolution |
| BackOffice.GetCustomerByCID | Stored Procedure | Customer lookup |
| RiskCalculation.SetRiskClassificationForCySec | Stored Procedure | CySEC risk classification |
| Compliance.AddNewRegulation | Stored Procedure | Inserts new regulation entries; also validates via SELECT before and after INSERT |
| Compliance.GetQuestionsExpirationPopulation | Stored Procedure | @RegulationID parameter scopes KYC reconfirmation population to a specific regulatory jurisdiction |
| Compliance.GetQuestionsExpirationPopulationNew | Stored Procedure | Same @RegulationID filter; performance-optimized variant with known @questions column bug |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Regulation_ID | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Regulation_ID | PRIMARY KEY | Unique regulation identifier |
| DF_DictionaryRegulation_IsUSA | DEFAULT | IsUSA defaults to 0 (non-US) |
| FK_DictionaryRegulation_DictionaryBankID | FK | BankID → Dictionary.Bank(BankID) |

---

## 8. Sample Queries

### 8.1 List all regulations with jurisdiction details
```sql
SELECT  ID,
        Name,
        RegulationLongName,
        JurisdictionName,
        CASE WHEN IsUSA = 1 THEN 'US' ELSE 'Non-US' END AS Region
FROM    [Dictionary].[Regulation] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count customers per regulation
```sql
SELECT  r.Name AS Regulation,
        r.JurisdictionName,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[Regulation] r WITH (NOLOCK)
        ON cs.RegulationID = r.ID
GROUP BY r.Name, r.JurisdictionName
ORDER BY CustomerCount DESC;
```

### 8.3 Show regulation with banking partner and default fallback
```sql
SELECT  r.ID,
        r.Name,
        r.JurisdictionName,
        b.Name AS BankPartner,
        dr.Name AS DefaultFallback
FROM    [Dictionary].[Regulation] r WITH (NOLOCK)
LEFT JOIN [Dictionary].[Bank] b WITH (NOLOCK)
        ON r.BankID = b.BankID
LEFT JOIN [Dictionary].[Regulation] dr WITH (NOLOCK)
        ON r.DefaultRegulationID = dr.ID
ORDER BY r.ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.Regulation. Business meaning derived from live data analysis and extensive usage across Billing, Trade, Compliance, and BackOffice schemas.

---

*Generated: 2026-03-13 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Regulation | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Regulation.sql*
