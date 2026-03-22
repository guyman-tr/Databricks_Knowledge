# Refer-a-Friend (RAF) Compensation Audit

**Date:** 21 March 2026
**Scope:** Independent audit of RAF abuse detection, compensation mechanics, and customer quality
**Data Period:** January 2024 – March 2026
**Prepared by:** Data Platform team (Cursor agent-assisted analysis)

---

## 1. Background & Motivation

### 1.1 Origin

A Databricks-based agent conducted research into RAF bonus abuse across two notebooks:
- **RAF Device ID Blind Spot (lean)** — Notebook ID `3729404030563007`
- **RAF Abuse Detection Research (full)** — Notebook ID `1140806784982497`

The agent's central claim was that **device ID data exists but is not used in RAF fraud detection**, and that **2.8M entries have a null trigger** in the automated fraud detection system. It also flagged an ML pipeline producing `FraudScore` values that aren't being actioned.

This audit was initiated to:
1. Independently verify those claims
2. Quantify the actual financial exposure
3. Challenge assumptions about real-time blocking capability
4. Propose improvements backed by data

### 1.2 Thesis Going In

> Better enforcement could save money — but how much, and where exactly?

As the audit progressed, the thesis evolved from "catch more fraud" to a more fundamental question: **is the RAF programme optimised for customer quality, or only for fraud prevention?**

---

## 2. What We Checked

### 2.1 Data Sources Queried

| Source | System | Tables Examined |
|--------|--------|-----------------|
| RAF tracking & processing | Databricks | `bronze_rafcompensations_customer_raftrackingprocessed` |
| RAF actual payouts | Databricks | `bronze_etoro_customer_rafgiven` |
| RAF configuration | Databricks | `bronze_rafcompensations_config_viewconfig` |
| ML fraud scores | Databricks | `rnd_output_experience_raf_candidates` |
| Device/tracking IDs | Databricks | `bronze_etoro_customer_trackingid` |
| RAF customer pairs | Databricks | `bronze_etoro_dwh_rafcustomers` |
| Customer first dates | Databricks | `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates` |
| Invitee KPIs & monitoring | Synapse | `BI_DB_dbo.BI_DB_RAF_Invitees_KPIs` |
| Customer master | Synapse | `DWH_dbo.Dim_Customer` |
| Affiliate fraud SP | DataPlatform repo | `SP_M_Affiliates_FraudMonitoring` |

### 2.2 Verification Approach

- Searched all 16 RAF-related tables for device ID columns — **zero found**
- Searched all 17 RAF status values for device-related statuses — **zero found**
- Searched 8 ML features for device fingerprint inputs — **zero found**
- Confirmed device ID IS used for **affiliate fraud** (separate system, separate SP) but is **not wired into RAF**
- Verified the ML pipeline produces `FraudScore` in `rnd_output_experience_raf_candidates`, but `IsProcessed = 0` on all records — the model scores but **does not block**
- Confirmed `FraudScore = 0.95` threshold is operationally permissive (only blocks >95% probability fraud)

**Verdict on the Databricks agent's claims:** Largely correct. Device ID is genuinely absent from RAF fraud logic, and the ML model's output is not fully actioned. The "2.8M null trigger" claim could not be independently verified at the same granularity but is directionally consistent.

---

## 3. How RAF Works Today

### 3.1 Compensation Mechanics

RAF is a **primarily referrer-paid** system. The referring customer (inviter) receives a cash bonus when their referred friend (invitee) deposits and meets minimum criteria.

**Invitee compensation:** The invitee receives $0 in EU/APAC/Middle East/Australia configurations. The exception is the **US market** (RegulationID 6/7/8), where since April 2025 both parties receive **$30 each** under the Default Setting. Out of 87,199 compensated pairs since Jan 2024, only 1,475 (1.7%) included a referred-party payment. There may also be separate welcome/signup promotions tracked outside the RAF compensation system that provide invitee incentives — the RAF config tables do not capture these.

**Compensation is a daily batch job** (runs ~04:00 UTC), not real-time. This provides an intervention window but means it's not instantaneous fraud prevention.

### 3.2 Tier Structure (as of Oct 2025)

