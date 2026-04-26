# BI_DB_dbo.BI_DB_Finance_Cashout_RollbackDetails

> Daily cashout rollback detail report for the finance team: 107 rows (Jan 2023 – Mar 2026), each row is a single cashout rollback event keyed by Status Modification Time and Withdraw Payment ID; primary populations are BVI (57%) and FSA Seychelles (21%) wire-transfer returnedpayments, with full audit trail including previous cashout status via window function.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.External_etoro_Billing_CashoutRollbackTracking + DWH_dbo.Fact_BillingWithdraw + 12 dimension tables via SP_Finance_Cashout_RollbackDetails |
| **Refresh** | Daily (SB_Daily Priority 20); DELETE WHERE [Status Modification Time] BETWEEN @Date AND @Date+1 + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 107 rows |
| **Date Range** | Jan 2023 – Mar 2026 (Status Modification Time) |

---

## 1. Business Meaning

`BI_DB_Finance_Cashout_RollbackDetails` is a daily finance audit table that records individual cashout rollback events. A **cashout rollback** occurs when a previously approved withdrawal payment is reversed — either because the payment was returned by the bank (ReturnedPayment), failed/rejected at the processor (RejectOrFailedPayment), or an adjustment was cancelled (CancelRollback).

Each row represents a single status change event on a rollback transaction, identified by the combination of `[Withdraw Payment ID]` + `[Status Modification Time]`. The same withdrawal can appear in multiple rows if it goes through multiple status transitions (e.g., Processed → Partialy Reversed → Reversed).

**Key statistics (live data)**:
- Total events: 107 rows across 3+ years — a low-volume table tracking exceptional payment events
- Regulation split: BVI 61 (57%), FSA Seychelles 22 (21%), CySEC 20 (19%), FCA 4 (4%)
- Funding method: WireTransfer (71%), MoneyBookers (29%)
- Rollback reasons: ReturnedPayment (64%), CancelRollback (34%), RejectOrFailedPayment (3%)

**Use case**: Finance team operational report for reconciling rolled-back cashout payments — enables investigation of failed withdrawals, tracking of resolution status, and calculation of exchange difference (PIPs in USD) arising from rate movement between original withdrawal and rollback.

---

## 2. Business Logic

### 2.1 Event-Level Granularity (Multiple Rows per Withdrawal)

**What**: Each status change for a rollback creates a new row in this table.
**Columns Involved**: `[Withdraw Payment ID]`, `[WithdrawID]`, `[Status Modification Time]`, `[Withdraw Processing Id Stauts]`, `[PreviousCS]`
**Rules**:
- The SP queries `External_etoro_History_vWithdrawToFundingAction` to get all status changes for rolled-back withdrawals
- A `LAG()` window function computes `[PreviousCS]` — the cashout status immediately before the current modification
- First status transition for a payment has `[PreviousCS] = 0` (default from LAG second arg)
- Same `[Withdraw Payment ID]` can appear multiple times with different `[Status Modification Time]` and `[Withdraw Processing Id Stauts]` values

### 2.2 Daily Refresh with Date-Range Delete

**What**: The SP processes one day at a time.
**Columns Involved**: `[Status Modification Time]`, `[UpdateDate]`
**Rules**:
- @Date parameter → @StartDate = @Date, @EndDate = @Date + 1 day
- WHERE clause: `cast(t.ModificationDate as date) = @StartDate` (source filter)
- DELETE clause: `WHERE [Status Modification Time] BETWEEN @StartDate AND @EndDate`
- This means re-running for a date replaces all rows for that date, enabling reruns for corrections
- The table accumulates records over time — it is NOT a full-reload table

### 2.3 PIPs in USD Calculation

**What**: Exchange difference arising from rate movement between withdrawal processing and rollback.
**Columns Involved**: `[PIPs in USD]`, `[Net Amount]`, `[Net USD Amount]`, `[Exchange Rate]`
**Rules**:
- Formula: `((-1 * AmountUSD / BaseExchangeRate) + Amount) * BaseExchangeRate`
- `Amount` = local currency amount (BillingWithdraw.Amount_WithdrawToFunding / ExchangeRate); negated in #withdraw
- `BaseExchangeRate` = adjusted exchange rate depending on currency (special handling for VND, CNH, MYR, PHP, THB, IDR, CAD, CHF, DKK, HUF, NOK, PLN, SEK, CZK, SGD currencies uses inverted rate)
- Result is the PIP/FX loss or gain in USD; `0` for USD-denominated withdrawals where no FX conversion occurs
- Observed value: 0.000000 for all sampled rows — USD wire transfers dominate and have no FX difference

