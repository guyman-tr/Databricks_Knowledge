# Dictionary.SpecialChar

> Reference table mapping accented and special Unicode characters to their ASCII equivalents for name normalization in identity verification.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Key (NCHAR(1), PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.SpecialChar provides a character transliteration map used to normalize user names containing accented or special characters into ASCII equivalents. When performing Electronic Verification (EV), user names must be standardized to match against data sources that may not support Unicode. This table ensures consistent matching across languages and character sets.

This table covers 136 character mappings across Latin Extended characters from French, German, Spanish, Portuguese, Turkish, Polish, Czech, Romanian, Scandinavian, and other European languages. For example, "Muller" with an umlaut becomes "Muller", and "Gonzalez" with a tilde becomes "Gonzalez".

The table is read by name normalization routines before sending user data to EV providers. Without it, names like "Bjorn" (with accented 'o') would fail to match against provider data that stores "Bjorn" in ASCII.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Character substitution map. See individual element descriptions in Section 4.

---

## 3. Data Overview

| Key | Value | Meaning |
|---|---|---|
| a (with accent) | A | French/Spanish/Portuguese accented 'a' variants all normalize to 'A' |
| c (with cedilla) | C | French/Turkish cedilla normalizes to 'C' |
| n (with tilde) | N | Spanish tilde normalizes to 'N' |
| u (with umlaut) | U | German umlaut normalizes to 'U' |
| ss (sharp s) | S | German Eszett normalizes to 'S' |

*5 representative mappings of 136 total.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Key | nchar(1) | NO | - | CODE-BACKED | Primary key. The Unicode character to be replaced (e.g., accented vowels, cedilla, umlaut, tilde). Single character. |
| 2 | Value | char(1) | NO | - | CODE-BACKED | The ASCII replacement character. Always a basic Latin letter (A-Z). Used in name normalization for EV matching. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Name normalization routines | Key | Lookup | Used to transliterate names before EV matching |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_SpecialChar | CLUSTERED PK | Key | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all character mappings
```sql
SELECT [Key], Value FROM Dictionary.SpecialChar WITH (NOLOCK) ORDER BY [Key]
```

### 8.2 Normalize a name
```sql
DECLARE @Name NVARCHAR(100) = N'Muller'
SELECT @Name = REPLACE(@Name, [Key], Value) FROM Dictionary.SpecialChar WITH (NOLOCK)
SELECT @Name AS NormalizedName
```

### 8.3 Count mappings per target letter
```sql
SELECT Value AS TargetLetter, COUNT(*) AS SourceCharCount
FROM Dictionary.SpecialChar WITH (NOLOCK)
GROUP BY Value ORDER BY SourceCharCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.SpecialChar | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.SpecialChar.sql*
