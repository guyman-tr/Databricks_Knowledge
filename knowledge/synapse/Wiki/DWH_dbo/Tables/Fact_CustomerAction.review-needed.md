# DWH_dbo.Fact_CustomerAction — Review Needed

> Items requiring human domain expert review. Generated alongside the wiki documentation.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed) override on the next pipeline rerun. Use `glossary` in the Scope column if the term should also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| IsPlug | "Plug/adjustment flag. Always NULL" | Dismissed — deprecated/unused column. Always NULL. | table | Guy | 2026-03-03 |
| HistoryID | "Composite unique identifier encoding ActionTypeID + GCID" | Not a reliable key — contains duplicates. Never use for JOINs, deduplication, or row identification. Removed encoding section from Business Logic. | table | Guy | 2026-03-03 |
| PreviousOccurred | "Timestamp of customer's previous action" | Dismissed — deprecated/unused, not reliably populated. | table | Guy | 2026-03-03 |
| PlatformID | "Derived login platform (101-126)" | Badly named FK — actually references Dim_Product.ProductID. JOIN for Product/Platform/SubPlatform. Never hard-code value mappings. Added Dim_Product to Common JOINs and Relationships. | table | Guy | 2026-03-03 |
| FundingTypeID | "No lookup table found in DWH" | References DWH_dbo.Dim_FundingType.FundingTypeID. Added to Relationships. | table | Guy | 2026-03-03 |
| BonusTypeID | "No lookup table found in DWH" | References DWH_dbo.Dim_BonusType.BonusTypeID — Name, IsWithdrawable, IsActive. | table | Guy | 2026-03-03 |
| PaymentStatusID | "No lookup table found in DWH" | References DWH_dbo.Dim_PaymentStatus.PaymentStatusID — Name. | table | Guy | 2026-03-03 |
| CampaignID | "No lookup table found in DWH" | References DWH_dbo.Dim_Campaign.CampaignID — Code, Description, dates, MaxBonusAmount. | table | Guy | 2026-03-03 |
| CountryIDByIP | "References country lookup" | References DWH_dbo.Dim_Country.CountryID. Also see Dim_CountryIP for IP resolution. | table | Guy | 2026-03-03 |
| Tagline | "one row per event per customer per day" | Fixed to "one row per event" — SP inserts individual rows, not aggregated per day. | table | auto | 2026-03-03 |
| IsReal | "Always 1 — unknown if demo exists" | Confirmed: `1 AS IsReal` hard-coded in SP. No demo FCA table exists. | table | auto | 2026-03-03 |
| Cashier Loggin | "Typo in ActionType name?" | Not a typo — "Loggin" is the actual naming throughout the codebase (Ext_FCA_Real_Cashier_Loggin). | table | auto | 2026-03-03 |
| Social engagement (21-26) | "Source unknown" | Dead data — legacy rows exist but no longer updated. No active ETL. | table | Guy | 2026-03-03 |

---

## Auto-Applied from Dim_Position Review

These corrections were already applied from the DimPos review session. Listed here for traceability.

| Column | DimPos Correction Applied | Status |
|--------|--------------------------|--------|
| Commission / CommissionOnClose | Described as "eToro markup (spread)" per DimPos glossary correction | Applied |
| FullCommission / FullCommissionOnClose | Described as "market spread + eToro markup" per DimPos glossary correction | Applied |
| IsAirDrop | "position created by eToro on behalf of customer" — not just crypto per DimPos correction | Applied |
| RedeemStatus / RedeemID | "Crypto redemption to eToro wallet" with correct value mapping per DimPos correction | Applied |
| SettlementTypeID | Values 0-5 mapped per DimPos correction (0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE) | Applied |

## Corrections Applied (from DimPos review)

| Column | Correction Applied | Status |
|--------|-------------------|--------|
| DLTOpen | Updated to "DLT (German crypto broker) flag at open" per DimPos glossary correction | Applied |
| DLTClose | Updated to "DLT broker flag at close: 1=closed on DLT broker platform" per DimPos glossary correction | Applied |

---

## Tier 4 (UNVERIFIED) Columns

These columns received descriptions based only on column name inference. A domain expert should verify or correct.

| # | Column | Current Description | Question for Reviewer |
|---|--------|--------------------|-----------------------|
| | *(none remaining)* | | |

## Columns Needing Clarification

| Column | Tier | Question |
|--------|------|----------|
| HistoryID | 5 | [RESOLVED] Domain expert confirmed: intended as key but has duplicates. Not reliable — never use for JOINs or deduplication. |
| PreviousOccurred | 5 | [RESOLVED] Dismissed — deprecated/unused, not reliably populated. |
| StatusID | 3 | Nearly always 1 (~11B rows). ~2M rows are NULL. What does NULL mean — deleted? Failed? Legacy? Is any value other than 1 ever used? |
| PlatformID | 5 | [RESOLVED] Badly named FK — actually references Dim_Product.ProductID. JOIN to Dim_Product for Product/Platform/SubPlatform. Never hard-code value mappings. |
| BonusTypeID | 5 | [RESOLVED] References DWH_dbo.Dim_BonusType.BonusTypeID — JOIN for Name, IsWithdrawable, IsActive. |
| FundingTypeID | 5 | [RESOLVED] References DWH_dbo.Dim_FundingType.FundingTypeID — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive. |
| PaymentStatusID | 5 | [RESOLVED] References DWH_dbo.Dim_PaymentStatus.PaymentStatusID — JOIN for Name. |
| CampaignID | 5 | [RESOLVED] References DWH_dbo.Dim_Campaign.CampaignID — JOIN for Code, Description, dates, MaxBonusAmount, IsActive. |

## Structural Questions

| Topic | Question |
|-------|----------|
| Tagline — "per day" | [RESOLVED] Fixed to "one row per event". SP inserts individual rows per credit/position/login — not aggregated per day. |
| ActionTypeID gaps | IDs 13, 20, 31, 33 not found in Dim_ActionType or ETL SPs. Likely deprecated/never used. Skipped. |
| Social engagement source | [RESOLVED] ActionTypeID 21-26 are dead data — no longer updated. Legacy social engagement rows exist but no active ETL loads them. |
| IsReal always 1 | [RESOLVED] Confirmed from SP code: `1 AS IsReal` is hard-coded in all INSERT statements. No separate demo FCA table exists in the repo — demo actions are simply not tracked. |
| Cashier Loggin (ActionTypeID 29) | [RESOLVED] "Loggin" is the actual naming in source code — staging table is `Ext_FCA_Real_Cashier_Loggin`, named consistently throughout the ETL. Not a typo in the wiki — it's from the codebase. |

---

*Generated: 2026-03-03 | Companion to Fact_CustomerAction.md*
