# eMoney_dbo.eMoney_Reports_AcquisitionFunnel

> 3.67M-row daily snapshot of verified eToro depositors in active eMoney markets, tracking their progression through 9 acquisition funnel stages — from eToro depositor status through eMoney account enrollment, first money-in (FMI), first money-out (FMO), card creation, card activation, and first card transaction. Refreshed daily by `SP_eMoney_Reports_Daily`; each row represents one customer (CID/GCID grain).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + eMoney_Dim_Account + eMoney_Panel_FirstDates + DWH_dbo.Fact_CustomerAction (via SP_eMoney_Reports_Daily) |
| **Refresh** | Daily — TRUNCATE + INSERT full refresh via SP_eMoney_Reports_Daily |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override strategy, daily) |

---

## 1. Business Meaning

`eMoney_Reports_AcquisitionFunnel` is the primary eToro Money acquisition analytics table. Each row represents one verified eToro depositor (IsVerifiedFTD=1) who lives in a country where eToro Money is live, tagged with a set of boolean indicators capturing their current eMoney funnel stage. As of 2026-04-12 there are **3,672,801** customer rows. The eligible population is restricted to: verified FTD customers, in active eMoney markets (from `eMoney_Dim_Country_Rollout`), with a valid customer status (PlayerStatusID NOT IN 2,4,14,15).

Key funnel metrics from live data:
- IsVerifiedFTDPlus2Weeks: 3,659,851 (99.6%) — nearly all depositors are 2+ weeks old
- IseMoneyAccount: 1,726,054 (47%) — roughly half have an eMoney account
- IsFMI: 1,201,484 (32.7%) — have completed First Money In
- IsFMO: 1,160,237 (31.6%) — have completed First Money Out
- IsActiveMIMO: 449,123 (12.2%) — active in last 91 days (MIMO actions 7 or 8)
- IsCardCreated: 89,823 (2.4%) — have an eToro Money card
- IsCardActivated: 26,079 (0.7%) — have activated their card
- IsCardFirstTx: 23,690 (0.6%) — have made a card transaction

Club distribution: Bronze 84%, Silver 5.9%, Gold 5.4%, Platinum 2.6%, Platinum Plus 1.9%, Diamond 0.2%.

---

## 2. Business Logic

### 2.1 Customer Eligibility Filter

**What**: Only verified depositors in active eToro Money markets are included.
**Columns Involved**: CID, GCID, Country
**Rules**:
- `IsDepositor = 1` — customer must have made a deposit
- `IsValidCustomer = 1` — active, non-deleted account
- `VerificationLevelID = 3` — fully KYC-verified
- `PlayerStatusID NOT IN (2, 4, 14, 15)` — excludes blocked, suspended, and specific restricted statuses
- INNER JOIN to `eMoney_Dim_Country_Rollout` — only customers in countries where eToro Money is live
- `IsVerifiedFTD` is always 1 by construction (all rows pass the depositor/verification filter)

### 2.2 Funnel Stage Logic (Boolean Flags)

**What**: Each flag represents the customer reaching a distinct eToro Money adoption milestone.
**Columns Involved**: IsValidForFunnel, IsVerifiedFTDPlus2Weeks, IsActiveMIMO, IseMoneyAccount, IsFMI, IsFMO, IsCardCreated, IsCardActivated, IsCardFirstTx
**Rules**:
- `IsValidForFunnel`: ISNULL(eMoney_Dim_Account.IsValidETM, 1). Defaults to 1 if customer has no eMoney account yet. 0 indicates an invalid eMoney enrollment (only 710 rows as of last refresh)
- `IsVerifiedFTDPlus2Weeks`: 1 if DATEDIFF(DAY, FirstDepositDate, yesterday) > 14. Measures 2-week post-FTD maturation
- `IsActiveMIMO`: 1 if customer performed a MIMO action (ActionTypeID 7 or 8) in Fact_CustomerAction within the last 91 days
- `IseMoneyAccount`: 1 if customer has a row in eMoney_Panel_FirstDates (has an active eMoney account)
- `IsFMI`: 1 if Panel_FirstDates.FMI_Date IS NOT NULL (received first settled incoming transfer)
- `IsFMO`: 1 if Panel_FirstDates.FMO_Date IS NOT NULL (made first settled outgoing transfer)
- `IsCardCreated`: 1 if eMoney_Dim_Account.CardCreateTime IS NOT NULL (card has been issued)
- `IsCardActivated`: 1 if Panel_FirstDates.CardActivationTime IS NOT NULL (card reached Active status)
- `IsCardFirstTx`: 1 if Panel_FirstDates.FirstCardSettledTXDate IS NOT NULL (first card spend)

