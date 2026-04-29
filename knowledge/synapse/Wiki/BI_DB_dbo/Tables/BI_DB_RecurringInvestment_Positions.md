# BI_DB_dbo.BI_DB_RecurringInvestment_Positions

> 118,880-row mapping table linking trading positions (PositionID) to their originating recurring investment deposits (DepositID). Populated by `SP_RecurringInvestment_Positions` via TRUNCATE+INSERT from an external parquet source. Identifies positions that were automatically opened by the recurring investment feature.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | RecurringInvestment service (external parquet) via `SP_RecurringInvestment_Positions` |
| **Refresh** | Daily (TRUNCATE+INSERT — full refresh) |
| **Synapse Distribution** | HASH(PositionID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~118,880 (1:1 with PositionID) |

---

## 1. Business Meaning

`BI_DB_RecurringInvestment_Positions` is a lightweight mapping table that identifies which trading positions were opened by the automatic recurring investment feature. Each row links one position (PositionID) to the deposit (DepositID) that triggered it.

The recurring investment feature allows customers to set up automatic periodic investments. When a recurring deposit executes, the system automatically opens positions according to the customer's configured allocation. This table captures that linkage, enabling analysts to distinguish organically-opened positions from automatically-opened ones.

The data is sourced from an external parquet file (`External_bi_db_recurringinvestment_positions_parquet`) which is loaded from the data lake. The SP performs a simple TRUNCATE+INSERT with no transformations — a pure passthrough from the external table.

---

## 2. Business Logic

### 2.1 Position-to-Deposit Mapping

**What**: 1:1 mapping between positions and their triggering recurring deposits.
**Columns Involved**: `PositionID`, `DepositID`
**Rules**:
- Each PositionID appears exactly once (118,880 unique positions)
- Multiple PositionIDs can map to the same DepositID (one deposit → multiple positions via allocation)
- 55,986 distinct DepositIDs → average ~2.1 positions per deposit

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(PositionID) with CLUSTERED COLUMNSTORE INDEX — optimized for JOIN on PositionID. Co-located with any table also distributed on PositionID (e.g., Dim_Position).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is this position from recurring investment? | `WHERE PositionID IN (SELECT PositionID FROM BI_DB_RecurringInvestment_Positions)` |
| How many positions per recurring deposit? | `SELECT DepositID, COUNT(*) FROM ... GROUP BY DepositID` |
| Total value of recurring investment positions | `JOIN Dim_Position dp ON rip.PositionID = dp.PositionID` and sum Amount |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | `PositionID = PositionID` | Full position details (CID, instrument, dates, amounts) |
| DWH_dbo.Fact_BillingDeposit | `DepositID = DepositID` | Deposit details (amount, date, payment method) |

### 3.4 Gotchas

- **TRUNCATE+INSERT means no history**: Only current recurring investment positions are present. Closed/removed recurring positions are not retained.
- **PositionID is bigint**: Match type when joining to Dim_Position (also bigint).
- **No CID column**: To filter by customer, join to Dim_Position first.
- **External source is opaque**: The parquet file originates from the RecurringInvestment service. No SSDT DDL exists for the source schema.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | YES | Trading position identifier opened by the recurring investment feature. FK to Dim_Position. Each PositionID appears once. (Tier 2 — SP_RecurringInvestment_Positions, RecurringInvestment service) |
| 2 | DepositID | int | YES | Recurring deposit identifier that triggered this position. FK to Fact_BillingDeposit. Multiple positions can share the same DepositID (one deposit → multiple allocated positions). (Tier 2 — SP_RecurringInvestment_Positions, RecurringInvestment service) |
| 3 | UpdateDate | datetime | YES | GETDATE() at SP execution. All rows share the same value after each TRUNCATE+INSERT refresh. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| PositionID | RecurringInvestment service (parquet) | PositionID | passthrough |
| DepositID | RecurringInvestment service (parquet) | DepositID | passthrough |
| UpdateDate | (computed) | — | GETDATE() |

### 5.2 ETL Pipeline

```
RecurringInvestment service (production)
  |-- Data lake export (parquet) --|
  v
BI_DB_dbo.External_bi_db_recurringinvestment_positions_parquet
  |
  |-- SP_RecurringInvestment_Positions (daily TRUNCATE+INSERT)
  |   Pure passthrough — SELECT PositionID, DepositID, GETDATE()
  v
BI_DB_dbo.BI_DB_RecurringInvestment_Positions (118.9K rows, HASH(PositionID) CCI)
  |-- No UC target (Not_Migrated) --|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position (PositionID) | Position dimension — CID, instrument, dates, P&L |
| DepositID | DWH_dbo.Fact_BillingDeposit (DepositID) | Deposit fact — amount, date, payment method |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| (None documented) | Used as a filter/lookup to identify recurring investment positions |

---

## 7. Sample Queries

### 7.1 Recurring Investment Positions with Details

```sql
SELECT
    rip.PositionID,
    rip.DepositID,
    dp.CID,
    dp.InstrumentID,
    dp.Amount,
    dp.OpenDateID
FROM BI_DB_dbo.BI_DB_RecurringInvestment_Positions rip
JOIN DWH_dbo.Dim_Position dp ON rip.PositionID = dp.PositionID
```

### 7.2 Positions Per Recurring Deposit

```sql
SELECT
    DepositID,
    COUNT(*) AS Positions_Per_Deposit
FROM BI_DB_dbo.BI_DB_RecurringInvestment_Positions
GROUP BY DepositID
ORDER BY Positions_Per_Deposit DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 2 T2, 0 T3, 0 T4, 1 T5 | Elements: 3/3, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_RecurringInvestment_Positions | Type: Table | Production Source: RecurringInvestment service via SP_RecurringInvestment_Positions*