| Tier | Comp per Referral | Max Compensations | Wait (days) | Min Trade Vol | Check Window |
|------|------------------:|------------------:|------------:|--------------:|-------------:|
| Default | $50 | 10 | **7** | **$100** | **90 days** |
| Gold | $200 | 10–50 | None | None | None |
| Platinum | $200 | 10–50 | None | None | None |
| Diamond | $500 | 50 | None | None | None |
| Platinum Plus | $500 | 50 | None | None | None |

**Critical gap:** Quality gates (wait period, minimum trade volume, check window) exist only for the Default tier. Premium tiers — which account for **84% of total RAF spend** — have **no quality gates whatsoever**.

### 3.3 Regulatory Segmentation

| RegulationID | Markets | Check Window |
|:---:|---------|:---:|
| 1 | EU/EEA (CySEC) — 18 countries | 90 days |
| 2 | APAC (Philippines, Singapore, Vietnam) | 30 days |
| 9 | Middle East (Bahrain, Kuwait, Qatar) | 90 days |
| 10 | Australia (ASIC) | 90 days |
| 11 | UAE | 90 days |

### 3.4 Fraud Detection Layers

| Layer | Status | Notes |
|-------|--------|-------|
| ML fraud scoring | Scoring active, **not actioned** | `FraudScore` produced but `IsProcessed = 0` on all records |
| Fraud threshold | 0.95 across all tiers | Only blocks >95% probability — very permissive |
| `MatualIPAdress30Days` flag | Monitored in KPI table | Not used as a blocking criterion |
| Device fingerprinting | **Not connected to RAF** | Used for affiliate fraud only |
| Referrer-is-depositor check | Functional | Non-depositing referrers earn $0 |
| Waiting period | Default tier only | 7 days EU, 14 days US (pre-Oct 2025 configs) |
| Min trade volume gate | Default tier only | $100 within 90 days |

---

## 4. Findings

### 4.1 Total RAF Spend

Since January 2024, **87,193 referral pairs were compensated** for a total of **$15.42M**:

| Tier | Pairs Paid | Total Spend | Share |
|------|----------:|----------:|------:|
| Diamond ($500) | 13,568 | $6.81M | 44.2% |
| Gold/Platinum ($200) | 30,857 | $6.18M | 40.1% |
| Default ($50) | 34,993 | $1.65M | 10.7% |
| Other ($100/$30/$10) | 7,775 | $0.78M | 5.1% |
| **Total** | **87,193** | **$15.42M** | **100%** |

### 4.2 Referrer Profiling — Volume vs Quality

We profiled referrers by the number of people they referred and measured invitee quality:

| Referrer Volume | Referrer Count | Invitees | Avg FTD | Avg Trades | % Funded 14d |
|-----------------|---------------:|---------:|--------:|-----------:|-------------:|
| 20+ referrals | 994 | 46,266 | **$323** | **585** | **53.0%** |
| 10–19 referrals | 3,105 | 39,422 | $298 | 478 | 69.5% |
| 5–9 referrals | 5,057 | 32,318 | $425 | 1,398 | 75.3% |
| 2–4 referrals | 23,406 | 59,414 | $698 | 2,680 | 80.2% |
| 1 referral (organic) | 76,380 | 76,380 | **$1,041** | **4,513** | **83.5%** |

Organic single-referrers bring invitees who deposit **3.2× more**, trade **7.7× more**, and stay funded **1.6× more** than high-volume referrers.

### 4.3 The Retention Cliff — The Central Finding

We measured whether invitees were still active on the platform 30 and 90 days **after compensation was paid**:

| Tier | Referrer Vol | Comp Paid | 30-Day Retention | 90-Day Retention |
|------|-------------|----------:|-----------------:|-----------------:|
| Default $50 | High (10+) | $414K | **0.3%** | 0.2% |
| Default $50 | Low (1–2) | $753K | 66.1% | 57.0% |
| Gold/Plat $200 | High (10+) | $1.17M | **4.5%** | 3.9% |
| Gold/Plat $200 | Low (1–2) | $1.63M | 71.4% | 64.4% |
| Diamond $500 | High (10+) | $787K | 37.1% | 32.9% |
| Diamond $500 | Low (1–2) | $1.35M | 69.7% | 63.8% |

