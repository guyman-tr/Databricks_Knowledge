# History.MaxLeverageByInstrumentForExposure

> SQL Server temporal history table automatically maintained by the database engine, recording every past state of Trade.MaxLeverageByInstrumentForExposure - the per-instrument exposure tier table that caps leverage based on a customer's total open position size.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.MaxLeverageByInstrumentForExposure is the temporal history backing table for Trade.MaxLeverageByInstrumentForExposure. It is populated automatically by SQL Server's SYSTEM_VERSIONING mechanism whenever rows in the live table are inserted, updated, or deleted - no application or stored procedure writes here directly.

The live table (Trade.MaxLeverageByInstrumentForExposure) implements a tiered leverage cap system: for each instrument, different maximum leverage values apply depending on how many units of that instrument the customer already has open. For example, EUR/USD might allow up to 30x leverage for up to 1,000 units, but only 10x leverage for positions over 10,000 units. This prevents customers from accumulating dangerously large positions in a single instrument by progressively reducing available leverage as exposure grows.

When risk managers adjust these tier thresholds or leverage caps (e.g., during periods of heightened volatility or regulatory changes), the old configuration is automatically preserved here. This history allows the risk team to audit what leverage policy was in effect on any given date and to trace how the exposure limits have evolved over time.

The trigger `Tr_T_MaxLeverageByInstrumentForExposure_INSERT` on the live table performs a no-op UPDATE immediately after every INSERT. This forces the just-inserted row to be captured in this history table as well (since SQL Server temporal normally only archives rows on UPDATE/DELETE, not on INSERT). The result is a complete audit trail: every state of every row is archived, including the initial insertion.

With 0 rows in the test environment, this table is only populated when leverage tiers are actively managed in production.

---

## 2. Business Logic

### 2.1 Temporal History - Automatic State Archival

**What**: SQL Server SYSTEM_VERSIONING automatically writes old row states to this history table whenever rows in Trade.MaxLeverageByInstrumentForExposure change. The SysStartTime/SysEndTime columns define the validity period of each historical state.

**Columns/Parameters Involved**: `InstrumentID`, `MaxPositionUnits`, `MaxLeverage`, `SysStartTime`, `SysEndTime`

**Rules**:
- SysEndTime = the moment this row was superseded (UTC, datetime2 precision)
- SysStartTime = the moment this row became current (UTC)
- SysEndTime='9999-12-31 23:59:59.9999999' only appears in the live table, never in history
- A row in history with SysStartTime=T1, SysEndTime=T2 means: "from T1 to T2, InstrumentID X had MaxPositionUnits=Y allowing MaxLeverage=Z"
- To find what was active at a specific time T: `WHERE SysStartTime <= T AND SysEndTime > T`

**Diagram**:
```
Risk team updates MaxLeverage for InstrumentID=1, MaxPositionUnits=1000:
  Old: MaxLeverage=30 (SysStart=2024-01-01, SysEnd=9999 in live)
  UPDATE Trade.MaxLeverageByInstrumentForExposure SET MaxLeverage=25
  --> SQL Server writes to History:
      InstrumentID=1, MaxPositionUnits=1000, MaxLeverage=30
      SysStartTime=2024-01-01 00:00:00, SysEndTime=2024-03-15 10:00:00
  --> Live table now has:
      InstrumentID=1, MaxPositionUnits=1000, MaxLeverage=25
      SysStartTime=2024-03-15 10:00:00, SysEndTime=9999-12-31
```

### 2.2 INSERT Trigger - Capturing Initial Row State in History

**What**: The trigger `Tr_T_MaxLeverageByInstrumentForExposure_INSERT` fires on every INSERT to the live table and performs a no-op UPDATE (SET InstrumentID=InstrumentID), causing the newly inserted row to be immediately archived in History before the transaction closes.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- Without the trigger: an INSERT to the live table creates no history row (temporal only archives on UPDATE/DELETE)
- With the trigger: every INSERT generates exactly one history row with a very short validity window (SysStartTime to SysEndTime differ by milliseconds)
- DbLoginName (computed column = suser_name()) and AppLoginName (computed column = CONVERT(varchar(500), context_info())) capture the operator identity and application context at the time of the no-op UPDATE
- The caller is responsible for setting context_info() BEFORE the INSERT so that AppLoginName is populated in the history row
- This pattern ensures the history table contains a complete record of who added each tier configuration entry

### 2.3 Tiered Leverage Cap Lookup

