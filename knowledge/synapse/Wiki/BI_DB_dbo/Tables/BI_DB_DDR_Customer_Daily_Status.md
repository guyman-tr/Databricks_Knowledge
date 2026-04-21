# BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status

> 13.3B-row DDR customer daily status dimension — full daily snapshot of every customer's deposit status, account segmentation, FTD dates across all platforms (TP, IBAN, Options, MoneyFarm), regulation, login activity, and funded/active trading flags, providing the segmentation backbone for the entire DDR framework.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Dimension — DDR daily customer status snapshot) |
| **Production Source** | Derived from 15+ sources via `SP_DDR_Customer_Daily_Status` — `BI_DB_Client_Balance_CID_Level_New`, `Dim_Customer`, `Fact_SnapshotCustomer`, `Fact_CustomerAction`, `eMoney_Fact_Transaction_Status`, `MIMO_AllPlatforms`, plus 5 population functions |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + `INSERT` per business date |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_DDR_Customer_Daily_Status` is the **central customer segmentation table** for the DDR framework. It maintains a **full daily snapshot** (not SCD) of every customer who has ever appeared in the eToro ecosystem — one row per CID per calendar day.

The population is built from five mutually exclusive sources:
1. **TP (Trading Platform)** — customers with balance records in `BI_DB_Client_Balance_CID_Level_New`
2. **IBAN (eMoney)** — IBAN-only customers from `eMoney_Fact_Transaction_Status` not in TP
3. **Options** — Options-platform customers from `Dim_Customer` (FTDPlatformID=2) not in TP/IBAN
4. **Options MIMO** — Options customers found only in MIMO transaction data
5. **MoneyFarm** — MoneyFarm customers (FTDPlatformID=4) not in any of the above

Each customer is then enriched with:
- **Platform-specific FTD dates and amounts** (TP, IBAN, Options, MoneyFarm)
- **Global FTD** — earliest deposit across all platforms
- **Daily MIMO flags** — deposited today, first deposit today, redeposited, cashed out, per platform
- **Account segmentation** — active trader, balance-only, portfolio-only, inactive
- **Snapshot attributes** — regulation, player status, country, MiFID categorization
- **Login activity** — logged in today, split by depositor type
- **Funded status** — IsFunded, FirstTimeFunded, FirstFundedDateID, FirstIOBDateID

The table was created in July 2024 by Guy Manova. Significant changelog includes IBAN C2F fix (Aug 2025), Options FTDs (Oct 2025), global FTD coercion logic (Nov 2025), MoneyFarm support (Nov 2025), and deduplication fix (Dec 2025).

**ETL**: `SP_DDR_Customer_Daily_Status` runs daily (Priority 99, SB_Daily). Data spans from 2007-10-01 to present with ~13.3B rows across ~6.8M distinct CIDs.

---

## 2. Business Logic

### 2.1 Population Building (5-Layer Waterfall)

**What**: Builds the complete customer universe from five mutually exclusive sources.

**Rules**:
- TP population first (from `BI_DB_Client_Balance_CID_Level_New` for the date)
- IBAN-only users added second (settled deposits, TxTypeID 7/14, not in TP)
- Options users third (FTDPlatformID=2, not in TP/IBAN)
- Options MIMO users fourth (from MIMO Options table, not in any above)
- MoneyFarm users last (FTDPlatformID=4, not in any above)

### 2.2 Platform-Specific FTD Assignment

**What**: Assigns first-time-deposit date, date ID, and amount per platform.

**Columns Involved**: `TP_FTD_DateID/Date/FTDA`, `IBAN_FTD_DateID/Date/FTDA`, `Options_FTD_DateID/Date/FTDA`, `MoneyFarm_FTD_DateID/Date/FTDA`, `Global_FTD_DateID/Date/FTDA`

**Rules**:
- Each platform FTD comes from `Dim_Customer` filtered by `FTDPlatformID` (1=TP, 2=Options, 3=IBAN, 4=MoneyFarm)
- `Global_FTD` = earliest FTD across all platforms (MIN date)
- `IsDepositorGlobal` = 1 when `FirstDepositDate > '1900-01-01'`

### 2.3 Daily MIMO Flags (Coercion Logic)

**What**: Derives daily deposit/withdraw flags from `BI_DB_DDR_Fact_MIMO_AllPlatforms` with timing coercion.

**Columns Involved**: `GlobalDeposited`, `GlobalFirstDeposited`, `GlobalRedeposited`, `GlobalCashedOut`, `Redeemed`, `DepositedTP/IBAN/Options`, `ReDepositedTP/IBAN/Options`, `TPFirstDeposited`, `IBANFirstDeposited`, `OptionsFirstDeposited`, `TPExternalFirstDeposited`

**Rules**:
- FTD coercion: `Dim_Customer.FirstDepositDate` may differ from MIMO transaction date (recovery dates). The SP coerces the MIMO date to match Dim_Customer for consistency.
- `GlobalDeposited` = deposited today on any platform (excluding internal transfers)
- `GlobalFirstDeposited` = first deposit ever on any platform today
- `GlobalRedeposited` = deposited today but not FTD and not internal
- `TPExternalFirstDeposited` = TP FTD excluding internal transfers (FundingTypeID ≠ 33)

### 2.4 Account Segmentation

**What**: Classifies each customer into one of three mutually exclusive DDR engagement tiers using three TVFs. Top tier wins — evaluation is in priority order.

**Columns Involved**: `ActiveTraded`, `BalanceOnlyAccount`, `Portfolio_Only`, `AccountActive`, `AccountInActive`

**Tier hierarchy (mutually exclusive, priority top-to-bottom)**:
1. **Active Traders** (`ActiveTraded = 1`): Customer explicitly opened a new position (ActionTypeID 1 or 39), opened or added capital to a copy mirror (ActionTypeID 15=OpenMirror, 17=AddMirror), or placed an Options trade on this date. Auto-created copy positions — positions auto-generated when a copied trader opens a position — do NOT qualify; only deliberate mirror opens/additions count. Sourced from `Function_Population_Active_Traders`.
2. **Portfolio Only** (`Portfolio_Only = 1`): Customer holds at least one open TP position or Options position (via Apex buy-power data) but placed no qualifying trading actions in the period. The HODL segment — investors who traded historically and still hold. Includes copy positions (MirrorID>0) and CopyFund/Smart Portfolio (MirrorTypeID=4) positions. Explicitly excludes anyone in Active Traders. Sourced from `Function_Population_Portfolio_Only`.
3. **Balance Only** (`BalanceOnlyAccount > 0`): Customer has positive equity on at least one platform (TP, eMoney/IBAN, or Options) but holds no open positions and placed no trading actions in the period. The lowest engagement tier — cash at eToro, no portfolio. Returns the customer's maximum total equity (numeric, not 0/1). Excludes both Active Traders and Portfolio Only customers. Sourced from `Function_Population_Balance_Only_Accounts`.

- `AccountActive` = `CASE WHEN ActiveTraded = 1 OR Portfolio_Only = 1 THEN 1 ELSE 0 END`
- `AccountInActive` = customer is in none of the three active tiers

### 2.5 Login Activity

**What**: Classifies logins by depositor type.

**Columns Involved**: `LoggedIn`, `LoggedInTPDepositor`, `LoggedInIBANDepositor`, `LoggedInGlobalDepositor`

**Rules**:
- `LoggedIn` = 1 if customer has ActionTypeID 14 on the date
- `LoggedInTPDepositor` = logged in AND has TP FTD
- `LoggedInIBANDepositor` = logged in AND has IBAN FTD
- `LoggedInGlobalDepositor` = logged in AND has any FTD (global depositor)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) with CLUSTERED COLUMNSTORE. **Always filter on DateID** — this is a 13.3B row table. For single-customer queries, filter on both DateID and RealCID.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Active traders for a date | `WHERE ActiveTraded = 1 AND DateID = @dateID` |
| Global FTDs today | `WHERE GlobalFirstDeposited = 1 AND DateID = @dateID` |
| Customer status breakdown | `GROUP BY ActiveTraded, BalanceOnlyAccount, Portfolio_Only, AccountInActive WHERE DateID = @dateID` |
| Depositor logins by region | `WHERE LoggedInGlobalDepositor = 1 GROUP BY MarketingRegion` |
| TP vs IBAN FTD trend | `SUM(TPFirstDeposited), SUM(IBANFirstDeposited) GROUP BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DDR_Fact_AUM | RealCID + DateID | AUM per customer for the date |
| BI_DB_dbo.BI_DB_DDR_Fact_PnL | RealCID + DateID | Revenue per customer |
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | RealCID + DateID | MIMO transaction details |
| DWH_dbo.Dim_Customer | RealCID | Extended customer attributes |
| DWH_dbo.Dim_Regulation | RegulationID | Regulation name |
| DWH_dbo.Dim_Country | CountryID | Country details |

