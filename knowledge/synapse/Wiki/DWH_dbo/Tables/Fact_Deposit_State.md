# DWH_dbo.Fact_Deposit_State

> Daily incremental fact table capturing deposit state change events -- each row represents a deposit (or reversal/chargeback) record as it appeared on its modification date, enabling point-in-time reconstruction of deposit lifecycles.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_staging.etoro_Billing_BI_Deposit_State_Report (Billing BI state report) |
| **Refresh** | Daily incremental (delete-for-date + insert pattern via @dt parameter) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX(CID ASC) |
| | |
| **UC Target** | _Not found in generic pipeline mapping - custom Billing pipeline_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

Fact_Deposit_State captures daily snapshots of deposit transaction state changes on the eToro platform. Each row records a deposit (or chargeback/refund event) as it was modified on a given date. The table acts as a daily changelog for the billing deposit pipeline: it does not store the full deposit history from inception, but captures the state as-of each modification date, allowing analysts to see how deposits progressed through their lifecycle (e.g., from Approved to Chargeback) day by day.

Data originates from `DWH_staging.etoro_Billing_BI_Deposit_State_Report`, which is a Billing BI report staging view aggregating deposit state data from the eToro billing system. This is a custom Billing pipeline, not part of the standard Generic Pipeline mapping. The table covers data from 2023-01-01 onwards (19.4M rows as of March 2026).

Loaded daily by `SP_Fact_Deposit_State(@dt)`. The SP deletes all rows where `ModificationDateID` falls on `@dt`, then reloads from staging for the same date window. `ModificationDateID` (YYYYMMDD int) and `UpdateDate` (GETDATE()) are the only DWH-derived columns; all others are passthrough from staging.

---

## 2. Business Logic

### 2.1 Deposit Status Lifecycle

**What**: Each deposit record transitions through statuses over its lifetime. Fact_Deposit_State captures this transition: `DepositStatus` is the current state, `PreviousStatus` is the state before the last modification.

**Columns Involved**: `DepositStatus`, `PreviousStatus`, `TransactionType`

**Rules**:
- `DepositStatus` reflects the deposit's state at the time of `ModificationDate`
- `PreviousStatus` is the prior status (empty string for initial creation events)
- Values observed in production:

| DepositStatus | Count | Meaning |
|--------------|-------|---------|
| Deposit | ~19.4M (99.9%) | Standard approved/processed deposit |
| Refund | ~11K | Deposit refunded to customer |
| Chargeback | ~5.3K | Customer-initiated chargeback |
| ChargebackReversal | ~1.1K | Chargeback reversed by acquiring bank |
| Approved | ~514 | Explicitly approved state |
| ReversedDeposit | ~163 | Internally reversed deposit |
| RefundReversal | ~9 | Refund itself reversed |

**Diagram**:
```
Deposit (creation) -> Deposit (ongoing)
                   -> Refund (customer request or platform action)
                   -> Chargeback (customer disputes with bank)
                     -> ChargebackReversal (bank reverses chargeback)
                   -> ReversedDeposit (internal reversal)
```

### 2.2 Transaction Type Classification

**What**: `TransactionType` provides a more granular classification of the event type, including cancellation sub-types that describe failed or rolled-back state transitions.

**Columns Involved**: `TransactionType`

**Rules**:
- 10 distinct values observed:
  - `Deposit` - standard deposit event (99.9%)
  - `Refund`, `Chargeback`, `ChargebackReversal`, `ReversedDeposit` - reversal events
  - `CancelledRefund`, `CancelledChargeback`, `CancelledReversedDeposit`, `CancelledChargebackReversal`, `CancelledRefundReversal` - cancelled reversal attempts