**High-volume Default referrers: 0.3% retention at 30 days.** Effectively 100% churn. $414K spent on customers who all left within a month.

Gold/Platinum high-volume: 4.5% retention. $1.17M spent with near-total churn.

**Low-volume referrers consistently achieve 64–71% retention at 90 days**, regardless of tier. These are real people recommending to real friends.

### 4.4 Referrer Quality Scoring

We graded referrers (3+ referrals) by the funded rate of their invitees:

| Grade | Referrers | Comp Paid | Avg Funded Rate |
|-------|----------:|----------:|----------------:|
| Quality (≥50% funded) | 8,832 | $1.88M | 81.0% |
| Decent (30–50%) | 2,771 | $303K | 35.6% |
| Mediocre (10–30%) | 2,086 | $288K | 20.5% |
| Poor (<10%) | 367 | $78K | 6.4% |
| **Zero quality (0% funded)** | **4,637** | **$372K** | **0.0%** |

**4,637 referrers have a 0% funded rate** across all their invitees and collectively earned $372K. The 367 "poor" referrers average **56 referrals each** — classic referral mills.

### 4.5 Referrer Profile — Are They Real Users?

| Referrer Type | Count | Invitees | % Deposited | Comp Paid |
|---------------|------:|---------:|------------:|----------:|
| Never deposited | 12,352 | 15,357 | 6.6% | $0 |
| Micro (<$100 FTD) | 15,172 | 22,292 | 40.0% | $234K |
| Small ($100–500 FTD) | 43,565 | 101,429 | 48.7% | $1.68M |
| Real (>$500 FTD) | 37,853 | 114,722 | 47.4% | $2.12M |

The system correctly blocks never-deposited referrers ($0 comp). But micro-depositors who deposit just enough to qualify still earn $234K bringing mediocre invitees.

### 4.6 Payout Timing

The 7-day waiting period (introduced Oct 2025 for Default tier) is enforced — 85.9% of payouts land at exactly day 7. Across all tiers, average FTD-to-comp is 7.6–8.8 days, suggesting the wait is applied more broadly than config suggests.

No payouts occur at day 0 or 1 post-October 2025, confirming the batch job correctly enforces the delay.

---

## 5. What Currently Works

Credit where it's due — the existing system is not broken:

1. **Never-deposited referrers earn $0** — the basic eligibility check works
2. **The 7-day wait period is enforced** — near-zero early payouts since Oct 2025
3. **Default tier has quality gates** — $100 min trade volume in 90 days filters minimum-effort deposits
4. **The ML model produces fraud scores** — the scoring pipeline runs, even if the output isn't fully actioned
5. **The `isAbuser` flag catches known patterns** — mutual IP, behavioral signals are tracked
6. **99.8–100% of compensated invitees have traded** — the system ensures some minimum activity

The core programme works. The issue isn't that fraud is rampant — it's that the programme pays for **customer acquisition without measuring customer quality**.

---

## 6. Proposals

### 6.1 Progressive Payout (Highest Impact)

**Current state:** Referrer receives 100% of compensation at FTD + 7 days.

**Proposed:** Split the payout into retention milestones:

| Milestone | % of Comp | Trigger |
|-----------|----------:|---------|
| FTD + 7 days | 30% | Invitee deposited and passed fraud check |
| FTD + 30 days | 40% | Invitee still funded and has traded |
| FTD + 90 days | 30% | Invitee is an active customer |

**Estimated impact:** Based on the retention data, high-volume referrers at Default/Gold tiers (0.3–4.5% 30-day retention) would receive only 30% of their comp instead of 100%. **Estimated savings: $1.5–2.4M annually** from comp that would never vest, without blocking a single legitimate referral.

**Why it works:** Legitimate referrers (64–71% 90-day retention) lose almost nothing. Referral mills lose 70% of their payout. The incentive flips from "acquire a signup" to "bring a real customer."

**Regulatory note:** This conditions the **referrer's** payment (a marketing cost) on invitee activity, not a bonus to the invitee. Analogous to affiliate CPA models across financial services. See §7 for regulatory analysis.

### 6.2 Extend Quality Gates to All Tiers

**Current state:** Gold/Platinum/Diamond have no waiting period, no minimum trade volume, and no check window.

