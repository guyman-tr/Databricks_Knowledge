# Trade.ExchangeInstrumentFeeDefinition

> Exchange-level fee schedule that defines which fee type (overnight vs. weekend) applies for each day of the week per exchange and optionally per instrument, used by the CFD overnight/weekend fee process.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ExchangeID, InstrumentID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

**WHAT**: Trade.ExchangeInstrumentFeeDefinition defines the fee type (0=No fee, 1=Overnight fee, 2=Weekend fee) for each day of the week, per exchange and optionally per instrument. The columns sunday through saturday each hold a tinyint: 0 exempts the position from fees that day, 1 means overnight/daily fee applies, 2 means weekend fee applies. InstrumentID=-999 is a wildcard meaning "all instruments on this exchange"—so exchange-level defaults are defined with InstrumentID=-999, and instrument-specific overrides use the actual InstrumentID. This table drives Trade.GetPositionsForFeeProcess, Trade.GetPositionsForFeeBulkGeneral, and Monitor.CheckIfFeeProcessExecute.

**WHY**: Different exchanges have different trading calendars (e.g., US markets vs. FX). The fee process runs daily and must know: (a) on Wednesday, take weekend fee for positions held over the weekend; (b) on other weekdays, take overnight fee. The day-of-week mapping is exchange- and instrument-specific because instruments on LSE (London) have different schedules than instruments on NASDAQ. Without this table, the system could not determine which fee type to apply on a given day. Dictionary.FeeDefinition documents FeeID 0/1/2; this table's sunday..saturday values align with that (0=No, 1=Daily/Overnight, 2=Weekly/Weekend).

**HOW**: Trade.GetPositionsForFeeProcess UNPIVOTs sunday..saturday to (ExchangeID, InstrumentID, Day, Fee), then JOINs on IMD.ExchangeID = EIFD.ExchangeID, (IMD.InstrumentID = EIFD.InstrumentID OR EIFD.InstrumentID = -999), and EIFD.[Day] = LOWER(DATENAME(WEEKDAY, @TimeLimit)). Rnk = DENSE_RANK() ensures instrument-specific rows override exchange defaults when both match. The trigger TRG_T_ExchangeInstrumentFeeDefinition fires on INSERT as a no-op (UPDATE A SET A.InstrumentID = A.InstrumentID) to support temporal/audit patterns. Trade.InstrumentMetaData trigger validates ExchangeID exists here and upserts rows when ExchangeID changes. System versioning copies history to History.ExchangeInstrumentFeeDefinition.

---

## 2. Business Logic

### 2.1 Day-of-Week Fee Mapping

**What**: Each weekday column (sunday, monday, ..., saturday) holds the fee type for that day.

**Columns/Parameters Involved**: sunday, monday, tuesday, wednesday, thursday, friday, saturday

**Rules**:
- 0 = No fee (position exempt from overnight/weekend charges that day)
- 1 = Overnight/daily fee (Fee=1 in GetPositionsForFeeProcess logic)
- 2 = Weekend fee (Fee=2 in GetPositionsForFeeProcess logic)
- On Wednesday the fee process takes weekend fee; on other days overnight fee (see procedure comment)
- Defaults: sunday/monday/tuesday/saturday=1, wednesday=2, thursday/friday=0

### 2.2 Exchange and Instrument Scope

**What**: ExchangeID plus InstrumentID define the scope. InstrumentID=-999 means exchange-wide default.

**Columns/Parameters Involved**: ExchangeID, InstrumentID

**Rules**:
- ExchangeID: FK to Dictionary.ExchangeInfo (implicit). Identifies the exchange (e.g., 1=FX, 2=another, 4=Nasdaq, 5=NYSE).
- InstrumentID=-999: Wildcard for "all instruments on this exchange." Default for InstrumentID.
- InstrumentID=17, 22, 559, etc.: Specific instrument overrides for that exchange.
- Join logic: (IMD.InstrumentID = EIFD.InstrumentID OR EIFD.InstrumentID = -999). Instrument-specific rows take precedence via Rnk=1.

### 2.3 InstrumentMetaData Integration

**What**: When an instrument's ExchangeID is updated, the trigger ensures a row exists in ExchangeInstrumentFeeDefinition.

**Columns/Parameters Involved**: ExchangeID, InstrumentID