- `TransactionType` and `DepositStatus` are often identical but may differ during transition states

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `CID`. ROUND_ROBIN means no data skew but broadcast JOINs are required when joining with HASH-distributed tables. The CI on CID makes customer-level scans efficient. Always filter by `CID` or `ModificationDateID` for best performance. Avoid large scans without predicates -- 19.4M rows.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is not found in the generic pipeline mapping. It may be exported via a custom pipeline. Consult the Billing team for Databricks UC table availability.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All deposit state changes for a customer | `WHERE CID = @cid ORDER BY ModificationDate` |
| All chargebacks on a given date | `WHERE ModificationDateID = @dateID AND DepositStatus = 'Chargeback'` |
| Daily deposit volume in USD | `WHERE ModificationDateID = @dateID AND DepositStatus = 'Deposit'` then `SUM(AmountInUSD)` |
| Deposits with card payment details | `WHERE CardType IS NOT NULL AND CardType <> 'N/A'` |
| Chargeback rate analysis | ratio of Chargeback rows to Deposit rows per `ModificationDateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Currency | ON f.CurrencyID = dc.CurrencyID | Resolve currency name (EUR, USD, GBP...) |
| DWH_dbo.Dim_BillingDepot | ON f.DepotID = db.DepotID | Resolve payment gateway/depot name |
| DWH_dbo.Dim_PaymentStatus | ON f.PaymentStatusID = dps.PaymentStatusID | Resolve payment status name |
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | ON f.ProtocolMIDSettingsID = dp.ProtocolMIDSettingsID | Resolve protocol MID settings |

### 3.4 Gotchas

- Data starts from **2023-01-01** only -- this is not a full historical deposit table. For pre-2023 deposit history, use `Fact_BillingDeposit` which has full history.
- `FromDate`/`EndDate` form a 1-day window (e.g., 2026-03-10 to 2026-03-11) representing the modification date's day boundary. This is a partitioning mechanism, not a business duration.
- `DepositStatus` and `TransactionType` are often identical. `DepositStatus` reflects the final state; `TransactionType` classifies the event type including cancellation sub-types.
- `ProtocolMIDSettingsID = 0` for most rows (0 = no protocol settings). Join only for non-zero values.
- `ExchangeFee` appears to be in basis points or a fee code (values 0, 52, 70, 101) -- not a currency amount. Verify with Billing team.
- `PIPsInUSD` meaning is unclear from code alone. Appears to be a small decimal fee amount. Requires Billing team clarification.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CreditID | bigint | YES | Unique identifier for the deposit/credit record in the billing system. Passed through from DWH_staging.etoro_Billing_BI_Deposit_State_Report. (Tier 2 - SP_Fact_Deposit_State) |
| 2 | FromDate | datetime2(7) | YES | Start-date timestamp passed through from DWH_staging.etoro_Billing_BI_Deposit_State_Report. The ETL partitions on ModificationDate, not FromDate. (Tier 2 – SP_Fact_Deposit_State) |
| 3 | EndDate | datetime2(7) | YES | End of the day window for this deposit state record. Set to midnight of the next day (e.g., 2026-03-11 00:00:00). Paired with FromDate to define the date boundary. (Tier 3 - live data sampling) |
| 4 | CID | int | YES | Customer ID. Unique identifier for the eToro customer who made the deposit. CLUSTERED INDEX key -- use in WHERE/JOIN for efficient customer-level queries. (Tier 2 - SP_Fact_Deposit_State) |
| 5 | CurrencyID | int | YES | Deposit currency identifier. Foreign key to DWH_dbo.Dim_Currency. 26 distinct currencies in production. Identifies the currency of the Amount field. (Tier 2 - SP_Fact_Deposit_State) |
| 6 | DepositID | int | YES | Unique deposit transaction identifier. 19.37M distinct DepositIDs (near 1:1 with rows). Primary business key for tracing individual deposits. (Tier 2 - SP_Fact_Deposit_State) |
| 7 | DepotID | int | YES | Billing depot (payment gateway) identifier. Foreign key to DWH_dbo.Dim_BillingDepot. 37 distinct depots in production (eToroMoneyEU, NuveiEMUK, eToroMoneyAU etc). (Tier 2 - SP_Fact_Deposit_State) |
| 8 | FundingID | int | YES | Funding record identifier linking this deposit to the customer's funding account/method. (Tier 2 - SP_Fact_Deposit_State) |
| 9 | PaymentStatusID | int | YES | Payment processing status code. Foreign key to DWH_dbo.Dim_PaymentStatus. 7 values in production: 2=Approved (99.8%), 12=Refund, 11=Chargeback, 37=ChargebackReversal, 38=RefundReversal, 39=[UNVERIFIED], 3=Decline. (Tier 2 - SP_Fact_Deposit_State) |
| 10 | CardType | nvarchar(max) | YES | Card type label from payment provider (e.g., "Master Card", "Visa", "N/A" for non-card payments). Not normalized -- stored as text. (Tier 2 - SP_Fact_Deposit_State) |
| 11 | CardCategory | nvarchar(max) | YES | Card product category from payment provider (e.g., "Gold MasterCard Card", "N/A" for non-card). More granular than CardType. (Tier 2 - SP_Fact_Deposit_State) |
| 12 | MID | nvarchar(max) | YES | Merchant Identifier code. Identifies the acquiring bank's merchant account used to process the deposit (e.g., "eToroMoneyEU", "NuveiEMUK"). (Tier 2 - SP_Fact_Deposit_State) |
| 13 | MIDName | nvarchar(max) | YES | Human-readable name for the MID (e.g., "eToroEU", "eToroUK", "EMUK"). Corresponds to the eToro entity or gateway brand. (Tier 2 - SP_Fact_Deposit_State) |
| 14 | BaseExchangeRate | decimal(16,8) | YES | Base (pre-fee) exchange rate between deposit currency and USD. Used to calculate the USD equivalent before exchange fees. (Tier 2 - SP_Fact_Deposit_State) |
| 15 | ExchangeFee | int | YES | Exchange fee indicator; CS deposit conversion guidance references **fee in PIPs** and exchange fee in USD alongside base vs effective rate — consistent with fee encoded as points/tier (observed 0, 52, 70, 101). (Tier 4 — Confluence, Deposit conversion fee) |
| 16 | ExchangeRate | decimal(16,8) | YES | Effective exchange rate applied to the deposit (post-fee). AmountInUSD = Amount * ExchangeRate. Compare to BaseExchangeRate to derive the fee impact. (Tier 2 - SP_Fact_Deposit_State) |
| 17 | ModificationDate | datetime2(7) | YES | Timestamp when this deposit record was last modified in the billing system. Primary time axis for this table. Used in the daily ETL window filter. (Tier 2 - SP_Fact_Deposit_State) |
| 18 | AmountInUSD | decimal(19,4) | YES | Deposit amount converted to USD. Computed as Amount * ExchangeRate. Standard financial reporting currency. (Tier 2 - SP_Fact_Deposit_State) |
| 19 | Amount | decimal(19,4) | YES | Deposit amount in the original deposit currency (CurrencyID). Customer-facing transaction amount. (Tier 2 - SP_Fact_Deposit_State) |
| 20 | ProtocolMIDSettingsID | int | YES | Protocol-level MID settings identifier. Foreign key to DWH_dbo.Dim_BillingProtocolMIDSettingsID. 0 for most rows (no special protocol settings). (Tier 2 - SP_Fact_Deposit_State) |
| 21 | MerchantAccountID | int | YES | Merchant account identifier at the payment processor level. More granular than MID -- identifies the specific merchant account within the depot. (Tier 2 - SP_Fact_Deposit_State) |
| 22 | ExTransactionID | nvarchar(max) | YES | External transaction identifier from the payment processor or gateway. Used for reconciliation with the acquiring bank or payment provider. (Tier 2 - SP_Fact_Deposit_State) |
| 23 | DepositStatus | nvarchar(max) | YES | Current deposit status label. 7 values: Deposit (99.9%), Refund, Chargeback, ChargebackReversal, Approved, ReversedDeposit, RefundReversal. Reflects the state at ModificationDate. (Tier 2 - SP_Fact_Deposit_State) |
| 24 | PreviousStatus | nvarchar(max) | YES | Deposit status before the current modification. Empty string for initial creation events. Used to track state transitions (e.g., "Deposit" -> "Chargeback"). (Tier 2 - SP_Fact_Deposit_State) |
| 25 | TransactionType | nvarchar(max) | YES | Transaction event type classification. 10 values: Deposit, Refund, Chargeback, ChargebackReversal, CancelledRefund, ReversedDeposit, CancelledChargeback, CancelledReversedDeposit, CancelledChargebackReversal, CancelledRefundReversal. (Tier 2 - SP_Fact_Deposit_State) |
| 26 | PIPsInUSD | decimal(19,4) | YES | **PIP in USD** — finance definition: conversion-fee revenue in USD (original amount × spread between base and effective rate, or amount × conversion fee / 10000 per FC playbook). Aligns with small USD amounts on deposit lines. Observed 0.00–5.30. (Tier 4 — Confluence, Conversion fee Revenue Calculation (PIP in USD)) |
| 27 | FeeInPercentage | decimal(38,7) | YES | Fee applied to the deposit expressed as a percentage (e.g., 0.4498343 = 0.45% fee). (Tier 2 - SP_Fact_Deposit_State) |
| 28 | ModificationDateID | int | YES | ModificationDate as YYYYMMDD integer (e.g., 20260310). DWH-derived: computed in SP as CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY,0,ModificationDate), 0), 112)). Used for date-range deletes and partitioning. (Tier 2 - SP_Fact_Deposit_State) |
| 29 | UpdateDate | datetime | YES | DWH load timestamp. Set to GETDATE() at ETL execution time. Tracks when this row was last written to Synapse. (Tier 2 - SP_Fact_Deposit_State) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CreditID | etoro_Billing_BI_Deposit_State_Report | CreditID | Passthrough |
| FromDate | etoro_Billing_BI_Deposit_State_Report | FromDate | Passthrough |
| EndDate | etoro_Billing_BI_Deposit_State_Report | EndDate | Passthrough |
| CID | etoro_Billing_BI_Deposit_State_Report | CID | Passthrough |
| CurrencyID | etoro_Billing_BI_Deposit_State_Report | CurrencyID | Passthrough |
| DepositID | etoro_Billing_BI_Deposit_State_Report | DepositID | Passthrough |
| DepotID | etoro_Billing_BI_Deposit_State_Report | DepotID | Passthrough |
| FundingID | etoro_Billing_BI_Deposit_State_Report | FundingID | Passthrough |
| PaymentStatusID | etoro_Billing_BI_Deposit_State_Report | PaymentStatusID | Passthrough |
| CardType | etoro_Billing_BI_Deposit_State_Report | CardType | Passthrough |
| CardCategory | etoro_Billing_BI_Deposit_State_Report | CardCategory | Passthrough |
| MID | etoro_Billing_BI_Deposit_State_Report | MID | Passthrough |
| MIDName | etoro_Billing_BI_Deposit_State_Report | MIDName | Passthrough |
| BaseExchangeRate | etoro_Billing_BI_Deposit_State_Report | BaseExchangeRate | Passthrough |
| ExchangeFee | etoro_Billing_BI_Deposit_State_Report | ExchangeFee | Passthrough |
| ExchangeRate | etoro_Billing_BI_Deposit_State_Report | ExchangeRate | Passthrough |
| ModificationDate | etoro_Billing_BI_Deposit_State_Report | ModificationDate | Passthrough |
| AmountInUSD | etoro_Billing_BI_Deposit_State_Report | AmountInUSD | Passthrough |
| Amount | etoro_Billing_BI_Deposit_State_Report | Amount | Passthrough |
| ProtocolMIDSettingsID | etoro_Billing_BI_Deposit_State_Report | ProtocolMIDSettingsID | Passthrough |
| MerchantAccountID | etoro_Billing_BI_Deposit_State_Report | MerchantAccountID | Passthrough |
| ExTransactionID | etoro_Billing_BI_Deposit_State_Report | ExTransactionID | Passthrough |
| DepositStatus | etoro_Billing_BI_Deposit_State_Report | DepositStatus | Passthrough |
| PreviousStatus | etoro_Billing_BI_Deposit_State_Report | PreviousStatus | Passthrough |
| TransactionType | etoro_Billing_BI_Deposit_State_Report | TransactionType | Passthrough |
| PIPsInUSD | etoro_Billing_BI_Deposit_State_Report | PIPsInUSD | Passthrough |
| FeeInPercentage | etoro_Billing_BI_Deposit_State_Report | FeeInPercentage | Passthrough |
| ModificationDateID | ETL-computed | ModificationDate | CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY,0,ModificationDate), 0), 112)) |
| UpdateDate | ETL-computed | N/A | GETDATE() |

No upstream wiki available. DWH_staging.etoro_Billing_BI_Deposit_State_Report is a custom Billing BI staging view (not in DB_Schema etoro wiki).

### 5.2 ETL Pipeline

```
eToro Billing System -> DWH_staging.etoro_Billing_BI_Deposit_State_Report
  -> SP_Fact_Deposit_State(@dt)
    -> DWH_dbo.Fact_Deposit_State [DELETE for @dt + INSERT]
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_staging.etoro_Billing_BI_Deposit_State_Report | Billing BI deposit state report staging view |
| ETL | SP_Fact_Deposit_State | Per-date delete-for-ModificationDateID + INSERT |
| Target | DWH_dbo.Fact_Deposit_State | DWH deposit state fact table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (Pending) | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency (EUR, USD, GBP, AUD, etc.) |
| DepotID | DWH_dbo.Dim_BillingDepot | Payment gateway/depot used |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Payment processing status code |
| ProtocolMIDSettingsID | DWH_dbo.Dim_BillingProtocolMIDSettingsID | Protocol MID configuration |
| ModificationDateID | DWH_dbo.Dim_Date (via DateID) | Date dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| _Not yet identified_ | | This table is relatively new (2023+). Downstream consumers TBD. |

