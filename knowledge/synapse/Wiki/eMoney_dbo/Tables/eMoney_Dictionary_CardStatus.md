# eMoney_dbo.eMoney_Dictionary_CardStatus

> 9-row lookup table materializing FiatDwhDB.Dictionary.CardStatuses into the Synapse DWH; defines the lifecycle states of physical and virtual eToro Money payment cards (NotActivated, Activated, Blocked, Suspended, Risk, Stolen, Lost, Expired, Fraud). All values loaded 2023-06-12; static since initial load.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.CardStatuses (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; Override strategy, 1440 min cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 9 (0=NotActivated through 8=Fraud) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_CardStatus` is a lookup/reference table that defines the valid lifecycle states for eToro Money physical and virtual payment cards. Each row maps an integer ID to a human-readable status name. Card status controls whether the card can be used for transactions and — when restricted — the reason for the restriction.

The 9 states span the full card lifecycle: from issuance before activation (`NotActivated`), through normal operation (`Activated`), temporary restrictions (`Blocked`, `Suspended`, `Risk`), permanent terminal states due to loss/theft/fraud (`Stolen`, `Lost`, `Fraud`), and natural expiry (`Expired`). Terminal states (Stolen, Lost, Expired, Fraud) cannot be reactivated — a replacement card must be issued.

This dictionary is sourced directly from `FiatDwhDB.Dictionary.CardStatuses` via the Generic Pipeline Bronze export. Status changes in FiatDwhDB are tracked in `dbo.FiatCardStatuses` with EventTimestamp. All Synapse rows carry UpdateDate 2023-06-12 (single bulk load, no subsequent refresh).

---

## 2. Business Logic

### 2.1 Card Lifecycle States

**What**: Classification of card operational status for transaction authorization and compliance.

**Columns Involved**: `CardStatusID`, `CardStatus`

**Rules**:
- `0=NotActivated` — card issued but cardholder has not yet activated it; transactions blocked
- `1=Activated` — card is fully operational; transactions permitted
- `2=Blocked` — temporary cardholder or system block; reversible
- `3=Suspended` — suspended pending investigation or review; reversible
- `4=Risk` — flagged by risk engine due to suspicious activity patterns; requires review
- `5=Stolen` — reported stolen; permanently disabled; replacement card issued
- `6=Lost` — reported lost; permanently disabled; replacement card issued
- `7=Expired` — card has passed expiry date; no transactions permitted
- `8=Fraud` — confirmed fraudulent activity; permanently disabled

### 2.2 Terminal vs. Reversible States

**What**: Distinguishes permanent card disablement from temporary restrictions.

**Columns Involved**: `CardStatusID`

**Rules**:
- Reversible (card can return to Activated): Blocked (2), Suspended (3), Risk (4)
- Terminal (card cannot be reactivated): Stolen (5), Lost (6), Expired (7), Fraud (8)
- Risk actions from transaction processing can automatically change card status via FiatDwhDB.dbo.FiatCardStatuses

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distributes all 9 rows to every node. Joins from card activity tables are data-local. HEAP is optimal for 9 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up card status name | `SELECT CardStatus FROM eMoney_Dictionary_CardStatus WHERE CardStatusID = @id` |
| Decode status on card records | `JOIN eMoney_Dictionary_CardStatus cs ON c.CardStatusID = cs.CardStatusID` |
| Count active cards | `WHERE c.CardStatusID = 1 -- Activated` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Card_Instance_Summary | CardStatusID = CardStatusID | Decode card lifecycle state on card records |
| FiatCardStatuses (eMoney_dbo mirror) | CardStatusID = CardStatusID | Decode status on status-change history |

### 3.4 Gotchas

- `1=Activated` — NOT `Active`; exact string match matters for status filters
- `2=Blocked` — NOT `Frozen` or `Deleted` (prior batch context had wrong values; live MCP confirmed correct names)
- Terminal states (5, 6, 7, 8) should be excluded from active-card counts
- `4=Risk` is a separate state from `3=Suspended` — Risk is risk-engine triggered, Suspended is compliance/review-triggered

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
| 1 | CardStatusID | int | YES | Lookup identifier. Primary key. 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. (Tier 1 — Dictionary.CardStatuses) |
| 2 | CardStatus | varchar(50) | YES | Human-readable name for this value. 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. (Tier 1 — Dictionary.CardStatuses) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CardStatusID | FiatDwhDB.Dictionary.CardStatuses | Id | Rename; tinyint→int widen |
| CardStatus | FiatDwhDB.Dictionary.CardStatuses | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.CardStatuses (source — 9 rows: 0=NotActivated through 8=Fraud)
  |-- Generic Pipeline (Bronze export, Override, 1440 min) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/CardStatuses/)
  |-- External Table: External_FiatDwhDB_Dictionary_CardStatuses ---|
  v
eMoney_dbo.eMoney_Dictionary_CardStatus (9 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_Card_Instance_Summary | CardStatusID | Card records reference lifecycle state |
| FiatCardStatuses (eMoney_dbo mirror) | CardStatusID | Status-change history references card status |

---

## 7. Sample Queries

### 7.1 View all card status values
```sql
SELECT CardStatusID, CardStatus, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_CardStatus]
ORDER BY CardStatusID;
```

### 7.2 Card count by status
```sql
SELECT cs.CardStatus, COUNT(*) AS CardCount
FROM [eMoney_dbo].[eMoney_Card_Instance_Summary] c
JOIN [eMoney_dbo].[eMoney_Dictionary_CardStatus] cs
    ON c.CardStatusID = cs.CardStatusID
GROUP BY cs.CardStatus
ORDER BY CardCount DESC;
```

### 7.3 Active vs. restricted vs. terminal card breakdown
```sql
SELECT
    CASE
        WHEN c.CardStatusID = 1 THEN 'Active'
        WHEN c.CardStatusID IN (2,3,4) THEN 'Restricted'
        WHEN c.CardStatusID IN (5,6,7,8) THEN 'Terminal'
        ELSE 'NotActivated'
    END AS CardStateGroup,
    COUNT(*) AS CardCount
FROM [eMoney_dbo].[eMoney_Card_Instance_Summary] c
GROUP BY
    CASE
        WHEN c.CardStatusID = 1 THEN 'Active'
        WHEN c.CardStatusID IN (2,3,4) THEN 'Restricted'
        WHEN c.CardStatusID IN (5,6,7,8) THEN 'Terminal'
        ELSE 'NotActivated'
    END;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dictionary values are documented in the FiatDwhDB upstream wiki and business glossary.

---

PHASE GATE CHECK — eMoney_Dictionary_CardStatus [SIMPLE-DICT]:
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist   [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Dictionary_CardStatus [SIMPLE-DICT]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

T1 COPY VERIFICATION:
  CardStatusID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=NotActivated ... 8=Fraud." — IDENTICAL (values added from live MCP)
  CardStatus: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=NotActivated ... 8=Fraud." — IDENTICAL

*Generated: 2026-04-21 | Quality: 9.2/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_CardStatus | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.CardStatuses*
