# Customer.CustomerLatinName

> Per-customer Latin-script transliteration store: holds converted versions of customer names (first, last, middle), address, and city for KYC/tax/regulatory reporting where non-Latin scripts must be represented in ASCII/Latin characters.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK, fillfactor=95) |

---

## 1. Business Meaning

Customer.CustomerLatinName stores Latin-script (ASCII-transliterated) versions of customer name and address fields. When a customer's legal name is in a non-Latin script (Cyrillic, Arabic, Hebrew, etc.) or contains diacritical characters, the platform must also store Latin equivalents for regulatory reporting, KYC verification, tax forms, and integration with systems that cannot handle Unicode names.

Each row is a per-customer override: one row per CID, containing the Latin versions of FirstName, LastName, MiddleName, Address, and City. The table is populated via MERGE upsert through Customer.SetCustomerLatinName, which accepts a batch of CID + Latin name data as a TVP (Customer.CustomerLatinNameType). The Latin name data originates from operator input (BackOffice), automated transliteration tools, or customer self-submission.

10,506 rows currently, indicating a meaningful subset of customers have Latin name data recorded - likely those from countries with non-Latin scripts (Russia, UAE, Israel, Greece, etc.) where regulatory submissions require Latin transliterations.

A staging counterpart (Customer.CustomerLatinNameTemp, same DDL structure) exists in SSDT but is not deployed in the current environment. A separate automated transliteration table (Customer.CustomerLatinNameFromNonLatin) handles diacritical European characters programmatically.

This table is flagged as PII in the Data Lake platform (BDP space), confirming it contains personally identifiable information subject to GDPR and data masking requirements.

---

## 2. Business Logic

### 2.1 MERGE Upsert via TVP

**What**: Customer.SetCustomerLatinName performs a MERGE upsert - INSERT if CID not in table, UPDATE if CID exists. Accepts batch input via Customer.CustomerLatinNameType TVP.

**Columns/Parameters Involved**: `CID`, `FirstName`, `LastName`, `MiddleName`, `Address`, `City`, `ModifiedDate`

**Rules**:
- On INSERT: all columns populated from TVP; ModifiedDate = GetUTCDate() (procedure-level, overrides table DEFAULT of getdate())
- On UPDATE: FirstName, LastName, Address, City, MiddleName all replaced; ModifiedDate = GetUTCDate()
- NULL columns in TVP source: stored as NULL in the table (no partial-update logic)
- One row per CID - the MERGE ensures idempotency; re-submitting the same CID updates the existing row

### 2.2 Latin Transliteration Scope

**What**: This table covers both manually-supplied Latin names and those transliterated from non-Latin scripts (Cyrillic, Arabic, Hebrew, etc.). It stores all 5 personal fields including Address and City.

**Columns/Parameters Involved**: `FirstName`, `LastName`, `MiddleName`, `Address`, `City`

**Rules**:
- All varchar (not nvarchar) - stored in Latin1 characters only; Unicode non-Latin characters should not appear here
- MiddleName: nullable - not all naming conventions have a middle name; stored as empty string ('') in current data for test accounts
- Address and City: Latin transliterations of physical address for KYC/W8BEN/W9 forms
- The automated diacritic-stripping process (SetCustomerLatinNameFromNonLatin) covers European diacritical marks; this table covers the result of all transliteration methods

---

## 3. Data Overview

| CID | FirstName | LastName | MiddleName | Address | City | Meaning |
|---|---|---|---|---|---|---|
| 149 | YoniAssia | YoniAssia | (empty) | ssss | ssss | Test account - name=same as username placeholder |
| 10669626 | Hanz | Berger | NULL | NULL | NULL | Real customer: name only, no address stored |
| 13549670 | QAdovivqckro | QAhbtiwawbib | QAcgxhjvoscd | Dobelner Strabe | Lommatzsch | QA test data with German address |

