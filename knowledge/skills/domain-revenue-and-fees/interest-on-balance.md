---
name: domain-revenue-and-fees
description: |
  Interest on Balance (IOB) — eToro's treasury-yield revenue stream where
  customer cash sitting on the platform is put to work in money-market /
  treasury counterparties, eToro earns the gross market rate, pays the
  customer a tiered IOB rate, and keeps the spread as net revenue. NOT a
  cost line — this is a material revenue stream and economically the closest
  cousin to staking (gross / RevShare / net split). Covers the consent
  layer (`bronze_interest_trade_interestconsent`, ConsentStatusID 1=opted-in
  / 2=opted-out / absent=never-eligible-treated-as-opt-out, SCD-style on
  ValidFrom / ValidTo with `9999-12-31T23:59:59.990Z` sentinel for current
  state), the per-customer payment fact (`fact_customeraction` rows where
  `ActionTypeID = 36 AND CompensationReasonID = 57`, partition `etr_ymd`
  INT YYYYMMDD), and the explicit gap that the GROSS treasury yield (and
  therefore eToro's net IOB revenue) lives in Finance Excel today and is
  NOT yet in Unity Catalog — surface this gap on every revenue-side
  question. Load when users ask about Interest on Balance, IOB, interest
  paid to customers, the IOB consent table, ActionTypeID=36 +
  CompensationReasonID=57, IOB opt-in / opt-out, treasury yield on
  customer balances, or how IOB net revenue is computed.
triggers:
  - Interest on Balance
  - IOB
  - interest on balance
  - interest paid to customers
  - interest on cash
  - cash interest
  - balance interest
  - interestconsent
  - bronze_interest_trade_interestconsent
  - ConsentStatusID
  - opted in IOB
  - opted out IOB
  - IOB opt-in
  - IOB opt-out
  - IOB consent
  - IOB eligibility
  - ActionTypeID 36 CompensationReasonID 57
  - CompensationReasonID = 57
  - treasury yield
  - treasury revenue
  - net IOB
  - gross IOB
  - IOB rate
  - IOB tier
  - IOB club rate
required_tables:
  - main.bi_db.bronze_interest_trade_interestconsent
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
  - main.general.bronze_etoro_history_credit
intersects_with:
  - domain-revenue-and-fees/SKILL.md           # the revenue super-domain hub; CompensationReasonID 57 must be added to its reference table
  - domain-revenue-and-fees/fees-misc-dormant-options-interest.md  # legacy InterestFee (margin-interest charged TO customers) lives here — IOB is its inverse
  - domain-staking/SKILL.md                    # economic twin: gross / RevShare-by-club / net split
  - domain-staking/rewards-formula-and-calculation.md  # canonical pattern for "gross then split by tier" (Raw_Staking_Amount → Client_Airdrop / Etoro_Amount)
  - domain-customer-and-identity/customer-populations-and-lifecycle.md  # already references first-IOB as an FTF FirstAction signal — should now point here
out_of_scope:
  - InterestFee (the deprecated margin interest CHARGED TO customers on borrowed positions, post-Jul-2023 ~zero) — see fees-misc-dormant-options-interest.md
  - Staking rewards economics (same gross/net shape, different pipeline) — see domain-staking
  - Rollover / overnight financing fees — see trading-revenue-and-fees.md
  - Customer-facing IOB rate calibration / product policy — owned by Finance, NOT in UC
  - eToro treasury investment policy / counterparty selection — owned by Finance, NOT in UC
version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-11"
---

# Interest on Balance (IOB)

> **Tier 0 — Why this lives in revenue-and-fees, not in payments or customer-economics.**
> IOB is a **net revenue stream for eToro**, not a customer benefit we
> simply pay out. Customer cash sitting on the platform is put to work
> with treasury / money-market counterparties. eToro earns the gross
> market interest, pays the customer a tiered rate (IOB), and keeps the
> spread.
>
> Worked example — illustrative numbers, not the actual rates:
> - Gross treasury yield eToro earns: **5%**
> - IOB rate paid to the customer: **3%**
> - eToro net IOB revenue: **2%**
>
> Economically this is the **closest cousin to staking** (see
> `../domain-staking/rewards-formula-and-calculation.md` — `Raw_Staking_Amount`
> = gross, `Client_Airdrop` = customer share via `RevShare`, `Etoro_Amount`
> = eToro keeps). The mechanics differ (treasury counterparties vs
> on-chain validators) but the revenue shape is identical.
>
> **Source-of-truth gap (acknowledge on every revenue-side question).** Today UC
> only carries the **NET** half — what we paid the customer
> (`fact_customeraction` rows with `ActionTypeID = 36 / CompensationReasonID = 57`).
> The **GROSS** treasury yield (and therefore eToro's net IOB revenue)
> lives in **Finance Excel**, calibrated daily based on (a) the prevailing
> market interest rate, (b) IOB eligibility, and (c) the customer's club
> tier. The bronze SharePoint→UC pipeline that would land this feed in
> Unity Catalog is **not yet built**. When that lands, this skill should
> grow a "Net IOB revenue" canonical SQL block that joins paid-out IOB
> (gross down) against the gross-yield feed; until then, every
> revenue-side answer must say "net IOB revenue is not yet available in
> UC — Finance owns it in Excel."

## When to Use

Load this skill when the user asks about:
- "Interest on Balance" / "IOB" / "interest paid on cash" / "balance interest"
- The IOB **consent** layer: who opted in, who opted out, the SCD-style `bronze_interest_trade_interestconsent` table
- The IOB **payment** layer: per-customer IOB amounts, `ActionTypeID = 36 + CompensationReasonID = 57`
- IOB **eligibility** rules (consent + club + jurisdictional rules — partly captured in consent + club, partly external)
- The relationship between IOB and **club tier** (the IOB rate is club-tiered, mirroring the staking RevShare ladder)
- **Net IOB revenue** for eToro (gross treasury yield minus paid IOB) — even though the gross side isn't in UC yet, users ask this and we must respond with the gap acknowledgement, not silence
- First-IOB as the **FTF FirstAction** signal (already used in `customer-populations-and-lifecycle.md`)
- The contrast with the deprecated `InterestFee` (which is charged TO customers, the polar opposite of IOB)

## Scope

**In scope:** the consent table semantics (`bronze_interest_trade_interestconsent` — SCD on `ValidFrom` / `ValidTo`, ConsentStatusID 1/2/absent, current-state filter pattern); the payment fact rows on `fact_customeraction` (`ActionTypeID = 36 AND CompensationReasonID = 57`); the secondary `bronze_etoro_history_credit` source for IOB credits; the gross-vs-net economics framing; the explicit acknowledgement that gross treasury yield is in Finance Excel and not yet in UC; routing pointers to staking (economic twin) and to the deprecated `InterestFee` (semantic opposite).

**Out of scope:**
- `InterestFee` (deprecated margin interest charged TO customers) → `fees-misc-dormant-options-interest.md`
- Staking rewards (different pipeline, same economic shape) → `domain-staking`
- Rollover / overnight financing → `trading-revenue-and-fees.md`
- IOB product / commercial policy (rate setting, market positioning) → owned by Finance and Product, not in UC
- Treasury counterparty selection / investment policy → owned by Finance, not in UC

Last verified: 2026-06-11

## Critical Warnings

### Tier 1 — Silent wrong numbers

1. **`fact_customeraction.etr_ymd` is INT `YYYYMMDD`, NOT a string and NOT a date.** Filtering with `etr_ymd >= '2026-01-01'` (string), `etr_ymd >= DATE '2026-01-01'`, or `etr_ymd = 20260101.0` either fails or silently mis-matches. Use INT literals: `etr_ymd >= 20260101`. This is the opposite of EXW's `etr_ymd` (which is STRING `'YYYY-MM-DD'`) — corpus-wide landmine, easy to invert when context-switching between domains.
2. **`Amount` on the IOB row is what the CUSTOMER receives — it is the NET-PAID side, not eToro's revenue.** Do not call `SUM(Amount)` "IOB revenue". It is "IOB paid to customers" / "IOB cost of revenue" / "the GROSS-DOWN side of the spread". eToro's actual IOB revenue is the gross treasury yield MINUS this paid-out amount, and the gross side lives in Finance Excel (see Tier 0 callout). Mislabelling this number as revenue is the most common IOB analytical mistake.
3. **Customers absent from `bronze_interest_trade_interestconsent` are NOT opted-in by default — they are NEVER ELIGIBLE.** The semantic is three-valued: ConsentStatusID = 1 (opted in), ConsentStatusID = 2 (opted out), or row absent (never offered IOB → treated as opted out). Joining customers to consent with an `INNER JOIN` and assuming "no row = opted in" silently misclassifies the entire never-eligible cohort. Always `LEFT JOIN` and treat NULL ConsentStatusID as opted out.
4. **The current-state filter is `ValidTo = '9999-12-31T23:59:59.990Z'`, NOT `ValidTo IS NULL`.** The high-date sentinel is a string-formatted timestamp with millisecond precision and a trailing `Z`. Filtering on `ValidTo > current_timestamp()` works but is wasteful; filtering on `IS NULL` returns zero rows. Use the exact sentinel literal.

### Tier 2 — Aggregate / interpretation

5. **`bronze_interest_trade_interestconsent` is SCD-style — one customer can appear in multiple rows over time.** Without a current-state filter, `COUNT(DISTINCT CID)` over the full table double-counts every customer who ever toggled their consent. For point-in-time consent, walk `ValidFrom <= @asOf AND ValidTo >= @asOf`. For current state, use the `9999-12-31` sentinel.
6. **`CompensationReasonID = 57` is one row in a wide enum.** The same `ActionTypeID = 36` carries DormantFee (CRID 30), AdminFee (117), SpotAdjustFee (118), ShareLending (119), Affiliate Payments (41, 51), and others. Forgetting the `CompensationReasonID = 57` filter inflates IOB paid-out by 2–3 orders of magnitude. Always pair the two filters.
7. **First-IOB is one of the three FTF "FirstAction" components** (along with first trade in `Dim_Position` and first options trade) — see `domain-customer-and-identity/customer-populations-and-lifecycle.md` for the full FTF formula. When that skill loads alongside this one, the IOB action is a funnel signal; when this skill loads alone, IOB is a revenue topic. Don't conflate the two lenses.

### Tier 3 — Operational / dependencies

8. **Net IOB revenue is not yet computable in UC.** The gross treasury yield eToro earns sits in a Finance-managed Excel calibrated daily on (a) market interest rate, (b) eligibility, (c) club tier. A SharePoint → bronze UC ingest is on the roadmap but not yet built. Until then: every revenue-side answer must surface the gap. Do not estimate the spread from public market rates — Finance's effective gross yield is the only authoritative source.
9. **`bronze_etoro_history_credit` is a secondary IOB source.** Filter `CompensationReasonID = 57` (no ActionTypeID column required there). Cross-checking it against `fact_customeraction` is a useful reconciliation when amounts disagree, but the canonical UC fact for IOB paid out is `fact_customeraction`.

## Core Concepts

| Concept | What it is | Aliases |
|---|---|---|
| **IOB** | Interest on Balance — interest paid to customers on idle cash on platform | Interest on cash, balance interest |
| **Gross treasury yield** | What eToro earns from treasury / MM counterparties on customer cash. **Not in UC.** Finance Excel only. | Gross yield, treasury rate |
| **Net IOB revenue** | Gross treasury yield − IOB paid to customers. eToro's actual revenue from IOB. **Not in UC** until the gross feed lands. | IOB net revenue, IOB spread, eToro IOB margin |
| **IOB rate** | Customer-facing rate, calibrated by Finance daily on (market rate × eligibility × club tier). External Excel input today. | IOB tier rate, club IOB rate |
| **IOB consent** | Customer-level opt-in / opt-out flag carried in `bronze_interest_trade_interestconsent` | InterestConsent, IOB opt-in |
| **IOB payment row** | A row in `fact_customeraction` where `ActionTypeID = 36 AND CompensationReasonID = 57`. The `Amount` is what the customer received. | IOB credit, IOB paid out |
| **Never-eligible** | A customer with no row in the consent table at all — treated as opted out for analysis | "no consent row", "absent" |
| **Current-state sentinel** | The literal `'9999-12-31T23:59:59.990Z'` — `ValidTo` for the active row | High-date sentinel |

## Source tables

### Consent (eligibility / opt-in tracking)

`main.bi_db.bronze_interest_trade_interestconsent` — SCD-style, one row per (CID, consent-window).

| Column | Type | Description |
|---|---|---|
| `CID` | INT | Customer ID |
| `GCID` | INT | Global Customer ID |
| `ConsentStatusID` | INT | 1 = Opted In, 2 = Opted Out |
| `ValidFrom` | TIMESTAMP | When this consent status became effective |
| `ValidTo` | TIMESTAMP | When this status ended; `'9999-12-31T23:59:59.990Z'` = currently active |

### Payments (per-customer IOB paid out — the NET-PAID side)

`main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` filtered with `ActionTypeID = 36 AND CompensationReasonID = 57`.

| Column | Alias | Description |
|---|---|---|
| `RealCID` | CID | Customer ID |
| `GCID` | GCID | Global Customer ID |
| `Occurred` | DateTimePaid | Timestamp the IOB credit was made |
| `Amount` | IOB_Paid | The customer-side IOB amount (NET PAID, not revenue) |
| `CreditID` | CreditID | Unique identifier for the credit |
| `Description` | Description | Free text describing the payment |
| `etr_ymd` | — | Partition key — INT `YYYYMMDD`. Always filter on this. |

### Secondary / reconciliation source

`main.general.bronze_etoro_history_credit` — also carries IOB credits. Filter `CompensationReasonID = 57`. Useful for cross-check, not the canonical analytical surface.

### Future feed — NOT YET IN UC

The gross treasury yield (and therefore the per-day eToro IOB revenue) is currently maintained in **Finance Excel**, calibrated daily on:

1. **Market interest rate** — the prevailing rate eToro earns from its treasury counterparties.
2. **Eligibility** — only opted-in, eligible customers contribute to the gross yield base.
3. **Club tier** — the customer-paid IOB rate is tiered by club (analogous to staking's club RevShare).

A SharePoint → bronze UC ingest is on the roadmap. When the feed lands, this skill should grow a canonical SQL block that joins the paid-out side (this skill) against the gross-yield feed and produces **net IOB revenue per day**. Until then, **every revenue-side answer must surface the gap** rather than silently produce a paid-out total and call it revenue.

## Query patterns

### Currently opted-in users

```sql
SELECT CID, GCID, ValidFrom
FROM main.bi_db.bronze_interest_trade_interestconsent
WHERE ConsentStatusID = 1
  AND ValidTo = '9999-12-31T23:59:59.990Z';
```

### Currently opted-out users (explicit)

```sql
SELECT CID, GCID, ValidFrom
FROM main.bi_db.bronze_interest_trade_interestconsent
WHERE ConsentStatusID = 2
  AND ValidTo = '9999-12-31T23:59:59.990Z';
```

### Resolve IOB status for an arbitrary customer cohort (LEFT JOIN — never-eligible classified as opted out)

```sql
SELECT
  u.CID,
  CASE
    WHEN c.ConsentStatusID = 1 THEN 'Opted In'
    WHEN c.ConsentStatusID = 2 THEN 'Opted Out'
    ELSE 'Never Eligible (Opted Out)'
  END AS iob_status
FROM <user_cohort> u
LEFT JOIN main.bi_db.bronze_interest_trade_interestconsent c
  ON u.CID = c.CID
 AND c.ValidTo = '9999-12-31T23:59:59.990Z';
```

### IOB paid out — date range

```sql
SELECT
  RealCID                AS CID,
  GCID,
  Occurred               AS DateTimePaid,
  Amount                 AS IOB_Paid,
  CreditID,
  Description
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 36
  AND CompensationReasonID = 57
  AND etr_ymd >= 20260101
  AND etr_ymd <  20260201;
```

### Total IOB paid out per customer — calendar year

```sql
SELECT
  RealCID                  AS CID,
  GCID,
  SUM(Amount)              AS total_iob_paid,   -- NET-PAID side, NOT eToro revenue
  COUNT(*)                 AS payment_count,
  MIN(Occurred)            AS first_iob_paid,
  MAX(Occurred)            AS latest_iob_paid
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
WHERE ActionTypeID = 36
  AND CompensationReasonID = 57
  AND etr_ymd >= 20260101
GROUP BY RealCID, GCID;
```

### Net IOB revenue — TBD until gross-yield feed lands

```sql
-- TBD: requires the Finance gross-yield feed (currently Excel; SharePoint→UC pipeline pending).
-- When that table lands, the canonical pattern is:
--
-- WITH paid_out AS (
--   SELECT etr_ymd, SUM(Amount) AS iob_paid_to_customers
--   FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
--   WHERE ActionTypeID = 36 AND CompensationReasonID = 57
--   GROUP BY etr_ymd
-- ),
-- gross AS (
--   SELECT etr_ymd, gross_treasury_yield_usd
--   FROM <future_finance_feed>
-- )
-- SELECT
--   g.etr_ymd,
--   g.gross_treasury_yield_usd                        AS gross_iob_revenue,
--   COALESCE(p.iob_paid_to_customers, 0)              AS iob_paid_to_customers,
--   g.gross_treasury_yield_usd
--     - COALESCE(p.iob_paid_to_customers, 0)          AS net_iob_revenue
-- FROM gross g LEFT JOIN paid_out p USING (etr_ymd);
```

## Routing

- **Deprecated `InterestFee`** (margin interest charged TO customers, NOT the same thing as IOB) → `fees-misc-dormant-options-interest.md`. Mention the contrast in any answer that risks ambiguity.
- **Staking** — economic twin (gross / RevShare / net split). The mechanics differ but the revenue shape is identical. → `../domain-staking/rewards-formula-and-calculation.md`.
- **First-IOB as FTF signal** → `../domain-customer-and-identity/customer-populations-and-lifecycle.md` already references this; that skill owns the funnel lens, this skill owns the revenue lens.
- **Revenue super-domain hub** → `./SKILL.md` — the `CompensationReasonID` reference table there should list `57 = InterestOnBalance (IOB)` alongside 30 / 117 / 118 / 119.

## Provenance / verification

- **Customer-supplied source** (uploaded 2026-06-11): the consent and payment definitions in this skill are taken verbatim from the user's IOB SKILL.md request, validated against the existing corpus.
- **Cross-checked** against `domain-customer-and-identity/customer-populations-and-lifecycle.md` (which already references `ActionTypeID = 36 / CompensationReasonID = 57` as the first-IOB signal — corroborates the filter).
- **Cross-checked** against `domain-revenue-and-fees/SKILL.md` `CompensationReasonID` table (lists 30, 117, 118, 119 — gap: 57 not yet listed; fix in a sibling commit).
- **Gross-yield economics** captured from the user 2026-06-11: rate set in Finance Excel daily on (market rate × eligibility × club tier); SharePoint→UC ingest pending; net revenue currently NOT in UC.
