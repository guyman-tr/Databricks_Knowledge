# Column Lineage: DWH_dbo.Fact_CustomerAction

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_CustomerAction` |
| **Synapse row count (partition stats)** | ~11.44B rows (`sys.partitions` sum, 2026-05 session) |
| **UC Target (masked/Gold)** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` (Databricks `SHOW TABLES` 2026-05-14 — no `*_pii*` / `main.pii_data` sibling for this object) |
| **Generic Pipeline mapping** | `datalake_path`: `Gold/sql_dp_prod_we/DWH_dbo/Fact_CustomerAction/`, `copy_strategy`: Append, `frequency_minutes`: 1440 (`knowledge/synapse/Wiki/_generic_pipeline_mapping.json` generic_id 412) |
| **Production origins** | **Indirect composite** — `History.Credit` (financial events), `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `Billing.Login`, `STS_Audit.UserOperationsData` (logins), `Customer.CustomerStatic` (registration), plus enrichment joins documented in sibling dims |
| **ETL SP (writer)** | `DWH_dbo.SP_Fact_CustomerAction` (+ partition switch helpers `SP_Fact_CustomerAction_SWITCH`, `SP_Fact_CustomerAction_CheckExistPartition`, `SP_Fact_CustomerAction_Create_SWITCH_SINGLE`; extract `SP_Fact_CustomerAction_DL_To_Synapse`; post-load `SP_Fact_CustomerAction_IsParitalCloseParent`) |
| **Catalog gap** | `sys.sql_modules.definition` **NULL** for `SP_Fact_CustomerAction` / `SP_Fact_CustomerAction_DL_To_Synapse` on this Synapse pool — lineage below uses **SSD T / cross-wiki citations** plus **distribution evidence** (`DateID >= 20260101`) |
| **Generated** | 2026-05-14 |

## Source Objects

| Source Object | Role |
|---------------|------|
| `etoro.History.Credit` (lake → staging / external pipes) | Credit rows → `ActionTypeID` mapped from `CreditTypeID` (+ related attributes: `DepositID`, `WithdrawPaymentID`, `WithdrawID`, `MoveMoneyReasonID`, `FundingTypeID`, `CompensationReasonID`, `CreditID`, `Description`, bonuses, mirrors, deposits, fees, …) |
| `etoro.Trade.OpenPositionEndOfDay` (lake → staging) | Position **open** facts → `ActionTypeID` ∈ {1,2,3,39}; position economics + identifiers |
| `etoro.History.ClosePositionEndOfDay` (lake → staging) | Position **close** facts → `ActionTypeID` ∈ {4,5,6,28,40}; close-side economics; `RedeemID`/`RedeemStatus` passthrough lineage from `Trade.PositionTbl` semantics (via close snapshot) |
| `etoro.Billing.Login` (lake → staging) | Cashier / login adjunct rows (`ActionTypeID` 29) |
| STS audit / login pipelines (see existing Confluence STS pointer in wiki §8) | `ActionTypeID` 14 logins (`IPNumber`, session proxies, durations, etc.) |
| `Customer.CustomerStatic` | `ActionTypeID` 41 registration |
| `DWH_dbo.Dim_BackOfficeCustomer` / regulation history staging (joined in position path per existing column notes) | `RegulationIDOnOpen` |
| `Trade.Position*` / computed position views (per `Dim_Position` wiki): `Trade.PositionTbl`, `Trade.Position` view family | Derived unit/proration commissions, `SettlementTypeID`, reopen/partial-close fields, crypto airdrop flag, markup proration |

## Lineage Chain

```
Production OLTP ──► Azure Data Lake (Bronze/Gold layouts per Generic Pipeline)
        │
        ├── History.Credit (+ archives / ActiveCredit union in prod)
        ├── Trade.OpenPositionEndOfDay  +  History.ClosePositionEndOfDay
        ├── Billing.Login , Customer.CustomerStatic , STS login feeds
        │
        └── Synapse staging / EXTERNAL / CopyFromLake tables (writer SP_DL family)
                     │
                     ▼
        DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse  →  intermediate Ext_FCA_* payloads
                     │
                     ▼
        DWH_dbo.SP_Fact_CustomerAction  →  Ext_FCA_Fact_CustomerAction (final staging)
                     │
                     ▼
        SP_Fact_CUSTOMERACTION_SWITCH  →  DWH_dbo.Fact_CustomerAction  (HASH(RealCID), columnstore + NC indexes)
                     │
                     └── SP_Fact_CustomerAction_IsParitalCloseParent  (post-process)


