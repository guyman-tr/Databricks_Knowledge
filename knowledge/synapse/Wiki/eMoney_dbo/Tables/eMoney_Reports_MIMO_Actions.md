# eMoney_dbo.eMoney_Reports_MIMO_Actions

> **FROZEN TABLE** — Legacy predecessor to `eMoney_Daily_MIMO_New_Reports_Action`. Contains daily MIMO deposit/cashout aggregations for eToro Money customers from 2022-05-01 to 2024-10-12 (1,544,381 rows). Stopped receiving new data on 2024-09-30 when SP_eMoney_Daily_MIMO was modified to target the new table (which added the Type_of_IBAN dimension). Identical schema to `eMoney_Daily_MIMO_New_Reports_Action` except this table has 20 columns (no Type_of_IBAN) and UpdateDate is nullable. UNION with the successor table for the full 2022–present time series.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction (ActionTypeID IN 7=Deposit, 8=Cashout). Written by SP_eMoney_Daily_MIMO prior to 2024-09-30. |
| **Refresh** | **FROZEN** — no new data since 2024-10-12. Last populated by SP_eMoney_Daily_MIMO before it was redirected to eMoney_Daily_MIMO_New_Reports_Action. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (historical archive) |

---

## 1. Business Meaning

`eMoney_Reports_MIMO_Actions` is the historical MIMO (Money In / Money Out) analytics table for eToro Money, covering 2022-05-01 to 2024-10-12 (1,544,381 rows). It was the primary daily MIMO KPI table from the eToro Money Synapse migration in November 2022 until September 2024.

**Grain**: One row per (ActionDate × Country × Club × ActionType × FundingType × IsValid × Seniority_daily_FTD_Group × Is_Corporate_Account). This is identical to `eMoney_Daily_MIMO_New_Reports_Action` but without the Type_of_IBAN dimension. The same country, club, action type, and funding type segmentation applies.

**Why it was superseded**: On 2024-09-30, Adva Jakobson modified SP_eMoney_Daily_MIMO to (1) add Type_of_IBAN segmentation from eMoney_Dim_Account.BankAccountIBAN and (2) redirect inserts to `eMoney_Daily_MIMO_New_Reports_Action`. The old table is preserved as a historical archive. The "New_Reports_Action" naming reflects this transition.

**Complete time series**: To query the full MIMO history from 2022 to present, UNION this table (for dates ≤ 2024-10-12) with `eMoney_Daily_MIMO_New_Reports_Action` (for all dates). Set Type_of_IBAN = NULL for rows from this legacy table.

**MIMO KPI semantics**: All CNT_/Value_ columns follow the same eMoney vs. Other split logic as the successor table. FundingTypeID=33 (eToroMoney) separates platform-internal transfers from external bank/card/PayPal funding. The "ByeMoneyClients" suffix restricts the population to valid eToro Money participants (IsValidETM=1 in eMoney_Dim_Account).

---

## 2. Business Logic

### 2.1 Identical to eMoney_Daily_MIMO_New_Reports_Action

All business logic rules from `eMoney_Daily_MIMO_New_Reports_Action` apply verbatim:
- **eMoney vs. Other split** (FundingTypeID=33): same split logic
- **Seniority buckets** (FTD-based): same 11 groups
- **Country rollout filter**: same point-in-time logic
- **IsValid default**: same ISNULL(IsValidETM, 1) behavior

See `eMoney_Daily_MIMO_New_Reports_Action.md` for full business logic documentation.

### 2.2 Key Differences vs. Successor Table

