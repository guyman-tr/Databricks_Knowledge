# BI_DB_dbo.BI_DB_LargeCashoutReport

> Daily compliance snapshot of all large withdrawal requests (≥$20K) currently in Pending or InProcess status (14 cols, ~117 rows, refreshed daily). Written by `SP_LargeCashOutReport` from `External_etoro_Billing_Withdraw`. Enriched with customer name, account manager, country, region, desk routing, current equity, and total deposits. Used by account managers and the compliance team for daily follow-up on high-value cashout requests. ⚠️ Contains PII (customer full names, account manager names).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Billing.Withdraw` via `External_etoro_Billing_Withdraw`; enriched from `Dim_Customer`, `Dim_Manager`, `Dim_Country`, `V_Liabilities` |
| **Refresh** | Daily SB_Daily (TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | — |
| **Row Count** | ~117 (117 rows as of 2026-04-12; fluctuates daily with cashout queue) |

---

## 1. Business Meaning

`BI_DB_LargeCashoutReport` is a **live compliance and account management dashboard** for large withdrawal requests. It contains every active (Pending or InProcess) cashout of $20,000 USD or more that has not yet been completed or cancelled.

Each daily run fully replaces the table with the current state of the cashout queue. The table enables:
- **Account managers** to see which of their high-value clients have pending withdrawals and prioritize follow-up
- **Compliance / risk teams** to monitor large cashout activity, flag affiliate-requested cashouts, and track processing delays (DaysFromCoRequest)
- **Desk-level routing** via the Desk column — each region maps to a specific sales/service desk responsible for that geography

With ~117 rows in the current queue (April 2026), the table is very small and suitable for full-result queries. The row count fluctuates daily as new requests arrive and existing ones are processed.

**Key threshold**: $20,000 USD (`@CoAmount = 20000`) — a hardcoded constant in the SP. Cashouts below this threshold do not appear in this report.

**PII note**: This table contains full customer names (`CustomerName`) and account manager names (`AccountManager`). Access should be governed accordingly.

---

## 2. Business Logic

### 2.1 Eligibility: $20K Threshold + Active Status

**What**: Only large, currently-actionable cashout requests are included.

**Columns Involved**: Amount, CashoutStatus, CID

**Rules**:
- `Amount >= 20000` (USD) — hardcoded `@CoAmount = 20000` in the SP
- `CashoutStatusID IN (1, 2)`: Pending (1) or InProcess (2) only
- StatusID 3 (Processed), 4 (Cancelled), and specialized states (5, 7, 8, 14, 16, 17) are excluded — this is a live queue of unresolved requests, not a historical log
- Customer exclusions: `PlayerLevelID ≠ 4` (excludes demo/test accounts), `LabelID ≠ 30`, `AccountTypeID ≠ 9`
- LEFT JOIN to Dim_Customer: if the customer has no matching Dim_Customer row after filters, CustomerName/AccountManager/Country will be NULL but the row is still included (from #temp)

### 2.2 Business Day Calculation for DaysFromCoRequest

**What**: Measures processing elapsed time in business days, excluding weekends.

**Columns Involved**: DaysFromCoRequest, RequestDate

**Rules**:
- Formula: `DaysFromCoRequest = DATEDIFF(dd, RequestDate, GETDATE()) - (DATEDIFF(wk, RequestDate, GETDATE()) * 2) + weekend adjustments`
- Adjustments: +1 if RequestDate is a Saturday (DATEPART(dw)=7); -1 if RequestDate is a Sunday (DATEPART(dw)=1); -1 if GETDATE() is a Sunday
- This approximates ISO business days but does NOT exclude public holidays
- A value of 0 means the request was submitted today or yesterday
- Used by account managers to prioritize follow-up on stale pending requests

### 2.3 AffiliateCO Flag

**What**: Identifies withdrawals specifically initiated through affiliate cashout channels.

**Columns Involved**: AffiliateCO

**Rules**:
- `AffiliateCO = CASE WHEN CashoutReasonID IN (14, 15) THEN 1 ELSE 0 END`
- CashoutReasonIDs 14 and 15 correspond to affiliate-specific withdrawal reasons in `Billing.Withdraw`
- AffiliateCO = 1 signals that the cashout may require additional affiliate partner coordination
- Distribution in live data (April 2026): all sampled rows have AffiliateCO = 0 — affiliated cashouts may be rare events

### 2.4 Desk Routing: Hardcoded Region → Desk Mapping

**What**: Routes each cashout to the responsible sales/service desk based on the customer's marketing region.

**Columns Involved**: Desk, Region

**Rules**:
- Hardcoded mapping in #desk temp table (19 Region values → 8 Desk labels):
  - UK → 'UK'
  - German → 'German'
  - French → 'French'; Israel → 'French'
  - Italian → 'Italian'
  - Spain → 'Spain'; South & Central America → 'Spain'
  - Arabic GCC → 'Arabic'; Arabic Other → 'Arabic'
  - Eastern Europe → 'Eastern Europe'
  - Russian → 'Russian'
  - China → 'China'
  - Africa, Australia, Canada, North Europe, Other Asia, ROE, ROW → 'ROW'
- INNER JOIN on #desk (not LEFT JOIN): customers whose Region does not match any of the 19 mapped values will be excluded from the result
- The Desk mapping is static and encoded in the SP — any region additions to Dim_Country require a corresponding SP update to avoid exclusions

### 2.5 Equity and Deposit Enrichment

**What**: Contextualizes the cashout request with the customer's current financial position.

**Columns Involved**: CurrentEquity, TotalDeposits

**Rules**:
- `CurrentEquity = V_Liabilities.Liabilities + V_Liabilities.ActualNWA` at `DateID = yesterday's date` (`@ddint`). Represents the customer's net equity position including unrealized exposure. LEFT JOIN — NULL if V_Liabilities has no row for the customer at yesterday's DateID.
- `TotalDeposits = External_etoro_BackOffice_CustomerAllTimeAggregatedData.TotalDeposit` — the customer's total all-time USD deposit amount. LEFT JOIN — NULL if no matching record. Stored as bigint (integer USD).
- Account managers use CurrentEquity / Amount ratio to assess whether the withdrawal would significantly deplete the customer's position, and TotalDeposits to gauge long-term value.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution: ROUND_ROBIN. Clustered on CID. With only ~117 rows, all queries are full-table scans regardless of index. No query optimization needed at this scale.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All pending large cashouts for a desk | `SELECT * WHERE Desk = 'UK' AND CashoutStatus = 'Pending' ORDER BY Amount DESC` |
| Stale pending requests (> 3 business days) | `SELECT * WHERE CashoutStatus = 'Pending' AND DaysFromCoRequest > 3 ORDER BY DaysFromCoRequest DESC` |
| Total value of pending cashouts by desk | `SELECT Desk, SUM(Amount) TotalPending, COUNT(CID) Requests WHERE CashoutStatus = 'Pending' GROUP BY Desk ORDER BY TotalPending DESC` |
| Cashout vs. equity ratio by region | `SELECT Region, CID, CustomerName, Amount, CurrentEquity, Amount * 1.0 / NULLIF(CurrentEquity, 0) AS CashoutPct ORDER BY CashoutPct DESC` |
| Data freshness | `SELECT MAX(UpdateDate) FROM [BI_DB_dbo].[BI_DB_LargeCashoutReport]` |

