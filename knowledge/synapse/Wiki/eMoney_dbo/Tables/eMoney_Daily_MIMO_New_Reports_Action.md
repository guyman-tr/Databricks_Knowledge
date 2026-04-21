# eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action

> Daily MIMO (Money In / Money Out) deposit and cashout analytics for eToro Money customers, aggregated by country, club, action type, funding type, seniority, and IBAN type. 3,516,399 rows covering 2022-05-01 to 2026-04-11 (daily grain since May 2022). Replaced `eMoney_Reports_MIMO_Actions` on 2024-09-30 when the Type_of_IBAN dimension was added. Written by SP_eMoney_Daily_MIMO via daily DELETE+INSERT loop from DWH_dbo.Fact_CustomerAction.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction (ActionTypeID IN 7=Deposit, 8=Cashout), joined to Dim_Customer, Dim_ActionType, Dim_FundingType, Dim_PlayerLevel, Fact_SnapshotCustomer. eMoney eligibility from eMoney_Dim_Account. Written by SP_eMoney_Daily_MIMO. |
| **Refresh** | Daily WHILE loop — DELETE WHERE ActionDate = @MIMODate + INSERT aggregated metrics. Starts from last ActionDate + 1 and iterates to GETDATE()-1. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Daily_MIMO_New_Reports_Action` is the primary MIMO (Money In / Money Out) KPI table for eToro Money analytics. It provides daily deposit and cashout aggregations across all open eToro Money countries, segmented by the full analyst cut — country, club tier, action type, funding method, customer seniority, corporate flag, and IBAN origin country.

**Grain**: One row per (ActionDate × Country × Club × ActionType × FundingType × IsValid × Seniority_daily_FTD_Group × Is_Corporate_Account × Type_of_IBAN). A single action date typically produces ~350-800 rows covering all active dimensions. The table has 3,516,399 rows covering 2022-05-01 to 2026-04-11.

**MIMO KPI split**: The core analytical pattern splits actions into two streams based on FundingTypeID:
- **eMoney actions** (FundingTypeID=33 = eToroMoney): transfers into/out of eToro Money wallets from the eToro brokerage platform. These are the primary eToro Money adoption metric.
- **Other actions** (FundingTypeID≠33): external bank/card/PayPal/crypto transactions. These show non-platform funding activity.

**eMoney client overlay**: For both streams, the "ByeMoneyClients" columns subset the population to customers who are valid eToro Money users (IsValidETM=1 AND GCID_Unique_Count=1 in eMoney_Dim_Account). This lets analysts compare how many total market actions are from eToro Money customers vs. the broader eToro population.

**Country filter**: Only countries where eToro Money has launched (eMoney_Dim_Country_Rollout.RolloutDateID ≤ @MIMODateID) are included. This is a point-in-time filter — countries that rolled out later are excluded from historical dates.

**Snapshot join**: Customer club and country are taken from Fact_SnapshotCustomer at the action date using Dim_Range (point-in-time valid customer snapshot). This ensures country/club reflect the customer's state at the time of action, not their current state.

**Type_of_IBAN**: Added 2024-09-24 by Adva Jakobson. Contains the first 2 characters of the customer's BankAccountIBAN (IBAN country code: GB, FR, DE, AU, etc.). NULL for customers without an IBAN or non-eMoney customers. This enables analysis of actions by IBAN geography.

**Predecessor table**: `eMoney_Reports_MIMO_Actions` (frozen at 2024-10-12) is the identical table without Type_of_IBAN. For a complete time series, UNION both tables (joining on all shared columns).

---

## 2. Business Logic

### 2.1 eMoney vs. Other Actions Split (FundingTypeID=33)

**What**: Every action is classified as "eMoney" or "Other" based on the funding method.
**Columns Involved**: `CNT_eMoneyActions`, `CNT_OtherActions`, `Value_eMoneyActions`, `Value_OtherActions`, all `*ByeMoneyClients` variants
**Rules**:
- FundingTypeID = 33 → eToroMoney funding (eToro ↔ eMoney wallet transfer)
- FundingTypeID ≠ 33 → Other funding (bank wire, credit card, PayPal, crypto, etc.)
- CNT_TotalActions = CNT_eMoneyActions + CNT_OtherActions
- The "ByeMoneyClients" suffix further restricts: only actions where the customer has a valid eToro Money account (LEFT JOIN eMoney_Dim_Account IS NOT NULL)

### 2.2 Customer Seniority Buckets (FTD-Based)

**What**: Each action is tagged with the customer's deposit seniority at the action date.
**Columns Involved**: `Seniority_daily_FTD_Group`
**Rules**:
- Computed as DATEDIFF(DAY, Dim_Customer.FirstDepositDate, @MIMODate)
- 'No deposits': FirstDepositDate = 1900-01-01 (sentinel for never-deposited)
- '0': deposited same day as action
- '1-4', '5-7', '8-14', '15-30': early-lifecycle buckets
- '31-91', '92-183', '184-365', '366-730': mid-lifecycle
- '731+': mature customers (>2 years since first deposit)

### 2.3 Country Rollout Filter (Point-in-Time)

**What**: Only countries where eToro Money was officially launched by the action date are included.
**Columns Involved**: `Country`
**Rules**:
- eMoney_Dim_Country_Rollout.RolloutDateID ≤ @MIMODateID for inclusion
- Joined to Fact_SnapshotCustomer.CountryID via CountryID for country name
- 34 distinct countries appear in the 2026-04-11 data (as of latest available date)

### 2.4 IsValid Flag Semantics

**What**: The IsValid column marks whether the customer was a valid eToro Money participant at the time of action.
**Columns Involved**: `IsValid`
**Rules**:
- ISNULL(mda.IsValidETM, 1) — if the customer's GCID is not in eMoney_Dim_Account (not yet matched), defaults to 1 (valid)
- For customers IN eMoney_Dim_Account, uses their IsValidETM flag
- IsValid=0 rows are still included in the table (for full market coverage) but flagged for filtering

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution means data is spread evenly across nodes regardless of dimension values. This is appropriate for an aggregated report table where no single column dominates query patterns. All aggregation queries (`SUM`, `COUNT`) will read from multiple nodes in parallel. No skew risk.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily eMoney deposit volume by country | `WHERE ActionType='Deposit' AND IsValid=1 GROUP BY ActionDate, Country` |
| MIMO trend by funding type | `GROUP BY ActionDate, FundingType ORDER BY SUM(Value_TotalActions) DESC` |
| eToro Money adoption rate | `SUM(CNT_eMoneyActions) / NULLIF(SUM(CNT_TotalActions),0)` |
| New customer deposits (FTD day) | `WHERE Seniority_daily_FTD_Group = '0' AND ActionType = 'Deposit'` |
| UK IBAN holders' cashout activity | `WHERE Type_of_IBAN = 'GB' AND ActionType = 'Cashout'` |
| Full series (pre + post 2024-09-30) | `UNION ALL` with eMoney_Reports_MIMO_Actions (without Type_of_IBAN column) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Reports_MIMO_Actions | ActionDate, Country, Club, ActionType, FundingType | Historical completeness pre-2024-10-12 |
| DWH_dbo.Dim_Country | Country name lookup | Resolve to CountryID for DWH joins |

### 3.4 Gotchas

- **Type_of_IBAN is NULL pre-2024-09-30**: Always handle NULL when querying this column across the full date range. Join with eMoney_Reports_MIMO_Actions for the complete series — that table lacks this column.
- **FundingTypeID=33 hardcoded**: The eMoney/Other split is hardcoded to FundingTypeID=33. If Tribe introduces a new eMoney payment method with a different FundingTypeID, the split logic in the SP must be updated.
- **Country filter is point-in-time**: Countries not yet launched at a given historical date are excluded. Do NOT compare raw country-level action counts across dates spanning a country launch.
- **Deposit+Cashout only**: ActionTypeID IN (7, 8). Other action types (internal transfers, fee charges, etc.) are excluded.
- **IsValid defaults to 1**: Customers not matched to eMoney_Dim_Account are assumed valid. This overstates IsValid counts slightly for new accounts not yet in the dimension.
- **Duplicate date refresh**: The SP iterates from last ActionDate + 1 to yesterday. If the job runs twice in a day, each date is DELETE+INSERTed idempotently (no duplicates).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB_Schema wiki |
| Tier 2 | Derived from SP code analysis or internal DWH tables |
| Tier 3 | Inferred from column name, data type, and context |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ActionDate | date | YES | The date of the deposit or cashout action (CAST(Fact_CustomerAction.Occurred AS DATE)). Grain date for this aggregation — one complete calendar day. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 2 | Country | varchar(50) | YES | Country of the customer at the time of action, from eMoney_Dim_Country_Rollout.CountryName. Only eToro Money open countries (RolloutDateID ≤ ActionDate) appear. 34 distinct countries as of 2026-04-11. (Tier 2 — SP_eMoney_Daily_MIMO via Fact_SnapshotCustomer) |
| 3 | Club | varchar(50) | YES | Customer loyalty club tier at the time of action, from DWH_dbo.Dim_PlayerLevel.Name (e.g., Bronze, Silver, Gold, Platinum, Elite). Derived from Fact_SnapshotCustomer.PlayerLevelID at the action date. (Tier 2 — SP_eMoney_Daily_MIMO via Dim_PlayerLevel) |
| 4 | ActionType | varchar(100) | YES | Type of financial action from DWH_dbo.Dim_ActionType.Name. Only Deposit (ActionTypeID=7) and Cashout (ActionTypeID=8) are included. (Tier 2 — SP_eMoney_Daily_MIMO via Dim_ActionType) |
| 5 | FundingType | varchar(100) | YES | Funding method name from DWH_dbo.Dim_FundingType.Name. Examples: eToroMoney (FundingTypeID=33), CreditCard, PayPal, iDEAL, Przelewy24, Trustly, WireTransfer, eToroCryptoWallet, MoneyBookers. FundingTypeID=33 is the eToro Money split key. (Tier 2 — SP_eMoney_Daily_MIMO via Dim_FundingType) |
| 6 | IsValid | int | YES | 1 if the customer is a valid eToro Money participant (IsValidETM=1 in eMoney_Dim_Account with GCID_Unique_Count=1); defaults to 1 when the customer is not in eMoney_Dim_Account. 0 for explicitly ineligible customers. (Tier 2 — SP_eMoney_Daily_MIMO via eMoney_Dim_Account.IsValidETM) |
| 7 | Seniority_daily_FTD_Group | varchar(50) | YES | Customer deposit seniority bucket based on days since first deposit at the action date. Values: No deposits / 0 / 1-4 / 5-7 / 8-14 / 15-30 / 31-91 / 92-183 / 184-365 / 366-730 / 731+. Computed from DATEDIFF(Dim_Customer.FirstDepositDate, ActionDate). (Tier 2 — SP_eMoney_Daily_MIMO via Dim_Customer.FirstDepositDate) |
| 8 | Is_Corporate_Account | int | YES | 1 if the customer's AccountTypeID=2 in DWH_dbo.Dim_Customer; 0 otherwise. Identifies corporate/institutional accounts. (Tier 2 — SP_eMoney_Daily_MIMO via Dim_Customer.AccountTypeID) |
| 9 | CNT_TotalActions | int | YES | Total count of deposit or cashout actions in this (date × country × club × type × funding × seniority × corporate × IBAN) grouping. Not deduplicated — a customer making 3 deposits counts as 3. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 10 | CNT_UniqueGCIDs | int | YES | Count of distinct customer GCIDs in this grouping. Represents the number of unique customers who performed actions (vs. total action count in CNT_TotalActions). (Tier 2 — SP_eMoney_Daily_MIMO) |
| 11 | CNT_eMoneyActions | int | YES | Count of actions funded via eToroMoney (FundingTypeID=33) — the eToro platform ↔ eToro Money wallet transfer. Primary eToro Money adoption count metric. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 12 | CNT_OtherActions | int | YES | Count of actions funded via external methods (FundingTypeID ≠ 33) — bank wires, credit cards, PayPal, crypto, etc. CNT_TotalActions = CNT_eMoneyActions + CNT_OtherActions. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 13 | CNT_OtherActionsByeMoneyClients | int | YES | Count of non-eMoney-funded actions (FundingTypeID ≠ 33) performed by customers who are also valid eToro Money participants (LEFT JOIN eMoney_Dim_Account IS NOT NULL). Measures external funding activity of eToro Money customers. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 14 | CNT_eMoneyActionsByeMoneyClients | int | YES | Count of eMoney-funded actions (FundingTypeID=33) performed by customers who are valid eToro Money participants. Removes actions from customers who happen to use eToroMoney but aren't eToro Money clients. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 15 | Value_TotalActions | decimal(38,2) | YES | Total monetary value (in account currency) of all actions in this grouping. Sourced from Fact_CustomerAction.Amount. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 16 | Value_eMoneyActions | decimal(38,2) | YES | Total value of eMoney-funded actions (FundingTypeID=33). Measures the monetary flow through the eToro ↔ eMoney wallet channel. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 17 | Value_OtherActions | decimal(38,2) | YES | Total value of externally-funded actions (FundingTypeID ≠ 33). (Tier 2 — SP_eMoney_Daily_MIMO) |
| 18 | Value_OtherActionsByeMoneyClients | decimal(38,2) | YES | Total value of external-funded actions by customers who are eToro Money participants. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 19 | Value_eMoneyActionsByeMoneyClients | decimal(38,2) | YES | Total value of eMoney-funded actions by customers who are eToro Money participants. The primary monetary signal for eToro Money platform adoption. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 20 | UpdateDate | datetime | NO | ETL run timestamp — GETDATE() at INSERT time. Indicates when this date's rows were last computed. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 21 | Type_of_IBAN | varchar(50) | YES | First 2 characters of the customer's BankAccountIBAN from eMoney_Dim_Account — the IBAN country code (e.g., GB=UK, FR=France, DE=Germany, AU=Australia). NULL for customers without an IBAN or not in eMoney_Dim_Account. Added 2024-09-24. (Tier 2 — SP_eMoney_Daily_MIMO via eMoney_Dim_Account.BankAccountIBAN) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|--------------|-----------|
| ActionDate | Fact_CustomerAction | Occurred | CAST(AS DATE) |
| Country | Fact_SnapshotCustomer → eMoney_Dim_Country_Rollout | CountryID → CountryName | JOIN chain |
| Club | Fact_SnapshotCustomer → Dim_PlayerLevel | PlayerLevelID → Name | JOIN |
| ActionType | Dim_ActionType | Name | JOIN via ActionTypeID (7,8 only) |
| FundingType | Dim_FundingType | Name | JOIN via FundingTypeID |
| IsValid | eMoney_Dim_Account | IsValidETM | ISNULL(IsValidETM, 1) |
| Seniority_daily_FTD_Group | Dim_Customer | FirstDepositDate | CASE DATEDIFF buckets |
| Is_Corporate_Account | Dim_Customer | AccountTypeID | CASE WHEN = 2 THEN 1 |
| CNT_*: / Value_* | Fact_CustomerAction | GCID, Amount, FundingTypeID | Aggregated (COUNT/SUM) |
| Type_of_IBAN | eMoney_Dim_Account | BankAccountIBAN | LEFT(BankAccountIBAN, 2) |

### 5.2 ETL Pipeline

```
etoro (production DB)
  |-- DWH_dbo pipeline (Generic Pipeline Bronze export) --|
  v
