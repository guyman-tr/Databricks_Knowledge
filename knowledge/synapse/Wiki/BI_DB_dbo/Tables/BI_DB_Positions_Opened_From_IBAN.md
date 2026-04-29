# BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN

> 2.98M-row mapping table linking positions opened directly from IBAN bank account deposits with their corresponding DepositID. Used for tracing which opened positions were funded via IBAN deposits. Sourced from an external finance BI output table, deduplicated via `Dim_Position` and `Fact_BillingDeposit` CID matching. Refreshed daily via `SP_Positions_Opened_From_IBAN` (TRUNCATE+INSERT).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `External_bi_output_finance_bi_db_positions_opened_from_iban_parquet` (external table) → deduplicated via `DWH_dbo.Dim_Position` + `DWH_dbo.Fact_BillingDeposit` |
| **Writer SP** | `BI_DB_dbo.SP_Positions_Opened_From_IBAN` (Guy Manova 2025-03-19, updated 2025-07-21) |
| **Refresh** | Daily, TRUNCATE+INSERT |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, delta, daily) |

---

## 1. Business Meaning

This is a **position-to-deposit linkage table** for IBAN-funded position openings. When a customer deposits funds from an IBAN bank account and opens a position directly from that deposit (rather than from the eToro wallet balance), this table records which PositionID was opened and which DepositID in the billing system corresponds to the funding.

The table has 2.98M rows and is fully refreshed daily (TRUNCATE+INSERT). The source is an external parquet file produced by the finance BI output pipeline (`External_bi_output_finance_bi_db_positions_opened_from_iban_parquet`). The same R&D design flaw deduplication applied to the companion `BI_DB_Positions_Closed_To_IBAN` table is applied here: child/mirror positions that incorrectly inherited parent deposit references are filtered out by JOINing through `Dim_Position` (for CID) and `Fact_BillingDeposit` (to verify CID matches the deposit record).

---

## 2. Business Logic

### 2.1 CID-Based Deduplication

**What**: Removes false linkages from mirror/child positions that inherit parent DepositIDs.
**Columns Involved**: PositionID, DepositID
**Rules**:
- External source provides raw PositionID-DepositID pairs
- JOIN to Dim_Position gets the real CID for each position
- JOIN to Fact_BillingDeposit verifies the CID matches the deposit's CID
- Only pairs where both the position and the deposit belong to the same customer survive

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(PositionID) distribution — optimal for PositionID-based JOINs. CLUSTERED COLUMNSTORE INDEX.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Find deposit for an IBAN-opened position | `WHERE PositionID = <id>` |
| All IBAN openings for a customer | JOIN to Dim_Position for CID, then filter |
| MIMO analysis with IBAN-opened positions | JOIN to BI_DB_Positions_Closed_To_IBAN for full IBAN lifecycle |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | PositionID = PositionID | Get position details, CID, instrument |
| DWH_dbo.Fact_BillingDeposit | DepositID = DepositID | Get deposit amount, status, funding type |
| BI_DB_Positions_Closed_To_IBAN | PositionID = PositionID | Link IBAN-opened to IBAN-closed positions |

### 3.4 Gotchas

- **No CID column** — must JOIN to Dim_Position to get the customer identifier
- **External source dependency** — the external parquet file is the ultimate source

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Description from SP code analysis |
| Tier 3 | Description from data sampling / parameter inference |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | YES | Trading position that was opened directly from an IBAN bank account deposit. Distribution key. Deduplicated via CID matching against Dim_Position and Fact_BillingDeposit. (Tier 2 — SP_Positions_Opened_From_IBAN) |
| 2 | DepositID | int | YES | Corresponding deposit record in the billing system (Fact_BillingDeposit). Links the opened position to its IBAN deposit funding transaction. (Tier 2 — SP_Positions_Opened_From_IBAN) |
| 3 | UpdateDate | datetime | YES | Row load timestamp. GETDATE() at insert time. (Tier 3 — SP_Positions_Opened_From_IBAN, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| PositionID | External_...opened_from_iban_parquet | PositionID | Passthrough (after CID dedup) |
| DepositID | External_...opened_from_iban_parquet | DepositID | Passthrough (after CID dedup) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
Finance BI Output (external parquet)
  |-- External_bi_output_finance_bi_db_positions_opened_from_iban_parquet
  |-- JOIN DWH_dbo.Dim_Position (CID for dedup)
  |-- JOIN DWH_dbo.Fact_BillingDeposit (CID + DepositID match)
  |-- TRUNCATE + INSERT, UpdateDate = GETDATE()
  v
BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN (2.98M rows)
  |-- Generic Pipeline (Override, delta, daily)
  v
general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position | FK — position details |
| DepositID | DWH_dbo.Fact_BillingDeposit | FK — deposit transaction details |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in the SSDT repo. Used for MIMO-to-position data JOINs in ad-hoc analysis.

---

## 7. Sample Queries

### 7.1 Deposit Details for IBAN-Opened Positions

```sql
SELECT o.PositionID, o.DepositID,
    dp.CID, dp.InstrumentID, dp.OpenOccurred,
    fbd.Amount AS DepositAmount, fbd.FundingTypeID
FROM BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN o
JOIN DWH_dbo.Dim_Position dp ON o.PositionID = dp.PositionID
JOIN DWH_dbo.Fact_BillingDeposit fbd ON o.DepositID = fbd.DepositID
WHERE dp.CID = 13944640
```

### 7.2 Full IBAN Lifecycle: Opened and Closed via IBAN

```sql
SELECT o.PositionID, o.DepositID, c.WithdrawPaymentID
FROM BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN o
JOIN BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN c ON o.PositionID = c.PositionID
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 2 T2, 1 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 8/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN | Type: Table | Production Source: External_bi_output_finance via SP_Positions_Opened_From_IBAN*
