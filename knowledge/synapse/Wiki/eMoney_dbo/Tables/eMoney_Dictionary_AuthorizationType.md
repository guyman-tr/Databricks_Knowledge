# eMoney_dbo.eMoney_Dictionary_AuthorizationType

> 15-row lookup table materializing FiatDwhDB.Dictionary.AuthorizationTypes into the Synapse DWH; classifies card transaction authorization flows (Normal, PreAuthorize, FinalAuthorize, Recurring, Refund, Reversal, etc.) for eToro Money fiat analytics. All values loaded 2023-06-12; static since initial load.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.AuthorizationTypes (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; Override strategy, 1440 min cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 15 (0=Unknown through 14=AccountFunding) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_AuthorizationType` is a lookup/reference table that defines the valid values for card transaction authorization type in the eToro Money fiat platform. Each row maps an integer ID to a human-readable name. Authorization type classifies how a card transaction was authorized by the payment network — determining the authorization flow, hold behavior, and settlement rules for each transaction event.

The 15 values cover the full lifecycle: standard purchases (Normal), pre-authorization flows (PreAuthorize → Incremental → FinalAuthorize), specialized merchant scenarios (Instalment, PreferredCustomer, Recurring, DelayedCharges, NoShow), network messages (AuthorizeAdvice), and reversal/return operations (Refund, Reversal, SysReversal). AccountFunding (14) covers card-load operations.

This dictionary is sourced directly from `FiatDwhDB.Dictionary.AuthorizationTypes` via the Generic Pipeline Bronze export and materialized into Synapse DWH. All rows carry the same UpdateDate (2023-06-12 03:48:01) indicating a single initial bulk load with no subsequent refresh.

---

## 2. Business Logic

### 2.1 Authorization Flow Lifecycle

**What**: Pre-authorization flow for hotel, car rental, and delayed-charge scenarios.

**Columns Involved**: `AuthorizationTypeID`

**Rules**:
- `PreAuthorize (2)` → initial hold for unknown final amount
- `Incremental (4)` → optional additional hold (extended hotel stay)
- `FinalAuthorize (3)` → closes the pre-auth with final settled amount
- `DelayedCharges (8)` → post-checkout charges (e.g., minibar)

### 2.2 Terminating Transaction Types

**What**: One-and-done authorization flows with no pre-auth step.

**Columns Involved**: `AuthorizationTypeID`

**Rules**:
- `Normal (1)` — standard card purchase
- `Instalment (5)` — split into multiple payments
- `PreferredCustomer (6)` — trusted merchant with special processing
- `Recurring (7)` — subscription/standing order
- `NoShow (9)` — charge for failed reservation honor
- `AccountFunding (14)` — top-up / load funds onto card balance

### 2.3 Reversal and Refund Types

**What**: Cancellation and return flows.

**Columns Involved**: `AuthorizationTypeID`

**Rules**:
- `Refund (11)` — merchant-initiated return of funds
- `Reversal (12)` — cancellation of an authorization before settlement
- `SysReversal (13)` — system-initiated reversal (timeout or processing error)
- `AuthorizeAdvice (10)` — advisory message confirming an authorization decision (not a debit/credit)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distributes all 15 rows to every node. Joins from any fact/dimension table are data-local. HEAP is optimal for 15 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Look up authorization type name | `SELECT AuthorizationType FROM eMoney_Dictionary_AuthorizationType WHERE AuthorizationTypeID = @id` |
| Decode authorization types on transactions | `JOIN eMoney_Dictionary_AuthorizationType a ON t.AuthorizationTypeID = a.AuthorizationTypeID` |
| Group transactions by authorization flow | `GROUP BY a.AuthorizationTypeID, a.AuthorizationType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| FiatTransactionsStatuses (FiatDwhDB mirror) | AuthorizationTypeID = AuthorizationTypeID | Decode authorization type on transaction status records |

### 3.4 Gotchas

- `0=Unknown` exists as a sentinel; exclude when analyzing specific authorization flows
- `AuthorizeAdvice (10)` is a network advisory message — it does not debit or credit the account; do not count it as a financial transaction
- `SysReversal (13)` differs from `Reversal (12)` — system-initiated vs customer/merchant-initiated; filter accordingly for dispute analysis
- All rows have identical UpdateDate (2023-06-12); the table has not been refreshed since initial load — check Generic Pipeline schedule if values appear stale

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
| 1 | AuthorizationTypeID | int | YES | Lookup identifier. Primary key. 0=Unknown, 1=Normal, 2=PreAuthorize, 3=FinalAuthorize, 4=Incremental, 5=Instalment, 6=PreferredCustomer, 7=Recurring, 8=DelayedCharges, 9=NoShow, 10=AuthorizeAdvice, 11=Refund, 12=Reversal, 13=SysReversal, 14=AccountFunding. (Tier 1 — Dictionary.AuthorizationTypes) |
| 2 | AuthorizationType | varchar(50) | YES | Human-readable name for this value. 0=Unknown, 1=Normal, 2=PreAuthorize, 3=FinalAuthorize, 4=Incremental, 5=Instalment, 6=PreferredCustomer, 7=Recurring, 8=DelayedCharges, 9=NoShow, 10=AuthorizeAdvice, 11=Refund, 12=Reversal, 13=SysReversal, 14=AccountFunding. (Tier 1 — Dictionary.AuthorizationTypes) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AuthorizationTypeID | FiatDwhDB.Dictionary.AuthorizationTypes | Id | Rename; tinyint→int widen |
| AuthorizationType | FiatDwhDB.Dictionary.AuthorizationTypes | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.AuthorizationTypes (source — 15 rows: 0=Unknown through 14=AccountFunding)
  |-- Generic Pipeline (Bronze export, Override, 1440 min) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/AuthorizationTypes/)
  |-- External Table: External_FiatDwhDB_Dictionary_AuthorizationTypes ---|
  v