DWH_dbo.Fact_CustomerAction  (all deposits/cashouts across eToro platform)
DWH_dbo.Dim_Customer         (FirstDepositDate, AccountTypeID)
DWH_dbo.Dim_ActionType       (ActionType names)
DWH_dbo.Dim_FundingType      (FundingType names; ID=33=eToroMoney)
DWH_dbo.Dim_PlayerLevel      (Club tier names)
DWH_dbo.Fact_SnapshotCustomer (Country, IsValidCustomer — point-in-time via Dim_Range)
  |
  +-- JOIN eMoney_dbo.eMoney_Dim_Account (IsValidETM, BankAccountIBAN → Type_of_IBAN)
  +-- JOIN eMoney_dbo.eMoney_Dim_Country_Rollout (open country filter + CountryName)
  |
  |-- SP_eMoney_Daily_MIMO  (SP 9 in Execute_Group_One)
  |   WHILE loop: ActionDate from last+1 to yesterday
  |   DELETE WHERE ActionDate = @date
  |   INSERT aggregated MIMO metrics
  v
eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action  (3.5M rows, 2022-05-01 to 2026-04-11)
  |-- Generic Pipeline (Gold export) --|
  v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action

Predecessor (frozen):
eMoney_dbo.eMoney_Reports_MIMO_Actions  (1.5M rows, 2022-05-01 to 2024-10-12)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| ActionType | DWH_dbo.Dim_ActionType | ActionTypeID 7=Deposit, 8=Cashout |
| FundingType | DWH_dbo.Dim_FundingType | FundingTypeID=33=eToroMoney split key |
| Club | DWH_dbo.Dim_PlayerLevel | Customer loyalty tier |
| Country | eMoney_dbo.eMoney_Dim_Country_Rollout | Open countries and launch dates |
| Type_of_IBAN | eMoney_dbo.eMoney_Dim_Account | BankAccountIBAN source |

