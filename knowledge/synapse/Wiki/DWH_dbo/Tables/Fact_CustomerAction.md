# DWH_dbo.Fact_CustomerAction

> The central customer activity fact table in the Synapse DWH, recording every significant user action — position opens/closes, logins, deposits, cashouts, fees, bonuses, social engagement, copy-trade operations, and more — as one row per event.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Distribution** | HASH(RealCID) |
| **Index Type** | CLUSTERED COLUMNSTORE + 4 nonclustered |
| **Row Count** | ~11 billion |
| **Production Sources** | `History.Credit` (via `History.ActiveCredit`), `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `STS_Audit_UserOperationsData` (logins), `Billing.Login` (cashier logins), `Customer.CustomerStatic` (registrations) |
| **Refresh** | Daily (midnight ETL via SWITCH partition) |

---

## 1. Business Meaning

`DWH_dbo.Fact_CustomerAction` is the unified customer event log for the eToro platform. Every significant action a customer performs — opening a position, closing a position, depositing money, withdrawing, logging in, publishing a social post, receiving a fee, getting a bonus, registering an account — is captured as a single row in this table. It answers: "What did this customer do, when, and what were the financial details?"

The table consolidates events from five distinct production sources into a single ActionTypeID-driven schema:
1. **Position opens** (ActionTypeID 1-3, 39): From `Trade.OpenPositionEndOfDay` via the Generic Pipeline + staging
2. **Position closes** (ActionTypeID 4-6, 28, 40): From `History.ClosePositionEndOfDay` via the Generic Pipeline + staging
3. **Credit/financial events** (ActionTypeID 7-13, 15-20, 27, 30, 32, 34-38, 42-45): From `History.Credit` (which unions `History.ActiveCredit` + archived Credit partition tables back to 2007)
4. **Logins** (ActionTypeID 14): From `STS_Audit_UserOperationsData` (Session Tracking Service) with platform/browser detection
5. **Registrations** (ActionTypeID 41): From `Customer.CustomerStatic`

Because the table unions fundamentally different event types, **most columns are only populated for specific ActionTypeIDs**. Position-related columns (InstrumentID, Leverage, Commission, IsBuy, etc.) are NULL/0 for non-position events. Fee-specific columns (IsFeeDividend, DividendID) are only set for ActionTypeID=35. This is a sparse fact table by design.

The data originates from production systems, flows through the Azure Data Lake and DWH staging tables, and is loaded by `SP_Fact_CustomerAction_DL_To_Synapse` (staging extract) and `SP_Fact_CustomerAction` (transform + load). Post-load, `SP_Fact_CustomerAction_IsParitalCloseParent` marks partial-close parents. The load uses SWITCH partition for daily increments.

---

## 2. Business Logic

### 2.1 ActionTypeID — Event Classification

**What**: Every row is classified by ActionTypeID, which determines what type of customer action occurred and which columns are populated.

**Columns Involved**: `ActionTypeID`, mapped via `DWH_dbo.Dim_ActionType`

**Rules**:

| ActionTypeID | Name | Category | Source |
|---|---|---|---|
| 1 | ManualPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID=0 |
| 2 | CopyPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID>0, OrigParentPositionID>0 |
| 3 | CopyPlusPositionOpen | PositionOpen | Trade.OpenPositionEndOfDay — MirrorID=0, OrigParentPositionID>0 |
| 4 | ManualPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 5 | CopyPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 6 | CopyPlusPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 7 | Deposit | Deposit | History.Credit (CreditTypeID=1) |
| 8 | Cashout | Cashout | History.Credit (CreditTypeID=2) |
| 9 | Bonus | Bonus | History.Credit (CreditTypeID=7) |
| 10 | Cashout request | Cashout request | History.Credit (CreditTypeID=9) |
| 11 | Chargeback | Chargeback | History.Credit (CreditTypeID=11) |
| 12 | Refund | Refund | History.Credit (CreditTypeID=12) |
| 14 | LoggedIn | LoggedIn | STS_Audit_UserOperationsData |
| 15 | Account balance to mirror | Mirror ops | History.Credit (CreditTypeID=18) |
| 16 | Mirror balance to account | Mirror ops | History.Credit (CreditTypeID=19) |
| 17 | Register new mirror | Mirror ops | History.Credit (CreditTypeID=20) |
| 18 | Unregister mirror | Mirror ops | History.Credit (CreditTypeID=21) |
| 19 | Detach position from mirror | DetachPosition | History.Credit |
| 21-26 | Publish Post/Comment/Like, Received Post/Comment/Like | Social engagement | **DEAD DATA** — legacy rows exist but no longer updated. No active ETL. |
| 27 | DepositAttempt | DepositAttempt | History.Credit |
| 28 | DetachedPositionClose | PositionClose | History.ClosePositionEndOfDay |
| 29 | Cashier Loggin | Cashier login | Billing.Login |
| 30 | Processed Cashout | Processed Cashout | History.Credit (CreditTypeID=2 processed) |
| 32 | Edit StopLoss | Edit StopLoss | History.Credit (CreditTypeID=13) |
| 34 | Open Stock Order | Stock order | History.Credit (CreditTypeID=29) |
| 35 | End Of The Week Fee | Fees | History.Credit (CreditTypeID=14) — overnight, weekend, dividend, SDRT, ticket fees |
| 36 | Compensation | Compensation | History.Credit (CreditTypeID=6) |
| 37 | Reverse cashout | Reverse cashout | History.Credit (CreditTypeID=8) |
| 38 | Affiliate Deposit | Deposit | History.Credit |
| 39 | PositionOpenTypeUnknown | PositionOpen | Position open without matching History.Credit (fix at weekly maintenance) |
| 40 | PositionCloseTypeUnknown | PositionClose | Position close without matching History.Credit |
| 41 | Customer Registration | Registration | Customer.CustomerStatic |
| 42 | Cashout Rollback | Chargeback | History.Credit (CreditTypeID=33) |
| 43 | Reverse Deposit | Reverse Deposit | History.Credit (CreditTypeID=32) |
| 44 | InternalDeposit | Deposit | History.Credit (MoveMoneyReasonID=5) |
| 45 | InternalWithdraw | Withdraw | History.Credit (MoveMoneyReasonID=5) |

### 2.2 IsFeeDividend — Fee Sub-Classification

**What**: For ActionTypeID=35 (End of Week Fee), classifies the specific fee type.

**Columns Involved**: `IsFeeDividend`, `Description`

**Rules** (per DSM-1463):
- `1` = Overnight/weekend fee (Description: "Over night fee", "Weekend fee")
- `2` = Dividend payment (Description LIKE '%dividend%')
- `3` = SDRT charge (Description LIKE '%sdrt%')
- `4` = Ticket fees (Description: "OpenTotalFees" or "CloseTotalFees")
- `NULL` = Not ActionTypeID=35

### 2.3 Position-Derived Columns (Shared with Dim_Position)

**What**: ~33 columns in Fact_CustomerAction are copies of the same data from `Trade.OpenPositionEndOfDay` / `History.ClosePositionEndOfDay` that also populates `DWH_dbo.Dim_Position`. These columns display the same data under the same column names but are populated independently at ETL time.

**Shared columns**: `PositionID`, `InstrumentID`, `Amount`, `Leverage`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `MirrorID`, `IsSettled`, `InitialUnits`, `IsDiscounted`, `CommissionByUnits`, `FullCommissionByUnits`, `RegulationIDOnOpen`, `ReopenForPositionID`, `IsReOpen`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `OriginalPositionID`, `IsPartialCloseParent`, `IsPartialCloseChild`, `IsAirDrop`, `SettlementTypeID`, `DLTOpen`, `DLTClose`, `OpenMarkupByUnits`, `IsBuy`, `NetProfit`, `RedeemStatus`, `RedeemID`, `IsRedeem`

**Rules**:
- These columns are ONLY populated for position events (ActionTypeID IN 1-6, 28, 39, 40)
- For non-position events, these columns are 0 or NULL
- The ETL joins from staging tables directly — NOT from Dim_Position itself
- Column meanings are identical to Dim_Position (see `Dim_Position.md` for detailed descriptions)

### 2.4 PlatformID — Product/Platform Resolution

**What**: Identifies which product/platform the action originated from. Badly named — it's actually a FK to `Dim_Product.ProductID`, not a standalone platform enum.

**Columns Involved**: `PlatformID`

**Rules**:
- Only populated for ActionTypeID=14 (logins) and 41 (registrations)
- Resolve via JOIN to `DWH_dbo.Dim_Product` — provides Product, Platform, and SubPlatform columns
- Do NOT hard-code value mappings (101=Android, etc.) — always JOIN to Dim_Product

**Query pattern**:
```sql
SELECT dp.Product, dp.Platform, dp.SubPlatform, fca.*
FROM DWH_dbo.Fact_CustomerAction fca
JOIN DWH_dbo.Dim_Product dp ON fca.PlatformID = dp.ProductID
WHERE fca.ActionTypeID = 14
```

### 2.6 Reopen Commission Adjustment

**What**: For reopened positions (IsReOpen=1), the commission at close is adjusted.

**Columns Involved**: `CommissionOnClose`, `FullCommissionOnClose`, `CommissionOnCloseOrig`, `FullCommissionOnCloseOrig`, `IsReOpen`, `ReopenForPositionID`

**Rules**:
- `CommissionOnClose = new_position.CommissionOnClose - original_position.CommissionOnClose`
- `CommissionOnCloseOrig` / `FullCommissionOnCloseOrig` preserve original values

---

## 3. Query Advisory

### 3.1 Distribution Key

This table is HASH-distributed on `RealCID`. Always include `RealCID` in WHERE or JOIN for optimal single-distribution queries. Nonclustered indexes exist on `ActionTypeID+DateID`, `ActionTypeID`, `CompensationReasonID`, and `RealCID+DateID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All logins for a customer | `WHERE ActionTypeID = 14 AND RealCID = @cid` |
| Position opens in a date range | `WHERE ActionTypeID IN (1,2,3) AND DateID BETWEEN @start AND @end` |
| Revenue (commissions) | `WHERE ActionTypeID IN (1,2,3,4,5,6,28) AND Commission > 0` |
| Deposits for a customer | `WHERE ActionTypeID = 7 AND RealCID = @cid` |
| Overnight fees | `WHERE ActionTypeID = 35 AND IsFeeDividend = 1` |
| Dividend payments | `WHERE ActionTypeID = 35 AND IsFeeDividend = 2` |
| First-time deposits (FTD) | `WHERE IsFTD = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_ActionType` | `ON fca.ActionTypeID = dat.ActionTypeID` | Action type name and category |
| `DWH_dbo.Dim_Customer` | `ON fca.RealCID = dc.RealCID` | Customer demographics, country |
| `DWH_dbo.Dim_Instrument` | `ON fca.InstrumentID = di.InstrumentID` | Instrument name (position events only) |
| `DWH_dbo.Dim_Position` | `ON fca.PositionID = dp.PositionID` | Full position details (avoid when possible — heavy join on 11B rows) |
| `DWH_dbo.Dim_BonusType` | `ON fca.BonusTypeID = dbt.BonusTypeID` | Bonus type name, IsWithdrawable (bonus events only) |
| `DWH_dbo.Dim_Campaign` | `ON fca.CampaignID = dcm.CampaignID` | Campaign code, description, dates |
| `DWH_dbo.Dim_Country` | `ON fca.CountryIDByIP = dco.CountryID` | Country name from IP geolocation |
| `DWH_dbo.Dim_FundingType` | `ON fca.FundingTypeID = dft.FundingTypeID` | Payment method name (deposit/cashout events) |
| `DWH_dbo.Dim_PaymentStatus` | `ON fca.PaymentStatusID = dps.PaymentStatusID` | Payment status name |
| `DWH_dbo.Dim_Product` | `ON fca.PlatformID = dp.ProductID` | Product, Platform, SubPlatform (logins/registrations only) |
| `DWH_dbo.Dim_Date` | `ON fca.DateID = dd.DateID` | Calendar attributes |
| `DWH_dbo.Dim_Regulation` | `ON fca.RegulationIDOnOpen = dr.ID` | Regulation name |