*10,506 total rows. Most recent ModifiedDate: 2024-05-02 (bulk refresh). Test accounts (QA*, attack*) visible alongside real customer data.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - primary key. One Latin name record per customer. References CID in Customer.CustomerStatic (no FK constraint declared). |
| 2 | FirstName | varchar(100) | YES | - | CODE-BACKED | Latin-script first name. Transliterated from original non-Latin first name or supplied directly. varchar (not nvarchar) ensures only Latin/ASCII characters stored. |
| 3 | LastName | varchar(100) | YES | - | CODE-BACKED | Latin-script last name. Transliterated equivalent of the customer's legal surname. |
| 4 | ModifiedDate | datetime | NO | getdate() | CODE-BACKED | UTC timestamp of last update. Default = getdate() (table-level), but Customer.SetCustomerLatinName explicitly sets GetUTCDate() on insert and update. Always UTC. |
| 5 | Address | varchar(200) | YES | - | CODE-BACKED | Latin-script street address. Used for KYC and tax form submissions (W8BEN mailing address). NULL when address was not provided. |
| 6 | City | varchar(100) | YES | - | CODE-BACKED | Latin-script city name. Complements Address for full mailing address on regulatory forms. NULL when address was not provided. |
| 7 | MiddleName | varchar(100) | YES | - | CODE-BACKED | Latin-script middle name. Nullable - many naming conventions do not include middle names. Empty string ('') stored for some accounts where MiddleName was set but empty in the source TVP. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | CID is the customer identifier; no FK constraint declared |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetCustomerLatinName | CID | MERGE WRITER | Primary write path: MERGE upsert via CustomerLatinNameType TVP |
| Customer.CustomerLatinNameTemp | CID | Staging twin | Structurally identical staging table used during bulk operations |
| Customer.CustomerLatinNameFromNonLatin | CID | Related | Stores automated diacritic-stripped names; separate table, same CID key |
| Customer.CustomerLatinName_Ver2 | CID | Legacy | Earlier version without Address/City/MiddleName columns |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard dependencies.

### 6.1 Objects This Depends On

No dependencies (no FK constraints).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetCustomerLatinName | Stored Procedure | MERGE upsert writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerLatinName | CLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerLatinName | PRIMARY KEY | CID must be unique - one Latin name record per customer |
| DF_CustomerLatinName_ModifiedDate | DEFAULT | ModifiedDate = getdate() (overridden by procedure with GetUTCDate()) |

---

## 8. Sample Queries

### 8.1 Get Latin name for a customer

```sql
SELECT
    CID,
    FirstName,
    LastName,
    MiddleName,
    Address,
    City,
    ModifiedDate
FROM Customer.CustomerLatinName WITH (NOLOCK)
WHERE CID = 10669626
```

### 8.2 Find customers with full address on file

```sql
SELECT
    CID,
    FirstName,
    LastName,
    Address,
    City
FROM Customer.CustomerLatinName WITH (NOLOCK)
WHERE Address IS NOT NULL
  AND City IS NOT NULL
ORDER BY ModifiedDate DESC
```

### 8.3 Count customers with Latin names by completeness

```sql
SELECT
    CASE
        WHEN Address IS NOT NULL THEN 'Name + Address'
        WHEN MiddleName IS NOT NULL AND MiddleName <> '' THEN 'Name + Middle'
        ELSE 'Name Only'
    END AS Completeness,
    COUNT(*) AS CustCount
FROM Customer.CustomerLatinName WITH (NOLOCK)
GROUP BY
    CASE
        WHEN Address IS NOT NULL THEN 'Name + Address'
        WHEN MiddleName IS NOT NULL AND MiddleName <> '' THEN 'Name + Middle'
        ELSE 'Name Only'
    END
ORDER BY CustCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PII data mapping for DL](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11908645178) | Confluence (BDP) | CustomerLatinName flagged as PII table in Data Lake platform; subject to GDPR masking in DL pipelines |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerLatinName | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CustomerLatinName.sql*
