# eMoney_Tribe.Authorizes_RiskActions-796100

> 3.8M-row raw Tribe child table storing risk action boolean flags for eToro Money UK Visa card authorization events, spanning 2023-12-20 to 2026-04-26. Ingested daily via Generic Pipeline (Append) from FiatDwhDB.Tribe on prod-banking. LEFT JOINed by `SP_eMoney_Reconciliation_ETLs` to enrich `eMoney_dbo.ETL_Authorize` with risk action outcomes.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 (prod-banking) via Generic Pipeline (Append, daily) |
| **Refresh** | Daily (1440 min), Append strategy |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (4 NCIs on @Authorizes_Authorize@Id-312243, @Id x2, partition_date) |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (raw) |

---

## 1. Business Meaning

This table is a **raw Bronze-layer child table** from the Tribe Payments platform, storing risk action outcomes triggered during card authorization processing for eToro Money UK Visa debit cards.

The table holds **~3.8M rows** spanning **2023-12-20 to 2026-04-26** (partition_date range). Data arrives daily via Generic Pipeline (Append strategy) from `FiatDwhDB.Tribe.Authorizes_RiskActions-796100` on the `prod-banking` server.

Each row corresponds 1:1 to an authorization event in the parent table `Authorizes_Authorize-312243`, linked via `@Id`. The table contains 7 boolean flag columns (stored as varchar "0"/"1") indicating which risk actions were triggered by Tribe's risk engine for each authorization. These flags include marking transactions as suspicious, notifying cardholders, changing card/account statuses, and rejecting transactions.

The downstream ETL stored procedure `SP_eMoney_Reconciliation_ETLs` (Reconciliation Table 03 -- Authorize) LEFT JOINs this table to `Authorizes_Authorize-312243` on `[@Id]` and selects 5 of the 7 risk action columns (MarkTransactionAsSuspicious, NotifyCardholderBySendingTAIsNotification, ChangeCardStatusToRisk, ChangeAccountStatusToSuspended, RejectTransaction) as passthrough into `eMoney_dbo.ETL_Authorize`. The two newer columns (ChangeAccountStatusToReceiveOnly, ChangeAccountStatusToSpendOnly) are not yet consumed by the SP.

---

## 2. Business Logic

### 2.1 Risk Action Boolean Flags

**What**: Each column represents a specific risk action that Tribe's risk engine can trigger on an authorization event.
**Columns Involved**: MarkTransactionAsSuspicious, NotifyCardholderBySendingTAIsNotification, ChangeCardStatusToRisk, ChangeAccountStatusToSuspended, RejectTransaction, ChangeAccountStatusToReceiveOnly, ChangeAccountStatusToSpendOnly
**Rules**:
- All flags stored as varchar: `0` = action not triggered, `1` = action triggered
- Most authorizations have all flags set to `0` (no risk action taken)
- MarkTransactionAsSuspicious is the most commonly triggered flag (~0.4% of recent authorizations)
- ChangeCardStatusToRisk is triggered on ~0.02% of authorizations
- ChangeAccountStatusToSuspended has zero triggers in 2026 data
- ChangeAccountStatusToReceiveOnly and ChangeAccountStatusToSpendOnly are newer columns, currently empty/unpopulated in observed data

### 2.2 Risk Action Categories

**What**: The flags fall into two logical groups based on what entity they affect.
**Columns Involved**: All 7 risk action columns
**Rules**:
- **Transaction-level actions**: MarkTransactionAsSuspicious, RejectTransaction, NotifyCardholderBySendingTAIsNotification -- affect only the current authorization
- **Account/card status changes**: ChangeCardStatusToRisk, ChangeAccountStatusToSuspended, ChangeAccountStatusToReceiveOnly, ChangeAccountStatusToSpendOnly -- change the persistent status of the card or account, affecting future transactions

### 2.3 Parent-Child Relationship

