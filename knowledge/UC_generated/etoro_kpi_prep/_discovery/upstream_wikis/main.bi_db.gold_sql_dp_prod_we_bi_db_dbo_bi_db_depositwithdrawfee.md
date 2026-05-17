# BI_DB_dbo.BI_DB_DepositWithdrawFee

## 1. Overview

Daily **deposit, withdrawal, and fee / reversal-style cash events** at transaction grain, enriched with customer snapshot attributes, payment method and card metadata, merchant (**MID**) fields, and **PIPs** (payment processing) amounts in USD. Each row represents one logical transaction row from **Fact_Deposit_State** or **Fact_Cashout_State** (plus billing dimension joins); **Amount**, **AmountUSD**, and **PIPsCalculation** are signed after load using a transaction-type direction map.

**Row grain**: One row per **DepositWithdrawID** / **TransactionID** combination for the processed **DateID** (deposits and withdraws unions), after deduplication rules on billing withdraw.

---

## 2. Business context

Replaces legacy deposit/withdraw logic with the RnD PIPS-based pipeline (2025). Used for **finance reconciliation**, payment analytics, and geographic / method attribution (**RegCountry**, **BinCountry**, **CardType**, **MIDName**, etc.).

**Key business rules** (from `SP_DepositWithdrawFee`):
- **Scope**: Rows where **ModificationDateID** = **@StartDateID** from **Fact_Deposit_State** (deposits vs non-deposit types) and **Fact_Cashout_State** (withdraws vs non-withdraw types).
- **Withdraw path**: **Fact_Cashout_State** joined to deduped **Fact_BillingWithdraw** rows present in **Fact_Cashout_State** for that date (handles duplicate billing rows).
- **Deposit path**: **Fact_Deposit_State** joined to **Fact_BillingDeposit** for funding metadata.
- **ABS then sign**: Source amounts are loaded with **ABS**; final **UPDATE** applies **#amountDirections** so **Withdraw** / **Refund** / **Chargeback** types are negative where configured.
- **PIPsCalculation**: **ABS(ISNULL(PIPsInUSD,0))** at insert; further multiplied or negated by direction rules and special-case **UPDATE**s for rollback / chargeback-reversal rows joined to **Fact_CustomerAction**.
- **CreditTypeID**: Intentionally **NULL** in the modern proc (per change history).
- **MOPCountry**, **IsGermanBaFin**: **NULL** literals in current build.
- **IsIBANTrade**: **1** when billing **FlowID** = 2 (withdraw) or = 1 (deposit) per branch logic.
- **TransactionID**: **CAST(DepositID AS varchar) + 'D'** or **CAST(WPID AS varchar) + 'W'**.

