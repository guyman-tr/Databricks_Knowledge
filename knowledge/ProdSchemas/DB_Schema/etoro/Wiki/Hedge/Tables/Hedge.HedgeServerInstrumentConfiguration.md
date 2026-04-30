# Hedge.HedgeServerInstrumentConfiguration

> Per-hedge-server, per-instrument override configuration table defining failover behavior, price source selection, deal size validation, and IM routing thresholds - currently empty (designed but not yet operationally activated).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (HedgeServerID, InstrumentID) - composite PK CLUSTERED |
| **Partition** | No (on [DICTIONARY] filegroup) |
| **Indexes** | 3 (PK + idx_HSID + idx_InstrumentID) |
| **Versioning** | SYSTEM_VERSIONING -> History.HedgeServerInstrumentConfiguration |

---

## 1. Business Meaning

`Hedge.HedgeServerInstrumentConfiguration` provides a per-server, per-instrument override layer for hedge execution behavior. Where `Hedge.InstrumentConfiguration` applies global per-instrument settings and `Hedge.HBCAccountConfiguration` applies per-account/instrument settings, this table targets the specific intersection of a hedge server and an instrument.

The four data columns each address a distinct execution concern:
- **AllowHBCFailover**: Whether the HBC (Hedge Bot Controller) can fall back to normal execution when HBC processing fails for this instrument on this server.
- **PriceSource**: Which price feed the server uses for this instrument (DEFAULT 1 = primary feed).
- **AllowClosePositionMaxDealSizeCheck**: Whether close-position orders are validated against the max deal size limit (DEFAULT 1 = validate).
- **MinAmountForIM**: Minimum order size (in base currency) required before routing via IM (Institutional Market) path.

**Current data**: 0 rows in both current table and history. The table and reader procedure (`GetHedgeServerInstrumentConfiguration`) are fully implemented and in production, but no rows have ever been inserted. All servers use the system defaults for these per-instrument behaviors, making this a ready-to-activate configuration layer.

This is distinct from `Hedge.BusinessFlowBehavior` which has `AllowHBCFailover` at the server level (7 rows configured). This table would provide instrument-level overrides of that server-level setting.

---

## 2. Business Logic

### 2.1 HBC Failover Override Per Instrument

**What**: `AllowHBCFailover` controls whether, for a specific instrument on a specific server, the hedge engine can fall back to non-HBC execution when HBC processing fails.

**Columns/Parameters Involved**: `AllowHBCFailover`, `HedgeServerID`, `InstrumentID`

**Rules**:
- This is an instrument-level override of the server-level `AllowHBCFailover` in `Hedge.BusinessFlowBehavior`
- 1 = failover allowed: if HBC fails for this instrument, fall back to standard execution
- 0 = no failover: HBC failure results in the order not being executed (strict mode)
- No DEFAULT defined in DDL - must be explicitly set when a row is inserted (required value)
- Currently no rows, so the server-level BusinessFlowBehavior setting governs all instruments

### 2.2 Price Source Selection Per Instrument

**What**: `PriceSource` selects which price feed the server uses for pricing this instrument.

**Columns/Parameters Involved**: `PriceSource`

**Rules**:
- smallint, DEFAULT 1 (primary price source)
- The same `PriceSource` column exists in `Trade.HedgeServer` (server-level default); this table would override per instrument
- Exact enum values not defined in DDL - inferred from DEFAULT 1 = primary feed, other values = alternative feeds

### 2.3 Max Deal Size Check for Close Positions

**What**: `AllowClosePositionMaxDealSizeCheck` controls whether close-position hedge orders are subject to the max deal size validation.

**Columns/Parameters Involved**: `AllowClosePositionMaxDealSizeCheck`

**Rules**:
- DEFAULT 1 = validate close orders against max deal size (same as open orders)
- 0 = bypass the max deal size check for close-position orders on this instrument/server pair
- Use case: instruments where close orders must execute in full regardless of size limits

### 2.4 Minimum Amount for IM Routing

**What**: `MinAmountForIM` sets a minimum order size below which IM (Institutional Market) routing is not used.

**Columns/Parameters Involved**: `MinAmountForIM`

**Rules**:
- decimal(16,4), DEFAULT 0 = no minimum (all orders can route via IM)
- Non-zero values enforce a floor: orders smaller than this are not routed to the IM path
- "IM" refers to OMS IM accounts (AccountTypeID=4: OMS UAT IM3 IM Pricing, OMS UAT IM4 IM Hedging)

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Current rows | 0 |
| History rows | 0 |
| Distinct HedgeServerIDs | 0 |
| Distinct InstrumentIDs | 0 |

