# eMoney_Tribe.SettlementsTransactions_RiskActions-236807

> 2.9M-row table storing risk-action flags for card settlement transactions from the eMoney platform (FiatDwhDB.Tribe on prod-banking). Each row represents the set of automated risk responses triggered during transaction processing. Data spans 2023-12-20 to 2026-04-25, loaded daily via Generic Pipeline #539 (Append strategy).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_Tribe |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 (prod-banking) via Generic Pipeline #539 |
| **Refresh** | Daily (every 1440 min), Append strategy, parquet format |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (4 NCIs: ClusteredIndex_ST_236807 on @Id, ClusteredIndex_ST_236807_c2 on FK column, XI_partition_date on partition_date, idx_236807_Id on @Id) |
| **UC Target** | `emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export |

---

## 1. Business Meaning

This table captures the risk-action decisions applied to settlement transactions processed through the eMoney (Tribe) card-processing platform. Each row records whether specific automated risk responses were triggered for a given transaction, such as marking it as suspicious, changing card or account status, rejecting the transaction, or notifying the cardholder.

The table contains ~2.87M rows spanning from December 2023 to April 2026. Each record is keyed by `@Id` (a GUID that also serves as the FK to the parent `SettlementsTransactions_SettlementTransaction-637239` table). The vast majority of risk-action flags are `0` (not triggered); for example, only 1,179 of ~2.87M rows have `MarkTransactionAsSuspicious = 1` and only 230 have `ChangeCardStatusToRisk = 1`.

Data is loaded daily via Generic Pipeline (Append strategy) from `FiatDwhDB.Tribe` on the `prod-banking` server. There is no writer SP — the pipeline copies data directly from the production banking system. The table is consumed downstream by `SP_eMoney_Reconciliation_ETLs`, which LEFT JOINs it to `SettlementsTransactions_SettlementTransaction-637239` to build the `ETL_SettlementsTransactions` reconciliation dataset.

Approximately 51K rows (~1.8%) have empty-string values across all flag columns, suggesting records ingested before the risk-action fields were populated or transactions where no risk evaluation was performed.

---

## 2. Business Logic

### 2.1 Risk-Action Boolean Flags

**What**: Seven columns represent discrete automated risk responses that can be triggered during settlement transaction processing.
**Columns Involved**: MarkTransactionAsSuspicious, NotifyCardholderBySendingTAIsNotification, ChangeCardStatusToRisk, ChangeAccountStatusToSuspended, RejectTransaction, ChangeAccountStatusToReceiveOnly, ChangeAccountStatusToSpendOnly
**Rules**:
- Each flag is stored as varchar but holds boolean-like values: `0` (not triggered), `1` (triggered), or empty string (not evaluated / pre-population).
- Flags are independent — multiple actions can be triggered on the same transaction.
- `MarkTransactionAsSuspicious` is the most commonly triggered action (1,179 occurrences), followed by `ChangeCardStatusToRisk` (230 occurrences).
- `NotifyCardholderBySendingTAIsNotification`, `ChangeAccountStatusToSuspended`, and `RejectTransaction` show zero `1` values in the current dataset — all are either `0` or empty.
- `ChangeAccountStatusToReceiveOnly` and `ChangeAccountStatusToSpendOnly` have a higher proportion of empty-string values (~34%) compared to the other flags (~1.8%), suggesting these columns were added later.

### 2.2 Transaction-to-Risk-Actions Relationship

**What**: Each risk-action record is linked 1:1 to a settlement transaction via the `@Id` GUID.
**Columns Involved**: @Id, @SettlementsTransactions_SettlementTransaction@Id-637239
**Rules**:
- `@Id` and `@SettlementsTransactions_SettlementTransaction@Id-637239` contain identical GUID values in the sampled data, indicating the risk-action record shares the same identifier as its parent settlement transaction.
- The relationship is enforced via NCI indexes and used in the LEFT JOIN in `SP_eMoney_Reconciliation_ETLs`.

### 2.3 ETL Date Partitioning

**What**: Three date-granularity columns and a partition_date column are added by the Generic Pipeline for partitioning and incremental load support.
**Columns Involved**: etr_y, etr_ym, etr_ymd, partition_date
**Rules**:
- `etr_y` = year of `Created` (e.g., "2023")
- `etr_ym` = year-month of `Created` (e.g., "2023-12")
- `etr_ymd` = year-month-day of `Created` (e.g., "2023-12-20"), matches `partition_date`
- `partition_date` = date-only cast of `Created`, indexed for efficient partition pruning

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table uses REPLICATE distribution (full copy on every compute node) with a HEAP storage structure. This is appropriate for a ~2.9M-row reference/flag table that is primarily joined to other eMoney_Tribe tables. Four NCIs exist: two on `@Id` (redundant), one on the FK column, and one on `partition_date`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many transactions triggered a specific risk action? | `SELECT MarkTransactionAsSuspicious, COUNT(*) FROM [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807] WHERE MarkTransactionAsSuspicious = '1' GROUP BY MarkTransactionAsSuspicious` |
| Which transactions had multiple risk actions triggered? | Filter rows where more than one flag column = '1' |
| Daily trend of risk actions | JOIN to partition_date, GROUP BY partition_date and flag columns |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239 | ON @Id = @Id | Parent settlement transaction details |
| eMoney_Tribe.SettlementsTransactions-333243 | Via SettlementTransaction-637239 | Root settlements batch record |
| eMoney_dbo.ETL_SettlementsTransactions | Downstream consumer | Reconciliation dataset built by SP_eMoney_Reconciliation_ETLs |

### 3.4 Gotchas

- **String-typed booleans**: All flag columns are `varchar(max)`, not `bit` or `int`. Compare with string `'1'` or `'0'`, not numeric values.
- **Empty strings vs NULL**: Empty-string values (`''`) represent unpopulated flags, not NULL. Filter with `WHERE col = '1'` rather than `WHERE col IS NOT NULL`.
- **Duplicate @Id indexes**: `ClusteredIndex_ST_236807` and `idx_236807_Id` are both NCIs on `@Id` — functionally redundant.
- **@Id = FK column**: In sampled data, `@Id` and `@SettlementsTransactions_SettlementTransaction@Id-637239` hold identical GUIDs. This is expected — the risk-action sub-record inherits the parent transaction's identifier.
- **Late-added columns**: `ChangeAccountStatusToReceiveOnly` and `ChangeAccountStatusToSpendOnly` have ~34% empty strings vs ~1.8% for the other flags, indicating they were added to the source schema later.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | ETL-computed or framework-generated column |
| Tier 3 | Grounded in DDL + SP code + data evidence, no upstream wiki available |
| Tier 4 | Inferred from name only (banned for this object) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | @Id | varchar(40) | YES | Unique identifier (GUID) for the risk-action record. Matches the parent settlement transaction ID in SettlementsTransactions_SettlementTransaction-637239. Indexed (ClusteredIndex_ST_236807, idx_236807_Id). Used as JOIN key in SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe) |
| 2 | @SettlementsTransactions_SettlementTransaction@Id-637239 | varchar(40) | YES | Foreign key GUID linking to the parent settlement transaction record in eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239. Contains identical values to @Id in sampled data. Indexed (ClusteredIndex_ST_236807_c2). (Tier 3 — FiatDwhDB.Tribe) |
| 3 | MarkTransactionAsSuspicious | varchar(max) | YES | Boolean flag indicating whether the transaction was marked as suspicious by automated risk evaluation. Values: '0' = not triggered (98.2%), '1' = triggered (1,179 rows), '' = not evaluated (~1.8%). Read by SP_eMoney_Reconciliation_ETLs into ETL_SettlementsTransactions. (Tier 3 — FiatDwhDB.Tribe) |
| 4 | NotifyCardholderBySendingTAIsNotification | varchar(max) | YES | Boolean flag indicating whether a Transaction Alert (TA) notification was sent to the cardholder. Values: '0' = not triggered (98.2%), '' = not evaluated (~1.8%). No '1' values observed in current data. Read by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe) |
| 5 | ChangeCardStatusToRisk | varchar(max) | YES | Boolean flag indicating whether the card status was changed to 'Risk' as an automated response. Values: '0' = not triggered (98.2%), '1' = triggered (230 rows), '' = not evaluated (~1.8%). Read by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe) |
| 6 | ChangeAccountStatusToSuspended | varchar(max) | YES | Boolean flag indicating whether the account status was changed to 'Suspended' as an automated response. Values: '0' = not triggered (98.2%), '' = not evaluated (~1.8%). No '1' values observed in current data. Read by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe) |
| 7 | RejectTransaction | varchar(max) | YES | Boolean flag indicating whether the transaction was rejected by automated risk evaluation. Values: '0' = not triggered (98.2%), '' = not evaluated (~1.8%). No '1' values observed in current data. Read by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe) |
| 8 | etr_y | varchar(max) | YES | Year component extracted from Created timestamp by the Generic Pipeline ETL framework. String format (e.g., '2023'). Used for date-based partitioning. (Tier 2 — Generic Pipeline) |
| 9 | etr_ym | varchar(max) | YES | Year-month component extracted from Created timestamp by the Generic Pipeline ETL framework. String format (e.g., '2023-12'). Used for date-based partitioning. (Tier 2 — Generic Pipeline) |
| 10 | etr_ymd | varchar(max) | YES | Year-month-day component extracted from Created timestamp by the Generic Pipeline ETL framework. String format (e.g., '2023-12-20'). Matches partition_date values. (Tier 2 — Generic Pipeline) |
| 11 | SynapseUpdateDate | datetime | YES | Timestamp recording when the row was last loaded or updated in Synapse. Set by the Generic Pipeline at ingestion time. (Tier 2 — Generic Pipeline) |
| 12 | Created | datetime2(7) | YES | Timestamp of when the risk-action record was created in the source system (FiatDwhDB.Tribe). Used as the incremental load watermark in SP_eMoney_Reconciliation_ETLs and as the basis for etr_* partition columns. Range: 2023-12-20 to 2026-04-25. (Tier 3 — FiatDwhDB.Tribe) |
| 13 | partition_date | date | YES | Date-only value derived from Created by the Generic Pipeline. Indexed (XI_partition_date) for efficient partition pruning on date-range queries. Values match etr_ymd. (Tier 2 — Generic Pipeline) |
| 14 | ChangeAccountStatusToReceiveOnly | varchar(max) | YES | Boolean flag indicating whether the account status was changed to 'Receive Only' as an automated risk response. Values: '0' = not triggered (66.2%), '' = not evaluated (~33.8%). No '1' values observed. Added to source schema later than the original flag columns (higher empty-string rate). Not read by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe) |
| 15 | ChangeAccountStatusToSpendOnly | varchar(max) | YES | Boolean flag indicating whether the account status was changed to 'Spend Only' as an automated risk response. Values: '0' = not triggered (66.2%), '' = not evaluated (~33.8%). No '1' values observed. Added to source schema later than the original flag columns (higher empty-string rate). Not read by SP_eMoney_Reconciliation_ETLs. (Tier 3 — FiatDwhDB.Tribe) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| @Id | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | @Id | Passthrough |
| @SettlementsTransactions_SettlementTransaction@Id-637239 | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | @SettlementsTransactions_SettlementTransaction@Id-637239 | Passthrough |
| MarkTransactionAsSuspicious | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | MarkTransactionAsSuspicious | Passthrough |
| NotifyCardholderBySendingTAIsNotification | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | NotifyCardholderBySendingTAIsNotification | Passthrough |
| ChangeCardStatusToRisk | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | ChangeCardStatusToRisk | Passthrough |
| ChangeAccountStatusToSuspended | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | ChangeAccountStatusToSuspended | Passthrough |
| RejectTransaction | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | RejectTransaction | Passthrough |
| etr_y | Generic Pipeline | Created | YEAR extraction |
| etr_ym | Generic Pipeline | Created | Year-month extraction |
| etr_ymd | Generic Pipeline | Created | Year-month-day extraction |
| SynapseUpdateDate | Generic Pipeline | — | GETDATE() at load |
| Created | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | Created | Passthrough |
| partition_date | Generic Pipeline | Created | CAST AS DATE |
| ChangeAccountStatusToReceiveOnly | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | ChangeAccountStatusToReceiveOnly | Passthrough |
| ChangeAccountStatusToSpendOnly | FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 | ChangeAccountStatusToSpendOnly | Passthrough |

### 5.2 ETL Pipeline

```
FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 (prod-banking)
  |-- Generic Pipeline #539 (Append, daily, parquet) ---|
  v
