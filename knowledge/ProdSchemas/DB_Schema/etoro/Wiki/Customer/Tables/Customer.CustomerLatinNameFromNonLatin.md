# Customer.CustomerLatinNameFromNonLatin

> Automated diacritic-stripping transliteration table: stores Latin-script first and last names derived from Customer.CustomerStatic by algorithmically replacing European diacritical characters (Ä, Ö, Ü, Ç, Š, etc.) with their ASCII equivalents.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (PRIMARY filegroup, PAGE compression) |
| **Indexes** | 1 (clustered PK, fillfactor=90, PAGE compression) |

---

## 1. Business Meaning

Customer.CustomerLatinNameFromNonLatin stores algorithmically-generated Latin transliterations of customer names for customers whose names in Customer.CustomerStatic contain European diacritical characters (e.g., Muller -> Muller, Novak -> Novak, Garcia -> Garcia when stored as Müller, Novák, García).

This is complementary to Customer.CustomerLatinName: while CustomerLatinName stores manually-supplied or operator-confirmed Latin names, CustomerLatinNameFromNonLatin stores names that can be derived automatically using a deterministic character-substitution map (200+ diacritical character mappings: Ä->A, Ö->O, Ü->U, Ç->C, Č->C, Ę->E, Ñ->N, etc.).

The table is populated by Customer.SetCustomerLatinNameFromNonLatin, which:
1. Builds an in-memory diacritic-to-ASCII mapping table covering Latin Extended-A/B characters
2. Scans Customer.CustomerStatic incrementally (CID > max(CID) already in this table)
3. Uses a cursor to process each customer's FirstName and LastName character-by-character
4. Inserts the transliterated results into this table

Currently 0 rows in the environment, indicating either: (a) no customers with these diacritical characters exist in this DB environment, or (b) the SetCustomerLatinNameFromNonLatin job has not been run. The procedure is incremental (resumes from last processed CID), so data accumulates over time.

The PAGE compression on the PK index reduces storage footprint for this potentially large table (applied to all customers with diacritical names). The 0-row state is expected in a non-production environment.

---

## 2. Business Logic

### 2.1 Diacritic Substitution Map

**What**: The procedure maintains an inline character mapping of 200+ diacritical Latin variants to their ASCII base characters. Covers Latin Extended-A and Latin Extended-B Unicode blocks.

**Columns/Parameters Involved**: `FirstName`, `LastName`

**Rules**:
- A->A: Ä, ä, À, à, Á, á, Â, â, Ã, ã, Å, å, Ą, ą, Ă, ă, Æ, æ
- C->C: Ç, ç, Ć, ć, Ĉ, ĉ, Č, č
- D->D: Ď, ď, Đ, đ, ð
- E->E: È, è, É, é, Ê, ê, Ë, ë, Ě, ě, Ę, ę
- N->N: Ñ, ñ, Ń, ń, Ň, ň
- O->O: Ö, ö, Ò, ò, Ó, ó, Ô, ô, Ő, ő, Ø, ø, Œ, œ
- S->S: ß, ẞ, Ś, ś, Š, š, Ş, ş, Ș, ș
- U->U: Ü, ü, Ù, ù, Ú, ú, Û, û, Ű, ű, Ų, ų, Ů, ů
- Z->Z: Ź, ź, Ž, ž, Ż, ż
- (and G, H, I, J, K, L, R, T, W, Y variants)
- Only applies to Latin-extended diacritical characters. Cyrillic, Arabic, Hebrew, and other non-Latin scripts are NOT covered by this table.

### 2.2 Incremental Batch Processing

**What**: The procedure resumes from where it last stopped by tracking the highest CID already in this table.

**Columns/Parameters Involved**: `CID`, `ModifiedDate`

**Rules**:
- @CID = MAX(CID) from this table (0 if empty)
- Processes only Customer.CustomerStatic rows where CID > @CID AND (FirstName OR LastName contains a diacritical character)
- INSERT only (no MERGE) - each CID processed exactly once; no updates if Customer.CustomerStatic name changes later
- If re-run from scratch (after TRUNCATE), full reprocessing occurs
- ModifiedDate: nullable in this table (no NOT NULL constraint unlike CustomerLatinName); default = getutcdate()

### 2.3 Scope: Name Only (No Address/City)

**What**: Unlike Customer.CustomerLatinName which includes Address and City, this table stores only FirstName and LastName.

**Rules**:
- Address transliteration is not automated via this procedure
- If a customer's address also has diacritical characters, those must be handled via manual entry in CustomerLatinName

---

## 3. Data Overview

*Customer.CustomerLatinNameFromNonLatin is currently empty (0 rows). This is expected in non-production environments where Customer.SetCustomerLatinNameFromNonLatin has not been run or no qualifying customers exist.*

Expected data pattern when populated:
| CID | FirstName | LastName | ModifiedDate | Meaning |
|---|---|---|---|---|
| (example) | Muller | Schroeder | 2024-01-01 | Customer originally stored as "Müller, Schröder" in CustomerStatic |
| (example) | Novak | Kadlec | 2024-01-01 | Customer with Czech diacriticals: "Novák, Kadlec" -> "Novak, Kadlec" |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - primary key. Each customer processed by SetCustomerLatinNameFromNonLatin gets one row. References CID in Customer.CustomerStatic (no FK constraint). |
| 2 | FirstName | varchar(100) | YES | - | CODE-BACKED | Latin-script first name with diacriticals replaced by ASCII equivalents. e.g., "Müller" -> "Muller". varchar (not nvarchar) as only ASCII characters appear after transliteration. |
| 3 | LastName | varchar(100) | YES | - | CODE-BACKED | Latin-script last name with diacriticals stripped. Processed identically to FirstName. |
| 4 | ModifiedDate | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the transliteration was recorded. Nullable (unlike CustomerLatinName where ModifiedDate is NOT NULL). Default = getutcdate(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Source of FirstName/LastName data; CID identity reference |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetCustomerLatinNameFromNonLatin | CID | WRITER | Incremental batch procedure that populates this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CustomerLatinNameFromNonLatin (table)
  <- Customer.SetCustomerLatinNameFromNonLatin reads Customer.CustomerStatic
```

### 6.1 Objects This Depends On

No FK dependencies (no constraints declared).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetCustomerLatinNameFromNonLatin | Stored Procedure | Reads MAX(CID) for incremental tracking; inserts transliterated names |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Customer_CustomerLatinNameFromNonLatin | CLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Customer_CustomerLatinNameFromNonLatin | PRIMARY KEY | CID must be unique - one transliteration row per customer (PAGE compression applied) |
| Df_Customer_CustomerLatinNameFromNonLatin_ModifiedDate | DEFAULT | ModifiedDate = getutcdate() |

---

## 8. Sample Queries

### 8.1 Check transliteration coverage

```sql
SELECT COUNT(*) AS TransliteratedCustomers
FROM Customer.CustomerLatinNameFromNonLatin WITH (NOLOCK)
-- 0 = not yet populated or no qualifying customers
```

### 8.2 Find customers with diacritical names not yet transliterated (when table is populated)

```sql
SELECT cs.CID, cs.FirstName, cs.LastName
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.CID > (SELECT ISNULL(MAX(CID), 0) FROM Customer.CustomerLatinNameFromNonLatin WITH (NOLOCK))
  AND (cs.FirstName LIKE N'%[^A-Za-z0-9 -]%'
    OR cs.LastName  LIKE N'%[^A-Za-z0-9 -]%')
ORDER BY cs.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerLatinNameFromNonLatin | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CustomerLatinNameFromNonLatin.sql*