### 3.4 Gotchas

- **Most columns are only populated for specific ActionTypeIDs.** InstrumentID, Leverage, Commission, IsBuy are all 0/NULL for logins, deposits, social events, etc.
- **11 billion rows** — always filter by ActionTypeID + DateID to avoid full scans
- **IsReal is always 1** in this table — it only contains real-account actions (no demo)
- **Leverage=0 means non-position event**, not "no leverage". For actual position opens, Leverage=1 means no leverage (real ownership)
- **IsBuy NULL** means non-position event. For position events: True=Buy, False=Sell
- **Description is sparse** — only populated for fee events (ActionTypeID=35) and a few others. Contains human-readable strings like "Over night fee", "Payment caused by dividend", "OpenTotalFees"
- **PlatformTypeID** vs **PlatformID**: PlatformTypeID is a legacy field (0=default, 99=STS); PlatformID is a FK to `Dim_Product.ProductID` (badly named — always JOIN to Dim_Product, don't hard-code values)
- **StatusID is nearly always 1** (~11B rows with StatusID=1, ~2M NULL)
- **DemoCID is always 0** (real accounts only)
- **HistoryID is NOT unique** — despite being intended as a key, it contains duplicates. Never use it for JOINs, deduplication, or row identification

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | decimal(38,0) | NO | Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert) |
| 2 | GCID | int | NO | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 3 | RealCID | int | NO | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | DemoCID | int | NO | Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 5 | Occurred | datetime | NO | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 6 | IPNumber | bigint | YES | IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login) |
| 7 | IsReal | tinyint | NO | Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 8 | ActionTypeID | smallint | NO | Event type classifier. References `DWH_dbo.Dim_ActionType.ActionTypeID` — JOIN for Name, Category, CategoryID. See Section 2.1 for full mapping. Key filter column — drives which other columns are populated. (Tier 1 — ETL-derived from CreditTypeID/source) |
| 9 | PlatformTypeID | smallint | NO | Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms. (Tier 3 — ETL-assigned) |
| 10 | InstrumentID | int | NO | Financial instrument. References `Dim_Instrument`. 0 for non-position events. Same meaning as `Dim_Position.InstrumentID`. (Tier 1 — Trade.OpenPositionEndOfDay / History.ClosePositionEndOfDay) |
| 11 | Amount | decimal(11,2) | NO | Event amount in account currency (USD). For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative). (Tier 1 — source-dependent) |
| 12 | Leverage | int | NO | Leverage multiplier for position events. 0 for non-position events. 1=no leverage. Same meaning as `Dim_Position.Leverage`. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 13 | NetProfit | money | NO | Realized P&L for position closes. 0 for opens and non-position events. Same meaning as `Dim_Position.NetProfit`. (Tier 1 — History.ClosePositionEndOfDay) |
| 14 | Commission | money | NO | eToro markup (spread) at position open, in account currency. 0 for non-position events. Same meaning as `Dim_Position.Commission`. (Tier 5 — domain expert) |
| 15 | PositionID | bigint | NO | Position identifier for position events. 0 for non-position events. Same meaning as `Dim_Position.PositionID`. (Tier 1 — Trade positions) |
| 16 | CampaignID | int | NO | Marketing campaign identifier. 0 if not campaign-related. References `DWH_dbo.Dim_Campaign.CampaignID` — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive. (Tier 5 — domain expert) |
| 17 | BonusTypeID | smallint | NO | Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus events. References `DWH_dbo.Dim_BonusType.BonusTypeID` — JOIN for Name, IsWithdrawable, IsActive. (Tier 5 — domain expert) |
| 18 | FundingTypeID | smallint | NO | Payment method used for deposits/withdrawals. 0 for non-deposit events. References `DWH_dbo.Dim_FundingType.FundingTypeID` — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive. (Tier 5 — domain expert) |
| 19 | LoginID | int | NO | Login session identifier from `Billing.Login`. 0 for non-login events. (Tier 1 — Billing.Login) |
| 20 | MirrorID | int | NO | Copy-trade relationship ID. 0=manual action, >0=action within a copy-trade. Same meaning as `Dim_Position.MirrorID`. (Tier 1 — Trade positions) |
| 21 | WithdrawID | int | NO | Withdrawal request ID for cashout events. 0 for non-cashout events. (Tier 1 — History.Credit) |
| 22 | DurationInSeconds | int | YES | Duration of a login session in seconds. NULL for non-login events. (Tier 1 — Billing.Login) |
| 23 | PostID | uniqueidentifier | YES | Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. (Tier 1 — Social platform) |
| 24 | CaseID | int | NO | CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise. (Tier 1 — CRM) |
| 25 | UpdateDate | datetime | NO | UTC timestamp of the last DWH ETL update for this row. Set to `GETUTCDATE()` during each ETL run. (Tier 2 — ETL-assigned) |
| 26 | DateID | int | NO | Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. (Tier 2 — ETL-computed) |
| 27 | TimeID | int | NO | Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`. (Tier 2 — ETL-computed) |
| 28 | StatusID | tinyint | YES | Row status. Nearly always 1 (active). NULL for ~2M rows. (Tier 3 — ETL-assigned) |
| 29 | PreviousOccurred | datetime | YES | Deprecated/unused column. NULL for most rows — not reliably populated. Do not use. (Tier 5 — domain expert) |
| 30 | CompensationReasonID | int | NO | Compensation reason for compensation events (ActionTypeID=36) and position opens (for airdrop identification). References `BackOffice.CompensationReason`. 0 for non-compensation events. (Tier 1 — History.Credit, updated 2025-12-21) |
| 31 | WithdrawPaymentID | int | NO | Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL. (Tier 1 — History.Credit) |
| 32 | CommissionOnClose | money | NO | eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as `Dim_Position.CommissionOnClose`. (Tier 5 — domain expert) |
| 33 | IsPlug | bit | YES | Deprecated/unused column. Always NULL. (Tier 5 — domain expert) |
| 34 | DepositID | int | YES | Deposit transaction identifier. NULL for non-deposit events. (Tier 1 — History.Credit) |
| 35 | PostRootID | varchar(200) | YES | Root post ID for social engagement events. NULL for non-social events. (Tier 1 — Social platform) |
| 36 | FullCommission | money | YES | Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as `Dim_Position.FullCommission`. (Tier 5 — domain expert) |
| 37 | FullCommissionOnClose | money | YES | Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as `Dim_Position.FullCommissionOnClose`. (Tier 5 — domain expert) |
| 38 | RedeemID | int | YES | Crypto redemption transaction reference. NULL when not a redeem. Same meaning as `Dim_Position.RedeemID`. (Tier 1 — Billing.Redeem) |
| 39 | RedeemStatus | int | YES | Crypto redemption status: 0=N/A, 1=Pending, 6=Closed by redeem, 20=Terminated, 21=FailedToCancel. Same meaning as `Dim_Position.RedeemStatus`. (Tier 5 — domain expert) |
| 40 | SessionID | bigint | YES | STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events. (Tier 1 — STS) |
| 41 | IsRedeem | int | YES | Redeem flag. 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as `Dim_Position.IsRedeem` (via RedeemStatus mapping). (Tier 3 — ETL-derived) |
| 42 | RegulationIDOnOpen | int | YES | Regulatory jurisdiction at position open time. Same mapping as `Dim_Position.RegulationIDOnOpen`: 0=None, 1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 9=FSA Seychelles, etc. NULL for non-position events. (Tier 2 — BackOffice.Customer) |
| 43 | PlatformID | int | YES | Product/platform identifier — badly named, actually references `Dim_Product.ProductID` (not a standalone platform enum). Resolves to Product, Platform, and SubPlatform via JOIN to `DWH_dbo.Dim_Product`. Only populated for ActionTypeID=14 (logins) and 41 (registrations). (Tier 5 — domain expert) |
| 44 | ReopenForPositionID | bigint | YES | For reopened positions: the PositionID of the original closed position. Same meaning as `Dim_Position.ReopenForPositionID`. (Tier 1 — Trade positions) |
| 45 | IsReOpen | int | YES | Reopen flag: 1 = position created by reopening. Same meaning as `Dim_Position.IsReOpen`. (Tier 1 — Trade positions) |
| 46 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustment. Same meaning as `Dim_Position.CommissionOnCloseOrig`. (Tier 2 — ETL reopen logic) |
| 47 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reopen adjustment. Same meaning as `Dim_Position.FullCommissionOnCloseOrig`. (Tier 2 — ETL reopen logic) |
| 48 | OriginalPositionID | bigint | YES | For partial-close children: the parent PositionID. When `OriginalPositionID ≠ PositionID`, this is a partial-close child. Same meaning as `Dim_Position.OriginalPositionID`. (Tier 2 — ETL-derived) |
| 49 | IsPartialCloseParent | int | YES | Flag: 1 = this position has had partial close children. Set by `SP_Fact_CustomerAction_IsParitalCloseParent`. Same meaning as `Dim_Position.IsPartialCloseParent`. (Tier 2 — post-load SP) |
| 50 | IsPartialCloseChild | int | YES | Flag: 1 = this position was created by partial close. Filter out when counting positions. Same meaning as `Dim_Position.IsPartialCloseChild`. (Tier 2 — ETL-derived) |
| 51 | InitialUnits | decimal(16,6) | YES | Original unit count at position open. Same meaning as `Dim_Position.InitialUnits`. (Tier 1 — Trade positions) |
| 52 | PaymentStatusID | int | YES | Payment processing status for deposit/cashout events. NULL for non-payment events. References `DWH_dbo.Dim_PaymentStatus.PaymentStatusID` — JOIN for Name. (Tier 5 — domain expert) |
| 53 | IsDiscounted | int | YES | Discounted pricing flag: 0=standard, 1=discounted (VIP/partner). Same meaning as `Dim_Position.IsDiscounted`. (Tier 1 — Trade.PositionTreeInfo) |
| 54 | IsSettled | int | YES | Real ownership flag: 1=settled (customer owns asset), 0=CFD. NULL for non-position events. The ETL also derives IsSettled when source is NULL: `IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) → 1`. Same meaning as `Dim_Position.IsSettled`. (Tier 1 — Trade positions, with ETL fallback) |
| 55 | CommissionByUnits | decimal(38,6) | YES | Commission prorated by units: `(AmountInUnitsDecimal / InitialUnits) * Commission`. Same meaning as `Dim_Position.CommissionByUnits`. (Tier 5 — domain expert) |
| 56 | FullCommissionByUnits | decimal(38,6) | YES | Full spread prorated by units. Same meaning as `Dim_Position.FullCommissionByUnits`. (Tier 5 — domain expert) |
| 57 | IsFTD | int | YES | First-Time Deposit flag: 1 = this is the customer's first deposit. NULL for non-deposit events. (Tier 2 — ETL-computed) |
| 58 | CountryIDByIP | int | YES | Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID` — JOIN for country name. Also see `DWH_dbo.Dim_CountryIP` for IP-to-country resolution. (Tier 5 — domain expert) |
| 59 | IsAnonymousIP | int | YES | Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows. (Tier 1 — IP geolocation) |
| 60 | ProxyType | varchar(3) | YES | Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections. (Tier 1 — STS) |
| 61 | IsFeeDividend | int | YES | Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See Section 2.2 and DSM-1463. (Tier 2 — ETL-derived from Description) |
| 62 | IsAirDrop | int | YES | Airdrop flag: 1 = position created by eToro on behalf of customer. Same meaning as `Dim_Position.IsAirDrop`. (Tier 5 — domain expert, via Trade.PositionAirdropLog) |
| 63 | DividendID | int | YES | Dividend event identifier for dividend-related fees. NULL for non-dividend events. (Tier 1 — Trade positions) |
| 64 | MoveMoneyReasonID | int | YES | Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. References `Dictionary.MoveMoneyReason`. (Tier 1 — History.Credit) |
| 65 | SettlementTypeID | int | YES | Settlement mechanism: 0=CFD, 1=Real asset, 2/4/5=other. NULL for non-position events. Same meaning as `Dim_Position.SettlementTypeID`. (Tier 1 — Trade positions) |
| 66 | DLTOpen | smallint | YES | DLT (German crypto broker) flag at open: 0=not executed via DLT broker, 1=opened on DLT broker platform. NULL for non-position events. Same meaning as `Dim_Position.DLTOpen`. (Tier 5 — domain expert, added 2024-06) |
| 67 | DLTClose | smallint | YES | DLT broker flag at close: 1=closed on DLT broker platform. Same meaning as `Dim_Position.DLTClose`. (Tier 5 — domain expert, added 2024-06) |
| 68 | OpenMarkupByUnits | money | YES | Open markup prorated by units: `OpenMarkup * AmountInUnitsDecimal / InitialUnits`. Same meaning as `Dim_Position.OpenMarkupByUnits`. (Tier 5 — domain expert) |
| 69 | Description | varchar(255) | YES | Human-readable description. Populated mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". For ActionTypeID=32: "edit stop loss by customer". For deposits: "Processed By eToro.Payments.Deposit", etc. (Tier 1 — History.Credit, added 2024-08) |
| 70 | IsBuy | bit | YES | Trade direction: True=Buy (long), False=Sell (short). NULL for non-position events. Same meaning as `Dim_Position.IsBuy`. (Tier 1 — Trade positions, added 2024-09) |
| 71 | CreditID | bigint | YES | Reference to the source `History.Credit.CreditID`. Enables join back to credit history for audit. (Tier 1 — History.Credit, added 2025-07) |