**What**: Structural differences between this legacy table and the successor.
**Columns Involved**: UpdateDate, Type_of_IBAN (absent here)
**Rules**:
- **No Type_of_IBAN column** — this dimension was added only in the new table. Rows here cannot be segmented by IBAN country.
- **UpdateDate is nullable** — in the new table, UpdateDate is NOT NULL. In this table, it allows NULLs (though no NULLs are expected in practice).
- **ROUND_ROBIN distribution** — same as new table.
- **Frozen at 2024-10-12**: last ActionDate in this table. `MAX(UpdateDate)` = 2024-10-13 (day after last action date, per DELETE+INSERT pattern).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN — same as successor table. No distribution key bias. Aggregation queries distribute evenly.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Historical MIMO (pre-Oct 2024) | Query this table directly for ActionDate ≤ '2024-10-12' |
| Full time series 2022–present | UNION this table (NULL Type_of_IBAN) with eMoney_Daily_MIMO_New_Reports_Action |
| Last date in table | `SELECT MAX(ActionDate) FROM [eMoney_dbo].[eMoney_Reports_MIMO_Actions]` → 2024-10-12 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Daily_MIMO_New_Reports_Action | UNION ALL on all 20 shared columns | Complete time series |

### 3.4 Gotchas

- **DO NOT use for current analysis**: This table is frozen. All data is historical ≤ 2024-10-12. Always use `eMoney_Daily_MIMO_New_Reports_Action` for current metrics.
- **No Type_of_IBAN**: Any analysis requiring IBAN country segmentation must use the new table (ActionDate ≥ 2022-05-01 with IBAN data only available from 2024-09-30 onwards in the new table).
- **Same country filter semantics**: The country rollout filter was the same when this table was populated, so country-level comparisons across the two tables are consistent.
- **UpdateDate is nullable**: Do not use UpdateDate IS NOT NULL as a data quality check for this table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB_Schema wiki |
| Tier 2 | Derived from SP code analysis or internal DWH tables |
| Tier 3 | Inferred from column name, data type, and context |
| Tier 4 | Best available knowledge, limited confidence |

