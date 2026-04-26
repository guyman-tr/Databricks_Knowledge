# BI_DB_Compliance_VP_Monthly_MI

## 1. Purpose
Compliance VP (Vulnerable Persons) Monthly Management Information report. Generates all-time trading activity statistics for a specific curated list of FCA-regulated customers supplied by Compliance via a Google Sheets document (synced through Fivetran). One row per customer. Provides trading counts and net notional trade flow broken down by asset class (CFD, Real Stocks/ETF, Real Crypto), along with current customer status attributes. Used by Compliance management to monitor trading behavior of high-attention clients (currently 56 FCA customers in the list).

## 2. Grain & Size
| Property | Value |
|----------|-------|
| **Grain** | One row per customer (`CID`) |
| **Row Count** | 56 (as of 2026-04-13) — driven entirely by input CID list size |
| **Unique CIDs** | 56 (1:1) |
| **Regulation** | FCA only (all current list entries are FCA-regulated) |
| **Refresh** | Daily, full refresh (TRUNCATE + INSERT) via `SP_Compliance_VP_Monthly_MI` |
| **Last UpdateDate** | 2026-04-13 04:56:43 |

## 3. Key Business Rules
- **CID source**: Exclusively customers in `External_Fivetran_google_sheets_vp_monthly_mi` — a Google Sheets list managed by Compliance and synced via Fivetran. Currently 56 customers.
- **All-time scope**: No date filter — all historical trade actions are aggregated for each customer.
- **TradesExecuted = opens + closes**: Both open actions (ActionTypeID 1-3) and close actions (ActionTypeID 4-6) are counted. A complete round-trip trade counts 2.
- **Net notional calculation**: Open actions contribute **negative** notional; close actions contribute **positive** notional. `NotionalAmount_* = Σ close_notional − Σ open_notional`. Positive values indicate net closed flow exceeds net open flow.
- **Asset class classification** from Fact_CustomerAction:
  - CFD: `IsSettled = 0` (leveraged / CFD positions)
  - Real Stocks/ETF: `IsSettled = 1 AND InstrumentTypeID IN (5, 6)`
  - Real Crypto: `IsSettled = 1 AND InstrumentTypeID = 10`
- **Regulation source**: Uses primary `RegulationID` (not DesignatedRegulationID) via DWH_dbo.Dim_Regulation.

## 4. Customer Status Profile
| PlayerStatus | Count |
|-------------|-------|
| Normal | 43 |
| Blocked | 9 |
| Block Deposit & Trading | 2 |
| Blocked Upon Request | 2 |

All 56 customers: FCA-regulated, VerificationLevelID=3 (fully verified), IsDepositor=1, IsValidCustomer=1.

