# Trade.ProviderMarginMarkupByInstrument

> System-versioned configuration table for liquidity-provider margin markup percentage per instrument; temporal history tracks all changes with who/when audit trail.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID, ProviderID |
| **Partition** | No |
| **Indexes** | 1 (clustered PK on InstrumentID, ProviderID) |

---

## 1. Business Meaning

**WHAT:** Trade.ProviderMarginMarkupByInstrument configures the margin markup percentage that a liquidity provider charges per instrument. The markup is added on top of the base margin requirement. Each row is a (InstrumentID, ProviderID) pair with a MarkupPercentage.

**WHY:** Different providers charge different margin markups. The system needs per-instrument, per-provider configuration to calculate correct margin requirements for hedging and risk. Without this table, margin calculations would use a single default or miss provider-specific charges.

**HOW:** Rows are inserted/updated via procedures (e.g. Trade.UpsertProviderMarginMarkupByInstrument). System versioning (temporal) tracks every change: History.ProviderMarginMarkupByInstrument stores the full history. An INSERT trigger forces an immediate update to capture the initial state in the history table. DbLoginName and AppLoginName computed columns record who changed each row (SQL login vs application via context_info).

---

## 2. Business Logic

### 2.1 Margin Markup Application

**What**: MarkupPercentage is applied on top of base margin for the instrument-provider pair.

**Columns Involved**: `InstrumentID`, `ProviderID`, `MarkupPercentage`

**Rules**:
- Composite PK (InstrumentID, ProviderID) -> one markup per instrument per provider
- MarkupPercentage is added to base margin (e.g. 10% -> 10% extra on base)
- All current sample rows have ProviderID=99 and MarkupPercentage=10%

**Diagram**:
```
Base Margin (from provider/instrument config)
    +
MarkupPercentage (from this table)
    =
Effective Margin Requirement
```

### 2.2 Temporal and Audit

**What**: System versioning and computed columns provide full audit trail.

**Columns Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- SysStartTime, SysEndTime: temporal period columns
- DbLoginName = suser_name() -> who changed via SQL
- AppLoginName = CONVERT(varchar(500), context_info()) -> which app changed
- INSERT trigger forces versioning to capture initial row

**Diagram**:
```
Current Table (Trade.ProviderMarginMarkupByInstrument)
    |
    v
History Table (History.ProviderMarginMarkupByInstrument)
    - All prior versions with SysStartTime, SysEndTime
    - Query FOR SYSTEM_TIME AS OF <date> for point-in-time
```

---

## 3. Data Overview

| InstrumentID | ProviderID | MarkupPercentage | Meaning |
|--------------|------------|------------------|---------|
| 0 | 99 | 10.00 | Default/special instrument (0) with provider 99, 10% markup |
| 18 | 99 | 10.00 | Instrument 18 with provider 99, 10% markup |
| 27 | 99 | 10.00 | Instrument 27 with provider 99, 10% markup |
| (other rows) | 99 | 10.00 | ~20 rows total; all ProviderID=99, MarkupPercentage=10% |

**Selection criteria**: 20 rows total. Sample shows InstrumentID 0 (default), 18, 27. All current rows have ProviderID=99 and MarkupPercentage=10%.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Part of PK. Instrument. References Trade.Instrument. |
| 2 | ProviderID | int | NO | - | CODE-BACKED | Part of PK. Liquidity provider. References Trade.Provider. |
| 3 | MarkupPercentage | decimal(10,2) | NO | - | CODE-BACKED | Margin markup percentage (e.g. 10 = 10%) added to base margin. |
| 4 | DbLoginName | nvarchar(128) | - | Computed | CODE-BACKED | Computed: suser_name(). SQL login who changed the row. |
| 5 | AppLoginName | varchar(500) | - | Computed | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application that changed via context_info. |
| 6 | SysStartTime | datetime2(7) | NO | Generated | CODE-BACKED | Row start for temporal; GENERATED ALWAYS AS ROW START. |
| 7 | SysEndTime | datetime2(7) | NO | Generated | CODE-BACKED | Row end for temporal; GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Instrument for margin markup. |
| ProviderID | Trade.Provider | Implicit | Liquidity provider. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpsertProviderMarginMarkupByInstrument | Procedure | Writes | Inserts/updates markup config. |
| Margin/PnL calculations | - | Reads | Uses markup for effective margin. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderMarginMarkupByInstrument (table)
(No code-level dependencies - CREATE TABLE has no FROM/JOIN)
```

### 6.1 Objects This Depends On

No code-level dependencies. Logical references to Trade.Instrument, Trade.Provider are in Section 5. History.ProviderMarginMarkupByInstrument is the system-versioned history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpsertProviderMarginMarkupByInstrument | Procedure | Inserts and updates markup rows. |
| History.ProviderMarginMarkupByInstrument | Table | System versioning history. |
| Margin calculation logic | - | Reads markup for risk/margin. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (implicit) | CLUSTERED PK | InstrumentID ASC, ProviderID ASC | - | - | Active |

PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime). SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.ProviderMarginMarkupByInstrument).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | InstrumentID, ProviderID (clustered) |
| PERIOD | SYSTEM_TIME | SysStartTime, SysEndTime |

INSERT trigger forces system versioning to capture initial row in history.

---

## 8. Sample Queries

### 8.1 Current markup by instrument and provider

```sql
SELECT InstrumentID, ProviderID, MarkupPercentage, DbLoginName, AppLoginName
FROM   Trade.ProviderMarginMarkupByInstrument WITH (NOLOCK);
```

### 8.2 Resolve instrument and provider names

```sql
SELECT p.InstrumentID, p.ProviderID, p.MarkupPercentage,
       i.Symbol AS InstrumentSymbol, pr.ProviderName
FROM   Trade.ProviderMarginMarkupByInstrument p WITH (NOLOCK)
JOIN   Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = p.InstrumentID
JOIN   Trade.Provider pr WITH (NOLOCK) ON pr.ProviderID = p.ProviderID;
```

### 8.3 Point-in-time history (temporal query)

```sql
SELECT InstrumentID, ProviderID, MarkupPercentage,
       SysStartTime, SysEndTime
FROM   Trade.ProviderMarginMarkupByInstrument
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + context*
*Sources: DDL, Trade.Instrument doc, Trade.Provider doc, live data sample | Corrections: 0 applied*
*Object: Trade.ProviderMarginMarkupByInstrument | Type: Table | Source: etoro/Trade/Tables/ProviderMarginMarkupByInstrument.sql*
