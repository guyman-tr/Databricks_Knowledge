# Canonical Query Patterns — RAF & Airdrops

Supplement to [`../raf-and-incentives.md`](../raf-and-incentives.md). No frontmatter — not validated by CI. Patterns A–E are standard RAF/airdrop patterns; F–G are the airdrop-to-position-to-campaign chain patterns added 2026-06-23.

---

## Pattern A — Total RAF cost last quarter (referrer + referee)

```sql
SELECT
  DATE_TRUNC('month', CompensationDate) AS month,
  ReferringRegulationName AS regulation,
  COUNT(*) AS n_referrals,
  SUM(ReferringCompensationAmount + ReferredCompensationAmount) AS total_cost_usd,
  SUM(ReferringCompensationAmount) AS referrer_cost_usd,
  SUM(ReferredCompensationAmount)  AS referee_cost_usd
FROM main.etoro_kpi.v_raf
WHERE RafStatusName = 'RafGiven'
  AND CompensationDate >= DATE_TRUNC('quarter', current_date) - INTERVAL 1 QUARTER
  AND CompensationDate <  DATE_TRUNC('quarter', current_date)
GROUP BY 1, 2
ORDER BY 1, 2
```

---

## Pattern B — Top RAF failure reasons by country

```sql
SELECT
  ReferringCountry,
  CASE
    WHEN RafStatusName LIKE '%FTDReferring%' THEN 'Referring FTD check'
    WHEN RafStatusName LIKE '%FTDReferred%'  THEN 'Referred FTD check'
    WHEN RafStatusName LIKE '%PositionsAmountReferring%' THEN 'Referring positions check'
    WHEN RafStatusName LIKE '%PositionsAmountReferred%'  THEN 'Referred positions check'
    WHEN RafStatusName LIKE '%RegistrationDateExpired%'  THEN 'Registration date expired'
    WHEN RafStatusName = 'Fraud'                THEN 'Fraud'
    WHEN RafStatusName = 'NoReferringConfig'    THEN 'No referring config'
    WHEN RafStatusName = 'NoDefaultReferredConfig' THEN 'No referred config'
    WHEN RafStatusName = 'LimitReached'         THEN 'Limit reached'
    WHEN RafStatusName = 'NoMoneyIsSetInConfig' THEN 'Config money is zero'
    WHEN RafStatusName = 'RafGiven'             THEN 'Success'
    ELSE 'Multi-reason'
  END AS reason_category,
  COUNT(*) AS n_referrals
FROM main.etoro_kpi.v_raf
GROUP BY 1, 2
ORDER BY 1, n_referrals DESC
LIMIT 100
```

---

## Pattern C — Per-country active RAF policy lookup

```sql
SELECT
  CountryName,
  RegulationName,
  LevelName,
  ReferringCompensationInDollar AS referrer_payout_usd,
  ReferredCompensationInDollar  AS referee_payout_usd,
  MaxNumberOfCompensations      AS max_per_referrer,
  DaysToWaitFromFTD,
  DaysToCheckMinPositionsAmountFromRegistration,
  FraudScore,
  ValidFrom
FROM main.etoro_kpi.v_raf_config
WHERE CountryName = 'United Kingdom'
ORDER BY ValidFrom DESC
LIMIT 10
```

---

## Pattern D — Airdrop conversion funnel last month

```sql
SELECT
  s.AirdropStatusName,
  COUNT(*) AS n_rows,
  COUNT(DISTINCT a.GCID) AS n_distinct_customers
FROM main.bi_db.bronze_marketperformance_airdrop_customer a
JOIN main.general.bronze_marketperformance_dictionary_airdropstatus s
  ON s.AirdropStatusID = a.AirdropStatusID
WHERE a.ValidFrom >= DATE_TRUNC('month', current_date) - INTERVAL 1 MONTH
  AND a.ValidFrom <  DATE_TRUNC('month', current_date)
GROUP BY 1
ORDER BY MIN(a.AirdropStatusID)
```

---

## Pattern E — Multi-reason RAF failure analysis (3+ bits set)

