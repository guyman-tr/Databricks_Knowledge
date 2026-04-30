# Trade.InstrumentTypesAndCountriesForCFDFee

> Returns two result sets used to determine CFD fee applicability: the instrument types subject to CFD fees (from feature config), and the countries with their fee type classifications (overnight vs end-of-week).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A - no parameters, dual result set output |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InstrumentTypesAndCountriesForCFDFee is a configuration-reader procedure that assembles the two dimensions needed to evaluate whether a CFD fee applies to a given position: the instrument type and the customer's country. It is a thin aggregation facade - it does no filtering or joining itself, but returns the complete reference tables that fee calculation services need to perform their own evaluation.

Result Set 1 delivers the list of InstrumentTypeIDs subject to CFD fees, sourced from Trade.GetInstrumentTypeIDsForCFDFee (which reads FeatureID=115 in Maintenance.Feature). This means the list is runtime-configurable - operations can add or remove asset classes from CFD fee eligibility without a code deployment.

Result Set 2 delivers the per-country fee type mapping from the Settings database synonym SYN_Settings_DictionaryCountryFeeType, filtered to rows where IsInclude = 1 (countries currently subject to CFD fees). The FeeTypeID column distinguishes overnight fees (1) from end-of-week fees (2), enabling fee calculation services to apply the correct fee schedule per country.

Data flow: Fee calculation services (application layer) call this procedure once at startup or on refresh to load the CFD fee configuration into memory. They then apply the two result sets to each position's (InstrumentTypeID, CountryID) pair to determine fee eligibility and the correct fee schedule.

---

## 2. Business Logic

### 2.1 Result Set 1 - Instrument Types Subject to CFD Fees

**What**: Delegates to Trade.GetInstrumentTypeIDsForCFDFee() to return the configured set of instrument types.

**Columns/Parameters Involved**: (none - no input parameters)

**Rules**:
- Calls `[Trade].[GetInstrumentTypeIDsForCFDFee]()` with no arguments.
- Returns all rows from the function: a single-column table of InstrumentTypeID (INT).
- The underlying function reads Maintenance.Feature FeatureID=115, parses the comma-separated Value string, and returns each InstrumentTypeID as a row.
- No filtering applied here - the full configured set is returned.

**Result Set 1 Columns**:
- `InstrumentTypeID` (INT) - ID of an instrument type subject to CFD fees. FK to Dictionary.InstrumentType.

### 2.2 Result Set 2 - Country CFD Fee Type Mapping

**What**: Returns countries that are included in CFD fee applicability, with their fee type (overnight vs end-of-week).

**Columns/Parameters Involved**: `SYN_Settings_DictionaryCountryFeeType.IsInclude`, `SYN_Settings_DictionaryCountryFeeType.CountryID`, `SYN_Settings_DictionaryCountryFeeType.FeeTypeID`

**Rules**:
- Source: `[dbo].[SYN_Settings_DictionaryCountryFeeType]` - a synonym pointing to the Settings database DictionaryCountryFeeType table.
- Filter: `WHERE IsInclude = 1` - only countries currently included in CFD fee applicability are returned. Rows with IsInclude = 0 are excluded (countries not subject to CFD fees).
- FeeTypeID values (from inline comment in DDL):
  - 1 = OverNightFee - standard overnight CFD holding fee
  - 2 = EndOfWeekFee - fee charged at end of week (used in some regulatory jurisdictions)

**Result Set 2 Columns**:
- `CountryID` (INT) - Country identifier. FK to Dictionary.Country.
- `FeeTypeID` (INT) - Fee schedule type: 1=OverNightFee, 2=EndOfWeekFee.

**Diagram**:
```
Trade.InstrumentTypesAndCountriesForCFDFee()
    |
    +-- Result Set 1:
    |   SELECT InstrumentTypeID
    |   FROM Trade.GetInstrumentTypeIDsForCFDFee()
    |       -> reads Maintenance.Feature (FeatureID=115)
    |       -> parses CSV -> returns instrument type IDs
    |
    +-- Result Set 2:
        SELECT CountryID, FeeTypeID
        FROM dbo.SYN_Settings_DictionaryCountryFeeType
        WHERE IsInclude = 1
            -> FeeTypeID=1: OverNightFee
            -> FeeTypeID=2: EndOfWeekFee
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| RS1.1 | InstrumentTypeID | int | NO | - | CODE-BACKED | Output (Result Set 1). Instrument type subject to CFD fees. Sourced from Maintenance.Feature FeatureID=115. FK to Dictionary.InstrumentType. |
| RS2.1 | CountryID | int | NO | - | CODE-BACKED | Output (Result Set 2). Country subject to CFD fees. FK to Dictionary.Country. |
| RS2.2 | FeeTypeID | int | NO | - | CODE-BACKED | Output (Result Set 2). CFD fee schedule type for this country. 1=OverNightFee (standard daily holding fee), 2=EndOfWeekFee (weekly fee applied in some jurisdictions). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (RS1) | Trade.GetInstrumentTypeIDsForCFDFee | Callee (Function) | Returns instrument types subject to CFD fees from feature config |
| SELECT (RS2) | dbo.SYN_Settings_DictionaryCountryFeeType | Reader (Synonym) | Reads country-to-fee-type mapping from Settings database |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by fee calculation services in the application layer to load CFD fee configuration.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentTypesAndCountriesForCFDFee (procedure)
├── Trade.GetInstrumentTypeIDsForCFDFee (function) - returns CFD fee instrument types
│   └── Maintenance.Feature (table) - FeatureID=115, CSV of InstrumentTypeIDs
└── dbo.SYN_Settings_DictionaryCountryFeeType (synonym) - country fee type mapping
    └── [Settings].[dbo].[DictionaryCountryFeeType] (remote table via synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentTypeIDsForCFDFee | Function | Called to get instrument types subject to CFD fees (reads Maintenance.Feature FeatureID=115) |
| dbo.SYN_Settings_DictionaryCountryFeeType | Synonym | Source of country-to-fee-type mappings; filtered to IsInclude=1 rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CFD fee calculation services | External (Application) | Calls to load CFD fee eligibility configuration (instrument types + countries) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| No input parameters | Design | Configuration reader - all filtering is encoded in the source objects |
| IsInclude = 1 filter | Business rule | Only countries currently subject to CFD fees are returned; excluded countries (IsInclude=0/NULL) are filtered out |
| FeeTypeID values | Inline enum | 1=OverNightFee, 2=EndOfWeekFee (documented only in DDL comment) |

---

## 8. Sample Queries

### 8.1 Call the procedure and capture both result sets

```sql
-- Result Set 1: Instrument types subject to CFD fees
-- Result Set 2: Countries with fee type mapping
EXEC Trade.InstrumentTypesAndCountriesForCFDFee;
```

### 8.2 Preview instrument types subject to CFD fees

```sql
SELECT InstrumentTypeID
FROM Trade.GetInstrumentTypeIDsForCFDFee();
-- Cross-reference with Dictionary.InstrumentType for names
```

### 8.3 Preview country fee type mappings

```sql
SELECT c.CountryID, c.FeeTypeID,
    CASE c.FeeTypeID WHEN 1 THEN 'OverNightFee' WHEN 2 THEN 'EndOfWeekFee' ELSE 'Unknown' END AS FeeTypeName
FROM dbo.SYN_Settings_DictionaryCountryFeeType c
WHERE c.IsInclude = 1
ORDER BY c.CountryID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentTypesAndCountriesForCFDFee | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InstrumentTypesAndCountriesForCFDFee.sql*
