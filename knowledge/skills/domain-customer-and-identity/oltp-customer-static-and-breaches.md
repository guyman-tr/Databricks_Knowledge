---
id: oltp-customer-static-and-breaches
name: "OLTP Customer Static & Breach Investigations"
description: "Production-OLTP customer truth (Customer.CustomerStatic — bronzed to main.general.bronze_etoro_customer_customerstatic_masked, 83 columns, RealCID PK), BackOffice operational mirror (verification, document, risk, all-time-aggregated), EXW_DimUser (crypto-wallet user master, joined via GCID), and the Breaches Investigation Bot cluster (BI_DB_Compliance_Illegal_Trades_Alerts, BI_DB_Scored_Appropriateness_Negative_Market — both in UC). Synapse-only tables in this cluster that have NOT migrated to UC: BI_DB_US_Compliance_Apex_Clients, BI_DB_OPS_MultipleAccounts, BI_DB_WatchListsByFunnel, BI_DB_AML_Documents_Request, EXW_DimUser_Enriched, Dictionary.Country, Dictionary.Regulation (verified 2026-05-11). Load this skill when you need column-level forensics on the raw OLTP source (LinkedAccountHash1 duplicate-detection, IsHedged trigger semantics, IsEmailActivated vs IsEmailVerified, the CitizenshipCountryID / POBCountryID / SubRegionID / RegionByIP_ID granular geography, PhonePrefix vs PhoneBody structured-phone, OptOutReasonID, PlayerStatusSubReasonID + free-text comment, EmailVerificationProviderID, DLT / Tangany / Apex external IDs, the PERSISTED LinkedAccountHash1 used for linked-account detection, ExternalID APEX decimal(38,0)) — or when you're investigating a customer for illegal trades, negative-market scored-appropriateness violations, multi-account chains, watchlists, or AML document-request lifecycle. The Breaches Investigation Bot Genie space joins these on RealCID."
triggers:
  - Customer.CustomerStatic
  - bronze_etoro_customer_customerstatic
  - OLTP customer
  - production OLTP truth
  - column-level forensics
  - BackOffice.Customer
  - backoffice_customer
  - BackOffice.CustomerDocument
  - BackOffice.CustomerRisk
  - BackOffice.CustomerAllTimeAggregatedData
  - EXW_DimUser
  - EXW_DimUser_Enriched
  - crypto wallet user
  - breach
  - illegal trade
  - illegal_trades_alerts
  - scored appropriateness
  - negative market
  - appropriateness test
  - multi-account
  - linked accounts
  - LinkedAccountHash1
  - duplicate detection
  - watchlist
  - WatchListsByFunnel
  - AML document request
  - Breaches Investigation Bot
  - Apex US-resident
  - US_Compliance_Apex_Clients
  - OPS_MultipleAccounts
  - IsHedged
  - IsEmailActivated
  - LinkedAccountHash1
  - CitizenshipCountryID
  - POBCountryID
  - SubRegionID
  - PhonePrefix
  - ExternalID APEX
required_tables:
  - main.general.bronze_etoro_customer_customerstatic_masked
  - main.pii_data.bronze_etoro_customer_customerstatic
  - main.general.bronze_etoro_backoffice_customer
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market
sample_questions:
  - "Show the OLTP CustomerStatic row for RealCID 12345"
  - "Which columns are in Customer.CustomerStatic that are not in Dim_Customer?"
  - "Is customer X hedged? Why is IsHedged=0?"
  - "Find customers with matching LinkedAccountHash1 (linked-account detection)"
  - "Show all illegal-trade alerts for customers in CySEC in 2025"
  - "Which customers failed the scored-appropriateness negative-market test?"
  - "Crypto-wallet user lookup for GCID"
domain_tags:
  - oltp
  - customer
  - breaches
  - compliance
  - aml
  - investigation
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# OLTP Customer Static & Breach Investigations

Production-OLTP truth about a customer plus the Breaches Investigation Bot working set. Two reasons to come here instead of `customer-master-record` (B.1) or `identity-jurisdiction-and-regulation` (B.2):

