# BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New_Blocked

> Single-date snapshot (GETDATE()-2) of `BI_DB_Client_Balance_CID_Level_New` filtered to customers with PlayerStatusReasonID=6 (AML-Account Closed), enriched with blocking metadata: when first blocked, how long blocked (TimeBucket), and sub-reason detail. Currently 5 rows. Refreshed daily (no @date param) by `SP_Client_Balance_CID_Level_New_Blocked`; historical data discarded on each run (TRUNCATE+INSERT).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (filter: PlayerStatusReasonID=6, Date=GETDATE()-2) + DWH blocking metadata |
| **Refresh** | Daily (no @date param; TRUNCATE + INSERT; GETDATE()-2 hard-coded) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (no index) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Client_Balance_CID_Level_New_Blocked` is a daily monitoring snapshot of customers whose accounts are currently blocked for AML/regulatory reasons. It is a filtered subset of `BI_DB_Client_Balance_CID_Level_New` — the platform's primary CID-level daily client balance table — restricted to customers where `PlayerStatusReasonID=6` (mapped to "AML-Account Closed" in production).

The table was created on 2022-01-18 by Pavlina Masuora and has had no changes since. Each daily run captures the blocked customers' complete financial balance snapshot from 2 days ago (GETDATE()-2), and enriches it with:
- When was the customer first placed in this block status (`BlockedTime`)
- When was the specific reason first recorded (`BlockedReasonTime`)
- How long have they been blocked, as a categorical bucket (`TimeBucket`, `BlockedReasonBucket`)
- The human-readable reason and sub-reason names (`PlayerStatusReason`, `PlayerStatusSubReason`)

**Current state (run date: 2026-04-11)**: 5 rows — all customers with PlayerStatusReason="AML-Account Closed", all in TimeBucket="Over 2 Months". Some have been blocked since 2022-10-19 (3.5+ years). Closing balances are near zero for all current rows.

**Column scope note**: The Blocked table captures only the first 121 columns of `BI_DB_Client_Balance_CID_Level_New` as they existed in January 2022. Columns added to the base table after that date (TRS crypto, futures, DLT, stocks margin, etc.) are NOT present here — the SP uses an explicit column list frozen at creation.

**Downstream consumers**: None identified. This table is consumed manually or by compliance/AML monitoring processes.

---

## 2. Business Logic

### 2.1 Blocked Customer Filter

**What**: Only customers with a specific player status reason are included.

**Rules**:
- Filter: `dc.PlayerStatusReasonID=6` on `DWH_dbo.Dim_Customer.PlayerStatusReasonID`
- In production data this maps to PlayerStatusReason = "AML-Account Closed"
- The filter is applied to the CURRENT state of Dim_Customer — not the state at the data date
- Customers who were blocked but have since been unblocked do not appear
- Customers who are currently blocked but had no activity on GETDATE()-2 also do not appear (they'd be absent from the base table for that date)

### 2.2 Date Reference (GETDATE()-2)

**What**: The SP always retrieves base table data for 2 days ago.

**Rules**:
- `declare @EndDate date = CONVERT(date, getdate()-2)` — hard-coded, no parameter
- Base table rows are selected with `CID.Date = @EndDate`
- Cannot be parameterized for historical dates — the SP always processes GETDATE()-2
- The TRUNCATE before INSERT means only the most recent run's date is retained in the table

### 2.3 TRUNCATE + INSERT (No History)

**What**: Daily full replacement — historical rows are not retained.

**Rules**:
- `TRUNCATE TABLE BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New_Blocked` before each INSERT
- Only the most recent run's data is present at any time
- No historical record of prior blocked-customer states — use `BI_DB_Client_Balance_CID_Level_New` directly with a PlayerStatusReasonID filter for historical analysis

### 2.4 BlockedTime — When the Block Was First Applied

**What**: The earliest date the customer had their current PlayerStatusID.

**Rules**:
- Built from `#blockedtime`: `MIN(dd.FullDate)` where `Fact_SnapshotCustomer.PlayerStatusID = #active.PlayerStatusID`
- Uses `Fact_SnapshotCustomer` + `Dim_Range` (DateRangeID) + `Dim_Date` (DateKey→FullDate)
- LEFT JOINed to `#active` — NULL if no Fact_SnapshotCustomer history available
- Represents when the customer FIRST entered the current block-status type (not specifically the current reason)