**Rules**:
- trg_update_Trade_InstrumentMetaData validates ExchangeID exists in ExchangeInstrumentFeeDefinition before allowing the update.
- UPDATE Trade.ExchangeInstrumentFeeDefinition adds/updates rows when InstrumentMetaData.ExchangeID changes.

---

## 3. Data Overview

| ExchangeID | InstrumentID | sunday | monday | tuesday | wednesday | thursday | friday | saturday | Meaning |
|------------|--------------|--------|--------|---------|-----------|----------|--------|----------|---------|
| 1 | -999 | 0 | 1 | 1 | 2 | 1 | 1 | 0 | FX exchange default: no fee Sun/Sat, overnight Mon/Tue/Thu/Fri, weekend Wed. |
| 2 | -999 | 0 | 1 | 1 | 2 | 1 | 1 | 0 | Same pattern for exchange 2 default. |
| 2 | 17 | 0 | 1 | 1 | 1 | 1 | 2 | 0 | Instrument 17 override: weekend fee on Friday instead of Wednesday. |
| 2 | 22 | 0 | 1 | 1 | 1 | 1 | 2 | 0 | Instrument 22: same override as 17. |
| 2 | 559 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | Instrument 559: fee all days (e.g., crypto or 24/5 instrument). |

**Selection criteria**: Top 5 rows from live MCP query, showing exchange defaults (InstrumentID=-999) and instrument-specific overrides.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NO | - | CODE-BACKED | FK to Dictionary.ExchangeInfo (implicit). Exchange identifier (e.g., 1=FX, 2=CFD, 4=Nasdaq, 5=NYSE). |
| 2 | InstrumentID | int | NO | -999 | CODE-BACKED | -999 = exchange-wide default; specific InstrumentID = instrument override. FK to Trade.Instrument (implicit). |
| 3 | sunday | tinyint | YES | 1 | CODE-BACKED | Fee type for Sunday: 0=None, 1=Overnight, 2=Weekend. |
| 4 | monday | tinyint | YES | 1 | CODE-BACKED | Fee type for Monday: 0=None, 1=Overnight, 2=Weekend. |
| 5 | tuesday | tinyint | YES | 1 | CODE-BACKED | Fee type for Tuesday: 0=None, 1=Overnight, 2=Weekend. |
| 6 | wednesday | tinyint | YES | 2 | CODE-BACKED | Fee type for Wednesday: 0=None, 1=Overnight, 2=Weekend. Typically 2 (weekend fee day). |
| 7 | thursday | tinyint | YES | 0 | CODE-BACKED | Fee type for Thursday: 0=None, 1=Overnight, 2=Weekend. |
| 8 | friday | tinyint | YES | 0 | CODE-BACKED | Fee type for Friday: 0=None, 1=Overnight, 2=Weekend. |
| 9 | saturday | tinyint | YES | 1 | CODE-BACKED | Fee type for Saturday: 0=None, 1=Overnight, 2=Weekend. |
| 10 | DbLoginName | computed | NO | suser_name() | CODE-BACKED | Current SQL login; audit trail. |
| 11 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start. History.ExchangeInstrumentFeeDefinition. |
| 12 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System versioning row end. Current rows have max datetime. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| ExchangeID | Dictionary.ExchangeInfo | Implicit | Exchange (FX, Nasdaq, LSE, etc.) |
| InstrumentID | Trade.Instrument | Implicit | Instrument when not -999; Trade.InstrumentMetaData joins via InstrumentID |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForFeeProcess | JOIN | Reader | UNPIVOT + join for fee type by day |
| Trade.GetPositionsForFeeBulkGeneral | JOIN | Reader | Same pattern for bulk fee processing |
| Trade.GetPositionsForFeeBulkGeneral_Aus | JOIN | Reader | Australian-specific fee bulk |
| Monitor.CheckIfFeeProcessExecute | SELECT | Reader | Checks if overnight fee (1) applies today |
| Trade.InstrumentMetaData | trigger | Writer/Validator | Validates ExchangeID, upserts rows on ExchangeID change |
| History.ExchangeInstrumentFeeDefinition | SYSTEM_VERSIONING | History | Temporal history table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExchangeInstrumentFeeDefinition (table)
├── Dictionary.ExchangeInfo (implicit via ExchangeID)
├── Trade.Instrument (implicit via InstrumentID when not -999)
└── Trade.InstrumentMetaData (trigger updates)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExchangeInfo | Table | ExchangeID lookup |
| Trade.Instrument | Table | InstrumentID when specific (not -999) |
| Trade.InstrumentMetaData | Table | Supplies ExchangeID + InstrumentID for join; trigger maintains this table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForFeeProcess | Procedure | Fee type by day for overnight/weekend charges |
| Trade.GetPositionsForFeeBulkGeneral | Procedure | Bulk fee calculation |
| Trade.GetPositionsForFeeBulkGeneral_Aus | Procedure | Australian bulk fee |
| Monitor.CheckIfFeeProcessExecute | Procedure | Determine if fee process should run today |
| Trade.InstrumentMetaData | Table/Trigger | Validates ExchangeID exists; upserts rows |
| History.ExchangeInstrumentFeeDefinition | Table | System versioning history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExchangeInstrumentFeeDefinition | CLUSTERED | ExchangeID, InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExchangeInstrumentFeeDefinition | PK | ExchangeID, InstrumentID (composite) |
| DF InstrumentID | DEFAULT | InstrumentID = -999 |
| DF sunday | DEFAULT | sunday = 1 |
| DF monday | DEFAULT | monday = 1 |
| DF tuesday | DEFAULT | tuesday = 1 |
| DF wednesday | DEFAULT | wednesday = 2 |
| DF thursday | DEFAULT | thursday = 0 |
| DF friday | DEFAULT | friday = 0 |
| DF saturday | DEFAULT | saturday = 1 |
| DF_ExchangeInstrumentFeeDefinition_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_ExchangeInstrumentFeeDefinition_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| TRG_T_ExchangeInstrumentFeeDefinition | TRIGGER | FOR INSERT—no-op UPDATE for audit/temporal support |
| SYSTEM_VERSIONING | - | History.ExchangeInstrumentFeeDefinition |

