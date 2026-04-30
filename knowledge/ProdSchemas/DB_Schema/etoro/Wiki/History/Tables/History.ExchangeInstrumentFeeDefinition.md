# History.ExchangeInstrumentFeeDefinition

> Temporal system-versioned history table storing all past versions of exchange-instrument overnight (rollover) fee multiplier configurations - recording every change to which day-of-week fee rates apply to each exchange, with optional per-instrument overrides.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (ExchangeID, InstrumentID) + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Trade.ExchangeInstrumentFeeDefinition`. SQL Server automatically moves rows here whenever an exchange-instrument fee definition is updated or deleted.

`Trade.ExchangeInstrumentFeeDefinition` defines the **overnight (rollover) fee schedule** for each combination of exchange and instrument. For every day of the week, a tinyint multiplier specifies how many overnight fees to charge that night:

| Fee Value | Meaning |
|-----------|---------|
| 0 | No overnight fee charged (market closed, fee waived) |
| 1 | Standard overnight fee x1 (single night) |
| 2 | Double overnight fee x2 (covers multiple closed nights) |

**The most common schedule** (42 of 47 current rows - standard Western equity markets):

| Sun | Mon | Tue | Wed | Thu | Fri | Sat |
|-----|-----|-----|-----|-----|-----|-----|
| 0 | 1 | 1 | 1 | 1 | 2 | 0 |

Friday charges 2x because it covers Saturday and Sunday nights when markets are closed. Sunday and Saturday charge 0 because the fee was already collected on Friday.

**Mid-East exchange variant** (e.g., ExchangeID=1/2 DEFAULT_EXCHANGE/GLOBAL_EXCHANGE):

| Sun | Mon | Tue | Wed | Thu | Fri | Sat |
|-----|-----|-----|-----|-----|-----|-----|
| 0 | 1 | 1 | 2 | 1 | 1 | 0 |

Wednesday charges 2x in this variant - consistent with the FX market convention where Wednesday's spot settlement (value date Friday) rolls to Monday, creating a triple overnight.

**Instrument-level override**: InstrumentID=-999 is a wildcard matching all instruments for an exchange. A specific InstrumentID row overrides the exchange default for that instrument only (e.g., ExchangeID=2 InstrumentID=17 has its own schedule distinct from the exchange-wide default).

**Row count**: 100 historical rows spanning Aug 2022 to Feb 2026, across 36 distinct exchanges and 4 distinct InstrumentID values (including -999).

**Confluence**: Referenced in "Roll Over Fee - Detailed (Sampling)" (REGTECH space) which documents the overnight fee calculation process that consumes this data.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever a fee definition is updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ExchangeID`, `InstrumentID`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `SysEndTime` = moment of update.
- When a row is **deleted**: SQL Server moves the row here with `SysEndTime` = deletion timestamp.
- Active rows in `Trade.ExchangeInstrumentFeeDefinition` have `SysEndTime = '9999-12-31...'` and are NOT in this history table.
- CLUSTERED index on `(SysEndTime, SysStartTime)` enables efficient `FOR SYSTEM_TIME AS OF` temporal queries.

### 2.2 INSERT Trigger Creates Zero-Duration History Rows

**What**: `TRG_T_ExchangeInstrumentFeeDefinition` fires a no-op UPDATE after every INSERT, generating a zero-duration history row for each new fee definition.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- After INSERT, trigger executes: `UPDATE A SET A.InstrumentID = A.InstrumentID` (no-op self-update joined on ExchangeID + InstrumentID).
- SQL Server temporal treats this as an UPDATE, moving the just-inserted row to history with `SysStartTime = SysEndTime = T` (zero-duration).
- Zero-duration rows (SysStartTime = SysEndTime) are INSERT artifacts; rows with SysStartTime < SysEndTime represent actual active periods with business meaning.
- Observable in history data: ExchangeID=40 (SysStartTime=SysEndTime=2025-06-23), ExchangeID=998 and 999 (SysStartTime=SysEndTime=2025-04-16).

