# eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus

> 5-row lookup table materializing FiatDwhDB.Dictionary.CurrencyBalanceStatuses into the Synapse DWH; defines the operational states controlling money movement permissions on individual eToro Money currency balances (Active, ReceiveOnly, SpendOnly, Suspended, Blocked). All values loaded 2023-06-12; static since initial load.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.CurrencyBalanceStatuses (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; Override strategy, 1440 min cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 5 (0=Active through 4=Blocked) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_CurrencyBalanceStatus` is a lookup/reference table that defines the valid operational states for a specific currency balance within an eToro Money account. Each row maps an integer ID to a human-readable status name. Currency balance status controls what types of money movement are permitted for that balance — making it a key compliance and risk control mechanism.

The 5 states span from full operational access (`Active`) through partial restrictions (`ReceiveOnly`, `SpendOnly`) to complete freezes (`Suspended`, `Blocked`). `ReceiveOnly` and `SpendOnly` are partial restriction states used during account wind-down or migration scenarios. `Blocked` typically indicates a compliance or legal hold. Status changes in FiatDwhDB are tracked in `dbo.FiatCurrencyBalancesStatuses` with source and reason.

This dictionary is sourced from `FiatDwhDB.Dictionary.CurrencyBalanceStatuses` via Generic Pipeline Bronze export. All Synapse rows carry UpdateDate 2023-06-12 (single bulk load).

---

## 2. Business Logic

### 2.1 Balance Permission Matrix

**What**: Controls which types of money movement are permitted for each currency balance status.

**Columns Involved**: `CurrencyBalanceStatusID`

**Rules**:
- `0=Active` — full operational; can send and receive funds
- `1=ReceiveOnly` — incoming funds permitted; outgoing transactions blocked
- `2=SpendOnly` — can spend down existing balance; no new incoming funds
- `3=Suspended` — frozen; no inbound or outbound transactions permitted
- `4=Blocked` — blocked; typically due to compliance or legal hold

### 2.2 Wind-Down and Restriction Patterns

**What**: Partial restriction states used during account transition or closure.

**Columns Involved**: `CurrencyBalanceStatusID`

**Rules**:
- `ReceiveOnly (1)` and `SpendOnly (2)` are transitional states — accounts in wind-down receive inflows while spending down, or stop receiving while allowing existing balance to be spent
- `Blocked (4)` is a stronger hold than `Suspended (3)` — typically compliance/legal hold

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distributes all 5 rows to every node. Joins from balance tables are data-local. HEAP is optimal for 5 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up balance status name | `SELECT CurrencyBalanceStatus FROM eMoney_Dictionary_CurrencyBalanceStatus WHERE CurrencyBalanceStatusID = @id` |
| Filter for fully active balances | `WHERE CurrencyBalanceStatusID = 0` |
| Identify restricted balances | `WHERE CurrencyBalanceStatusID IN (1,2,3,4)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Dim_Account | CurrencyBalanceStatusID = CurrencyBalanceStatusID | Decode balance status on account records |
| FiatCurrencyBalancesStatuses (eMoney_dbo mirror) | CurrencyBalanceStatusID = CurrencyBalanceStatusID | Decode status on status-change history |

### 3.4 Gotchas

- `1=ReceiveOnly` and `2=SpendOnly` are NOT equivalent to `3=Suspended` — they still allow one direction of movement; do not group them with Suspended/Blocked in "fully restricted" counts
- `0=Active` (not `Active/Open`); ensure exact string match when filtering
- All rows have identical UpdateDate (2023-06-12); confirmed Generic Pipeline source is FiatDwhDB.Dictionary.CurrencyBalanceStatuses

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
| 1 | CurrencyBalanceStatusID | int | YES | Lookup identifier. Primary key. 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. (Tier 1 — Dictionary.CurrencyBalanceStatuses) |
| 2 | CurrencyBalanceStatus | varchar(50) | YES | Human-readable name for this value. 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. (Tier 1 — Dictionary.CurrencyBalanceStatuses) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CurrencyBalanceStatusID | FiatDwhDB.Dictionary.CurrencyBalanceStatuses | Id | Rename; tinyint→int widen |
| CurrencyBalanceStatus | FiatDwhDB.Dictionary.CurrencyBalanceStatuses | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.CurrencyBalanceStatuses (source — 5 rows: 0=Active through 4=Blocked)
  |-- Generic Pipeline (Bronze export, Override, 1440 min) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/CurrencyBalanceStatuses/)
  |-- External Table: External_FiatDwhDB_Dictionary_CurrencyBalanceStatuses ---|
  v
eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus (5 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_Dim_Account | CurrencyBalanceStatusID | Account dimension references currency balance status |
| FiatCurrencyBalancesStatuses (eMoney_dbo mirror) | CurrencyBalanceStatusID | Balance status-change history |

---

## 7. Sample Queries

### 7.1 View all currency balance status values
```sql
SELECT CurrencyBalanceStatusID, CurrencyBalanceStatus, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_CurrencyBalanceStatus]
ORDER BY CurrencyBalanceStatusID;
```

### 7.2 Account distribution by currency balance status
```sql
SELECT cbs.CurrencyBalanceStatus, COUNT(*) AS AccountCount
FROM [eMoney_dbo].[eMoney_Dim_Account] a
JOIN [eMoney_dbo].[eMoney_Dictionary_CurrencyBalanceStatus] cbs
    ON a.CurrencyBalanceStatusID = cbs.CurrencyBalanceStatusID
GROUP BY cbs.CurrencyBalanceStatus
ORDER BY AccountCount DESC;
```

### 7.3 Restricted balance breakdown
```sql
SELECT cbs.CurrencyBalanceStatus, COUNT(*) AS Count,
       CASE WHEN cbs.CurrencyBalanceStatusID IN (1,2) THEN 'Partial' ELSE 'Full' END AS RestrictionType
FROM [eMoney_dbo].[eMoney_Dim_Account] a
JOIN [eMoney_dbo].[eMoney_Dictionary_CurrencyBalanceStatus] cbs
    ON a.CurrencyBalanceStatusID = cbs.CurrencyBalanceStatusID
WHERE cbs.CurrencyBalanceStatusID > 0
GROUP BY cbs.CurrencyBalanceStatus, cbs.CurrencyBalanceStatusID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dictionary values are documented in the FiatDwhDB upstream wiki and business glossary.

---

PHASE GATE CHECK — eMoney_Dictionary_CurrencyBalanceStatus [SIMPLE-DICT]:
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist   [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Dictionary_CurrencyBalanceStatus [SIMPLE-DICT]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

T1 COPY VERIFICATION:
  CurrencyBalanceStatusID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Active ... 4=Blocked." — IDENTICAL
  CurrencyBalanceStatus: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Active ... 4=Blocked." — IDENTICAL

*Generated: 2026-04-21 | Quality: 9.2/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.CurrencyBalanceStatuses*