Table is fully empty - feature designed and implemented but not yet operationally configured. When activated, rows would define per-server, per-instrument overrides for the 4 behavioral flags.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server this configuration applies to. Part of composite PK. Implicit reference to Trade.HedgeServer (no FK constraint). Indexed via idx_HSID for per-server lookups. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this configuration applies to. Part of composite PK. Implicit reference to Trade.Instrument (no FK constraint). Indexed via idx_InstrumentID for per-instrument lookups. |
| 3 | AllowHBCFailover | bit | NO | - (required) | CODE-BACKED | Whether HBC execution failure for this server/instrument can fall back to standard execution. 1=failover allowed, 0=strict (no fallback). Instrument-level override of Hedge.BusinessFlowBehavior.AllowHBCFailover. No DEFAULT - must be explicitly provided on insert. |
| 4 | PriceSource | smallint | NO | 1 | CODE-BACKED | Price feed selection for this server/instrument pair. DEFAULT 1 = primary price source. Instrument-level override of Trade.HedgeServer.PriceSource. Exact enum values not defined in schema. |
| 5 | AllowClosePositionMaxDealSizeCheck | bit | NO | 1 | CODE-BACKED | Whether max deal size validation applies to close-position orders for this server/instrument. DEFAULT 1 = validate (same rules as open orders). 0 = bypass size check for close orders only. |
| 6 | MinAmountForIM | decimal(16,4) | NO | 0 | CODE-BACKED | Minimum order size (base currency) for routing via Institutional Market (IM) path. DEFAULT 0 = no minimum. Non-zero = orders below this threshold bypass IM routing for this server/instrument. |
| 7 | DbLoginName | varchar(computed) | YES | suser_name() | CODE-BACKED | Computed audit column. SQL Server login executing the DML. |
| 8 | AppLoginName | varchar(computed) | YES | context_info() | CODE-BACKED | Computed audit column. Application identity from CONTEXT_INFO(). NULL when not set. |
| 9 | SysStartTime | datetime2(7) | NO | getutcdate() | VERIFIED | Temporal period start. UTC timestamp when this row version became active. |
| 10 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | VERIFIED | Temporal period end. 9999-12-31 for current rows. History in History.HedgeServerInstrumentConfiguration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. HedgeServerID and InstrumentID are application-managed without explicit FK enforcement.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetHedgeServerInstrumentConfiguration | (table ref) | READER | Full table scan - returns all 5 data columns (no WHERE clause); hedge engine loads all configured overrides on startup |
| History.HedgeServerInstrumentConfiguration | (temporal) | Temporal History | Stores historical row versions via SYSTEM_VERSIONING |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeServerInstrumentConfiguration (table)
  (no FK dependencies - leaf table)
```

---

### 6.1 Objects This Depends On

No FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetHedgeServerInstrumentConfiguration | Stored Procedure | READER - bulk-loads all rows into hedge engine on startup |
| History.HedgeServerInstrumentConfiguration | Table | Temporal shadow table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_HedgeServerInstrumentConfiguration | CLUSTERED PK | HedgeServerID ASC, InstrumentID ASC | - | - | Active |
| idx_HSID | NONCLUSTERED | HedgeServerID ASC | - | - | Active |
| idx_InstrumentID | NONCLUSTERED | InstrumentID ASC | - | - | Active |

Note: Two supporting nonclustered indexes pre-built for fast per-server and per-instrument filtering, indicating expected query patterns once data is populated.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_HedgeServerInstrumentConfiguration | PRIMARY KEY | (HedgeServerID, InstrumentID) - one configuration row per server/instrument pair |
| DEFAULT PriceSource | DEFAULT | PriceSource = 1 |
| DEFAULT AllowClosePositionMaxDealSizeCheck | DEFAULT | AllowClosePositionMaxDealSizeCheck = 1 |
| DF_HedgeServerInstrumentConfiguration_MinAmountForIM | DEFAULT | MinAmountForIM = 0 |
| DF_HedgeServerInstrumentConfiguration_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_HedgeServerInstrumentConfiguration_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime, SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.HedgeServerInstrumentConfiguration |

Note: `AllowHBCFailover` has NO DEFAULT - insert must explicitly provide it.

### 7.3 Triggers

| Trigger Name | Event | Action |
|-------------|-------|--------|
| Tr_T_HedgeServerInstrumentConfiguration_INSERT | INSERT | No-op self-UPDATE (SET HedgeServerID=HedgeServerID, InstrumentID=InstrumentID) to force temporal history capture on INSERT |

---

## 8. Sample Queries

### 8.1 Match GetHedgeServerInstrumentConfiguration output

```sql
-- Matches Hedge.GetHedgeServerInstrumentConfiguration (no parameters)
SELECT
    HedgeServerID,
    InstrumentID,
    AllowHBCFailover,
    PriceSource,
    AllowClosePositionMaxDealSizeCheck,
    MinAmountForIM
FROM Hedge.HedgeServerInstrumentConfiguration WITH (NOLOCK)
ORDER BY HedgeServerID, InstrumentID
-- Currently returns 0 rows
```

### 8.2 When populated - find servers with HBC failover disabled for specific instruments

```sql
SELECT
    hsic.HedgeServerID,
    hsic.InstrumentID,
    hsic.AllowHBCFailover,
    hsic.PriceSource,
    hsic.AllowClosePositionMaxDealSizeCheck,
    hsic.MinAmountForIM
FROM Hedge.HedgeServerInstrumentConfiguration hsic WITH (NOLOCK)
WHERE hsic.AllowHBCFailover = 0  -- strict mode - no HBC failover
ORDER BY hsic.HedgeServerID, hsic.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeServerInstrumentConfiguration | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.HedgeServerInstrumentConfiguration.sql*