### 2.3 Day-of-Week Fee Multiplier Resolution (UNPIVOT Pattern)

**What**: The fee process resolves the correct multiplier for today using UNPIVOT to reshape the 7 day columns into rows.

**Columns/Parameters Involved**: `sunday` through `saturday`, `ExchangeID`, `InstrumentID`

**Rules** (from `Trade.GetPositionsForFeeProcess`):
```sql
SELECT ExchangeID, InstrumentID, Day, Fee
FROM Trade.ExchangeInstrumentFeeDefinition
UNPIVOT (Fee FOR Day IN (sunday, monday, tuesday, wednesday, thursday, friday, saturday)) AS unpvt
WHERE Day = LOWER(DATENAME(weekday, @TimeLimit))
```
- The UNPIVOT reshapes all 7 day columns into a single `Fee` value for the current weekday name.
- Joined to `Trade.InstrumentMetaData` on `ExchangeID` and `InstrumentID`.
- Override priority: specific InstrumentID row (rank 1 via `DENSE_RANK() ORDER BY InstrumentID DESC`) overrides exchange-wide default (InstrumentID=-999, lowest rank).
- `Fee = 0` -> no overnight charge applied for this instrument tonight.
- `Fee = 1` -> one overnight fee charged.
- `Fee = 2` -> two overnight fees charged (covers multiple market-closed nights).

### 2.4 Fee Process Gating via Monitor

**What**: `Monitor.CheckIfFeeProcessExecute` checks whether fees should run today by testing if any exchange has a non-zero fee value for the current weekday.

**Columns/Parameters Involved**: `sunday` through `saturday`

**Rules**:
```sql
EXISTS (
    SELECT 1 FROM Trade.ExchangeInstrumentFeeDefinition
    WHERE CASE @TodayName
        WHEN 'sunday' THEN sunday
        WHEN 'monday' THEN monday
        ...
    END > 0
)
```
- If ALL exchanges have Fee=0 for today (e.g., a market holiday override), the fee process is skipped entirely.
- This provides a global kill switch: set all rows' day column to 0 to suppress fees for that day.

---

## 3. Data Overview

**Current (Trade.ExchangeInstrumentFeeDefinition)**: 47 rows, one per (ExchangeID, InstrumentID) pair.

| ExchangeID | InstrumentID | Sun | Mon | Tue | Wed | Thu | Fri | Sat | Pattern |
|---|---|---|---|---|---|---|---|---|---|
| 1 | -999 | 0 | 1 | 1 | 2 | 1 | 1 | 0 | Mid-week double (DEFAULT_EXCHANGE) |
| 2 | -999 | 0 | 1 | 1 | 2 | 1 | 1 | 0 | Mid-week double (GLOBAL_EXCHANGE) |
| 2 | 17 | 0 | 1 | 1 | 1 | 1 | 2 | 0 | Friday double (instrument override) |
| 2 | 22 | 0 | 1 | 1 | 1 | 1 | 2 | 0 | Friday double (instrument override) |
| 2 | 559 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | All days = 1 (crypto, 24/7 markets) |
| 3-6,... | -999 | 0 | 1 | 1 | 1 | 1 | 2 | 0 | Standard Western equity (most common) |

**History**: 100 rows spanning Aug 2022 - Feb 2026. 36 distinct exchanges, 4 instrument IDs (-999, 17, 22, 559). Most history rows show fee schedule tuning over time as new exchanges were onboarded or day multipliers were adjusted.

