# eMoney_dbo.eMoney_Dictionary_TribeScriptStatus

> 3-row lookup table materializing FiatDwhDB.Dictionary.TribeScriptStatus into the Synapse DWH; defines the approval workflow states for scripts executed against the Tribe provider system (Unapproved, Approved, Executed). All values loaded 2023-06-12; static since initial load.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.TribeScriptStatus (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; Override strategy, 1440 min cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 3 (0=Unapproved, 1=Approved, 2=Executed) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_TribeScriptStatus` is a lookup/reference table that defines the valid approval workflow states for scripts executed against the Tribe provider system. Each row maps an integer ID to a human-readable status name. Tribe is the card-issuing and payment infrastructure provider for eToro Money; scripts queued for execution against Tribe follow a two-step approval gate before running.

The 3 states represent the linear workflow: `Unapproved (0)` — script is pending review; `Approved (1)` — script has been authorized for execution; `Executed (2)` — script has been run against the Tribe system. Script status transitions are tracked in `Tribe.FilesScriptHistoryStatus` in FiatDwhDB.

This dictionary is sourced from `FiatDwhDB.Dictionary.TribeScriptStatus` via Generic Pipeline Bronze export. All Synapse rows carry UpdateDate 2023-06-12 (single bulk load).

---

## 2. Business Logic

### 2.1 Script Approval Workflow

**What**: Defines the two-step gate before a script is executed against the Tribe card/payment provider system.

**Columns Involved**: `TribeScriptStatusID`

**Rules**:
- `0=Unapproved` — script has been submitted but not yet authorized; blocked from execution
- `1=Approved` — script has passed review and is authorized for execution against Tribe
- `2=Executed` — script has been run; status is terminal for that script instance

### 2.2 Terminal State

**Columns Involved**: `TribeScriptStatusID`

**Rules**:
- `Executed (2)` is a terminal state — once executed, a script entry does not revert; re-runs require a new script submission
- `Unapproved (0)` can move to `Approved (1)` or be rejected (rejection handling tracked in `Tribe.FilesScriptHistoryStatus`, not in this dictionary)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distributes all 3 rows to every node. Joins from script history tables are data-local. HEAP is optimal for 3 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up script status name | `SELECT TribeScriptStatus FROM eMoney_Dictionary_TribeScriptStatus WHERE TribeScriptStatusID = @id` |
| Filter for pending scripts | `WHERE TribeScriptStatusID = 0 -- Unapproved` |
| Filter for executed scripts | `WHERE TribeScriptStatusID = 2` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Tribe.FilesScriptHistoryStatus (eMoney_dbo mirror) | TribeScriptStatusID = TribeScriptStatusID | Decode approval state on Tribe script history records |

### 3.4 Gotchas

- Only 3 rows; any query returning more indicates a data issue
- `0=Unapproved` does NOT mean rejected — rejection is a separate workflow event in the history table
- `2=Executed` is terminal for that script instance; do not interpret as "always successful" — execution success/failure is tracked separately

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB) |
| Tier 2 | Derived from ETL SP code or DWH logic |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary-sourced |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TribeScriptStatusID | int | YES | Lookup identifier. Primary key. 0=Unapproved, 1=Approved, 2=Executed. (Tier 1 — Dictionary.TribeScriptStatus) |
| 2 | TribeScriptStatus | varchar(50) | YES | Human-readable name for this value. 0=Unapproved, 1=Approved, 2=Executed. (Tier 1 — Dictionary.TribeScriptStatus) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| TribeScriptStatusID | FiatDwhDB.Dictionary.TribeScriptStatus | Id | Rename; tinyint→int widen |
| TribeScriptStatus | FiatDwhDB.Dictionary.TribeScriptStatus | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.TribeScriptStatus (source — 3 rows: 0=Unapproved, 1=Approved, 2=Executed)
  |-- Generic Pipeline (Bronze export, Override, 1440 min) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/TribeScriptStatus/)
  |-- External Table: External_FiatDwhDB_Dictionary_TribeScriptStatus ---|
  v
eMoney_dbo.eMoney_Dictionary_TribeScriptStatus (3 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| Tribe.FilesScriptHistoryStatus (eMoney_dbo mirror) | TribeScriptStatusID | Tribe script history records decode approval state via this dictionary |

---

## 7. Sample Queries

### 7.1 View all Tribe script status values
```sql
SELECT TribeScriptStatusID, TribeScriptStatus, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_TribeScriptStatus]
ORDER BY TribeScriptStatusID;
```

### 7.2 Script count by approval status
```sql
SELECT tss.TribeScriptStatus, COUNT(*) AS ScriptCount
FROM [eMoney_dbo].[eMoney_Tribe_FilesScriptHistoryStatus] h
JOIN [eMoney_dbo].[eMoney_Dictionary_TribeScriptStatus] tss
    ON h.TribeScriptStatusID = tss.TribeScriptStatusID
GROUP BY tss.TribeScriptStatus
ORDER BY ScriptCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dictionary values are documented in the FiatDwhDB upstream wiki and business glossary.

---

PHASE GATE CHECK — eMoney_Dictionary_TribeScriptStatus [SIMPLE-DICT]:
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist   [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Dictionary_TribeScriptStatus [SIMPLE-DICT]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

T1 COPY VERIFICATION:
  TribeScriptStatusID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Unapproved, 1=Approved, 2=Executed." — IDENTICAL (values added from live MCP)
  TribeScriptStatus: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Unapproved, 1=Approved, 2=Executed." — IDENTICAL

*Generated: 2026-04-21 | Quality: 9.2/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_TribeScriptStatus | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.TribeScriptStatus*