---

## 7. Sample Queries

### 7.1 Daily deposit volume and chargeback summary

```sql
SELECT
    f.ModificationDateID,
    dc.CurrencyName,
    f.DepositStatus,
    COUNT(*) AS event_count,
    SUM(f.AmountInUSD) AS total_usd
FROM [DWH_dbo].[Fact_Deposit_State] f
JOIN [DWH_dbo].[Dim_Currency] dc ON f.CurrencyID = dc.CurrencyID
WHERE f.ModificationDateID = 20260310
GROUP BY f.ModificationDateID, dc.CurrencyName, f.DepositStatus
ORDER BY total_usd DESC;
```

### 7.2 Deposits for a specific customer with status history

```sql
SELECT
    f.DepositID,
    f.ModificationDate,
    f.DepositStatus,
    f.PreviousStatus,
    f.TransactionType,
    f.Amount,
    dc.CurrencyName,
    f.AmountInUSD,
    db.DepotName
FROM [DWH_dbo].[Fact_Deposit_State] f
JOIN [DWH_dbo].[Dim_Currency] dc ON f.CurrencyID = dc.CurrencyID
JOIN [DWH_dbo].[Dim_BillingDepot] db ON f.DepotID = db.DepotID
WHERE f.CID = 12345678
ORDER BY f.DepositID, f.ModificationDate;
```