### 3.3 Gotchas

- **This is NOT a historical log**: TRUNCATE runs daily — only today's Pending/InProcess queue is visible. Use `Billing.Withdraw` directly for historical cashout analysis.
- **$20K threshold is hardcoded**: Changing the threshold requires an SP code change to `@CoAmount`. The wiki description reflects the production value (20000 USD).
- **INNER JOIN on Desk table**: Customers in regions not covered by the #desk mapping (e.g., new regions added to Dim_Country) will be silently excluded. If the row count seems unexpectedly low, check whether all regions are covered in the SP's #desk inserts.
- **AffiliateCO logic is binary**: The flag uses CashoutReasonID IN (14,15). The actual meaning of ReasonIDs 14 and 15 is defined in Dictionary.CashoutReasonID — consult the Billing.Withdraw upstream wiki for the full ReasonID dictionary.
- **DaysFromCoRequest excludes public holidays**: The formula uses a simple weekend-subtraction formula. Bank holidays and regional holidays are NOT excluded. A request spanning a multi-day public holiday will appear to have accumulated business days that were not actual working days.
- **CustomerName can be NULL**: LEFT JOIN on Dim_Customer means internal/filtered accounts (PlayerLevelID=4, LabelID=30, AccountTypeID=9) will have NULL CustomerName and AccountManager but will still appear in the table.
- **CashoutStatus 'Null' is possible**: The SP uses `ELSE 'Null'` for any CashoutStatusID not matching 1 or 2. If the filtering (`WHERE CashoutStatusID IN (1,2)`) is correctly applied in #temp, this ELSE branch should be unreachable — but if it appears, it signals an unexpected CashoutStatusID in the source.
- **PII**: CustomerName and AccountManager contain real individual full names. This table should not be shared in analytics reports without anonymization or appropriate access controls.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki — passthrough column |
| Tier 2 | SP-derived, dimension-joined, or computed field |
| Propagation | Canonical ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — FK to `Customer.CustomerStatic`. The customer who submitted the cashout request. Primary join key to Dim_Customer. NOT NULL — every row has a CID from Billing.Withdraw. (Tier 1 — Billing.Withdraw) |
| 2 | CustomerName | varchar(100) | YES | Customer's full legal name: `Dim_Customer.FirstName + ' ' + Dim_Customer.LastName`. Contains real PII. NULL for customers excluded by PlayerLevelID, LabelID, or AccountTypeID filters on the LEFT JOIN. (Tier 1 — Customer.CustomerStatic) |
| 3 | RequestDate | datetime | YES | Timestamp when the customer submitted the withdrawal request, from `Billing.Withdraw.RequestDate`. Used to compute DaysFromCoRequest and to understand request urgency. (Tier 1 — Billing.Withdraw) |
| 4 | Amount | int | YES | Gross withdrawal amount in USD (cast to int from money type in Billing.Withdraw). All rows ≥ $20,000 by population filter. Sample range: $20K to $374K as of 2026-04-12. (Tier 1 — Billing.Withdraw) |
| 5 | CashoutStatus | varchar(500) | YES | Human-readable withdrawal status derived from `Billing.Withdraw.CashoutStatusID`: 1 → 'Pending', 2 → 'InProcess'. Only these two values appear — the SP filters to CashoutStatusID IN (1,2). Distribution (2026-04-12): Pending=75, InProcess=42. (Tier 2 — SP_LargeCashOutReport) |
| 6 | AffiliateCO | int | YES | Affiliate cashout flag: 1 if `Billing.Withdraw.CashoutReasonID IN (14, 15)`, else 0. Identifies cashouts initiated via affiliate channels that may require partner coordination. See Billing.Withdraw upstream wiki for CashoutReasonID dictionary. (Tier 2 — SP_LargeCashOutReport) |
| 7 | AccountManager | varchar(5000) | YES | Full name of the assigned account manager: `Dim_Manager.FirstName + ' ' + Dim_Manager.LastName` via `Dim_Customer.AccountManagerID`. Contains real PII. NULL for customers without an assigned manager or excluded by customer filters. (Tier 2 — Dim_Manager via BackOffice.Manager) |
| 8 | Country | varchar(500) | YES | Customer's country of residence in English from `DWH_dbo.Dim_Country.Name` via `Dim_Customer.CountryID`. INNER JOIN via #desk means only countries with a mapped Region → Desk will appear. (Tier 1 — Dictionary.Country) |
| 9 | Region | varchar(500) | YES | Marketing region label from `DWH_dbo.Dim_Country.Region` (etoro.Dictionary.MarketingRegion.Name). 12 distinct values in current data (e.g., UK, Arabic GCC, German). The lookup key for the Desk mapping. (Tier 2 — Dim_Country.Region via Dictionary.MarketingRegion) |
| 10 | Desk | varchar(500) | YES | Sales/service desk responsible for this customer's geography. Hardcoded Region → Desk mapping in the SP (#desk temp table): UK→'UK', German→'German', French/Israel→'French', Italian→'Italian', Spain/South&Central America→'Spain', Arabic GCC/Arabic Other→'Arabic', Eastern Europe→'Eastern Europe', Russian→'Russian', China→'China', all others→'ROW'. (Tier 2 — SP_LargeCashOutReport hardcoded mapping) |
| 11 | DaysFromCoRequest | int | YES | Business days elapsed from `RequestDate` to today (GETDATE()), excluding Saturday and Sunday. Does NOT exclude public holidays. A value of 0 indicates the request was submitted today or yesterday; higher values flag processing delays requiring escalation. (Tier 2 — SP_LargeCashOutReport business-day calculation) |
| 12 | CurrentEquity | bigint | YES | Customer's current equity position: `V_Liabilities.Liabilities + V_Liabilities.ActualNWA` at yesterday's DateID. Includes unrealized positions. LEFT JOIN — NULL if V_Liabilities has no row for the customer. Used to assess whether the cashout would deplete most of the customer's equity. (Tier 2 — DWH_dbo.V_Liabilities) |
| 13 | TotalDeposits | bigint | YES | Customer's total all-time USD deposit amount from `External_etoro_BackOffice_CustomerAllTimeAggregatedData.TotalDeposit`. Stored as integer USD. LEFT JOIN — NULL if no record. Provides context for the customer's long-term deposit value. (Tier 2 — BackOffice.CustomerAllTimeAggregatedData) |
| 14 | UpdateDate | datetime | YES | ETL metadata: timestamp when the table was last refreshed by SP_LargeCashOutReport. Set to GETDATE() at INSERT time. Since this is a TRUNCATE+INSERT, all rows share the same UpdateDate from the most recent daily run. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | etoro.Billing.Withdraw | CID | Direct passthrough |
| RequestDate | etoro.Billing.Withdraw | RequestDate | Direct passthrough |
| Amount | etoro.Billing.Withdraw | Amount | Cast to int from money |
| CashoutStatus | etoro.Billing.Withdraw | CashoutStatusID | CASE: 1→'Pending', 2→'InProcess' |
| AffiliateCO | etoro.Billing.Withdraw | CashoutReasonID | CASE: IN(14,15)→1, else→0 |
| CustomerName | Customer.CustomerStatic | FirstName, LastName | Via Dim_Customer — concatenate |
| AccountManager | BackOffice.Manager | FirstName, LastName | Via Dim_Manager on AccountManagerID |
| Country | Dictionary.Country | Name | Via Dim_Country on CountryID |
| Region | Dictionary.MarketingRegion | Name | Via Dim_Country.Region |
| Desk | SP hardcoded | — | #desk mapping: Region → Desk label |
| DaysFromCoRequest | Computed | RequestDate, GETDATE() | Business-days DATEDIFF formula |
| CurrentEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | SUM two columns at yesterday's DateID |
| TotalDeposits | BackOffice.CustomerAllTimeAggregatedData | TotalDeposit | Via external table |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
External_etoro_Billing_Withdraw (etoro.Billing.Withdraw)
  Filter: CashoutStatusID IN (1,2) AND Amount >= $20,000
  → CashoutStatus label (CASE on StatusID)
  → AffiliateCO flag (CASE on ReasonID)
  → DaysFromCoRequest (business-day calculation)
  + LEFT JOIN Dim_Customer (CustomerName, AccountManagerID; filters: PL≠4, Label≠30, AccType≠9)
  + LEFT JOIN Dim_Manager (AccountManager name)
  + INNER JOIN Dim_Country (Country, Region)
  + INNER JOIN #desk (Desk routing)
  + LEFT JOIN V_Liabilities (CurrentEquity at yesterday)
  + LEFT JOIN External_BackOffice_CustomerAllTimeAggregatedData (TotalDeposits)
         |-- SP_LargeCashOutReport (daily) ---|
         |   TRUNCATE TABLE; INSERT queue      |
         v