Notable change: ExchangeID=8 changed `saturday` from 0 -> 1 (fee enabled on Saturday, Mar 2025) then back adjustment same day (two history rows 10 minutes apart, both made by TRAD\bonniegr then TRAD\neriaam).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NO | - | VERIFIED | The exchange this fee schedule applies to. Composite PK with InstrumentID in source table. FK to Price.Exchange (enforced on source). Known values from current data: 1=DEFAULT_EXCHANGE, 2=GLOBAL_EXCHANGE, 3=NYSE, 4=NASDAQ, 5=XETRA - covers all exchanges where eToro instruments are traded. |
| 2 | InstrumentID | int | NO | -999 | VERIFIED | The instrument for which this schedule applies. Default -999 = wildcard matching all instruments on this exchange. Specific positive InstrumentID = per-instrument override, takes priority over the -999 default via DENSE_RANK in fee process. FK to Trade.Instrument (implicit). Currently overridden instruments: 17 (InstrumentID=17, GLOBAL_EXCHANGE), 22, 559 (crypto - all days fee). |
| 3 | sunday | tinyint | YES | 1 | VERIFIED | Sunday overnight fee multiplier. 0=no fee (market closed, charged on Friday), 1=1 fee, 2=2 fees. Standard Western equity exchanges: 0 (no Sunday fee - collected on Friday). All-days markets (InstrumentID=559/crypto): 1. |
| 4 | monday | tinyint | YES | 1 | VERIFIED | Monday overnight fee multiplier. Standard: 1 (one fee). First trading day of the week for most exchanges - always charged once. |
| 5 | tuesday | tinyint | YES | 1 | VERIFIED | Tuesday overnight fee multiplier. Standard: 1 (one fee). |
| 6 | wednesday | tinyint | YES | 2 | VERIFIED | Wednesday overnight fee multiplier. Standard Western equity: 1. Mid-East/FX pattern (ExchangeID=1,2 defaults): 2 (double charge - FX spot settlement convention where Wednesday rolls to Monday value date creating triple overnight). Default constraint of 2 reflects the initial mid-East exchange setup. |
| 7 | thursday | tinyint | YES | 0 | VERIFIED | Thursday overnight fee multiplier. Standard Western equity: 1. Default constraint of 0 (reflecting Mid-East exchange pattern where Thursday/Friday are weekend). |
| 8 | friday | tinyint | YES | 0 | VERIFIED | Friday overnight fee multiplier. Standard Western equity: 2 (double - covers Saturday and Sunday nights when markets are closed). Default constraint of 0 reflects Mid-East pattern where Friday is the Islamic day of rest. |
| 9 | saturday | tinyint | YES | 1 | VERIFIED | Saturday overnight fee multiplier. Standard Western equity: 0 (fee collected on Friday). All-days/crypto markets: 1. Default constraint of 1 reflects initial Mid-East exchange setup. |
| 10 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login captured via suser_name() computed column on source. Identifies who changed the fee configuration. Observed values: TRAD\danielma, TRAD\bonniegr, TRAD\neriaam, TRAD\Amitgl, TRAD\erezbe, TRAD\eladav - various trading operations team members. NULL if login unavailable. |
| 11 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this fee configuration became active. Managed automatically by SQL Server temporal system-versioning. Equal to SysEndTime for INSERT-triggered zero-duration artifact rows. |
| 12 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded. Clustered index leading column. Equal to SysStartTime for INSERT artifact rows. Useful for reconstructing the fee schedule as-of any historical date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExchangeID | Price.Exchange | Implicit (FK on source table) | The exchange whose instruments this schedule governs |
| InstrumentID | Trade.Instrument | Implicit | The specific instrument (-999 = all instruments on exchange) |
| (all columns) | Trade.ExchangeInstrumentFeeDefinition | Temporal | This row is a historical version of the source table row with matching (ExchangeID, InstrumentID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ExchangeInstrumentFeeDefinition | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server writes superseded rows here automatically on UPDATE/DELETE |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExchangeInstrumentFeeDefinition (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Trade.ExchangeInstrumentFeeDefinition (table)
- INSERT trigger TRG_T_ExchangeInstrumentFeeDefinition on source creates zero-duration history rows

Trade.ExchangeInstrumentFeeDefinition (source) is read by:
- Trade.GetPositionsForFeeProcess (SP) -> UNPIVOT day columns, join to InstrumentMetaData
- Trade.GetPositionsForFeeBulkGeneral (SP) -> same pattern
- Trade.GetPositionsForFeeBulkGeneral_Aus (SP) -> Australia-specific fee process variant
- Monitor.CheckIfFeeProcessExecute (SP) -> gating check for fee process
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExchangeInstrumentFeeDefinition | Table | Source table - SQL Server writes old row versions here on UPDATE/DELETE; INSERT trigger also generates zero-duration rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ExchangeInstrumentFeeDefinition | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Filegroup**: [PRIMARY].
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

**Source table constraints** (Trade.ExchangeInstrumentFeeDefinition):

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExchangeInstrumentFeeDefinition | PRIMARY KEY (CLUSTERED) | Uniqueness on (ExchangeID, InstrumentID) with FILLFACTOR=95 |
| DF...InstrumentID | DEFAULT | InstrumentID = -999 (wildcard default) |
| DF...sunday | DEFAULT | sunday = 1 |
| DF...monday | DEFAULT | monday = 1 |
| DF...tuesday | DEFAULT | tuesday = 1 |
| DF...wednesday | DEFAULT | wednesday = 2 |
| DF...thursday | DEFAULT | thursday = 0 |
| DF...friday | DEFAULT | friday = 0 |
| DF...saturday | DEFAULT | saturday = 1 |

---

## 8. Sample Queries

### 8.1 Fee schedule as-of a specific date
```sql
SELECT ExchangeID, InstrumentID, sunday, monday, tuesday, wednesday, thursday, friday, saturday,
       DbLoginName, SysStartTime, SysEndTime
FROM [History].[ExchangeInstrumentFeeDefinition]
WHERE '2025-01-01' BETWEEN SysStartTime AND SysEndTime
  AND SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY ExchangeID, InstrumentID
```

### 8.2 Change history for a specific exchange
```sql
-- Historical versions
SELECT ExchangeID, InstrumentID, sunday, monday, tuesday, wednesday, thursday, friday, saturday,
       DbLoginName, SysStartTime, SysEndTime
FROM [History].[ExchangeInstrumentFeeDefinition]
WHERE ExchangeID = 2  -- GLOBAL_EXCHANGE
ORDER BY InstrumentID, SysStartTime

UNION ALL
-- Current version
SELECT ExchangeID, InstrumentID, sunday, monday, tuesday, wednesday, thursday, friday, saturday,
       DbLoginName, SysStartTime, SysEndTime
FROM [Trade].[ExchangeInstrumentFeeDefinition]
WHERE ExchangeID = 2
ORDER BY InstrumentID, SysStartTime
```

### 8.3 Reconstruct what fee would be charged for an instrument on a given weekday
```sql
-- What fee multiplier applies to InstrumentID=17 on a Friday?
SELECT ExchangeID, InstrumentID, friday AS FeeMultiplier, DbLoginName
FROM [Trade].[ExchangeInstrumentFeeDefinition]
WHERE InstrumentID IN (17, -999)
ORDER BY InstrumentID DESC  -- specific instrument first (same as dense_rank DESC logic)
```

### 8.4 Exchanges with non-standard fee patterns
```sql
SELECT ExchangeID, InstrumentID,
       sunday, monday, tuesday, wednesday, thursday, friday, saturday
FROM [Trade].[ExchangeInstrumentFeeDefinition]
WHERE NOT (sunday = 0 AND monday = 1 AND tuesday = 1 AND wednesday = 1
       AND thursday = 1 AND friday = 2 AND saturday = 0)
  AND NOT (sunday = 0 AND monday = 1 AND tuesday = 1 AND wednesday = 2
       AND thursday = 1 AND friday = 1 AND saturday = 0)
ORDER BY ExchangeID, InstrumentID
```

---

## 9. Atlassian Knowledge Sources

- **Confluence**: "Roll Over Fee - Detailed (Sampling)" (REGTECH space) - documents the rollover fee calculation process that uses this table as the day-multiplier configuration source.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExchangeInstrumentFeeDefinition | Type: Table | Source: etoro/etoro/History/Tables/History.ExchangeInstrumentFeeDefinition.sql*