## 5. Column Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. One row per VP list customer. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer.RealCID) |
| 2 | IsDepositor | int | YES | 1 = customer has made at least one deposit; 0 = never deposited. All current VP list customers have IsDepositor=1. (Tier 1 — BackOffice.Customer via DWH_dbo.Dim_Customer.IsDepositor) |
| 3 | IsValidCustomer | int | YES | 1 = active customer; 0 = inactive/test account. All current VP list customers have IsValidCustomer=1. (Tier 1 — BackOffice.Customer via DWH_dbo.Dim_Customer.IsValidCustomer) |
| 4 | VerificationLevelID | int | YES | KYC verification level. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. All current VP list customers are Level 3. (Tier 1 — BackOffice.Customer via DWH_dbo.Dim_Customer.VerificationLevelID) |
| 5 | Regulation | nvarchar(250) | YES | Regulatory entity from primary RegulationID (via DWHRegulationID JOIN). All current customers are 'FCA'. (Tier 1 — DWH_dbo.Dim_Regulation.Name via DWH_dbo.Dim_Customer.RegulationID) |
| 6 | PlayerStatus | nvarchar(250) | YES | Customer account status. Observed values: "Normal" (43), "Blocked" (9), "Block Deposit & Trading" (2), "Blocked Upon Request" (2). (Tier 1 — BackOffice.Customer via DWH_dbo.Dim_PlayerStatus.Name) |
| 7 | TradesExecuted | int | YES | Total count of ALL trade actions ever (opens + closes). ActionTypeID 1-3 (opens) + ActionTypeID 4-6 (closes). A complete round-trip trade = 2 towards this count. All-time historical, no date filter. Range in current data: 4 to 35,111. (Tier 2 — SP_Compliance_VP_Monthly_MI, DWH_dbo.Fact_CustomerAction, ActionTypeID 1-6) |
| 8 | TradesExecuted_CFD | int | YES | Count of all CFD trade actions (opens + closes) where `IsSettled = 0`. All-time. (Tier 2 — SP_Compliance_VP_Monthly_MI, DWH_dbo.Fact_CustomerAction WHERE IsSettled=0) |
| 9 | NotionalAmount_CFD | money | YES | Net notional amount for CFD trades: `Σ(close Amount × Leverage) − Σ(open Amount × Leverage)` for `IsSettled=0` actions. Positive = net closed volume exceeds net open volume. All-time historical. (Tier 2 — SP_Compliance_VP_Monthly_MI, DWH_dbo.Fact_CustomerAction WHERE IsSettled=0) |
| 10 | TradesExecuted_RealStocksETF | int | YES | Count of all Real Stocks/ETF trade actions (opens + closes) where `IsSettled = 1 AND InstrumentTypeID IN (5, 6)`. All-time. (Tier 2 — SP_Compliance_VP_Monthly_MI, DWH_dbo.Fact_CustomerAction JOIN Dim_Instrument WHERE IsSettled=1, TypeID 5/6) |
| 11 | NotionalAmount_RealStocksETF | money | YES | Net notional amount for Real Stocks/ETF trades: `Σ(close Amount × Leverage) − Σ(open Amount × Leverage)` for `IsSettled=1 AND InstrumentTypeID IN (5, 6)`. Leverage is typically 1 for real stocks. All-time historical. (Tier 2 — SP_Compliance_VP_Monthly_MI, DWH_dbo.Fact_CustomerAction JOIN Dim_Instrument WHERE IsSettled=1, TypeID 5/6) |
| 12 | TradesExecuted_RealCrypto | int | YES | Count of all Real Crypto trade actions (opens + closes) where `IsSettled = 1 AND InstrumentTypeID = 10`. All-time. (Tier 2 — SP_Compliance_VP_Monthly_MI, DWH_dbo.Fact_CustomerAction JOIN Dim_Instrument WHERE IsSettled=1, TypeID 10) |
| 13 | NotionalAmount_RealCrypto | money | YES | Net notional amount for Real Crypto trades: `Σ(close Amount × Leverage) − Σ(open Amount × Leverage)` for `IsSettled=1 AND InstrumentTypeID=10`. All-time historical. (Tier 2 — SP_Compliance_VP_Monthly_MI, DWH_dbo.Fact_CustomerAction JOIN Dim_Instrument WHERE IsSettled=1, TypeID 10) |
| 14 | UpdateDate | datetime | NO | ETL metadata: SP execution timestamp. NOT NULL. Set by `GETDATE()` at insert time. Single value per run (all rows share same timestamp). (Tier 3 — ETL metadata, SP_Compliance_VP_Monthly_MI) |

## 6. ETL Summary

```
External_Fivetran_google_sheets_vp_monthly_mi (VP customer list)
    + DWH_dbo.Dim_Customer, Dim_PlayerStatus, Dim_Regulation (customer attributes)
    + DWH_dbo.Fact_CustomerAction (ALL historical, ActionTypeID 1-6)
    + DWH_dbo.Dim_Instrument (asset class classification)
        ↓  UNION ALL opens (negative notional) + closes (positive notional)
        ↓  GROUP BY CID, SUM net notional per asset class
        ↓  TRUNCATE + INSERT (full daily refresh)
BI_DB_Compliance_VP_Monthly_MI
```

- **OpsDB**: Priority 0, `SP_Compliance_VP_Monthly_MI`, daily

## 7. Usage Notes
- **All-time figures**: TradesExecuted and all NotionalAmount columns cover the customer's entire trading history, not just the current month. The "Monthly" in the table name refers to when the report is typically presented to management, not a monthly data filter.
- **TradesExecuted double-counts**: Each round-trip trade is counted twice (open + close). To get approximate trade count as a Compliance analyst would, divide by 2 or note that "TradesExecuted" = total trade actions, not unique positions.
- **Net notional interpretation**: `NotionalAmount_* > 0` means cumulative close flow > cumulative open flow for that asset class. Given all-time scope with no date filter, this is an accumulation measure, not an instantaneous exposure snapshot.
- **"VP" meaning**: VP likely stands for "Vulnerable Persons" — a UK FCA regulatory category requiring enhanced monitoring. The list is Compliance-controlled via Google Sheets, not auto-generated.
- **Table size changes daily**: The 56-row count is entirely determined by the Fivetran CID list. Adding or removing customers from the Google Sheets list directly changes the output on the next run.
- **UpdateDate is NOT NULL datetime**: Unlike most BI_DB tables where UpdateDate is varchar(50) NULL, this column is `datetime NOT NULL` — fully typed and never null.

## 8. Tier Breakdown
| Tier | Column Count | Source |
|------|-------------|--------|
| Tier 1 | 6 | Dim_Customer (CID, IsDepositor, IsValidCustomer, VerificationLevelID), Dim_Regulation (Regulation), Dim_PlayerStatus (PlayerStatus) |
| Tier 2 | 7 | Fact_CustomerAction + Dim_Instrument (TradesExecuted, 3×TradesExecuted_* counts, 3×NotionalAmount_* net notionals) via SP aggregation; Fivetran external (CID filter) |
| Tier 3 | 1 | UpdateDate (ETL metadata) |