### 3.4 Gotchas

- **One row per CID per day** — full snapshot, not SCD. Every customer appears for every date they were in the system.
- **13.3B rows** — second largest table in BI_DB. Filter on DateID first.
- **FTD coercion**: `Dim_Customer` FTD dates can differ from MIMO transaction dates due to recovery logic. The SP coerces dates to match Dim_Customer, which is the authoritative source.
- **Mutually exclusive segments**: A customer is in exactly one of ActiveTraded, BalanceOnlyAccount, Portfolio_Only, or Inactive. `AccountActive = ActiveTraded OR Portfolio_Only`.
- **FirstFundedDateID/FirstActionDateID sentinel**: Value `30000101` means no event (future sentinel date).
- **FirstActionType = 'NoAction'**: Customer has not taken any trading action yet.
- **MarketingRegion**: From `Dim_Country.MarketingRegionManualName`, not from Dim_Customer directly.
- **Options FTD coercion UPDATE**: Post-insert UPDATE sets OptionsFirstDeposited=1 when Options_FTD_DateID = @dateID but MIMO data didn't arrive.
- **Deduplication**: ROW_NUMBER at the end ensures one row per CID even if production bugs create duplicate source rows.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Customer_Daily_Status) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date — equals parameter `@date`. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 2 | DateID | int | YES | Business date as YYYYMMDD integer. Delete/replace key. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 3 | RealCID | int | YES | Real customer ID. Population from 5-layer waterfall (TP → IBAN → Options → OptionsMIMO → MoneyFarm). HASH distribution key. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 4 | TP_FTD_DateID | int | YES | Trading Platform first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=1. NULL if no TP FTD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 5 | TP_FTD_Date | datetime | YES | Trading Platform first-time deposit datetime. From Dim_Customer.FirstDepositDate where FTDPlatformID=1. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 6 | TP_FTDA | decimal(16,6) | YES | Trading Platform first-time deposit amount in USD. From Dim_Customer.FirstDepositAmount where FTDPlatformID=1. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 7 | IBAN_FTD_DateID | int | YES | IBAN (eMoney) first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=3. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 8 | IBAN_FTD_Date | datetime | YES | IBAN first-time deposit datetime. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 9 | IBAN_FTDA | decimal(16,6) | YES | IBAN first-time deposit amount in USD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 10 | TP_External_FTDA | decimal(16,6) | YES | TP external FTD amount — excludes internal transfers (FundingTypeID ≠ 33). From MIMO aggregation. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 11 | Global_FTD_DateID | int | YES | Global first-time deposit date (YYYYMMDD) — earliest across all platforms. MIN(TP, IBAN, Options, MoneyFarm). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 12 | Global_FTD_Date | datetime | YES | Global first-time deposit datetime — earliest across all platforms. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 13 | Global_FTDA | decimal(16,6) | YES | Global first-time deposit amount in USD — amount of the earliest deposit. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 14 | IsDepositorGlobal | int | YES | Global depositor flag. 1 when Dim_Customer.FirstDepositDate > '1900-01-01'. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 15 | GlobalDeposited | int | YES | Deposited today on any platform (excluding internal transfers). ISNULL(0). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 16 | GlobalFirstDeposited | int | YES | First deposit ever on any platform today. From MIMO IsGlobalFTD flag. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 17 | GlobalRedeposited | int | YES | Redeposited today (not FTD, not internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 18 | GlobalCashedOut | int | YES | Withdrew today on any platform (excluding internal transfers). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 19 | Redeemed | int | YES | Billing redeem withdrawal today. From MIMO IsRedeem flag. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 20 | DepositedTP | int | YES | Deposited today on Trading Platform (excl internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 21 | DepositedIBAN | int | YES | Deposited today on IBAN/eMoney (excl internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 22 | ReDepositedTP | int | YES | Redeposited today on TP (not platform FTD, not internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 23 | ReDepositedIBAN | int | YES | Redeposited today on IBAN (not platform FTD, not internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 24 | TPFirstDeposited | int | YES | First deposit on Trading Platform today. From MIMO IsPlatformFTD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 25 | IBANFirstDeposited | int | YES | First deposit on IBAN/eMoney today. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 26 | TPExternalFirstDeposited | int | YES | First external TP deposit today (excl FundingTypeID=33 internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 27 | ActiveTraded | int | YES | **DDR top engagement tier.** 1 if the customer explicitly opened a new position (ActionTypeID 1 or 39), opened/added capital to a copy mirror (ActionTypeID 15=OpenMirror, 17=AddMirror), or placed an Options trade on this date. Auto-created copy positions (generated when a copied trader opens) do NOT qualify — only deliberate mirror opens/additions count. Includes Options trading via Function_Revenue_OptionsPlatform. Source: Function_Population_Active_Traders. (Tier 1 — Function_Population_Active_Traders) |
| 28 | BalanceOnlyAccount | decimal(16,6) | YES | **DDR lowest engagement tier — cash at eToro, no portfolio (numeric equity, not 0/1).** Customer has positive equity on any platform (TP NWA+Liability, eMoney ClosingBalanceBO×FXRate, Options TotalEquity from Apex buy-power) but holds no open positions and placed no qualifying trading actions in the period. Returns the customer’s maximum combined equity across all platforms. Excludes Active Traders and Portfolio Only (higher tiers win). Source: Function_Population_Balance_Only_Accounts. (Tier 1 — Function_Population_Balance_Only_Accounts) |
| 29 | Portfolio_Only | int | YES | **DDR middle engagement tier — the HODL segment.** 1 if the customer holds at least one open TP position or Options position (Apex buy-power) but placed no qualifying trading actions in the period. Includes copy positions (MirrorID>0) and CopyFund/Smart Portfolio (MirrorTypeID=4). Excludes Active Traders (higher priority wins). Source: Function_Population_Portfolio_Only. (Tier 1 — Function_Population_Portfolio_Only) |
| 30 | AccountActive | int | YES | Account is active. CASE WHEN ActiveTraded=1 OR Portfolio_Only=1 THEN 1 ELSE 0. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 31 | AccountInActive | int | YES | Account is completely inactive (not in any of the 3 active segments). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 32 | RegulationID | int | YES | Regulation ID from Fact_SnapshotCustomer for the date range. FK → DWH_dbo.Dim_Regulation. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 33 | DesignatedRegulationID | int | YES | Designated regulation ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 34 | PlayerStatusID | int | YES | Player status ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 35 | IsCreditReportValidCB | int | YES | Credit report valid flag from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 36 | IsValidCustomer | int | YES | Valid customer flag from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 37 | AccountTypeID | int | YES | Account type ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 38 | CountryID | decimal(16,6) | YES | Country ID from Fact_SnapshotCustomer. FK → DWH_dbo.Dim_Country. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 39 | MarketingRegion | varchar(100) | YES | Marketing region name. From Dim_Country.MarketingRegionManualName joined via CountryID. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 40 | MifidCategorizationID | decimal(16,6) | YES | MiFID categorization ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 41 | PlayerLevelID | int | YES | Player level ID from Fact_SnapshotCustomer. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 42 | IsDepositor | int | YES | TP depositor flag from Fact_SnapshotCustomer (SCD-based). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 43 | IsFunded | int | YES | **1 if the customer meets ALL four funded criteria on this date:** (1) real deposit per Dim_Customer.IsDepositor=1 (excludes 13K bad-FTD cohort:  FTDs on Aug 18-20 2025 with no subsequent real deposit); (2) KYC verified to level 3 (VerificationLevelID=3); (3) at least one non-airdrop activity completed — a TP trade (Dim_Position.IsAirDrop=0), IOB interest credit (Fact_CustomerAction ActionTypeID=36/CompensationReasonID=57), or Options trade; AND (4) positive equity on this date across TP, eMoney, or Options. All four conditions must hold simultaneously. Source: Function_Population_Funded. (Tier 1 — Function_Population_Funded) |
| 44 | FirstTimeFunded | int | YES | **1 on the exact date the customer first crossed the fully-funded threshold.** Computed as CASE WHEN FirstFundedDateID = @dateID THEN 1 ELSE 0. This date is always on or after the first deposit date — it only fires when KYC (level 3) and first qualifying activity (trade/IOB/options) are also complete simultaneously. A customer who deposited months ago but only recently verified will fire FirstTimeFunded on their verification date (if they had prior activity). Source: Function_Population_First_Time_Funded. (Tier 1 — Function_Population_First_Time_Funded) |
| 45 | FirstFundedDateID | int | YES | **Permanent graduation date (YYYYMMDD) — the LATEST of the three funded milestones.** Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Counterintuitively this is NOT the first deposit date — it is the last day on which all three conditions were simultaneously satisfied for the first time. Example: deposited Jan 1, verified Jan 5, first trade Jan 10 → FirstFundedDateID = 20260110. Sentinel 30000101 = not yet funded. Source: Function_Population_First_Time_Funded. (Tier 1 — Function_Population_First_Time_Funded) |
| 46 | FirstActionType | varchar(50) | YES | First trading action type (e.g., 'Crypto', 'Forex', 'Stocks'). From Function_Population_First_Trading_Action. 'NoAction' if none or future. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 47 | FirstActionDateID | int | YES | Date of first trading action (YYYYMMDD). Sentinel 30000101 = no action. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 48 | LoggedIn | int | YES | Logged in today. 1 when ActionTypeID=14 in Fact_CustomerAction. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 49 | LoggedInTPDepositor | int | YES | Logged in today AND is a TP depositor. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 50 | LoggedInIBANDepositor | int | YES | Logged in today AND is an IBAN depositor. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 51 | LoggedInGlobalDepositor | int | YES | Logged in today AND is a global depositor (any platform). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 52 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at insert time. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 53 | FirstIOBDateID | int | YES | **Date of first Interest on Balance (IOB) credit (YYYYMMDD).** IOB is an interest payment credited to customer accounts (Fact_CustomerAction, ActionTypeID=36, CompensationReasonID=57). Added Aug 2025 as an alternative qualifying activity for Funded status alongside trading a position or Options trade. A customer who never traded but receives IOB interest while meeting deposit+KYC criteria counts as Funded. NULL = no IOB credit ever received. Source: Function_Population_First_Time_Funded. (Tier 1 — Function_Population_First_Time_Funded) |
| 54 | FirstIOBTime | datetime | YES | **Exact timestamp of the customer’s first Interest on Balance credit.** Used alongside FTDDateID and FirstVerifiedDateID inside Function_Population_First_Time_Funded when computing FirstFundedDateID via GREATEST(). NULL if no IOB credit was ever received. (Tier 1 — Function_Population_First_Time_Funded) |
| 55 | Options_FTD_DateID | int | YES | Options platform first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=2. Added Oct 2025. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 56 | Options_FTD_Date | datetime | YES | Options platform first-time deposit datetime. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 57 | Options_FTDA | decimal(16,6) | YES | Options platform first-time deposit amount in USD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 58 | OptionsFirstDeposited | int | YES | First deposit on Options platform today. May be set by post-insert UPDATE when MIMO data missing. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 59 | DepositedOptions | int | YES | Deposited today on Options platform (excl internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 60 | ReDepositedOptions | int | YES | Redeposited today on Options (not platform FTD, not internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 61 | MoneyFarm_FTD_DateID | int | YES | MoneyFarm first-time deposit date (YYYYMMDD). From Dim_Customer where FTDPlatformID=4. Added Nov 2025. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 62 | MoneyFarm_FTD_Date | datetime | YES | MoneyFarm first-time deposit datetime. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 63 | MoneyFarm_FTDA | decimal(16,6) | YES | MoneyFarm first-time deposit amount in USD. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 64 | MoneyFarmFirstDeposited | int | YES | First deposit on MoneyFarm platform today. CASE WHEN MoneyFarm_FTD_DateID = @dateID THEN 1. (Tier 2 — SP_DDR_Customer_Daily_Status) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column Group | Production Source | Transform |
|---------------------|-------------------|-----------|
| Population (col 3) | BI_DB_Client_Balance_CID_Level_New + eMoney_Fact_Transaction_Status + Dim_Customer + MIMO_Options | 5-layer waterfall UNION |
| Platform FTDs (cols 4-13, 55-63) | Dim_Customer × Dim_FTDPlatform | CASE by FTDPlatformID |
| MIMO daily flags (cols 14-26, 58-60) | BI_DB_DDR_Fact_MIMO_AllPlatforms + coercion logic | MAX/CASE aggregation |
| Segments (cols 27-31) | Population functions (Active/BalanceOnly/Portfolio) | Function calls |
| Snapshot attrs (cols 32-42) | Fact_SnapshotCustomer + Dim_Range + Dim_Country | passthrough |
| Funded/Action (cols 43-47) | Population functions (Funded/FirstTimeFunded/FirstAction) | Function calls |
| Login (cols 48-51) | Fact_CustomerAction (ActionTypeID=14) | CASE + depositor join |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (TP population)
  + eMoney_dbo.eMoney_Fact_Transaction_Status (IBAN-only)
  + DWH_dbo.Dim_Customer (Options, MoneyFarm)
  + BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform (Options MIMO)
  → #population (5-layer waterfall)
     |
     + Fact_SnapshotCustomer + Dim_Range → #fsc
     + Function_Population_Funded → #funded
     + Function_Population_First_Time_Funded → #firstTimeFunded
     + Function_Population_First_Trading_Action → #FirstActions
     + Function_Population_Balance_Only_Accounts → #balanceOnly
     + Function_Population_Portfolio_Only → #portfolioOnly
     + Function_Population_Active_Traders → #activeTraders
     + Dim_Customer → #globalFTDs → platform-specific FTD temps
     + MIMO_AllPlatforms → #mimoUsersPrep → coercion → #mimoUsers
     + Fact_CustomerAction → #loggedIn → #depositorsLoggedIn
     |
     → #enrichStatusActions (merge all + dedup RN=1)
        |
        → SP_DDR_Customer_Daily_Status(@date) [Priority 99, SB_Daily]
             |-- DELETE WHERE DateID = @dateID
             |-- UPDATE Options FTD coercion
             |-- INSERT from #enrichStatusActions WHERE RN=1
             v
        BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status (13.3B rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| DateID | DWH_dbo.Dim_Date | Calendar dimension |
| RegulationID | DWH_dbo.Dim_Regulation | Regulation lookup |
| CountryID | DWH_dbo.Dim_Country | Country lookup |
| AccountTypeID | DWH_dbo.Dim_AccountType | Account type lookup |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Player status lookup |
| MifidCategorizationID | DWH_dbo.Dim_MifidCategorization | MiFID categorization |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status | — | Periodic aggregation reads daily status |
| BI_DB_dbo.BI_DB_V_DDR_* | — | All DDR views reference this for customer segmentation |
| BI_DB_dbo.SP_DDR_* | — | DDR SPs use this as the customer dimension |

---

## 7. Sample Queries

### 7.1 Active traders by regulation for a date

```sql
SELECT d.RegulationName, COUNT(*) AS ActiveTraders
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status s
JOIN DWH_dbo.Dim_Regulation d ON s.RegulationID = d.RegulationID
WHERE s.DateID = 20260309 AND s.ActiveTraded = 1
GROUP BY d.RegulationName
ORDER BY ActiveTraders DESC
```

### 7.2 Global FTDs by marketing region this month

```sql
SELECT MarketingRegion,
       SUM(GlobalFirstDeposited) AS FTD_Count,
       SUM(Global_FTDA) AS FTD_Volume
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
WHERE DateID BETWEEN 20260301 AND 20260309
  AND GlobalFirstDeposited = 1
GROUP BY MarketingRegion
ORDER BY FTD_Count DESC
```

### 7.3 Account segmentation breakdown

```sql
SELECT DateID,
       SUM(ActiveTraded) AS Active,
       SUM(CASE WHEN BalanceOnlyAccount > 0 THEN 1 ELSE 0 END) AS BalanceOnly,
       SUM(Portfolio_Only) AS PortfolioOnly,
       SUM(AccountInActive) AS Inactive
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
WHERE DateID = 20260309
GROUP BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 12/14*
*Tiers: 0 T1, 64 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | Type: Table | Production Source: SP_DDR_Customer_Daily_Status (15+ sources)*