**Related table**: **BI_DB_DepositWithdrawFee_Reversals** receives deposit/withdraw **reversal** subsets from the same SP (not documented in this file).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 44 |
| **Distribution** | HASH(CID) |
| **Clustered index** | CLUSTERED COLUMNSTORE INDEX |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as **YYYYMMDD** for the load (**@StartDateID**). (Tier 2 -- SP_DepositWithdrawFee, @StartDateID) |
| 2 | CID | int | YES | Internal customer id (**RealCID**) from deposit or cashout state. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.CID / Fact_Cashout_State.CID) |
| 3 | DepositWithdrawID | int | YES | **DepositID** or **WithdrawID** depending on path -- stable id for the cash event. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositID / Fact_Cashout_State.WithdrawID) |
| 4 | Occurred | datetime | YES | Event timestamp (**ModificationDate** from state fact). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ModificationDate) |
| 5 | CreditTypeID | int | YES | Set to **NULL** in the current procedure (legacy column retired). (Tier 2 -- SP_DepositWithdrawFee, NULL) |
| 6 | TransactionID | varchar(200) | YES | Synthetic id: deposit id + **D** or WP id + **W**. (Tier 2 -- SP_DepositWithdrawFee, computed) |
| 7 | Date | date | YES | Calendar date of **ModificationDate**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ModificationDate) |
| 8 | Customer | varchar(200) | YES | External customer id (**Dim_Customer.ExternalID**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Customer.ExternalID) |
| 9 | TransactionType | varchar(200) | YES | Type string from state (**Deposit**, **Withdraw**, chargebacks, refunds, rollbacks, etc.). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.TransactionType) |
| 10 | PaymentMethod | varchar(200) | YES | Funding type name (**Dim_FundingType.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_FundingType.Name) |
| 11 | Amount | numeric(38,8) | YES | Transaction amount in original currency; **ABS** at insert then signed via **#amountDirections** (and edge-case **UPDATE**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.Amount) |
| 12 | Currency | varchar(200) | YES | Currency code (**Dim_Currency.Abbreviation**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Currency.Abbreviation) |
| 13 | ExchangeRate | numeric(38,8) | YES | FX rate on the state row. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExchangeRate) |
| 14 | AmountUSD | numeric(38,8) | YES | USD amount; **ABS** at insert then signed like **Amount**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.AmountInUSD) |
| 15 | RegulationID | int | YES | Regulation key from customer snapshot. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.RegulationID) |
| 16 | LabelID | int | YES | Marketing / label id from snapshot (deposit path uses **dc.LabelID** join in one branch). (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.LabelID / Dim_Customer.LabelID) |
| 17 | PlayerLevelID | int | YES | Player level id from snapshot. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.PlayerLevelID) |
| 18 | Regulation | varchar(200) | YES | Regulation name (**Dim_Regulation.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Regulation.Name) |
| 19 | Label | varchar(200) | YES | Label name (**Dim_Label.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_Label.Name) |
| 20 | IsValidCustomer | int | YES | Snapshot validity flag. (Tier 2 -- SP_DepositWithdrawFee, Fact_SnapshotCustomer.IsValidCustomer) |
| 21 | UpdateDate | datetime | NO | Row load timestamp (**GETDATE()** at insert). (Tier 3 -- SP_DepositWithdrawFee, GETDATE()) |
| 22 | BaseExchangeRate | numeric(38,8) | YES | Base FX rate from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.BaseExchangeRate) |
| 23 | ExchangeFee | numeric(38,8) | YES | Exchange fee from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExchangeFee) |
| 24 | ExternalTransactionID | varchar(200) | YES | Provider transaction id (**ExTransactionID**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.ExTransactionID) |
| 25 | Depot | varchar(200) | YES | Billing depot name (**Dim_BillingDepot**). (Tier 2 -- SP_DepositWithdrawFee, Dim_BillingDepot.Name) |
| 26 | MIDValue | varchar(200) | YES | Merchant id value on the state row (**MID**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.MID) |
| 27 | Club | varchar(200) | YES | Player level / club name (**Dim_PlayerLevel.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_PlayerLevel.Name) |
| 28 | PlayerStatus | varchar(200) | YES | Player status label (**Dim_PlayerStatus.Name**). (Tier 2 -- SP_DepositWithdrawFee, Dim_PlayerStatus.Name) |
| 29 | PIPsCalculation | numeric(38,8) | YES | **ABS(PIPsInUSD)** at insert; adjusted by direction rules and post-join **UPDATE**s (rollbacks, chargeback reversals, **Fact_CustomerAction** tie-break). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.PIPsInUSD) |
| 30 | RegCountry | varchar(200) | YES | Registration country from snapshot **CountryID**. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name) |
| 31 | RegCountryByIP | varchar(50) | YES | Country from customer **CountryIDByIP**. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name) |
| 32 | CardType | varchar(200) | YES | Card type name (**Dim_CardType.CarTypeName**) or raw **Fact_Deposit_State.CardType** on deposit path. (Tier 2 -- SP_DepositWithdrawFee, Dim_CardType / Fact_Deposit_State) |
| 33 | CardCategory | varchar(200) | YES | Card category from billing deposit or withdraw. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingDeposit / Fact_BillingWithdraw) |
| 34 | BinCountry | varchar(200) | YES | Country from BIN country id on billing. (Tier 2 -- SP_DepositWithdrawFee, Dim_Country.Name) |
| 35 | MOPCountry | varchar(200) | YES | Not populated (**NULL**) in current SP. (Tier 2 -- SP_DepositWithdrawFee, NULL) |
| 36 | IsGermanBaFin | int | YES | Not populated (**NULL**) in current SP. (Tier 2 -- SP_DepositWithdrawFee, NULL) |
| 37 | IsIBANTrade | int | YES | **1** when deposit **FlowID** = 1 or withdraw **FlowID** = 2 on billing fact. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingDeposit.FlowID / Fact_BillingWithdraw.FlowID) |
| 38 | MIDName | varchar(200) | YES | Merchant display name from state. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.MIDName) |
| 39 | GuruStatus | varchar(200) | YES | Guru status from snapshot (**Dim_GuruStatus**). (Tier 2 -- SP_DepositWithdrawFee, Dim_GuruStatus.GuruStatusName) |
| 40 | PreviousTransactionStatus | varchar(200) | YES | Prior status on state (**PreviousStatus** / **PreviousStatus**). (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.PreviousStatus) |
| 41 | TransactionStatus | varchar(200) | YES | Current status (**DepositStatus** or **CashoutStatus**). (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositStatus / Fact_Cashout_State.CashoutStatus) |
| 42 | DepositID | int | YES | Populated on deposit rows; **NULL** on withdraw rows. (Tier 2 -- SP_DepositWithdrawFee, Fact_Deposit_State.DepositID) |
| 43 | WithdrawPaymentID | int | YES | Populated on withdraw rows; **NULL** on deposit rows. (Tier 2 -- SP_DepositWithdrawFee, Fact_BillingWithdraw.WithdrawPaymentID) |
| 44 | CreditID | bigint | YES | Credit id from state (**CreditID**) for reconciliation to **Fact_CustomerAction**. (Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.CreditID) |

