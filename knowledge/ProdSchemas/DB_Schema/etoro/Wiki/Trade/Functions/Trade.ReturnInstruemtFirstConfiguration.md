# Trade.ReturnInstruemtFirstConfiguration

> Scalar function that reconstructs the original EXEC Trade.InsertInstrumentRealTable command from the XML parameters stored when an instrument was first created, enabling replay of instrument creation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(8000) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReturnInstruemtFirstConfiguration retrieves the original configuration parameters used when a financial instrument was first inserted into the system. It reads the XML-serialized parameter snapshot from History.InstrumentInsertParameters (taking the most recent entry by InsertDate), parses each XML element, and reconstructs a ready-to-execute EXEC Trade.InsertInstrumentRealTable command string.

This function exists as a diagnostic and audit tool. When a DBA or operations team needs to understand how an instrument was originally configured - or needs to recreate it in another environment - this function provides the exact command that was (or would have been) used. It covers all instrument properties: identifiers, pricing configuration, currency IDs, exchange settings, fee structures (leveraged/non-leveraged, buy/sell, overnight/end-of-week), liquidity provider mappings (up to 10 providers), market range settings, and volatility thresholds.

The function reads from History.InstrumentInsertParameters (cross-schema dependency on History schema) which stores XML snapshots of all parameters at instrument creation time. It does not call any other functions or modify any data. Note: the function name contains a typo ("Instruemt" instead of "Instrument").

---

## 2. Business Logic

### 2.1 XML Parameter Extraction

**What**: Parses structured XML containing all instrument configuration parameters captured at creation time.

**Columns/Parameters Involved**: `@Instrument_ID1`, `ParametersValues` (XML column from History.InstrumentInsertParameters)

**Rules**:
- Retrieves TOP 1 row from History.InstrumentInsertParameters ordered by InsertDate DESC (most recent snapshot)
- Each parameter is extracted using XQuery: `@Params.value('(Root/{ParamName}/@Value)[1]', '{type}')`
- XML structure follows pattern: `<Root><Name Value="..."/><ISINCode Value="..."/>...</Root>`
- Covers approximately 60+ parameters including: Name, ISINCode, UnitMargin, currency IDs, exchange settings, fee rates, liquidity provider configurations (10 slots), market range settings, volatility parameters

### 2.2 Command String Assembly

**What**: Concatenates all extracted parameters into an executable EXEC statement.

**Columns/Parameters Involved**: All extracted XML parameters, `@cmd`, `@cmd1`

**Rules**:
- Output format: `EXEC Trade.InsertInstrumentRealTable @Name='value', @ISINCode='value', ...`
- NULL values are rendered as the string 'null' (not SQL NULL)
- String parameters are quoted with single quotes
- Numeric parameters are unquoted
- Command is split across two VARCHAR(8000) variables (@cmd, @cmd1) to handle the length
- Final return: @cmd + @cmd1 (concatenated)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Instrument_ID1 | INT | NO | - | CODE-BACKED | The InstrumentID to look up in History.InstrumentInsertParameters. Retrieves the most recent XML parameter snapshot for this instrument. |
| 2 | Return value | VARCHAR(8000) | YES | - | CODE-BACKED | A complete EXEC Trade.InsertInstrumentRealTable command string with all original creation parameters. Can be executed directly to recreate the instrument. NULL if no history record exists. Due to VARCHAR(8000) limit across two variables, total output can be up to 16000 characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Instrument_ID1 | History.InstrumentInsertParameters | SELECT (WHERE) | Reads the XML parameter snapshot for the given instrument, ordered by InsertDate DESC TOP 1 |

### 5.2 Referenced By (other objects point to this)

No consumers found in the codebase. This is a diagnostic/ad-hoc utility function.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReturnInstruemtFirstConfiguration (function)
  +-- History.InstrumentInsertParameters (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.InstrumentInsertParameters | Table | SELECT TOP 1 ParametersValues WHERE InstrumentID = @Instrument_ID1 ORDER BY InsertDate DESC |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get original configuration for a specific instrument
```sql
SELECT Trade.ReturnInstruemtFirstConfiguration(1001) AS OriginalCreateCommand
```

### 8.2 Get configurations for all instruments in a range
```sql
SELECT I.InstrumentID,
       I.DisplayName,
       Trade.ReturnInstruemtFirstConfiguration(I.InstrumentID) AS OriginalConfig
FROM   Trade.Instrument I WITH (NOLOCK)
WHERE  I.InstrumentID BETWEEN 1000 AND 1010
```

### 8.3 Find instruments where configuration was captured
```sql
SELECT DISTINCT InstrumentID
FROM   History.InstrumentInsertParameters WITH (NOLOCK)
ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReturnInstruemtFirstConfiguration | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ReturnInstruemtFirstConfiguration.sql*
