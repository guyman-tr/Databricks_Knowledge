# BackOffice.CitizenShips

> Reference lookup of 173 citizenship/nationality labels used in KYC and regulatory compliance processes - the CitizenShip text column is protected by dynamic data masking.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY) - no PK constraint declared |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 0 (no indexes defined) |

---

## 1. Business Meaning

BackOffice.CitizenShips is a static lookup table of citizenship/nationality labels used in the BackOffice KYC (Know Your Customer) process. Each row contains an adjective form of a nationality (e.g., "British", "Israeli", "Brazilian") that BackOffice agents select when recording a customer's citizenship during identity verification. The table provides the dropdown options in the BackOffice UI via the GetCitizenShips procedure.

The CitizenShip column carries SQL Server dynamic data masking (`MASKED WITH (FUNCTION = 'default()')`), which returns an empty string for users without the UNMASK privilege. This indicates the data is treated as potentially privacy-sensitive under GDPR or similar regulations - citizenship information is a protected personal data category in many jurisdictions.

The table has 173 rows covering nationalities from Afghan to Zimbabwean. The list has some noteworthy characteristics: the UK is represented four times (ID=24 British, ID=50 English, ID=128 Scottish, ID=167 Welsh) reflecting sub-national identity options; legacy entries include ID=170 Yugoslav and ID=171 Zairean (historical nations); and entries like ID=159 UAE and ID=161 US use country abbreviations instead of demonyms, suggesting the list evolved over time without normalization.

No declared PK constraint exists in the DDL - the IDENTITY column (ID) acts as a de facto unique identifier but lacks the enforcement. No FK references to this table exist in the SSDT repo, suggesting it is consumed directly by the application.

---

## 2. Business Logic

### 2.1 Dynamic Data Masking for Privacy Compliance

**What**: The CitizenShip column is protected by SQL Server's dynamic data masking to restrict access to citizenship data to authorized users only.

**Columns Involved**: `CitizenShip`

**Rules**:
- Mask function: `default()` - for nvarchar columns, this returns an empty string `""` to users without UNMASK privilege.
- Users WITH the UNMASK server permission see the actual citizenship values.
- Users WITHOUT UNMASK see empty strings for every row's CitizenShip value.
- This aligns with GDPR Article 9 which classifies nationality/ethnic origin as a special category of sensitive personal data requiring enhanced protection.
- The MCP service account has UNMASK permission (confirmed - values are visible in queries from this environment).

---

## 3. Data Overview

| ID | CitizenShip | Meaning |
|----|-------------|---------|
| 1 | Afghan | First alphabetically. Afghanistan is an FATF high-risk jurisdiction, making this citizenship notable for KYC enhanced due diligence. |
| 24 | British | One of 4 UK-related entries (also 50=English, 128=Scottish, 167=Welsh). Allows customers to self-identify by constituent nation within the UK. |
| 77 | Israeli | Relevant as eToro is Israel-headquartered. May appear frequently in customer records. |
| 161 | US | Uses country abbreviation rather than "American". US customers face FATCA reporting requirements - this citizenship triggers specific compliance workflows. |
| 170 | Yugoslav | Historical citizenship (Yugoslavia dissolved 1991-2006). Retained for existing customer records. |

