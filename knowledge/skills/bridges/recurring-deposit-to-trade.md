---
name: bridge-recurring-deposit-to-trade
description: |
  Connects a customer's deposit cadence (especially recurring/auto-deposit
  plans) to the trades they subsequently open. The classic eToro funnel
  story — "deposit happened → first position opened within N days" —
  including FTD-to-FT and recurring-cadence-driving-volume analysis.
  Bridges Payments C.1 (Deposits) and the Trading super-domain.
keywords: [deposit to trade, FTD to FT, first time funded to first trade,
           recurring deposit, IsRecurring, recurring investment, auto-deposit,
           cadence, deposit funnel, time-to-first-trade, deposit-driven volume,
           bronze_recurringinvestment]
load_after: [_router.md]
connects:
  - payments/deposits-and-withdrawals
  - payments/mimo-panel-and-ddr
  # - trading/SKILL  (planned)
intersects_with:
  - revenue-and-fees/SKILL
primary_objects:
  - DWH_dbo.Fact_BillingDeposit
  - DWH_dbo.Dim_Customer
  - DWH_dbo.Fact_CustomerAction
  - DWH_dbo.Dim_Position
  - BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms
  - BI_DB_dbo.BI_DB_First5Actions
  - general.bronze_recurringinvestment_recurringinvestment_planinstances
  - etoro_kpi_prep.v_fact_customeraction_w_metrics
---

# Bridge — Recurring Deposit → Trade

The flagship eToro funnel story. A customer deposits — sometimes once,
sometimes on a recurring plan — and then opens trading positions. This
bridge captures the join from the deposit (C.1 / C.2) to the resulting
trade (Trading) and answers "how often did the deposit lead to a trade,
and how soon."

## The chain

```mermaid
graph LR
    Plan[Recurring plan defined<br/>bronze_recurringinvestment_planinstances]
    Dep[Deposit row<br/>Fact_BillingDeposit<br/>IsRecurring = 1]
    DepMimo[MIMO row<br/>BI_DB_DDR_Fact_MIMO_AllPlatforms<br/>IsRecurring = 1]
    Cust[Customer<br/>Dim_Customer<br/>FTDDate / FirstTradeDate]
    Action[Trading action<br/>Fact_CustomerAction<br/>ActionTypeID open]
    Pos[Position opened<br/>Dim_Position]
    First5[BI_DB_First5Actions<br/>first 5 distinct actions per CID]

    Plan --> Dep --> DepMimo
    Dep --> Cust
    Cust -.FTD.-> Action --> Pos
    Cust --> First5
```

## Anchor patterns

There are 3 layers depending on what you need:

1. **`Dim_Customer.FTDDate` and `Dim_Customer.FirstTradeDate`** — already-computed canonical "first deposit date" and "first trade date" per CID. For *FTD-to-FT funnel* analysis at scale, USE THESE — don't re-derive.
2. **`BI_DB_dbo.BI_DB_First5Actions`** — first 5 distinct customer actions per CID (e.g. registration, KYC, FTD, first deposit on TP, first trade). Useful for "what was action #2 / action #3" funnel questions.
3. **`general.bronze_recurringinvestment_recurringinvestment_planinstances`** *(UC bronze)* — the recurring-plan definitions. Each row = one customer's recurring investment plan instance with cadence, instrument, amount.
4. **`etoro_kpi_prep.v_fact_customeraction_w_metrics`** *(UC view)* — already JOINS `Fact_CustomerAction` + recurring plan instances + position data + fee revenue. **This is the pre-stitched bridge view.** Use it for cohort-level "deposit → trade" analysis.

## Canonical patterns

```sql
-- 1. FTD-to-FT funnel (TIME from first deposit to first trade), already-computed dates
SELECT
  DATEDIFF(day, dc.FTDDate, dc.FirstTradeDate) AS days_ftd_to_ft,
  COUNT(*) AS customers
FROM DWH_dbo.Dim_Customer dc
WHERE dc.FTDDate BETWEEN @from AND @to
  AND dc.FirstTradeDate IS NOT NULL
GROUP BY DATEDIFF(day, dc.FTDDate, dc.FirstTradeDate)
ORDER BY days_ftd_to_ft
```

