# History.FeeInPercentageConfigurations

> SQL Server system-versioned temporal history table for Trade.FeeInPercentageConfigurations, recording every change to the percentage-based open/close fee rates configured per instrument, instrument type, or group.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Trade.FeeInPercentageConfigurations`. SQL Server's system-versioning manages this table transparently: whenever a row in `Trade.FeeInPercentageConfigurations` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Trade.FeeInPercentageConfigurations` stores percentage-based fee rates applied when customers open or close positions on specific instruments. Fee rates are configured at three levels of specificity: by individual InstrumentID (most specific), by GroupID (instrument group), or by InstrumentTypeID (most general fallback). The fee applies differently for settled positions (IsSettled=true, i.e., real stock ownership) vs. CFD positions (IsSettled=false). `Trade.FnGetCloseFeeInPercentage` resolves the effective close fee using a priority lookup: instrument-level config beats group-level which beats type-level.

Fee configuration changes are operationally sensitive - modifying percentage fees for instruments directly affects customer trading costs. The history table provides a complete audit trail of every rate change, supporting compliance reviews, customer dispute resolution, and fee calculation verification for historical positions. The `AppLoginName` column contains the context_info value at change time, which in practice is the Unicode-encoded user email from the ops tool API (e.g., "opstest01@etoro.com" padded with null bytes).

---

## 2. Business Logic

### 2.1 Three-Level Fee Configuration Hierarchy

**What**: Fee rates can be set at instrument level, group level, or instrument-type level. The most specific configuration wins.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentTypeID`, `GroupID`, `FeeValue`, `FeeOperationTypeID`

**Rules**:
- CHECK constraint enforces: at least one of (InstrumentID, InstrumentTypeID, GroupID) must be non-null; InstrumentID and InstrumentTypeID cannot both be non-null (unless GroupID is also present)
- UNIQUE constraint: (InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, GroupID) - exactly one fee rate per combination
- Resolution priority in `Trade.FnGetCloseFeeInPercentage`:
  - Priority 1 (most specific): InstrumentID-based config (FeeOperationTypeID IN (2,3))
  - Priority 2 (group): GroupID-based config - if instrument belongs to multiple groups, MAX(FeeValue) is used
  - Priority 3 (fallback): InstrumentTypeID-based config
- FeeOperationTypeID values: 1=Open (position open fee), 2=Close (position close fee), 3=All (applies to both open and close)

**Diagram**:
```
For InstrumentID=1003, IsSettled=false, operation=Close:
  Check: InstrumentID=1003 + FeeOperationTypeID IN (2,3) -> FeeValue=3.8% (FOUND -> use this)
  Skip:  Group lookup (not reached)
  Skip:  InstrumentType lookup (not reached)
  -> Customer pays 3.8% fee on closing a CFD position in InstrumentID=1003