**What**: The live table (and by extension its history) implements a step-function cap: for a given instrument and a given customer's current total exposure, the procedure `Trade.GetMaxLeverageByInstrumentForExposureForCID` finds the highest MaxPositionUnits tier that the customer's exposure + new position would not exceed.

**Columns/Parameters Involved**: `InstrumentID`, `MaxPositionUnits`, `MaxLeverage`

**Rules**:
- InstrumentID=0 is the default/catch-all tier, used when no instrument-specific configuration exists
- MaxPositionUnits tiers must be ascending per instrument for the TOP 1 ORDER BY MaxPositionUnits lookup to work correctly
- MaxLeverage decreases (or stays flat) as MaxPositionUnits increases (higher exposure = lower allowed leverage)
- If a customer's total exposure + new position size exceeds all configured MaxPositionUnits tiers, Trade.GetMaxLeverageByInstrumentForExposureForCID raises error 'Over exposure' (@@ROWCOUNT=0 guard)

---

## 3. Data Overview

No data in test environment (0 rows). Production rows represent historical snapshots of leverage tier configurations. Representative example of what history rows would look like after a tier adjustment:

| InstrumentID | MaxPositionUnits | MaxLeverage | DbLoginName | AppLoginName | SysStartTime | SysEndTime |
|---|---|---|---|---|---|---|
| 0 | 1000.0000 | 30 | etoro_admin | RiskManager | 2024-01-01 00:00:00 | 2024-03-15 10:00:00 | Default tier (InstrumentID=0): max 30x for up to 1000 units. Superseded when MaxLeverage lowered to 25 on 2024-03-15. |
| 0 | 10000.0000 | 10 | etoro_admin | RiskManager | 2024-01-01 00:00:00 | 2024-06-01 09:30:00 | Default tier: max 10x for up to 10,000 units. Superseded when MaxPositionUnits threshold increased. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument to which this leverage tier applies. InstrumentID=0 is a special default used when no instrument-specific configuration exists (Trade.GetMaxLeverageByInstrumentForExposureForCID falls back to InstrumentID=0 if no rows exist for the specific instrument). In the live table, part of the composite PK (InstrumentID, MaxPositionUnits). References Trade.Instrument/History.Instrument (no FK enforced in history table). |
| 2 | MaxPositionUnits | decimal(18,4) | NO | - | CODE-BACKED | The upper bound of the exposure tier in units of the instrument. If a customer's existing open units + new position units is <= this value, then MaxLeverage applies. Multiple tiers per InstrumentID create a step function: (1000 units -> 30x), (10000 units -> 10x), (100000 units -> 5x). Part of the composite PK on the live table - each (InstrumentID, MaxPositionUnits) pair is a unique tier configuration row. |
| 3 | MaxLeverage | int | NO | - | CODE-BACKED | The maximum leverage multiplier allowed when a customer's total exposure for this instrument falls within this tier (i.e., <= MaxPositionUnits). Lower tiers (smaller MaxPositionUnits) have higher MaxLeverage; higher tiers have lower MaxLeverage. Applied by Trade.GetMaxLeverageByInstrumentForExposureForCID when evaluating whether a new position open is permitted. |
| 4 | DbLoginName | nvarchar(128) | YES | suser_name() | CODE-BACKED | The SQL Server login name of the session that last modified this row, captured as a computed column on the live table (= suser_name()). Copied into History when the row is archived. Identifies the database-level operator identity for the change - typically a service account (e.g., "etoro_admin", "RiskService_prod"). NULL if not captured. |
| 5 | AppLoginName | varchar(500) | YES | context_info() | CODE-BACKED | The application-level identity of the operator, stored via SQL Server's context_info() mechanism. Captured as a computed column on the live table (= CONVERT(varchar(500), context_info())). The calling application sets context_info() before performing DML so that the responsible user or process name is recorded. Copied into History when the row is archived. NULL if context_info was not set. |
| 6 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when this row became the current state in the live table. Populated automatically by SQL Server SYSTEM_VERSIONING as GENERATED ALWAYS AS ROW START. In the history table, represents when the archived configuration became active. datetime2(7) provides 100-nanosecond precision. |
| 7 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC timestamp when this row was superseded and moved to history. Populated automatically by SQL Server SYSTEM_VERSIONING as GENERATED ALWAYS AS ROW END. For rows in this history table, SysEndTime is always a real past timestamp (not 9999). The interval [SysStartTime, SysEndTime) is the period during which this tier configuration was active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument / History.Instrument | Implicit | References the instrument for which this leverage tier applies. InstrumentID=0 is a special default. No FK enforced in history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.MaxLeverageByInstrumentForExposure | SYSTEM_VERSIONING | Writer (automatic) | The live table's SYSTEM_VERSIONING = ON configuration makes SQL Server automatically archive old row states here on UPDATE/DELETE |
| Tr_T_MaxLeverageByInstrumentForExposure_INSERT | (trigger) | Writer (forced) | INSERT trigger on live table performs no-op UPDATE to force INSERT events into history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MaxLeverageByInstrumentForExposure (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: Trade.MaxLeverageByInstrumentForExposure (live temporal table)
    - Populated automatically by SQL Server SYSTEM_VERSIONING
    - Every INSERT/UPDATE/DELETE to the live table generates a history row
    - Tr_T_MaxLeverageByInstrumentForExposure_INSERT trigger forces INSERT events into history
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by SQL Server temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.MaxLeverageByInstrumentForExposure | Table | Live temporal table - this is its HISTORY_TABLE |
| Trade.GetMaxLeverageByInstrumentForExposureForCID | Stored Procedure | Reads the live table directly; this history table enables point-in-time audit of past leverage configurations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MaxLeverageByInstrumentForExposure | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: The (SysEndTime ASC, SysStartTime ASC) clustered index is the standard SQL Server temporal history table index pattern. Queries using AS OF T syntax translate to `WHERE SysStartTime <= T AND SysEndTime > T`, which benefits from leading SysEndTime. PAGE compression applied.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none on history table) | - | Temporal history tables have no PKs or FKs - SQL Server manages integrity via SYSTEM_VERSIONING |