---

## 5. Relationships

### 5.1 References To

| Target Object | Join Column | Purpose |
|--------------|-------------|---------|
| DWH_dbo.Dim_ActionType | ActionTypeID | Action type name and category |
| DWH_dbo.Dim_Customer | RealCID | Customer demographics, country, regulation |
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument name, type (position events only) |
| DWH_dbo.Dim_Position | PositionID | Full position details (position events only) |
| DWH_dbo.Dim_Product | PlatformID → ProductID | Product, Platform, SubPlatform (badly named FK) |
| DWH_dbo.Dim_Regulation | RegulationIDOnOpen | Regulation name at event time |
| DWH_dbo.Dim_Date | DateID | Calendar attributes |
| DWH_dbo.Dim_BonusType | BonusTypeID | Bonus type name, IsWithdrawable, IsActive |
| DWH_dbo.Dim_Campaign | CampaignID | Campaign code, description, dates, bonus amount |
| DWH_dbo.Dim_Country | CountryIDByIP → CountryID | Country name (IP geolocation) |
| DWH_dbo.Dim_FundingType | FundingTypeID | Payment method name and properties |
| DWH_dbo.Dim_PaymentStatus | PaymentStatusID | Payment status name |
| Dictionary.CreditType | (via CreditID → History.Credit) | Credit type classification |
| Dictionary.MoveMoneyReason | MoveMoneyReasonID | Money movement reason |