```

### 2.2 Settled vs. CFD Fee Differentiation

**What**: Real stock (settled) positions and CFD positions can have different percentage fees for the same instrument.

**Columns/Parameters Involved**: `IsSettled`, `FeeValue`, `InstrumentID`, `FeeOperationTypeID`

**Rules**:
- IsSettled=true (1): configuration applies to positions where the customer owns actual shares (settled/real stock)
- IsSettled=false (0): configuration applies to CFD positions (contracts for difference, no actual ownership)
- IsSettled=NULL: configuration applies to both settled and CFD (universal rate for that instrument/type/group)
- Observed live data pattern for InstrumentID=1003: Open settled=1.8%, Open CFD=2.8%; Close settled=1.9%, Close CFD=3.8% - CFD positions carry higher fees than settled positions
- `Trade.FnGetCloseFeeInPercentage` uses `(config.IsSettled IS NULL OR config.IsSettled = @IsSettled)` to match both universal and specific configs

### 2.3 SQL Server Temporal + INSERT Trigger Capture Pattern

**What**: The same dual-capture pattern used across Trade temporal tables: temporal versioning for full-row history, plus an INSERT trigger to capture initial row creation.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- SYSTEM_VERSIONING routes all UPDATE/DELETE superseded versions here automatically
- INSERT trigger `TRG_TradeFeeInPercentageConfigurations_INSERT` fires on INSERT and executes `UPDATE SET InstrumentID=InstrumentID` (no-op) to force SQL Server to write the new row into this history table
- AppLoginName = CONVERT(varchar(500), context_info()) captures the calling service user; in practice this is a Unicode-padded email (e.g., "opstest01@etoro.com" followed by null bytes, from the ops tool API setting context_info as nvarchar)
- Changes made via trading-opstool-api (service account) with user email in context_info

---

## 3. Data Overview

| ID | InstrumentID | IsSettled | FeeOperationTypeID | FeeValue | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|---|
| 2535 | 1003 | true | 1 (Open) | 1.80% | 2026-03-18 18:12:22 | 2026-03-18 18:12:22 | INSERT capture: Open fee for settled (real stock) position on InstrumentID=1003 = 1.80%. Zero-duration version = INSERT trigger capture. Changed by trading-opstool-api (opstest01@etoro.com). |
| 2536 | 1003 | true | 2 (Close) | 1.90% | 2026-03-18 18:12:22 | 2026-03-18 18:12:44 | INSERT capture: Close fee for settled position = 1.90%. Superseded ~22s after creation (rapid configuration test). |
| 2537 | 1003 | false | 1 (Open) | 2.80% | 2026-03-18 18:12:22 | 2026-03-18 18:12:55 | INSERT capture: Open fee for CFD position = 2.80%. CFD open fee is higher than settled (2.8% vs 1.8%). |
| 2538 | 1003 | false | 2 (Close) | 3.80% | 2026-03-18 18:12:22 | 2026-03-18 18:13:02 | INSERT capture: Close fee for CFD position = 3.80% - highest fee tier. CFD close fee nearly double the settled close fee (3.8% vs 1.9%). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate identifier from Trade.FeeInPercentageConfigurations IDENTITY PK. Matches the source row. Multiple history rows with the same ID represent successive value versions for that fee configuration row. |
| 2 | InstrumentID | int | YES | - | VERIFIED | Specific instrument for which this fee applies. NULL when the fee is configured at InstrumentType or Group level instead. InstrumentID-based configs take priority over group and type-level. Implicit FK to Trade.Instrument - not enforced in history table. |
| 3 | InstrumentTypeID | int | YES | - | VERIFIED | Instrument type for which this fee applies as a fallback (lowest priority). NULL when fee is configured at instrument or group level. Examples: 1=Forex, 5=Stocks, 10=Crypto. CHECK constraint prevents InstrumentID and InstrumentTypeID from both being non-null. |
| 4 | IsSettled | bit | YES | - | VERIFIED | Whether this fee applies to real stock (settled) or CFD positions. 1=applies to settled (real stock ownership) positions. 0=applies to CFD positions. NULL=applies to both. Fee values typically differ: CFD positions carry higher fees than settled positions for the same operation. |
| 5 | FeeOperationTypeID | tinyint | NO | - | VERIFIED | The trading operation this fee applies to. FK to Dictionary.FeeOperationTypes. Values: 1=Open (fee charged when position opened), 2=Close (fee charged when position closed), 3=All (applies to both open and close). Trade.FnGetCloseFeeInPercentage matches FeeOperationTypeID IN (2,3) for close fee resolution. |
| 6 | FeeValue | decimal(16,8) | NO | - | VERIFIED | The fee percentage charged for this configuration. Stored as a raw percentage value (e.g., 3.8 = 3.8%). High precision (16,8) supports fractional percentage configurations. Used directly by Trade.FnGetCloseFeeInPercentage as the return value. |
| 7 | DataUpdated | datetime | NO | - | CODE-BACKED | Application-set timestamp recording when this configuration row was last updated by the managing service. Set by the calling application (trading-opstool-api) before the DML, not a SQL DEFAULT. Represents business update time, distinct from SysStartTime (SQL Server temporal version time). |
| 8 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Computed column in source, materialized here. Observed: "trading-opstool-api" - the operations tool API service account that manages fee configurations. |
| 9 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level user from context_info() at time of change. Computed as CONVERT(varchar(500), context_info()). In practice contains the ops tool user email encoded as Unicode (nvarchar), resulting in null-byte padding between each character (e.g., "o\0p\0s\0t\0e\0s\0t\00\01\0@\0e\0t\0o\0r\0o\0.\0c\0o\0m"). Identifies the specific ops team member who initiated the change. |
| 10 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version became active in Trade.FeeInPercentageConfigurations. For INSERT-trigger-captured rows, equals SysEndTime (zero-duration version at creation). |
| 11 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column for temporal range scans. SysEndTime=SysStartTime indicates an INSERT trigger capture event. |
| 12 | GroupID | int | YES | - | VERIFIED | Instrument group identifier for group-level fee configuration. When non-null, the fee applies to all instruments in this group. Group-based config has priority between instrument-level (highest) and type-level (lowest). When an instrument belongs to multiple groups, Trade.FnGetCloseFeeInPercentage applies MAX(FeeValue) across all matching group configs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeeOperationTypeID | Dictionary.FeeOperationTypes | Implicit | Identifies the operation type (Open/Close/All). FK is on Trade.FeeInPercentageConfigurations. |
| InstrumentID | History.Instrument | Implicit | Identifies the instrument for instrument-level fee configs. No FK in history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FeeInPercentageConfigurations | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here automatically; INSERT trigger captures creations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FeeInPercentageConfigurations (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FeeInPercentageConfigurations | Table | Source temporal table |
| Trade.FnGetCloseFeeInPercentage | Function | Reads Trade.FeeInPercentageConfigurations (not history directly) for close fee resolution with 3-tier priority lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FeeInPercentageConfigurations | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE) |

### 7.2 Constraints

None on history table. Source table has: PK on ID, UNIQUE on (InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, GroupID), CHECK ensuring at least one of InstrumentID/InstrumentTypeID/GroupID is non-null and InstrumentID/InstrumentTypeID cannot both be non-null without GroupID.

---

## 8. Sample Queries

### 8.1 What were the fee rates for an instrument on a specific date?

```sql
SELECT
    fpc.ID,
    fpc.InstrumentID,
    fpc.InstrumentTypeID,
    fpc.GroupID,
    fpc.IsSettled,
    fpc.FeeOperationTypeID,
    fot.Name AS OperationType,
    fpc.FeeValue,
    fpc.SysStartTime,
    fpc.SysEndTime