---

## 8. Sample Queries

### 8.1 Fee definition for an exchange with instrument override precedence
```sql
SELECT EIFD.ExchangeID, EIFD.InstrumentID,
       EIFD.sunday, EIFD.monday, EIFD.tuesday, EIFD.wednesday,
       EIFD.thursday, EIFD.friday, EIFD.saturday,
       EI.ExchangeDescription
  FROM Trade.ExchangeInstrumentFeeDefinition EIFD WITH (NOLOCK)
  LEFT JOIN Dictionary.ExchangeInfo EI WITH (NOLOCK) ON EIFD.ExchangeID = EI.ExchangeID
 WHERE EIFD.ExchangeID = 2
 ORDER BY EIFD.InstrumentID DESC  -- -999 (default) last
```

### 8.2 Effective fee type for today by exchange
```sql
DECLARE @Today NVARCHAR(10) = LOWER(DATENAME(WEEKDAY, GETUTCDATE()));

SELECT EIFD.ExchangeID, EIFD.InstrumentID,
       CASE @Today
         WHEN 'sunday'   THEN EIFD.sunday
         WHEN 'monday'   THEN EIFD.monday
         WHEN 'tuesday'  THEN EIFD.tuesday
         WHEN 'wednesday' THEN EIFD.wednesday
         WHEN 'thursday' THEN EIFD.thursday
         WHEN 'friday'   THEN EIFD.friday
         WHEN 'saturday' THEN EIFD.saturday
       END AS FeeTypeToday
  FROM Trade.ExchangeInstrumentFeeDefinition EIFD WITH (NOLOCK)
 WHERE EIFD.ExchangeID IN (1, 2, 4, 5)
```

### 8.3 Exchanges requiring overnight fee today (for Monitor-style check)
```sql
DECLARE @Today NVARCHAR(10) = LOWER(DATENAME(WEEKDAY, GETUTCDATE()));

SELECT DISTINCT EIFD.ExchangeID
  FROM Trade.ExchangeInstrumentFeeDefinition EIFD WITH (NOLOCK)
 WHERE CASE @Today
         WHEN 'sunday'   THEN EIFD.sunday
         WHEN 'monday'   THEN EIFD.monday
         WHEN 'tuesday'  THEN EIFD.tuesday
         WHEN 'wednesday' THEN EIFD.wednesday
         WHEN 'thursday' THEN EIFD.thursday
         WHEN 'friday'   THEN EIFD.friday
         WHEN 'saturday' THEN EIFD.saturday
       END = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dictionary.FeeDefinition and Trade.InstrumentMetaData docs reference fee configuration.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | Object: Trade.ExchangeInstrumentFeeDefinition | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ExchangeInstrumentFeeDefinition.sql*