**Full list** (173 entries, alphabetical by CitizenShip): Afghan, Albanian, Algerian, Andorran, Angolan, Argentinian, Armenian, Australian, Austrian, Azerbaijani, Bahamian, Bahraini, Bangladeshi, Barbadian, Belarusian, Belgian, Belizian, Beninese, Bhutanese, Bolivian, Bosnian, Botswanan, Brazilian, British, Bruneian, Bulgarian, Burkinese, Burmese, Burundian, Cambodian, Cameroonian, Canadian, Cape Verdean, Chadian, Chilean, Chinese, Colombian, Congolese, Costa Rican, Croat, Cuban, Cypriot, Czech, Danish, Djiboutian, Dominican, Ecuadorean, Egyptian, Salvadorean, English, Eritrean, Estonian, Ethiopian, Fijian, Finnish, French, Gabonese, Gambian, Georgian, German, Ghanaian, Greek, Grenadian, Guatemalan, Guinean, Guyanese, Haitian, Dutch, Honduran, Hungarian, Icelandic, Indian, Indonesian, Iranian, Iraqi, Irish, Israeli, Italian, Jamaican, Japanese, Jordanian, Kazakh, Kenyan, Kuwaiti, Laotian, Latvian, Lebanese, Liberian, Libyan, Lithuanian, Macedonian, Malagasy, Malawian, Malaysian, Maldivian, Malian, Maltese, Mauritanian, Mauritian, Mexican, Moldovan, Monacan, Mongolian, Montenegrin, Moroccan, Mozambican, Namibian, Nepalese, New Zealand, Nicaraguan, Nigerien, North Korean, Norwegian, Omani, Pakistani, Panamanian, Papua New Guinean, Paraguayan, Peruvian, Philippine, Polish, Portuguese, Qatari, Romanian, Russian, Rwandan, Saudi Arabian, Scottish, Senegalese, Serb or Serbian, Seychellois, Sierra Leonian, Singaporean, Slovak, Slovenian, Somali, South African, South Korean, Spanish, Sri Lankan, Sudanese, Surinamese, Swazi, Swedish, Swiss, Syrian, Taiwanese, Tajik, Tanzanian, Thai, Togolese, Trinidadian, Tunisian, Turkish, Turkmen, Tuvaluan, Ugandan, Ukrainian, UAE, UK, US, Uruguayan, Uzbek, Vanuatuan, Venezuelan, Vietnamese, Welsh, Western Samoan, Yemeni, Yugoslav, Zairean, Zambian, Zimbabwean.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing row identifier. No PK constraint declared in DDL - acts as de facto unique key via IDENTITY. Not referenced by FK constraints in any known consuming table. Range: 1-173 (contiguous, no gaps). |
| 2 | CitizenShip | nvarchar(50) | NO | - | VERIFIED | Nationality/citizenship label in adjective form (e.g., "British", "Israeli", "Brazilian"). **MASKED WITH (FUNCTION = 'default()')**: users without UNMASK privilege see empty string. Returned by GetCitizenShips ordered alphabetically for BackOffice UI dropdown. 173 distinct values covering all recognized nationalities plus historical nations (Yugoslav, Zairean) and sub-national UK options (English, Scottish, Welsh). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCitizenShips | CitizenShip | READER | Returns all citizenship labels ordered alphabetically for UI dropdown |

No FK references to this table found in the SSDT repo. Application code likely matches citizenship text values directly against customer citizenship fields.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCitizenShips | Procedure | READER - provides citizenship dropdown for BackOffice UI |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined on this table. With 173 rows, sequential scan is negligible.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none declared) | - | No PK, no unique, no FK constraints in DDL. IDENTITY column provides de facto uniqueness. |

### 7.3 Dynamic Data Masking

The CitizenShip column uses `MASKED WITH (FUNCTION = 'default()')`. This is a SQL Server feature that returns an empty string for nvarchar columns when queried by users without the `UNMASK` server permission. Purpose: citizenship/nationality is classified as sensitive personal data under GDPR Article 9 (racial/ethnic origin). Only privileged BackOffice roles with UNMASK permission can see actual citizenship values.

---

## 8. Sample Queries

### 8.1 Get all citizenships for BackOffice dropdown (as GetCitizenShips does)
```sql
SELECT CitizenShip
FROM BackOffice.CitizenShips WITH (NOLOCK)
ORDER BY CitizenShip ASC
```

### 8.2 Look up a specific citizenship by name
```sql
SELECT ID, CitizenShip
FROM BackOffice.CitizenShips WITH (NOLOCK)
WHERE CitizenShip LIKE '%British%'
```

### 8.3 Get all citizenships with their IDs for reference mapping
```sql
SELECT ID, CitizenShip
FROM BackOffice.CitizenShips WITH (NOLOCK)
ORDER BY ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object. FATCA-related Confluence pages (FATCA New Procedure, FATCA Procedure) exist in the OTS space and may use citizenship data for US-person identification, but no direct link to this table was established.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CitizenShips | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CitizenShips.sql*
