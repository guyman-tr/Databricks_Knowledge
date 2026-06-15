# BI_DB_dbo.BI_DB_Finance_Net_MIMO

> Daily net money-in/money-out (MIMO) aggregation table: 699K rows (Jan 2021 – Apr 2026), approved deposits as positive inflows and approved withdrawals as negative outflows, grouped by FundingType × Currency × Regulation × Club × IsCreditReportValidCB per day; $10.9B net positive MIMO across the period with CySEC the largest regulated market.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingDeposit + DWH_dbo.Fact_BillingWithdraw + DWH_dbo.Fact_SnapshotCustomer + 5 dimension tables via SP_Finance_Net_MIMO |
| **Refresh** | Daily (SB_Daily Priority 20); DELETE WHERE ModificationDateID = @DateID + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (ModificationDateID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 699,055 rows |
| **Date Range** | 2021-01-01 to 2026-04-12 (1,928 distinct dates) |

---

## 1. Business Meaning

`BI_DB_Finance_Net_MIMO` is a daily net money-flow fact table. **MIMO = Money In, Money Out**: the table measures how much money entered and left the eToro platform on each day, broken down by payment method, currency, regulatory jurisdiction, and customer segment.

Each row represents the net financial flow for a specific combination of (ModificationDate, FundingType, Currency, Regulation, Club, IsCreditReportValidCB). `Net_MIMO_AmountUSD` is positive when more money came in (net inflow) and negative when more money went out (net outflow) for that segment.

**Scale and composition (live data)**:
- Total net MIMO (Jan 2021 – Apr 2026): **+$10.95B** (platform received more than it paid out)
- Gross inflows (positive rows): +$20.3B | Gross outflows (negative rows): -$9.4B
- 699K dimension combinations across 1,928 trading days
- 21 distinct funding types, 30 currencies, 14+ regulations, 6 clubs

**Regulatory composition by net MIMO**:
- CySEC: $6.2B (227K rows) — largest market
- FCA: $2.7B (162K rows)
- ASIC & GAML: $1.1B (119K rows)
- BVI: -$204M negative (net outflow — more withdrawals than deposits for this jurisdiction)

**Top channels (sample 2026-04-12)**: eToroMoney EUR is the dominant funding type, followed by CreditCard EUR. eToroMoney deposits and withdrawals are always 1:1 transaction-to-subtransaction (no multi-payment attempts).

**Use case**: Finance team daily monitoring of platform money flows — used for liquidity management, regulatory reporting, revenue analysis, and monitoring of deposit/withdrawal patterns by market and payment method.

---

## 2. Business Logic

### 2.1 MIMO Sign Convention (Deposits Positive, Withdrawals Negative)

**What**: Net_MIMO_AmountUSD = net USD flow where deposits are inflows (+) and withdrawals are outflows (−).
**Columns Involved**: `Net_MIMO_AmountUSD`
**Rules**:
- Deposits: `SUM(ISNULL(fbd.AmountUSD, 0))` — already positive
- Withdrawals: `SUM(fbw.Amount_WithdrawToFunding * -1)` — sign-flipped to represent money leaving
- After UNION ALL and GROUP BY: `SUM(Total_AmountUSD)` across both stages = Net_MIMO
- Positive Net_MIMO: more deposits than withdrawals on that day for that dimension combination
- Negative Net_MIMO: more withdrawals than deposits
- A row can appear with Net_MIMO = 0 if deposits exactly equal withdrawals (rare)

### 2.2 Approved Events Only

**What**: Only successfully completed transactions are included.
**Columns Involved**: (implicit in SP filter)
**Rules**:
- Deposits: `WHERE PaymentStatusID = 2` — Approved deposits only (not pending, failed, or cancelled)
- Withdrawals: `WHERE CashoutStatusID_Withdraw = 3` — Approved/completed withdrawals only
- This means MIMO reflects actual settled financial flows, not attempted or pending ones

### 2.3 Valid Customers Only

**What**: Demo accounts and invalid customer records are excluded.
**Columns Involved**: `IsCreditReportValidCB` (the only customer validity dimension surfaced in output)
**Rules**:
- SP filters `Fact_SnapshotCustomer WHERE IsValidCustomer = 1` — only valid retail customers
- IsValidCustomer is NOT in the output table — all rows implicitly represent IsValidCustomer=1 populations
- `IsCreditReportValidCB` is a further dimension within the valid-customer population

### 2.4 Transaction vs SubTransaction Count

**What**: Distinguishes unique payment requests from payment attempts.
**Columns Involved**: `Total_Transaction_Count`, `Total_SubTransaction_Count`
**Rules**:
- **Deposits**: `Transaction_Count = COUNT(DISTINCT DepositID)`, `SubTransaction_Count = COUNT(DepositID)` — always equal since each deposit has one record
- **Withdrawals**: `Transaction_Count = COUNT(DISTINCT WithdrawID)`, `SubTransaction_Count = COUNT(WithdrawPaymentID)` — differ when one WithdrawID has multiple WithdrawPaymentIDs (customer attempts multiple payment methods for the same withdrawal)
- Net table sums both stages: `Total_Transaction_Count = deposits_transaction_count + withdrawals_transaction_count`
- When Total_Transaction_Count ≠ Total_SubTransaction_Count: there are multi-payment withdrawal attempts in the segment

### 2.5 Funding Type Asymmetry (Deposit vs Withdrawal Side)

**What**: The FundingType dimension uses different source columns for deposits and withdrawals.
**Columns Involved**: `FundingTypeID`, `FundingType`
**Rules**:
- Deposits: `FundingTypeID = fbd.FundingTypeID` (customer's chosen deposit method)
- Withdrawals: `FundingTypeID = fbw.FundingTypeID_Funding` (processor's funding type — the payment method used to pay out, not what the customer originally used to deposit)
- Currency similarly: deposits use `CurrencyID`, withdrawals use `ProcessCurrencyID` (processing currency at withdrawal)

### 2.6 Daily Refresh Pattern

**What**: Each day's data is fully deleted and re-inserted when the SP runs.
**Columns Involved**: `ModificationDateID`, `UpdateDate`
**Rules**:
- `DELETE FROM BI_DB_Finance_Net_MIMO WHERE ModificationDateID = @DateID`
- INSERT fresh aggregated data for that date
- Historic dates remain stable unless explicitly re-run (no full-table reload)
- `UpdateDate = GETDATE()` records the refresh timestamp

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on ModificationDateID ASC. Date-range queries (most common access pattern) benefit from the clustered index allowing efficient range seeks. 699K rows is moderately sized — use date filters to avoid full scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Daily net MIMO for a regulation | `WHERE Regulation = 'FCA' GROUP BY ModificationDate ORDER BY ModificationDate` |
| Net MIMO by funding type for a month | `WHERE ModificationDate BETWEEN '2026-03-01' AND '2026-03-31' GROUP BY FundingType` |
| Deposit-heavy vs withdrawal-heavy days | `WHERE Net_MIMO_AmountUSD < 0 GROUP BY ModificationDate` (negative = net outflow) |
| Transaction volume by club/tier | `GROUP BY ModificationDate, Club, SUM(Total_Transaction_Count)` |
| Currency exposure by regulation | `GROUP BY Regulation, Currency, SUM(Net_MIMO_AmountUSD)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_FundingType | `FundingTypeID = dft.FundingTypeID` | Additional funding type metadata |
| DWH_dbo.Dim_Currency | `CurrencyID = cur.CurrencyID` | Currency details (full name, symbol) |
| DWH_dbo.Dim_Regulation | `RegulationID = dr.DWHRegulationID` | Regulation metadata |

### 3.4 Gotchas

- **All rows are IsValidCustomer=1**: The SP filters valid customers before aggregation — IsValidCustomer is NOT a column. Do not assume demo traffic is present.
- **Withdrawals are sign-flipped**: `Net_MIMO_AmountUSD < 0` means more withdrawals than deposits — do not interpret negative as an error.
- **FundingType is processor-side for withdrawals**: A customer who withdrew via their credit card may appear under a different FundingType depending on the processor's payout method. This means you cannot split withdrawals by customer deposit method using this table.
- **Transaction count is additive (deposits + withdrawals)**: `Total_Transaction_Count` is the SUM of both inflow and outflow unique counts. It does not represent unique customers.
- **SubTransaction > Transaction for withdrawals**: When a withdrawal has multiple payment attempts (multiple WithdrawPaymentIDs), SubTransaction > Transaction. The difference indicates re-attempted payments.
- **BVI and FinCEN+FINRA are net negative**: These jurisdictions have historically more withdrawals than deposits — their Net_MIMO_AmountUSD sums are negative. Expected behavior.
- **Gaps on non-trading days**: ModificationDate corresponds to actual billing events. Days with no approved deposits or withdrawals produce no rows for that date.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream DWH_dbo wiki (canonical source) |
| Tier 2 | Description derived from SP code, DDL, or ETL logic (high confidence) |
| Tier 3 | Description inferred from column name, data patterns (medium confidence) |
| Tier 4 | Description speculative — needs business SME review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ModificationDate | date | YES | Date of the financial event (deposit or withdrawal ModificationDate). Represents when the payment status was last updated to its approved state. (Tier 2 — SP_Finance_Net_MIMO) |
| 2 | ModificationDateID | int | YES | YYYYMMDD integer representation of ModificationDate. Clustered index key for date-range query performance. ETL delete key: DELETE WHERE ModificationDateID = @DateID before re-inserting. (Tier 2 — SP_Finance_Net_MIMO) |
| 3 | FundingTypeID | int | YES | Integer foreign key for the funding/payment method. Deposits: Fact_BillingDeposit.FundingTypeID. Withdrawals: Fact_BillingWithdraw.FundingTypeID_Funding (processor side). (Tier 2 — SP_Finance_Net_MIMO) |
| 4 | FundingType | varchar(50) | NOT NULL | Funding/payment method name from DWH_dbo.Dim_FundingType (e.g., 'eToroMoney', 'CreditCard', 'WireTransfer'). For withdrawals, reflects the payment processor method, not the customer's original deposit method. (Tier 2 — SP_Finance_Net_MIMO) |
| 5 | CurrencyID | int | YES | Integer foreign key for the transaction currency. Deposits: Fact_BillingDeposit.CurrencyID. Withdrawals: Fact_BillingWithdraw.ProcessCurrencyID (processing currency). (Tier 2 — SP_Finance_Net_MIMO) |
| 6 | Currency | varchar(20) | NOT NULL | Currency abbreviation from DWH_dbo.Dim_Currency (e.g., 'EUR', 'GBP', 'USD'). 30 distinct currencies observed. For withdrawals, represents the processing currency. (Tier 2 — SP_Finance_Net_MIMO) |
| 7 | RegulationID | tinyint | YES | Regulatory jurisdiction ID from DWH_dbo.Fact_SnapshotCustomer. Used to join Dim_Regulation via DWHRegulationID. GROUP BY dimension. (Tier 2 — SP_Finance_Net_MIMO) |
| 8 | Regulation | varchar(50) | YES | Regulatory jurisdiction name from DWH_dbo.Dim_Regulation (e.g., 'CySEC', 'FCA', 'ASIC & GAML', 'BVI'). 14 distinct regulations observed. (Tier 2 — SP_Finance_Net_MIMO) |
| 9 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 10 | Club | varchar(50) | NOT NULL | Customer club/tier name from DWH_dbo.Dim_PlayerLevel (e.g., 'Bronze', 'Platinum', 'Platinum Plus'). Snapshot value at the time of the transaction via SCD2 Dim_Range join. 6 distinct clubs observed. (Tier 2 — SP_Finance_Net_MIMO) |
| 11 | Total_Transaction_Count | int | YES | Net sum of unique payment events for this dimension combination: COUNT(DISTINCT DepositID) for deposits + COUNT(DISTINCT WithdrawID) for withdrawals. Counts both inflows and outflows. (Tier 2 — SP_Finance_Net_MIMO) |
| 12 | Total_SubTransaction_Count | int | YES | Net sum of payment attempts: COUNT(DepositID) + COUNT(WithdrawPaymentID). Equals Total_Transaction_Count for deposits; exceeds it for withdrawals with multiple payment attempts (multiple WithdrawPaymentIDs per WithdrawID). (Tier 2 — SP_Finance_Net_MIMO) |
| 13 | Net_MIMO_AmountUSD | decimal(38,2) | YES | Net USD money flow for this dimension combination: SUM of deposit AmountUSD (positive) + SUM of withdrawal Amount_WithdrawToFunding × −1 (negative). Positive = net inflow; negative = net outflow. (Tier 2 — SP_Finance_Net_MIMO) |
| 14 | UpdateDate | datetime | NOT NULL | ETL metadata: GETDATE() at INSERT. Records when this row was last refreshed by the pipeline. (Tier 2 — SP_Finance_Net_MIMO) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source Object | Source Column | Transform |
|--------|--------------|---------------|-----------|
| ModificationDate | Fact_BillingDeposit / Fact_BillingWithdraw | ModificationDate | CAST AS DATE |
| ModificationDateID | SP_Finance_Net_MIMO | ModificationDate | CAST(CONVERT(CHAR(8), date, 112) AS INT) |
| FundingTypeID | Fact_BillingDeposit / Fact_BillingWithdraw | FundingTypeID / FundingTypeID_Funding | Direct passthrough |
| FundingType | DWH_dbo.Dim_FundingType | Name | Via FundingTypeID |
| CurrencyID | Fact_BillingDeposit / Fact_BillingWithdraw | CurrencyID / ProcessCurrencyID | Direct passthrough |
| Currency | DWH_dbo.Dim_Currency | Abbreviation | Via CurrencyID / ProcessCurrencyID |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | GROUP BY passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Via snp.RegulationID = reg.DWHRegulationID |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | GROUP BY passthrough |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Via snp.PlayerLevelID |
| Total_Transaction_Count | Fact_BillingDeposit / Fact_BillingWithdraw | DepositID / WithdrawID | SUM(COUNT DISTINCT per stage) |
| Total_SubTransaction_Count | Fact_BillingDeposit / Fact_BillingWithdraw | DepositID / WithdrawPaymentID | SUM(COUNT per stage) |
| Net_MIMO_AmountUSD | Fact_BillingDeposit / Fact_BillingWithdraw | AmountUSD / Amount_WithdrawToFunding | SUM(deposits) + SUM(withdrawals × −1) |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingDeposit (PaymentStatusID=2, approved deposits)
  + DWH_dbo.Fact_BillingWithdraw (CashoutStatusID_Withdraw=3, approved withdrawals)
  + DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1; IsCreditReportValidCB, RegulationID, PlayerLevelID)
  + DWH_dbo.Dim_Range (SCD2 bridge: ModificationDateID BETWEEN FromDateID AND ToDateID)
  + DWH_dbo.Dim_FundingType (funding method name for both stages)
  + DWH_dbo.Dim_Currency (currency abbreviation for both stages)
  + DWH_dbo.Dim_Regulation (regulation name via DWHRegulationID)
  + DWH_dbo.Dim_PlayerLevel (club/tier name via PlayerLevelID)
    |-- SP_Finance_Net_MIMO @Date (Daily, SB_Daily Priority 20) ---|
    |   #deposit_agg (positive AmountUSD, PaymentStatusID=2)         |
    |   #withdraw_agg (negated Amount_WithdrawToFunding, StatusID=3) |
    |   UNION ALL → #unionall → GROUP BY dims → #netmimo             |
    |   DELETE WHERE ModificationDateID = @DateID                    |
    |   INSERT 14 columns                                             |
    v
BI_DB_dbo.BI_DB_Finance_Net_MIMO
  (699,055 rows, Jan 2021 – Apr 2026)
  UC Target: Not Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Net_MIMO_AmountUSD (deposits) | DWH_dbo.Fact_BillingDeposit | Approved deposit amounts (PaymentStatusID=2) |
| Net_MIMO_AmountUSD (withdrawals) | DWH_dbo.Fact_BillingWithdraw | Approved withdrawal amounts (CashoutStatusID_Withdraw=3) |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | Customer validity flag (SCD2 snapshot via Dim_Range) |
| FundingTypeID, FundingType | DWH_dbo.Dim_FundingType | Payment method name |
| CurrencyID, Currency | DWH_dbo.Dim_Currency | Currency abbreviation |
| RegulationID, Regulation | DWH_dbo.Dim_Regulation | Regulatory jurisdiction name |
| Club | DWH_dbo.Dim_PlayerLevel | Customer club/tier name |

### 6.2 Referenced By (other objects point to this)

No downstream SP dependencies identified in OpsDB dependency scan. This table is consumed by finance team dashboards and daily MIMO monitoring reports.

---

## 7. Sample Queries

### Daily Net MIMO by Regulation (Last 30 Days)

```sql
SELECT ModificationDate,
       Regulation,
       SUM(Net_MIMO_AmountUSD) AS Net_MIMO,
       SUM(Total_Transaction_Count) AS Transactions
FROM [BI_DB_dbo].[BI_DB_Finance_Net_MIMO]
WHERE ModificationDate >= DATEADD(day, -30, CAST(GETDATE() AS DATE))
GROUP BY ModificationDate, Regulation
ORDER BY ModificationDate DESC, Net_MIMO DESC;
```

### Top Funding Types by Net MIMO (Year-to-Date)

```sql
SELECT FundingType,
       Currency,
       SUM(Net_MIMO_AmountUSD) AS Net_MIMO_USD,
       SUM(Total_Transaction_Count) AS Total_Transactions
FROM [BI_DB_dbo].[BI_DB_Finance_Net_MIMO]
WHERE ModificationDate >= '2026-01-01'
  AND IsCreditReportValidCB = 1
GROUP BY FundingType, Currency
ORDER BY Net_MIMO_USD DESC;
```

### Net Outflow Days (Platform Paying Out More Than Taking In)

```sql
SELECT ModificationDate,
       SUM(Net_MIMO_AmountUSD) AS Daily_Net_MIMO
FROM [BI_DB_dbo].[BI_DB_Finance_Net_MIMO]
GROUP BY ModificationDate
HAVING SUM(Net_MIMO_AmountUSD) < 0
ORDER BY Daily_Net_MIMO ASC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this table. The MIMO concept (Money In / Money Out) is a standard finance reporting framework. Billing source tables (Fact_BillingDeposit, Fact_BillingWithdraw) are documented in the DWH_dbo wiki.

---

*Generated: 2026-04-22 | Quality: 9.0/10 | Phases: 13/14*
*Tiers: 1 T1, 13 T2, 0 T3, 0 T4, 0 T5 | Elements: 14/14, Logic: 9/10, Evidence: 10/10*
*Object: BI_DB_dbo.BI_DB_Finance_Net_MIMO | Type: Table | Production Source: SP_Finance_Net_MIMO via DWH_dbo.Fact_BillingDeposit + Fact_BillingWithdraw*
