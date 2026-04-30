# History.FixPerLotConfigurations

> SQL Server system-versioned temporal history table for Trade.FixPerLotConfigurations, recording every change to the fixed-dollar-per-lot fee rates configured per instrument, instrument type, or group.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Trade.FixPerLotConfigurations`. SQL Server's system-versioning manages this table transparently: whenever a row in `Trade.FixPerLotConfigurations` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Trade.FixPerLotConfigurations` stores fixed-amount (dollar-per-lot) fee rates charged when customers open or close positions. The "Fix" in the name refers to "fixed fee" - a flat dollar amount per lot traded, as opposed to a percentage of the position value (which is stored in `Trade.FeeInPercentageConfigurations`). Fee rates follow the same three-level specificity hierarchy: InstrumentID (most specific), GroupID (instrument group), or InstrumentTypeID (most general fallback). The same settled/CFD differentiation via `IsSettled` applies.

218 history rows span changes from December 2025 to February 2026, all made via the `trading-opstool-api` service account with operator emails (igorve@etoro.com, miriyamma@etoro.com, yevgenyni@etoro.com) encoded in AppLoginName.

---

## 2. Business Logic

### 2.1 Three-Level Fee Configuration Hierarchy (Fixed Per-Lot Amount)

**What**: Fixed fee rates can be set at instrument level, group level, or instrument-type level. The most specific configuration wins, same priority as FeeInPercentageConfigurations.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentTypeID`, `GroupID`, `FeeValue`, `FeeOperationTypeID`

**Rules**:
- CHECK constraint enforces: at least one of (InstrumentID, InstrumentTypeID, GroupID) must be non-null; InstrumentID and InstrumentTypeID cannot both be non-null (unless GroupID is also present)
- UNIQUE constraint on (InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, GroupID) - exactly one fee rate per combination
- FeeOperationTypeID values: 1=Open (charged when position opened), 2=Close (charged when position closed), 3=All (applies to both)
- FeeValue is decimal(16,4) representing a dollar amount per lot (e.g., 1.4 = $1.40 per lot, 5.0 = $5.00 per lot)
- Resolution: instrument-level (most specific) beats group-level beats type-level; when instrument belongs to multiple groups, MAX(FeeValue) likely applies consistent with FeeInPercentageConfigurations

**Contrast with FeeInPercentageConfigurations**:
- `Trade.FixPerLotConfigurations`: FeeValue = flat dollar amount per lot (e.g., $1.40/lot)
- `Trade.FeeInPercentageConfigurations`: FeeValue = percentage of position value (e.g., 3.8%)
- Both tables share the same schema structure, same 3-level hierarchy, same IsSettled differentiation, and same temporal audit pattern

### 2.2 Settled vs. CFD Fee Differentiation

**What**: Real stock (settled) positions and CFD positions can carry different fixed per-lot fees for the same instrument or group.

**Columns/Parameters Involved**: `IsSettled`, `FeeValue`, `InstrumentID`, `GroupID`, `FeeOperationTypeID`

**Rules**:
- IsSettled=true (1): applies to real stock ownership (settled) positions
- IsSettled=false (0): applies to CFD positions
- IsSettled=NULL: applies to both settled and CFD (universal rate)
- Observed pattern: GroupID=41, Close, settled: $1.50/lot; GroupID=41, Close, CFD: $2.00/lot - CFD attracts higher fixed fee

### 2.3 SQL Server Temporal + INSERT Trigger Capture

**What**: Same dual-capture pattern used across Trade configuration temporal tables.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `TRG_TradeFixPerLotConfigurations_INSERT` fires a no-op UPDATE (SET InstrumentID=InstrumentID) matching on `ID` (IDENTITY PK) to force SQL Server to write the new row into this history table
- Zero-duration history rows (SysStartTime = SysEndTime) are INSERT trigger captures
- AppLoginName = CONVERT(varchar(500), context_info()) - in practice contains Unicode-encoded operator email (e.g., "i\0g\0o\0r\0v\0e\0@\0e\0t\0o\0r\0o\0.\0c\0o\0m") from trading-opstool-api
- DbLoginName: "trading-opstool-api" (service account) or "TRAD\\gittysa" (direct SQL access by ops team member)

---

## 3. Data Overview

| ID | InstrumentID | GroupID | IsSettled | FeeOperationTypeID | FeeValue | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|---|---|
| 103 | NULL | 41 | true | 1 (Open) | $5.00 | 2026-02-18 | 2026-02-18 | INSERT capture: Open fee for settled positions in GroupID=41 = $5.00/lot. Changed by miriyamma@etoro.com via trading-opstool-api. |
| 101 | 1005 | NULL | NULL | 3 (All) | $1.40 | 2025-12-16 | 2025-12-29 | FeeValue=1.4 for both open and close on InstrumentID=1005 (both settled and CFD). Active for 13 days then superseded. |
| 93 | 1003 | NULL | true | 2 (Close) | $1.50 | 2025-12-15 | 2025-12-28 | Close fee for settled InstrumentID=1003 = $1.50/lot. Prior value was $0 (9 seconds earlier). |
| 93 | 1003 | NULL | true | 2 (Close) | $0 | 2025-12-15 | 2025-12-15 | Zero-fee period (8 seconds). Initial value set by yevgenyni@etoro.com then immediately corrected. |
| 9 | NULL | 41 | false | 2 (Close) | $2.00 | 2025-12-25 | 2025-12-25 | CFD close fee for GroupID=41 updated from $1.00 to $2.00. Active ~1 minute (rapid correction). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate identifier from Trade.FixPerLotConfigurations IDENTITY PK. Multiple history rows with the same ID represent successive fee value versions for that configuration row. |
| 2 | InstrumentID | int | YES | - | VERIFIED | Specific instrument for which this fixed per-lot fee applies. NULL when configured at group or type level. Instrument-level configs take highest priority. Implicit FK to Trade.Instrument (no FK enforced in history). |
| 3 | InstrumentTypeID | int | YES | - | VERIFIED | Instrument type for the lowest-priority fallback fee rate. NULL when configured at instrument or group level. CHECK constraint prevents InstrumentID and InstrumentTypeID from both being non-null without GroupID. Examples: 5=Stocks, 10=Crypto. |
| 4 | IsSettled | bit | YES | - | VERIFIED | Whether this fee applies to real stock (1=settled) or CFD (0=CFD) positions. NULL=applies to both. Observed: CFD fees can be higher than settled for the same operation. |
| 5 | FeeOperationTypeID | tinyint | NO | - | VERIFIED | The trading operation this fee applies to. FK to Dictionary.FeeOperationTypes. 1=Open (fee charged when position opened), 2=Close (fee charged when position closed), 3=All (open and close). |
| 6 | FeeValue | decimal(16,4) | NO | - | VERIFIED | The fixed fee amount in USD charged per lot for this configuration. Stored as a dollar amount (e.g., 1.4 = $1.40 per lot, 5.0 = $5.00 per lot). Lower precision than FeeInPercentageConfigurations (4 decimal places vs 8) reflecting cent-level granularity for fixed amounts. |
| 7 | DataUpdated | datetime | NO | - | CODE-BACKED | Application-set timestamp recording when the managing service (trading-opstool-api) last updated this configuration row. Set by the caller before DML, distinct from SysStartTime (SQL Server temporal version time). |
| 8 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Observed: "trading-opstool-api" (ops tool service account, normal path), "TRAD\\gittysa" (direct SQL access by ops team member). |
| 9 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level user from context_info() at time of change. In practice contains operator email as Unicode (nvarchar stored as varchar), resulting in null-byte padding: "i\0g\0o\0r\0v\0e\0@\0e\0t\0o\0r\0o\0.\0c\0o\0m\0\0...". NULL when change was made directly via SQL without the ops tool. Identifies the specific ops team member. |
| 10 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version became active. For INSERT-trigger-captured rows, equals SysEndTime (zero-duration version at creation). |
| 11 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. SysEndTime=SysStartTime marks INSERT trigger capture events. |
| 12 | GroupID | int | YES | - | VERIFIED | Instrument group identifier for group-level fee configuration. When non-null, applies to all instruments in this group. Middle priority: more specific than InstrumentTypeID but less specific than InstrumentID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeeOperationTypeID | Dictionary.FeeOperationTypes | Implicit | Identifies the operation type (Open/Close/All). FK enforced on Trade.FixPerLotConfigurations, not on history table. |
| InstrumentID | History.Instrument | Implicit | Identifies the instrument for instrument-level fee configs. No FK in history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FixPerLotConfigurations | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here automatically; INSERT trigger captures creations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FixPerLotConfigurations (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FixPerLotConfigurations | Table | Source temporal table |
| Trade.GetAllFixPerLotConfigurations | Stored Procedure | Reads source table to return all current configurations (ID, InstrumentID, GroupID, InstrumentTypeID, IsSettled, FeeValue, FeeOperationTypeID) |
| Trade.AddFixPerLotConfigurations | Stored Procedure | Inserts new fee configurations |
| Trade.UpdateFixPerLotConfigurations | Stored Procedure | Updates existing fee configurations |
| Trade.DeleteFixPerLotConfigurations | Stored Procedure | Deletes fee configurations |
| Trade.ValidateFixPerLotConfigurations | Stored Procedure | Validates configuration before apply |
| Trade.FixPerLotConfigurationsTblValidate | Stored Procedure | Table-level validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FixPerLotConfigurations | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

### 7.2 Constraints

None on history table. Source table has: PK on ID, UNIQUE on (InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, GroupID), CHECK ensuring at least one of InstrumentID/InstrumentTypeID/GroupID is non-null and InstrumentID/InstrumentTypeID cannot both be non-null without GroupID, FK on FeeOperationTypeID to Dictionary.FeeOperationTypes.

---

## 8. Sample Queries

### 8.1 What were the fixed per-lot fees for an instrument on a specific date?

```sql
SELECT
    fpl.ID,
    fpl.InstrumentID,
    fpl.InstrumentTypeID,
    fpl.GroupID,
    fpl.IsSettled,
    fpl.FeeOperationTypeID,
    fpl.FeeValue AS FeePerLotUSD,
    fpl.SysStartTime,
    fpl.SysEndTime