### 5.2 Referenced By

| Source Object | Type | Usage |
|--------------|------|-------|
| BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms | Function | First deposit across platforms |
| BI_DB_dbo.Function_Population_Active_Traders | Function | Active trader population |
| BI_DB_dbo.Function_Population_First_Time_Funded | Function | FTD population |
| BI_DB_dbo.Function_Population_First_Trading_Action | Function | First trading action |
| BI_DB_dbo.Function_Population_OTD_DateRange | Function | OTD date range population |
| BI_DB_dbo.Function_Revenue_Commissions | Function | Commission revenue calculation |
| BI_DB_dbo.Function_Revenue_FullCommissions | Function | Full commission revenue |
| BI_DB_dbo.Function_Revenue_CashoutFee_* | Function | Cashout fee revenue |
| BI_DB_dbo.Function_Revenue_DormantFee | Function | Dormant fee revenue |
| BI_DB_dbo.Function_Revenue_Share_Lending | Function | Share lending revenue |
| BI_DB_dbo.Function_Revenue_TransferCoinFee | Function | Crypto transfer fee revenue |
| BI_DB_dbo.V_C2P_Positions | View | CRM-to-position mapping |
| DWH_dbo.V_FCA_NumOfLogins_mean_1q | View | Average login count (1 quarter) |
| DWH_dbo.SP_Fact_FirstCustomerAction | SP | First action per customer |
| DWH_dbo.Fact_FirstCustomerAction | Table | Derivative table: first action per customer per type |