Bronze Data Lake: Bronze/FiatDwhDB/Tribe/SettlementsTransactions_RiskActions-236807/
  |-- Synapse COPY / External Table ---|
  v
eMoney_Tribe.SettlementsTransactions_RiskActions-236807 (2.87M rows, REPLICATE)
  |-- SP_eMoney_Reconciliation_ETLs (LEFT JOIN, reads 5 flag columns) ---|
  v
eMoney_dbo.ETL_SettlementsTransactions (reconciliation dataset)
  |-- Generic Pipeline (Bronze export) ---|
  v
emoney.bronze_fiatdwhdb_tribe_settlementstransactions_riskactions-236807 (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| @SettlementsTransactions_SettlementTransaction@Id-637239 | eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239 | Parent settlement transaction (1:1 on @Id) |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| @Id | eMoney_dbo.SP_eMoney_Reconciliation_ETLs | LEFT JOIN reads 5 risk-action flags into ETL_SettlementsTransactions |

---

## 7. Sample Queries

### 7.1 Count Transactions by Risk Action Type

```sql
SELECT
    SUM(CASE WHEN MarkTransactionAsSuspicious = '1' THEN 1 ELSE 0 END) AS suspicious,
    SUM(CASE WHEN ChangeCardStatusToRisk = '1' THEN 1 ELSE 0 END) AS card_risk,
    SUM(CASE WHEN ChangeAccountStatusToSuspended = '1' THEN 1 ELSE 0 END) AS suspended,
    SUM(CASE WHEN RejectTransaction = '1' THEN 1 ELSE 0 END) AS rejected,
    SUM(CASE WHEN NotifyCardholderBySendingTAIsNotification = '1' THEN 1 ELSE 0 END) AS notified
FROM [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807]
WHERE partition_date >= '2026-01-01'
```

### 7.2 Daily Risk-Action Trend

```sql
SELECT
    partition_date,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN MarkTransactionAsSuspicious = '1' THEN 1 ELSE 0 END) AS suspicious_count,
    SUM(CASE WHEN ChangeCardStatusToRisk = '1' THEN 1 ELSE 0 END) AS card_risk_count
FROM [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807]
WHERE partition_date >= DATEADD(MONTH, -3, GETDATE())
GROUP BY partition_date
ORDER BY partition_date
```

### 7.3 Join Risk Actions to Settlement Transaction Details

```sql
SELECT
    st.TransactionId,
    st.MerchantName,
    ra.MarkTransactionAsSuspicious,
    ra.ChangeCardStatusToRisk,
    ra.RejectTransaction,
    ra.Created
FROM [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807] ra
INNER JOIN [eMoney_Tribe].[SettlementsTransactions_SettlementTransaction-637239] st
    ON ra.[@Id] = st.[@Id]
WHERE ra.MarkTransactionAsSuspicious = '1'
    OR ra.ChangeCardStatusToRisk = '1'
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 13/14*
*Tiers: 0 T1, 4 T2, 11 T3, 0 T4, 0 T5 | Elements: 15/15, Logic: 7/10, Lineage: 8/10*
*Object: eMoney_Tribe.SettlementsTransactions_RiskActions-236807 | Type: Table | Production Source: FiatDwhDB.Tribe.SettlementsTransactions_RiskActions-236807 (prod-banking)*