```sql
SELECT
  RafStatusName,
  LENGTH(RafStatusName) - LENGTH(REPLACE(RafStatusName, ',', '')) + 1 AS n_failure_atoms,
  COUNT(*) AS n_referrals
FROM main.etoro_kpi.v_raf
WHERE RafStatusName <> 'RafGiven'
  AND RafStatusName LIKE '%,%,%'
GROUP BY 1, 2
ORDER BY n_failure_atoms DESC, n_referrals DESC
LIMIT 30
```

---

## Pattern F — Full airdrop-to-position-to-campaign chain

Full chain-of-evidence: airdrop allocation → position execution → campaign attribution.

```sql
WITH airdrop_given AS (
  SELECT
    a.GCID, a.CID, a.ConfigurationID, a.AirdropPlanID,
    a.OfferTypeID, a.SelectedInstrumentID, a.Amount,
    a.AcceptedDate, a.PurchaseRequestDate, a.GivenDate,
    a.PositionRequestID
  FROM main.bi_db.bronze_marketperformance_airdrop_customer a
  WHERE a.AirdropStatusID = 4  -- Given
    AND a.GivenDate >= current_date() - INTERVAL 30 DAYS
)
SELECT
  -- Airdrop allocation
  ag.GCID,
  ag.CID,
  ag.SelectedInstrumentID,
  ag.Amount AS airdrop_amount_usd,
  ag.AcceptedDate,
  ag.GivenDate,
  -- Offer category (always join dictionary — never hardcode OfferTypeIDs)
  ot.OfferTypeName,
  plan_d.AirdropPlanName,
  -- Configuration rule
  cfg.RegulationID,
  cfg.CountryID,
  cfg.ExperimentVariationID,
  -- Position execution
  pal.PositionID,
  pal.ExecutionOccurred,
  pal.Result AS position_result,
  pal.AmountInUnits,
  pal.Rate AS execution_rate,
  pal.CompensationReasonID,
  cr.Name AS compensation_reason_name,  -- resolved via gold dim, never hardcoded
  -- Campaign attribution (from Mixpanel)
  mx.affiliateid_numeric,
  CASE
    WHEN ot.OfferTypeName = 'Affiliate' AND mx.affiliateid_numeric = 11 THEN 'RAF'
    WHEN ot.OfferTypeName = 'Affiliate' AND mx.affiliateid_numeric IS NOT NULL THEN 'Paid Affiliate'
    WHEN ot.OfferTypeName = 'Classic' THEN 'Retention (organic)'
    WHEN ot.OfferTypeName = 'AcademyLite' THEN 'Education (engagement)'
    ELSE 'Other / New Type'  -- catch-all: surfaces new offer types without silently dropping them
  END AS campaign_category
FROM airdrop_given ag
-- Offer type dictionary (always join — never hardcode OfferTypeIDs)
LEFT JOIN main.experience.bronze_marketperformance_dictionary_airdropoffertypes ot
  ON ot.OfferTypeID = ag.OfferTypeID
-- Plan dictionary
LEFT JOIN main.general.bronze_marketperformance_dictionary_airdropplan plan_d
  ON plan_d.AirdropPlanID = ag.AirdropPlanID
-- Configuration
LEFT JOIN main.general.bronze_marketperformance_airdrop_configuration cfg
  ON cfg.ConfigurationID = ag.ConfigurationID
-- Position execution: CID + Instrument + date proximity — this join IS the airdrop filter
LEFT JOIN main.trading.bronze_etoro_trade_positionairdroplog pal
  ON pal.CID = ag.CID
  AND pal.InstrumentID = ag.SelectedInstrumentID
  AND pal.etr_ymd >= DATE_FORMAT(current_date() - INTERVAL 30 DAYS, 'yyyy-MM-dd')
  AND pal.ExecutionOccurred BETWEEN ag.GivenDate - INTERVAL 2 DAYS AND ag.GivenDate + INTERVAL 2 DAYS
-- Compensation reason gold dim (always join for name — never hardcode IDs)
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason cr
  ON cr.CompensationReasonID = pal.CompensationReasonID
-- Mixpanel campaign attribution (de-duped to earliest event per GCID in window)
LEFT JOIN (
  SELECT
    CAST(mp_user_id AS INT) AS gcid,
    affiliateid_numeric,
    MIN(etr_ymd) AS event_date
  FROM main.mixpanel.silver
  WHERE mp_event_name = 'Airdrop Delivered BE'
    AND etr_ymd >= DATE_FORMAT(current_date() - INTERVAL 30 DAYS, 'yyyy-MM-dd')
  GROUP BY CAST(mp_user_id AS INT), affiliateid_numeric
) mx ON mx.gcid = ag.GCID
```