### 7.3 Chargeback rate by depot for a month

```sql
SELECT
    db.DepotName,
    SUM(CASE WHEN f.DepositStatus = 'Deposit' THEN 1 ELSE 0 END) AS deposits,
    SUM(CASE WHEN f.DepositStatus = 'Chargeback' THEN 1 ELSE 0 END) AS chargebacks,
    CAST(SUM(CASE WHEN f.DepositStatus = 'Chargeback' THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(SUM(CASE WHEN f.DepositStatus = 'Deposit' THEN 1 ELSE 0 END), 0) AS chargeback_rate
FROM [DWH_dbo].[Fact_Deposit_State] f
JOIN [DWH_dbo].[Dim_BillingDepot] db ON f.DepotID = db.DepotID
WHERE f.ModificationDateID BETWEEN 20260201 AND 20260228
GROUP BY db.DepotName
ORDER BY chargeback_rate DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Deposit in BO and statuses](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11705024980/Deposit+in+BO+and+statuses) | Confluence | Deposit statuses (New, Technical, Pending, Refund, etc.) and BO context. |
| [Deposit Statuses and Back Office](https://etoro-jira.atlassian.net/wiki/spaces/USACS/pages/11752211021/Deposit+Statuses+and+Back+Office) | Confluence | USACS variant of deposit status definitions. |
| [Deposit conversion fee](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11705909430/Deposit+conversion+fee) | Confluence | Cashier columns: base rate, exchange rate, **fee in PIPs**, exchange fee in USD. |
| [Conversion fee Revenue Calculation (PIP in USD)](https://etoro-jira.atlassian.net/wiki/spaces/FC/pages/12000526439/Conversion+fee+Revenue+Calculation+PIP+in+USD) | Confluence | **PIP in USD** formula for conversion fee revenue on deposits/chargebacks/refunds. |
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) | Confluence | Billing **Deposit** / **vDeposit** as DWH pipeline sources. |

---

*Generated: 2026-03-19 | Quality: 8.2/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 27 T2, 2 T3, 0 T4 [UNVERIFIED], 2 T4 — Confluence, 0 T5 | Elements: 9.5/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10*
*Object: DWH_dbo.Fact_Deposit_State | Type: Table | Production Source: DWH_staging.etoro_Billing_BI_Deposit_State_Report*