---

## 6. Dependencies

### 6.1 ETL Pipeline

```
Production Sources:
  History.ActiveCredit + Archive Credit Tables (2007-2022Q1)
    → History.Credit (view, UNION ALL)
      → Generic Pipeline → DWH_staging.Ext_FCA_Real_History_Credit_ForFactAction
  
  Trade.PositionTbl → Trade.OpenPositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_Trade_OpenPositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Trade_Position
  
  History.Position_Active → History.ClosePositionEndOfDay (view)
    → Generic Pipeline → DWH_staging.etoro_History_ClosePositionEndOfDay
      → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_History_Position
  
  STS_Audit_UserOperationsData (Session Tracking Service)
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Audit_Loggin
  
  Billing.Login → DWH_staging.etoro_Billing_Login
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Cashier_Loggin
  
  Customer.CustomerStatic → DWH_staging.etoro_Customer_CustomerStatic
    → SP_Fact_CustomerAction_DL_To_Synapse → Ext_FCA_Real_Customer_Registration

All staging → SP_Fact_CustomerAction → Ext_FCA_Fact_CustomerAction
  → SP_Fact_CustomerAction_SWITCH → Fact_CustomerAction (SWITCH partition)
  → SP_Fact_CustomerAction_IsParitalCloseParent (post-load update)
```

