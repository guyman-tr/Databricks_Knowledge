# Trade.CusipConfigTbl

> A table-valued parameter type for batch-updating security identifier configurations for instruments. Maps InstrumentID to CUSIP (US standard), ISIN (global standard), ISIN country code, and SEDOL (UK/Ireland), used by clearing brokers like Apex.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (PRIMARY KEY) |
| **Partition** | N/A |
| **Indexes** | 1 (PRIMARY KEY CLUSTERED on InstrumentID) |

---

## 1. Business Meaning

Trade.CusipConfigTbl is a TVP for batch-updating security identifier configurations. Financial instruments are identified by multiple standards: CUSIP (US, 9 characters), ISIN (global, 12 characters), ISIN country code (2-letter), and SEDOL (UK/Ireland). Clearing brokers such as Apex require these identifiers for settlement, reporting, and regulatory filing.

Without this type, each instrument's identifier set would require a separate update. Batch semantics let operations load or correct many instrument mappings in one call - for example when onboarding new symbols, reconciling with a broker feed, or bulk-updating after an identifier change.

The consuming procedure Trade.UpdateCusip receives a populated instance. The PRIMARY KEY on InstrumentID ensures one row per instrument; IGNORE_DUP_KEY = OFF means duplicate InstrumentIDs will raise an error. All identifier columns except InstrumentID are nullable - an instrument may have only some identifiers populated.

---

## 2. Business Logic

### 2.1 One Mapping Per Instrument

**What**: The clustered primary key on InstrumentID enforces exactly one configuration row per instrument in the TVP.

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- InstrumentID is the primary key. Duplicate InstrumentIDs in the TVP will cause a key violation (IGNORE_DUP_KEY = OFF).
- Callers must ensure one row per instrument. The procedure uses MERGE or similar to update the target table.

**Diagram**:
```
InstrumentID (PK) -> One row -> CUSIP, ISIN, ISINCountryCode, SEDOL (any can be NULL)
```

### 2.2 Identifier Standards

**What**: CUSIP, ISIN, and SEDOL are distinct standards used in different jurisdictions.

**Columns/Parameters Involved**: `CUSIP`, `ISINCode`, `ISINCountryCode`, `SEDOL`

**Rules**:
- CUSIP: US standard, typically 9 characters. Required by US clearing.
- ISIN: Global standard, 12 characters. Prefixed by 2-letter country code.
- ISINCountryCode: The country portion of ISIN (first 2 chars) or a separate 2-letter code.
- SEDOL: UK/Ireland, 7 characters. Used for LSE and Irish listings.
- All can be NULL - an instrument might only have CUSIP, or only ISIN, etc.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument ID - the eToro internal identifier. Primary key - one configuration row per instrument. |
| 2 | CUSIP | varchar(500) | YES | - | CODE-BACKED | CUSIP (Committee on Uniform Securities Identification Procedures) - the US standard 9-character identifier. Used by clearing brokers like Apex for US securities. |
| 3 | ISINCode | varchar(500) | YES | - | CODE-BACKED | ISIN (International Securities Identification Number) - the global 12-character standard. Used for cross-border settlement and reporting. |
| 4 | ISINCountryCode | varchar(15) | YES | - | CODE-BACKED | Two-letter country code associated with the ISIN or the instrument's domicile. Part of the ISIN structure or standalone. |
| 5 | SEDOL | varchar(50) | YES | - | CODE-BACKED | SEDOL (Stock Exchange Daily Official List) - UK/Ireland 7-character identifier. Used for LSE and Irish listings. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no declared outgoing references. InstrumentID semantically references the instrument catalog; identifier columns are external standard codes, not FKs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateCusip | @Table parameter | Parameter (TVP) | Receives batch of instrument-to-identifier mappings for update |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateCusip | Stored Procedure | READONLY parameter - batch update security identifier configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (implied) | CLUSTERED | InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | UNIQUE | InstrumentID - enforces one row per instrument. IGNORE_DUP_KEY = OFF. |

---

## 8. Sample Queries

### 8.1 Declare and populate for batch CUSIP/ISIN update

```sql
DECLARE @Config Trade.CusipConfigTbl;
INSERT INTO @Config (InstrumentID, CUSIP, ISINCode, ISINCountryCode, SEDOL)
VALUES (100, '037833100', 'US0378331005', 'US', NULL),
       (101, '594918104', 'US5949181045', 'US', NULL),
       (200, NULL, 'IE00B4L5Y983', 'IE', 'B3YHQD3');
EXEC Trade.UpdateCusip @Config = @Config;
```

### 8.2 Build TVP from external feed

```sql
DECLARE @Config Trade.CusipConfigTbl;
INSERT INTO @Config (InstrumentID, CUSIP, ISINCode, ISINCountryCode, SEDOL)
SELECT  i.InstrumentID, f.CUSIP, f.ISIN, f.ISINCountry, f.SEDOL
FROM    Trade.InstrumentTbl i WITH (NOLOCK)
JOIN    ExternalFeed.CusipMapping f ON i.Symbol = f.Symbol
WHERE   f.UpdatedDate > @Since;
EXEC Trade.UpdateCusip @Config = @Config;
```

### 8.3 Update only CUSIP for US instruments

```sql
DECLARE @Config Trade.CusipConfigTbl;
INSERT INTO @Config (InstrumentID, CUSIP, ISINCode, ISINCountryCode, SEDOL)
SELECT  InstrumentID, @NewCusip, NULL, NULL, NULL
FROM    Trade.InstrumentTbl WITH (NOLOCK)
WHERE   InstrumentTypeID = 1 AND ExchangeID = 5;
EXEC Trade.UpdateCusip @Config = @Config;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CusipConfigTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CusipConfigTbl.sql*