### 6.2 Referenced By

| Object | How | Notes |
|--------|-----|-------|
| eMoney_Reports_MIMO_Actions | Historical predecessor | UNION for full time series |

---

## 7. Sample Queries

### Daily eMoney adoption rate by country

```sql
SELECT
    ActionDate,
    Country,
    SUM(CNT_eMoneyActionsByeMoneyClients) AS emoney_actions_by_emoney_clients,
    SUM(CNT_TotalActions)                  AS total_market_actions,
    CAST(SUM(CNT_eMoneyActionsByeMoneyClients) * 100.0 /
         NULLIF(SUM(CNT_TotalActions),0) AS DECIMAL(5,2)) AS emoney_adoption_pct
FROM [eMoney_dbo].[eMoney_Daily_MIMO_New_Reports_Action]
WHERE ActionDate >= '2026-01-01'
  AND ActionType = 'Deposit'
  AND IsValid = 1
GROUP BY ActionDate, Country
ORDER BY ActionDate DESC, SUM(CNT_eMoneyActionsByeMoneyClients) DESC;
```

### MIMO value trend by funding type (last 30 days)

```sql
SELECT
    ActionDate,
    ActionType,
    FundingType,
    SUM(Value_TotalActions) AS total_value,
    SUM(CNT_UniqueGCIDs)    AS unique_customers
FROM [eMoney_dbo].[eMoney_Daily_MIMO_New_Reports_Action]
WHERE ActionDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
  AND IsValid = 1
GROUP BY ActionDate, ActionType, FundingType
ORDER BY ActionDate DESC, SUM(Value_TotalActions) DESC;
```