### 6.2 ETL Stored Procedures

| SP | Role |
|----|------|
| SP_Fact_CustomerAction_DL_To_Synapse | Stage 1: Extract data from lake staging tables into Ext_FCA_* intermediate tables |
| SP_Fact_CustomerAction | Stage 2: Transform and load into Ext_FCA_Fact_CustomerAction (final staging) |
| SP_Fact_CustomerAction_SWITCH | Stage 3: SWITCH partition from staging into production table |
| SP_Fact_CustomerAction_CheckExistPartition | Ensure partition exists for the target date |
| SP_Fact_CustomerAction_Create_SWITCH_SINGLE | Create SWITCH_SINGLE staging table for partition swap |
| SP_Fact_CustomerAction_IsParitalCloseParent | Post-load: mark IsPartialCloseParent flags |

---

## 7. Column Lineage (Position-Derived Columns)

| Fact_CustomerAction Column | Source | Transformation | Also in Dim_Position? |
|---------------------------|--------|---------------|----------------------|
| InstrumentID | Trade.OpenPositionEndOfDay / History.ClosePositionEndOfDay | Direct pass-through | Yes |
| Amount | Trade.OpenPositionEndOfDay → TotalCashChange (for opens) | `ISNULL(TotalCashChange, 0)` | Yes (different source for Amount) |
| Leverage | Trade.OpenPositionEndOfDay | Direct | Yes |
| Commission | Trade.OpenPositionEndOfDay | Direct | Yes |
| CommissionOnClose | History.ClosePositionEndOfDay | Adjusted for reopen: `new - original` | Yes |
| FullCommission | Trade.OpenPositionEndOfDay | `ISNULL(FullCommission, 0.00)` | Yes |
| FullCommissionOnClose | History.ClosePositionEndOfDay | Adjusted for reopen | Yes |
| IsSettled | Trade.OpenPositionEndOfDay | With ETL fallback: `IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) → 1` | Yes |
| IsDiscounted | Trade.PositionTreeInfo | Direct | Yes |
| CommissionByUnits | Trade.Position (view) | Computed: `(AmountInUnitsDecimal / InitialUnits) * Commission` | Yes |
| FullCommissionByUnits | Trade.Position (view) | Computed: `(AmountInUnitsDecimal / InitialUnits) * FullCommission` | Yes |
| DLTOpen | Trade.OpenPositionEndOfDay | Direct (with ISNULL from close data) | Yes |
| DLTClose | History.ClosePositionEndOfDay | Direct | Yes |
| OpenMarkupByUnits | Trade.Position (view) | Computed: `OpenMarkup * AmountInUnitsDecimal / InitialUnits` | Yes |
| IsBuy | Trade positions | `ISNULL(close.IsBuy, open.IsBuy)` | Yes |

