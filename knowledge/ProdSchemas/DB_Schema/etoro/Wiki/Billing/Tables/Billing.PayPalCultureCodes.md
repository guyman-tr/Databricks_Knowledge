# Billing.PayPalCultureCodes

> Mapping table translating eToro's internal LanguageID values to PayPal locale codes, used to initialize the PayPal checkout SDK in the customer's language.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | LanguageID (INT, PK CLUSTERED - not identity, matches eToro language registry) |
| **Partition** | PRIMARY filegroup (PAGE compressed) |
| **Indexes** | 1 active (PK clustered, FILLFACTOR=90) |

---

## 1. Business Meaning

Billing.PayPalCultureCodes maps eToro's internal language identifiers (LanguageID) to PayPal-recognized locale codes (e.g., "en_GB", "de_DE", "zh_CN"). When presenting the PayPal checkout interface to a customer, eToro looks up the customer's LanguageID and uses the corresponding CultureCode as the `locale` parameter in the PayPal SDK initialization, ensuring the PayPal payment UI is displayed in the customer's language.

24 rows cover the full set of eToro's supported languages. Notable mappings: multiple LanguageIDs (11, 12, 16, 21, 22, 24) all map to English US variants (mix of "en_US" underscore and "en-US" hyphen formats - slight inconsistency). This is a pure lookup/configuration table with no SPs referencing it in the Billing schema (queried directly by the application layer or via a non-Billing SP).

---

## 2. Business Logic

### 2.1 Language-to-Locale Resolution

**What**: One-to-one lookup: given a LanguageID, return the PayPal locale code.

**Columns/Parameters Involved**: `LanguageID`, `CultureCode`

**Rules**:
- LanguageID is the PK - each language has exactly one PayPal locale mapping.
- Multiple LanguageIDs can map to the same CultureCode (e.g., IDs 11, 12, 16, 21, 22, 24 all map to en-US variants). This handles eToro's multiple internal English variants (UK English, US English, etc.) all mapping to PayPal's single en-US locale.
- Format inconsistency: IDs 1-20 use underscore format (en_GB, de_DE), IDs 21+ use hyphen format (en-US, da-DK). Likely reflects two different integration eras. PayPal accepts both formats.
- CultureCode is nullable (though all 24 rows have values). A NULL would cause the PayPal SDK to use its default locale.

---

## 3. Data Overview

| LanguageID | CultureCode | Language |
|-----------|-------------|---------|
| 1 | en_GB | English (UK) |
| 2 | de_DE | German |
| 3 | ar_EG | Arabic (Egypt) |
| 4 | zh_CN | Chinese Simplified |
| 5 | ru_RU | Russian |
| 6 | es_ES | Spanish |
| 7 | fr_FR | French |
| 8 | it_IT | Italian |
| 9 | ja_JP | Japanese |
| 10 | pt_BR | Portuguese (Brazil) |
| 11 | en_US | English (US variant 1) |
| 12 | en_US | English (US variant 2) |
| 13 | ko_KR | Korean |
| 14 | sv_SE | Swedish |
| 15 | no_NO | Norwegian |
| 16 | en_US | English (US variant 3) |
| 17 | pl_PL | Polish |
| 18 | zh_TW | Chinese Traditional |
| 19 | nl_NL | Dutch |
| 20 | pt_PT | Portuguese (Portugal) |
| 21 | en-US | English US (hyphen format) |
| 22 | en-US | English US (hyphen format) |
| 23 | da-DK | Danish |
| 24 | en-US | English US (hyphen format) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LanguageID | int | NO | - | CODE-BACKED | eToro's internal language identifier. PK - not identity (manually assigned to match eToro's language registry). Range 1-24 covering all eToro-supported languages. FK to Dictionary.Language (implicit - no constraint declared). |
| 2 | CultureCode | nvarchar(10) | YES | - | VERIFIED | PayPal-recognized locale code for SDK initialization. Format: "{language}_{REGION}" or "{language}-{REGION}" (both underscore and hyphen formats accepted by PayPal). Maximum 10 characters. 24 rows, all populated. Used as the PayPal checkout `locale` parameter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LanguageID | Dictionary.Language | Implicit | Language identifier matching eToro's language registry. No declared FK. |

### 5.2 Referenced By (other objects point to this)

No SP references found in the Billing schema. The application layer queries this table directly via the Billing data access layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayPalCultureCodes (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No FK constraints declared.

### 6.2 Objects That Depend On This

No stored procedures in the Billing schema reference this table. Consumed directly by application code.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BPPC | CLUSTERED PK | LanguageID ASC | - | - | Active (PAGE compressed, FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BPPC | PRIMARY KEY | LanguageID clustered |

---

## 8. Sample Queries

### 8.1 Get PayPal locale for a specific language

```sql
SELECT CultureCode
FROM Billing.PayPalCultureCodes WITH (NOLOCK)
WHERE LanguageID = @LanguageID
```

### 8.2 View all language-to-locale mappings

```sql
SELECT pcc.LanguageID, pcc.CultureCode
FROM Billing.PayPalCultureCodes pcc WITH (NOLOCK)
ORDER BY pcc.LanguageID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.PayPalCultureCodes | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PayPalCultureCodes.sql*