Live table constraints (for reference):
- PK_TradeMaxLeverageByInstrumentForExposure: Composite PK on (InstrumentID ASC, MaxPositionUnits ASC), FILLFACTOR=95
- PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime): defines temporal period columns

---

## 8. Sample Queries

### 8.1 Point-in-time audit - what leverage tiers were active on a specific date

```sql
-- Using temporal FOR SYSTEM_TIME AS OF syntax (reads History automatically)
SELECT InstrumentID, MaxPositionUnits, MaxLeverage, DbLoginName, AppLoginName
FROM [Trade].[MaxLeverageByInstrumentForExposure]
FOR SYSTEM_TIME AS OF '2024-03-01 00:00:00'
WHERE InstrumentID IN (0, 1, 5)  -- default, EUR/USD, etc.
ORDER BY InstrumentID, MaxPositionUnits

-- Equivalent direct history query:
SELECT InstrumentID, MaxPositionUnits, MaxLeverage, DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM [History].[MaxLeverageByInstrumentForExposure] WITH (NOLOCK)
WHERE SysStartTime <= '2024-03-01' AND SysEndTime > '2024-03-01'
  AND InstrumentID IN (0, 1, 5)
ORDER BY InstrumentID, MaxPositionUnits
```

### 8.2 Full change history for a specific instrument tier

```sql
-- Combine live + history for complete timeline
SELECT 'History' AS Source, InstrumentID, MaxPositionUnits, MaxLeverage,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM [History].[MaxLeverageByInstrumentForExposure] WITH (NOLOCK)
WHERE InstrumentID = 0
UNION ALL
SELECT 'Current', InstrumentID, MaxPositionUnits, MaxLeverage,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM [Trade].[MaxLeverageByInstrumentForExposure] WITH (NOLOCK)
WHERE InstrumentID = 0
ORDER BY MaxPositionUnits, SysStartTime
```

### 8.3 Detect all MaxLeverage reductions (tightening of limits)

```sql
SELECT
    h.InstrumentID,
    h.MaxPositionUnits,
    h.MaxLeverage AS OldMaxLeverage,
    h.SysEndTime AS ChangedAt,
    h.DbLoginName AS ChangedBy,
    -- Find what it was changed TO by looking at what became active at SysEndTime
    live.MaxLeverage AS NewMaxLeverage
FROM [History].[MaxLeverageByInstrumentForExposure] h WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 MaxLeverage
    FROM [Trade].[MaxLeverageByInstrumentForExposure]
    FOR SYSTEM_TIME AS OF h.SysEndTime
    WHERE InstrumentID = h.InstrumentID AND MaxPositionUnits = h.MaxPositionUnits
) live
WHERE live.MaxLeverage < h.MaxLeverage   -- leverage was reduced
ORDER BY h.SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.GetMaxLeverageByInstrumentForExposureForCID) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.MaxLeverageByInstrumentForExposure | Type: Table | Source: etoro/etoro/History/Tables/History.MaxLeverageByInstrumentForExposure.sql*