### Full historical series (includes predecessor table)

```sql
SELECT ActionDate, Country, Club, ActionType, FundingType, IsValid,
       Seniority_daily_FTD_Group, Is_Corporate_Account,
       CNT_TotalActions, CNT_UniqueGCIDs, CNT_eMoneyActions, CNT_OtherActions,
       CNT_OtherActionsByeMoneyClients, CNT_eMoneyActionsByeMoneyClients,
       Value_TotalActions, Value_eMoneyActions, Value_OtherActions,
       Value_OtherActionsByeMoneyClients, Value_eMoneyActionsByeMoneyClients,
       UpdateDate,
       NULL AS Type_of_IBAN  -- not available in predecessor
FROM [eMoney_dbo].[eMoney_Reports_MIMO_Actions]  -- 2022-05-01 to 2024-10-12
WHERE ActionDate < '2024-10-13'

UNION ALL

SELECT ActionDate, Country, Club, ActionType, FundingType, IsValid,
       Seniority_daily_FTD_Group, Is_Corporate_Account,
       CNT_TotalActions, CNT_UniqueGCIDs, CNT_eMoneyActions, CNT_OtherActions,
       CNT_OtherActionsByeMoneyClients, CNT_eMoneyActionsByeMoneyClients,
       Value_TotalActions, Value_eMoneyActions, Value_OtherActions,
       Value_OtherActionsByeMoneyClients, Value_eMoneyActionsByeMoneyClients,
       UpdateDate, Type_of_IBAN
FROM [eMoney_dbo].[eMoney_Daily_MIMO_New_Reports_Action];  -- 2022-05-01 ongoing
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence pages or Jira tickets found for `eMoney_Daily_MIMO_New_Reports_Action`. The SP was created 2022-11-16 as part of the "eToro Money Daily MIMO — Migration to Synapse" project and modified 2024-09-30 to add IBAN type segmentation. Contextual background: the MIMO KPI is a core eToro Money dashboard metric tracking the Money In/Money Out flows across the platform.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 13/14*
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4 | Elements: 21/21, Logic: 4/10, ETL: documented*
*Object: eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction (ActionTypeID 7,8)*
