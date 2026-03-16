# BI_DB_dbo.BI_DB_CIDFirstDates — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

The following 18 columns have descriptions inferred from column names only (Tier 4). Domain experts should verify or correct these:

| # | Column | Current Description | Question for Reviewer |
|---|--------|--------------------|-----------------------|
| 28 | FirstTimeUser | First time user engaged as new user | What specifically triggers this timestamp? Is this from a specific system/event? |
| 30 | FirstDemoLoggedIn | First demo login timestamp | Is this still populated for new customers? What source updates it? |
| 31 | FirstDemoPosOpenDate | First demo position open date | Same as above — is demo data still tracked? |
| 32 | FirstDemoMirrorRegistrationDate | First demo copy-trade registration | Is demo copy-trade tracking still active? |
| 33 | LastDemoMirrorRegistrationDate | Last demo copy-trade registration | Same question as #32 |
| 34 | FirstDemoMirrorPosOpenDate | First demo copy-trade position | Same question as #32 |
| 50 | FirstDepositAmountExtended | Extended first deposit including bonuses | What makes this "extended"? How does it differ from FirstDepositAmount? |
| 52 | LastDemoLoggedIn | Last demo login date | Is demo data still being tracked? |
| 53 | LastDemoMirrorPosOpenDate | Last demo copy-trade position | Same question |
| 54 | LastDemoPosOpenDate | Last demo position open | Same question |
| 78 | SevenDayRetained | Day 7 retention flag | What is the exact definition? Is it: still has equity? Has logged in within 7 days? Has open positions? |
| 79 | FirstToSevenDayRetained | First-to-7-day retention | How does this differ from SevenDayRetained? Is it measuring retention from FTD to day 7? |
| 80 | FirstDateRetained | First-date retention | What is "first date" retention? Same day as first deposit? |
| 86 | FirstContactAttemptDate_ByPhone | First phone contact attempt | Is this populated from Salesforce? Same source as LastContactAttemptDate_ByPhone? |
| 88 | FirstContactDate_ByPhone | First successful phone contact | Same source question as #86 |
| 89 | PremiumAccount | Premium account flag | What defines a "premium account"? This column is entirely NULL — is it deprecated? |
| 91 | FirstToThirtyDayRetained | 30-day retention flag | Same definition question as #78 but for 30-day window |
| 97 | Follow5UsersDate | Date customer followed 5 users | Is this social onboarding milestone still tracked? What was the business purpose? |
| 98 | NumberOfUsersFollowed | Count of followed users | Is this updated currently or historical-only? |
| 103 | Model_FTDsOTDs | ML model score for FTD/OTD | What model produces this? Is it still in use? |
| 104 | Model_Leads | ML model score for leads | Same question as #103 |
| 108 | Model_ReDepositor | ML model score for re-deposit | Same question as #103 |
| 136 | SignedW8Date | W-8BEN tax form signing date | Was this populated before being disabled? Is it sourced from a specific system? |

## Columns Needing Clarification

| Column | Issue | Context |
|--------|-------|---------|
| KycModeID | Values 1-4 found but no label resolution | What do values 1, 2, 3, 4 represent? E.g., 1=Standard KYC, 2=Enhanced Due Diligence? |
| DocsOK | Only 30,740 customers have value 1 | Is this still actively set? What "docs" does it refer to? |
| IsSales | 2.6M have value 0, 16K have value 1 | What defines a "sales" customer? Is this set by the CRM team? |
| HasPic | 653K have value 1, 87 have value 0 | What is the difference between NULL and 0? Both mean "no picture"? |
| FeedUnlocked vs FeedUnBlocked | FeedUnBlocked is all NULL, FeedUnlocked has values | Are these the same concept? Was FeedUnBlocked replaced by FeedUnlocked? |
| FirstDepositAttemptProcessor/FundingType | Currently 'NA' for all | These are set to 'NA' in the SP code. Was there ever a plan to populate them properly? |

## Structural Questions

| Question | Context |
|----------|---------|
| Demo columns (FirstDemoLoggedIn, etc.) | Are these 7 demo-related columns still being populated by any process, or are they historical-only from before the SP was refactored? |
| Retention columns (SevenDayRetained, etc.) | What process populates these? They're not in SP_CIDFirstDates. Is there a separate SP? |
| Model columns (Model_FTDsOTDs, Model_Leads, Model_ReDepositor) | Are these populated by a separate ML pipeline? Are they current? |
| Is there a plan to deprecate the discontinued columns? | 16 columns are deprecated/not updated. Should they be dropped from the table/UC? |