### 2.3 Country Override

**What**: Country reflects the customer's registered eMoney country, not their eToro trading country.
**Columns Involved**: Country
**Rules**:
- `Country = ISNULL(eMoney_Dim_Account.RegCountry, eMoney_Dim_Country_Rollout.CountryName)`
- eMoney RegCountry (country at eMoney account creation) takes precedence
- Falls back to the rollout country name (from Dim_Customer.CountryID → eMoney_Dim_Country_Rollout) if no eMoney account exists

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution — optimal for joins to Dim_Customer and other CID-distributed tables. HEAP index is appropriate for a full-refresh analytical table. Avoid joins on GCID without including CID — GCID is not the distribution key.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Overall funnel conversion rates | `SELECT Country, SUM(IseMoneyAccount)*1.0/COUNT(*) AS pct_eMoney, SUM(IsFMI)*1.0/COUNT(*) AS pct_FMI ... GROUP BY Country` |
| Club-level funnel breakdown | `SELECT Club, SUM(IsFMI), SUM(IsFMO), SUM(IsCardFirstTx) FROM ... GROUP BY Club` |
| New customers not yet in funnel | `WHERE IseMoneyAccount = 0 AND IsVerifiedFTDPlus2Weeks = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Dim_Account | `eMoney_Dim_Account.GCID = eMoney_Reports_AcquisitionFunnel.GCID` | Enrich with account details, card type, balance |
| eMoney_Panel_FirstDates | `eMoney_Panel_FirstDates.CID = eMoney_Reports_AcquisitionFunnel.CID` | Enrich with first action dates and amounts |
| DWH_dbo.Dim_Customer | `Dim_Customer.RealCID = eMoney_Reports_AcquisitionFunnel.CID` | Add registration date, language, regulation |

### 3.4 Gotchas

- **IsVerifiedFTD is always 1** — all rows passed the filter; this column carries no analytical variance. It serves as a label to confirm funnel eligibility.
- **IsValidForFunnel ≠ IseMoneyAccount**: A customer can have IsValidForFunnel=1 with no eMoney account (defaults to 1 via ISNULL). IseMoneyAccount=1 means they have a Panel_FirstDates row.
- **Country may differ from eToro registration country**: Country here is the eMoney RegCountry (at eMoney enrollment), not the customer's current eToro trading country.
- **IsActiveMIMO uses a 91-day rolling window** (yesterday minus 91 days). The window is recalculated fresh each daily refresh.
- **IsCardCreated vs IsCardActivated**: IsCardCreated = card issued; IsCardActivated = card activated (status = 1). A card can be created but not activated (26K activated vs 90K created).
- **TRUNCATE changed from DELETE**: Changed by MaorTu on 2022-07-22 from DELETE to TRUNCATE for performance. This means no audit trail of previous run state.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki — production source confirmed, description inherited directly |
| Tier 2 | ETL-computed or derived — SP logic is the authoritative source of this column's value |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |
| 3 | Country | varchar(50) | YES | Customer's eMoney-registered country name. Derived as ISNULL(eMoney_Dim_Account.RegCountry, eMoney_Dim_Country_Rollout.CountryName) — eMoney account's registered country takes precedence over the current eToro trading country. Scoped to eMoney-eligible markets only. (Tier 2 — SP_eMoney_Reports_Daily) |
| 4 | Club | varchar(50) | YES | Customer's current eToro loyalty club tier at time of refresh. 6 values: Bronze=84%, Silver=5.9%, Gold=5.4%, Platinum=2.6%, Platinum Plus=1.9%, Diamond=0.2%. Sourced from DWH_dbo.Dim_PlayerLevel.Name. (Tier 2 — SP_eMoney_Reports_Daily) |
| 5 | IsValidForFunnel | int | YES | 1 if the customer is eligible for the eToro Money funnel, 0 if excluded. Derived from ISNULL(eMoney_Dim_Account.IsValidETM, 1). Defaults to 1 when no eMoney account exists (customer is potentially eligible). 0 indicates an invalid eMoney enrollment (710 rows = 0.02%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 6 | IsVerifiedFTD | int | YES | Always 1 — all rows in this table are verified eToro FTD depositors (IsDepositor=1, VerificationLevelID=3 filter applied during SP execution). Serves as an eligibility label confirming funnel entry criteria. (Tier 2 — SP_eMoney_Reports_Daily) |
| 7 | IsVerifiedFTDPlus2Weeks | int | YES | 1 if the customer's first deposit was more than 14 days ago (DATEDIFF(DAY, FirstDepositDate, yesterday) > 14). Measures 2-week post-FTD maturation used in some cohort definitions. 3,659,851 rows = 1 (99.6%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 8 | IsActiveMIMO | int | YES | 1 if the customer performed at least one MIMO action (ActionTypeID IN [7, 8] in DWH_dbo.Fact_CustomerAction) within the last 91 days (rolling window from yesterday). 449,123 rows = 1 (12.2%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 9 | IseMoneyAccount | int | YES | 1 if the customer has a row in eMoney_Panel_FirstDates (GCID IS NOT NULL after LEFT JOIN). Indicates the customer has an active eMoney account represented in the first-dates panel. 1,726,054 rows = 1 (47.0%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 10 | IsFMI | int | YES | 1 if the customer's FMI_Date IS NOT NULL in eMoney_Panel_FirstDates — they have received their first settled incoming eToro Money transfer (First Money In). 1,201,484 rows = 1 (32.7%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 11 | IsFMO | int | YES | 1 if the customer's FMO_Date IS NOT NULL in eMoney_Panel_FirstDates — they have made their first settled outgoing eToro Money transfer (First Money Out). 1,160,237 rows = 1 (31.6%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 12 | IsCardCreated | int | YES | 1 if eMoney_Dim_Account.CardCreateTime IS NOT NULL — an eToro Money physical or virtual card has been issued for this customer. 89,823 rows = 1 (2.4%). (Tier 2 — SP_eMoney_Reports_Daily) |
| 13 | IsCardActivated | int | YES | 1 if eMoney_Panel_FirstDates.CardActivationTime IS NOT NULL — the customer's card has reached Active status (CardStatusID=1). 26,079 rows = 1 (0.7%). Always ≤ IsCardCreated. (Tier 2 — SP_eMoney_Reports_Daily) |
| 14 | IsCardFirstTx | int | YES | 1 if eMoney_Panel_FirstDates.FirstCardSettledTXDate IS NOT NULL — the customer has made at least one settled card transaction. 23,690 rows = 1 (0.6%). The final stage of the card adoption funnel. (Tier 2 — SP_eMoney_Reports_Daily) |
| 15 | UpdateDate | datetime | YES | Timestamp of the most recent SP refresh. Set to GETDATE() at insert time; all rows share the same value per daily refresh. Last observed: 2026-04-12 06:45:41. (Tier 2 — SP_eMoney_Reports_Daily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename |
| GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| Country | eMoney_Dim_Account / eMoney_Dim_Country_Rollout | RegCountry / CountryName | ISNULL(RegCountry, CountryName) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough |
| IsValidForFunnel | eMoney_Dim_Account | IsValidETM | ISNULL(IsValidETM, 1) |
| IsVerifiedFTD | DWH_dbo.Dim_Customer | IsDepositor + VerificationLevelID | Hardcoded 1 for all qualifying rows |
| IsVerifiedFTDPlus2Weeks | DWH_dbo.Dim_Customer | FirstDepositDate | CASE DATEDIFF > 14 |
| IsActiveMIMO | DWH_dbo.Fact_CustomerAction | GCID / ActionTypeID | CASE WHEN action in (7,8) last 91d |
| IseMoneyAccount | eMoney_Panel_FirstDates | GCID | CASE WHEN GCID IS NOT NULL |
| IsFMI | eMoney_Panel_FirstDates | FMI_Date | CASE WHEN IS NOT NULL |
| IsFMO | eMoney_Panel_FirstDates | FMO_Date | CASE WHEN IS NOT NULL |
| IsCardCreated | eMoney_Dim_Account | CardCreateTime | CASE WHEN IS NOT NULL |
| IsCardActivated | eMoney_Panel_FirstDates | CardActivationTime | CASE WHEN IS NOT NULL |
| IsCardFirstTx | eMoney_Panel_FirstDates | FirstCardSettledTXDate | CASE WHEN IS NOT NULL |
| UpdateDate | SP_eMoney_Reports_Daily | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3, PlayerStatusID filter)
  + INNER JOIN eMoney_Dim_Country_Rollout (CountryID → active eMoney markets only)
  + INNER JOIN DWH_dbo.Dim_PlayerLevel (Club name)
  + DWH_dbo.Fact_CustomerAction (ActionTypeID IN [7,8], last 91d → IsActiveMIMO)
  + LEFT JOIN eMoney_Dim_Account (RegCountry, IsValidETM, CardCreateTime)
  + LEFT JOIN eMoney_Panel_FirstDates (FMI/FMO dates, CardActivationTime, FirstCardSettledTXDate)
    |-- SP_eMoney_Reports_Daily Steps 1-4 (TRUNCATE + INSERT, daily) ---|
    v
eMoney_dbo.eMoney_Reports_AcquisitionFunnel (3,672,801 rows, HASH(CID) HEAP)
    |-- Generic Pipeline (Override, delta, daily) ---|
    v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Source customer dimension (RealCID) |
| GCID | DWH_dbo.Dim_Customer | Source customer global ID |
| Country | eMoney_Dim_Country_Rollout | Country name fallback via CountryID filter |
| Club | DWH_dbo.Dim_PlayerLevel | Club display name |
| IsActiveMIMO | DWH_dbo.Fact_CustomerAction | MIMO activity signal (ActionTypeID 7,8) |
| IseMoneyAccount / IsFMI / IsFMO / IsCardActivated / IsCardFirstTx | eMoney_Panel_FirstDates | First dates signals |
| IsValidForFunnel / IsCardCreated | eMoney_Dim_Account | Account validity and card creation signal |

### 6.2 Referenced By

| Object | Join Column | Description |
|--------|------------|-------------|
| eMoney_Reports_AcquisitionFunnelAggregated | Derived | Aggregated by Country+Club from this table's intermediate result in SP |

---

## 7. Sample Queries

### Funnel conversion by country (top 10)

```sql
SELECT Country,
       COUNT(*) AS eligible_customers,
       SUM(IseMoneyAccount)*100.0/COUNT(*) AS pct_eMoney_enrolled,
       SUM(IsFMI)*100.0/COUNT(*) AS pct_FMI,
       SUM(IsCardFirstTx)*100.0/COUNT(*) AS pct_card_tx