FROM Trade.FeeInPercentageConfigurations FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' fpc WITH (NOLOCK)
JOIN Dictionary.FeeOperationTypes fot WITH (NOLOCK) ON fot.FeeOperationTypeID = fpc.FeeOperationTypeID
WHERE fpc.InstrumentID = @InstrumentID
ORDER BY fpc.FeeOperationTypeID, fpc.IsSettled;
```

### 8.2 Full change history for an instrument's fee configurations

```sql
SELECT
    h.ID,
    h.InstrumentID,
    h.IsSettled,
    h.FeeOperationTypeID,
    h.FeeValue,
    h.DataUpdated,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSecs
FROM History.FeeInPercentageConfigurations h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100  -- exclude INSERT captures
ORDER BY h.ID, h.SysStartTime;
```

### 8.3 Resolve effective close fee for an instrument (mirrors FnGetCloseFeeInPercentage logic)

```sql
SELECT TOP 1
    cfg.FeeValue,
    cfg.IsSettled,
    cfg.InstrumentID,
    cfg.InstrumentTypeID,
    cfg.GroupID,
    CASE WHEN cfg.InstrumentID IS NOT NULL THEN 1
         WHEN cfg.GroupID IS NOT NULL THEN 2
         ELSE 3 END AS Priority
FROM Trade.FeeInPercentageConfigurations cfg WITH (NOLOCK)
LEFT JOIN Trade.InstrumentMetaData meta WITH (NOLOCK) ON meta.InstrumentID = @InstrumentID
LEFT JOIN Trade.InstrumentGroups ig WITH (NOLOCK) ON ig.InstrumentID = @InstrumentID AND ig.GroupID = cfg.GroupID
WHERE cfg.FeeOperationTypeID IN (2, 3)  -- Close or All
  AND (cfg.IsSettled IS NULL OR cfg.IsSettled = @IsSettled)
  AND (cfg.InstrumentID = @InstrumentID
       OR cfg.GroupID = ig.GroupID
       OR cfg.InstrumentTypeID = meta.InstrumentTypeID)
ORDER BY Priority ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.FnGetCloseFeeInPercentage, Trade.AddFeeInPercentageConfigurations) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FeeInPercentageConfigurations | Type: Table | Source: etoro/etoro/History/Tables/History.FeeInPercentageConfigurations.sql*
