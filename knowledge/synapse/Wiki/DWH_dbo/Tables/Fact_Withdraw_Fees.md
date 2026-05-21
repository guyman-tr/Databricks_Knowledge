# DWH_dbo.Fact_Withdraw_Fees

> Withdrawal transaction fact table - 6.6M rows covering processed cashouts from 2021-2024. Tracks withdrawal fees in PIPs/USD, processing details (PreparationType, ExecutionType), and payment channel attribution (CreditCard 32%, WireTransfer 23%, eToroMoney 21%, eToroCryptoWallet 8%). Pipeline stopped July 2024.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | BackOffice.GetProcessedWithdrawPCIVersion (SP) via DWH_staging.etoro_BackOffice_GetProcessedWithdrawPCIVersion |
| **Refresh** | STOPPED (staging source table dropped; last loaded 2024-07-01; data through 2024-06-30) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

DWH_dbo.Fact_Withdraw_Fees captures every processed withdrawal (cashout) transaction with its associated fee data, processing pipeline details, and payment channel information. This is the withdrawal counterpart to Fact_Deposit_Fees, covering 6.6M cashout events from 2021-12-01 to 2024-06-30.

The table's focus is fee analysis at the withdrawal level: `FeeInPIPs` (withdrawal fee in price interest points) and `PIPsinUSD` (USD value of that fee). The withdrawal-specific columns (PreparationType, ExecutionType, Executedby, PaymentOrderStatus) capture the internal processing workflow for each cashout.

Notable: `DepositID` is present in withdrawal records - this enables linking a withdrawal back to its associated deposit (required for card-match rules, where funds must return to the original payment card).

ETL uses proper DELETE+INSERT with active WHERE clause (daily incremental by StatusModificationTime), unlike Fact_Deposit_Fees which has its WHERE commented out. Pipeline stopped July 2024 when staging source was dropped.

---

## 2. Business Logic

### 2.1 Withdrawal Status Lifecycle

**What**: Tracks the final processing status of each withdrawal.

**Columns Involved**: `WithdrawStatus`, `PaymentOrderStatus`, `StatusModificationTime`

**WithdrawStatus distribution** (live data):
- Processed (6,596,539 = 99.9%): Withdrawal completed, funds sent to customer
- Partially Processed (2,971 = 0.04%): Partial amount sent
- Partialy Reversed (56 = <0.001%): Partially reversed - note: DWH has a typo "Partialy" (missing 'l')
- Rejected (38 = <0.001%): Withdrawal rejected by processor
- Reversed (28 = <0.001%): Fully reversed withdrawal
- InProcess (5 = <0.001%): Still processing at last load time

`PaymentOrderStatus`: Payment order level status (distinct from the overall WithdrawStatus).

### 2.2 Withdrawal Fee in PIPs

**What**: Withdrawal fee measured in PIPs and converted to USD.

**Columns Involved**: `FeeInPIPs`, `PIPsinUSD`, `NetCashoutDollarAmount`, `NetAmountinOrigCurrency`, `ExchangeRate`

**Rules**:
- `FeeInPIPs` (int): Withdrawal fee in price interest points
- `PIPsinUSD` (decimal): USD value of the fee
- `NetCashoutDollarAmount`: Net withdrawal amount in USD after fee deduction
- `NetAmountinOrigCurrency`: Net withdrawal amount in original currency
- `ExchangeRate`: Rate used for currency conversion

### 2.3 Withdrawal Processing Channel Breakdown

**What**: 6.6M withdrawals distributed across 16 funding methods.

**Columns Involved**: `FundingMethod`, `FundingID`, `Depot`, `MID`, `MIDName`, `CashoutType`

**FundingMethod distribution** (live data):
```
CreditCard:          2,099,893 (31.8%) - card return
WireTransfer:        1,522,101 (23.1%) - bank wire
eToroMoney:          1,394,631 (21.1%) - eToro wallet
PayPal:                721,444 (10.9%)
eToroCryptoWallet:     532,899 (8.1%)  - crypto withdrawals
OnlineBanking:          94,633 (1.4%)
iDEAL:                  62,076 (0.9%)
PWMB:                   61,707 (0.9%)
ACH:                    46,336 (0.7%)
Trustly, MoneyBookers, Przelewy24, EtoroOptions, Neteller, Payoneer, UnionPay: <0.5%
```

### 2.4 Withdrawal Processing Pipeline Types

**What**: Captures how the withdrawal was processed internally.

**Columns Involved**: `PreparationType`, `ExecutionType`, `Executedby`