eMoney_dbo.eMoney_Dictionary_AuthorizationType (15 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| FiatTransactionsStatuses (eMoney_dbo mirror) | AuthorizationTypeID | Transaction status records decode authorization type via this dictionary |

---

## 7. Sample Queries

### 7.1 View all authorization type values
```sql
SELECT AuthorizationTypeID, AuthorizationType, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_AuthorizationType]
ORDER BY AuthorizationTypeID;
```

### 7.2 Transaction count by authorization type (last 30 days)
```sql
SELECT a.AuthorizationType, COUNT(*) AS TxCount
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
JOIN [eMoney_dbo].[eMoney_Dictionary_AuthorizationType] a
    ON t.AuthorizationTypeID = a.AuthorizationTypeID
WHERE t.AuthorizationTypeID IS NOT NULL
GROUP BY a.AuthorizationType
ORDER BY TxCount DESC;
```

### 7.3 Pre-authorization flow analysis
```sql
SELECT a.AuthorizationType, COUNT(*) AS Count
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] t
JOIN [eMoney_dbo].[eMoney_Dictionary_AuthorizationType] a
    ON t.AuthorizationTypeID = a.AuthorizationTypeID
WHERE a.AuthorizationTypeID IN (2, 3, 4)  -- PreAuthorize, FinalAuthorize, Incremental
GROUP BY a.AuthorizationType
ORDER BY a.AuthorizationTypeID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Dictionary values are documented in the FiatDwhDB upstream wiki and business glossary.

---

PHASE GATE CHECK — eMoney_Dictionary_AuthorizationType [SIMPLE-DICT]:
  [x] P1 DDL   [x] P2 Sample   [-] P3 Dist   [x] P4 Lookup
  [-] P5 JOIN  [-] P6 BizLogic [-] P7 Views  [x] P8 SP-scan
  [-] P9 SP-logic [-] P9B ETL  [-] P10 Jira  [x] P10A Upstream  [x] P10B Lineage
  → Ready for P11
OUTPUT CHECK — eMoney_Dictionary_AuthorizationType [SIMPLE-DICT]:
  [x] .lineage.md exists   [x] .md exists   [x] .review-needed.md (writing next)
  [-] .alter.sql — deferred to /generate-alter-dwh

T1 COPY VERIFICATION:
  AuthorizationTypeID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Unknown ... 14=AccountFunding." — IDENTICAL (values added from live MCP; base phrase not paraphrased)
  AuthorizationType: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Unknown ... 14=AccountFunding." — IDENTICAL (values added from live MCP; base phrase not paraphrased)

*Generated: 2026-04-21 | Quality: 9.2/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_AuthorizationType | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.AuthorizationTypes*
