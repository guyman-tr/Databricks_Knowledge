---
object_fqn: main.bi_output.bi_output_vg_parentcid
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_parentcid
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 76
row_count: null
generated_at: '2026-05-19T15:01:51Z'
upstreams:
- main.bi_output.bi_output_vg_date
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_parentcid.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_parentcid.sql
concept_count: 6
formula_count: 76
tier_breakdown:
  tier1_columns: 14
  tier2_columns: 62
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_parentcid

> View in `main.bi_output`. 6 business concept(s) in §2; 76 of 76 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_parentcid` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 76 |
| **Concepts** | 6 (see §2) |
| **Downstream consumers** | 2 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Sat Mar 07 07:33:40 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_parentcid` is a view in `main.bi_output` that composes 6 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_vg_date` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md`. Additional upstreams: 8 object(s), listed in §5 Lineage.

Of its 76 columns: 14 inherit byte-for-byte from upstream wikis (Tier 1), 62 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 Dim lookup via alias `dcu` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `cp.CID = dcu.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_parentcid.sql` L86
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.2 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_parentcid.sql` L92
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.3 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_parentcid.sql` L94
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.4 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_parentcid.sql` L96
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.5 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_parentcid.sql` L98
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.6 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_parentcid.sql` L100
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`, `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `cp.CID = dcu.RealCID` | Lookup via alias `dcu` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `fsc.AccountStatusID = ast.AccountStatusID` | Lookup via alias `ast` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `fsc.AccountTypeID = act.AccountTypeID` | Lookup via alias `act` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `fsc.PlayerStatusID = pst.PlayerStatusID` | Lookup via alias `pst` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID` | Lookup via alias `psr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID` | Lookup via alias `pssr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: bi_output.bi_output_vg_parentcid -- Captured: 2026-05-…`. (Tier 2 — computed in source) |
| 1 | Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Date`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 2 | WeekNumberYear | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 3 | CalendarYearMonth | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 4 | CalendarQuarter | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 5 | CalendarYear | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 6 | IsLastDayWeek | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,IsLastDayWeek`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 7 | IsLastDayMonth | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,IsLastDayWeek ,IsLastDayMonth`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 8 | IsLastDayQuarter | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 9 | IsLastDayYear | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear`. (Tier 2 — from `bi_output.bi_output_vg_date`) |
| 10 | RealCID | INT | YES | Customer ID of the Popular Investor, Smart Portfolio, or Removed PI. From Fact_SnapshotCustomer.RealCID. (Tier 2 — Fact_SnapshotCustomer) |
| 11 | UserName | STRING | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 12 | Gender | STRING | YES | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 13 | Manager | STRING | YES | Account manager full name (FirstName + ' ' + LastName from Dim_Manager). Concatenated in the SP. (Tier 2 — Dim_Manager) |
| 14 | Country | STRING | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 15 | Region | STRING | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from the automated MarketingRegion label (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Passthrough from Dim_Country.MarketingRegionManualName. (Tier 1 — Ext_Dim_Country) |
| 16 | Language | STRING | YES | Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. Passthrough from Dim_Language. (Tier 1 — Dictionary.Language) |
| 17 | Club | STRING | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel. (Tier 1 — Dictionary.PlayerLevel) |
| 18 | Regulation | STRING | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 19 | RegisteredReal | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear ,CID AS RealCID ,UserName ,cp.…`. (Tier 2 — from `bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 20 | FirstDepositDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear ,CID AS RealCID ,UserName ,cp.…`. (Tier 2 — from `bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 21 | Seniority | INT | YES | Months since first deposit, computed as DATEDIFF(MONTH, FirstDepositDate, first-of-month(@date)). NULL if customer never deposited. (Tier 2 — Dim_Customer) |
| 22 | DaysAsPI | INT | YES | Days since the customer first achieved any PI status (GuruStatusID >= 2). Computed from MIN(Fact_SnapshotCustomer FromDate where GuruStatusID >= 2). NULL for Portfolio accounts. (Tier 2 — Fact_SnapshotCustomer) |
| 23 | CopyType | STRING | YES | Population classification: 'PI' = active Popular Investor (GuruStatusID 2-6, IsValidCustomer=1), 'Portfolio' = Smart Portfolio fund (AccountTypeID=9), 'RemovedPI' = former PI no longer in active PI status. (Tier 2 — Fact_SnapshotCustomer) |
| 24 | PortfolioType | STRING | YES | Human-readable label for the fund type. Used in the platform UI, fund details pages, and management reporting. Describes the fundamental strategy approach of the fund category. 1=TopTraders, 2=Partners, 3=Market. NULL for PI and RemovedPI CopyTypes. Passthrough from Dim_FundType.FundTypeName via Dim_Fund. (Tier 1 — Dictionary.FundType) |
| 25 | GuruStatusID | INT | YES | Popular Investor program status code from the snapshot date. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro. Passthrough from Fact_SnapshotCustomer. (Tier 2 — Fact_SnapshotCustomer) |
| 26 | GuruStatus | STRING | YES | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus. (Tier 1 — Dictionary.GuruStatus) |
| 27 | PreviousGuruStatus | STRING | YES | The GuruStatusID of the most recent different guru status for this CID. Determined via ROW_NUMBER over Fact_SnapshotCustomer history, filtering rows where GuruStatusID differs from the current status, ordered by ToDateID DESC. NULL if no previous status change found. Stored as the raw GuruStatusID integer (not the name). (Tier 2 — Fact_SnapshotCustomer) |
| 28 | TotalDaysInCurrentStatus | INT | YES | Total calendar days the PI has held their current GuruStatusID, summed across potentially non-contiguous SCD2 date ranges. Only computed for CopyType='PI'. NULL for Portfolio and RemovedPI. (Tier 2 — Fact_SnapshotCustomer) |
| 29 | BIO_Len | INT | YES | Character length of the PI's "About Me" biography text from their public profile. Source: LEN(AboutMe) from External_UserApiDB_dbo_Publications. NULL if no biography published. (Tier 2 — External_UserApiDB_dbo_Publications) |
| 30 | IsPrivate | INT | YES | Whether the PI's profile is set to private. 0 if PrivacyPolicyID=2 (public), 1 otherwise (private). Derived from Dim_Customer.PrivacyPolicyID. (Tier 2 — Dim_Customer) |
| 31 | AllowDisplayFullName | INT | YES | Whether the PI allows their full legal name to be displayed publicly. From External_etoroGeneral_Customer_Settings, windowed by ValidFrom/ValidTo to the snapshot date. (Tier 2 — External_etoroGeneral_Customer_Settings) |
| 32 | HasAvatar | INT | YES | Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). Passthrough from Dim_Customer. (Tier 2 — Dim_Customer) |
| 33 | RiskScore | INT | YES | Discrete portfolio risk score (typically 1-10) derived from mapping the daily portfolio standard deviation (AvgSTD from DWH_CIDsDailyRisk) to risk buckets defined in External_etoro_Internal_RiskScore. Higher values = more volatile portfolio. MAX per CID. (Tier 2 — DWH_CIDsDailyRisk) |
| 34 | PlayerStatus | STRING | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Passthrough from Dim_PlayerStatus. (Tier 1 — Dictionary.PlayerStatus) |
| 35 | LastBlockedDate | TIMESTAMP | YES | Most recent date when copy-trading operations were blocked for this CID. Source: MAX(Occurred/BlockStart) from External_etoro_Customer_BlockedCustomerOperations and External_etoro_History_BlockedCustomerOperations where OperationTypeID=2. NULL if never blocked. (Tier 2 — External_etoro_Customer_BlockedCustomerOperations) |
| 36 | BlockReason | STRING | YES | Human-readable reason for the most recent copy block event. Looked up from External_etoro_Dictionary_BlockUnBlockReason via BlockReasonID. NULL if never blocked. (Tier 2 — External_etoro_Dictionary_BlockUnBlockReason) |
| 37 | CanOpenPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,IsLastDayQuarter ,IsLastDayYear ,CID AS RealCID ,UserName ,Gender ,Manager ,Country ,Region ,Language ,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,cp…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 38 | CanClosePosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,IsLastDayYear ,CID AS RealCID ,UserName ,Gender ,Manager ,Country ,Region ,Language ,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,Seniority ,DaysAs…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 39 | CanEditPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CID AS RealCID ,UserName ,Gender ,Manager ,Country ,Region ,Language ,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,Seniority ,DaysAsPI ,CopyType ,cp…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 40 | CanBeCopied | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,UserName ,Gender ,Manager ,Country ,Region ,Language ,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,Seniority ,DaysAsPI ,CopyType ,PortfolioType ,cp.…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 41 | CanDeposit | BOOLEAN | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only/pending statuses (9, 13, 15), status 10 (Deposit Blocked), and status 11 (Social Index). |
| 42 | CanRequestWithdraw | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Manager ,Country ,Region ,Language ,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,Seniority ,DaysAsPI ,CopyType ,PortfolioType ,GuruStatusID ,GuruSta…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 43 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Country ,Region ,Language ,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,Seniority ,DaysAsPI ,CopyType ,PortfolioType ,GuruStatusID ,GuruStatus ,Prev…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 44 | PlayerStatusReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,Region ,Language ,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,Seniority ,DaysAsPI ,CopyType ,PortfolioType ,GuruStatusID ,GuruStatus ,PreviousGuruStat…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 45 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Language ,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,Seniority ,DaysAsPI ,CopyType ,PortfolioType ,GuruStatusID ,GuruStatus ,PreviousGuruStatus ,Tota…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 46 | PlayerStatusSubReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,Club ,Regulation ,RegisteredReal ,FirstDepositDate ,Seniority ,DaysAsPI ,CopyType ,PortfolioType ,GuruStatusID ,GuruStatus ,PreviousGuruStatus ,TotalDaysInCurren…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy`) |
| 47 | TotalEquity | DECIMAL | YES | Customer total balance on the snapshot date: ISNULL(Liabilities, 0) + ISNULL(ActualNWA, 0) from V_Liabilities. Equals RealizedEquity + PositionPnL. (Tier 2 — V_Liabilities) |
| 48 | RealizedEquity | DECIMAL | YES | Realized equity (cash + credit + in-process cashouts) on the snapshot date. Direct passthrough from V_Liabilities.RealizedEquity. (Tier 2 — Fact_SnapshotEquity) |
| 49 | TotalPositionsAmount | DECIMAL | YES | Total invested amount across all open positions on the snapshot date. Direct passthrough from V_Liabilities.TotalPositionsAmount. (Tier 2 — Fact_SnapshotEquity) |
| 50 | PositionPnL | DECIMAL | YES | Unrealized position profit/loss on the snapshot date. Direct passthrough from V_Liabilities.PositionPnL. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 51 | Credit | DECIMAL | YES | Available credit balance on the snapshot date. Direct passthrough from V_Liabilities.Credit. (Tier 2 — Fact_SnapshotEquity) |
| 52 | NumOfCopiers | INT | YES | Count of valid depositor customers currently copying this PI/Portfolio, from etoroGeneral_History_GuruCopiers where Timestamp = day-after-@date. Only counts IsValidCustomer=1 AND IsDepositor=1 copiers. (Tier 2 — etoroGeneral_History_GuruCopiers) |
| 53 | CopyAUC | DECIMAL | YES | Total Assets Under Copy -- sum of Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL across all valid copiers of this PI/Portfolio. (Tier 2 — etoroGeneral_History_GuruCopiers) |
| 54 | CopyPnL | DECIMAL | YES | Total copy PnL -- sum of PnL + DetachedPosInvestment + Dit_PnL across all valid copiers of this PI/Portfolio. (Tier 2 — etoroGeneral_History_GuruCopiers) |
| 55 | MI | DECIMAL | YES | Mirror In -- daily inflow of funds into copy relationships where this CID is the copied person. SUM(-Amount) for ActionTypeID IN (15=Account-to-Mirror, 17=Register New Mirror) from Fact_CustomerAction on the snapshot date. (Tier 2 — Fact_CustomerAction) |
| 56 | MO | DECIMAL | YES | Mirror Out -- daily outflow of funds from copy relationships where this CID is the copied person. SUM(Amount) for ActionTypeID IN (16=Mirror-to-Account, 18=Unregister Mirror) from Fact_CustomerAction on the snapshot date. (Tier 2 — Fact_CustomerAction) |
| 57 | NetMI | DECIMAL | YES | Net Mirror In -- net daily money flow into copy relationships. SUM(-Amount) for all mirror ActionTypeIDs (15,16,17,18). Positive = net inflow, negative = net outflow. (Tier 2 — Fact_CustomerAction) |
| 58 | Trades | INT | YES | Count of manual (non-copy) positions opened by this CID on the snapshot date. Source: COUNT from Dim_Position WHERE MirrorID=0 AND ISNULL(IsPartialCloseChild,0)=0 AND OpenDateID=@date_int. (Tier 2 — Dim_Position) |
| 59 | Top_3_Traded_Instruments | STRING | YES | Comma-separated list of the top 3 instrument symbols by invested amount among open positions. Determined by ranking open positions by SUM(Amount) DESC per InstrumentID, then STRING_AGG of top 3 Symbol values. NULL if no open positions. (Tier 2 — Dim_Position / Dim_Instrument) |
| 60 | Top3TradedIndustries | STRING | YES | Comma-separated list of the top 3 industries by invested amount among open positions. Ranked by SUM(Amount) DESC per Industry, then STRING_AGG of top 3. NULL if no open positions. (Tier 2 — Dim_Position / Dim_Instrument) |
| 61 | Lev_weighted_average | DECIMAL | YES | Amount-weighted average leverage across all open positions on the snapshot date. Formula: SUM(Leverage * Amount) / NULLIF(SUM(Amount), 0). Source: BI_DB_PositionPnL for the snapshot DateID. (Tier 2 — BI_DB_PositionPnL) |
| 62 | BuyPercent | DECIMAL | YES | Sell percentage among high-leverage positions held >30 days (Leverage >= 5, opened > 30 days ago). NOTE: despite the column name "BuyPercent", the SP actually stores the SELL ratio here (IsBuy=0 count / total count). NULL if no qualifying high-lev positions exist. (Tier 2 — Dim_Position) |
| 63 | SellPercent | DECIMAL | YES | Buy percentage among high-leverage positions held >30 days. Computed as 1 - BuyPercent. Despite the name "SellPercent", this is actually the BUY ratio (since BuyPercent stores the sell ratio). NULL if no qualifying high-lev positions. (Tier 2 — Dim_Position) |
| 64 | HoldsHighLevPosition | INT | YES | 1 if the CID holds any position open >30 days with leverage exceeding asset-class thresholds (Stocks/ETF >= 5x, Indices >= 10x, Currencies/Commodities >= 20x). 0 otherwise. (Tier 2 — Dim_Position) |
| 65 | Classification | STRING | YES | Portfolio asset allocation category based on open position volumes. Values: 'Long Equity' (>=70% equity, >80% buy), 'Long/Short Equity' (>=70% equity, >=20% buy AND >=20% short), 'Currencies', 'Commodities', 'Crypto', 'ETF' (each >=70%), '100% cash balance' (no positions), 'Multi-Asset' (default). (Tier 2 — Dim_Position) |
| 66 | Largest_Asset_Class | STRING | YES | The single asset class (InstrumentType) with the highest total invested amount among open positions. Values: Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies. NULL if no open positions. (Tier 2 — Dim_Position / Dim_Instrument) |
| 67 | AvgerageHoldingTime | INT | YES | Average holding time in days across all positions and mirrors opened/closed within the last 2 years. Includes both trading positions (Dim_Position) and copy relationships (Dim_Mirror). Open positions use @date as the close proxy. Note: column name has a typo ("Avgerageee" instead of "Average"). (Tier 2 — Dim_Position / Dim_Mirror) |
| 68 | TraderType | STRING | YES | Classification of the PI by average holding time. 'Short term investor' if AvgerageHoldingTime < 22 days, 'Long term investor' otherwise. (Tier 2 — SP_DailyPanel_Copy) |
| 69 | HighLevHoldingDetail | STRING | YES | Comma-separated list of "Leverage-InstrumentType" strings for all high-leverage positions held >30 days (same criteria as HoldsHighLevPosition). E.g., "5-Stocks, 10-Indices". NULL if no qualifying positions. (Tier 2 — Dim_Position / Dim_Instrument) |
| 70 | Value_percenet | DECIMAL | YES | Top position value as a fraction of total portfolio (positions + credit). Formula: ROUND(Position_Value / NULLIF(Total_Position_Value + Credit, 0), 3). Measures portfolio concentration. Note: column name has a typo ("percenet" instead of "percent"). (Tier 2 — BI_DB_PositionPnL / V_Liabilities) |
| 71 | Last_Day_Performance | DOUBLE | YES | Daily compound portfolio return as a decimal. ISNULL(Gain_d, 0) from DWH_GainDaily for the snapshot date. 0.05 = 5% gain. (Tier 2 — DWH_GainDaily) |
| 72 | Gain_YTD | DOUBLE | YES | Year-to-date compound portfolio return as a decimal. ISNULL(Gain_YTD, 0) from DWH_GainDaily. From Jan 1 to snapshot date. (Tier 2 — DWH_GainDaily) |
| 73 | Gain_QTD | DOUBLE | YES | Quarter-to-date compound portfolio return as a decimal. ISNULL(Gain_QTD, 0) from DWH_GainDaily. From first of current quarter to snapshot date. (Tier 2 — DWH_GainDaily) |
| 74 | Gain_MTD | DOUBLE | YES | Month-to-date compound portfolio return as a decimal. ISNULL(Gain_MTD, 0) from DWH_GainDaily. From first of current month to snapshot date. (Tier 2 — DWH_GainDaily) |
| 75 | MonthsSinceFirstOpen | INT | YES | Months since the customer's first trading action (position open or mirror registration). DATEDIFF(Month, MIN(FirstOccurred), @date) from Fact_FirstCustomerAction WHERE ActionTypeID IN (1=ManualOpen, 2=CopyOpen, 17=RegisterMirror). (Tier 2 — Fact_FirstCustomerAction) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_vg_date` | Primary | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyPanel_Copy.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output.bi_output_vg_date
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
... (6 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_parentcid   ←── this object
        │
        ▼
main.bi_dealing_stg.bi_output_dealing_bod_pi_kpis
main.bi_dealing_stg.bi_output_dealing_bod_sp_kpis
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=76 runtime=76 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output.bi_output_vg_date` (wiki: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md`)
- **JOIN/UNION upstreams**: 8 additional object(s)
- **Wiki coverage**: 8/8 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_dealing_stg.bi_output_dealing_bod_pi_kpis`
- `main.bi_dealing_stg.bi_output_dealing_bod_sp_kpis`

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 6 | Formulas: 76 | Tiers: 14 T1, 62 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 76/76 | Source: view_definition*