Gold Generic Pipeline ──►  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction  (Delta; partition cols `etr_y`,`etr_ym`,`etr_ymd` added at UC layer vs Synapse DDL)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column carried from staging source without business-side CASE (may still coerce NULL→0/`ISNULL` in loader) |
| **ETL-computed** | `CASE`, calendar bucketing (`DateID`,`TimeID`), string pattern tests, `GETUTCDATE()` / load metadata |
| **SP-adjusted** | Multi-branch UNION targets; reopened-commission adjustments; dedupe keys |
| **join-enriched** | Added via JOIN to regulation / dictionaries / STS merge tables in writer |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|------------|--------------|---------------|-----------|---------------------|-------|
| HistoryID | History.Credit (and position branches per ActionType routing) | Source history / synthetic key columns | SP-adjusted | Multi-branch INSERT assigns `HistoryID` per source arm (dedupe / UNION). **Duplicates observed in production counts — not a surrogate key.** | Tier 5 semantics for usage |
| GCID | Customer.CustomerStatic (+ credit joins as applicable) | GCID | passthrough / join-enriched | Propagated where registration / credit payloads carry GCID linkage | Canonical text: Dim_Customer |
| RealCID | All major branches | RealCID | passthrough | `RealCID` from credit / position / login / registration feeds | HASH distribution column |
| DemoCID | Customer identity feeds | DemoCID | passthrough | Loaded for real-centric fact (`0` predominant) — see Phase 2 sample | Dim_Customer |
| Occurred | Branch-specific | Occurred timestamps | passthrough | Event timestamp from STS, Credit, Login, Open/Close snapshots | |
| IPNumber | STS / Login | Numeric IP representation | passthrough | Populated heavily for login / registration rows | Tier 1 — STS/Billing.Login per existing wiki |
| IsReal | ETL sentinel | Literal | ETL-computed | Real-account filter upstream; table stores real actions (`1`) | |
| ActionTypeID | CreditType / branch classifier | Mapped IDs | SP-adjusted | Maps production `CreditTypeID` (+ movement reasons, deposit internals) AND position enums into `Dictionary.ActionType` / DWH dimension keys | **`Dim_ActionType` join for labels** |
| PlatformTypeID | STS vs legacy | PlatformTypeIDs | passthrough | `99` common on STS-modern login slices (Phase 2 sample 202601+) | |
| InstrumentID | Open/Close snapshots | InstrumentID | passthrough | 0 on non-trade rows | Tier 1 — Trade.PositionTbl |
| Amount | Opens (cash change), closes (PnL context), credits | Currency amounts | SP-adjusted | Opens use `TotalCashChange` pathway (see wiki §historical lineage); Credits use ledger amounts | Tier 1 — Trade.PositionTbl / Credits |
| Leverage | Position snapshots | Leverage | passthrough | Tier 1 — Trade.PositionTbl |
| NetProfit | Position closes | NetProfit components | passthrough | Monetary type; 0 when non-close | Tier 1 — Trade.PositionTbl |
| Commission | Position snapshots | Commission | passthrough | Cents→dollars division on OPEN path historically (`/100` per Dim_Position lineage) | Tier 1 — Trade.PositionTbl |
| PositionID | Position snapshots | PositionID | passthrough | `Internal.GetPositionID_Bigint` domain | Tier 1 — Trade.PositionTbl |
| CampaignID | Credit/marketing payloads | CampaignID | passthrough | 0 sentinel common | Tier 5 |
| BonusTypeID | Credit bonus rows | BonusTypeID | passthrough | 0 sentinel off-bonus | Tier 5 |
| FundingTypeID | History.Credit / billing joins | FundingTypeID | join-enriched + `ISNULL` | **`ISNULL(FundingTypeID,0)`** per `Dim_FundingType.md` §2.2 | Join `Dim_FundingType` |
| LoginID | Billing.Login branch | LoginID | passthrough | 0 when not login | Tier 1 — Billing.Login |
| MirrorID | Position snapshots | MirrorID | passthrough | Tier 1 — Trade.PositionTbl |
| WithdrawID | Credits (cash-outs) | WithdrawID | passthrough | Tier 1 — History.Credit |
| DurationInSeconds | Billing.Login | Session duration | passthrough | NULL outside login cashier rows | Tier 1 — Billing.Login |
| PostID | Social legacy payloads | GUID | passthrough | NULL outside dead social IDs | Tier 1 — Social platform |
| CaseID | CRM credit rows | CaseID | passthrough | | Tier 1 — CRM |
| UpdateDate | Loader | clock | ETL-computed | `GETUTCDATE()` / Synapse canonical load watermark | Tier 2 — SP_Fact_CustomerAction |
| DateID | Occurred | date bucketing | ETL-computed | `CONVERT`/CAST to `YYYYMMDD` int | Tier 2 — SP_Fact_CustomerAction |
| TimeID | Occurred | hour | ETL-computed | `DATEPART(HOUR,Occurred)` | Tier 2 — SP_Fact_CustomerAction |
| StatusID | ETL sentinel | Status | passthrough | Predominantly `1`; NULL cohort ~ millions historical | Tier 3 |
| PreviousOccurred | Deprecated upstream | Legacy | passthrough | Sparse / deprecated per prior wiki verification | Tier 5 |
| CompensationReasonID | History.Credit / Backoffice | Compensation reason | passthrough | Used for comps + opens (airdrop linkage) per prior wiki | Tier 1 — History.Credit |
| WithdrawPaymentID | Credits | WithdrawProcessing/Payment surrogate | passthrough | Dedup semantics per prior wiki narrative | Tier 1 — History.Credit |
| CommissionOnClose | Close snapshot | CommissionOnClose | SP-adjusted | Reopen subtraction logic ties to Dim_Position lineage | Tier 1 — Trade.PositionTbl |
| IsPlug | Deprecated | — | passthrough | NULL / unused sentinel | Tier 5 |
| DepositID | Credits (deposits) | Deposit identifiers | passthrough | NULL outside deposits | Tier 1 — History.Credit |
| PostRootID | Social legacy | identifiers | passthrough | | Tier 1 — Social |
| FullCommission | Position open | FullCommission | passthrough | `$ /100` open path historically | Tier 1 — Trade.PositionTbl |
| FullCommissionOnClose | Close snapshot | FullCommissionOnClose | SP-adjusted | Reopen-adjusted symmetrical to `CommissionOnClose` | Tier 1 — Trade.PositionTbl |
| RedeemID | Close snapshot / Position | RedeemID | passthrough | **CFD Billing.Redeem reference** semantics | Tier 1 — Trade.PositionTbl (verbatim inheritance) |
| RedeemStatus | Close snapshot / Position | RedeemStatus | passthrough | **CFD redemption state** semantics | Tier 1 — Trade.PositionTbl (verbatim inheritance) |
| SessionID | STS / login integrations | STS session bigint | passthrough | | Tier 1 — STS |
| IsRedeem | **Dual semantics** — (A) **History.Credit cashout**, (B) **Position close snapshots** | `CreditTypeID` + `FundingTypeID` (+ close flags) | ETL-computed / SP-adjusted | **(A) Documented CASE (cross-wiki parity with `Dim_FundingType.md` §2.3): `CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END` for Crypto-wallet labeled cashouts.** Live sample `DateID>=20260101`: `ActionTypeID=8 AND IsRedeem=1 ⇒ FundingTypeID=27` universally in slice. **`ActionTypeID=30 AND IsRedeem=1`** rows align to **transfer-to-coin / TransferCoinFee** analytics per `BI_DB_dbo.Function_Revenue_TransferCoinFee`. **(B) Position closes (`ActionTypeID` ∈ {4,6,…})**: `IsRedeem=1` appears with CFD redeem identifiers (`RedeemID` populated; sample shows `RedeemStatus=0` still) — interpretation: **Billing.Redeem / position CFD redemption**, distinct from **transfercoin**. **Exact CLOSE-branch expression not extractable:** Synapse catalog returns NULL SP body (`sys.sql_modules`) — pull SSDT when available. | **Canary column** |
| RegulationIDOnOpen | Backoffice regulation history staging | Regulation ID lookup | join-enriched | Latest regulation join window (tie to `Dim_Position` explanation) | Tier 2 — SP_Dim_Position_DL_To_Synapse (same text as wiki) |
| PlatformID | Login / Registration | Product/Platform surrogate | passthrough | Only ActionType `{14,41}` cohorts | FK to Dim_Product.ProductID semantics |
| ReopenForPositionID | Position snapshot | linkage | passthrough | | Tier 1 — Trade.PositionTbl |
| IsReOpen | Position snapshot | Derived | ETL-computed | `CASE WHEN ReopenForPositionID IS NOT NULL THEN 1 ELSE 0 END` defaults | Tier 2 — SP_Dim_Position_DL_To_Synapse |
| CommissionOnCloseOrig | Position reopen logic | Stored original | ETL-computed | `CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0` | Tier 2 — SP_Dim_Position_DL_To_Synapse |
| FullCommissionOnCloseOrig | Position reopen logic | Stored original | ETL-computed | Default `0` / reopen rules | Tier 2 — SP_Dim_Position_DL_To_Synapse |
| OriginalPositionID | Partial close lineage | Identifier | passthrough | | Tier 2 — SP_Dim_Position_DL_To_Synapse |
| IsPartialCloseParent | Partial-close detection | Flags | SP-adjusted | Post-load UPDATE in `SP_Fact_CustomerAction_IsParitalCloseParent` per operations docs | Mixed Tier 2/5 per expert notes |
| IsPartialCloseChild | Partial-close detection | Flags | SP-adjusted | Child remainder positions | Tier 5 — domain expert, SP lineage |
| InitialUnits | Position snapshot | Units | passthrough | | Tier 1 — Trade.PositionTbl |
| PaymentStatusID | Credits | Payment statuses | passthrough | NULL outside money movement rows | Tier 5 |
| IsDiscounted | Position tree infos | Discounted flag | passthrough | CAST bit→int note per Dim_Position | Tier 1 — Trade.PositionTbl |
| IsSettled | Position snapshot (+ instrument typing heuristics historically) | Legacy settlement | SP-adjusted | Supplanted in meaning by `SettlementTypeID` but retained | Tier 5 — Expert Review |
| CommissionByUnits | Derived from units | Commission proration | ETL-computed | `(AmountInUnitsDecimal / InitialUnits) * Commission` style formula | Tier 1 — Trade.Position |
| FullCommissionByUnits | Derived | Full commission proration | ETL-computed | Mirrors CommissionByUnits for full fee | Tier 1 — Trade.Position |
| IsFTD | Credit + customer dimension | FTD detection | SP-adjusted | Customer first-deposit overlays / credit classification | Tier 2 — Fact_CustomerAction ETL composition |
| CountryIDByIP | Geo lookups | Resolved CountryID | join-enriched | | Tier 5 |
| IsAnonymousIP | STS | Fraud/geo flags | passthrough | | Tier 1 |
| ProxyType | STS proxy classifier | Codes | passthrough | DCH/VPN/TOR enums | Tier 1 — STS |
| IsFeeDividend | Credit descriptions | Parsed fee subtype | ETL-computed | Pattern match on Description for Fee ActionType (=35); DSM-1463 | Tier 2 — SP_Fact_CustomerAction |
| IsAirDrop | Airdrop staging join | Exists flag | join-enriched | `etoro_Trade_PositionAirdropLog` linkage per Dim lineage | Tier 2 — SP_Dim_Position_DL_To_Synapse |
| DividendID | Fee / dividend credit | Dividend identifier | passthrough | | Tier 1 — Trade positions |
| MoveMoneyReasonID | Credits | Reasons | passthrough | `Dictionary.MoveMoneyReason` | Tier 1 — History.Credit |
| SettlementTypeID | Position snapshot | Modern settlement dictionary | passthrough | `Dictionary.SettlementTypes` | Tier 1 — Trade.PositionTbl |
| DLTOpen | Open snapshot | Distributed ledger flag | passthrough | Feature added 2024-06 | Tier 2 — SP_Dim_Position_DL_To_Synapse |
| DLTClose | Close snapshot | Distributed ledger flag | passthrough | | Tier 2 — SP_Dim_Position_DL_To_Synapse |
| OpenMarkupByUnits | Markup math | markup proration | ETL-computed | `OpenMarkup * AmountInUnitsDecimal / InitialUnits` | Tier 1 — Trade.Position |
| IsBuy | Open/Close merges | Direction | passthrough | `ISNULL(close.IsBuy, open.IsBuy)` pattern historically | Tier 1 — Trade.PositionTbl |
| Description | Credits | Narrative text | passthrough | Fee narratives, deposit processors, SL edits etc. | Tier 1 — History.Credit |
| CreditID | History.Credit | CreditID | passthrough | Strengthens audit/back join | Tier 1 — History.Credit |

## Summary

| Category | Count |
|----------|-------|
| **Columns mapped** | 71 |
| **Known SP catalog blind spot** | `SP_Fact_CustomerAction` / `_DL_To_Synapse` bodies unavailable via `sys.sql_modules` on this warehouse |
| **High-risk dual-meaning** | `IsRedeem` (transfer-to-coin vs CFD redeem) |