### 2.4 RollbackReason Decoding

**What**: Human-readable rollback reason from RollbackReasonID.
**Columns Involved**: `[RollbackReason]`
**Rules**:
- RollbackReasonID=1 → 'ReturnedPayment ' (trailing space present in SP CASE output)
- RollbackReasonID=2 → 'RejectOrFailedPayment '
- RollbackReasonID=3 → 'AdjustDiscrepancy' (no trailing space)
- RollbackReasonID=4 → 'CancelRollback '
- `AdjustDiscrepancy` not observed in current data (0 rows as of Mar 2026)

### 2.5 MID Conditional Logic

**What**: Merchant ID value differs by depot type.
**Columns Involved**: `[MID]`, `[Mid Name]`, `[Depot]`
**Rules**:
- For DepotIDs 7, 8, or 93: MID = `BPMS1.Description` (same as Mid Name)
- For all other depots: MID = `BPMS1.Value` (the MID code itself)
- `[Mid Name]` always uses `BPMS1.Description` regardless of depot

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. At 107 rows this is a tiny table — no performance concerns. Full table scans are acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| All rollbacks for a specific customer | `WHERE CID = <value> ORDER BY [Status Modification Time]` |
| Latest status of each rollback payment | `WHERE [PreviousCS] IS NOT NULL ORDER BY [Withdraw Payment ID], [Status Modification Time]` |
| Unresolved rollbacks (not yet fully reversed) | `WHERE [Withdraw Processing Id Stauts] NOT IN ('Reversed') ORDER BY [Status Modification Time]` |
| Rollback volume by month/regulation | `GROUP BY CONVERT(VARCHAR(7), [Status Modification Time], 120), Regulation` |
| Status transition history for a payment | `WHERE [Withdraw Payment ID] = <id> ORDER BY [Status Modification Time]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingWithdraw | `WithdrawID = BW.WithdrawID` | Re-join for additional billing fields not in this table |
| DWH_dbo.Dim_Customer | `CID = dc.RealCID` | Customer demographics not stored here |

### 3.4 Gotchas

- **Column name typo**: `[Withdraw Processing Id Stauts]` has "Stauts" instead of "Status". Always use the exact (misspelled) column name.
- **Multiple rows per withdrawal**: The same `[Withdraw Payment ID]` appears multiple rows for different status transitions. Do not `COUNT(DISTINCT [Withdraw Payment ID])` expecting it equals `COUNT(*)`.
- **`[Payment Details]` is always 'Payment Details'**: This column is a hardcoded literal in the SP — it contains no real data. Do not join or filter on it.
- **`[Brand]` is always empty for wire transfers**: The card-bin lookup only works for card payments. All wire transfer and MoneyBookers rows have empty Brand.
- **`[Fee PIPs]` is ExchangeFee, not PIPs**: Despite the column name, this field contains `Fact_BillingWithdraw.ExchangeFee` — a billing fee, not a count of PIPs. Always 0 for wire transfers.
- **`[RollbackReason]` has trailing spaces**: CASE output for reasons 1, 2, 4 includes a trailing space (e.g., 'ReturnedPayment '). Use LTRIM/RTRIM if filtering by exact value.
- **`[PreviousCS] = 0`**: LAG default is 0 (int), not NULL — first status events have PreviousCS = '0' (stored as varchar). Do not assume NULL = first event.
- **No CID-level balance data**: This is a payment event table. For customer balance at time of rollback, join DWH_dbo.Fact_SnapshotCustomer by date.

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
| 1 | CID | int | YES | Customer ID. Matched to DWH_dbo.Dim_Customer.RealCID to retrieve label and regulation. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 2 | White Label | varchar(50) | YES | Brand label name from DWH_dbo.Dim_Label (e.g., 'eToro'). All observed rows are 'eToro'. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 3 | Withdraw Payment ID | bigint | YES | Internal billing withdrawal-to-funding ID from External_etoro_Billing_CashoutRollbackTracking (source column `WitdrawToFundingID` — note SP source has "Witdraw" typo). Foreign key to Fact_BillingWithdraw.WithdrawPaymentID. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 4 | WithdrawID | bigint | YES | Withdrawal request ID from CashoutRollbackTracking. Links to Fact_BillingWithdraw.WithdrawID for financial detail lookup. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 5 | Process Time | datetime | YES | Date the payment was processed by the payment processor. From DWH_dbo.Fact_BillingWithdraw.ProcessorValueDate. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 6 | Status Modification Time | datetime | YES | Timestamp of the cashout status change event. ETL delete key: rows for the run date are deleted and re-inserted (DELETE WHERE BETWEEN @Date AND @Date+1). (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 7 | Net Amount | money | YES | Withdrawal amount in the payment's local currency. Computed as BW.Amount_WithdrawToFunding / BW.ExchangeRate. For USD withdrawals, equals Net USD Amount. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 8 | Currency | varchar(20) | YES | Payment processing currency abbreviation from DWH_dbo.Dim_Currency (e.g., 'USD'). All observed rows use 'USD'. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 9 | Net USD Amount | money | YES | Withdrawal amount in USD. From DWH_dbo.Fact_BillingWithdraw.Amount_WithdrawToFunding (raw USD value before local currency conversion). (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 10 | Withdraw Processing Id Stauts | varchar(max) | YES | Current cashout processing status from DWH_dbo.Dim_CashoutStatus (e.g., 'Reversed', 'Partialy Reversed', 'Processed'). **Note: column name has DDL typo "Stauts" instead of "Status"** — use exact spelling in queries. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 11 | Rollback Date | datetime | YES | Date the rollback was executed, from CashoutRollbackTracking.RollbackDate. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 12 | Rollback Amount | money | YES | Rollback amount in local currency (CashoutRollbackTracking.RollbackAmountInCurrency). (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 13 | Exchange Rate | decimal(16,8) | YES | Exchange rate at time of rollback from CashoutRollbackTracking.ExchangeRate. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 14 | Fee PIPs | int | YES | Exchange fee from DWH_dbo.Fact_BillingWithdraw.ExchangeFee. Despite the column name, this is not a PIP count — it is a billing exchange fee. Always 0 for wire transfers. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 15 | Rollback USD Amount | money | YES | Rollback amount converted to USD (CashoutRollbackTracking.RollbackAmountInUSD). (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 16 | Reference Number | varchar(max) | YES | External payment reference identifier from CashoutRollbackTracking.ReferenceNumber. Bank or processor reference for the rollback. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 17 | RollbackReason | varchar(max) | YES | Decoded rollback reason from CashoutRollbackTracking.RollbackReasonID: 1='ReturnedPayment ', 2='RejectOrFailedPayment ', 3='AdjustDiscrepancy', 4='CancelRollback '. Reasons 1, 2, 4 have a trailing space from the SP CASE statement. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 18 | Funding Method | varchar(max) | YES | Payment funding method name from DWH_dbo.Dim_FundingType. CASE: uses FundingTypeID_Funding name if available, else FundingTypeID_Withdraw name. Observed values: 'WireTransfer', 'MoneyBookers'. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 19 | Brand | varchar(max) | YES | Card type name from DWH_dbo.Dim_CardType via BinCode lookup. Empty/NULL for wire transfers and MoneyBookers — card bin data only available for card payments. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 20 | Payment Details | varchar(max) | YES | Hardcoded literal string 'Payment Details' in every row. This is a static placeholder in the SP INSERT — not populated with actual payment detail data. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 21 | FundingID | bigint | YES | Internal funding method record ID from External_etoro_Billimg_vWithdrawToFunding_FUll.FundingID. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 22 | Depot | varchar(max) | YES | Payment processing depot name from DWH_dbo.Dim_BillingDepot. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 23 | VerificationCode | varchar(max) | YES | Payment authorization/verification code from DWH_dbo.Fact_BillingWithdraw.VerificationCode. Billing system verification reference. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 24 | Regulation | varchar(max) | YES | Customer regulatory jurisdiction name from DWH_dbo.Dim_Regulation. Observed: BVI (57%), FSA Seychelles (21%), CySEC (19%), FCA (4%). (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 25 | Mid Name | varchar(max) | YES | Merchant/protocol MID description from DWH_dbo.Dim_BillingProtocolMIDSettingsID.Description. Always the human-readable description regardless of depot. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 26 | MID | varchar(max) | YES | Merchant ID value. For DepotIDs 7, 8, or 93: uses BPMS1.Description (same as Mid Name); for all other depots: uses BPMS1.Value (the actual MID code). (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 27 | Comments | varchar(max) | YES | Free-text comments on the rollback from CashoutRollbackTracking.Comments. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 28 | PlayerLevel | varchar(max) | YES | Customer club/tier name from DWH_dbo.Dim_PlayerLevel. All observed rows show 'Internal'. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 29 | PIPs in USD | decimal(16,6) | YES | Exchange difference in USD arising from FX rate movement between original withdrawal and rollback. Formula: ((-1 × AmountUSD / BaseExchangeRate) + LocalAmount) × BaseExchangeRate. Zero for USD-to-USD transactions with no FX conversion. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 30 | PreviousCS | varchar(max) | YES | Cashout status immediately before the current status modification, computed via LAG([Withdraw Processing Id Stauts], 1, 0) OVER (PARTITION BY [Withdraw Payment ID] ORDER BY ModificationDate). Default '0' (int 0 stored as varchar) for the first status event of a payment. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |
| 31 | UpdateDate | datetime | YES | ETL metadata: GETDATE() timestamp at INSERT. Records when this row was last refreshed. (Tier 2 — SP_Finance_Cashout_RollbackDetails) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source Object | Source Column | Transform |
|--------|--------------|---------------|-----------|
| CID | External_etoro_Billing_CashoutRollbackTracking | CID | Direct passthrough |
| White Label | DWH_dbo.Dim_Label | Name | Via Dim_Customer.LabelID |
| Withdraw Payment ID | External_etoro_Billing_CashoutRollbackTracking | WitdrawToFundingID | Direct passthrough |
| Process Time | DWH_dbo.Fact_BillingWithdraw | ProcessorValueDate | Direct passthrough |
| Status Modification Time | External_etoro_Billing_CashoutRollbackTracking | ModificationDate | Direct passthrough (delete key) |
| Net Amount | DWH_dbo.Fact_BillingWithdraw | Amount_WithdrawToFunding, ExchangeRate | Amount_WithdrawToFunding / ExchangeRate |
| Net USD Amount | DWH_dbo.Fact_BillingWithdraw | Amount_WithdrawToFunding | Direct passthrough |
| Withdraw Processing Id Stauts | DWH_dbo.Dim_CashoutStatus | Name | Via WithdrawToFundingAction.CashoutStatusID |
| Rollback Date | External_etoro_Billing_CashoutRollbackTracking | RollbackDate | Direct passthrough |
| RollbackReason | External_etoro_Billing_CashoutRollbackTracking | RollbackReasonID | CASE 1-4 decode |
| Fee PIPs | DWH_dbo.Fact_BillingWithdraw | ExchangeFee | Direct passthrough (mislabeled) |
| Brand | DWH_dbo.Dim_CardType | CarTypeName | Via Dim_CountryBin BinCode |
| Payment Details | SP hardcoded | (none) | Literal 'Payment Details' |
| Depot | DWH_dbo.Dim_BillingDepot | Name | Via BW.DepotID |
| MID | DWH_dbo.Dim_BillingProtocolMIDSettingsID | Description / Value | CASE DepotID IN (7,8,93) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Via Dim_Customer.RegulationID |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | Via Dim_Customer.PlayerLevelID |
| PIPs in USD | (derived in #withdraw2) | Multiple billing fields | ((-1×AmountUSD/BaseExRate)+LocalAmt)×BaseExRate |
| PreviousCS | (derived in #previousstatus) | Withdraw Processing Id Stauts | LAG(1, 0) OVER PARTITION BY WitdrawToFundingID |

### 5.2 ETL Pipeline

```
BI_DB_dbo.External_etoro_Billing_CashoutRollbackTracking (driving rollback event table)
  + DWH_dbo.Fact_BillingWithdraw (financial amounts, exchange rates, verification)
  + BI_DB_dbo.External_etoro_Billimg_vWithdrawToFunding_FUll (FundingID)
  + BI_DB_dbo.External_etoro_History_vWithdrawToFundingAction + DWH_dbo.Dim_CashoutStatus (status history)
  + DWH_dbo.Dim_Currency, Dim_Customer, Dim_Regulation, Dim_Label (dimension enrichment)
  + DWH_dbo.Dim_BillingProtocolMIDSettingsID, Dim_BillingDepot, Dim_FundingType (billing dimensions)
  + DWH_dbo.Dim_CountryBin, Dim_CardType (card type → Brand)
  + DWH_dbo.Dim_PlayerLevel (club tier)
    |-- SP_Finance_Cashout_RollbackDetails @Date (Daily) ---|
    |   #rollback (single day events) → #allstatuses → #previousstatus (LAG)   |
    |   #withdraw → #withdraw2 (PIPsCalculation)                                |
    |   #details (DISTINCT join) → #final (join PreviousCS)                     |
    |   DELETE WHERE [Status Modification Time] BETWEEN @Date AND @Date+1        |
    |   INSERT 31 columns                                                         |
    v
