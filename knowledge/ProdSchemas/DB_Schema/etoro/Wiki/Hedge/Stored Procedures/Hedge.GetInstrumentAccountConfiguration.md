# Hedge.GetInstrumentAccountConfiguration

> Full-table read procedure: returns all rows and all 9 columns from Hedge.AccountInstrumentConfiguration - the per-account, per-instrument execution parameter table. No parameters. Used by the hedge engine at startup to load limit order price rounding precision and execution unit throttling settings (throttling columns are all NULL in the current environment).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all 147 rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetInstrumentAccountConfiguration is the startup loader for per-account, per-instrument execution parameters. The hedge engine calls this procedure at initialization to load the full AccountInstrumentConfiguration table into memory, which it then uses during order routing to apply account- and instrument-specific execution controls.

The primary active configuration is `LimitRoundPrecision`: how many decimal places limit order prices are rounded to when submitting to a provider. This varies by account and instrument because different providers have different price precision requirements (e.g., Forex = 4-5 decimals, equities = 1-2 decimals).

The six execution unit throttling columns (`MaxExecutionUnitsThreshold`, `MaxExecutionUnitsLowerBound`, `MaxExecutionUnitsUpperBound`, `ExecutionUnitsStep`, `MaxRequestedPerInterval`, `IntervalPeriodSeconds`) are designed capabilities that are currently NULL across all 147 rows - the infrastructure is in place but no throttling has been configured.

Currently 147 rows across 3 AccountIDs (1, 10, 308) and 86 instruments.

---

## 2. Business Logic

### 2.1 Full-Table Read, No Filtering

**What**: Returns all 9 columns from AccountInstrumentConfiguration without any WHERE clause.

**Rules**:
- No NOLOCK hint (unlike many Hedge read procedures). Uses default isolation level.
- No ORDER BY. Result order is undefined.
- All 147 rows returned; caller filters by AccountID as needed.
- The 9 returned columns match all data columns of AccountInstrumentConfiguration (the composite PK columns AccountID and InstrumentID are included in the SELECT).

### 2.2 Active Column: LimitRoundPrecision

**What**: Specifies decimal precision for limit order prices per account/instrument.

**Rules**:
- DEFAULT -1 = no rounding override (use provider/instrument default).
- Active values: 1, 2, or 4 decimal places, depending on provider precision requirements.
- Applied when the hedge engine constructs a limit order price before submission.

### 2.3 Designed-but-Inactive: Execution Unit Throttling

**What**: Six columns for rate limiting and order sizing constraints.

**Rules**:
- All currently NULL = no throttling active for any account/instrument pair.
- Designed intent: MaxExecutionUnitsThreshold = max single-order size before band routing; LowerBound/UpperBound = target execution band; ExecutionUnitsStep = sizing granularity; MaxRequestedPerInterval + IntervalPeriodSeconds = order rate limit.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (all 9 columns of Hedge.AccountInstrumentConfiguration):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountID | int | NO | - | CODE-BACKED | Part of composite PK. Liquidity account identifier. Currently configured for 3 accounts: 1, 10, 308. FK to Hedge.Accounts.ID. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Part of composite PK. Instrument identifier. 86 distinct instruments configured. FK to Trade.Instrument. |
| 3 | MaxExecutionUnitsThreshold | decimal | YES | - | CODE-BACKED | Maximum single-order size threshold before band-based routing. Currently NULL (not activated). |
| 4 | MaxExecutionUnitsLowerBound | decimal | YES | - | CODE-BACKED | Lower bound of the target execution band when threshold is exceeded. Currently NULL. |
| 5 | MaxExecutionUnitsUpperBound | decimal | YES | - | CODE-BACKED | Upper bound of the target execution band. Currently NULL. |
| 6 | ExecutionUnitsStep | decimal | YES | - | CODE-BACKED | Granularity step for execution unit sizing within the band. Currently NULL. |
| 7 | MaxRequestedPerInterval | int | YES | - | CODE-BACKED | Maximum number of orders allowed within the IntervalPeriodSeconds window (rate limiting). Currently NULL. |
| 8 | IntervalPeriodSeconds | int | YES | - | CODE-BACKED | Time window in seconds for the MaxRequestedPerInterval rate limit. Currently NULL. |
| 9 | LimitRoundPrecision | smallint | NO | -1 | CODE-BACKED | Decimal places for limit order price rounding. -1 = no override. Active values: 1, 2, 4. The only actively configured column in this table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Full table read | Hedge.AccountInstrumentConfiguration | Lookup / Read | All 147 rows, all 9 columns. No filter. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | Result set | Caller | Loads execution parameters at startup for limit price rounding and throttling decisions. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetInstrumentAccountConfiguration (procedure)
└── Hedge.AccountInstrumentConfiguration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountInstrumentConfiguration | Table | Full read. 147 rows, 9 columns. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Startup config load for per-account, per-instrument execution parameters. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No temp tables. No NOLOCK. No parameters. Simple single-table SELECT of all columns.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetInstrumentAccountConfiguration;
```

### 8.2 Check active LimitRoundPrecision values

```sql
SELECT AccountID, LimitRoundPrecision, COUNT(*) AS InstrumentCount
FROM   Hedge.AccountInstrumentConfiguration
GROUP BY AccountID, LimitRoundPrecision
ORDER BY AccountID, LimitRoundPrecision;
```

### 8.3 Verify all throttling columns are NULL

```sql
SELECT COUNT(*) AS TotalRows,
       SUM(CASE WHEN MaxExecutionUnitsThreshold IS NOT NULL THEN 1 ELSE 0 END) AS ThrottleConfigured
FROM   Hedge.AccountInstrumentConfiguration;
-- Expected: ThrottleConfigured = 0
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Per-account instrument execution config; limit price rounding for provider compatibility. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetInstrumentAccountConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetInstrumentAccountConfiguration.sql*
