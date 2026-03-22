# DWH_dbo.Fact_BillingRedeem

> Fact table tracking every copy-trading redeem (cashout) request — recording the customer, trading position being redeemed, requested and final amounts, payment instrument, status, and modification timestamps. 1.4M rows updated hourly from etoro.Billing.Redeem via SP_Fact_BillingRedeem_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Redeem (via Generic Pipeline — hourly, 60 min, Override) |
| **Refresh** | Hourly (SP_Fact_BillingRedeem_DL_To_Synapse, 7-day rolling DELETE + INSERT) |
| | |
| **Synapse Distribution** | HASH (RedeemID) |
| **Synapse Index** | CLUSTERED (ModificationDateID ASC) + NC (RedeemID) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Fact_BillingRedeem` records every copy-trading position redeem request on the eToro platform. A "redeem" is the act of cashing out a position — closing a copied investment and requesting the return of funds. The table captures the request state, the amounts (at request time vs. at close), the payment instrument used, and the current processing status.

This table represents the withdrawal/liquidation side of eToro's copy-trading financial flow: customers may redeem a position (convert the position value back to cash) via the cashier system. The `RedeemID` is the primary key identifying each individual redeem request.

**ETL pattern**: `SP_Fact_BillingRedeem_DL_To_Synapse` uses a 7-day rolling window strategy:
1. DELETE from `Ext_FBR_Fact_BillingRedeem` (staging table) for the last 7 days by ModificationDateID
2. INSERT fresh data from `DWH_staging.etoro_Billing_Redeem` into Ext_FBR for the same window
3. DELETE from main `Fact_BillingRedeem` for the same 7-day window
4. INSERT from Ext_FBR into the main table

The 7-day window means redeems modified in the last week are always refreshed, ensuring status changes (e.g., processing → approved) are captured within the SLA.

**Source**: `etoro.Billing.Redeem` is the production table on etoroDB-REAL. The Generic Pipeline exports it hourly (60-minute interval, Override strategy) to Bronze, where it is staged into `DWH_staging.etoro_Billing_Redeem`.

No upstream wiki exists for `Billing.Redeem` at the time of documentation.

---

## 2. Business Logic

### 2.1 Redeem Amount Tracking (Request vs. Close)

**What**: Two separate amounts capture the redeem value at different lifecycle stages.

**Columns Involved**: `AmountOnRequest`, `AmountOnClose`

**Rules**:
- `AmountOnRequest`: the position value at the time the redeem was initiated. This is what the customer expected to receive
- `AmountOnClose`: the actual position value at close time. May differ from AmountOnRequest if the market moved between request and settlement
- Both are stored in the position's base currency (USD typically for copied positions)

### 2.2 Rolling 7-Day Refresh Window

**What**: Only the last 7 days of redeems are re-processed on each SP run.

**Columns Involved**: `ModificationDateID`, `LastModificationDate`

**Rules**:
- `ModificationDateID = CONVERT(INT, LastModificationDate)` — YYYYMMDD integer derived from the datetime
- Rows modified more than 7 days ago remain as-is (not re-processed unless forced)
- Provides idempotent re-processing for the recent window; older data is considered stable

### 2.3 Redeem Status Lifecycle

**What**: Redeems move through processing states tracked by RedeemStatusID.

**Columns Involved**: `RedeemStatusID`, `RedeemReasonID`

**Rules**:
- `RedeemStatusID` references `DWH_dbo.Dim_RedeemStatus` (documented in Batch 9)
- `RedeemReasonID` references `DWH_dbo.Dim_RedeemReason` (documented in Batch 9) — explains why the redeem was requested (e.g., manual close, stop-loss, copy-stop)
- NULL `RedeemReasonID` indicates no specific reason recorded

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`HASH(RedeemID)` is appropriate for the primary key distribution — ensures even spread across distributions. The clustered index on `ModificationDateID` supports the 7-day rolling window ETL pattern and range queries by modification date. The non-clustered index on `RedeemID` supports point lookups by redeem ID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Redeem volume by day | GROUP BY ModificationDateID, COUNT(*) |
| Status breakdown | JOIN Dim_RedeemStatus ON RedeemStatusID |
| Customer redeem history | WHERE CID = @CID ORDER BY RequestDate |
| Redeem amount discrepancy | WHERE AmountOnClose <> AmountOnRequest |

### 3.3 Gotchas

- **7-day window**: Redeems older than 7 days are not refreshed. For historical analysis, the data should be accurate but status changes older than 7 days may not be reflected
- **ModificationDateID vs. RequestDate**: Use `ModificationDateID` for date-range queries (clustered index); `RequestDate` is a datetime (no index)
- **No upstream wiki**: All column descriptions are Tier 2 (SP code analysis) — not validated against Billing.Redeem documentation

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 2 — SP ETL code | (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| Tier 3 — live data sampling | (Tier 3 — Phase 2 live sample) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Customer ID. Identifies the eToro customer who initiated the redeem request. References DWH_dbo.Dim_Customer. Primary join key for customer-level redeem analytics. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 2 | RedeemID | int | NOT NULL | Primary key for the redeem request. Distribution key (HASH). Uniquely identifies each redeem operation across the platform. Non-clustered index key for point lookups. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 3 | PositionID | bigint | NOT NULL | Trading position being redeemed. References the copy-trading position that is being closed/liquidated. BIGINT to accommodate the large position ID space. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 4 | RedeemStatusID | int | NOT NULL | Current processing status of the redeem request. References DWH_dbo.Dim_RedeemStatus (documented in Batch 9). Tracks the lifecycle from submission through approval/rejection/processing. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 5 | RedeemReasonID | int | YES | Reason code explaining why the redeem was initiated. References DWH_dbo.Dim_RedeemReason (documented in Batch 9). NULL when no specific reason was recorded. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 6 | AmountOnRequest | money | YES | Position value (in base currency) at the time the redeem request was submitted. Represents what the customer expected to receive. May differ from AmountOnClose if market moved during processing. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 7 | AmountOnClose | money | YES | Actual position value (in base currency) at close/settlement time. The final amount processed for the redeem. NULL if not yet settled. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 8 | FundingID | int | YES | Payment instrument (funding method) used for this redeem payout. References Billing.Funding. Identifies the credit card, bank account, or e-wallet that received the redeemed funds. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 9 | RequestDate | datetime | YES | Datetime when the redeem request was submitted by the customer. Records the initiation time of the redeem lifecycle. No index — use ModificationDateID for range queries. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 10 | LastModificationDate | datetime | YES | Most recent datetime when this redeem record was modified. Used as the source for ModificationDateID. The ETL 7-day rolling window is based on this field. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 11 | ModificationDateID | int | NOT NULL | Clustered index key. Integer date in YYYYMMDD format derived from `CONVERT(INT, LastModificationDate)`. The ETL rolling 7-day window operates on this column. Use for date-range queries and partitioning in downstream systems. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |
| 12 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to `GETDATE()` at SP execution time, not from the production source. Use for ETL freshness monitoring. (Tier 2 — SP_Fact_BillingRedeem_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | etoro.Billing.Redeem | CID | Passthrough |
| RedeemID | etoro.Billing.Redeem | RedeemID | Passthrough |
| PositionID | etoro.Billing.Redeem | PositionID | Passthrough |
| RedeemStatusID | etoro.Billing.Redeem | RedeemStatusID | Passthrough |
| RedeemReasonID | etoro.Billing.Redeem | RedeemReasonID | Passthrough |
| AmountOnRequest | etoro.Billing.Redeem | AmountOnRequest | Passthrough |
| AmountOnClose | etoro.Billing.Redeem | AmountOnClose | Passthrough |
| FundingID | etoro.Billing.Redeem | FundingID | Passthrough |
| RequestDate | etoro.Billing.Redeem | RequestDate | Passthrough |
| LastModificationDate | etoro.Billing.Redeem | LastModificationDate | Passthrough |
| ModificationDateID | etoro.Billing.Redeem | LastModificationDate | ETL-computed: CONVERT(INT, LastModificationDate) → YYYYMMDD |
| UpdateDate | — | — | ETL-computed: GETDATE() at SP execution time |

### 5.2 ETL Pipeline

```
etoro.Billing.Redeem (etoroDB-REAL, production redeem ledger)
  |
  v [Generic Pipeline — hourly, 60 min, Override]
Bronze/etoro/Billing/Redeem/
  |
  v [staging]
DWH_staging.etoro_Billing_Redeem
  |
  v [SP_Fact_BillingRedeem_DL_To_Synapse — 7-day rolling window]
    1. DELETE from Ext_FBR_Fact_BillingRedeem (7-day window by ModificationDateID)
    2. INSERT into Ext_FBR from staging (7-day window)
    3. DELETE from Fact_BillingRedeem (7-day window)
    4. INSERT from Ext_FBR into Fact_BillingRedeem
DWH_dbo.Fact_BillingRedeem (1.4M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Billing.Redeem | Production redeem transaction table (etoroDB-REAL) |
| Lake | Bronze/etoro/Billing/Redeem/ | Hourly full export (Override, 60-min interval, parquet) |
| Staging | DWH_staging.etoro_Billing_Redeem | Raw staging import |
| Ext | DWH_dbo.Ext_FBR_Fact_BillingRedeem | Intermediate staging table for the 7-day window |
| ETL | SP_Fact_BillingRedeem_DL_To_Synapse | 7-day rolling DELETE+INSERT; ModificationDateID derived; UpdateDate=GETDATE() |
| Target | DWH_dbo.Fact_BillingRedeem | 1.4M rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who initiated the redeem |
| RedeemStatusID | DWH_dbo.Dim_RedeemStatus | Current processing status of the redeem |
| RedeemReasonID | DWH_dbo.Dim_RedeemReason | Reason code for the redeem |
| ModificationDateID | DWH_dbo.Dim_Date | Date dimension for time analysis |
| FundingID | etoro.Billing.Funding | Payment instrument for payout (implicit) |

### 6.2 Referenced By (other objects point to this)

No downstream DWH consumers identified at documentation time.

---

## 7. Sample Queries

### 7.1 Daily redeem volume trend

```sql
SELECT
    ModificationDateID,
    COUNT(*) AS RedeemCount,
    SUM(AmountOnClose) AS TotalAmountOnClose
FROM [DWH_dbo].[Fact_BillingRedeem]
WHERE ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-30,GETDATE()), 112))
GROUP BY ModificationDateID
ORDER BY ModificationDateID DESC
```

### 7.2 Redeem status breakdown

```sql
SELECT
    rs.RedeemStatusName,
    COUNT(*) AS RedeemCount,
    SUM(AmountOnClose) AS TotalAmount
FROM [DWH_dbo].[Fact_BillingRedeem] fbr
JOIN [DWH_dbo].[Dim_RedeemStatus] rs
    ON fbr.RedeemStatusID = rs.RedeemStatusID
GROUP BY rs.RedeemStatusName
ORDER BY RedeemCount DESC
```

### 7.3 Amount discrepancy (request vs. close)

```sql
SELECT
    RedeemID,
    CID,
    AmountOnRequest,
    AmountOnClose,
    AmountOnClose - AmountOnRequest AS AmountDelta,
    RedeemStatusID
FROM [DWH_dbo].[Fact_BillingRedeem]
WHERE AmountOnRequest IS NOT NULL
  AND AmountOnClose IS NOT NULL
  AND AmountOnRequest <> AmountOnClose
ORDER BY ABS(AmountOnClose - AmountOnRequest) DESC
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) | Confluence | Lists **etoro.Billing.Redeem** as a DWH pipeline source (validation of lake/DWH lineage). |
| [What is Redeem?](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/12273977411/What+is+Redeem) | Confluence | Product definition of Redeem (crypto transfer to eToro Money wallet); **note:** DWH `Fact_BillingRedeem` is documented here as **copy-trading position** redeem — use Confluence for shared Billing/redeem semantics only. |
| [HLD: Redeem service](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11685691393/HLD+Redeem+service) | Confluence | Redeem service architecture (Trading ↔ Billing messaging). |
| [Redeem Handling](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/971374912/Redeem+Handling) | Confluence | Ops handling and BO reporting around redeems. |

---

*Generated: 2026-03-19 | Quality: 7.7/10 | Phases: 8/14*
*Tiers: 0 T1, 10 T2, 2 T3, 0 T4-Inferred | Elements: 8.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10*
*Object: DWH_dbo.Fact_BillingRedeem | Type: Table | Production Source: etoro.Billing.Redeem*
