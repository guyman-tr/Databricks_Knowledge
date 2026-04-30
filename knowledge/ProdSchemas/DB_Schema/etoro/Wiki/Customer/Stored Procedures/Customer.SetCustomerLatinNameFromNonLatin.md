# Customer.SetCustomerLatinNameFromNonLatin

> Incremental batch job that algorithmically converts European diacritical characters (Ä->A, Ö->O, Ü->U, Č->C, Ñ->N, etc.) in customer FirstName and LastName from Customer.CustomerStatic and inserts the ASCII-transliterated results into Customer.CustomerLatinNameFromNonLatin; resumes from the last processed CID on each run.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; resumes from MAX(CID) in Customer.CustomerLatinNameFromNonLatin |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetCustomerLatinNameFromNonLatin` is an automated batch transliteration job that processes Customer.CustomerStatic records where the customer's FirstName or LastName contains European diacritical characters (e.g., Muller from Müller, Schmidt from Schmitt, Garcia from García). It strips diacritics and substitutes the ASCII base letter, inserting the result into Customer.CustomerLatinNameFromNonLatin.

This is the automated counterpart to `SetCustomerLatinName` (which handles manually-provided Latin names). While SetCustomerLatinName relies on operator input or external transliteration tools for non-Latin scripts (Cyrillic, Arabic, Hebrew), SetCustomerLatinNameFromNonLatin handles the algorithmic case - Latin Extended-A/B diacritical characters that have a deterministic ASCII equivalent. The character substitution map covers 200+ diacritical variants across A, C, D, E, G, H, I, J, K, L, N, O, R, S, T, U, W, Y, Z.

The procedure is incremental by design: it reads the current MAX(CID) from the target table and only processes CustomerStatic records with CID greater than that value. This means it can be safely scheduled as a recurring job - each run extends the transliteration coverage without re-processing already-converted customers.

---

## 2. Business Logic

### 2.1 Incremental Resume Point

**What**: Determines where to resume by reading the max already-processed CID.

**Columns/Parameters Involved**: `Customer.CustomerLatinNameFromNonLatin.CID`, `@CID`

**Rules**:
- `SELECT @CID = ISNULL(MAX(CID), 0) FROM Customer.CustomerLatinNameFromNonLatin`
- If table is empty: @CID = 0, all CustomerStatic records are processed.
- If table has data: only CustomerStatic rows with CID > @CID are processed (incremental).
- No explicit lock or transaction guard on this read - concurrent runs could theoretically overlap, but INSERTs on a PK-keyed table would simply fail for duplicates.

### 2.2 Diacritical Character Mapping Table

**What**: An in-memory table variable @T holds the 200+ non-Latin -> Latin character substitution map.

**Columns/Parameters Involved**: `@T.Latin CHAR(1)`, `@T.NonLatin NCHAR(1)`

**Rules**:
- Built via a CTE (T) that defines VALUES tuples for each (Latin, NonLatin) pair.
- Covers Latin Extended-A and Latin Extended-B Unicode blocks:
  - A: Ä ä À à Á á Â â Ã ã Å å Ǎ ǎ Ą ą Ă ă Æ æ
  - C: Ç ç Ć ć Ĉ ĉ Č č
  - D: Ď ď Đ đ ð
  - E: È è É é Ê ê Ë ë Ě ě Ę ę
  - G: Ĝ ĝ Ģ ģ Ğ ğ
  - H: Ĥ ĥ
  - I: Ì ì Í í Î î Ï ï ı
  - J: Ĵ ĵ
  - K: Ķ ķ
  - L: Ĺ ĺ Ļ ļ Ł ł Ľ ľ
  - N: Ñ ñ Ń ń Ň ň
  - O: Ö ö Ò ò Ó ó Ô ô Õ õ Ő ő Ø ø Œ œ
  - R: Ŕ ŕ Ř ř
  - S: ẞ ß Ś ś Ŝ ŝ Ş ş Š š Ș ș
  - T: Ť ť Ţ ţ Þ þ Ț ț
  - U: Ü ü Ù ù Ú ú Û û Ű ű Ũ ũ Ų ų Ů ů
  - W: Ŵ ŵ
  - Y: Ý ý Ÿ ÿ Ŷ ŷ
  - Z: Ź ź Ž ž Ż ż
- Note: one entry `('U', N'ǎ')` appears to be a copy-paste typo - 'ǎ' (A with caron) maps to 'A' but is mapped to 'U' here. This is a minor data quality issue in the mapping.
- @T uses a PRIMARY KEY CLUSTERED on NonLatin (NCHAR(1)) - efficient lookup by character.

### 2.3 Candidate Customer Identification

**What**: Selects CustomerStatic rows with CID > @CID that have at least one diacritical character in FirstName or LastName.

**Columns/Parameters Involved**: `Customer.CustomerStatic.CID`, `FirstName`, `LastName`, `@CID`

**Rules**:
- `SELECT CID, FirstName, LastName INTO #CustomerLatinNameFromNonLatin FROM Customer.CustomerStatic (NOLOCK) WHERE CID > @CID AND EXISTS (SELECT * FROM @T T WHERE CONCAT(FirstName, LastName) LIKE CONCAT(N'%', T.NonLatin, N'%'))`
- Uses EXISTS + LIKE for the filter - checks the concatenated name string against all 200+ non-Latin characters.
- NOLOCK hint on CustomerStatic (dirty read acceptable for this batch job).
- Temp table used as cursor source (avoids re-reading CustomerStatic in the cursor loop).

### 2.4 Character-by-Character Substitution (CURSOR Loop)