**Context**: These describe the internal eToro withdrawal workflow:
- `PreparationType`: How the withdrawal was prepared (manual vs automated)
- `ExecutionType`: How it was executed (direct, batch, etc.)
- `Executedby`: Who/what executed the withdrawal (system agent or staff member)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distribution with CLUSTERED INDEX on CID. At 6.6M rows, ROUND_ROBIN provides even load across nodes. CID index supports customer-centric queries.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Delta (MANAGED), no partitioning. Consider partition by year/month for 6.6M row performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Withdrawal fees by funding method | GROUP BY FundingMethod; SUM(PIPsinUSD) |
| Processed cashout volumes | WHERE WithdrawStatus = 'Processed'; SUM(NetCashoutDollarAmount) |
| Date-range analysis | Use ModificationDateID (YYYYMMDD) for efficient filtering |
| Crypto withdrawal analysis | WHERE FundingMethod = 'eToroCryptoWallet' |
| Customer withdrawal history | WHERE CID = {cid} ORDER BY ProcessTime |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_Deposit_Fees | ON wf.DepositID = df.DepositID | Link withdrawal to originating deposit (card-match) |
| DWH_dbo.Fact_BillingDeposit (expected) | ON wf.DepositID = bd.DepositID | Original deposit reference |

### 3.4 Gotchas

- **Pipeline is dead**: Data stops at 2024-06-30. Staging table gone.
- **"Partialy Reversed" typo**: The status "Partialy Reversed" (missing 'l') appears in live data - this is a production data artifact, not a DWH error. Use LIKE or exact match accounting for the typo.
- **ProcessTime date range**: Starts 2021-12-01 (unlike deposits which start 2020). Earlier withdrawals are not in this table.
- **DepositID in withdrawals**: This links the withdrawal to the original deposit for card-match compliance (funds must return to original card). Not all withdrawals will have a DepositID.
- **ModificationDateID filter**: Use for date-range queries: `ModificationDateID >= 20240101 AND ModificationDateID < 20240701`.
- **No 3DS columns**: Withdrawals don't go through 3DS authentication; no Threedsresponse/Threedsparameters columns.
- **No RollbackReason/rollback columns**: Fact_Withdraw_Fees has no rollback tracking (unlike Fact_Reverse_Deposits for deposits).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Description |
|-------|------|-----|-------------|
| **5 stars** | Tier 5 | `(Tier 5 - domain expert)` | Domain expert confirmed |
| **4 stars** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Upstream production wiki verbatim |
| **3 stars** | Tier 2 | `(Tier 2 - ...)` | Synapse SP code or migration DDL |
| **2 stars** | Tier 3 | `(Tier 3 - ...)` | Live data sampling or DDL structure |
| **1 star** | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred from column name only |

**Identity Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. CLUSTERED INDEX key. (Tier 2 - SP_Fact_Withdraw_Fees_DL_To_Synapse passthrough) |
| 2 | WithdrawID | int | YES | Withdrawal event identifier, passed through from the staging source. Nullable; not defined as a primary key in the DDL. |
| 3 | WithdrawProcessingID | int | YES | Withdrawal processing order ID. Used in payment processing workflow. (Tier 2 - SP passthrough) |
| 4 | DepositID | int | YES | Original deposit identifier linked to this withdrawal. Required for card-match compliance - funds must return to originating payment card. NULL for non-card-match withdrawals. (Tier 2 - SP passthrough) |
| 5 | FundingID | int | YES | Funding method integer identifier. (Tier 2 - SP passthrough) |

**Status & Timing Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 6 | WithdrawStatus | nvarchar(max) | YES | Final withdrawal processing status. Values (live): Processed(99.9%), Partially Processed, Partialy Reversed (typo - missing 'l' in production), Rejected, Reversed, InProcess. (Tier 3 - live data sampling) |
| 7 | PaymentOrderStatus | nvarchar(max) | YES | Payment order status — distinct from overall withdrawal status; CS docs describe withdrawal/cashout status by method (MOP) and stage in Cashout History. (Tier 4 — Confluence, Withdrawal in BO and Statuses) |
| 8 | StatusModificationTime | datetime2(7) | YES | Timestamp of last status change. Source for ModificationDateID. ETL WHERE filter key. (Tier 2 - SP passthrough + WHERE clause) |
| 9 | ModificationDateID | int | YES | ETL date key from StatusModificationTime: YYYYMMDD integer. Efficient date-range filter. (Tier 2 - SP computed: convert(int,...StatusModificationTime...112)) |
| 10 | ProcessTime | datetime2(7) | YES | Withdrawal processing completion time. Range: 2021-12-01 to 2024-06-30. (Tier 2 - SP passthrough) |
| 11 | RequestTime | datetime2(7) | YES | Customer cashout request submission time. (Tier 2 - SP passthrough) |
| 12 | ProcessorValueDate | datetime2(7) | YES | Payment processor value date for settlement (when the provider books the transaction); may differ from `ProcessTime`. (Tier 4 — Confluence, Withdrawal in BO and Statuses) |
| 13 | UpdateDate | datetime | YES | ETL load timestamp (getdate()). Range: 2024-01-08 to 2024-07-01. (Tier 2 - SP computed: getdate()) |

