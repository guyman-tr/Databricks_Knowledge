# Hedge.NettingOld

> Legacy predecessor to Hedge.Netting - identical structure but without system-time versioning. Superseded when temporal versioning was added to the netting system; currently empty and no longer referenced by any procedures.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (LiquidityAccountID, InstrumentID, ValueDate) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK only) |

---

## 1. Business Meaning

Hedge.NettingOld is the original netting position table that predates SQL Server system-versioning. It stored the same data as the current Hedge.Netting table - one row per (LiquidityAccountID, InstrumentID, ValueDate) representing the current net hedge position - but without automatic historical change capture.

When the hedge system was upgraded to add temporal versioning (SysStartTime/SysEndTime and SYSTEM_VERSIONING = ON), the active table was renamed from a variation of NettingOld to Hedge.Netting (which now includes temporal versioning), and NettingOld was retained as a structural reference or migration fallback. The "Old" suffix in the name and the constraint name `PK_Netting` (vs `PK_NettingTemp` on the current table) confirm the timeline: Hedge.NettingOld was the original, and Hedge.Netting is the successor.

NettingOld is currently empty (0 rows) and is referenced by no stored procedures. It is a structural artifact that should be considered for decommission if confirmed unused across all environments.

---

## 2. Business Logic

### 2.1 Structural Relationship to Hedge.Netting

**What**: NettingOld and Hedge.Netting share the same business design (same columns, same composite PK structure), differing only in temporal versioning support.

**Columns/Parameters Involved**: All columns

**Rules**:
- Column set is identical to Hedge.Netting except NettingOld lacks SysStartTime and SysEndTime
- PK is (LiquidityAccountID, InstrumentID, ValueDate) - same as Hedge.Netting
- UpdateTime is nullable in NettingOld (NOT NULL in Hedge.Netting)
- No system versioning means no automatic history capture - position changes would simply overwrite the existing row without retention
- FK constraint name `FK_Netting_LiquidityAccountID` (vs `_Temp` suffix on current table) confirms NettingOld is the original

**Diagram**:
```
Evolution:
Hedge.NettingOld (original)     ->      Hedge.Netting (current)
  - (LA, Inst, ValueDate) PK              - (LA, Inst, ValueDate) PK
  - No temporal versioning                - SysStartTime / SysEndTime
  - UpdateTime nullable                   - SYSTEM_VERSIONING = ON
  - 0 rows (inactive)                     - 738 rows (active)
                                          - History in History.Netting_History
```

---

## 3. Data Overview

Hedge.NettingOld is empty (0 rows). No data is available for analysis. When it was active, rows would have represented the same concept as current Hedge.Netting rows - one net hedge position per (LiquidityAccount, Instrument, ValueDate). See [Hedge.Netting](Hedge.Netting.md) Section 3 for representative data examples.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | VERIFIED | First component of composite PK. FK to Trade.LiquidityAccounts - identifies the LP account holding this hedge position. Same semantics as Hedge.Netting.LiquidityAccountID. See [Hedge.Netting](Hedge.Netting.md). |
| 2 | InstrumentID | int | NO | - | VERIFIED | Second component of composite PK. FK to Trade.Instrument (implicit). The financial instrument being hedged. Same semantics as Hedge.Netting.InstrumentID. |
| 3 | Units | decimal(16,2) | YES | - | VERIFIED | Net aggregate hedge position size in instrument units. Same semantics as Hedge.Netting.Units. |
| 4 | IsBuy | bit | NO | - | VERIFIED | Net position direction. true = long, false = short. Same semantics as Hedge.Netting.IsBuy. |
| 5 | AvgRate | dbo.dtPrice | YES | - | VERIFIED | Volume-weighted average entry rate of the position. Same semantics as Hedge.Netting.AvgRate. |
| 6 | ValueDate | date | NO | - | VERIFIED | Third component of composite PK. Settlement date for the hedge positions with the LP. Same semantics as Hedge.Netting.ValueDate. |
| 7 | ExecTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the last hedge execution that updated this position. Same semantics as Hedge.Netting.ExecTime. |
| 8 | UpdateTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the row was last written. Nullable (unlike NOT NULL in NettingDaily and the temporal behavior of Netting) - reflecting this is the older, less strictly typed version. |
| 9 | HedgeServerID | int | NO | - | VERIFIED | FK to Trade.HedgeServer (implicit). Identifies which hedge server instance managed this position. Same semantics as Hedge.Netting.HedgeServerID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | FK (explicit, WITH CHECK) | Constrains valid LP accounts for hedge positions |
| InstrumentID | Trade.Instrument | Implicit | Identifies the hedged financial instrument |
| HedgeServerID | Trade.HedgeServer | Implicit | Identifies the managing hedge server |

### 5.2 Referenced By (other objects point to this)

No active procedures or views reference Hedge.NettingOld. It is not consumed by any code path.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.NettingOld (table)
├── Trade.LiquidityAccounts (table) [FK target - leaf]
├── Trade.Instrument (table) [implicit FK target - leaf]
└── Trade.HedgeServer (table) [implicit FK target - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |

### 6.2 Objects That Depend On This

No dependents found. Hedge.NettingOld is referenced by no stored procedures, views, or functions.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Netting | CLUSTERED PK | LiquidityAccountID ASC, InstrumentID ASC, ValueDate ASC | - | - | Active |

Note: Constraint name `PK_Netting` (without "Temp" suffix) confirms this was the original table before the Temp/versioned redesign.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Netting | PRIMARY KEY | Unique position per (LiquidityAccount, Instrument, ValueDate) |
| FK_Netting_LiquidityAccountID | FOREIGN KEY (WITH CHECK) | LiquidityAccountID must exist in Trade.LiquidityAccounts |

---

## 8. Sample Queries

### 8.1 Verify table is empty
```sql
SELECT COUNT(*) AS RowCount
FROM   [Hedge].[NettingOld] WITH (NOLOCK);
```

### 8.2 Compare schema to current Hedge.Netting (structural audit)
```sql
-- NettingOld columns
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_SCHEMA = 'Hedge' AND TABLE_NAME = 'NettingOld'
ORDER BY ORDINAL_POSITION;
```

### 8.3 Check for any FK violations if data were to be loaded
```sql
-- Validate that any historical data still has valid LiquidityAccountIDs
SELECT  no.LiquidityAccountID
FROM    [Hedge].[NettingOld] no WITH (NOLOCK)
LEFT JOIN [Trade].[LiquidityAccounts] la WITH (NOLOCK)
        ON no.LiquidityAccountID = la.LiquidityAccountID
WHERE   la.LiquidityAccountID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.NettingOld | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.NettingOld.sql*