**Verified examples (2026-06-23):**
- Acquisition: GCID 46250350, OfferType=Affiliate, affiliateid=11 (RAF), PositionID=3417583877
- Retention: GCID 46912739, OfferType=Classic, affiliateid=NULL, PositionID=3427744265, ConfigID=379 (RegulationID=9, CountryID=199, ExperimentVariationID=11)

---

## Pattern G — Aggregate: airdrop volume by offer type × compensation reason

All dictionaries joined dynamically — no hardcoded IDs. New types and reason codes auto-appear in results as the product team adds them.

```sql
SELECT
  ot.OfferTypeName,
  plan_d.AirdropPlanName,
  pal.CompensationReasonID,
  cr.Name AS compensation_reason_name,
  COUNT(DISTINCT pal.PositionID) AS position_count,
  SUM(a.Amount) AS total_airdrop_amount_usd
FROM main.bi_db.bronze_marketperformance_airdrop_customer a
-- Always join dictionaries — never assume fixed values
LEFT JOIN main.experience.bronze_marketperformance_dictionary_airdropoffertypes ot
  ON ot.OfferTypeID = a.OfferTypeID
LEFT JOIN main.general.bronze_marketperformance_dictionary_airdropplan plan_d
  ON plan_d.AirdropPlanID = a.AirdropPlanID
-- Position bridge: the join itself IS the airdrop filter
LEFT JOIN main.trading.bronze_etoro_trade_positionairdroplog pal
  ON pal.CID = a.CID
  AND pal.InstrumentID = a.SelectedInstrumentID
  AND pal.etr_ymd >= DATE_FORMAT(current_date() - INTERVAL 60 DAYS, 'yyyy-MM-dd')
  AND pal.ExecutionOccurred BETWEEN a.GivenDate - INTERVAL 2 DAYS AND a.GivenDate + INTERVAL 2 DAYS
-- Compensation reason gold dim (dynamic — new reasons auto-appear in results)
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason cr
  ON cr.CompensationReasonID = pal.CompensationReasonID
WHERE a.AirdropStatusID = 4
  AND a.GivenDate >= current_date() - INTERVAL 60 DAYS
GROUP BY ot.OfferTypeName, plan_d.AirdropPlanName, pal.CompensationReasonID, cr.Name
ORDER BY position_count DESC
```

**Expected output — reason-code totals via the airdrop join (60-day, re-verified 2026-06-24 against the gold dim; new rows may appear as new types are added):**

| ReasonID | CompensationReasonName | Positions | Amount USD |
|---:|---|---:|---:|
| 138 | AirDrop NWA | 23,372 | $2,401,890 |
| 20 | Special Promotion | 5,546 | $775,640 |
| 94 | Promotion - Leads | 35 | $1,750 |
| 131 | Academy Lite | 27 | $270 |

**Key insight**: "AirDrop NWA" (ID=138) dominates at ~80% — NOT "Special Promotion" (ID=20, ~19%). ID=20 is a generic code reused for both airdrop and non-airdrop compensations — NOT a reliable airdrop-only filter. The airdrop-customer join surfaces ONLY these 4 codes; a **standalone** scan of `positionairdroplog` is instead dominated by non-airdrop comp (91=Staking ≫ 92=Promotion ≫ 76=Stock Dividend ≫ 58=Position Airdrop, all ahead of 138), which is exactly why the join — not a reason-code filter — defines "is this an airdrop position?". New compensation reasons may appear at any time; this pattern handles them via the gold-dim join (`dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason`).