### 2.5 BlockedReasonTime — When the Specific Reason Was First Applied

**What**: The earliest date the customer had their current PlayerStatusReasonID.

**Rules**:
- Built from `#blockedtimeREASON`: `MIN(dd.FullDate)` where `Fact_SnapshotCustomer.PlayerStatusReasonID = #active.PlayerStatusReasonID`
- Same chain as BlockedTime but filters on reason ID, not status ID
- BlockedReasonTime >= BlockedTime (reason can't precede the status)
- In current data: BlockedReasonTime up to 2025-12-05, BlockedTime back to 2022-10-19

### 2.6 TimeBucket and BlockedReasonBucket (Aging Categories)

**What**: Categorical labels indicating how long the customer has been in the blocked state (relative to the SP run time, not the data date).

**Rules**:
```
TimeBucket / BlockedReasonBucket = CASE WHEN:
  DATEDIFF(HOUR, BlockedTime, GETDATE()) <= 24 → 'Under 24h'
  DATEDIFF(HOUR, BlockedTime, GETDATE()) <= 48 → 'Under 48h'
  DATEDIFF(DAY,  BlockedTime, GETDATE()) <= 5  → '5 days'
  DATEDIFF(DAY,  BlockedTime, GETDATE()) <= 10 → '10 days'
  DATEDIFF(DAY,  BlockedTime, GETDATE()) <= 15 → '15 days'
  DATEDIFF(MONTH,BlockedTime, GETDATE()) <= 1  → '1 month'
  DATEDIFF(MONTH,BlockedTime, GETDATE()) <= 2  → '2 months'
  ELSE → 'Over 2 Months'
```
- Computed at GETDATE() of the ETL run — not relative to the data date
- TimeBucket uses BlockedTime; BlockedReasonBucket uses BlockedReasonTime
- All 5 current rows are "Over 2 Months" for both buckets (long-standing AML closures)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** + **HEAP** — trivially appropriate for a 5-row table. No optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| "Which customers are currently blocked for AML?" | `SELECT CID, Country, Club, ClosingBalance, PlayerStatusReason, BlockedTime FROM BI_DB_CapitalGuarantee_Panel` — actually use this table: `SELECT * FROM BI_DB_Client_Balance_CID_Level_New_Blocked` |
| "How long has each customer been blocked?" | `SELECT CID, TimeBucket, BlockedTime, BlockedReasonBucket, BlockedReasonTime` |
| "What balances do currently-blocked customers have?" | `SELECT CID, ClosingBalance, AvailableCash, TotalLiability` |

### 3.3 Gotchas

- **5 rows total**: This table is nearly empty. All currently-blocked customers (PlayerStatusReasonID=6) have near-zero balances and have been blocked for 2+ months.
- **No history**: TRUNCATE before INSERT. Use `BI_DB_Client_Balance_CID_Level_New WHERE PlayerStatusReasonID=6` with Dim_Customer join for historical analysis of blocked-customer balances.
- **Column set frozen at Jan 2022**: Post-2022 columns (TRS crypto, futures, DLT, margin stocks, etc.) are absent. Do not join this table expecting those columns.
- **TimeBucket computed at SP run time**: The bucket reflects age at ETL run time, not at the data date. Because the SP runs daily, the bucket is accurate to within ~1 day.
- **PlayerStatusReasonID=6 only**: This SP is not generic — it only captures AML-Account Closed (ReasonID=6). Other block reasons (fraud, compliance, etc.) do not appear here.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description inherited verbatim from BI_DB_Client_Balance_CID_Level_New upstream wiki |
| Tier 2 | Description derived from SP code analysis |
| Propagation | ETL infrastructure column |

**Note**: Columns 1–121 are direct passthroughs from `BI_DB_Client_Balance_CID_Level_New`. For full column descriptions, refer to `BI_DB_Client_Balance_CID_Level_New.md`. Abbreviated descriptions below capture essential meaning.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer identifier. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 2 | TransferDirection | int | YES | 1 = current regulation row; -1 = prior regulation row for same-day regulation transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 3 | Regulation | varchar(100) | YES | Customer's regulatory entity name. (Tier 1 — BI_DB_Client_Balance_CID_Level_New.md) |
| 4 | IsCreditReportValidCB | int | YES | CB credit-validity flag. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 5 | DidRegulationTransfer | int | YES | 1 if regulation changed on this date. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 6 | DidCBValidTransfer | int | YES | 1 if credit-valid status changed on this date. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 7 | IsEtoroTradingCID | int | YES | 1 if eToro Trading entity CID. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 8 | eToroTradingGroupUser | varchar(100) | YES | eToro Trading group username. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 9 | IsGlenEagleAccount | int | YES | 1 if Glen Eagle legacy entity account. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 10 | Region | varchar(100) | YES | Marketing region. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 11 | FromRegulation | varchar(100) | YES | Source regulation for transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 12 | ToRegulation | varchar(100) | YES | Destination regulation for transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 13 | AccountType | varchar(100) | YES | Account type name. (Tier 1 — BI_DB_Client_Balance_CID_Level_New.md) |
| 14 | Label | varchar(100) | YES | CRM/marketing label segment. (Tier 1 — BI_DB_Client_Balance_CID_Level_New.md) |
| 15 | Country | varchar(100) | YES | Country of residence. (Tier 1 — BI_DB_Client_Balance_CID_Level_New.md) |
| 16 | MifidCategory | varchar(100) | YES | MiFID customer category (Retail/Professional). (Tier 1 — BI_DB_Client_Balance_CID_Level_New.md) |
| 17 | Club | varchar(100) | YES | eToro Club loyalty tier. (Tier 1 — BI_DB_Client_Balance_CID_Level_New.md) |
| 18 | PlayerStatus | varchar(100) | YES | Current player status name. (Tier 1 — BI_DB_Client_Balance_CID_Level_New.md) |
| 19 | DateID | int | YES | Business date as YYYYMMDD integer. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 20 | OpeningBalance | money | YES | Prior day closing balance = today's opening balance. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 21 | Deposits | decimal(18,6) | YES | FCA deposits for the date. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 22 | CompensationDeposit | decimal(18,6) | YES | Compensation deposits. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 23 | Bonus | decimal(18,6) | YES | Bonus credits. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 24 | Compensation | decimal(18,6) | YES | General compensation amounts. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 25 | CompensationPI | decimal(18,6) | YES | Popular Investor compensation. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 26 | CompensationToAffiliate | decimal(18,6) | YES | Compensation routed to affiliate. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 27 | NWAAdjustment | decimal(18,6) | YES | Non-withdrawable amount adjustment. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 28 | NegativeRefill | decimal(18,6) | YES | Negative balance refill by eToro. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 29 | Cashouts | decimal(18,6) | YES | Customer cashouts for the date. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 30 | CashoutsIncludingRedeem | decimal(18,6) | YES | Cashouts including bonus redemptions. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 31 | CompensationCashouts | decimal(18,6) | YES | Compensation cashout amounts. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 32 | CashoutFee | decimal(18,6) | YES | Cashout processing fee. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 33 | Chargeback | decimal(18,6) | YES | Chargeback amounts. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 34 | Refund | decimal(18,6) | YES | Refund amounts. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 35 | OvernightFee | decimal(18,6) | YES | Overnight/rollover fees. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 36 | LostDebt | decimal(18,6) | YES | Written-off customer debt. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 37 | ChargebackLoss | decimal(18,6) | YES | Chargeback loss to eToro. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 38 | OtherNegatives | decimal(18,6) | YES | Miscellaneous negative balance adjustments. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 39 | Foreclosure | decimal(18,6) | YES | Foreclosure amounts. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 40 | CompensationPnLAdjustments | decimal(18,6) | YES | PnL-based compensation adjustments. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 41 | CompensationDormantFee | decimal(18,6) | YES | Dormant account fee compensation. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 42 | ClientBalanceRealizedPnL | decimal(18,6) | YES | Total realized PnL in the balance cycle. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 43 | ClientBalanceRealizedPnLCFD | decimal(18,6) | YES | CFD realized PnL. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 44 | ClientBalanceRealizedPnLRealStocks | decimal(18,6) | YES | Real stocks realized PnL. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 45 | ClientBalanceRealizedPnLRealCrypto | decimal(18,6) | YES | Real crypto realized PnL. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 46 | TransferCoins | decimal(18,6) | YES | Crypto coin transfer amounts. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 47 | TransferCoinFees | decimal(18,6) | YES | Crypto coin transfer fees. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 48 | ClosingBalance | decimal(18,6) | YES | End-of-day balance (OpeningBalance + all flows). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 49 | realizedEquity | decimal(18,6) | YES | Total realized equity from V_Liabilities. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 50 | RealCryptoOpenBalance | decimal(18,6) | YES | Prior day real crypto position value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 51 | RealCryptoClosingBalance | decimal(18,6) | YES | Today's real crypto position value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 52 | ClientMoneyOpenBalance | decimal(18,6) | YES | Prior day client money (cash) value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 53 | ClientMoneyClosingBalance | decimal(18,6) | YES | Today's client money (cash) value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 54 | RealStocksOpeningBalance | decimal(18,6) | YES | Prior day real stocks position value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 55 | RealStocksClosingBalance | decimal(18,6) | YES | Today's real stocks position value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 56 | ClientBalanceFullCommission | decimal(18,6) | YES | Total full commission (incl. unrealized component). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 57 | ClientBalanceCommission | decimal(18,6) | YES | Net commission charged. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 58 | ClientBalanceFullCommissionCFD | decimal(18,6) | YES | Full commission for CFD positions. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 59 | ClientBalanceCommissionCFD | decimal(18,6) | YES | Net commission for CFD positions. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 60 | ClientBalanceFullCommissionRealCrypto | decimal(18,6) | YES | Full commission for real crypto. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 61 | ClientBalanceCommissionRealCrypto | decimal(18,6) | YES | Net commission for real crypto. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 62 | ClientBalanceFullCommissionRealStocks | decimal(18,6) | YES | Full commission for real stocks. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 63 | ClientBalanceCommissionRealStocks | decimal(18,6) | YES | Net commission for real stocks. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 64 | DividendsPaid | decimal(18,6) | YES | Dividends paid to customer. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 65 | TotalLiability | decimal(18,6) | YES | Total eToro liability to customer from V_Liabilities. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 66 | TotalNegativeLiability | decimal(18,6) | YES | Negative portion of total liability. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 67 | WithdrawableLiability | decimal(18,6) | YES | Withdrawable portion of liability. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 68 | NegativeWithdrawableLiability | decimal(18,6) | YES | Negative withdrawable liability. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 69 | LiabilityInUsedMargin | decimal(18,6) | YES | Liability locked in used margin. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 70 | NegativeLiabilityInUsedMargin | decimal(18,6) | YES | Negative liability in used margin. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 71 | InProcessCashout | decimal(18,6) | YES | In-process cashout value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 72 | NegativeInProcessCashout | decimal(18,6) | YES | Negative in-process cashout. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 73 | NOPCrypto | decimal(18,6) | YES | Net Open Position for crypto (CFD). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 74 | NOPCryptoCFD | decimal(18,6) | YES | NOP for crypto CFD instrument type. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 75 | NOPStocks | decimal(18,6) | YES | Net Open Position for stocks. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 76 | NOPStocksCFD | decimal(18,6) | YES | NOP for stocks CFD instrument type. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 77 | TotalRealCryptoLoan | decimal(18,6) | YES | Real crypto loan value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 78 | TotalRealCrypto | decimal(18,6) | YES | Total real (settled) crypto position value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 79 | TotalRealStocks | decimal(18,6) | YES | Total real (settled) stocks position value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 80 | PositionPNLCryptoReal | decimal(18,6) | YES | PnL for real crypto positions. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 81 | PositionPNLStocksReal | decimal(18,6) | YES | PnL for real stocks positions. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 82 | PositionPNL | decimal(18,6) | YES | Total unrealized position PnL. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 83 | AvailableCash | decimal(18,6) | YES | Customer's available cash balance. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 84 | CashInCopy | decimal(18,6) | YES | Cash allocated to copy-trading mirrors. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 85 | NOP | decimal(18,6) | YES | Total Net Open Position across all instruments. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 86 | PositionAmount | decimal(18,6) | YES | Total open position amount. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 87 | StockOrders | decimal(18,6) | YES | Pending stock orders value. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 88 | actualNWA | decimal(18,6) | YES | Actual Non-Withdrawable Amount. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 89 | UsedBonus | decimal(18,6) | YES | Bonus credit used in open positions. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 90 | UnrealizedCommissionChange | decimal(18,6) | YES | Day-over-day change in unrealized commission. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 91 | UnrealizedFullCommissionChange | decimal(18,6) | YES | Day-over-day change in full unrealized commission. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 92 | UnrealizedPnLChange | decimal(18,6) | YES | Day-over-day change in total unrealized PnL. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 93 | UnrealizedPnLChangeCFD | decimal(18,6) | YES | Day-over-day change in CFD unrealized PnL. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 94 | UnrealizedPnLChangeCryptoReal | decimal(18,6) | YES | Day-over-day change in real crypto unrealized PnL. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 95 | UnrealizedPnLChangeStocksReal | decimal(18,6) | YES | Day-over-day change in real stocks unrealized PnL. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 96 | UnrealizedFullCommissionChangeRealStocks | decimal(18,6) | YES | Day-over-day change in full unrealized commission for real stocks. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 97 | TotalNetTransfers | decimal(18,6) | YES | Total net regulation transfer amounts. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 98 | TotalTransfersInvestedRealStocks | decimal(18,6) | YES | Real stocks position value in regulation transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 99 | TotalTransfersInvestedRealCrypto | decimal(18,6) | YES | Real crypto position value in regulation transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 100 | NetTransfersNWA | decimal(18,6) | YES | NWA component of regulation transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 101 | NetTransfersUnrealizedPnL | decimal(18,6) | YES | Unrealized PnL component of regulation transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 102 | NetTransfersLiability | decimal(18,6) | YES | Liability component of regulation transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 103 | NetLiabilityTransferStocks | decimal(18,6) | YES | Stock-specific liability in regulation transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 104 | NetUnrealizedPnLTransferStocks | decimal(18,6) | YES | Stock-specific unrealized PnL in regulation transfers. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 105 | PositionPnLCrypto | decimal(18,6) | YES | PnL for all crypto positions (CFD + real). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 106 | PositionPnLStocks | decimal(18,6) | YES | PnL for all stock positions (CFD + real). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 107 | TotalCryptoPositionAmount | decimal(18,6) | YES | Total crypto position value (CFD + real). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 108 | TotalStocksPositionAmount | decimal(18,6) | YES | Total stock position value (CFD + real). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 109 | IsGermanBaFin | int | YES | 1 if under German BaFin regulatory supervision. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 110 | IsValidCustomer | int | YES | Segment flag: 1 = valid retail customer (not demo/internal/blocked-country). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 111 | Date | date | YES | Business date. Equals GETDATE()-2 for the run date. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 112 | YearMonth | int | YES | Year-month as YYYYMM integer. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 113 | YearQuarter | int | YES | Year-quarter as YYYYQQ integer. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 114 | Year | int | YES | Calendar year. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 115 | UnrealizedCommissionChangeRealStocks | money | YES | Day-over-day change in unrealized commission for real stocks (FINRA). (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 116 | TotalRealStocksEquityChange | money | YES | Day-over-day change in total real stocks equity. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 117 | CompensationsApexUSStocks | money | YES | Compensation for Apex US stocks operations. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 118 | UnrealizedFullCommissionChangeCFDStocks | money | YES | Day-over-day change in full unrealized commission for CFD stocks. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 119 | UnrealizedFullCommissionChangeRealCrypto | money | YES | Day-over-day change in full unrealized commission for real crypto. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 120 | UnrealizedFullCommissionChangeCFDCrypto | money | YES | Day-over-day change in full unrealized commission for CFD crypto. (Tier 2 — BI_DB_Client_Balance_CID_Level_New.md) |
| 121 | PlayerStatusID | int | YES | Player status identifier from Dim_Customer. Passthrough; all rows in current data have the same PlayerStatusID corresponding to the blocked status. (Tier 2 — SP_Client_Balance_CID_Level_New_Blocked) |
| 122 | PlayerStatusReasonID | int | YES | Player status reason ID from Dim_Customer. Filter key: always = 6 (AML-Account Closed) in this table. (Tier 2 — SP_Client_Balance_CID_Level_New_Blocked) |
| 123 | PlayerStatusReason | varchar(100) | YES | Human-readable name for the block reason from Dim_PlayerStatusReasons.Name. Current value: "AML-Account Closed" (PlayerStatusReasonID=6). (Tier 2 — SP_Client_Balance_CID_Level_New_Blocked) |
| 124 | PlayerStatusSubReason | varchar(100) | YES | Further sub-reason detail from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName, joined on Dim_Customer.PlayerStatusSubReasonID. Current values: "None" (3 rows) and "Cross Border" (2 rows). NULL if no sub-reason assigned. (Tier 2 — SP_Client_Balance_CID_Level_New_Blocked) |
| 125 | TimeBucket | varchar(100) | YES | Categorical aging bucket for how long the customer has been in the current block status, computed relative to GETDATE() at ETL run time using BlockedTime. Values: 'Under 24h', 'Under 48h', '5 days', '10 days', '15 days', '1 month', '2 months', 'Over 2 Months'. All current rows: 'Over 2 Months'. (Tier 2 — SP_Client_Balance_CID_Level_New_Blocked) |
| 126 | BlockedTime | date | YES | First date the customer entered their current PlayerStatusID, from MIN(Dim_Date.FullDate) where Fact_SnapshotCustomer.PlayerStatusID matches. Earliest: 2022-10-19 in production data. NULL if no Fact_SnapshotCustomer history. (Tier 2 — SP_Client_Balance_CID_Level_New_Blocked) |
| 127 | BlockedReasonTime | date | YES | First date the customer had their current PlayerStatusReasonID (ID=6), from MIN(Dim_Date.FullDate) where Fact_SnapshotCustomer.PlayerStatusReasonID matches. Can be later than BlockedTime if the reason was assigned after the initial block. Latest in production: 2025-12-05. (Tier 2 — SP_Client_Balance_CID_Level_New_Blocked) |
| 128 | BlockedReasonBucket | varchar(100) | YES | Same aging bucket thresholds as TimeBucket but computed using BlockedReasonTime instead of BlockedTime. Reflects how long the current block REASON has been in effect. All current rows: 'Over 2 Months'. (Tier 2 — SP_Client_Balance_CID_Level_New_Blocked) |
| 129 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. EXCEPTION: for frozen migration tables (DWH_Migration schema origin), this is the original production timestamp preserved from the legacy system — NOT set by GETDATE(). Run timestamp analysis (Phase 2 Tier A1) to determine which applies before using this description. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Column Group | Source | Notes |
|---|---|---|
| Cols 1–120 (base financial metrics) | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Direct passthrough; see base wiki for full lineage |
| PlayerStatusID, PlayerStatusReasonID | DWH_dbo.Dim_Customer | Joined on RealCID=CID in #active creation |
| PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | LEFT JOIN on PlayerStatusReasonID |
| PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | LEFT JOIN on Dim_Customer.PlayerStatusSubReasonID |
| BlockedTime | DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Date | MIN(FullDate) where PlayerStatusID matches |
| BlockedReasonTime | DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Date | MIN(FullDate) where PlayerStatusReasonID matches |
| TimeBucket, BlockedReasonBucket | Computed | CASE WHEN aging DATEDIFF against GETDATE() |
| UpdateDate | ETL runtime | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (Date=GETDATE()-2, PlayerStatusReasonID=6)
  + DWH_dbo.Dim_Customer (PlayerStatusID, PlayerStatusReasonID, PlayerStatusSubReasonID)
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Date (BlockedTime, BlockedReasonTime)
  + DWH_dbo.Dim_PlayerStatusReasons (PlayerStatusReason)
  + DWH_dbo.Dim_PlayerStatusSubReasons (PlayerStatusSubReason)
    |-- SP_Client_Balance_CID_Level_New_Blocked (no @date; daily; TRUNCATE + INSERT) ---|
    v
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New_Blocked (~5 rows, single date: GETDATE()-2)
    |-- UC: _Not_Migrated ---|
    v
  (no downstream consumers identified)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID | DWH_dbo.Dim_Customer | Customer profile; join on RealCID |
| All base cols | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Source of all 120 base financial columns |
| BlockedTime/BlockedReasonTime | DWH_dbo.Fact_SnapshotCustomer | Historical snapshot for timing computation |

### 6.2 Referenced By (other objects point to this)

No downstream SPs or views identified.

---

## 7. Sample Queries

### Current Blocked Customers with Balance Detail

```sql
SELECT
    CID,
    Country,
    Club,
    Regulation,
    PlayerStatusReason,
    PlayerStatusSubReason,
    ClosingBalance,
    AvailableCash,
    TotalLiability,
    BlockedTime,
    TimeBucket,
    BlockedReasonTime,
    BlockedReasonBucket
FROM [BI_DB_dbo].[BI_DB_Client_Balance_CID_Level_New_Blocked]
ORDER BY BlockedTime ASC
```

### Historical Analysis of Blocked Customers (from base table)

```sql
-- Since this table has no history, use the base table with Dim_Customer join
SELECT
    cb.CID,
    cb.Date,
    cb.ClosingBalance,
    cb.Country,
    cb.Regulation,
    dc.PlayerStatusReasonID
FROM [BI_DB_dbo].[BI_DB_Client_Balance_CID_Level_New] cb
JOIN [DWH_dbo].[Dim_Customer] dc ON cb.CID = dc.RealCID
WHERE dc.PlayerStatusReasonID = 6
  AND cb.DateID BETWEEN 20250101 AND 20260101
ORDER BY cb.CID, cb.DateID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this AML monitoring table.

---

*Generated: 2026-04-23 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 120 T1 (inherited from base), 8 T2, 0 T3, 0 T4, 0 T5, 1 Propagation | Elements: 129/129, Logic: 8/10, Completeness: 8/10*
*Object: BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New_Blocked | Type: Table | Production Source: BI_DB_Client_Balance_CID_Level_New (filtered) + DWH blocking metadata*