BI_DB_dbo.BI_DB_Finance_Cashout_RollbackDetails
  (107 rows, Jan 2023 – Mar 2026)
  UC Target: Not Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Withdraw Payment ID, WithdrawID | DWH_dbo.Fact_BillingWithdraw | Financial amounts, exchange rates, depot, funding type |
| CID | DWH_dbo.Dim_Customer | Customer regulation and label lookup |
| Regulation | DWH_dbo.Dim_Regulation | Regulatory jurisdiction name |
| White Label | DWH_dbo.Dim_Label | Brand label name |
| Withdraw Processing Id Stauts | DWH_dbo.Dim_CashoutStatus | Cashout processing status name |
| Currency | DWH_dbo.Dim_Currency | Payment currency abbreviation |
| Depot | DWH_dbo.Dim_BillingDepot | Payment depot name |
| MID, Mid Name | DWH_dbo.Dim_BillingProtocolMIDSettingsID | Merchant/MID details |
| Funding Method | DWH_dbo.Dim_FundingType | Payment method name |
| Brand | DWH_dbo.Dim_CardType, Dim_CountryBin | Card type via bin lookup |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Customer club/tier name |
| (source events) | BI_DB_dbo.External_etoro_Billing_CashoutRollbackTracking | Rollback event driving table |
| FundingID | BI_DB_dbo.External_etoro_Billimg_vWithdrawToFunding_FUll | Funding ID lookup |
| (status history) | BI_DB_dbo.External_etoro_History_vWithdrawToFundingAction | Cashout action status history |