FROM Trade.FixPerLotConfigurations FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' fpl WITH (NOLOCK)
WHERE fpl.InstrumentID = @InstrumentID
   OR fpl.GroupID IN (SELECT GroupID FROM Trade.InstrumentGroups WHERE InstrumentID = @InstrumentID)
ORDER BY fpl.FeeOperationTypeID, fpl.IsSettled;
```

### 8.2 Full change history for an instrument's fixed per-lot fees

```sql
SELECT
    h.ID,
    h.InstrumentID,
    h.GroupID,
    h.IsSettled,
    h.FeeOperationTypeID,
    h.FeeValue AS OldFeePerLotUSD,
    h.DataUpdated,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSecs
FROM History.FixPerLotConfigurations h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100  -- exclude INSERT captures
ORDER BY h.ID, h.SysStartTime;
```

### 8.3 All fee changes in a time window with operator identification

```sql
SELECT
    h.ID,
    h.InstrumentID,
    h.GroupID,
    h.InstrumentTypeID,
    h.IsSettled,
    h.FeeOperationTypeID,
    h.FeeValue AS OldFeePerLotUSD,
    h.SysEndTime AS ChangeTime,
    h.DbLoginName AS ChangedBy,
    -- Extract email from Unicode null-padded AppLoginName
    REPLACE(LEFT(h.AppLoginName, NULLIF(PATINDEX('%[^ ]%' + CHAR(0), h.AppLoginName + CHAR(0)), 0) - 1), CHAR(0), '') AS OperatorEmail
FROM History.FixPerLotConfigurations h WITH (NOLOCK)
WHERE h.SysEndTime >= @StartDate
  AND h.SysEndTime < @EndDate
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.GetAllFixPerLotConfigurations, DDL analysis) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FixPerLotConfigurations | Type: Table | Source: etoro/etoro/History/Tables/History.FixPerLotConfigurations.sql*