**What**: This table is a child of Authorizes_Authorize-312243, linked by @Id.
**Columns Involved**: @Id, @Authorizes_Authorize@Id-312243
**Rules**:
- @Id equals @Authorizes_Authorize@Id-312243 in all observed rows (1:1 mapping)
- The LEFT JOIN in SP_eMoney_Reconciliation_ETLs means authorizations without risk actions will have NULL risk action columns in ETL_Authorize

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **REPLICATE** distribution -- full copy on every compute node. Appropriate for this moderate-size child table (~3.8M rows).
- **HEAP** -- no clustered index. Four nonclustered indexes on @Authorizes_Authorize@Id-312243 (1 NCI), @Id (2 NCIs), and partition_date (1 NCI).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How often are risk actions triggered? | `WHERE partition_date >= ... GROUP BY MarkTransactionAsSuspicious, ChangeCardStatusToRisk` |
| Which authorizations were rejected? | `WHERE RejectTransaction = '1' AND partition_date >= ...` |
| Risk action trends over time | `GROUP BY partition_date, MarkTransactionAsSuspicious` with date filter |
| Full authorization with risk details | JOIN to Authorizes_Authorize-312243 on @Id |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.Authorizes_Authorize-312243 | `[@Id] = [@Id]` | Parent authorization record with transaction details |
| eMoney_Tribe.Authorizes-837045 | via parent table | File-level parent record |
| eMoney_Tribe.Authorizes_SecurityChecks-30662 | `[@Id] = [@Id]` | Sibling: security check results |
| eMoney_dbo.ETL_Authorize | downstream | Reconciled version built by SP_eMoney_Reconciliation_ETLs |

### 3.4 Gotchas

