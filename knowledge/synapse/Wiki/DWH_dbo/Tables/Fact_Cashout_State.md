# DWH_dbo.Fact_Cashout_State

> Snapshot fact table capturing the full state of every customer cashout (withdrawal) transaction — recording the request, routing, exchange details, and current status for 9.95M cashout events. Refreshed daily from the BI_Cashout_State_Report pipeline.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.BI_Cashout_State_Report (custom BI report export — not in Generic Pipeline mapping) |
| **Refresh** | Daily (SP_Fact_Cashout_State, DELETE current day + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED (CID ASC) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Fact_Cashout_State` is a daily snapshot fact table recording the current state of all customer cashout (withdrawal) requests on the eToro platform. Each row represents a cashout transaction at its most recent state — including the transaction type, previous status (for audit/transition tracking), withdrawal and deposit IDs, payment routing details, exchange rate information, and the final processed amounts.

The table covers 9.95M cashout events — the full history of eToro's withdrawal pipeline since inception.

**Data source**: `etoro.Billing.BI_Cashout_State_Report` is a custom BI-oriented reporting table/view in production that consolidates cashout state from multiple underlying billing tables. It is **not** listed in the `_generic_pipeline_mapping.json` — the pipeline that exports it to the data lake uses a custom mechanism rather than the standard Generic Pipeline framework.

**ETL pattern**: `SP_Fact_Cashout_State` uses a daily snapshot approach:
1. DELETE rows from `Fact_Cashout_State` where `ModificationDateID` = today's date
2. INSERT from `DWH_staging.etoro_Billing_BI_Cashout_State_Report` for today's date

This means only today's changes are re-processed each day. Historical rows are retained as-is unless a re-load is triggered.

**`CreditID` addition**: The `CreditID` column (bigint) was added on 2025-08-13 by guym to support credit account tracking for cashout operations.

**Distribution note**: `ROUND_ROBIN` was chosen over `HASH(WithdrawID)` — suggesting query patterns that don't rely heavily on equijoin on a single key, or the table was designed for full-scan analytics rather than lookup-heavy joins.

---

## 2. Business Logic

### 2.1 Cashout State Tracking

**What**: Each row captures the current and previous state of a cashout transaction.

**Columns Involved**: `CashoutStatusID`, `CashoutStatus`, `PreviousStatus`, `TransactionType`

**Rules**:
- `CashoutStatusID` is the numeric status code; `CashoutStatus` is the string label (both stored for convenience — no separate Dim_CashoutStatus join required for the name)
- `PreviousStatus` stores the string name of the prior status, enabling state transition analysis without history tables
- `TransactionType` classifies the withdrawal method (e.g., credit card, wire transfer, e-wallet)

### 2.2 Multi-Level Transaction Routing

**What**: Each cashout is routed through a depot (acquirer), MID (merchant ID settings), and merchant account.

**Columns Involved**: `DepotID`, `ProtocolMIDSettingsID`, `MerchantAccountID`, `MID`, `MIDName`

**Rules**:
- `DepotID` identifies the payment acquirer/gateway configuration
- `ProtocolMIDSettingsID` references the specific MID configuration profile
- `MerchantAccountID` identifies the legal entity/merchant account for regulatory routing
- `MID` (nvarchar) and `MIDName` (nvarchar) store the string representations of the merchant ID for display/reporting convenience

### 2.3 Amount and Exchange Rate

**What**: Stores both the local currency amount and USD equivalent with exchange details.

**Columns Involved**: `Amount`, `CurrencyID`, `AmountInUSD`, `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `ExchaFeeInPercentage`, `PIPsInUSD`

**Rules**:
- `Amount` is in the cashout currency (`CurrencyID`)
- `AmountInUSD` = Amount × ExchangeRate (pre-computed USD equivalent)
- `BaseExchangeRate` is the reference rate before fee markup; `ExchangeRate` includes the markup
- `ExchangeFee` is in basis points; `ExchaFeeInPercentage` is the percentage form
- `PIPsInUSD` captures the exchange fee value in USD for reporting

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`ROUND_ROBIN` means rows are distributed cyclically across nodes — optimal for full-scan aggregations but suboptimal for point lookups by customer or transaction ID. `CLUSTERED(CID)` physically orders rows by customer within each distribution. For per-customer queries, consider that rows for a single CID are spread across all distributions.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily cashout volume | GROUP BY ModificationDateID, SUM(AmountInUSD) |
| Status breakdown | GROUP BY CashoutStatus, COUNT(*) |
| Customer withdrawal history | WHERE CID = @CID ORDER BY ModificationDateID |
| Exchange fee analysis | SELECT AVG(ExchaFeeInPercentage), SUM(PIPsInUSD) GROUP BY CurrencyID |

### 3.3 Gotchas

- **ROUND_ROBIN + per-customer queries**: Joining to customer fact tables may cause significant data movement. Consider HASH distribution if per-CID query is the primary pattern
- **CashoutStatus is a string**: Unlike most DWH tables that use integer IDs exclusively, this table stores the status name directly in `CashoutStatus`. Both `CashoutStatusID` and `CashoutStatus` (string) are present
- **Not in Generic Pipeline mapping**: The data export mechanism for `BI_Cashout_State_Report` is custom — pipeline freshness monitoring requires checking the custom pipeline, not the standard Generic Pipeline dashboard
- **Daily snapshot, not rolling window**: Unlike Fact_BillingRedeem (7-day rolling), this table only reprocesses today. Yesterday's state changes won't be caught unless a manual re-load is run

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 2 — SP ETL code | (Tier 2 — SP_Fact_Cashout_State) |
| Tier 3 — live data sampling + naming | (Tier 3 — Phase 2 + column naming) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Identifies the eToro customer who submitted the cashout request. Clustered index key (co-locates customer rows within distributions). References DWH_dbo.Dim_Customer. (Tier 2 — SP_Fact_Cashout_State) |
| 2 | TransactionType | nvarchar(max) | YES | Classification of the withdrawal transaction method (e.g., credit card, wire transfer, e-wallet). String label providing context for the cashout routing path. (Tier 3 — column naming) |
| 3 | PreviousStatus | nvarchar(max) | YES | String label of the cashout status immediately before the current state. Enables state transition analysis without joining to a history table. (Tier 3 — column naming) |
| 4 | WithdrawID | int | YES | Identifier for the associated withdrawal request in the cashout pipeline. May reference Billing.Cashout or Billing.Withdraw tables in production. (Tier 2 — SP_Fact_Cashout_State) |
| 5 | WPID | int | YES | Withdrawal payment processing ID. Identifies the specific payment processing record associated with this cashout. (Tier 3 — column naming) |
| 6 | DepositID | int | YES | Original deposit ID linked to this cashout (for refund/chargeback scenarios). References Fact_BillingDeposit.DepositID when the cashout is associated with a deposit reversal. (Tier 3 — column naming) |
| 7 | FundingID | int | YES | Payment instrument (credit card, bank account, e-wallet) used for the cashout payout. References Billing.Funding. (Tier 2 — SP_Fact_Cashout_State) |
| 8 | DepotID | int | YES | Identifies the Billing.Depot (acquirer/gateway configuration) processing this cashout. Determines which payment processor handles the transaction. (Tier 2 — SP_Fact_Cashout_State) |
| 9 | CashoutStatusID | int | YES | Numeric status code for the current cashout state. References DWH_dbo.Dim_CashoutStatus (if documented). Companion to the string `CashoutStatus` column. (Tier 2 — SP_Fact_Cashout_State) |
| 10 | CashoutStatus | nvarchar(max) | YES | String label of the current cashout status. Stored as a denormalized string alongside CashoutStatusID to avoid requiring a Dim join for simple status filtering. (Tier 2 — SP_Fact_Cashout_State) |
| 11 | Amount | decimal(19,4) | YES | Cashout amount in the customer's requested currency (CurrencyID). 4 decimal place precision. (Tier 2 — SP_Fact_Cashout_State) |
| 12 | CurrencyID | int | YES | Currency of the cashout amount. References DWH_dbo.Dim_Currency. (Tier 2 — SP_Fact_Cashout_State) |
| 13 | AmountInUSD | decimal(19,4) | YES | Cashout amount converted to USD (Amount × ExchangeRate). Pre-computed for reporting convenience. (Tier 2 — SP_Fact_Cashout_State) |
| 14 | BaseExchangeRate | decimal(16,8) | YES | Reference exchange rate before fee markup. Used to compute the exchange fee spread: ExchangeRate - BaseExchangeRate = fee per unit. (Tier 2 — SP_Fact_Cashout_State) |
| 15 | ExchangeFee | int | YES | Exchange fee in a provider-specific integer encoding (typically basis points). (Tier 2 — SP_Fact_Cashout_State) |
| 16 | ExchangeRate | decimal(23,8) | YES | Applied exchange rate from cashout currency to USD, including fee markup. Higher precision (23,8) than BaseExchangeRate (16,8). (Tier 2 — SP_Fact_Cashout_State) |
| 17 | ExTransactionID | nvarchar(max) | YES | External (payment provider) transaction ID for this cashout. Used for provider-side reconciliation. (Tier 2 — SP_Fact_Cashout_State) |
| 18 | ModificationDate | datetime2(7) | YES | UTC timestamp of the most recent modification to this cashout record. Source value from production. (Tier 2 — SP_Fact_Cashout_State) |
| 19 | RequestDate | datetime2(7) | YES | UTC timestamp when the cashout was requested by the customer. (Tier 2 — SP_Fact_Cashout_State) |
| 20 | ProtocolMIDSettingsID | int | YES | Merchant ID (MID) configuration profile used for processing. References Billing.ProtocolMIDSettings. (Tier 2 — SP_Fact_Cashout_State) |
| 21 | MerchantAccountID | int | YES | Merchant account legal entity used for regulatory routing. References Billing.MerchantAccountRouting. (Tier 2 — SP_Fact_Cashout_State) |
| 22 | PIPsInUSD | decimal(21,6) | YES | Exchange fee value in USD (the "PIPs" — percentage in points — converted to USD absolute amount). Used for fee revenue reporting. (Tier 2 — SP_Fact_Cashout_State) |
| 23 | ExchaFeeInPercentage | decimal(10,2) | YES | Exchange fee as a percentage of the cashout amount (0.00-100.00). Normalized fee rate for comparison across currencies. Note: column name appears to have a typo ("Excha" vs "Exchange"). (Tier 2 — SP_Fact_Cashout_State) |
| 24 | MID | nvarchar(max) | YES | Merchant ID string — the actual MID identifier used with the payment processor. String representation of the MID for reporting/display. (Tier 2 — SP_Fact_Cashout_State) |
| 25 | MIDName | nvarchar(max) | YES | Human-readable label for the Merchant ID configuration. Display name for the MID used in reporting. (Tier 3 — column naming) |
| 26 | ModificationDateID | int | YES | Integer date key in YYYYMMDD format derived from ModificationDate by truncating to midnight and converting via style 112: `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, ModificationDate), 0), 112))`. Used as the ETL key for the daily DELETE+INSERT pattern in SP_Fact_Cashout_State. |
| 27 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at SP execution time. Not from the production source. Use for ETL freshness monitoring. (Tier 2 — SP_Fact_Cashout_State) |
| 28 | CreditID | bigint | YES | Credit account identifier associated with this cashout. Added 2025-08-13 by guym to support credit account tracking. NULL for cashouts not linked to a credit account. (Tier 2 — SP_Fact_Cashout_State) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | etoro.Billing.BI_Cashout_State_Report | CID | Passthrough |
| TransactionType | etoro.Billing.BI_Cashout_State_Report | TransactionType | Passthrough |
| PreviousStatus | etoro.Billing.BI_Cashout_State_Report | PreviousStatus | Passthrough |
| WithdrawID | etoro.Billing.BI_Cashout_State_Report | WithdrawID | Passthrough |
| WPID | etoro.Billing.BI_Cashout_State_Report | WPID | Passthrough |
| DepositID | etoro.Billing.BI_Cashout_State_Report | DepositID | Passthrough |
| FundingID | etoro.Billing.BI_Cashout_State_Report | FundingID | Passthrough |
| DepotID | etoro.Billing.BI_Cashout_State_Report | DepotID | Passthrough |
| CashoutStatusID | etoro.Billing.BI_Cashout_State_Report | CashoutStatusID | Passthrough |
| CashoutStatus | etoro.Billing.BI_Cashout_State_Report | CashoutStatus | Passthrough (denormalized string) |
| Amount | etoro.Billing.BI_Cashout_State_Report | Amount | Passthrough |
| CurrencyID | etoro.Billing.BI_Cashout_State_Report | CurrencyID | Passthrough |
| AmountInUSD | etoro.Billing.BI_Cashout_State_Report | AmountInUSD | Passthrough |
| BaseExchangeRate | etoro.Billing.BI_Cashout_State_Report | BaseExchangeRate | Passthrough |
| ExchangeFee | etoro.Billing.BI_Cashout_State_Report | ExchangeFee | Passthrough |
| ExchangeRate | etoro.Billing.BI_Cashout_State_Report | ExchangeRate | Passthrough |
| ExTransactionID | etoro.Billing.BI_Cashout_State_Report | ExTransactionID | Passthrough |
| ModificationDate | etoro.Billing.BI_Cashout_State_Report | ModificationDate | Passthrough |
| RequestDate | etoro.Billing.BI_Cashout_State_Report | RequestDate | Passthrough |
| ProtocolMIDSettingsID | etoro.Billing.BI_Cashout_State_Report | ProtocolMIDSettingsID | Passthrough |
| MerchantAccountID | etoro.Billing.BI_Cashout_State_Report | MerchantAccountID | Passthrough |
| PIPsInUSD | etoro.Billing.BI_Cashout_State_Report | PIPsInUSD | Passthrough |
| ExchaFeeInPercentage | etoro.Billing.BI_Cashout_State_Report | ExchaFeeInPercentage | Passthrough |
| MID | etoro.Billing.BI_Cashout_State_Report | MID | Passthrough |
| MIDName | etoro.Billing.BI_Cashout_State_Report | MIDName | Passthrough |
| ModificationDateID | etoro.Billing.BI_Cashout_State_Report | ModificationDate | ETL-computed: CONVERT(INT, ModificationDate) → YYYYMMDD |
| UpdateDate | — | — | ETL-computed: GETDATE() at SP execution time |
| CreditID | etoro.Billing.BI_Cashout_State_Report | CreditID | Passthrough (added 2025-08-13) |

### 5.2 ETL Pipeline

```
etoro.Billing.BI_Cashout_State_Report (production BI report table — custom pipeline)
  |
  v [Custom pipeline — daily, NOT in _generic_pipeline_mapping.json]
Bronze/etoro/Billing/BI_Cashout_State_Report/  (assumed)
  |
  v [staging]
DWH_staging.etoro_Billing_BI_Cashout_State_Report
  |
  v [SP_Fact_Cashout_State — daily DELETE current day + INSERT]
DWH_dbo.Fact_Cashout_State (9.95M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Billing.BI_Cashout_State_Report | Custom BI reporting table consolidating cashout states (etoroDB-REAL) |
| Lake | Bronze/etoro/Billing/BI_Cashout_State_Report/ | Daily export via custom pipeline (not Generic Pipeline) |
| Staging | DWH_staging.etoro_Billing_BI_Cashout_State_Report | Raw staging import |
| ETL | SP_Fact_Cashout_State | DELETE today's rows + INSERT from staging; ModificationDateID derived; UpdateDate=GETDATE() |
| Target | DWH_dbo.Fact_Cashout_State | 9.95M rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who requested the cashout |
| CurrencyID | DWH_dbo.Dim_Currency | Currency of the cashout amount |
| ModificationDateID | DWH_dbo.Dim_Date | Date dimension for time analysis |
| DepositID | DWH_dbo.Fact_BillingDeposit | Linked deposit (for refund/chargeback scenarios) |
| FundingID | etoro.Billing.Funding | Payment instrument for payout (implicit) |

### 6.2 Referenced By (other objects point to this)

No downstream DWH consumers identified at documentation time.

---

## 7. Sample Queries

### 7.1 Daily cashout volume (USD)

```sql
SELECT
    ModificationDateID,
    COUNT(*) AS CashoutCount,
    SUM(AmountInUSD) AS TotalUSD
FROM [DWH_dbo].[Fact_Cashout_State]
WHERE ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-30,GETDATE()), 112))
GROUP BY ModificationDateID
ORDER BY ModificationDateID DESC
```

### 7.2 Status breakdown with exchange fee analysis

```sql
SELECT
    CashoutStatus,
    COUNT(*) AS CashoutCount,
    AVG(AmountInUSD) AS AvgAmountUSD,
    AVG(ExchaFeeInPercentage) AS AvgFeePct,
    SUM(PIPsInUSD) AS TotalFeeUSD
FROM [DWH_dbo].[Fact_Cashout_State]
GROUP BY CashoutStatus
ORDER BY CashoutCount DESC
```

### 7.3 ETL freshness check

```sql
SELECT MAX(ModificationDateID) AS MaxModDate, MAX(UpdateDate) AS LastETLRun
FROM [DWH_dbo].[Fact_Cashout_State]
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 | Phases: 8/14*
*Tiers: 0 T1, 20 T2, 8 T3, 0 T4-Inferred | Elements: 8.0/10, Logic: 7.5/10, Relationships: 7.0/10, Sources: 7.0/10*
*Object: DWH_dbo.Fact_Cashout_State | Type: Table | Production Source: etoro.Billing.BI_Cashout_State_Report (custom pipeline)*
