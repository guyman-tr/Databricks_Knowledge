# eMoney_dbo.eMoney_Dictionary_TransactionStatus

> 6-row lookup table (Synapse; 8 rows in FiatDwhDB source) mapping fiat transaction lifecycle state identifiers to names; sourced from FiatDwhDB.Dictionary.TransactionStatuses via Generic Pipeline Bronze export. Currently missing statuses 6=Reserved and 7=Cancelled.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dictionary) |
| **Production Source** | FiatDwhDB.Dictionary.TransactionStatuses (Generic Pipeline Bronze export) |
| **Refresh** | Generic Pipeline (scheduled; matches FiatDwhDB update cadence) |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **Row Count** | 6 (live as of 2026-04-20; FiatDwhDB source has 8 — IDs 6 and 7 not yet propagated) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dictionary_TransactionStatus` is a lookup/reference table that defines the valid values for fiat transaction lifecycle state in the eToro Money platform. Each row maps an integer ID to a human-readable status name. Transactions flow through these states from authorization through settlement or failure; understanding these states is essential for reconciliation, AML monitoring, and customer-facing reporting.

As of 2026-04-20, the Synapse DWH table contains 6 of the 8 values defined in `FiatDwhDB.Dictionary.TransactionStatuses`. Statuses `6=Reserved` and `7=Cancelled` are defined in FiatDwhDB but have not been propagated to Synapse — any transactions with these statuses would appear with unmapped IDs. This is flagged in the review sidecar.

This dictionary is referenced by `eMoney_Dim_Transaction.TransactionStatusID`, `eMoney_Fact_Transaction_Status.TransactionStatusID`, and `eMoney_Calculated_Balance` analytics throughout the eMoney layer. Last loaded 2023-06-12.

---

## 2. Business Logic

### 2.1 Transaction Lifecycle States

**What**: Six confirmed states covering the full lifecycle of a fiat card or banking transaction.

**Columns Involved**: `TransactionStatusID`, `TransactionStatus`

**Rules**:
- `0=Failed` — authorization or processing failure; transaction did not complete
- `1=Authorized` — approved by Tribe/Mastercard but not yet settled; funds ring-fenced
- `2=Settled` — final settled state; funds transferred. **Used as the primary filter for financial calculations** (e.g., `WHERE TxStatusID=2` in SP_eMoney_Panel_FirstDates, SP_eMoney_Calculated_Balance)
- `3=Rejected` — rejected by the card scheme or banking rail
- `4=Returned` — transaction reversed/returned to sender
- `5=Expired` — authorization expired before settlement (typical window: 5-7 days)
- `6=Reserved` — defined in FiatDwhDB; **not yet in Synapse DWH**
- `7=Cancelled` — defined in FiatDwhDB; **not yet in Synapse DWH**

### 2.2 Settlement Filter Pattern

**What**: The most common analytical filter across eMoney_dbo tables is `TxStatusID=2` (Settled).

**Rules**:
- `eMoney_Fact_Transaction_Status` contains all status events; filter `WHERE TransactionStatusID=2` for financial analysis
- `eMoney_Dim_Transaction` (latest status per transaction) has a mix of statuses; verify the status you need
- `eMoney_Calculated_Balance` aggregates already pre-filter to `TxStatusID=2 AND HolderAmount<>0`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE — 6-row table broadcast to all distributions. Joins are data-local and essentially free.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode status for transaction analysis | `JOIN eMoney_Dictionary_TransactionStatus s ON f.TransactionStatusID = s.TransactionStatusID` |
| Count settled transactions only | `WHERE f.TransactionStatusID = 2` |
| Transaction funnel by status | `GROUP BY s.TransactionStatus ORDER BY COUNT(*) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Fact_Transaction_Status | TransactionStatusID = TransactionStatusID | Decode all status events |
| eMoney_Dim_Transaction | TransactionStatusID = TransactionStatusID | Decode latest transaction status |

### 3.4 Gotchas