FROM [eMoney_dbo].[eMoney_Reports_AcquisitionFunnel]
GROUP BY Country
ORDER BY eligible_customers DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### Club-level card adoption

```sql
SELECT Club,
       COUNT(*) AS total,
       SUM(IsCardCreated) AS card_created,
       SUM(IsCardActivated) AS card_activated,
       SUM(IsCardFirstTx) AS card_transacted
FROM [eMoney_dbo].[eMoney_Reports_AcquisitionFunnel]
GROUP BY Club
ORDER BY total DESC;
```

### Customers with eMoney account but no FMI (stalled at enrollment)

```sql
SELECT CID, GCID, Country, Club
FROM [eMoney_dbo].[eMoney_Reports_AcquisitionFunnel]
WHERE IseMoneyAccount = 1 AND IsFMI = 0;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-21 | Quality: 8.9/10 | Phases: 13/14*
*Tiers: 2 T1, 13 T2, 0 T3, 0 T4, 0 T5 | Elements: 15/15, Logic: 9/10, Completeness: 9/10*
*Object: eMoney_dbo.eMoney_Reports_AcquisitionFunnel | Type: Table | Production Source: DWH_dbo.Dim_Customer + eMoney_Dim_Account + eMoney_Panel_FirstDates (SP_eMoney_Reports_Daily)*