### 6.2 Referenced By (other objects point to this)

No downstream SP dependencies identified in OpsDB dependency scan. Consumed directly by the finance team's cashout rollback operational report.

---

## 7. Sample Queries

### All Events for a Specific Payment (Status History)

```sql
SELECT [Withdraw Payment ID],
       [WithdrawID],
       [Status Modification Time],
       [Withdraw Processing Id Stauts],
       [PreviousCS],
       [RollbackReason],
       [Net USD Amount]
FROM [BI_DB_dbo].[BI_DB_Finance_Cashout_RollbackDetails]
WHERE [Withdraw Payment ID] = <payment_id>
ORDER BY [Status Modification Time];
```

### Open Rollbacks (Not Yet Fully Reversed)

```sql
SELECT [CID], [Withdraw Payment ID], [WithdrawID],
       [Status Modification Time],
       LTRIM(RTRIM([Withdraw Processing Id Stauts])) AS Status,
       [Net USD Amount],
       [Regulation],
       LTRIM(RTRIM([RollbackReason])) AS RollbackReason
FROM [BI_DB_dbo].[BI_DB_Finance_Cashout_RollbackDetails]
WHERE [Withdraw Processing Id Stauts] NOT IN ('Reversed')
ORDER BY [Status Modification Time] DESC;
```