**Amount & Fee Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 14 | NetCashoutDollarAmount | decimal(38,18) | YES | Net withdrawal amount in USD after fee deduction. Primary monetary measure. (Tier 2 - SP passthrough) |
| 15 | NetAmountinOrigCurrency | decimal(38,18) | YES | Net withdrawal in customer's original currency. (Tier 2 - SP passthrough) |
| 16 | Currency | nvarchar(max) | YES | Customer withdrawal currency code. (Tier 2 - SP passthrough) |
| 17 | FeeInPIPs | int | YES | Withdrawal fee in price interest points. (Tier 2 - SP passthrough) |
| 18 | PIPsinUSD | decimal(38,18) | YES | USD value of withdrawal fee. (Tier 2 - SP passthrough) |
| 19 | ExchangeRate | decimal(38,18) | YES | Exchange rate applied for currency conversion. (Tier 2 - SP passthrough) |

**Processing Pipeline Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 20 | PreparationType | nvarchar(max) | YES | How the withdrawal was prepared in the cashout pipeline (e.g. manual vs automated preparation in CO workflows). (Tier 4 — Confluence, Cashout (CO) Approval Checks) |
| 21 | ExecutionType | nvarchar(max) | YES | How execution was performed after preparation (internal routing to provider/billing). (Tier 4 — Confluence, Cashout (CO) Processing) |
| 22 | Executedby | nvarchar(max) | YES | Actor or system step associated with execution (aligns with BO cashout/withdrawal processing terminology). (Tier 4 — Confluence, Cashout (CO) Processing) |
| 23 | CashoutType | nvarchar(max) | YES | Classification of the cashout path (e.g. standard withdrawal vs internal transfer flows in related product docs). (Tier 4 — Confluence, Withdrawal issues) |
| 24 | BackOfficeWithdrawReason | nvarchar(max) | YES | BackOffice reason for the withdrawal request (customer-initiated, compliance, manual payout, etc.). (Tier 4 — Confluence, Withdrawal issues) |
| 25 | VerificationCode | nvarchar(max) | YES | Processor or gateway verification code on the withdrawal. (Tier 4 — Confluence, Lost Cashout (CO) - Credit/Debit Card (CC)) |
| 26 | VendorCode | nvarchar(max) | YES | Payment vendor-specific code from the provider. (Tier 4 — Confluence, Withdrawal in BO and Statuses) |

**Payment Channel Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 27 | FundingMethod | nvarchar(max) | YES | Withdrawal channel. Values (live): CreditCard(31.8%), WireTransfer(23.1%), eToroMoney(21.1%), PayPal(10.9%), eToroCryptoWallet(8.1%), OnlineBanking, iDEAL, PWMB, ACH, Trustly, MoneyBookers, Przelewy24, EtoroOptions, Neteller, Payoneer, UnionPay. (Tier 3 - live data distribution) |
| 28 | Brand | nvarchar(max) | YES | Card network brand (Visa, Master Card, etc.) for card withdrawals. NULL for non-card methods. (Tier 2 - SP passthrough) |
| 29 | Depot | nvarchar(max) | YES | Payment gateway/processor. (Tier 2 - SP passthrough) |
| 30 | MID | nvarchar(max) | YES | Merchant ID for processor settlement. (Tier 2 - SP passthrough) |
| 31 | MIDName | nvarchar(max) | YES | Human-readable MID description. (Tier 2 - SP passthrough) |
| 32 | PaymentDetails | nvarchar(max) | YES | Method-specific payment details (bank account info for wire, etc.). (Tier 2 - SP passthrough) |

**Customer & Regulatory Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 33 | CustomerStatus | nvarchar(max) | YES | Customer account status at withdrawal time (e.g. limited/blocked accounts affect manual cashout handling). (Tier 4 — Confluence, Cashout (CO) Approval Checks) |
| 34 | CustomerLevel | nvarchar(max) | YES | Customer tier/club level at withdrawal time; fee exemptions (e.g. Platinum+ withdrawal fee) are documented in fee-group logic. (Tier 4 — Confluence, Fee Group Logic) |
| 35 | Regulation | nvarchar(max) | YES | Regulatory jurisdiction for this customer. (Tier 2 - SP passthrough) |
| 36 | WhiteLabel | nvarchar(max) | YES | White-label brand name. (Tier 2 - SP passthrough) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| All columns (except ModificationDateID, UpdateDate) | BackOffice.GetProcessedWithdrawPCIVersion (SP) | Same name | passthrough |
| ModificationDateID | ETL computation | StatusModificationTime | convert(int, convert(varchar, dateadd(...), 112)) -> YYYYMMDD |
| UpdateDate | ETL execution time | - | getdate() |