> **Cross-object consistency note**: All 20 column descriptions below are identical to the corresponding columns in `eMoney_Daily_MIMO_New_Reports_Action`. Same production source = same description. Only UpdateDate nullability differs structurally.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ActionDate | date | YES | The date of the deposit or cashout action (CAST(Fact_CustomerAction.Occurred AS DATE)). Grain date for this aggregation — one complete calendar day. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 2 | Country | varchar(50) | YES | Country of the customer at the time of action, from eMoney_Dim_Country_Rollout.CountryName. Only eToro Money open countries (RolloutDateID ≤ ActionDate) appear. (Tier 2 — SP_eMoney_Daily_MIMO via Fact_SnapshotCustomer) |
| 3 | Club | varchar(50) | YES | Customer loyalty club tier at the time of action, from DWH_dbo.Dim_PlayerLevel.Name (e.g., Bronze, Silver, Gold, Platinum, Elite). Derived from Fact_SnapshotCustomer.PlayerLevelID at the action date. (Tier 2 — SP_eMoney_Daily_MIMO via Dim_PlayerLevel) |
| 4 | ActionType | varchar(100) | YES | Type of financial action from DWH_dbo.Dim_ActionType.Name. Only Deposit (ActionTypeID=7) and Cashout (ActionTypeID=8) are included. (Tier 2 — SP_eMoney_Daily_MIMO via Dim_ActionType) |
| 5 | FundingType | varchar(100) | YES | Funding method name from DWH_dbo.Dim_FundingType.Name. Examples: eToroMoney (FundingTypeID=33), CreditCard, PayPal, iDEAL, Przelewy24, Trustly, WireTransfer, eToroCryptoWallet, MoneyBookers. FundingTypeID=33 is the eToro Money split key. (Tier 2 — SP_eMoney_Daily_MIMO via Dim_FundingType) |
| 6 | IsValid | int | YES | 1 if the customer is a valid eToro Money participant (IsValidETM=1 in eMoney_Dim_Account with GCID_Unique_Count=1); defaults to 1 when the customer is not in eMoney_Dim_Account. 0 for explicitly ineligible customers. (Tier 2 — SP_eMoney_Daily_MIMO via eMoney_Dim_Account.IsValidETM) |
| 7 | Seniority_daily_FTD_Group | varchar(50) | YES | Customer deposit seniority bucket based on days since first deposit at the action date. Values: No deposits / 0 / 1-4 / 5-7 / 8-14 / 15-30 / 31-91 / 92-183 / 184-365 / 366-730 / 731+. Computed from DATEDIFF(Dim_Customer.FirstDepositDate, ActionDate). (Tier 2 — SP_eMoney_Daily_MIMO via Dim_Customer.FirstDepositDate) |
| 8 | Is_Corporate_Account | int | YES | 1 if the customer's AccountTypeID=2 in DWH_dbo.Dim_Customer; 0 otherwise. Identifies corporate/institutional accounts. (Tier 2 — SP_eMoney_Daily_MIMO via Dim_Customer.AccountTypeID) |
| 9 | CNT_TotalActions | int | YES | Total count of deposit or cashout actions in this grouping. Not deduplicated — a customer making 3 deposits counts as 3. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 10 | CNT_UniqueGCIDs | int | YES | Count of distinct customer GCIDs in this grouping. Represents the number of unique customers who performed actions. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 11 | CNT_eMoneyActions | int | YES | Count of actions funded via eToroMoney (FundingTypeID=33) — the eToro platform ↔ eToro Money wallet transfer. Primary eToro Money adoption count metric. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 12 | CNT_OtherActions | int | YES | Count of actions funded via external methods (FundingTypeID ≠ 33) — bank wires, credit cards, PayPal, crypto, etc. CNT_TotalActions = CNT_eMoneyActions + CNT_OtherActions. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 13 | CNT_OtherActionsByeMoneyClients | int | YES | Count of non-eMoney-funded actions (FundingTypeID ≠ 33) performed by customers who are also valid eToro Money participants (LEFT JOIN eMoney_Dim_Account IS NOT NULL). Measures external funding activity of eToro Money customers. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 14 | CNT_eMoneyActionsByeMoneyClients | int | YES | Count of eMoney-funded actions (FundingTypeID=33) performed by customers who are valid eToro Money participants. Removes actions from customers who happen to use eToroMoney but aren't eToro Money clients. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 15 | Value_TotalActions | decimal(38,2) | YES | Total monetary value (in account currency) of all actions in this grouping. Sourced from Fact_CustomerAction.Amount. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 16 | Value_eMoneyActions | decimal(38,2) | YES | Total value of eMoney-funded actions (FundingTypeID=33). Measures the monetary flow through the eToro ↔ eMoney wallet channel. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 17 | Value_OtherActions | decimal(38,2) | YES | Total value of externally-funded actions (FundingTypeID ≠ 33). (Tier 2 — SP_eMoney_Daily_MIMO) |
| 18 | Value_OtherActionsByeMoneyClients | decimal(38,2) | YES | Total value of external-funded actions by customers who are eToro Money participants. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 19 | Value_eMoneyActionsByeMoneyClients | decimal(38,2) | YES | Total value of eMoney-funded actions by customers who are eToro Money participants. The primary monetary signal for eToro Money platform adoption. (Tier 2 — SP_eMoney_Daily_MIMO) |
| 20 | UpdateDate | datetime | YES | ETL run timestamp — GETDATE() at INSERT time. Nullable in this legacy table (vs. NOT NULL in the successor). Last value: 2024-10-13 (day after the last ActionDate). (Tier 2 — SP_eMoney_Daily_MIMO) |

---

## 5. Lineage

### 5.1 Production Sources

See `eMoney_Daily_MIMO_New_Reports_Action.lineage.md` — identical source chain (Fact_CustomerAction, Dim_Customer, Dim_ActionType, Dim_FundingType, Dim_PlayerLevel, Fact_SnapshotCustomer, eMoney_Dim_Account, eMoney_Dim_Country_Rollout).

### 5.2 ETL Pipeline

