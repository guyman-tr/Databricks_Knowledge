# eMoney_dbo.eMoney_Dictionary_AccountStatus

> 3-row lookup table mapping account lifecycle state identifiers to names for the eToro Money fiat platform; sourced from FiatDwhDB.Dictionary.AccountStatuses via Generic Pipeline Bronze export. Static — last loaded 2023-06-12.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.AccountStatuses (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; matches FiatDwhDB update cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 3 (0=Active, 1=Suspended, 2=Deleted) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_AccountStatus` is a lookup/reference table that defines the valid values for account lifecycle state in the eToro Money fiat platform. Each row maps an integer ID to a human-readable status name. The three states — **Active**, **Suspended**, and **Deleted** — represent the full lifecycle of a fiat currency balance account: **Active** for normal operation, **Suspended** for temporarily restricted accounts (e.g., during AML review or compliance holds), and **Deleted** for permanently closed accounts.

This dictionary is sourced directly from `FiatDwhDB.Dictionary.AccountStatuses` via the Generic Pipeline Bronze export. It is referenced by `eMoney_Dim_Account.AccountStatusID` and `eMoneyClientBalance.AccountStatus` throughout the eMoney analytics layer. The table is effectively static — the last UpdateDate is 2023-06-12.

---

## 2. Business Logic

### 2.1 Account Lifecycle States

**What**: Three-state lifecycle for eToro Money fiat currency balance accounts.

**Columns Involved**: `AccountStatusID`, `AccountStatus`

**Rules**:
- `0=Active` — account is in normal operation; can transact
- `1=Suspended` — account temporarily restricted; may be under compliance review or hold
- `2=Deleted` — account permanently closed; typically corresponds to `IsCancelledAccount=1` in `eMoney_Dim_Account`
- Transitions are managed in FiatDwhDB and propagated to DWH via Generic Pipeline

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution broadcasts the 3-row table to all distributions. Joins from large eMoney tables (Dim_Account, Risk_Portfolio) are data-local. HEAP is optimal.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode status for a set of accounts | `JOIN eMoney_Dictionary_AccountStatus s ON a.AccountStatusID = s.AccountStatusID` |
| Count active accounts | `WHERE a.AccountStatusID = 0` |
| Exclude deleted accounts | `WHERE a.AccountStatusID <> 2` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Dim_Account | AccountStatusID = AccountStatusID | Decode current account status |
| eMoney_Risk_Portfolio | AccountStatusID = AccountStatusID | Status context in AML/risk view |

### 3.4 Gotchas

- `0=Active` is the dominant status; non-zero values require special handling in retention/funnel calculations
- `eMoney_Dim_Account.AccountStatusDescription` stores the text inline (no join needed) — this dictionary is useful for GROUP BY / WHERE filters using the integer key
- Status changes are propagated incrementally by Generic Pipeline; there may be a short lag vs live FiatDwhDB

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
| 1 | AccountStatusID | int | YES | Lookup identifier. Primary key. 0=Active, 1=Suspended, 2=Deleted. (Tier 1 — Dictionary.AccountStatuses) |
| 2 | AccountStatus | varchar(50) | YES | Human-readable name for this value. 0=Active, 1=Suspended, 2=Deleted. (Tier 1 — Dictionary.AccountStatuses) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AccountStatusID | FiatDwhDB.Dictionary.AccountStatuses | Id | Rename; tinyint→int widen |
| AccountStatus | FiatDwhDB.Dictionary.AccountStatuses | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.AccountStatuses (source — 3 rows: 0=Active, 1=Suspended, 2=Deleted)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_Dictionary_AccountStatuses ---|
  v
eMoney_dbo.eMoney_Dictionary_AccountStatus (3 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_Dim_Account | AccountStatusID | Account dimension references lifecycle state |
| eMoney_Risk_Portfolio | AccountStatusID | Risk portfolio snapshot carries account status |
| eMoneyClientBalance | AccountStatus | Balance reconciliation references account status name |

---

## 7. Sample Queries

### 7.1 View all status values
```sql
SELECT AccountStatusID, AccountStatus, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_AccountStatus]
ORDER BY AccountStatusID;
```

### 7.2 Account count by status
```sql
SELECT s.AccountStatus, COUNT(*) AS AccountCount
FROM [eMoney_dbo].[eMoney_Dim_Account] a
JOIN [eMoney_dbo].[eMoney_Dictionary_AccountStatus] s
    ON a.AccountStatusID = s.AccountStatusID
GROUP BY s.AccountStatus
ORDER BY AccountCount DESC;
```

### 7.3 Active eToro Money account risk snapshot
```sql
SELECT a.CID, a.Entity, r.OverallRiskScore
FROM [eMoney_dbo].[eMoney_Risk_Portfolio] r
JOIN [eMoney_dbo].[eMoney_Dim_Account] a ON r.CurrencyBalanceID = a.CurrencyBalanceID
WHERE r.ReportDateID = CONVERT(int, CONVERT(varchar, GETDATE()-1, 112))
  AND a.AccountStatusID = 0  -- Active only
ORDER BY r.OverallRiskScore DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Status lifecycle definitions are documented in the FiatDwhDB upstream wiki.

---

T1 COPY VERIFICATION:
  AccountStatusID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Active, 1=Suspended, 2=Deleted." — IDENTICAL (values added from live data)
  AccountStatus: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Active, 1=Suspended, 2=Deleted." — IDENTICAL (values added from live data)

*Generated: 2026-04-20 | Quality: 9.1/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_AccountStatus | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.AccountStatuses*