1. **Column-level forensics on a column that Dim_Customer doesn't carry.** `Dim_Customer` is a curated 107-col subset of `Customer.CustomerStatic` (83 cols in the masked UC bronze) plus 14 source-microservice joins. Some columns live ONLY in the OLTP bronze: `IsHedged` (trigger-driven brokerage hedge flag), `LinkedAccountHash1` (MD5 fingerprint used for duplicate detection), `IsEmailActivated` (separate from `IsEmailVerified`), `PhonePrefix` / `PhoneBody` (structured phone), `SubRegionID` (province/state granularity), `EmailVerificationProviderID`, `OptOutReasonID`, `PlayerStatusSubReasonComment` (free-text), `LeverageType`, `LotCountGroupID`, `SpreadGroupID`, `HelpDeskType`, `ClientVersion`, `PersonID`, `RegionByIP_ID`, `OriginalProviderID`, `RealProviderID`.
2. **You're investigating a breach / regulatory alert.** The Breaches Investigation Bot Genie joins `Customer.CustomerStatic` + the BI_DB compliance tables to produce a customer-plus-alerts investigation row.

**Side classification:** broker-side production-OLTP source-of-truth and compliance-investigations working set.

## When to Use

Load when the question is about the raw OLTP customer or a compliance/AML breach investigation:

- "Show the CustomerStatic row for RealCID X" (full 83-col OLTP forensic dump)
- "Why is `IsHedged = 0` for this customer?" (trigger semantics: `LabelID = 26`, `PlayerLevelID = 4`, `CEP.ListCIDMappings(NamedListID=3)`, or `BackOffice.BonusOnlyCustomers`)
- "Find customers with matching `LinkedAccountHash1`" (linked-account / duplicate-detection forensics)
- "OLTP truth for verification title / status sub-reason / opt-out reason / email-verification provider"
- "Illegal-trade alerts for customers in CySEC last year"
- "Scored-appropriateness negative-market failures"
- "Apex US-resident broker compliance flags" (Synapse-only — see Warning 4)
- "Multi-account / linked-account chains" (Synapse-only — see Warning 4)
- "AML document-request lifecycle" (Synapse-only — see Warning 4)
- "EXW crypto-wallet user lookup for GCID X"

Do NOT load for:

- Analyst-friendly customer master ("show me country / regulation / level") → `customer-master-record` (anchors on `Dim_Customer`, 107 cols, denormalized).
- Historical attribute walks → `identity-jurisdiction-and-regulation`.
- CRM cases / CSAT / churn → `crm-cases-csat-and-churn`.
- LTV / segments / cluster → `customer-models-and-segmentation`.
- Deep crypto-wallet questions (transactions, balances, on-chain) → Payments super-domain `crypto-wallet`.

## Scope