BI_DB_dbo.BI_DB_LargeCashoutReport (~117 rows, live queue)
  |-- (No UC target — Not Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | etoro.Billing.Withdraw | Source of cashout requests |
| CustomerName | DWH_dbo.Dim_Customer | Customer name and account metadata |
| AccountManager | DWH_dbo.Dim_Manager | Account manager lookup |
| Country, Region | DWH_dbo.Dim_Country | Geographic enrichment |
| CurrentEquity | DWH_dbo.V_Liabilities | Live equity position |
| TotalDeposits | External_etoro_BackOffice_CustomerAllTimeAggregatedData | All-time deposit aggregate |

### 6.2 Referenced By

| Object | How Used |
|--------|----------|
| Account Manager dashboards | Daily monitoring of large pending cashouts assigned to their clients |
| Compliance / Risk team | Follow-up on high-value and stale cashout requests |

---

## 7. Sample Queries

### 7.1 All pending cashouts by desk, sorted by amount
```sql
SELECT Desk, CID, CustomerName, Country, Amount, DaysFromCoRequest,
       CurrentEquity, TotalDeposits, AccountManager
FROM [BI_DB_dbo].[BI_DB_LargeCashoutReport]
WHERE CashoutStatus = 'Pending'
ORDER BY Desk, Amount DESC;
```

### 7.2 Stale requests needing escalation (> 3 business days)
```sql
SELECT CID, CustomerName, RequestDate, Amount, CashoutStatus,
       Desk, DaysFromCoRequest, AccountManager
FROM [BI_DB_dbo].[BI_DB_LargeCashoutReport]
WHERE DaysFromCoRequest > 3
ORDER BY DaysFromCoRequest DESC, Amount DESC;
```

### 7.3 Cashout as a percentage of current equity
```sql
SELECT CID, CustomerName, Region, Desk,
       Amount, CurrentEquity,
       CAST(Amount * 100.0 / NULLIF(CurrentEquity, 0) AS DECIMAL(5,1)) AS CashoutEquityPct,
       TotalDeposits
FROM [BI_DB_dbo].[BI_DB_LargeCashoutReport]
ORDER BY CashoutEquityPct DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this table.

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Batch: 52*
*Tiers: 5 T1, 8 T2, 0 T3, 0 T4, 1 Propagation | Elements: 14/14, Logic: 5 subsections*
*Object: BI_DB_dbo.BI_DB_LargeCashoutReport | Type: Table | Source: etoro.Billing.Withdraw (large cashout queue ≥$20K, Pending/InProcess)*