```sql
-- 2. Recurring-plan subscribers and whether they traded in the next N days
SELECT
  rp.CID,
  rp.PlanInstanceID,
  rp.Cadence,
  rp.PlannedAmount,
  rp.PlannedInstrument,
  MIN(fbd.ModificationDate) AS first_deposit_under_plan,
  MIN(fca.ActionDate)        AS first_trade_after_plan
FROM general.bronze_recurringinvestment_recurringinvestment_planinstances rp
JOIN DWH_dbo.Fact_BillingDeposit fbd
       ON fbd.CID = rp.CID
      AND fbd.IsRecurring = 1
      AND fbd.PaymentStatusID = 2
LEFT JOIN DWH_dbo.Fact_CustomerAction fca
       ON fca.CID = rp.CID
      AND fca.ActionTypeID IN (/* trade-open action codes */ 1, 2, 5)
      AND fca.ActionDate >= fbd.ModificationDate
      AND fca.ActionDate < DATEADD(day, @window_days, fbd.ModificationDate)
WHERE rp.PlanCreatedDate BETWEEN @from AND @to
GROUP BY rp.CID, rp.PlanInstanceID, rp.Cadence, rp.PlannedAmount, rp.PlannedInstrument
```

```sql
-- 3. Use the pre-stitched view for cohort-level analysis
SELECT *
FROM etoro_kpi_prep.v_fact_customeraction_w_metrics
WHERE DateID BETWEEN @from AND @to
  AND CID = @cid
```

```sql
-- 4. "What was action #N for this customer" using First5
SELECT *
FROM BI_DB_dbo.BI_DB_First5Actions
WHERE CID = @cid
ORDER BY ActionOrdinal
```

## Gotchas

1. **`Dim_Customer.FTDDate` is the source of truth for first-time-deposit-date.** Don't compute `MIN(ModificationDate)` from `Fact_BillingDeposit` — there are bad-FTD exclusions and timezone normalisations baked in.
2. **`FirstTradeDate` excludes practice / virtual mode.** It's the first REAL-money trade.
3. **Recurring plans can be paused/canceled.** `bronze_recurringinvestment_planinstances` has lifecycle status — filter for active or use lifecycle dates appropriately.
4. **`IsRecurring = 1` on `Fact_BillingDeposit` marks the DEPOSIT as initiated by a recurring plan.** It does NOT mean the customer has a plan currently active. A plan can have ended, but the past deposits still carry `IsRecurring = 1`.
5. **For cross-platform "deposit then trade" go to MIMO** — `BI_DB_DDR_Fact_MIMO_AllPlatforms` has `IsRecurring`, plus an FTD framing already (`IsGlobalFTD`). The trade side still needs `Fact_CustomerAction` / `Dim_Position`.
6. **Trading-side action codes** (`ActionTypeID`) — see `DWH_dbo.Dim_ActionType` for the full enum. Open-position codes vary by platform (CFD vs stocks vs crypto wallet purchase). Filter carefully.
7. **`v_fact_customeraction_w_metrics` is an UC view** that already does the joining. Prefer it over manual JOINs unless the query is purely Synapse-side.
8. **Time window matters.** "Trade within N days of deposit" — N=1 (intraday), N=7 (weekly), N=30 (monthly) are common bands. The funnel result changes dramatically with N; pick deliberately.

## Common questions this bridge answers

- "What % of FTDs trade within their first 7 days?"
- "For customers on a recurring deposit plan, how does cadence ($50/wk vs $200/mo) affect first-position size?"
- "Show me CIDs whose only trade ever was within 24h of FTD" (likely indication of a quick-loss cohort)
- "Of customers who set up recurring deposits in Q1, how many were still active by end of Q3?"

## When to load just one parent instead

- "Recurring-deposit count this month" alone → C.1 / C.2 alone.
- "First-trade volume by cohort" alone → Trading alone (using `Dim_Customer.FirstTradeDate`).
- "Both: did the deposit lead to a trade" → load this bridge.
