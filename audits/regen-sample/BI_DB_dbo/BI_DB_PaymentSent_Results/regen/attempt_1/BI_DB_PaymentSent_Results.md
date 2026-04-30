# BI_DB_dbo.BI_DB_PaymentSent_Results

> Operational monitoring table tracking wire withdrawal requests stuck in "Payment Sent" status beyond currency-specific aging thresholds. Rebuilt daily via TRUNCATE+INSERT by SP_H_PaymentSent_Results from production billing and history external tables. Currently 0 rows (empty when no cashouts exceed the aging rules). Filtered to wire transfers (FundingTypeID=2) in USD, EUR, GBP, AUD, CAD only, with a 4-week lookback window.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_H_PaymentSent_Results (reads External_etoro_Billing_Withdraw, External_etoro_Billing_vWithdrawToFunding, External_etoro_History_vWithdrawToFundingAction, External_etoro_Billing_Depot) |
| **Refresh** | Daily (TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | _Pending_ |
| **UC Format** | _Pending_ |
| **UC Partitioned By** | _Pending_ |
| **UC Table Type** | _Pending_ |

---

## 1. Business Meaning

`BI_DB_PaymentSent_Results` is an operational monitoring table that identifies wire withdrawal requests that have been in "Payment Sent" status longer than expected. It serves as a cashout operations alerting tool — when a wire transfer has been sent to the payment provider but not yet confirmed as processed, and the elapsed time exceeds currency- and regulation-specific thresholds, the withdrawal appears in this table for operations review.

The table is rebuilt daily by `SP_H_PaymentSent_Results`, which:
1. Queries `External_etoro_History_vWithdrawToFundingAction` for withdrawals that reached CashoutStatusID=6 ("Payment Sent") within the last 4 weeks
2. Joins to `External_etoro_Billing_Withdraw` and `External_etoro_Billing_vWithdrawToFunding` for withdrawal details
3. Filters to wire transfers only (FundingTypeID=2) in 5 currencies: USD, EUR, GBP, AUD, CAD
4. Applies aging thresholds: USD/EUR/GBP require >= 1 day; AUD requires > 2 days under CySEC or > 1 day under other regulations
5. Truncates and reloads the target table with qualifying records

The table can be empty (0 rows) when no wire withdrawals currently exceed the aging thresholds — this is a valid operational state indicating no stuck payments.

---

## 2. Business Logic

### 2.1 Wire-Only Currency Filter

**What**: Only wire transfer withdrawals in 5 specific currencies are monitored.

**Columns Involved**: `Currency`, `Amount$Withdraw`

**Rules**:
- FundingTypeID must equal 2 (Wire transfer) — all other payment methods are excluded
- ProcessCurrencyID must be one of: 1 (USD), 2 (EUR), 3 (GBP), 5 (AUD), 7 (CAD)
- Currency column shows the Abbreviation from Dim_Currency for the ProcessCurrencyID

### 2.2 Payment Sent Aging Thresholds

**What**: Different currencies and regulations have different thresholds for when a "Payment Sent" status is considered overdue.

**Columns Involved**: `DaysInPaymentSentStatus`, `Currency`, `Regulation`

**Rules**:
- USD, EUR: flagged when DaysInPaymentSentStatus >= 1
- GBP: flagged when DaysInPaymentSentStatus >= 1
- AUD + CySEC regulation: flagged when DaysInPaymentSentStatus > 2
- AUD + non-CySEC regulation: flagged when DaysInPaymentSentStatus > 1
- CAD: included in the currency filter but no explicit aging threshold in the final WHERE clause (may appear regardless of age)

### 2.3 Payment Sent Status Detection

**What**: The SP identifies withdrawals that reached "Payment Sent" status by checking CashoutStatusID=6 in the withdraw-to-funding action history.

**Columns Involved**: `ModificationDate`, `DaysInPaymentSentStatus`

**Rules**:
- CashoutStatusID=6 corresponds to "Payment Sent" in the production cashout lifecycle (note: this status is NOT in the DWH Dim_CashoutStatus which only has IDs 0-4)
- LastUpdatedDate is the MAX(ModificationDate) for the WithdrawID where CashoutStatusID=6
- DaysInPaymentSentStatus = CAST(GETDATE() - LastUpdatedDate AS int) — integer days since the payment was sent
- Only withdrawals modified within the last 4 weeks are considered

### 2.4 TRUNCATE + INSERT Pattern

**What**: The table is fully rebuilt on each run.

**Rules**:
- SP truncates BI_DB_PaymentSent_Results before inserting
- No incremental logic — every run produces a fresh snapshot of currently-overdue wire cashouts
- UpdateDate is set to GETDATE() at insert time

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distribution with CLUSTERED INDEX on CID. The table is expected to be small (operational monitoring subset), so distribution choice has minimal performance impact.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All currently stuck wire cashouts | `SELECT * FROM BI_DB_dbo.BI_DB_PaymentSent_Results ORDER BY DaysInPaymentSentStatus DESC` |
| Stuck cashouts by regulation | `GROUP BY Regulation` |
| Stuck cashouts by provider | `GROUP BY Provider` |
| Total stuck amount by currency | `SELECT Currency, SUM(Amount$Withdraw) ... GROUP BY Currency` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID = CID | Full customer details for stuck cashout investigation |

### 3.4 Gotchas

- **Table can be empty**: When no wire cashouts exceed the aging thresholds, the table has 0 rows. This is normal.
- **Wire transfers only**: FundingTypeID=2 filter means credit card, PayPal, and all other payment methods are excluded.
- **CashoutStatusID=6 is not in DWH Dim_CashoutStatus**: The "Payment Sent" status (ID=6) is a production-only status not loaded into the DWH dimension (which only has IDs 0-4). This SP reads it from external production tables directly.
- **CAD has no explicit aging threshold**: CAD is included in the currency filter but the final WHERE clause does not explicitly gate CAD withdrawals by days — they may appear with any DaysInPaymentSentStatus value.
- **Amount$Withdraw column name**: The `$` in the column name requires bracket quoting in SQL: `[Amount$Withdraw]`.
- **4-week lookback**: Only withdrawals modified within the last 4 weeks are considered. Older stuck cashouts fall out of scope.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (dim-lookup passthrough with documented origin) |
| Tier 2 | Synapse SP code (ETL-computed or passthrough from undocumented external table) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from External_etoro_Billing_Withdraw. (Tier 1 — Customer.CustomerStatic) |
| 2 | Regulation | nvarchar(1000) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Dim-lookup passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 3 | Currency | varchar(50) | YES | Ticker symbol. "USD", "EUR" for forex; "AAPL.US", "TSLA.US" for US stocks (format: TICKER.EXCHANGE); "BTC" for crypto. Unique across all instruments. Use this for human-readable instrument identification. Dim-lookup passthrough from Dim_Currency.Abbreviation via ProcessCurrencyID. In this table, only USD, EUR, GBP, AUD, CAD appear (wire transfer currencies). (Tier 1 — Dictionary.Currency) |
| 4 | Amount$Withdraw | money | NO | Withdrawal amount in the process currency. Renamed from External_etoro_Billing_vWithdrawToFunding.Amount. Represents the wire transfer amount sent to the payment provider. (Tier 2 — External_etoro_Billing_vWithdrawToFunding) |
| 5 | DaysInPaymentSentStatus | int | YES | Number of integer days the withdrawal has been in "Payment Sent" status. Computed as CAST(GETDATE() - MAX(ModificationDate) AS int) where ModificationDate is the last time the withdrawal reached CashoutStatusID=6. (Tier 2 — External_etoro_History_vWithdrawToFundingAction) |
| 6 | ModificationDate | datetime | YES | Last modification date when the withdrawal reached "Payment Sent" (CashoutStatusID=6) status. Aggregated as MAX(ModificationDate) from External_etoro_History_vWithdrawToFundingAction per WithdrawID. (Tier 2 — External_etoro_History_vWithdrawToFundingAction) |
| 7 | WithdrawID | bigint | YES | Withdrawal request identifier from the Billing system. Links to External_etoro_Billing_Withdraw. Passthrough. (Tier 2 — External_etoro_Billing_Withdraw) |
| 8 | WithdrawProcessingID | bigint | YES | Withdraw-to-funding processing record ID. Renamed from External_etoro_Billing_vWithdrawToFunding.ID. Identifies the specific funding action within a withdrawal. (Tier 2 — External_etoro_Billing_vWithdrawToFunding) |
| 9 | FundingID | bigint | YES | Funding record identifier linking to the funding instrument used for this withdrawal. Passthrough from External_etoro_Billing_vWithdrawToFunding. (Tier 2 — External_etoro_Billing_vWithdrawToFunding) |
| 10 | Provider | nvarchar(1000) | YES | Payment provider/depot name handling the wire transfer. Renamed from External_etoro_Billing_Depot.Name via DepotID lookup. (Tier 2 — External_etoro_Billing_Depot) |
| 11 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at insert time by SP_H_PaymentSent_Results. Not a business date. (Tier 2 — SP_H_PaymentSent_Results) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Billing.Withdraw (via External) | CID | Passthrough |
| Regulation | Dictionary.Regulation (via Dim_Regulation) | Name | Dim-lookup passthrough |
| Currency | Dictionary.Currency (via Dim_Currency) | Abbreviation | Dim-lookup passthrough (rename) |
| Amount$Withdraw | Billing.vWithdrawToFunding (via External) | Amount | Rename |
| DaysInPaymentSentStatus | History.vWithdrawToFundingAction (via External) | ModificationDate | Computed: CAST(GETDATE() - MAX(ModificationDate) AS int) |
| ModificationDate | History.vWithdrawToFundingAction (via External) | ModificationDate | Aggregated: MAX per WithdrawID where CashoutStatusID=6 |
| WithdrawID | Billing.Withdraw (via External) | WithdrawID | Passthrough |
| WithdrawProcessingID | Billing.vWithdrawToFunding (via External) | ID | Rename |
| FundingID | Billing.vWithdrawToFunding (via External) | FundingID | Passthrough |
| Provider | Billing.Depot (via External) | Name | Rename |
| UpdateDate | - | - | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
Production Billing & History tables
  |-- External tables (BI_DB_dbo.External_etoro_*) ---|
  v
#LastUpdatedDate (temp)
  <- External_etoro_History_vWithdrawToFundingAction
  <- MAX(ModificationDate) WHERE CashoutStatusID=6, last 4 weeks
  v
#cashouts (temp)
  <- External_etoro_Billing_Withdraw (base withdrawals)
  <- External_etoro_Billing_vWithdrawToFunding (funding details)
  <- External_etoro_Billing_Funding_Datafactory (FundingTypeID=2 filter)
  <- External_etoro_Billing_Depot (provider name)
  <- DWH_dbo.Dim_Customer (RegulationID)
  <- DWH_dbo.Dim_Currency (Abbreviation for ProcessCurrencyID)
  <- DWH_dbo.Dim_CashoutStatus (status name, intermediate)
  <- DWH_dbo.Dim_Regulation (regulation name)
  v
#final (temp)
  <- #cashouts JOIN #LastUpdatedDate
  <- WHERE CashoutStatus_Funding = 'Payment Sent'
  <- Currency/Regulation aging thresholds applied
  v
TRUNCATE BI_DB_dbo.BI_DB_PaymentSent_Results
INSERT (11 columns + GETDATE() as UpdateDate)
  v
BI_DB_dbo.BI_DB_PaymentSent_Results (0+ rows, operational snapshot)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension lookup |
| WithdrawID | External_etoro_Billing_Withdraw | Source withdrawal record |
| FundingID | External_etoro_Billing_Funding_Datafactory | Source funding record |

### 6.2 Referenced By (other objects point to this)

No objects reference this table. It is a terminal reporting/monitoring table.

---

## 7. Sample Queries

### 7.1 All stuck wire cashouts ordered by aging
```sql
SELECT  CID,
        Regulation,
        Currency,
        [Amount$Withdraw],
        DaysInPaymentSentStatus,
        ModificationDate,
        Provider
FROM    [BI_DB_dbo].[BI_DB_PaymentSent_Results]
ORDER BY DaysInPaymentSentStatus DESC;
```

### 7.2 Total stuck amount by currency and regulation
```sql
SELECT  Currency,
        Regulation,
        COUNT(*) AS StuckCount,
        SUM([Amount$Withdraw]) AS TotalStuckAmount
FROM    [BI_DB_dbo].[BI_DB_PaymentSent_Results]
GROUP BY Currency, Regulation
ORDER BY TotalStuckAmount DESC;
```

### 7.3 Stuck cashouts by provider
```sql
SELECT  Provider,
        COUNT(*) AS StuckCount,
        SUM([Amount$Withdraw]) AS TotalAmount,
        MAX(DaysInPaymentSentStatus) AS MaxDaysStuck
FROM    [BI_DB_dbo].[BI_DB_PaymentSent_Results]
GROUP BY Provider
ORDER BY StuckCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 10/14 (no Atlassian)*
*Tiers: 3 T1, 8 T2, 0 T3, 0 T4 | Elements: 11/11, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_PaymentSent_Results | Type: Table | Production Source: SP_H_PaymentSent_Results (Billing external tables)*