### Monthly Rollback Summary by Regulation

```sql
SELECT CONVERT(VARCHAR(7), [Status Modification Time], 120) AS YearMonth,
       Regulation,
       LTRIM(RTRIM([RollbackReason])) AS RollbackReason,
       COUNT(*) AS EventCount,
       SUM([Net USD Amount]) AS TotalNetUSD
FROM [BI_DB_dbo].[BI_DB_Finance_Cashout_RollbackDetails]
GROUP BY CONVERT(VARCHAR(7), [Status Modification Time], 120),
         Regulation,
         LTRIM(RTRIM([RollbackReason]))
ORDER BY YearMonth DESC, EventCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this table. Billing system context (CashoutRollbackTracking, Fact_BillingWithdraw) is documented in the eToro billing domain. Finance use case is defined by SP header: "report to give details on rollback for cashouts to help finance team task" (author: Pavlina Masoura, 2023-01-30).

---

*Generated: 2026-04-22 | Quality: 8.2/10 | Phases: 13/14*
*Tiers: 0 T1, 31 T2, 0 T3, 0 T4, 0 T5 | Elements: 31/31, Logic: 8/10, Evidence: 9/10*
*Object: BI_DB_dbo.BI_DB_Finance_Cashout_RollbackDetails | Type: Table | Production Source: SP_Finance_Cashout_RollbackDetails*
