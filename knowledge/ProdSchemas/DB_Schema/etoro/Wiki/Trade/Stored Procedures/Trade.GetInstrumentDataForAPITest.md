# Trade.GetInstrumentDataForAPITest

> Test variant of Trade.GetInstrumentDataForAPI - identical structure with additional exclusion filter for problematic instruments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (key in all result sets) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a test/development variant of Trade.GetInstrumentDataForAPI. It returns the same three result sets (leverages, full instrument configuration, instrument groups) with nearly identical logic. The key difference is an additional exclusion filter in result set 2 that removes instruments listed in a `wrongInstruments04102025` table - likely a temporary table for testing instrument data cleanup from October 4, 2025.

The test variant also omits the `Slippage`, `ExtendedMarginAllowed`, and `AllowedRateDiffPercentageUpside` columns that exist in the production version, and does not include the backward-compatibility zero-fee columns.

Data flow: identical to Trade.GetInstrumentDataForAPI except for the `NOT IN (SELECT InstrumentID FROM wrongInstruments04102025)` filter. See [Trade.GetInstrumentDataForAPI](Trade.GetInstrumentDataForAPI.md) for full documentation.

---

## 2. Business Logic

### 2.1 Problematic Instrument Exclusion

**What**: Excludes instruments from a cleanup/exclusion list.

**Columns/Parameters Involved**: `wrongInstruments04102025`

**Rules**:
- Additional WHERE clause: `imd.InstrumentID NOT IN (SELECT InstrumentID FROM wrongInstruments04102025)`
- This table appears to be a temporary/test artifact from October 2025 data cleanup

### 2.2 All Other Logic

Same as production. See [Trade.GetInstrumentDataForAPI](Trade.GetInstrumentDataForAPI.md) for visibility filter, SDRT eligibility, US allowed check.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @getOnlyVisibleOrEnabledInstruments | BIT | NO | 1 | CODE-BACKED | Filter flag: 1=only visible/enabled, 0=all. Same as production. |

Result sets match production variant (see [Trade.GetInstrumentDataForAPI](Trade.GetInstrumentDataForAPI.md)) with these differences:
- Result set 2 excludes `Slippage`, `ExtendedMarginAllowed`, `AllowedRateDiffPercentageUpside` columns
- Result set 2 excludes backward-compatibility zero-fee columns
- Result set 2 adds `NOT IN wrongInstruments04102025` filter
- Result set 2 includes `Multiplier` from FuturesMetaData

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as Trade.GetInstrumentDataForAPI plus:

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | wrongInstruments04102025 | NOT IN (subquery) | Exclusion list for test cleanup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentDataForAPITest (procedure)
+-- Trade.ProviderToInstrument (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.GetInstrument (view)
+-- Dictionary.CurrencyType (table)
+-- Dictionary.InstrumentTypeSubCategory (table)
+-- Trade.FuturesMetaData (table)
+-- Trade.UsAllowedInstruments (table)
+-- Trade.ProviderInstrumentToLeverage (table)
+-- Dictionary.Leverage (table)
+-- Trade.InstrumentGroups (table)
+-- wrongInstruments04102025 (table - test artifact)
```

### 6.1 Objects This Depends On

Same as Trade.GetInstrumentDataForAPI plus wrongInstruments04102025.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute test variant

```sql
EXEC Trade.GetInstrumentDataForAPITest;
```

### 8.2 Compare with production

```sql
EXEC Trade.GetInstrumentDataForAPI;
EXEC Trade.GetInstrumentDataForAPITest;
```

### 8.3 Check exclusion list

```sql
SELECT  COUNT(*) AS ExcludedInstruments
FROM    wrongInstruments04102025 WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentDataForAPITest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentDataForAPITest.sql*
