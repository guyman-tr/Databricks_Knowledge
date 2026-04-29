# BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN

> 3.16M-row mapping table linking positions closed directly to IBAN bank accounts with their corresponding WithdrawPaymentID. Used for tracing which closed positions triggered IBAN withdrawals. Sourced from an external finance BI output table, deduplicated via `Dim_Position` and `Fact_BillingWithdraw` CID matching. Refreshed daily via `SP_Positions_Closed_To_IBAN` (TRUNCATE+INSERT).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `External_bi_output_finance_bi_db_positions_closed_to_iban_parquet` (external table) → deduplicated via `DWH_dbo.Dim_Position` + `DWH_dbo.Fact_BillingWithdraw` |
| **Writer SP** | `BI_DB_dbo.SP_Positions_Closed_To_IBAN` (Guy Manova 2025-03-19, updated 2025-07-21) |
| **Refresh** | Daily, TRUNCATE+INSERT |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, delta, daily) |

---

## 1. Business Meaning

This is a **position-to-withdrawal linkage table** for IBAN-based account closures. When a customer closes positions and the proceeds are sent directly to an IBAN bank account (rather than staying in the eToro wallet), this table records which PositionID was closed and which WithdrawPaymentID in the billing system corresponds to that closure.

The table has 3.16M rows and is fully refreshed daily (TRUNCATE+INSERT). The source is an external parquet file produced by the finance BI output pipeline (`External_bi_output_finance_bi_db_positions_closed_to_iban_parquet`). A critical deduplication step was added on 2025-07-21 to address an R&D design flaw: child positions (from copy trading/mirrors) were incorrectly assigned WithdrawToFundingIDs, causing duplications when joined to MIMO position data. The fix JOINs through `Dim_Position` (to get the real CID) and `Fact_BillingWithdraw` (to verify CID matches the withdrawal record).

The companion table `BI_DB_Positions_Opened_From_IBAN` performs the same function for deposits (PositionID → DepositID).

---

## 2. Business Logic

### 2.1 CID-Based Deduplication

**What**: Removes false linkages from mirror/child positions that inherit parent WithdrawPaymentIDs.
**Columns Involved**: PositionID, WithdrawPaymentID
**Rules**:
- External source provides raw PositionID-WithdrawPaymentID pairs
- JOIN to Dim_Position gets the real CID for each position
- JOIN to Fact_BillingWithdraw verifies the CID matches the withdrawal's CID
- Only pairs where both the position and the withdrawal belong to the same customer survive
- This eliminates mirror/child position false positives from the R&D design flaw

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(PositionID) distribution — optimal for PositionID-based JOINs. CLUSTERED COLUMNSTORE INDEX.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Find withdrawal for a closed position | `WHERE PositionID = <id>` |
| All IBAN closures for a customer | JOIN to Dim_Position for CID, then filter |
| MIMO analysis with closed-to-IBAN | JOIN to Dim_Position and BI_DB_Positions_Opened_From_IBAN |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | PositionID = PositionID | Get position details, CID, open/close dates |
| DWH_dbo.Fact_BillingWithdraw | WithdrawPaymentID = WithdrawPaymentID | Get withdrawal amount, status, funding type |
| BI_DB_Positions_Opened_From_IBAN | PositionID = PositionID | Link IBAN-opened positions to IBAN-closed positions |

### 3.4 Gotchas

- **No CID column** — must JOIN to Dim_Position to get the customer identifier
- **One-to-one mapping** — each PositionID appears once (deduplication ensures this)
- **External source dependency** — the external parquet file is the ultimate source; if it is stale, this table reflects stale data

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Description from SP code analysis |
| Tier 3 | Description from data sampling / parameter inference |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | YES | Trading position that was closed directly to an IBAN bank account. Distribution key. Deduplicated via CID matching against Dim_Position and Fact_BillingWithdraw. (Tier 2 — SP_Positions_Closed_To_IBAN) |
| 2 | WithdrawPaymentID | int | YES | Corresponding withdrawal payment record in the billing system (Fact_BillingWithdraw). Links the closed position to its IBAN withdrawal transaction. (Tier 2 — SP_Positions_Closed_To_IBAN) |
| 3 | UpdateDate | datetime | YES | Row load timestamp. GETDATE() at insert time. (Tier 3 — SP_Positions_Closed_To_IBAN, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| PositionID | External_...closed_to_iban_parquet | PositionID | Passthrough (after CID dedup) |
| WithdrawPaymentID | External_...closed_to_iban_parquet | WithdrawPaymentID | Passthrough (after CID dedup) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
Finance BI Output (external parquet)
  |-- External_bi_output_finance_bi_db_positions_closed_to_iban_parquet
  |-- JOIN DWH_dbo.Dim_Position (CID for dedup)
  |-- JOIN DWH_dbo.Fact_BillingWithdraw (CID + WithdrawPaymentID match)
  |-- TRUNCATE + INSERT, UpdateDate = GETDATE()
  v
BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN (3.16M rows)
  |-- Generic Pipeline (Override, delta, daily)
  v
general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position | FK — position details |
| WithdrawPaymentID | DWH_dbo.Fact_BillingWithdraw | FK — withdrawal transaction details |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in the SSDT repo. Used for MIMO-to-position data JOINs in ad-hoc analysis.

---

## 7. Sample Queries

### 7.1 Withdrawal Details for Closed-to-IBAN Positions

```sql
SELECT c.PositionID, c.WithdrawPaymentID,
    dp.CID, dp.InstrumentID, dp.CloseOccurred,
    fbw.Amount AS WithdrawAmount, fbw.FundingTypeID
FROM BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN c
JOIN DWH_dbo.Dim_Position dp ON c.PositionID = dp.PositionID
JOIN DWH_dbo.Fact_BillingWithdraw fbw ON c.WithdrawPaymentID = fbw.WithdrawPaymentID
WHERE dp.CID = 13944640
```

### 7.2 Count of IBAN Closures by Instrument

```sql
SELECT dp.InstrumentID, di.SymbolFull, COUNT(*) AS IBANClosures
FROM BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN c
JOIN DWH_dbo.Dim_Position dp ON c.PositionID = dp.PositionID
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
GROUP BY dp.InstrumentID, di.SymbolFull
ORDER BY IBANClosures DESC
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 2 T2, 1 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 8/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN | Type: Table | Production Source: External_bi_output_finance via SP_Positions_Closed_To_IBAN*