**What**: For each candidate customer, iterates through each character of FirstName and LastName, replacing non-Latin characters with their Latin equivalents.

**Columns/Parameters Involved**: `@FirstName`, `@LastName`, `@N` (position counter)

**Rules**:
- CURSOR iterates over #CustomerLatinNameFromNonLatin rows.
- Inner WHILE loop over positions 1 to LEN(@FirstName): `SELECT TOP 1 @FirstName = REPLACE(@FirstName, NonLatin, Latin) FROM @T WHERE SUBSTRING(@FirstName, @N, 1) = NonLatin`
- If position @N is not in @T (i.e., is already a plain ASCII character), the SELECT returns no rows and @FirstName is unchanged for that position.
- Same inner loop applied to @LastName.
- The position-by-position approach handles multi-diacritical names correctly (each character is checked independently).

### 2.5 Insert Transliterated Record

**What**: Inserts the transliterated (FirstName, LastName) for the processed CID.

**Columns/Parameters Involved**: `Customer.CustomerLatinNameFromNonLatin.CID`, `FirstName`, `LastName`

**Rules**:
- `INSERT INTO Customer.CustomerLatinNameFromNonLatin(CID, FirstName, LastName) VALUES(@CID, @FirstName, @LastName)`
- Note: Address, City, and MiddleName are NOT included - only FirstName and LastName are processed (unlike SetCustomerLatinName which handles all 5 fields).
- No UPDATE path - if a CID was somehow already present (concurrent run), the INSERT would fail on the PK constraint.

### 2.6 Error Handling

**What**: PRINT+THROW pattern consistent with other Customer schema procedures.

**Rules**:
- CATCH block logs diagnostic info (server, DB, procedure, error details, @@TranCount, timestamp) via PRINT.
- THROW re-raises to caller.
- No explicit transaction - each INSERT is auto-committed; partial runs leave the table with data up to the last successful INSERT (incremental design means the next run continues from where it left off).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure has no input or output parameters. It is a self-contained batch job driven entirely by the state of Customer.CustomerLatinNameFromNonLatin (resume CID) and Customer.CustomerStatic (source data). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MAX(CID) read | Customer.CustomerLatinNameFromNonLatin | READ (resume state) | Determines the last processed CID to enable incremental execution |
| Candidate scan | Customer.CustomerStatic | READ (source) | Source of CID, FirstName, LastName for customers with diacritical names |
| INSERT results | Customer.CustomerLatinNameFromNonLatin | WRITER (INSERT) | Inserts CID + transliterated FirstName + LastName records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduled job / BackOffice automation | External | Caller | Run periodically to extend transliteration coverage for newly registered customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetCustomerLatinNameFromNonLatin (procedure)
+-- Customer.CustomerLatinNameFromNonLatin (table) [READ resume CID + INSERT results]
+-- Customer.CustomerStatic (table) [READ source FirstName, LastName, CID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerLatinNameFromNonLatin | Table | SELECT MAX(CID) for resume; INSERT transliterated records |
| Customer.CustomerStatic | Table | SELECT source CID, FirstName, LastName for candidate customers |

### 6.2 Objects That Depend On This

No dependents found in Customer schema DDL. Called externally by scheduled job infrastructure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Incremental design | Design | Resumes from MAX(CID) in target table - safe for repeated scheduling; no re-processing of already-converted customers |
| CURSOR + nested WHILE | Performance | Character-by-character replacement is O(n*m) where n=name length, m=mapping entries. Acceptable for batch job, not suitable for real-time use. |
| FirstName/LastName only | Scope | Does NOT transliterate Address, City, or MiddleName (unlike SetCustomerLatinName which handles all 5 fields) |
| No UPDATE path | Design | INSERT-only; PK violation if CID already exists. Concurrent runs would fail. Intended as single-run-at-a-time job. |
| 'ǎ' -> 'U' mapping anomaly | Known defect | The character 'ǎ' (a with caron, U+01CE) is mapped to 'U' instead of 'A' in the character table. Minor data quality issue. |
| NOLOCK on CustomerStatic | Performance | Dirty reads accepted for batch transliteration - consistency is not critical here |

---

## 8. Sample Queries

### 8.1 Run the transliteration batch

```sql
EXEC Customer.SetCustomerLatinNameFromNonLatin;
-- No parameters - runs incrementally from last processed CID
```

### 8.2 Check current batch state

```sql
SELECT MAX(CID) AS LastProcessedCID,
       COUNT(*) AS TotalTransliteratedCustomers
FROM Customer.CustomerLatinNameFromNonLatin WITH (NOLOCK)
```

### 8.3 Find customers still needing transliteration

```sql
-- Customers in CustomerStatic with diacritical chars not yet in target table
SELECT COUNT(*) AS PendingCustomers
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.CID > (SELECT ISNULL(MAX(CID), 0) FROM Customer.CustomerLatinNameFromNonLatin WITH (NOLOCK))
  AND (cs.FirstName COLLATE Latin1_General_BIN LIKE N'%[ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞ]%'
    OR cs.LastName COLLATE Latin1_General_BIN LIKE N'%[ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞ]%')
```

### 8.4 Verify a transliteration result

```sql
SELECT cs.CID,
       cs.FirstName AS OriginalFirstName,
       cs.LastName AS OriginalLastName,
       t.FirstName AS TransliteratedFirstName,
       t.LastName AS TransliteratedLastName
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN Customer.CustomerLatinNameFromNonLatin t WITH (NOLOCK) ON t.CID = cs.CID
WHERE cs.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 7.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetCustomerLatinNameFromNonLatin | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetCustomerLatinNameFromNonLatin.sql*
