# BI_DB_dbo.BI_DB_CID_DailyPanel_Club

> Daily per-customer panel for eToro Club loyalty members (Silver–Diamond tiers, plus customers who downgraded back to Bronze). Each row captures a customer's current tier, tier-change history, equity, revenue, MIMO, credit line, interest, and Moneyfarm/eMoney balances for one calendar day. 67 columns. Covers 1.6B rows from 2020-01-01 to present across 1.1M distinct Club-eligible customers.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_ClubChangeLogProduct (primary) + DWH_dbo.V_Liabilities, BI_DB_DepositWithdrawFee, BI_DB_DailyCommisionReport, BI_DB_Daily_CreditLine, eMoney_dbo.CustomerEODBalance, External Moneyfarm / Interest tables |
| **Refresh** | Daily — DELETE WHERE DateID = @ddINT + INSERT (SP_CID_DailyPanel_Club, SB_Daily process, Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CID_DailyPanel_Club is the daily CRM panel for eToro's Club loyalty program — the tiered rewards system that segments customers by their realized equity (account value) into six tiers: Bronze, Silver, Gold, Platinum, Platinum Plus, and Diamond. The table serves Account Management (AM) and CRM teams to track club progression, identify upgrade/downgrade candidates, measure customer wealth and activity, and manage club-specific benefits such as credit lines, interest on balance (IOB), and fee exemptions.

**Scope**: Unlike general customer panel tables, this table is explicitly filtered to **Club-eligible customers only** — those who have at some point been assigned to a tier above Bronze (or who downgraded back to Bronze from a higher tier). Customers whose only club event is an initial Bronze assignment (OldTier IS NULL AND CurrentTier=1) are excluded. As of April 2026: ~1.1M distinct CIDs, ~13.5M records per daily date.

The SP has been updated three times since creation, with the current logic (post-2023-08-23) being the canonical version. Key changes across branches: (1) Revenue source switched from `Fact_CustomerAction` to `BI_DB_DailyCommisionReport`; (2) `RealizedEquityClub` was introduced as the club-eligibility equity metric (includes non-CFD + eMoney + Moneyfarm); (3) Interest on Balance (IOB) consent and daily amounts were added via external tables.

**Club Tier Map** (non-sequential PlayerLevelIDs — use Name/Sort for display):

| PlayerLevelID | Name | Equity Threshold (USD) | Records (April 2026) |
|--------------|------|------------------------|---------------------|
| 1 | Bronze | 0–5,000 (downgraded members) | 4.2M |
| 5 | Silver | 5,000–10,000 | 3.4M |
| 3 | Gold | 10,000–25,000 | 3.1M |
| 2 | Platinum | 25,000–50,000 | 1.5M |
| 6 | Platinum Plus | 50,000–250,000 | 1.1M |
| 7 | Diamond | 250,000+ | 127K |

---

## 2. Business Logic

### 2.1 Club Member Population Filter

**What**: Only customers with active club history (non-trivial Bronze entry) appear in this table.

**Columns Involved**: CID, CurrentTier, TierChangeDate, TierChangeType

**Rules**:
- Source: `BI_DB_ClubChangeLogProduct` — the master tier-change event log. The SP takes the most-recent row per CID (ROW_NUMBER OVER CID ORDER BY Date DESC = 1).
- Filter: `WHERE ccl.Date <= @Date AND c.IsValidCustomer = 1 AND NOT (ccl.CurrentTier=1 AND ccl.OldTier IS NULL)`. The last condition removes customers whose first and only club event was an initial Bronze assignment with no prior tier.
- A customer in Bronze here means they previously held a higher tier and were downgraded — not a first-time Bronze customer.
- Valid customer requirement: `Fact_SnapshotCustomer.IsValidCustomer = 1` at the @Date snapshot (via Dim_Range date filter).

### 2.2 Tier Change Flags

**What**: Identifies whether a tier change occurred on the specific report date.

**Columns Involved**: IsUpgrade, IsDowngrade, TierChangeDate, TierChangeType

**Rules**:
- `IsUpgrade = 1` when `TierChangeDate = @Date AND TierChangeType IN ('Upgrade', 'First Club') AND CurrentTier > 1`
- `IsDowngrade = 1` when `TierChangeDate = @Date AND TierChangeType = 'Downgrade'`
- Both flags are 0 on all other days (tier unchanged). Used by CRM to send upgrade/downgrade communications.
- **Dual spelling caveat**: `TierChangeType` contains both `'First Club'` (legacy) and `'FirstClub'` (current). Always filter using `IN ('FirstClub', 'First Club')` or `LIKE 'First%Club'`.

### 2.3 RealizedEquityClub — Club-Eligible Equity

**What**: The equity metric used for tier qualification (post-2023-01-01 logic), which includes non-CFD real assets, eToro Money, and Moneyfarm.

**Columns Involved**: RealizedEquityClub, RealizedEquity, RealizedEquityNoCFD, eMoneyBalance, Moneyfarm

**Rules**:
```
RealizedEquityClub = RealizedEquityNoCFD + eMoneyBalance + Moneyfarm
RealizedEquityNoCFD = V_Liabilities.TotalRealStocks + V_Liabilities.TotalRealCrypto + V_Liabilities.TotalCash
eMoneyBalance = eMoney_dbo.CustomerEODBalance (most recent by GCID, DateId <= @ddINT)
Moneyfarm = External_MoneyFarm_CID_DailyPanelClub.CalculatedAmountInUSD (SUM by GCID, try/catch)
```
- CFD positions (i.e., leveraged derivatives) are **excluded** from club-tier calculation. Only real non-leveraged assets count toward Club eligibility.
- `RealizedEquity` (from V_Liabilities, includes CFD) is retained for backward compatibility and is used in `IsFundedCurrentTier` for the pre-2023 branch only.
- If Moneyfarm external table is missing: PRINT error, eMoneyBalance still populated; Moneyfarm=0.

### 2.4 IsFundedCurrentTier and Tier Maintenance

**What**: Indicates whether the customer's current equity qualifies them for their current tier.

**Columns Involved**: IsFundedCurrentTier, IsFunded, AmountToUpgrade, AmountToRemain, CurrentTier

**Rules**:
- `IsFundedCurrentTier = 1` IF `RealizedEquityClub` (post-2023) or `RealizedEquity` (pre-2023) is BETWEEN `Dim_PlayerLevel.LowerBound` and `UpperBound` for the customer's CurrentTier.
- `IsFunded = 1` IF `Equity > 25` (total net equity exceeds $25 — a minimal "has money" check).
- `AmountToUpgrade` = next tier's UpperBound – current RealizedEquityClub. Zero for Diamond (highest tier).
- `AmountToRemain` = current tier's LowerBound – RealizedEquityClub. Zero if customer is within tier range.
- **Tier thresholds** (embedded in SP as variables): Bronze 0–5K, Silver 5K–10K, Gold 10K–25K, Platinum 25K–50K, Platinum Plus 50K–250K, Diamond 250K+.

### 2.5 Revenue Column (Post-2023-08-23 Logic)

**What**: Daily revenue generated by the customer from trading activity.

**Columns Involved**: Revenue

**Rules** (current branch — post-2023-08-23):
```sql
Revenue = SUM(ISNULL(RollOverFee, 0) + ISNULL(FullCommissions, 0))
          FROM BI_DB_DailyCommisionReport
          WHERE DateID = @ddINT AND RealCID = CID
```
- Pre-2023-08-23: sourced from `Fact_CustomerAction` (ActionTypeID 1-6, 28, 35, 39, 40) — open commissions + close commissions + rollover fees.
- Post-2023-08-23 switch improves correctness by using the already-aggregated commission report rather than recomputing from raw action events.
- Copy/mirror revenue is included (IsMirror rows not filtered out) in current logic.

### 2.6 Interest on Balance (IOB)

**What**: Daily interest earned by the customer on eligible cash balances.

**Columns Involved**: IsOptInInterest, OptInDate, DailyCalculationInterest

**Rules**:
- `IsOptInInterest = 1` IF the customer has an active IOB consent (`ConsentStatusID=1`) in `External_Interest_Trade_InterestConsent` as of @Date. 0 if no consent or opted-out.
- `OptInDate` = `ValidFrom` of the most recent consent record (ROW_NUMBER OVER CID ORDER BY ValidFrom DESC).
- `DailyCalculationInterest` = the daily interest amount in USD from `External_Interest_Trade_InterestDaily_CID_DailyPanelClub`.
- Both fields use try/catch on external table access — missing external table → 0/1900-01-01 defaults.
- `MonthlyInterestPayments` is **hardcoded 0** (deprecated, field removed from active logic).

### 2.7 Credit Line Fields

**What**: Tracks eToro's credit line product (loans to high-tier clients).

**Columns Involved**: TotalCLAmount, DailyFee, IsOpenCreditLine, IsClosedCreditLine, IsCreditLineCustomer, IsCreditEligible

**Rules**:
- Source: `BI_DB_Daily_CreditLine` — joined on `RealCID = CID AND DateID = @ddINT`.
- `IsCreditEligible = 1` IF `Equity >= 10,000 AND RegulationID = 1 (CySEC) AND Dim_PlayerLevel.Sort > 1 (above Bronze)`.
- CySEC (RegulationID=1) restriction: credit line is only offered to EU-regulated customers above Bronze.
- `IsOpenCreditLine = 1` IF `DateReceive IS NOT NULL` (credit line was opened/granted).
- `IsClosedCreditLine = 1` IF `DateDeduct IS NOT NULL AND TotalCLAmount <= 0` (credit line was fully repaid and closed).
- `IsCreditLineCustomer = 1` IF `TotalCLAmount > 0` (customer has an active outstanding credit line balance).

### 2.8 Deprecated Fields

The following columns are present in the DDL but are **hardcoded to default values** in all SP branches:

| Column | Hardcoded Value | Reason |
|--------|----------------|--------|
| Classification | NULL | Cluster assignment removed 2022-01-03 |
| IsExpectedDowngrade | 0 | External table downgrade-risk service decommissioned |
| ExpectedDowngradePlayerLevelID | 0 | Same as above |
| ExpectedDowngradeDate | '1900-01-01' | Same as above |
| ExpectedDowngradeTierLT | 0 | Same as above |
| ExpectedDowngradeStartDate | '1900-01-01' | Same as above |
| MonthlyInterestPayments | 0 | Interest monthly aggregation removed |

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on DateID. ROUND_ROBIN (not HASH) means queries filtering on CID will perform full-distribution scans — this is a performance consideration for CID-level lookups. Always include a DateID filter to leverage the clustered index range scan. Avoid unfiltered scans of the full 1.6B row table.

### 3.2 Population Scoping

This table is **Club members only** — not all eToro customers. For analysis of the full customer base, use `BI_DB_CID_DailyPanel_FullData`. For a complete Club member picture including members without recent tier changes, confirm the date filter spans the desired window (daily grain, one row per CID per date).

### 3.3 Tier Field Gotchas

- **PlayerLevelID is NOT rank-ordered**: ID 2=Platinum, 3=Gold, 5=Silver. Filtering `CurrentTier > 3` does NOT mean "above Gold". Use `JOIN Dim_PlayerLevel ON PlayerLevelID` and filter on `Sort` for rank comparisons.
- **TierChangeType dual spelling**: Filter using `TierChangeType IN ('FirstClub', 'First Club')` — both spellings represent the initial club assignment event.
- **IsUpgrade/IsDowngrade are date-specific**: These flags are 1 only on the date when the tier change occurred (TierChangeDate = DateID). They are 0 on all other days for the same customer.
- **Bronze customers in this table are downgrades**: A Bronze customer in this panel was previously in a higher tier. For truly new Bronze customers (first-time club entry), use `BI_DB_ClubChangeLogProduct` directly.

### 3.4 Revenue History Discontinuity

Revenue was sourced from different tables depending on the date:
- Pre-2023-01-01: `Fact_CustomerAction` commissions + rollover.
- 2023-01-01 to 2023-08-22: `BI_DB_DailyCommisionReport` (commissions only; InvestedAmount from `Fact_CustomerAction`).
- Post-2023-08-22: `BI_DB_DailyCommisionReport` (full current logic).

Cross-date revenue trends should account for this potential methodology discontinuity.

### 3.5 RealizedEquityClub vs RealizedEquity

`RealizedEquityClub` (non-CFD equity + eMoney + Moneyfarm) is the **tier qualification metric** and is available only post-2023. `RealizedEquity` (from V_Liabilities, includes CFD open positions) is the traditional net account value metric. For tier-based analysis, prefer `RealizedEquityClub`.

### 3.6 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's Club distribution | WHERE DateID = [today_int], GROUP BY CurrentTier |
| Customers who upgraded today | WHERE DateID = [today_int] AND IsUpgrade = 1 |
| Tier maintenance gap | SELECT CID, AmountToRemain WHERE DateID = [date] AND AmountToRemain > 0 |
| Upgrade potential | SELECT CID, AmountToUpgrade WHERE DateID = [date] AND AmountToUpgrade < 1000 |
| Credit line eligible customers | WHERE DateID = [date] AND IsCreditEligible = 1 AND IsCreditLineCustomer = 0 |
| Club member MIMO for a date | SUM(DepositAmount), SUM(WithdrawAmount) GROUP BY CurrentTier |

### 3.7 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_PlayerLevel | ON CurrentTier = PlayerLevelID | Resolve tier name/sort |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Country name lookup |
| DWH_dbo.Fact_SnapshotCustomer | ON CID = RealCID, date range filter | Extended customer attributes |
| BI_DB_dbo.BI_DB_DailyCommisionReport | ON CID = RealCID AND DateID | Detailed revenue breakdown |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (T1 - BI_DB_ClubChangeLogProduct wiki) |
| *** | Tier 2 - SP code / live data | (T2 - SP_CID_DailyPanel_Club) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | ETL date key in YYYYMMDD format. Identifies the report date as an integer. CLUSTERED INDEX key — always filter on DateID for performance. (T2 - SP_CID_DailyPanel_Club) |
| 2 | Date | date | YES | Calendar date corresponding to DateID. (T2 - SP_CID_DailyPanel_Club) |
| 3 | CID | int | YES | Customer identifier (RealCID). FK into DWH_dbo.Dim_Customer. One row per CID per DateID; scope is Club-eligible members only (see Business Meaning). (T2 - SP_CID_DailyPanel_Club) |
| 4 | TierChangeDate | date | YES | Date of the customer's most recent club tier change event (from BI_DB_ClubChangeLogProduct.Date). Static per CID until the next change event. (T1 - BI_DB_ClubChangeLogProduct wiki) |
| 5 | TierChangeType | varchar(50) | YES | Type of most recent tier change: 'Upgrade' (moved to higher tier), 'Downgrade' (moved to lower tier), 'First Club' (legacy first tier assignment), 'FirstClub' (current first tier assignment). Dual spelling for first-assignment — filter using IN ('FirstClub', 'First Club'). (T1 - BI_DB_ClubChangeLogProduct wiki) |
| 6 | IsUpgrade | int | YES | 1 if this CID was upgraded on this specific DateID (TierChangeDate = Date AND TierChangeType IN ('Upgrade','First Club') AND CurrentTier > 1); 0 otherwise. Day-specific flag for CRM upgrade events. (T2 - SP_CID_DailyPanel_Club) |
| 7 | IsDowngrade | int | YES | 1 if this CID was downgraded on this specific DateID; 0 otherwise. Day-specific flag for CRM downgrade communications. (T2 - SP_CID_DailyPanel_Club) |
| 8 | CurrentTier | tinyint | YES | PlayerLevelID of the customer's current club tier as of DateID. Non-sequential: 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond. Use JOIN to Dim_PlayerLevel for display names. (T1 - DWH_dbo.Dim_PlayerLevel wiki) |
| 9 | LastTier | tinyint | YES | PlayerLevelID of the customer's tier before their most recent change (BI_DB_ClubChangeLogProduct.OldTier). NULL for first-ever club assignment. Same non-sequential ID mapping as CurrentTier. (T2 - SP_CID_DailyPanel_Club) |
| 10 | MaxTier | tinyint | YES | PlayerLevelID of the highest tier the customer has ever achieved. Derived from MAX(CurrentSort) OVER (PARTITION BY CID) → Dim_PlayerLevel.PlayerLevelID via Sort. Useful for identifying loyal/lapsed high-value customers. (T2 - SP_CID_DailyPanel_Club) |
| 11 | CountryID | int | YES | Customer's country of residence. FK into DWH_dbo.Dim_Country. Sourced from Dim_Country via Fact_SnapshotCustomer.CountryID. (T2 - SP_CID_DailyPanel_Club) |
| 12 | RegulationID | int | YES | Regulatory entity governing the customer. 1=CySEC (EU), and other values for other regulators. Used to determine credit line eligibility (IsCreditEligible requires RegulationID=1). (T2 - SP_CID_DailyPanel_Club) |
| 13 | IsProCustomer | int | YES | 1 if customer is classified as a MiFID Professional (MifidCategorizationID IN (2,3) in Fact_SnapshotCustomer); 0 otherwise. Professional customers have different trading limits and protections. (T2 - SP_CID_DailyPanel_Club) |
| 14 | Classification | varchar(50) | YES | **DEPRECATED — always NULL.** Previously held a cluster/segment classification (CID_DailyCluster). Removed 2022-01-03 (Tom Boksenbojm). Do not use. (T2 - SP_CID_DailyPanel_Club) |
| 15 | FTDDate | date | YES | First Time Deposit date (Dim_Customer.FirstDepositDate). The date the customer made their first ever deposit. (T2 - SP_CID_DailyPanel_Club) |
| 16 | FTCDate | date | YES | First Time Club date — the date of the customer's first-ever promotion above Bronze (IsFTC=1 in BI_DB_ClubChangeLogProduct). NULL if the customer has not yet been promoted above Bronze. (T1 - BI_DB_ClubChangeLogProduct wiki) |
| 17 | IsFTC | int | YES | 1 if the customer's FTCDate falls on this DateID (i.e., they are being promoted above Bronze for the first time on this date); 0 otherwise. Note: can be NULL in older data for customers whose FTC was before the start of the table. (T1 - BI_DB_ClubChangeLogProduct wiki) |
| 18 | DaysTillFTC | int | YES | Number of days between FTDDate and FTCDate (DATEDIFF DAY). Measures how long it took the customer to reach Club status after first deposit. NULL if FTCDate is NULL. (T2 - SP_CID_DailyPanel_Club) |
| 19 | DaysFromFTD | int | YES | Number of days between FTDDate and DateID (DATEDIFF DAY). Customer age since first deposit. (T2 - SP_CID_DailyPanel_Club) |
| 20 | DaysInClub | int | YES | Number of days between FTCDate and DateID (DATEDIFF DAY). How long the customer has been a Club member (any tier above Bronze). (T2 - SP_CID_DailyPanel_Club) |
| 21 | DaysInCurrentClub | int | YES | Number of days between TierChangeDate and DateID (DATEDIFF DAY). How long the customer has been at their current tier level. (T2 - SP_CID_DailyPanel_Club) |
| 22 | RealizedEquity | money | YES | Customer's total account equity including CFD open positions (from DWH_dbo.V_Liabilities). Used for tier evaluation in pre-2023 data. Post-2023, RealizedEquityClub is the tier-qualification metric. (T2 - SP_CID_DailyPanel_Club) |
| 23 | Equity | decimal(23,4) | YES | Net equity = V_Liabilities.Liabilities + V_Liabilities.ActualNWA. Includes open position market value. Used for IsFunded and IsCreditEligible thresholds. (T2 - SP_CID_DailyPanel_Club) |
| 24 | Revenue | decimal(38,2) | YES | Daily revenue earned by the customer. Post-2023-08-23: SUM(RollOverFee + FullCommissions) from BI_DB_DailyCommisionReport. Pre-2023: from Fact_CustomerAction (open commissions + close commissions + rollover). Revenue methodology changed on 2023-08-23 — cross-date trends should account for this. (T2 - SP_CID_DailyPanel_Club) |
| 25 | InvestedAmount | decimal(38,2) | YES | Total notional USD opened in new trading positions on DateID. Pre-2023-08-23: -1 * SUM(Amount WHERE ActionTypeID IN (1,2,3,39)) from Fact_CustomerAction. Post-2023-01-01: SUM(MoneyIn WHERE ActionTypeID IN (1,15,17)). (T2 - SP_CID_DailyPanel_Club) |
| 26 | IsFundedCurrentTier | int | YES | 1 if the customer's RealizedEquityClub (post-2023) or RealizedEquity (pre-2023) falls within the LowerBound–UpperBound for their CurrentTier. 0 if not funded at tier level. Key metric for downgrade risk assessment. (T2 - SP_CID_DailyPanel_Club) |
| 27 | IsFunded | int | YES | 1 if Equity > 25 (minimal "has money" threshold). Broad flag distinguishing customers with meaningful account balance from empty accounts. (T2 - SP_CID_DailyPanel_Club) |
| 28 | AmountToUpgrade | money | YES | USD amount needed to qualify for the next higher tier: next tier's LowerBound - RealizedEquityClub. 0 for Diamond customers (already at highest tier). (T2 - SP_CID_DailyPanel_Club) |
| 29 | AmountToRemain | money | YES | USD amount the customer is below their current tier's LowerBound (if negative equity position): LowerBound - RealizedEquityClub when below threshold, else 0. Non-zero values indicate downgrade risk. (T2 - SP_CID_DailyPanel_Club) |
| 30 | IsExpectedDowngrade | int | YES | **DEPRECATED — hardcoded 0.** Previously populated from ClubService downgrade-risk external table. External table service decommissioned. Do not use. (T2 - SP_CID_DailyPanel_Club) |
| 31 | ExpectedDowngradePlayerLevelID | int | YES | **DEPRECATED — hardcoded 0.** See IsExpectedDowngrade. (T2 - SP_CID_DailyPanel_Club) |
| 32 | IsOptInInterest | int | YES | 1 if the customer has active Interest on Balance (IOB) consent as of DateID (ConsentStatusID=1 in External_Interest_Trade_InterestConsent). 0 if no consent or opted-out. Available post-2023-08-23; 0 for historical dates. (T2 - SP_CID_DailyPanel_Club) |
| 33 | OptInDate | date | YES | Date the customer's most recent IOB consent took effect (ValidFrom of most recent consent record). '1900-01-01' if not opted in or historical data. (T2 - SP_CID_DailyPanel_Club) |
| 34 | DepositAmount | numeric(38,8) | YES | Total deposit amount in USD on DateID from BI_DB_DepositWithdrawFee (TransactionType='Deposit'). 0 if no deposits. (T2 - SP_CID_DailyPanel_Club) |
| 35 | DepositTransactions | int | YES | Count of distinct deposit transactions on DateID (COUNT DISTINCT DepositWithdrawID WHERE Deposit). (T2 - SP_CID_DailyPanel_Club) |
| 36 | DepositAmountWireTransfer | numeric(38,8) | YES | Deposit amount via Wire Transfer payment method on DateID. Subset of DepositAmount. (T2 - SP_CID_DailyPanel_Club) |
| 37 | DepositWireTransferTransactions | int | YES | Count of deposit transactions via Wire Transfer on DateID. (T2 - SP_CID_DailyPanel_Club) |
| 38 | DepositConversionFee | numeric(38,6) | YES | Currency conversion fee applied on deposits: SUM((BaseExchangeRate - ExchangeRate) * Amount). (T2 - SP_CID_DailyPanel_Club) |
| 39 | DepositConversionFeeExemption | numeric(38,6) | YES | Wire Transfer conversion fee exemption value for Platinum/Platinum Plus (0.25%) and Diamond (0.5%) customers. Amount the customer was not charged due to their Club tier benefit. (T2 - SP_CID_DailyPanel_Club) |
| 40 | WithdrawAmount | numeric(38,6) | YES | Total withdrawal amount in USD on DateID (-1 * AmountUSD WHERE TransactionType='Withdraw'). 0 if no withdrawals. (T2 - SP_CID_DailyPanel_Club) |
| 41 | WithdrawAmountWireTransfer | numeric(38,6) | YES | Withdrawal amount via Wire Transfer on DateID. Subset of WithdrawAmount. (T2 - SP_CID_DailyPanel_Club) |
| 42 | WithdrawTransactions | int | YES | Count of distinct withdrawal transactions on DateID. (T2 - SP_CID_DailyPanel_Club) |
| 43 | WithdrawWireTransferTransactions | int | YES | Count of Wire Transfer withdrawal transactions on DateID. (T2 - SP_CID_DailyPanel_Club) |
| 44 | WithdrawAmountWallet | numeric(38,6) | YES | Withdrawal amount to eToro Crypto Wallet on DateID (PaymentMethod='eToroCryptoWallet'). (T2 - SP_CID_DailyPanel_Club) |
| 45 | WithdrawWalletTransactions | int | YES | Count of Crypto Wallet withdrawal transactions on DateID. (T2 - SP_CID_DailyPanel_Club) |
| 46 | WithdrawConversionFee | numeric(38,6) | YES | Currency conversion fee on withdrawals: SUM((BaseExchangeRate - ExchangeRate) * Amount) WHERE Withdraw. (T2 - SP_CID_DailyPanel_Club) |
| 47 | WithdrawConversionFeeExemption | numeric(38,6) | YES | Wire Transfer conversion fee exemption value for Platinum/Platinum Plus (0.25%) and Diamond (0.5%) customers on withdrawals. (T2 - SP_CID_DailyPanel_Club) |
| 48 | CashoutFeeExemption | int | YES | Cashout flat-fee exemption value for Platinum/Platinum Plus/Diamond customers (PlayerLevelID IN (2,6,7)): COUNT(Withdrawals) * PotentialFee (25 USD pre-2020-02-19, 5 USD after). Amount not charged due to Club tier. (T2 - SP_CID_DailyPanel_Club) |
| 49 | CashoutFeePaid | money | YES | Actual cashout processing fee paid by the customer on DateID (MAX(Fee) per WithdrawID from DWH_dbo.Fact_BillingWithdraw). (T2 - SP_CID_DailyPanel_Club) |
| 50 | TotalCLAmount | decimal(11,2) | YES | Total outstanding credit line balance (USD) from BI_DB_Daily_CreditLine. 0 if no credit line. (T2 - SP_CID_DailyPanel_Club) |
| 51 | DailyFee | decimal(11,2) | YES | Daily accruing fee on the customer's outstanding credit line balance. From BI_DB_Daily_CreditLine. (T2 - SP_CID_DailyPanel_Club) |
| 52 | IsOpenCreditLine | int | YES | 1 if the customer has an open credit line (DateReceive IS NOT NULL in BI_DB_Daily_CreditLine). (T2 - SP_CID_DailyPanel_Club) |
| 53 | IsClosedCreditLine | int | YES | 1 if the customer's credit line has been closed (DateDeduct IS NOT NULL AND TotalCLAmount <= 0). (T2 - SP_CID_DailyPanel_Club) |
| 54 | IsCreditLineCustomer | int | YES | 1 if the customer currently has an active credit line balance (TotalCLAmount > 0). (T2 - SP_CID_DailyPanel_Club) |
| 55 | IsCreditEligible | int | YES | 1 if the customer meets criteria for credit line eligibility: Equity >= 10,000 USD AND RegulationID = 1 (CySEC) AND Dim_PlayerLevel.Sort > 1 (above Bronze). (T2 - SP_CID_DailyPanel_Club) |
| 56 | DailyCalculationInterest | numeric(15,6) | YES | Daily interest earned on eligible cash balance under the Interest on Balance (IOB) program. From External_Interest_Trade_InterestDaily_CID_DailyPanelClub. 0 if not opted in or external table missing. (T2 - SP_CID_DailyPanel_Club) |
| 57 | MonthlyInterestPayments | int | YES | **DEPRECATED — hardcoded 0.** Previously tracked monthly interest payment count. Removed from active SP logic. (T2 - SP_CID_DailyPanel_Club) |
| 58 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by SP_CID_DailyPanel_Club (GETDATE() at INSERT time). (T2 - SP_CID_DailyPanel_Club) |
| 59 | ExpectedDowngradeDate | date | YES | **DEPRECATED — hardcoded '1900-01-01'.** External downgrade-risk service decommissioned. (T2 - SP_CID_DailyPanel_Club) |
| 60 | ExpectedDowngradeTierLT | int | YES | **DEPRECATED — hardcoded 0.** See ExpectedDowngradeDate. (T2 - SP_CID_DailyPanel_Club) |
| 61 | AccountManagerID | int | YES | Assigned Account Manager ID from Fact_SnapshotCustomer. FK into AM dimension. Used by AM teams to associate Club members with their designated manager. (T2 - SP_CID_DailyPanel_Club) |
| 62 | RealizedEquityNoCFD | money | YES | Equity from real (non-leveraged, non-CFD) assets only: V_Liabilities.TotalRealStocks + TotalRealCrypto + TotalCash. Component of RealizedEquityClub. (T2 - SP_CID_DailyPanel_Club) |
| 63 | Moneyfarm | money | YES | Customer's total Moneyfarm investment value in USD (SUM(CalculatedAmountInUSD) by GCID from External_MoneyFarm_CID_DailyPanelClub). 0 if no Moneyfarm investment or external table missing. Component of RealizedEquityClub. (T2 - SP_CID_DailyPanel_Club) |
| 64 | eMoneyBalance | money | YES | Customer's eToro Money wallet balance in USD (eMoney_dbo.CustomerEODBalance.EODBalanceAmount_USD, most recent EOD balance by GCID as of DateID). 0 if no eMoney account. Component of RealizedEquityClub. (T2 - SP_CID_DailyPanel_Club) |
| 65 | RealizedEquityClub | money | YES | **Club-eligible equity** used for tier qualification (post-2023): RealizedEquityNoCFD + eMoneyBalance + Moneyfarm. Excludes CFD positions. This is the metric against which tier thresholds are evaluated: IsFundedCurrentTier, AmountToUpgrade, AmountToRemain. (T2 - SP_CID_DailyPanel_Club) |
| 66 | ExpectedDowngradeStartDate | datetime | YES | **DEPRECATED — hardcoded '1900-01-01'.** See ExpectedDowngradeDate. (T2 - SP_CID_DailyPanel_Club) |
| 67 | LastContacted | datetime2(7) | YES | Timestamp of the customer's most recent successful contact by an Account Manager, sourced from BI_DB_UsageTracking_SF (Salesforce). Considers only ActionName IN ('Phone_Call_Succeed__c', 'Completed_Contact_Email__c'). NULL if never contacted. (T2 - SP_CID_DailyPanel_Club) |


---

## 5. Lineage

### 5.1 Production Sources

| Column Group | Source | Notes |
|-------------|--------|-------|
| Tier identity (CurrentTier, TierChangeDate, TierChangeType, IsFTC, FTCDate) | BI_DB_ClubChangeLogProduct | Most-recent row per CID as of @Date |
| Customer attributes (RegulationID, IsProCustomer, AccountManagerID) | DWH_dbo.Fact_SnapshotCustomer | Active snapshot row via Dim_Range |
| FTDDate | DWH_dbo.Dim_Customer | FirstDepositDate |
| Equity (RealizedEquity, Equity, RealizedEquityNoCFD) | DWH_dbo.V_Liabilities | WHERE DateID = @ddINT |
| Revenue (post-2023-08-23) | BI_DB_DailyCommisionReport | SUM(RollOverFee + FullCommissions) |
| Revenue (pre-2023-08-23) | DWH_dbo.Fact_CustomerAction | Open/close commissions + rollover |
| MIMO (Deposit/Withdraw) | BI_DB_DepositWithdrawFee | GROUP BY CID, DateID |
| CashoutFeePaid | DWH_dbo.Fact_BillingWithdraw | MAX(Fee) per WithdrawID |
| Credit line | BI_DB_Daily_CreditLine | WHERE DateID = @ddINT |
| eMoneyBalance | eMoney_dbo.CustomerEODBalance | Latest EOD by GCID ≤ @ddINT |
| Moneyfarm | External_MoneyFarm_CID_DailyPanelClub | External table (try/catch) |
| IOB consent | External_Interest_Trade_InterestConsent | Most-recent consent per CID |
| IOB daily interest | External_Interest_Trade_InterestDaily_CID_DailyPanelClub | External table (try/catch) |
| LastContacted | BI_DB_UsageTracking_SF | MAX(CreatedDate_SF) per CID |

Full column-level mapping: see `BI_DB_CID_DailyPanel_Club.lineage.md`.

### 5.2 ETL Pipeline

```
BI_DB_ClubChangeLogProduct (tier history)
  -> SP_CID_DailyPanel_Club(@Date)
     [+ V_Liabilities, BI_DB_DepositWithdrawFee, BI_DB_DailyCommisionReport,
        BI_DB_Daily_CreditLine, eMoney_dbo.CustomerEODBalance,
        External_MoneyFarm, External_Interest tables,
        BI_DB_UsageTracking_SF]
  -> DELETE WHERE DateID = @ddINT
  -> INSERT INTO BI_DB_CID_DailyPanel_Club
```

| Step | Object | Description |
|------|--------|-------------|
| Dependency | BI_DB_ClubChangeLogProduct | Must be populated for @Date before this SP runs |
| Dependency | BI_DB_DepositWithdrawFee | Must be populated for @Date |
| Dependency | BI_DB_DailyCommisionReport | Must be populated for @Date (post-2023) |
| Writer | SP_CID_DailyPanel_Club | DELETE + INSERT for @Date |
| Target | BI_DB_CID_DailyPanel_Club | Daily partition replaced (not full truncate) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Object | Join Column | Purpose |
|--------|------------|---------|
| BI_DB_dbo.BI_DB_ClubChangeLogProduct | CID | Primary tier change event source |
| DWH_dbo.Fact_SnapshotCustomer | RealCID = CID + Dim_Range | Customer attributes and valid-customer filter |
| DWH_dbo.Dim_PlayerLevel | PlayerLevelID = CurrentTier | Tier name, sort, equity bounds |
| DWH_dbo.V_Liabilities | CID + DateID | Equity values |
| BI_DB_dbo.BI_DB_DepositWithdrawFee | CID + DateID | Daily MIMO data |
| BI_DB_dbo.BI_DB_DailyCommisionReport | RealCID = CID + DateID | Revenue (post-2023) |
| BI_DB_dbo.BI_DB_Daily_CreditLine | RealCID = CID + DateID | Credit line data |
| eMoney_dbo.CustomerEODBalance | GCID + DateId | eMoney wallet balance |
| BI_DB_dbo.BI_DB_UsageTracking_SF | CID | AM contact history |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | CID + DateID (likely) | Full customer panel includes Club fields |
| Downstream CRM reports | CID + DateID | Club member segmentation |
| AM dashboards | CID, AccountManagerID | Account Manager Club member views |

---

## 7. Sample Queries

### 7.1 Club tier distribution for a specific date

```sql
SELECT dpl.Name AS Tier,
       dpl.Sort,
       COUNT(*) AS CustomerCount
FROM   [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club] cp
JOIN   [DWH_dbo].[Dim_PlayerLevel] dpl ON cp.CurrentTier = dpl.PlayerLevelID
WHERE  cp.DateID = 20260412
GROUP BY dpl.Name, dpl.Sort
ORDER BY dpl.Sort;
```

### 7.2 Customers who upgraded today — CRM trigger

```sql
SELECT CID, CurrentTier, LastTier, TierChangeType, RealizedEquityClub, AccountManagerID
FROM   [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club]
WHERE  DateID = 20260412
  AND  IsUpgrade = 1
ORDER BY CurrentTier DESC;
```

### 7.3 Customers at downgrade risk (funded below tier threshold)

```sql
SELECT CID, CurrentTier, RealizedEquityClub, AmountToRemain, AccountManagerID
FROM   [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club]
WHERE  DateID = 20260412
  AND  AmountToRemain > 0
  AND  CurrentTier > 1       -- above Bronze
ORDER BY AmountToRemain DESC;
```

### 7.4 Credit line upsell candidates

```sql
SELECT CID, CurrentTier, Equity, IsCreditEligible, IsCreditLineCustomer
FROM   [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club]
WHERE  DateID = 20260412
  AND  IsCreditEligible = 1
  AND  IsCreditLineCustomer = 0
ORDER BY Equity DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this specific table. Club program documentation may exist in Confluence DATA space under "eToro Club" or "CRM" pages.

---

*Generated: 2026-04-23 | Quality: 8.5/10 (****) | Phases: 11/14*
*Tiers: 4 T1, 63 T2, 0 T3, 0 T4, 0 T5 | Elements: 67/67, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_CID_DailyPanel_Club | Type: Table | Production Source: BI_DB_ClubChangeLogProduct (primary)*
