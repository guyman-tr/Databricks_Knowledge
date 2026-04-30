# History.FuturesInstrumentsInitialMarginByProviderMapping

> SQL Server system-versioned temporal history table for Trade.FuturesInstrumentsInitialMarginByProviderMapping, recording every change to the initial margin requirements for futures instruments per liquidity provider.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, ProviderID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Trade.FuturesInstrumentsInitialMarginByProviderMapping`. SQL Server's system-versioning manages this table transparently: whenever a row in `Trade.FuturesInstrumentsInitialMarginByProviderMapping` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Trade.FuturesInstrumentsInitialMarginByProviderMapping` stores the initial margin requirement (in USD) for each combination of futures instrument and liquidity provider. Initial margin is the capital a customer must hold to open a futures position - different liquidity providers may impose different margin requirements for the same instrument, reflecting their own risk policies and regulatory requirements.

2,064 history rows span November 2024 to March 2026 across 27 distinct instruments and 2 providers (ProviderID=1 and ProviderID=99). All changes are made by the `OpsFlowAPI` service via the `EtoroOps.Configurations` tool. The MERGE-based upsert pattern (same as FuturesInstrumentRiskSettings) generates repeated history rows when the same value is re-applied during configuration syncs.

---

## 2. Business Logic

### 2.1 Per-Provider Initial Margin Configuration

**What**: Each futures instrument can have a different initial margin requirement per liquidity provider, reflecting provider-specific risk and regulatory policies.

**Columns/Parameters Involved**: `InstrumentID`, `ProviderID`, `InitialMargin`

**Rules**:
- Composite PK: (InstrumentID, ProviderID) - one initial margin amount per instrument-provider pair
- InitialMargin is decimal(10,2) representing a USD amount (e.g., 11.00 = $11 initial margin required)
- Observed range: 0 to 11,000 (extremely wide range reflecting different instrument types and leverage requirements)
- Only 2 distinct providers in history: ProviderID=1 (likely the primary/internal provider) and ProviderID=99 (a secondary/external provider)
- All 27 distinct instruments tracked span both test (200000+) and production instrument IDs

### 2.2 MERGE Upsert via TVP

**What**: The sole write path uses a MERGE statement accepting a table-valued parameter for batch updates.

**Columns/Parameters Involved**: `InstrumentID`, `ProviderID`, `InitialMargin`

**Rules**:
- `Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping` accepts `Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping READONLY` TVP
- MERGE ON (InstrumentID, ProviderID): UPDATE InitialMargin if matched, INSERT new row if not
- No default value - InitialMargin must be explicitly provided in the source TVP
- Repeated calls generate new temporal versions even when the value is unchanged

### 2.3 SQL Server Temporal + INSERT Trigger Capture

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `Tr_T_FuturesInstrumentsInitialMarginByProviderMapping_INSERT` fires a no-op UPDATE (SET InstrumentID=InstrumentID) matching on (InstrumentID, ProviderID) to force creation capture
- AppLoginName: "email;EtoroOps.Configurations" with trailing space padding (same pattern as FuturesInstrumentRiskSettings)
- DbLoginName: "OpsFlowAPI" (exclusive writer)
- Zero-duration rows (SysStartTime=SysEndTime) mark INSERT trigger captures

---

## 3. Data Overview

| InstrumentID | ProviderID | InitialMargin | DbLoginName | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|
| 18 | 99 | $11.00 | OpsFlowAPI | 2026-03-18 18:18 | 2026-03-19 08:57 | Latest version for InstrumentID=18/Provider=99. Changed by alexre@etoro.com. |
| 18 | 99 | $11.00 | OpsFlowAPI | 2026-03-18 18:17 | 2026-03-18 18:18 | Rapid re-upsert (~53s). Same value, OpsFlow testing cycle. |
| (various) | 1 or 99 | 0-11000 | OpsFlowAPI | 2024-11 | 2026-03 | 2064 total rows across 27 instruments. Wide margin range reflects diverse futures instrument types. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The futures instrument for which this initial margin requirement applies. Part of the composite PK in source. Implicit FK to Trade.Instrument. 27 distinct instruments observed including production and synthetic/test IDs (200000+). |
| 2 | ProviderID | int | NO | - | CODE-BACKED | The liquidity provider for whom this margin requirement applies. Part of the composite PK. Only 2 distinct values observed: ProviderID=1 (primary/internal provider) and ProviderID=99 (secondary/external provider). Implicit FK to Trade.Provider. |
| 3 | InitialMargin | decimal(10,2) | NO | - | CODE-BACKED | The initial margin amount in USD required to open a futures position on this instrument with this provider. Stored as a dollar amount (e.g., 11.00 = $11). Observed range: 0 to 11,000. 0 indicates no margin requirement or a test value. High values (hundreds to thousands) reflect index or commodity futures with significant contract value. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Observed exclusively: "OpsFlowAPI". |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info(). Format: "email;EtoroOps.Configurations" with trailing space padding. Identifies the operator who triggered the margin update via OpsFlow configuration portal. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this margin version became active. For INSERT-trigger-captured rows, equals SysEndTime. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | History.Instrument | Implicit | The futures instrument these margin requirements apply to. No FK in history table. |
| ProviderID | Trade.Provider (implicit) | Implicit | The liquidity provider whose margin requirement is configured. No FK constraint. Only ProviderID=1 and ProviderID=99 observed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FuturesInstrumentsInitialMarginByProviderMapping | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger captures creations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FuturesInstrumentsInitialMarginByProviderMapping (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesInstrumentsInitialMarginByProviderMapping | Table | Source temporal table |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | Stored Procedure | MERGE upsert: inserts/updates initial margin per instrument-provider pair |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FuturesInstrumentsInitialMarginByProviderMapping | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

### 7.2 Constraints

None on history table. Source table has: CLUSTERED PK on (InstrumentID, ProviderID) with FILLFACTOR=90, DATA_COMPRESSION=PAGE.

---

## 8. Sample Queries

### 8.1 Initial margin requirement for an instrument-provider pair on a specific date

```sql
SELECT
    fimpm.InstrumentID,
    fimpm.ProviderID,
    fimpm.InitialMargin,
    fimpm.SysStartTime,
    fimpm.SysEndTime
FROM Trade.FuturesInstrumentsInitialMarginByProviderMapping
    FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' fimpm WITH (NOLOCK)
WHERE fimpm.InstrumentID = @InstrumentID
  AND fimpm.ProviderID = @ProviderID;
```

### 8.2 Change history for an instrument's margin across all providers

```sql
SELECT
    h.InstrumentID,
    h.ProviderID,
    h.InitialMargin,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    LEFT(h.AppLoginName, CHARINDEX(';', h.AppLoginName + ';') - 1) AS OperatorEmail,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSecs
FROM History.FuturesInstrumentsInitialMarginByProviderMapping h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.ProviderID, h.SysStartTime;
```

### 8.3 All current initial margin configurations

```sql
SELECT
    InstrumentID,
    ProviderID,
    InitialMargin
FROM Trade.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
ORDER BY InstrumentID, ProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FuturesInstrumentsInitialMarginByProviderMapping | Type: Table | Source: etoro/etoro/History/Tables/History.FuturesInstrumentsInitialMarginByProviderMapping.sql*