- **Synapse has 6 rows; FiatDwhDB has 8**: IDs 6=Reserved and 7=Cancelled are not in Synapse. If production introduces these statuses at scale, the DWH table will have unmapped values until the Generic Pipeline propagates the missing rows
- `TxStatusID=2` (Settled) is the financial gold standard — all monetary calculations in the eMoney layer use this filter
- `0=Failed` and `3=Rejected` are both non-completions but have different business meanings (Failed = technical failure; Rejected = scheme-level decision)

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
| 1 | TransactionStatusID | int | YES | Lookup identifier. Primary key. 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired. Note: 6=Reserved and 7=Cancelled are defined in FiatDwhDB source but absent from this Synapse table. (Tier 1 — Dictionary.TransactionStatuses) |
| 2 | TransactionStatus | varchar(50) | YES | Human-readable name for this value. 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired. (Tier 1 — Dictionary.TransactionStatuses) |
| 3 | UpdateDate | datetime | YES | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| TransactionStatusID | FiatDwhDB.Dictionary.TransactionStatuses | Id | Rename; tinyint→int widen |
| TransactionStatus | FiatDwhDB.Dictionary.TransactionStatuses | Name | Rename; nvarchar→varchar(50) narrow |
| UpdateDate | ETL metadata | — | Populated by Generic Pipeline |

### 5.2 ETL Pipeline

```
FiatDwhDB.Dictionary.TransactionStatuses (source — 8 rows: 0=Failed through 7=Cancelled)
  |-- Generic Pipeline (Bronze export) ---|
  v
Bronze parquet (ADLS Gen2 Data Lake)
  |-- External Table: External_FiatDwhDB_Dictionary_TransactionStatuses ---|
  v
eMoney_dbo.eMoney_Dictionary_TransactionStatus (6 rows live — IDs 6/7 missing, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus
```

---

## 6. Relationships

### 6.1 References To

This object has no outgoing foreign key references.

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| eMoney_Fact_Transaction_Status | TransactionStatusID | All transaction status events |
| eMoney_Dim_Transaction | TransactionStatusID | Latest status per transaction |
| eMoney_Calculated_Balance | (via Fact_Transaction_Status) | Pre-filters to TxStatusID=2 |

---

## 7. Sample Queries

### 7.1 View all confirmed status values
```sql
SELECT TransactionStatusID, TransactionStatus, UpdateDate
FROM [eMoney_dbo].[eMoney_Dictionary_TransactionStatus]
ORDER BY TransactionStatusID;
```

### 7.2 Transaction volume by status (last 30 days)
```sql
SELECT s.TransactionStatus, COUNT(*) AS TxCount,
       SUM(f.HolderAmount) AS TotalAmount
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status] f
JOIN [eMoney_dbo].[eMoney_Dictionary_TransactionStatus] s
    ON f.TransactionStatusID = s.TransactionStatusID
WHERE f.OccurredDateID >= CONVERT(int, CONVERT(varchar, DATEADD(day,-30,GETDATE()), 112))
GROUP BY s.TransactionStatus
ORDER BY TxCount DESC;
```

### 7.3 Settlement rate check
```sql
SELECT
    SUM(CASE WHEN TransactionStatusID = 2 THEN 1 ELSE 0 END) AS Settled,
    COUNT(*) AS Total,
    CAST(100.0 * SUM(CASE WHEN TransactionStatusID = 2 THEN 1 ELSE 0 END) / COUNT(*) AS decimal(5,2)) AS SettlementPct
FROM [eMoney_dbo].[eMoney_Fact_Transaction_Status]
WHERE OccurredDateID >= CONVERT(int, CONVERT(varchar, DATEADD(day,-7,GETDATE()), 112));
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Transaction status lifecycle is documented in the FiatDwhDB upstream wiki.

---

T1 COPY VERIFICATION:
  TransactionStatusID: upstream "Lookup identifier. Primary key." → wiki "Lookup identifier. Primary key. 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired. Note: 6=Reserved and 7=Cancelled are defined in FiatDwhDB source but absent from this Synapse table." — IDENTICAL core description; gap note added as DWH note (not paraphrasing, adding factual discrepancy)
  TransactionStatus: upstream "Human-readable name for this value." → wiki "Human-readable name for this value. 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired." — IDENTICAL (values from live data added)

*Generated: 2026-04-20 | Quality: 9.2/10 | Phases: 7/14 (SIMPLE-DICT fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Sources: 8/10*
*Object: eMoney_dbo.eMoney_Dictionary_TransactionStatus | Type: Table (Dictionary) | Production Source: FiatDwhDB.Dictionary.TransactionStatuses*
