# History.OverNightFeePattern

> SQL Server temporal history table storing prior row versions of Dictionary.OverNightFeePattern, preserving the full audit trail for changes to overnight fee calculation pattern definitions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No (on DICTIONARY filegroup) |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.OverNightFeePattern is the SQL Server system-versioning history table for Dictionary.OverNightFeePattern (declared as `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[OverNightFeePattern])`). Whenever a row in Dictionary.OverNightFeePattern is updated or deleted, the prior version is automatically written here by the SQL Server temporal engine.

Dictionary.OverNightFeePattern defines named patterns for how overnight (rollover) fees are calculated for trading positions. Each pattern specifies a fee calculation approach - for example, whether non-leveraged positions incur overnight fees, or whether fees must be set manually. This history table captures every change to these pattern definitions over time.

The same INSERT-capture trigger pattern used in other temporal lookup tables applies here: Dictionary.OverNightFeePattern has `TRG_INSERT_OverNightFeePattern` which fires on INSERT and performs a self-UPDATE (SET Description = Description), forcing the temporal engine to write a history record for the INSERT with SysStartTime = SysEndTime.

---

## 2. Business Logic

### 2.1 Temporal History Pattern

**What**: This table automatically receives prior versions of Dictionary.OverNightFeePattern rows.

**Columns/Parameters Involved**: `OverNightFeePatternID`, `SysStartTime`, `SysEndTime`

**Rules**:
- SysStartTime = SysEndTime (zero-duration window): INSERT-capture record from the trigger.
- SysStartTime < SysEndTime: normal UPDATE record where the row was active during that time window.
- The live current values are in Dictionary.OverNightFeePattern; this table holds all superseded versions.

### 2.2 Overnight Fee Pattern Values

**What**: The OverNightFeePatternID determines how overnight fees are calculated for instruments using that pattern.

**Columns/Parameters Involved**: `OverNightFeePatternID`, `OverNightFeePatternName`, `Description`

**Rules** (from live data):
- ID=1: "WithNonLeverageFee" (or previously "WithNonLeveragedBuy") - standard pattern that includes overnight fees for non-leveraged positions. Description has been updated multiple times, reflecting refinement of the fee logic.
- ID=2: "Manual" - overnight fees are NOT calculated programmatically; they must be set manually by operations.
- Pattern names and descriptions can change over time (as captured in this history table), but the IDs remain stable as FK keys.

---

## 3. Data Overview

| OverNightFeePatternID | OverNightFeePatternName | Description | SysStartTime | SysEndTime | Meaning |
|-----------------------|------------------------|-------------|-------------|------------|---------|
| 1 | WithNonLeverageFee | Regular overnight fee pattern which considers non-leveraged overnight fees | 2025-10-27 | 2025-11-16 | Name updated in Oct 2025 from "WithNonLeveragedBuy" to "WithNonLeverageFee"; active ~3 weeks |
| 1 | WithNonLeverageFee | Regular overnight fee pattern... | 2025-09-01 | 2025-10-27 | Same description, active ~8 weeks before the Oct rename |
| 1 | WithNonLeveragedBuy | Regular overnight fee pattern which considers non-leveraged buy overnight fees | 2025-06-29 | 2025-09-01 | Original name and description; active ~2 months |
| 2 | Manual | Overnight fee pattern that will not be calculated programmatically and must be set manually | 2025-06-29 | 2025-06-29 | INSERT-capture record (SysStart=SysEnd) - initial creation logged |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OverNightFeePatternID | tinyint | NO | - | CODE-BACKED | Overnight fee pattern identifier from Dictionary.OverNightFeePattern. Not unique in this history table - same ID can appear multiple times for each version of the row. |
| 2 | OverNightFeePatternName | varchar(50) | NO | - | CODE-BACKED | The name of the overnight fee calculation pattern (e.g., "WithNonLeverageFee", "Manual"). This value is what changed between versions for PatternID=1 - the name was refined from "WithNonLeveragedBuy" to "WithNonLeverageFee". |
| 3 | Description | varchar(max) | YES | - | CODE-BACKED | Human-readable explanation of how this pattern calculates overnight fees. Provides business context for the pattern name. Stored on DICTIONARY/TEXTIMAGE filegroup due to varchar(max). |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change, computed via SUSER_NAME() in the source table. Captures who made the update for audit purposes. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context info at change time, from CONTEXT_INFO(). Identifies the application/service that initiated the change. NULL when not set by the caller. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active in Dictionary.OverNightFeePattern. Set by the SQL Server temporal engine. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded. SysStartTime=SysEndTime indicates an INSERT-capture record (from the TRG_INSERT_OverNightFeePattern trigger pattern). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Dictionary.OverNightFeePattern | Temporal History | This table is the declared HISTORY_TABLE for Dictionary.OverNightFeePattern. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.OverNightFeePattern | HISTORY_TABLE | Temporal system versioning | All row version changes to Dictionary.OverNightFeePattern are automatically written here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.OverNightFeePattern | Table | Source of all history writes via SQL Server temporal system versioning |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_OverNightFeePattern | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints.

---

## 8. Sample Queries

### 8.1 View full change history for all overnight fee patterns

```sql
SELECT OverNightFeePatternID, OverNightFeePatternName, Description,
       DbLoginName, SysStartTime, SysEndTime
FROM History.OverNightFeePattern WITH (NOLOCK)
ORDER BY OverNightFeePatternID, SysStartTime;
```

### 8.2 Compare current vs previous definition for a specific pattern

```sql
SELECT 'Current' AS Version, OverNightFeePatternID, OverNightFeePatternName, Description, SysStartTime
FROM Dictionary.OverNightFeePattern WITH (NOLOCK)
WHERE OverNightFeePatternID = 1
UNION ALL
SELECT 'History', OverNightFeePatternID, OverNightFeePatternName, Description, SysStartTime
FROM History.OverNightFeePattern WITH (NOLOCK)
WHERE OverNightFeePatternID = 1
ORDER BY SysStartTime DESC;
```

### 8.3 Find all changes made by a specific DB user

```sql
SELECT OverNightFeePatternID, OverNightFeePatternName, Description, DbLoginName, SysStartTime, SysEndTime
FROM History.OverNightFeePattern WITH (NOLOCK)
WHERE DbLoginName LIKE '%bonniegr%'
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OverNightFeePattern | Type: Table | Source: etoro/etoro/History/Tables/History.OverNightFeePattern.sql*
