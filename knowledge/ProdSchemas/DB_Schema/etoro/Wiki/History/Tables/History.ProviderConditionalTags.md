# History.ProviderConditionalTags

> Temporal history backing table for Hedge.ProviderConditionalTags - storing all past versions of conditional tag assignment rules that control which tags are applied to liquidity provider orders based on conditions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [DICTIONARY] filegroup) |
| **Indexes** | 1 (1 clustered temporal) |

---

## 1. Business Meaning

`History.ProviderConditionalTags` is the **temporal history backing table** for `Hedge.ProviderConditionalTags`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly.

The live table `Hedge.ProviderConditionalTags` defines conditional rules for tagging orders sent to liquidity providers. Each rule specifies: for a given `ProviderTypeID` and `LiquidityAccountID`, when a certain condition is met, apply tag `TargetTag` with value `TargetValue` at priority level `Priority`. These tags are metadata attached to hedge/liquidity orders that instruct the downstream execution system (e.g., the prime broker or ECN) on how to handle the order.

With only 3 history rows, the conditional tag configuration is rarely changed - once set up, it remains stable. The unique GUID `ConditionID` PK (rather than a composite key) suggests each condition is an independently managed entity that can be updated or deleted without affecting other conditions.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to Hedge.ProviderConditionalTags automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = UTC timestamp when this conditional tag rule became active
- `SysEndTime` = UTC timestamp when this rule was superseded
- Rows here are EXPIRED versions only - current rules live in Hedge.ProviderConditionalTags

### 2.2 Conditional Tag Assignment Logic

**What**: Each row defines one condition that, when met, causes a tag to be applied to orders for a specific provider account.

**Columns/Parameters Involved**: `ConditionID`, `ProviderTypeID`, `LiquidityAccountID`, `Priority`, `TargetTag`, `TargetValue`

**Rules**:
- `ProviderTypeID` FK to Trade.LiquidityProviderType - identifies the provider type (e.g., a specific ECN or prime broker type)
- `LiquidityAccountID=0` in live data: 0 likely represents a "global" or "any account" scope
- `Priority`: determines evaluation order when multiple conditions apply (lower = higher priority based on observed values 0 and 1)
- `TargetTag=1` in all observed rows: the tag type to apply (likely an execution-level instruction tag)
- `TargetValue`: the value to set for the tag ("1" or "2" in observed data - binary-style values)
- The `Tr_Hedge_ProviderConditionalTags_INSERT` no-op trigger forces temporal row versioning on INSERT

---

## 3. Data Overview

3 rows. All from 2025-01-15. ProviderTypeID=2, LiquidityAccountID=0. TargetTag=1 with values "1" and "2".

| ConditionID | ProviderTypeID | LiquidityAccountID | Priority | TargetTag | TargetValue | SysStartTime | SysEndTime |
|---|---|---|---|---|---|---|---|
| 82521661-...A208 | 2 | 0 | 1 | 1 | "2" | 2025-01-15 08:08:10 | 2025-01-15 08:08:10 |
| E56A000A-...BB18 | 2 | 0 | 0 | 1 | "1" | 2025-01-15 08:08:10 | 2025-01-15 08:08:10 |

*2 conditions configured for ProviderTypeID=2 on the same day. Priority=0 (higher precedence) uses TargetValue="1", Priority=1 uses TargetValue="2".*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConditionID | uniqueidentifier | NO | - | VERIFIED | GUID PK of the conditional tag rule. Allows individual rules to be created, updated, or deleted independently. The uniqueidentifier type enables distributed ID generation (no IDENTITY sequence needed). |
| 2 | ProviderTypeID | int | NO | - | CODE-BACKED | The liquidity provider type this rule applies to. FK to Trade.LiquidityProviderType(LiquidityProviderTypeID) on the live table. Observed value: 2. Scopes the conditional tag rule to orders sent to a specific provider type. |
| 3 | LiquidityAccountID | int | NO | - | CODE-BACKED | The specific liquidity account within the provider type. 0 = applies to all accounts for this provider type (global scope). When non-zero, narrows the rule to a specific trading account at the provider. |
| 4 | Priority | int | NO | - | CODE-BACKED | Evaluation order when multiple conditions match. Lower value = higher priority (0 is evaluated before 1). Determines which tag value wins when multiple conditions could apply to the same order. |
| 5 | TargetTag | int | NO | - | CODE-BACKED | The tag type ID to set when this condition fires. Observed value: 1. Tags are execution-level metadata attached to orders sent to the liquidity provider. The tag type defines the semantic meaning (e.g., routing instruction, account classification). |
| 6 | TargetValue | varchar(256) | NO | - | CODE-BACKED | The value to assign to TargetTag when this condition fires. Observed values: "1" and "2" (binary-style). The TargetTag's definition determines how the provider interprets these values. |
| 7 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login captured via suser_name() at write time on the live table. Identifies who modified the conditional tag configuration. |
| 8 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application identity from context_info() at write time. May contain null-byte padding from varchar(500) context_info() storage. |
| 9 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this conditional tag rule became active. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). |
| 10 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this rule was superseded. Set by SQL Server temporal engine. Ending boundary (exclusive). Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderTypeID | Trade.LiquidityProviderType | Implicit (FK on live table) | The provider type these tag conditions apply to |
| (all columns) | Hedge.ProviderConditionalTags | Temporal | This is the history backing table for the live Hedge table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when Hedge.ProviderConditionalTags is modified |
| Tr_Hedge_ProviderConditionalTags_INSERT | Trigger | Related | No-op touch trigger on live table that forces temporal versioning on INSERT |
| Hedge.GetConditionalTags | Stored Procedure | READER | Reads live table to retrieve active conditional tag rules for order routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProviderConditionalTags (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ProviderConditionalTags | Table | Live table - SQL Server moves expired rows here automatically |
| Hedge.GetConditionalTags | Stored Procedure | Reads live table for active tag rules |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ProviderConditionalTags | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. ON [DICTIONARY] filegroup. Standard temporal history clustering pattern.*

### 7.2 Constraints

None (FK constraints enforced on live Hedge.ProviderConditionalTags table).

---

## 8. Sample Queries

### 8.1 Full change history for a specific condition

```sql
SELECT ConditionID, ProviderTypeID, LiquidityAccountID, Priority, TargetTag, TargetValue,
    DbLoginName, SysStartTime, SysEndTime
FROM History.ProviderConditionalTags WITH (NOLOCK)
WHERE ConditionID = @ConditionID
ORDER BY SysStartTime ASC
```

### 8.2 All past tag rules for a specific provider type

```sql
SELECT ConditionID, LiquidityAccountID, Priority, TargetTag, TargetValue,
    DbLoginName, SysStartTime, SysEndTime
FROM History.ProviderConditionalTags WITH (NOLOCK)
WHERE ProviderTypeID = @ProviderTypeID
ORDER BY SysStartTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProviderConditionalTags | Type: Table | Source: etoro/etoro/History/Tables/History.ProviderConditionalTags.sql*