---

## 5. Relationships

### Source tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| Fact_Deposit_State | DWH_dbo | Deposit and non-deposit transaction stream |
| Fact_Cashout_State | DWH_dbo | Withdraw and non-withdraw transaction stream |
| Fact_BillingDeposit | DWH_dbo | Deposit billing metadata |
| Fact_BillingWithdraw | DWH_dbo | Withdraw billing metadata (deduped for withdraw branch) |
| Dim_Customer | DWH_dbo | Customer external id, IP country |
| Fact_SnapshotCustomer | DWH_dbo | Regulation, label, player attributes |
| Dim_Range | DWH_dbo | Snapshot validity for modification date |
| Dim_Regulation, Dim_Label, Dim_PlayerLevel, Dim_PlayerStatus, Dim_GuruStatus | DWH_dbo | Descriptive attributes |
| Dim_Currency, Dim_FundingType, Dim_BillingDepot, Dim_CardType, Dim_Country | DWH_dbo | Reference data |
| Fact_CustomerAction | DWH_dbo | Post-load sign fixes for **PIPsCalculation** / amounts (edge cases) |

### Consumers

| Consumer | Purpose |
|----------|---------|
| Finance reporting & PIPs reconciliation | Cash movement and fee analysis by method and geography |

---

## 6. ETL & lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DepositWithdrawFee |
| **ETL pattern** | DELETE by **DateID**, INSERT union of **#deposits** and **#withdraws**, then **UPDATE** sign corrections |
| **Schedule** | Daily, Priority 99 (FinanceReportSPS) |
| **Parameter** | **@StartDate** (DATE) |
| **Delete scope** | `DELETE WHERE DateID = @StartDateID` |
| **Process log name** | **SP_DepositWithdrawFee_2025** (in **SP_ProcessStatusLog** call inside the procedure) |

---

## 7. Query advisory

| Consideration | Guidance |
|---------------|----------|
| **Filter on DateID and CID** | HASH on **CID**; **DateID** is the primary partition for daily reloads. |
| **Sign interpretation** | Always use post-**UPDATE** values; do not assume raw source sign. |
| **Reversals** | Reversal-only rows live in **BI_DB_DepositWithdrawFee_Reversals**. |
| **NULL columns** | **CreditTypeID**, **MOPCountry**, **IsGermanBaFin** are intentionally null today. |

---

## 8. Classification & status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Payments |
| **Sub-domain** | Deposits, withdrawals, fees |
| **Sensitivity** | PII-adjacent (**Customer**, **CID**, payment metadata) |
| **Owner** | Finance / Billing analytics |
| **Quality score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