- **All risk action columns are `varchar(max)`** -- stored as "0"/"1" strings, not bit/int. Use string comparison (`= '1'`), not numeric.
- **Newer columns are empty**: ChangeAccountStatusToReceiveOnly and ChangeAccountStatusToSpendOnly exist in DDL but have no populated values in observed data (empty strings). They are not consumed by SP_eMoney_Reconciliation_ETLs.
- **@Id = @Authorizes_Authorize@Id-312243**: Both columns contain the same UUID in all observed rows. The FK column name encodes the parent table ID (`312243`).
- **NULL etr_* on some rows**: The etr_y/etr_ym/etr_ymd partition columns are NULL on some rows (visible in sample for rows created in mid-2024), likely from a period before the partition key was populated by the pipeline.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL transform logic |
| Tier 3 | Grounded in DDL + live data + SP code, no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(40) | YES | Unique risk action record identifier (UUID format). Primary key for this record. Indexed (2 NCIs). Used as the JOIN key to parent Authorizes_Authorize-312243 and sibling SecurityChecks tables. In practice, equals @Authorizes_Authorize@Id-312243. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 2 | @Authorizes_Authorize@Id-312243 | varchar(40) | YES | Foreign key to the parent Authorizes_Authorize-312243 table. Links this risk action record to its parent authorization event. Indexed. In practice, equals @Id (1:1 relationship). (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 3 | MarkTransactionAsSuspicious | varchar(max) | YES | Boolean flag (varchar '0'/'1') indicating whether Tribe's risk engine marked this authorization as suspicious. Most commonly triggered risk action (~0.4% of recent authorizations have value '1'). Consumed by SP_eMoney_Reconciliation_ETLs into ETL_Authorize. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 4 | NotifyCardholderBySendingTAIsNotification | varchar(max) | YES | Boolean flag (varchar '0'/'1') indicating whether a Transaction Alert (TAIs) notification was sent to the cardholder for this authorization. Consumed by SP_eMoney_Reconciliation_ETLs into ETL_Authorize. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 5 | ChangeCardStatusToRisk | varchar(max) | YES | Boolean flag (varchar '0'/'1') indicating whether the card status was changed to 'Risk' as a result of this authorization. Triggered on ~0.02% of recent authorizations. Consumed by SP_eMoney_Reconciliation_ETLs into ETL_Authorize. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 6 | ChangeAccountStatusToSuspended | varchar(max) | YES | Boolean flag (varchar '0'/'1') indicating whether the account status was changed to 'Suspended' as a result of this authorization. Zero triggers observed in 2026 data. Consumed by SP_eMoney_Reconciliation_ETLs into ETL_Authorize. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 7 | RejectTransaction | varchar(max) | YES | Boolean flag (varchar '0'/'1') indicating whether the transaction was rejected by Tribe's risk engine. Consumed by SP_eMoney_Reconciliation_ETLs into ETL_Authorize. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 8 | etr_y | varchar(max) | YES | ETL partition key -- year component (e.g., '2023'). Populated by the Generic Pipeline Bronze extraction process. NULL on some rows. (Tier 3 -Generic Pipeline) |
| 9 | etr_ym | varchar(max) | YES | ETL partition key -- year-month component (e.g., '2023-12'). Populated by the Generic Pipeline Bronze extraction process. NULL on some rows. (Tier 3 -Generic Pipeline) |
| 10 | etr_ymd | varchar(max) | YES | ETL partition key -- year-month-day component (e.g., '2023-12-20'). Populated by the Generic Pipeline Bronze extraction process. NULL on some rows. (Tier 3 -Generic Pipeline) |
| 11 | SynapseUpdateDate | datetime | YES | Timestamp when this row was last loaded/updated in Synapse by the Generic Pipeline. (Tier 3 -Generic Pipeline) |
| 12 | Created | datetime2(7) | YES | Record creation timestamp from the Tribe source system. Marks when this risk action record was created in Tribe. Used as the incremental load watermark in SP_eMoney_Reconciliation_ETLs. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 13 | partition_date | date | YES | Date-based partition key used by the Generic Pipeline for incremental loads. Indexed (NCI). Range: 2023-12-20 to 2026-04-26. (Tier 3 -Generic Pipeline) |
| 14 | ChangeAccountStatusToReceiveOnly | varchar(max) | YES | Boolean flag (varchar '0'/'1') indicating whether the account status was changed to 'Receive Only' as a result of this authorization. Added in a later schema revision. Currently unpopulated (empty strings in all observed data). Not consumed by SP_eMoney_Reconciliation_ETLs. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |
| 15 | ChangeAccountStatusToSpendOnly | varchar(max) | YES | Boolean flag (varchar '0'/'1') indicating whether the account status was changed to 'Spend Only' as a result of this authorization. Added in a later schema revision. Currently unpopulated (empty strings in all observed data). Not consumed by SP_eMoney_Reconciliation_ETLs. (Tier 3 -FiatDwhDB.Tribe.Authorizes_RiskActions-796100) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | @Id | Passthrough |
| @Authorizes_Authorize@Id-312243 | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | @Authorizes_Authorize@Id-312243 | Passthrough |
| MarkTransactionAsSuspicious | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | MarkTransactionAsSuspicious | Passthrough |
| NotifyCardholderBySendingTAIsNotification | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | NotifyCardholderBySendingTAIsNotification | Passthrough |
| ChangeCardStatusToRisk | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | ChangeCardStatusToRisk | Passthrough |
| ChangeAccountStatusToSuspended | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | ChangeAccountStatusToSuspended | Passthrough |
| RejectTransaction | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | RejectTransaction | Passthrough |
| etr_y | Generic Pipeline | etr_y | Pipeline-generated partition key |
| etr_ym | Generic Pipeline | etr_ym | Pipeline-generated partition key |
| etr_ymd | Generic Pipeline | etr_ymd | Pipeline-generated partition key |
| SynapseUpdateDate | Generic Pipeline | SynapseUpdateDate | Pipeline-generated timestamp |
| Created | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | Created | Passthrough |
| partition_date | Generic Pipeline | partition_date | Pipeline-generated partition key |
| ChangeAccountStatusToReceiveOnly | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | ChangeAccountStatusToReceiveOnly | Passthrough |
| ChangeAccountStatusToSpendOnly | FiatDwhDB.Tribe.Authorizes_RiskActions-796100 | ChangeAccountStatusToSpendOnly | Passthrough |

### 5.2 ETL Pipeline

```
Tribe Payments Risk Engine (eToro Money UK -- Visa authorization risk actions)
  |-- Tribe data export (daily files) ---|
  v
FiatDwhDB.Tribe.Authorizes_RiskActions-796100 (prod-banking)
  |-- Generic Pipeline (Append, daily 1440 min, parquet) ---|
  v
Bronze/FiatDwhDB/Tribe/Authorizes_RiskActions-796100/ (Data Lake)
  |-- Generic Pipeline Bronze load ---|
  v
eMoney_Tribe.Authorizes_RiskActions-796100 (Synapse, 3.8M rows, REPLICATE)
  |-- SP_eMoney_Reconciliation_ETLs (Reconciliation Table 03) ---|
  |   LEFT JOIN on [@Id] to Authorizes_Authorize-312243
  |   Selects: MarkTransactionAsSuspicious, NotifyCardholder..., ChangeCardStatus...,
  |            ChangeAccountStatus..., RejectTransaction
  v
eMoney_dbo.ETL_Authorize (reconciled authorization data)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_authorizes_riskactions-796100 (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @Authorizes_Authorize@Id-312243 | eMoney_Tribe.Authorizes_Authorize-312243 | Parent authorization event record (1:1 via @Id) |

### 6.2 Referenced By (other objects point to this)

| Related Object | Element | Description |
|---|---|---|
| eMoney_dbo.SP_eMoney_Reconciliation_ETLs | LEFT JOIN on @Id | Reads 5 risk action columns to build ETL_Authorize |
| eMoney_Tribe_tmp.Authorizes_RiskActions-796100_tmp | -- | Temporary staging copy of this table |

---

## 7. Sample Queries

### 7.1 Risk Action Trigger Rates (Last 30 Days)

```sql
SELECT
    SUM(CASE WHEN MarkTransactionAsSuspicious = '1' THEN 1 ELSE 0 END) AS suspicious_count,
    SUM(CASE WHEN ChangeCardStatusToRisk = '1' THEN 1 ELSE 0 END) AS card_risk_count,
    SUM(CASE WHEN ChangeAccountStatusToSuspended = '1' THEN 1 ELSE 0 END) AS acct_suspended_count,
    SUM(CASE WHEN RejectTransaction = '1' THEN 1 ELSE 0 END) AS rejected_count,
    COUNT(*) AS total_auths
FROM [eMoney_Tribe].[Authorizes_RiskActions-796100]
WHERE partition_date >= DATEADD(DAY, -30, GETDATE());
```

### 7.2 Daily Suspicious Transaction Trend

```sql
SELECT
    partition_date,
    SUM(CASE WHEN MarkTransactionAsSuspicious = '1' THEN 1 ELSE 0 END) AS suspicious_count,
    COUNT(*) AS total_auths
FROM [eMoney_Tribe].[Authorizes_RiskActions-796100]
WHERE partition_date >= '2026-01-01'
GROUP BY partition_date
ORDER BY partition_date DESC;
```

### 7.3 Authorization Details With Risk Actions

```sql
SELECT
    a.TransactionDateTime,
    a.TransactionAmount,
    a.MerchantName,
    a.ResponseCode,
    r.MarkTransactionAsSuspicious,
    r.ChangeCardStatusToRisk,
    r.RejectTransaction
FROM [eMoney_Tribe].[Authorizes_Authorize-312243] a
JOIN [eMoney_Tribe].[Authorizes_RiskActions-796100] r ON a.[@Id] = r.[@Id]
WHERE r.MarkTransactionAsSuspicious = '1'
  AND r.partition_date >= '2026-01-01'
ORDER BY a.TransactionDateTime DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this raw Tribe child table. Business context is derived from the Tribe Payments platform data model and the downstream reconciliation SP (`SP_eMoney_Reconciliation_ETLs`, referenced in Freshservice change #20353).

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 15 T3, 0 T4, 0 T5 | Elements: 15/15, Logic: 7/10, Lineage: 8/10*
*Object: eMoney_Tribe.Authorizes_RiskActions-796100 | Type: Table | Production Source: FiatDwhDB.Tribe (prod-banking, dormant upstream wiki)*