---

## 8. Atlassian Knowledge Sources

| Title | Type | Key Knowledge |
|-------|------|---------------|
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862) | Confluence | Describes Fact_CustomerAction as foundation layer: "Raw or near-raw data storage, capturing all the data" |
| [STS - Audit_Loggin](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12026741071) | Confluence | Login data flow: STS → DataLake → staging → FCA |
| [DLT Test Plan](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12400853103) | Confluence | DLTOpen/DLTClose/OpenMarkupByUnits addition testing |
| [Synapse Performance improvement](https://etoro-jira.atlassian.net/wiki/spaces/DBAC/pages/12457148417) | Confluence | FCA query optimization (IP merge) |
| [DWH Daily Process Failure (2025-04-17)](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/13120503818) | Confluence | Postmortem: FCA daily process failure |
| [DSM-1771](https://etoro-jira.atlassian.net/browse/DSM-1771) | Jira (To Do) | Add InstrumentID for ActionType 35 — to avoid joining Dim_Position |
| [DSM-1769](https://etoro-jira.atlassian.net/browse/DSM-1769) | Jira (To Do) | Add PositionID + RedeemID for ActionTypes 30, 8 |
| [DSM-1463](https://etoro-jira.atlassian.net/browse/DSM-1463) | Jira (Done) | Ticket Fees / IsFeeDividend logic (1=fee, 2=dividend, 3=SDRT, 4=tickets) |
| [DSM-1219](https://etoro-jira.atlassian.net/browse/DSM-1219) | Jira (Done) | SDRT change to FCA |
| [DSM-2392](https://etoro-jira.atlassian.net/browse/DSM-2392) | Jira (To Do) | WithdrawPaymentID to Fact Tables + PositionID for redeem |
| [BIZBI-705](https://etoro-jira.atlassian.net/browse/BIZBI-705) | Jira (Done) | Login report gold table: `ActionTypeID=14 is login` |
| [MUL-1007](https://etoro-jira.atlassian.net/browse/MUL-1007) | Jira | CRM import: LastLoginDate, LastCopyDate, LastCFDDate from FCA |

---

*Generated: 2026-03-03 | Object: DWH_dbo.Fact_CustomerAction | Type: Table (Fact) | Phases: 14/14*
*Sources: Synapse metadata + SP analysis + upstream Wiki (History.Credit, Dictionary.CreditType, Dictionary.MoveMoneyReason, Dictionary.SubCreditTypeID) + cross-reference Dim_Position.md + Atlassian (5 Confluence, 7 Jira)*