### 5.2 ETL Pipeline

```
BackOffice.GetProcessedWithdrawPCIVersion (production SP - processed withdrawals report)
  -> DWH_staging.etoro_BackOffice_GetProcessedWithdrawPCIVersion (staging, NOW GONE)
       -> SP_Fact_Withdraw_Fees_DL_To_Synapse (@dt parameter)
            DELETE WHERE ModificationDateID in date range
            INSERT WHERE StatusModificationTime in date range
            -> DWH_dbo.Fact_Withdraw_Fees (6.6M rows, frozen at 2024-06-30)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | Customer dimension | Implicit FK to customer master |
| DepositID | DWH_dbo.Fact_Deposit_Fees | Original deposit for card-match compliance |
| FundingID | Funding type lookup | Payment method classification |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (none found) | - | No views or SPs reference this table in SSDT repo |

---

## 7. Sample Queries

### 7.1 Withdrawal volume by funding method
```sql
SELECT FundingMethod, COUNT(1) AS Withdrawals, SUM(NetCashoutDollarAmount) AS TotalUSD
FROM [DWH_dbo].[Fact_Withdraw_Fees]
WHERE WithdrawStatus = 'Processed'
GROUP BY FundingMethod
ORDER BY TotalUSD DESC;
```

### 7.2 Withdrawal fee analysis
```sql
SELECT FundingMethod, AVG(FeeInPIPs) AS AvgFeePIPs, SUM(ISNULL(PIPsinUSD,0)) AS TotalFeeUSD
FROM [DWH_dbo].[Fact_Withdraw_Fees]
WHERE WithdrawStatus = 'Processed'
GROUP BY FundingMethod
ORDER BY TotalFeeUSD DESC;
```

### 7.3 Date-range query using ModificationDateID
```sql
SELECT CID, WithdrawID, NetCashoutDollarAmount, FundingMethod, WithdrawStatus
FROM [DWH_dbo].[Fact_Withdraw_Fees]
WHERE ModificationDateID >= 20240101 AND ModificationDateID < 20240701
ORDER BY ProcessTime DESC;
```

### 7.4 Link withdrawal back to deposit (card-match)
```sql
SELECT w.CID, w.WithdrawID, w.NetCashoutDollarAmount,
       d.DepositAmount, d.FundingMethod AS DepositMethod
FROM [DWH_dbo].[Fact_Withdraw_Fees] w
LEFT JOIN [DWH_dbo].[Fact_Deposit_Fees] d ON w.DepositID = d.DepositID
WHERE w.DepositID IS NOT NULL
ORDER BY w.ProcessTime DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Withdrawal fees and conversion fees](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11699453953/Withdrawal+fees+and+conversion+fees) | Confluence | USD withdrawal fee; pip-based conversion fee example. |
| [Conversion fee Revenue Calculation (PIP in USD)](https://etoro-jira.atlassian.net/wiki/spaces/FC/pages/12000526439/Conversion+fee+Revenue+Calculation+PIP+in+USD) | Confluence | PIP-in-USD revenue formula for deposits/withdrawals/chargebacks/refunds. |
| [Withdrawal in BO and Statuses](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11668652311/Withdrawal+in+BO+and+Statuses) | Confluence | Cashout History, withdraw status by MOP, net amount and exchange context. |
| [Cashout (CO) Processing](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/902987840/Cashout+CO+Processing) | Confluence | BO navigation for cashout requests / withdrawals. |
| [Cashout (CO) Approval Checks](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/12451579392/Cashout+CO+Approval+Checks) | Confluence | Manual CO checks (HCO, AML, blocked status). |
| [Fee Group Logic](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/12002525197/Fee+Group+Logic) | Confluence | Club tiers and withdrawal/conversion fee exemptions. |

---

*Generated: 2026-03-18 | Quality: 7.0/10 (★★★☆☆) | Phases: 11/14*
*Tiers: 0 T1, 15 T2, 2 T3, 0 T4 [UNVERIFIED], 11 T4 — Confluence, 0 T5 | Elements: 7/10, Logic: 7/10, Relationships: 5/10, Sources: 8/10*
*Object: DWH_dbo.Fact_Withdraw_Fees | Type: Table | Production Source: BackOffice.GetProcessedWithdrawPCIVersion (SP) - pipeline stopped 2024-07-01*