In scope: `Customer.CustomerStatic` masked + PII bronze (83 cols), `BackOffice.Customer` operational mirror, the `BackOffice.Customer*` document/risk/all-time-aggregated family, `EXW_DimUser` crypto-wallet user master (21 cols, joins on GCID + RealCID), `BI_DB_Compliance_Illegal_Trades_Alerts` (illegal-trade event log), `BI_DB_Scored_Appropriateness_Negative_Market` (KYC/AT scoring + block/release lifecycle), the OLTP-only column surface that Dim_Customer doesn't expose (Critical Warning 2), the Synapse-only tables in this cluster (Critical Warning 4).
Out of scope: analyst-friendly current state (`customer-master-record`); SCD walks (`identity-jurisdiction-and-regulation`); CRM (`crm-cases-csat-and-churn`); customer models (`customer-models-and-segmentation`); compliance snapshot + club tier (`compliance-customer-snapshot-and-club`); customer-action audit trail (`customer-action-audit-trail`); deep crypto wallet (`domain-payments/crypto-wallet`); deposits / withdrawals (`domain-payments/deposits-and-withdrawals`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `Customer.CustomerStatic` (masked UC bronze) has 83 columns, NOT ~250.** Verified 2026-05-11 against `information_schema.columns`. Earlier internal estimates of "~250 columns" conflated CustomerStatic with the sum of CustomerStatic + BackOffice.Customer + 12 ancillary BackOffice/Compliance/UserApiDB tables that all feed into `Dim_Customer`. For a sense of what's actually there see the column-group catalogue below.

2. **Tier 1 — Speculative column names from v1 do NOT exist on `Customer.CustomerStatic`.** None of `IsTestUser`, `IsExcludedFromReporting`, `IsFraud`, `IsV1Accepted`, `V1ApprovalDate`, `V2ApprovalDate`, `V3ApprovalDate`, `MasterCID`, `IsTermsAcceptedYYYY`, `IsPrivacyAcceptedYYYY`, `IsCommunicationOptIn`, `MarketingConsentDate`, `IsCookieConsentGiven`, `PreferredDepositMethod`, `LastDepositMethodID`, `DepositMethodWhitelist`, `SupportChannelOptIns`, `IsLiveChatEnabled`, `IsWhatsAppOptedIn`, `LastAppVersion`, `LastWebVersion`, `LastDeviceID`, `IsBetaCohort`, `FeatureFlags` exist on the masked UC bronze. Verified 2026-05-11. The actual `Is*` columns are exactly five: `IsReal`, `IsEmailVerified`, `IsEmailActivated`, `IsRequestedCall`, `IsHedged`. For test-account / excluded-customer filtering use `IsValidCustomer` (DWH-computed on Dim_Customer); for breach/alert investigation use the BI_DB Compliance tables in this skill.

3. **Tier 1 — `IsHedged` is trigger-driven, not analyst-set.** `Customer.CustomerStatic.IsHedged` defaults to `1` and is overwritten to `0` by `CustomerVersionInsert` / `CustomerVersionUpdate` triggers when ANY of: `LabelID = 26` (`Dim_Label.Name = 'ILQ'`), `PlayerLevelID = 4` (`Dim_PlayerLevel.Name = 'Internal'` — the in-house / eToro-employee account level, NOT a Popular Investor signal — verified 2026-05-13), `CID IN CEP.ListCIDMappings(NamedListID = 3)`, or `CID IN BackOffice.BonusOnlyCustomers`. Reading `IsHedged = 0` without knowing the trigger logic leads to wrong conclusions about brokerage exposure. The downstream hedge truth lives in `Trade.PositionTbl.IsHedged` (per-position, current state) and the dealing-side execution log — see Trading super-domain `broker-and-lp-reconciliation`.

4. **Tier 1 — Four "breach cluster" tables are Synapse-only and NOT in UC.** Verified 2026-05-11 (`information_schema.tables` returned zero rows for these patterns):
   - `BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients` — US-resident customers cleared by Apex; Apex-side compliance flags.
   - `BI_DB_dbo.BI_DB_OPS_MultipleAccounts` — detected linked-account chains (one human → many `RealCID`s).
   - `BI_DB_dbo.BI_DB_WatchListsByFunnel` — watch-list filter per funnel stage.
   - `BI_DB_dbo.BI_DB_AML_Documents_Request` — AML document-request lifecycle.
   - `EXW_dbo.EXW_DimUser_Enriched` — the enriched crypto-wallet user dim (the base `EXW_DimUser` IS in UC at `main.bi_db.gold_..._exw_dimuser`).
   Querying these requires the Synapse MCP server or `pyodbc`. Do not attempt UC SQL against them.

5. **Tier 2 — `RealCID` is a STRING on `bi_db_compliance_illegal_trades_alerts`, but INT everywhere else.** Verified 2026-05-11. The illegal-trade-alerts table also stores most analytical fields (`InvestedAmount`, `OpenDateID`, `IsSettled`, `Leverage`, `IsCopy`, `VerificationLevelID`, `RegisteredReal`, `AmountUSD`) as STRING. When joining back to `Dim_Customer` or `Fact_CustomerAction` you MUST `CAST` (`CAST(a.RealCID AS INT)` etc.) or rely on implicit coercion which has caused silent join misses historically.

6. **Tier 2 — `EXW_DimUser` flag column is `IsTestAccount`, NOT `IsTestUser`.** Verified 2026-05-11 against `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser` (21 cols). Other surprises: it has a `Club` STRING column (the crypto-wallet user's eToro Club tier — sourced separately from the trading-side); `UserRegionID` + `UserRegion_State` (Apex-specific US state code); `ComplianceClosureEvent` (closure flag); `IsValidCustomer` (locally-computed, may disagree with Dim_Customer if EXW provisioning lags). Join the wallet user to the DWH on `GCID` (canonical) or `RealCID` (both present); for unique-customer counts in EXW use `EXWCustomerID` (not directly visible — the table key is `(GCID, RealCID)` composite).

7. **Tier 2 — `BI_DB_Scored_Appropriateness_Negative_Market` is the per-CID Apex AT / KYC restriction lifecycle.** Carries `IsKYC_NM_Trading_Experience`, `IsKYC_NM_Risk_Factor`, `IsKYC_NM`, `AT_Total_Score_KYC`, `AT_Total_Max_Potential_Score`, `IsKYC_AT_Passed`, `RestrictionStatusDesc`, `CFD_Status`, `BlockDate`, `BlockReasonID`, `BlockReasonDesc`, `ReleaseDate`, `ReleaseReasonID`, `ReleaseReasonDesc`, `DateDiffBlockRelease`, `AT_Date`, `ApproprietnessScore_Status` (sic — note typo), `DesignatedRegulationName`, `BlockSubReasonID`, `BlockSubReasonDesc`. The typo `ApproprietnessScore_Status` (missing `i` in Appropriateness) is intentional in the production schema — quoting it correctly matters.

8. **Tier 3 — `Dictionary.Country` and `Dictionary.Regulation` are OLTP dictionaries that are Synapse-only.** For analytical use prefer `Dim_Country` / `Dim_Regulation` (UC: `main.dwh.gold_..._dim_country` / `..._dim_regulation`). The OLTP dictionaries can carry intermediate values from in-flight migrations that the curated `Dim_*` versions filter out.

9. **Tier 3 — `BackOffice.Customer` operational mirror lags production OLTP by minutes.** Do NOT use `BackOffice.Customer.PlayerStatusID` for the latest live status. Use `Customer.CustomerStatic.PlayerStatusID` (production OLTP, immediate) or `Dim_Customer.StatusID` (analyst-curated nightly). `BackOffice.Customer` is correct only for back-office operator workflows.

10. **Tier 3 — `Customer.CustomerStatic` is bronze (raw streaming mirror), NOT the gold authoritative table.** The bronze can carry intermediate states during mid-day refresh. The DWH SP_Dim_Customer reads from the bronze on a daily cadence with CDC. For real-time forensics use the bronze; for reconcilable analytics use `Dim_Customer`.

## Customer.CustomerStatic — column groups (verified 2026-05-11, 83 cols on masked variant)

| Group | Columns |
|---|---|
| **Identity** | `CID`, `ID` (GUID), `ExternalID` (APEX decimal(38,0)), `ApexID`, `DltID`, `PersonID`, `GCID`, `OriginalCID`, `OriginalProviderID`, `ProviderID`, `RealProviderID`, `UserName`, `UserName_LOWER`, `LinkedAccountHash1` (PERSISTED MD5(lower(FirstName)+...)) |
| **PII (masked)** | `FirstName`, `LastName`, `MiddleName`, `BirthDate`, `Gender`, `Email`, `LowerEmail`, `Phone`, `PhonePrefix`, `PhoneBody`, `Mobile`, `Fax`, `IP`, `Address`, `BuildingNumber`, `Zip`, `City`, `Password` (hash) |
| **Geography** | `CountryID`, `CountryIDByIP`, `CitizenshipCountryID`, `POBCountryID`, `RegionID`, `RegionByIP_ID`, `SubRegionID`, `StateID`, `TimeZoneID` |
| **Acquisition** | `SerialID` (AffiliateID), `SubSerialID`, `ReferralID`, `CampaignID`, `BannerID`, `FunnelID`, `FunnelFromID`, `DownloadID`, `DownloadCounter`, `ClientVersion`, `PlatformID` |
| **Account lifecycle** | `Registered`, `IsReal`, `AccountStatusID`, `AccountExpirationDate`, `PendingClosureStatusID`, `PlayerStatusID`, `PlayerStatusReasonID`, `PlayerStatusSubReasonID`, `PlayerStatusSubReasonComment` |
| **Regulatory / level** | `PlayerLevelID`, `TradeLevelID`, `ClientTypeID`, `LabelID`, `MifID` lookup via Dim_MifidCategorization (not here), `OptOutReasonID`, `PrivacyPolicyID`, `EmailVerificationProviderID` |
| **Pricing / trading config** | `SpreadGroupID`, `LotCountGroupID`, `LeverageType`, `WeekendFeePrecentage` (sic), `CurrencyID` (FK to Dictionary.Currency — currently all USD in practice) |
| **Verification** | `IsEmailVerified`, `IsEmailActivated`, `VerificationTitle`, `VerificationTitleVersion` |
| **Operations** | `HelpDeskType`, `IsRequestedCall`, `IsHedged` (trigger-driven — Warning 3), `Comments` (operator free-text) |
| **Language** | `LanguageID`, `CommunicationLanguageID` |

For the full 107-column denormalized analyst-facing version use `Dim_Customer` (`customer-master-record`). For lineage / column-level transform map see `knowledge/synapse/Wiki/DWH_dbo/Tables/CustomerStatic.md` and `.lineage.md`.

## BackOffice.Customer + the document/risk family

| Table | UC FQN | Role |
|---|---|---|
| `BackOffice.Customer` | `main.general.bronze_etoro_backoffice_customer` | Operator-side mirror of customer state. Carries `OperatorAssignedRiskLevel`, KYC review verdicts, regulatory-action flags. Lags OLTP by minutes (Warning 9). |
| `BackOffice.CustomerDocument` | `main.billing.bronze_etoro_backoffice_customerdocument` | Per-document submission / approval / rejection. |
| `BackOffice.CustomerDocumentToDocumentType` | `main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype` | Document → document-type mapping. |
| `BackOffice.CustomerRisk` | `main.billing.bronze_etoro_backoffice_customerrisk` | Per-customer risk classification, operator-assigned. May allow multiple simultaneous flags. |
| `BackOffice.CustomerAllTimeAggregatedData` | `main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata` | All-time aggregated metrics (deposits / withdrawals / trades counts) — the operator's quick-summary. |

## EXW_DimUser — crypto-wallet user master (UC: 21 cols)

`main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser`

Columns (verified 2026-05-11): `GCID`, `RealCID`, `Username`, `FirstName`, `LastName`, `PlayerLevelID`, `VerificationLevelID`, `CountryID`, `Country` (string name), `RegionID`, `Region` (string name), `IsTestAccount` (NOT `IsTestUser` — Warning 6), `CreditReportValid`, `UpdateDate`, `IsValidCustomer` (locally-computed; can disagree with Dim_Customer — Warning 6), `RegulationID`, `Regulation` (string name), `UserRegionID`, `UserRegion_State` (US state code), `Club` (string club tier; sourced separately from trading-side), `ComplianceClosureEvent`.

Joins:
- **`Dim_Customer.GCID = EXW_DimUser.GCID`** — canonical; works for legacy accounts that have a GCID but EXW provisioning came later.
- **`Dim_Customer.RealCID = EXW_DimUser.RealCID`** — also present; use when GCID is NULL on either side.

The **enriched variant `EXW_DimUser_Enriched`** is Synapse-only (Warning 4). For wallet transactions / balances / on-chain detail, route to `domain-payments/crypto-wallet`.

## Breach / alert tables (UC subset)

| Table | UC FQN | What it carries |
|---|---|---|
| `BI_DB_Compliance_Illegal_Trades_Alerts` | `main.bi_db.gold_..._bi_db_compliance_illegal_trades_alerts` | 39-col event log per illegal-trade alert: `Date`, `AlertType`, `Synopsis`, `RealCID` (STRING — Warning 5), `Country`, `AccountMgr`, `UserName`, `Language`, `MifidCategorization`, `Regulation`, `PositionID`, `OpenDateID`, `InvestedAmount` (STRING), `InstrumentType`, `IsSettled`, `Leverage`, `IsCopy`, `PlayerStatus`, `PlayerStatusReason`, `PlayerSubReason`, `VerificationLevelID`, `RegisteredReal`, `UpdateDate`, `BlockDate`, `FirstDepositDate`, `PlayerStatusReasonID`, `PlayerStatusSubReasonID`, `DepositDate`, `GCID`, `TranID`, `Occurred`, `AmountUSD`, `State`, `CryptoName`, `CryptoID`, `InstrumentDisplayName`, `UpdatedClub`, `InstrumentID`, `SeychellesCategorizationID`, `SeychellesCategorization`. |
| `BI_DB_Scored_Appropriateness_Negative_Market` | `main.bi_db.gold_..._bi_db_scored_appropriateness_negative_market` | 37-col KYC / Appropriateness Test / block-release lifecycle — see Warning 7 for column list and the `ApproprietnessScore_Status` (sic) typo. |

For the four Synapse-only tables (`BI_DB_US_Compliance_Apex_Clients`, `BI_DB_OPS_MultipleAccounts`, `BI_DB_WatchListsByFunnel`, `BI_DB_AML_Documents_Request`) see Warning 4 — query via the Synapse MCP server.

## Critical anti-patterns

1. **DO NOT use `Customer.CustomerStatic` for analyst questions.** Use `Dim_Customer` (`customer-master-record`). The OLTP bronze has more noise (test rows, partially-completed registrations, mid-day state, bronze-tier streaming inconsistency) — `Dim_Customer` is the cleaned daily snapshot.
2. **DO NOT filter `IsTestUser = 0` on `Dim_Customer` or `CustomerStatic` — that column doesn't exist** (Warning 2). Use `IsValidCustomer = 1` on `Dim_Customer` instead.
3. **DO NOT count linked-account chains via `BI_DB_OPS_MultipleAccounts`** — it's Synapse-only (Warning 4) and runs on a separate refresh. For live linked-account counts use `LinkedAccountHash1` matching on `Customer.CustomerStatic` directly (the PERSISTED MD5 of FirstName+LastName+Zip+BirthDate+Gender) or `GCID` dedup on `Dim_Customer`.
4. **DO NOT trust `BackOffice.Customer.PlayerStatusID` as the current status** (Warning 9). Use `Customer.CustomerStatic.PlayerStatusID` or `Dim_Customer.PlayerStatusID`.
5. **DO NOT join `RealCID` across `illegal_trades_alerts` ↔ `Dim_Customer` without CASTing** (Warning 5). The alert table stores RealCID as STRING.
6. **DO NOT use `Dictionary.Country` / `Dictionary.Regulation` for analytical labels** (Warning 8). They are Synapse-only OLTP dictionaries. Use `Dim_Country` / `Dim_Regulation`.

## Query Patterns

### Pattern 1 — Full OLTP forensic row for a customer

```sql
SELECT *
FROM main.general.bronze_etoro_customer_customerstatic_masked
WHERE CID = :realcid;
```

(`SELECT *` intentional for forensic / column-discovery; for dashboards name the columns. Note: PK on this table is `CID` (NOT `RealCID`) — only `Dim_Customer` carries both names with identical values.)

### Pattern 2 — Hedge-flag diagnosis (why is `IsHedged = 0`?)

```sql
SELECT
  cs.CID,
  cs.IsHedged,
  cs.LabelID                                        -- 26 = ILQ (Dim_Label.Name) -> IsHedged = 0
  , cs.PlayerLevelID                                -- 4 = Internal (Dim_PlayerLevel.Name) -> IsHedged = 0
  , dl.LabelName                                    -- if Dim_Label available
FROM main.general.bronze_etoro_customer_customerstatic_masked cs
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label dl ON dl.LabelID = cs.LabelID
WHERE cs.CID = :realcid;
```

Plus check `BackOffice.BonusOnlyCustomers` and `CEP.ListCIDMappings(NamedListID = 3)` (both Synapse-only) for the remaining trigger conditions.

### Pattern 3 — Find linked accounts via `LinkedAccountHash1`

```sql
WITH target AS (
  SELECT LinkedAccountHash1
  FROM main.general.bronze_etoro_customer_customerstatic_masked
  WHERE CID = :realcid
)
SELECT cs.CID, cs.GCID, cs.UserName, cs.LinkedAccountHash1
FROM main.general.bronze_etoro_customer_customerstatic_masked cs
JOIN target t ON cs.LinkedAccountHash1 = t.LinkedAccountHash1
WHERE cs.LinkedAccountHash1 IS NOT NULL
  AND cs.CID <> :realcid;
```

This finds linked accounts by the PERSISTED MD5(lower(FirstName) + lower(LastName) + Zip + BirthDate + Gender) fingerprint. For an aggregated multi-account roll-up, see the Synapse-only `BI_DB_OPS_MultipleAccounts`.

### Pattern 4 — Illegal-trade alerts joined to the customer master

```sql
SELECT
  a.Date, a.AlertType, a.Synopsis,
  CAST(a.RealCID AS INT) AS RealCID,                -- alert table is STRING (Warning 5)
  a.PositionID, a.InstrumentDisplayName,
  c.CountryID, c.RegulationID, c.PlayerLevelID
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts a
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
  ON c.CID = CAST(a.RealCID AS INT)
WHERE a.Date >= TIMESTAMP'2025-01-01'
  AND c.IsValidCustomer = 1;
```

### Pattern 5 — Scored-appropriateness negative-market customers currently blocked

```sql
SELECT
  s.RealCID, s.GCID,
  s.CountryName, s.RegulationName, s.DesignatedRegulationName,
  s.RestrictionStatusDesc, s.CFD_Status,
  s.BlockDate, s.BlockReasonDesc, s.BlockSubReasonDesc,
  s.AT_Date,
  s.`ApproprietnessScore_Status` AS appropriateness_status     -- backtick the typo (Warning 7)
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_scored_appropriateness_negative_market s
WHERE s.ReleaseDate IS NULL
  AND s.BlockDate IS NOT NULL;
```

### Pattern 6 — EXW crypto-wallet user lookup

```sql
SELECT
  eu.GCID, eu.RealCID, eu.Username,
  eu.PlayerLevelID, eu.VerificationLevelID,
  eu.Country, eu.Region, eu.Regulation, eu.Club,
  eu.IsTestAccount,                                  -- NOT IsTestUser (Warning 6)
  eu.CreditReportValid, eu.IsValidCustomer,          -- locally computed; may diverge from Dim_Customer
  eu.ComplianceClosureEvent, eu.UpdateDate
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser eu
WHERE eu.GCID = :gcid;
```

For deeper crypto-wallet questions (transactions, balances, on-chain), route to `domain-payments/crypto-wallet`.

## Wiki deep-reads

- `knowledge/synapse/Wiki/DWH_dbo/Tables/CustomerStatic.md` — column dictionary for the Synapse-side staging of the OLTP `Customer.CustomerStatic` (the same 83-col surface visible in the UC bronze). Companion files `.lineage.md` and `.review-needed.md`.
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md` — for the analyst-side curated denormalization (see also `customer-master-record`).
- Wiki entries for `BackOffice.Customer`, `BackOffice.CustomerDocument`, `BackOffice.CustomerRisk`, `BackOffice.CustomerAllTimeAggregatedData` are in `knowledge/synapse/Wiki/BackOffice/...` (folder structure mirrors the Synapse schema).
- `knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_DimUser.md` — crypto-wallet user dim.
- `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Compliance_Illegal_Trades_Alerts.md`, `.../BI_DB_Scored_Appropriateness_Negative_Market.md` — UC-available breach tables.
- For the four Synapse-only tables (Warning 4) — query via Synapse MCP; wikis if present live under `BI_DB_dbo/Tables/`.

## Sources Consulted

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| main.general.bronze_etoro_customer_customerstatic_masked | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/CustomerStatic.md | column-level docs for the Synapse staging variant; lineage to OLTP source |
| main.general.bronze_etoro_customer_customerstatic_masked | S | 1b | UC `information_schema.columns` 2026-05-11 | confirmed 83 cols on masked variant (Warning 1); listed the 5 real `Is*` cols (Warning 2); IsHedged trigger semantics (Warning 3) |
| main.general.bronze_etoro_customer_customerstatic_masked | S | 4 | UC `WHERE column_name IN ('IsTestUser','IsExcludedFromReporting','MasterCID','IsV1Accepted', ...)` 2026-05-11 | zero matches — all speculative v1 column names absent (Warning 2) |
| main.bi_db.gold_..._bi_db_compliance_illegal_trades_alerts | S | 1b | UC `information_schema.columns` 2026-05-11 | confirmed 39 cols; `RealCID STRING` plus most analytical fields STRING-typed (Warning 5) |
| main.bi_db.gold_..._bi_db_scored_appropriateness_negative_market | S | 1b | UC `information_schema.columns` 2026-05-11 | confirmed 37 cols; documented the `ApproprietnessScore_Status` (sic) typo (Warning 7) |
| main.bi_db.gold_..._exw_dimuser | S | 1b | UC `information_schema.columns` 2026-05-11 | confirmed 21 cols; `IsTestAccount` not `IsTestUser` (Warning 6); `Club` string + `UserRegion_State` + `ComplianceClosureEvent` |
| (negative result) | S | 4 | UC `information_schema.tables WHERE table_name LIKE '%us_compliance_apex%' OR '%ops_multipleaccounts%' OR '%watchlistsbyfunnel%' OR '%aml_documents_request%' OR '%exw_dimuser_enriched%'` 2026-05-11 | zero rows — confirms five Synapse-only tables (Warning 4) |