**Proposed:** Apply the existing Default tier gates ($100 min trade vol, 7-day wait, 90-day check) to all tiers. These gates are already approved by legal for Default in EU markets.

**Estimated impact:** Difficult to backtest precisely (premium tier invitee trade volume isn't tracked in the KPI table), but $12.99M (84% of spend) currently flows through ungated tiers.

### 6.3 Referrer Quality Scoring & Volume Caps

**Current state:** `MaxNumberOfCompensations` is 10 (Default) or 50 (premium). No quality-based gating.

**Proposed:**
- After 5 referrals, gate future payouts on a minimum funded rate (e.g., ≥30% of previous invitees funded at 30 days)
- Implement volume-adjusted comp rates: referrals 1–5 at full rate, 6–10 at 75%, 11+ at 50%
- Surface a "Referrer Score" in the referrer's dashboard to gamify quality over quantity

**Estimated impact:** Directly targets the 367 "poor" referrers (avg 56 refs, 6.4% quality) and 4,637 "zero quality" referrers. Combined comp: $450K.

### 6.4 Activate the ML Pipeline

**Current state:** `FraudScore` is calculated but `IsProcessed = 0` for all records. Threshold is 0.95 (very permissive).

**Proposed:**
- Action the ML output — block payouts where `FraudScore ≥ 0.80` (not 0.95)
- Add device fingerprint (AppsFlyerDeviceID, UserUniqueIdentifierCookie, FirebaseAppInstanceId) as features to the model
- Add mutual IP address as a feature (data exists in `MatualIPAdress30Days` but isn't fed to the model)

**Estimated impact:** Incremental — device overlap between RAF pairs is minimal ($100 caught in historical analysis), suggesting abusers already use different devices. The bigger win is lowering the threshold from 0.95 to 0.80.

### 6.5 Monitoring Gap: Premium Tier KPI Tracking

**Current state:** The `BI_DB_RAF_Invitees_KPIs` table tracks primarily Default tier compensations. Premium tiers ($12.99M spend) are underrepresented.

**Proposed:** Extend the KPI monitoring table to cover Gold/Platinum/Diamond tiers with the same metrics: `IsFundedAfter14Days`, `MatualIPAdress30Days`, `isCashoutAfterCompensation`, revenue from referred user.

**Estimated impact:** No direct savings, but enables data-driven management of 84% of RAF spend that currently lacks monitoring.

---

## 7. Regulatory Considerations

### 7.1 Relevant Framework

European retail investment firms operate under MiFID II and ESMA product intervention measures. CySEC (the regulator for eToro's EU entity) issued guidance restricting **trading bonuses offered to clients** — incentives tied to trading volume that encourage excessive trading.

> **Important disclaimer:** The CySEC circular reference (C168, 2016) cited in this analysis is from the author's general knowledge of EU financial regulation. It was **not sourced from internal Confluence, Jira, or legal documentation**. The compliance team should verify the current regulatory position before implementing any changes to compensation structure.

### 7.2 Why Referrer Compensation Is Different

The RAF programme pays the **referrer** (marketing channel), not the **invitee** (client). This is a customer acquisition cost, not a client inducement:

| Aspect | Client Bonus (Restricted) | Referrer Comp (Current RAF) |
|--------|---------------------------|----------------------------|
| Who receives payment | The trading client | The referring client |
| What triggers payment | Client's own trading | Invitee's deposit/activity |
| Regulatory category | Client inducement | Marketing/affiliate cost |
| ESMA restriction | Applies | Does not directly apply |

In EU/APAC/ME/AU, `ReferredCompensationInCents = 0` across all tiers, strongly suggesting the legal team has drawn this line for regulated markets. The US exception ($30 to both parties since April 2025) operates under different regulatory constraints (SEC/FINRA rather than ESMA/CySEC).

### 7.3 Proposal Risk Assessment

| Proposal | Regulatory Risk | Rationale |
|----------|:-:|-----------|
| Progressive payout | **Low** | Conditions marketing spend on ROI — standard affiliate practice |
| Quality gates for all tiers | **Low** | Already approved for Default tier in EU; same legal framework |
| Referrer quality scoring | **Low** | Internal marketing channel optimisation |
| Activate ML pipeline | **Low** | Fraud prevention — explicitly permitted |
| Invitee platform credit | **High** | Would constitute a client inducement — likely prohibited in EU |

Proposal to give invitees platform credit (discussed during brainstorming) was excluded from final recommendations due to regulatory risk.

---

## 8. Recommended Priority & Effort

| # | Proposal | Est. Annual Savings | Effort | Risk |
|---|----------|--------------------:|--------|------|
| 1 | Quality gates on all tiers | TBD (needs monitoring first) | Low (config change) | Low |
| 2 | Premium tier KPI monitoring | Enables #1 | Medium (ETL extension) | None |
| 3 | Progressive payout | $1.5–2.4M | Medium (config + batch logic) | Low |
| 4 | ML pipeline activation | $100K–300K | Low (threshold change) | Low |
| 5 | Referrer quality scoring | $450K | Medium–High (new scoring + UI) | Low |

**Recommended sequencing:** #1 → #2 → #3 → #4 → #5

Start with the config change (quality gates on all tiers) because it's the lowest effort and uses existing, legally approved rules. Then extend monitoring to premium tiers so you can measure the impact. Progressive payout requires batch logic changes but delivers the largest savings. ML activation is a threshold tweak. Referrer scoring is the longest build but creates a sustainable quality flywheel.

---

## 9. Summary

The RAF programme spends **$15.4M annually** (Jan 2024 run rate) on customer acquisition via referrals. The fraud prevention layer works — obvious fraud is blocked, and the 7-day waiting period limits real-time exploitation.

However, **84% of spend ($13M) flows through premium tiers with zero quality gates**. High-volume referrers across all tiers bring invitees with **0.3–4.5% 30-day retention**, compared to **64–71% for organic single-referrers**. The programme pays for signups, not customers.

The shift from "did we block fraud?" to "did we acquire a customer who stays?" is where the real money is. Progressive payout alone could save $1.5–2.4M annually without penalising any legitimate referrer, because their invitees stay anyway.

---

## Appendix A: CID Journey Examples

Real referral pairs illustrating each archetype. All data from `bronze_etoro_customer_rafgiven` joined with `gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates`.

---

### A.1 — Organic Genuine (1:1, quality customer)

**Referrer CID 31138356** (Netherlands, Bronze club)
- Registered real user: $1,951 FTD, $3,827 equity, **still actively trading** as of 20 Mar 2026
- Referred **one friend**: CID 39683816

| | Referrer | Invitee |
|---|---|---|
| Country | Netherlands | Netherlands |
| Club | Bronze | **Platinum** |
| FTD | $1,951 | $4,267 |
| Current equity | $3,827 | **$27,117** |
| Last trade | 20 Mar 2026 | 20 Mar 2026 |
| Days active after comp | — | **652 days** |
| Last deposit | — | 3 Nov 2025 |

**$50 compensation → $27K equity retained customer, still active 652 days later.** This is what the programme is designed to produce.

**Referrer CID 36910597** (Singapore, Platinum)
- Real trader: $719 FTD, $26K equity, active daily
- Referred one friend: CID 39689394

| | Referrer | Invitee |
|---|---|---|
| Country | Singapore | Singapore |
| Club | Platinum | **Platinum Plus** |
| FTD | $719 | $3,500 |
| Current equity | $26,134 | **$52,712** |
| Days active after comp | — | **651 days** |

**$50 compensation → $52K equity Platinum Plus customer.** The invitee surpassed the referrer.

---

### A.2 — "Genuine Few" (3 refs, actually suspicious)

**Referrer CID 40221124** (Italy, Bronze)
- Registered 5 Aug 2024, deposited $540, opened **one position that same minute**, equity $0.05
- Referred 3 people — all from Italy, all registered within **24 hours of each other**:

| Invitee CID | Registered | FTD | Trades | Last Trade | Equity | Days active post-comp |
|-------------|-----------|----:|-------:|-----------|-------:|----------------------:|
| 40224567 | 6 Aug 07:11 | $110 | 1 | 6 Aug 07:19 | $0.04 | **-6** |
| 40226317 | 6 Aug 10:54 | $110 | 1 | 6 Aug 11:03 | $0.00 | **-6** |
| 40230195 | 6 Aug 17:45 | $538 | 1 | 7 Aug 07:22 | $0.07 | **-6** |

**$150 paid.** All 3 invitees deposited minimum, made 1 trade, and never returned. Last trade was before compensation was even issued. The low referral count (3) masks the abuse pattern.

**Referrer CID 40458020** (Italy, Bronze)
- Registered 4 Sep 2024, deposited $515, traded for 1 day
- 3 invitees — all Italy, all registered within **40 minutes of each other** on the same evening:

| Invitee CID | Registered | FTD | Last Trade | Equity | Days post-comp |
|-------------|-----------|----:|-----------|-------:|---------------:|
| 40458664 | 4 Sep 18:35 | $101 | 5 Sep 07:00 | $10.80 | **-5** |
| 40458816 | 4 Sep 18:54 | $101 | 5 Sep 07:00 | $10.41 | **-5** |
| 40458957 | 4 Sep 19:13 | $505 | 5 Sep 11:02 | $0.00 | **-6** |

**$150 paid.** Factory-line registration timing. All accounts dead.

---

### A.3 — High-Volume Premium Mill ($200/ref)

**Referrer CID 39556505** (Germany, Silver club)
- Registered 23 May 2024, deposited $100, traded for **4 days**, equity $0.94
- Earned **$2,000** (10 × $200 Gold/Plat rate)
- All 10 invitees from Germany, all deposited exactly **$100**, all made **1 trade**:

| Invitee CID | Registered | FTD | Trades | Last Trade | Equity |
|-------------|-----------|----:|-------:|-----------|-------:|
| 39640359 | 25 May 17:00 | $100 | 1 | 28 May | $10.63 |
| 39640457 | 25 May 17:16 | $100 | 1 | 27 May | $0.42 |
| 39637704 | 25 May 09:55 | $100 | 1 | 27 May | $0.10 |
| 39661933 | 27 May 10:57 | $100 | 1 | 27 May | $0.36 |
| 39661972 | 27 May 11:05 | $100 | 1 | 27 May | $0.75 |
| 39665503 | 27 May 20:12 | $100 | 1 | 27 May | $0.11 |
| 39675466 | 28 May 10:39 | $100 | 1 | 28 May | $0.72 |
| 39675623 | 28 May 11:05 | $100 | 1 | 28 May | $0.19 |
| 39778069 | 11 Jun 18:17 | $100 | 1 | 11 Jun | $0.44 |
| 39778178 | 11 Jun 18:35 | $100 | 1 | 11 Jun | $0.56 |

**$2,000 paid.** All 10 invitees deposited the minimum $100, made exactly 1 trade, never traded again. Several registered within minutes of each other. All 10 accounts have near-zero equity. **This passed through Gold tier with zero quality gates.**

---

### A.4 — High-Volume Default Mill ($50/ref)

**Referrer CID 39682105** (Switzerland, Bronze)
- Registered 29 May 2024, deposited $107, traded 19 days, equity $0
- Earned **$500** (10 × $50)
- **All 10 invitees registered on the same day** (29 May), with factory-line timing:

| Invitee CID | Registered | Time | FTD | Equity |
|-------------|-----------|------|----:|-------:|
| 39684063 | 29 May | 14:26 | $107 | $0.00 |
| 39684172 | 29 May | 14:41 | $107 | $0.00 |
| 39684536 | 29 May | 15:39 | $107 | $0.00 |
| 39684755 | 29 May | 16:13 | $107 | $0.00 |
| 39685015 | 29 May | 16:54 | $107 | $24.73 |
| 39685941 | 29 May | 19:21 | $107 | $0.00 |
| (+ 4 more in Jun) | | | ~$107–505 | $0.00 |

**$500 paid.** Assembly-line operation — 6 registrations in 5 hours, identical deposit amounts, 1 trade each, all dead. All "days active after comp" = **-7** (last trade was before compensation was even paid).

---

### A.5 — Zero Quality Mill (caught by system)

**Referrer CID 35258147** (Germany, 291 invitees, $0 comp)
- Mass registration generator. Sample of invitees:

| Invitee CID | Registered | Time Gap | FTD | Deposit | Funded 14d | Abuser Flag |
|-------------|-----------|---------|-----|---------|:---:|:---:|
| 36128627 | 28 Jan 13:43 | — | None | $0 | No | 0 |
| 36129562 | 28 Jan 15:25 | 1h 42m | None | $0 | No | 0 |
| 36129614 | 28 Jan 15:31 | 6 min | None | $0 | No | 0 |
| 36131466 | 28 Jan 18:37 | 3h 6m | None | $0 | No | 0 |
| 36131927 | 28 Jan 19:27 | 50 min | None | $0 | No | 0 |
| 36131936 | 28 Jan 19:28 | 1 min | None | $0 | No | 0 |
| 36131954 | 28 Jan 19:30 | 2 min | None | $0 | No | 0 |

**291 registration attempts, zero deposits, $0 earned.** The system correctly blocked all payouts. This is the fraud prevention working as intended — but note the `isAbuser = 0` flag despite obvious abuse patterns. The detection works via the "no FTD" gate, not via behavioral pattern recognition.

---

### Key Takeaway from Examples

The journey examples reveal a spectrum:

| Archetype | Comp/pair | Invitee Outcome | System Response |
|-----------|----------:|----------------|-----------------|
| A.1 Organic genuine | $50 | $27K–$52K equity, 650+ days active | **Paid — correct** |
| A.2 Small-batch fraud | $50 | $0 equity, 0 days active | **Paid — missed** |
| A.3 Premium mill | $200 | $0 equity, 0 days active | **Paid — missed** |
| A.4 Default mill | $50 | $0 equity, 0 days active | **Paid — missed** |
| A.5 Registration spam | $0 | No deposit | **Blocked — correct** |

The system catches the bottom (A.5: no deposit at all) but misses the middle (A.2--A.4: minimum deposit, 1 trade, abandon). Progressive payout would have saved 70% of comp in cases A.2--A.4 because none of those invitees were active at 30 days.

### Would these examples be blocked under today's rules?

All examples above are from 2024. As of 21 March 2026, the configuration has been verified against `bronze_rafcompensations_config_viewconfig` (latest `ValidFrom` entries). The answer is **mostly no**:

| Example | Tier | Current Rules (2025-2026) | Still paid today? |
|---------|------|--------------------------|:-:|
| A.1 Organic genuine | Default | 7-day wait, $50 min deposit, $100 min trade vol, 30-90 day check | **Yes (correct)** |
| A.2 Small-batch fraud | Default | Same as above | **Probably yes** -- invitees deposited $110-538 and opened 1 leveraged position (likely exceeds $100 notional) |
| A.3 Premium mill | Gold | **Zero quality gates** (min_deposit=NULL, min_trade=NULL, days_wait=NULL) | **Yes -- still no gates** |
| A.4 Default mill | Default | Same as A.2 | **Probably yes** -- $107 deposits, 1 trade |
| A.5 Registration spam | Default | FTD gate | **Still blocked (correct)** |

**Current live config (verified 21 Mar 2026):**

| Tier | Comp/ref | FraudScore | Wait | Min Deposit | Min Trade Vol | Trade Check Window | MaxComps |
|------|------:|:---:|:---:|------:|------:|:---:|:---:|
| Default | $50 | 0.95 | 7 days | $50 | $100 | 30-90 days | 10 |
| Gold | $200 | 0.95 | -- | -- | -- | -- | 10 |
| Platinum | $200 | 0.95 | -- | -- | -- | -- | 10 |
| Diamond | $500 | 0.95 | -- | -- | -- | -- | 50 |

The only change since the example period is **MaxComps reduced from 50 to 10** for Gold/Platinum (as of March 2026). This caps how many invitees a single referrer can farm, but each individual fraudulent pair still passes cleanly. The A.3 referrer (CID 39556505) had exactly 10 invitees -- even the new cap would not have stopped them.

**The "quality gates for all tiers" recommendation (#1 in Section 8) has not been implemented.** Extending the Default tier's existing gates ($50 min deposit, $100 min trade volume, 7-day wait) to Gold/Platinum/Diamond remains a config-only change that would immediately close the largest cost gap.

---

*Data sources: Databricks Unity Catalog (`main.experience`, `main.pii_data`, `main.general`), Synapse DWH (`BI_DB_dbo`, `DWH_dbo`), DataPlatform SSDT repo. All queries executed via MCP on 21 March 2026.*