```
etoro (production DB) → DWH_dbo pipeline → Fact_CustomerAction + dimensions
  |
  +-- JOIN eMoney_dbo.eMoney_Dim_Account (IsValidETM)
  +-- JOIN eMoney_dbo.eMoney_Dim_Country_Rollout (open countries)
  |
  |-- SP_eMoney_Daily_MIMO (pre-2024-09-30 version — before Type_of_IBAN was added)
  |   WHILE loop: ActionDate from last+1 to yesterday
  |   DELETE WHERE ActionDate = @date; INSERT aggregated MIMO metrics
  v
eMoney_dbo.eMoney_Reports_MIMO_Actions  ← FROZEN 2024-10-12 (1,544,381 rows)

[On 2024-09-30, SP_eMoney_Daily_MIMO was modified → now writes to eMoney_Daily_MIMO_New_Reports_Action]

For full series:
eMoney_dbo.eMoney_Reports_MIMO_Actions (2022-05-01 → 2024-10-12)
  UNION ALL
eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action (2022-05-01 → present, Type_of_IBAN included)
  |-- Generic Pipeline (Gold export) --|
  v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| ActionType | DWH_dbo.Dim_ActionType | ActionTypeID 7=Deposit, 8=Cashout |
| FundingType | DWH_dbo.Dim_FundingType | FundingTypeID=33=eToroMoney split key |
| Club | DWH_dbo.Dim_PlayerLevel | Customer loyalty tier |
| Country | eMoney_dbo.eMoney_Dim_Country_Rollout | Open country names and launch dates |

### 6.2 Referenced By

| Object | How | Notes |
|--------|-----|-------|
| eMoney_Daily_MIMO_New_Reports_Action | Historical predecessor in UNION | For full 2022–present time series |

---

## 7. Sample Queries

### Query last available date in legacy table

```sql
SELECT MAX(ActionDate) AS last_date, COUNT(*) AS rows_on_last_date
FROM [eMoney_dbo].[eMoney_Reports_MIMO_Actions]
WHERE ActionDate = (SELECT MAX(ActionDate) FROM [eMoney_dbo].[eMoney_Reports_MIMO_Actions]);
-- Returns: 2024-10-12
```

### Full historical series including legacy data

```sql
SELECT ActionDate, Country, Club, ActionType, FundingType, IsValid,
       Seniority_daily_FTD_Group, Is_Corporate_Account,
       CNT_TotalActions, CNT_UniqueGCIDs, CNT_eMoneyActions, CNT_OtherActions,
       CNT_OtherActionsByeMoneyClients, CNT_eMoneyActionsByeMoneyClients,
       Value_TotalActions, Value_eMoneyActions, Value_OtherActions,
       Value_OtherActionsByeMoneyClients, Value_eMoneyActionsByeMoneyClients,
       UpdateDate, NULL AS Type_of_IBAN
FROM [eMoney_dbo].[eMoney_Reports_MIMO_Actions]

UNION ALL

SELECT ActionDate, Country, Club, ActionType, FundingType, IsValid,
       Seniority_daily_FTD_Group, Is_Corporate_Account,
       CNT_TotalActions, CNT_UniqueGCIDs, CNT_eMoneyActions, CNT_OtherActions,
       CNT_OtherActionsByeMoneyClients, CNT_eMoneyActionsByeMoneyClients,
       Value_TotalActions, Value_eMoneyActions, Value_OtherActions,
       Value_OtherActionsByeMoneyClients, Value_eMoneyActionsByeMoneyClients,
       UpdateDate, Type_of_IBAN
FROM [eMoney_dbo].[eMoney_Daily_MIMO_New_Reports_Action];
```

### Verify no row overlap between tables

```sql
SELECT 'Legacy' AS source, MAX(ActionDate) AS max_date FROM [eMoney_dbo].[eMoney_Reports_MIMO_Actions]
UNION ALL
SELECT 'New', MIN(ActionDate) FROM [eMoney_dbo].[eMoney_Daily_MIMO_New_Reports_Action];
-- Both tables contain 2022-05-01 to 2024-10-12 (the new table backfilled from the same SP)
```

---

## 8. Atlassian Knowledge Sources

No Confluence pages or Jira tickets found specifically for `eMoney_Reports_MIMO_Actions`. The table was the original Synapse MIMO report table from November 2022. Replaced in September 2024 by `eMoney_Daily_MIMO_New_Reports_Action` when the IBAN type dimension was added. See the successor table's documentation for business context.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 0 T1, 20 T2, 0 T3, 0 T4 | Elements: 20/20, Logic: 2/10, ETL: documented*
*Object: eMoney_dbo.eMoney_Reports_MIMO_Actions | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction (FROZEN — legacy table, last date 2024-10-12)*
