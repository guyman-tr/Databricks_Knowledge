# Trade.CheckValidInstrumentsConstrients

> Validates data integrity for a newly inserted instrument by dynamically checking all foreign key constraints and unique index constraints across 22+ instrument-related tables, reporting violations via dbo.InsertInstrumentError.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckValidInstrumentsConstrients (note: "Constrients" is a typo for "Constraints") is a comprehensive data integrity validation procedure that runs after instrument data has been loaded into global temporary tables (##Schema_TableName). It verifies that all foreign key relationships and unique index constraints hold true before the instrument data is committed to production tables.

The procedure is part of the instrument onboarding/update pipeline. It dynamically inspects sys.foreign_key_columns and sys.indexes for a predefined list of 22+ instrument-related tables across Trade, Hedge, Price, and Dictionary schemas. For each FK, it builds and executes dynamic SQL to verify referential integrity. For each unique index, it checks for duplicates between the staged data (in ##temp tables) and existing production data. Violations are logged to dbo.InsertInstrumentError and reported to the caller via @isvalid OUTPUT and a descriptive error message result set.

---

## 2. Business Logic

### 2.1 Source Table Registry

**What**: Defines the list of 22+ tables that participate in instrument data validation.

**Tables**: Hedge.InstrumentConfiguration, Price.InstrumentConfiguration, Dictionary.Currency, Trade.Instrument, Trade.InstrumentToFeeConfig, Trade.TradonomiContracts, Trade.InstrumentImages, Trade.ActiveFeatureThreshold, Trade.InstrumentSpread, Trade.Spread, Trade.SpreadToGroup, Trade.ProviderToInstrument, Hedge.HBCAccountConfiguration, Trade.LiquidityProviderContracts, Hedge.ProviderUnitConversionRatio, Trade.InstrumentConversion, Hedge.InstrumentBoundaries, Price.InstrumentRateSources, Price.LiquidityAccountToInstrument, Trade.ProviderInstrumentToLeverage, Trade.ProviderInstrumentToLotCount, Trade.InstrumentMetaData, Price.DictionaryCurrency, Price.Instrument

### 2.2 Foreign Key Validation

**What**: Dynamically builds and executes EXCEPT queries to find FK violations between staged and production data.

**Rules**:
- For each FK constraint on the source tables: checks that every FK column value in the ##temp table either exists in the corresponding ##temp PK table OR in the production PK table
- Multi-column FKs are handled by concatenating all columns via FOR XML PATH
- Violations are logged to ##erroroutput and dbo.InsertInstrumentError

### 2.3 Unique Index Validation

**What**: Checks for duplicate values between staged data and production data on unique indexes.

**Rules**:
- For each unique index on the source tables: checks if any values in the ##temp table already exist in the production table (INTERSECT)
- Identity columns excluded (is_identity=0)
- Specific indexes excluded: PK_TSPR, PK_TS2G, PK_TradonomiContracts (auto-increment keys)
- Violations logged to ##erroroutput and dbo.InsertInstrumentError

### 2.4 Output

**What**: Returns error messages and sets @isvalid=0 on failure.

**Rules**:
- FK violations: "The Data for this Instrument is incorrect violation: {FK_Name} You Inserted to {Column} the value: {Value} TO TABLE {FKTable} that does not exist in Table: {PKTable}"
- Index violations: "The Data for this Instrument is incorrect violation: {IndexName} You Inserted to {Columns} the value: {Value} that already exists in Table: {Table}"
- RETURN -1 on failure

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument being validated. Used for error logging to dbo.InsertInstrumentError. |
| 2 | @isvalid | BIT (OUTPUT) | NO | - | CODE-BACKED | Set to 0 if any constraint violations are found. Caller checks this to determine success/failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (dynamic) | sys.tables, sys.foreign_key_columns, sys.indexes, sys.index_columns, sys.columns | SELECT | Metadata introspection for constraint discovery |
| (writes) | dbo.InsertInstrumentError | INSERT | Logs FK and index violations |
| (reads) | 22+ tables across Trade, Hedge, Price, Dictionary schemas | Dynamic EXEC | Production data for constraint validation |
| (reads) | ##Source_table, ##fkcmd, ##uniqueindex, ##erroroutput | Global temp tables | Staged instrument data from caller |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckValidInstruments | EXEC call | EXEC | Calls this procedure at the end of validation to check FK and unique index constraints across all ##temp tables |
| Trade.InsertInstrumentRealTable | (indirect via CheckValidInstruments) | EXEC | Ultimate caller in the instrument onboarding pipeline |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckValidInstrumentsConstrients (procedure)
+-- sys.tables / sys.foreign_key_columns / sys.indexes / sys.index_columns / sys.columns (system)
+-- dbo.InsertInstrumentError (table)
+-- 22+ instrument-related tables (dynamic reads)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.InsertInstrumentError | Table | INSERT violations |
| sys catalog views | System | Metadata introspection |
| 22+ instrument tables | Tables | Dynamic constraint validation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instrument onboarding pipeline | External | Validation step |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL via EXEC() | Security risk | Uses string concatenation with EXEC(), not sp_executesql - no parameterization |
| Global temp tables | Coupling | Relies on ##-prefixed temp tables created by the caller |
| WHILE loop pattern | Performance | Iterates one constraint at a time rather than set-based |
| No explicit transaction | Atomicity | Error logging is not transactional |

---

## 8. Sample Queries

### 8.1 Run constraint validation

```sql
DECLARE @isvalid BIT;
EXEC Trade.CheckValidInstrumentsConstrients @InstrumentID = 1001, @isvalid = @isvalid OUTPUT;
SELECT @isvalid AS IsValid;
```

### 8.2 Check recent instrument errors

```sql
SELECT TOP 10 *
FROM   dbo.InsertInstrumentError WITH (NOLOCK)
WHERE  InstrumentID = 1001
ORDER BY InstrumentID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckValidInstrumentsConstrients | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckValidInstrumentsConstrients.sql*
