# eMoney_dbo.eMoney_Aggregated_Tribe_Balance

> Daily aggregated balance and account-health summary for all eToro Money (Tribe) accounts, segmented by entity (UK/Malta/AUS), program, sub-program, currency, and account status. 67,580 rows covering 2024-01-31 to 2026-04-11. Each row represents one (BalanceDate × Entity × Program × SubProgram × AccountStatus × ExistingUser × CurrencyIson × IsTest) combination. Written by SP_eMoney_Aggregated_Tribe_Balance via incremental DELETE+INSERT from ETL_AccountSnapshot staging data.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | ETL_AccountSnapshot (internal DWH staging from FiatDwhDB); enriched by eMoney_Dim_Account (SubProgram, IsTest) and eMoney_EntityByCurrencyISO_MappingStatic (Entity, currency name). Written by SP_eMoney_Aggregated_Tribe_Balance. |
| **Refresh** | Daily incremental DELETE+INSERT — deletes from last BalanceDateID and re-inserts from that point. No full truncate. |
| **Synapse Distribution** | HASH(BalanceDateID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Aggregated_Tribe_Balance` is the daily balance and account-health aggregation table for all eToro Money accounts held at Tribe Payments. It provides CASS (Client Asset Segregation Scheme) monitoring metrics, funding activity signals, and dormancy indicators needed for regulatory reporting and operational oversight.

**Grain**: One row per (BalanceDate × Entity × Program × AccountSubProgram × AccountStatus × ExistingUser × EpmMethodID × CurrencyIson × IsTest). A single balance date produces ~130 rows across all entity/program/status combinations. The table has 67,580 rows covering daily snapshots from 2024-01-31 to 2026-04-11.

**Three entities** are tracked:
- **eToro Money UK** (CurrencyIson=826, GBP) — 638,710 accounts across UK CARD GBP, UK IBANO, UK FTD, UK GBP FOR UAE programs
- **eToro Money Malta** (CurrencyIson=978 EUR + 208 DKK) — 1,356,805 accounts across EU Card, EU IBANO, EU FTD, EU TEST variants, Banking Circle DKK programs
- **eToro Money AUS** (CurrencyIson=36, AUD) — 39,762 accounts via Banking Circle AUD Account

**Balance semantics**: `BalanceDate` = the actual account balance date (ETL snapshot date minus 1 day). `Date` = the ETL processing date. `WorkDate` = the Tribe API processing timestamp. BalanceDateID is the integer YYYYMMDD of BalanceDate.

**Account activity flags**: `Active30`/`Active90` = accounts whose `AccountDateTimeUpdated` falls within the 30/90-day window before BalanceDate. `NeverActive` = accounts where AccountDateUpdated equals AccountDateCreated (never had a transaction or status change). `FundedAccounts` = accounts with SettledBalance > 0. `FundedAbove5` = accounts with SettledBalance > 5 (meaningful funded threshold).

**CASS split**: `CASSBalances` = sum of positive settled balances (customer money that must be segregated). `NegativeBalances` = sum of overdrawn balances (regulatory exception — should be zero in healthy state). `TotalBalances` = net sum (CASSBalances + NegativeBalances).

**ExistingUser flag**: 1 if the account's GCID is found in eMoney_Dim_Account with GCID_Unique_Count=1; 0 for accounts not yet matched to a known eToro customer (typically provisioned-but-unverified accounts).

**IsTest flag**: 1 for accounts flagged as test accounts in eMoney_Dim_Account.IsTestAccount.

The table supports the "Aggregated Tribe Balance" Tableau dashboard and CASS prudential reporting.

---

## 2. Business Logic

### 2.1 Balance Date vs. Snapshot Date Offset

**What**: The balance date lags the ETL snapshot date by 1 day.
**Columns Involved**: `BalanceDate`, `BalanceDateID`, `Date`, `DateID`, `WorkDate`
**Rules**:
- `Date` = ETL_AccountSnapshot.Date (the day the snapshot was taken, i.e., "tomorrow" from a balance perspective)
- `BalanceDate` = Date − 1 day
- `BalanceDateID` = FORMAT(BalanceDate, 'yyyyMMdd') as INT
- The SP uses `DateID >= @ReportDateID` to select incomplete dates for refresh

### 2.2 Program Classification (14 Categories)

**What**: ProgramId integer is mapped to a human-readable program name.
**Columns Involved**: `ProgramId`, `Program`
**Rules**:
- 39 = UK CARD GBP
- 175 = UK IBANO
- 176 = EU TEST IBANO
- 177 = EU IBANO
- 178 = UK FTD
- 179 = EU FTD
- 180 = UK GBP FOR UAE
- 181 = EU TEST BC
- 182 = EU Card
- 183 = Banking Circle AUD Account (Australia, added 2025-09-28)
- 184 = Banking Circle DKK Account (Denmark, added 2025-09-28)
- 185 = Banking Circle DKK Test
- 186 = Banking Circle AUD Test
- Else = NA

### 2.3 Incremental Load Logic

**What**: The SP avoids full truncate by rolling back only the last partially-loaded date and forward.
**Columns Involved**: `BalanceDateID`, `DateID`
**Rules**:
- `@AGGDateID` = MAX(DateID) from current table
- `@BalanceDateID` = MIN(BalanceDateID) where DateID = @AGGDateID
- DELETE all rows where BalanceDateID >= @BalanceDateID
- Re-insert from ETL_AccountSnapshot where DateID >= @AGGDateID
- Deduplication: ROW_NUMBER() OVER (PARTITION BY AccountId, BalanceDate ORDER BY Created DESC) = 1

### 2.4 Account Existence and Test Flags

**What**: Accounts not yet matched to a known eToro customer are flagged as new/unmatched.
**Columns Involved**: `ExistingUser`, `IsTest`, `AccountSubProgramID`, `AccountSubProgram`
**Rules**:
- eMoney_Dim_Account is joined via `ProviderCurrencyBalanceID = AccountId` (dim1) OR `ProviderHolderID = HolderId` (dim2), with GCID_Unique_Count=1 filter
- ExistingUser = 0 when both join paths return NULL (unmatched account)
- IsTest comes from eMoney_Dim_Account.IsTestAccount
- AccountSubProgramID/AccountSubProgram use COALESCE(dim1, dim2) preference order

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(BalanceDateID) distributes rows evenly across balance dates. Most queries filter by BalanceDateID or BalanceDate — this ensures data locality. The HEAP index is suitable for the aggregated grain (no row-level updates after insert).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily CASS balance by entity | `WHERE BalanceDateID = ? GROUP BY Entity` |
| Active account trend over time | `SELECT BalanceDate, Entity, SUM(Active30) GROUP BY BalanceDate, Entity` |
| Funded account penetration | `SUM(FundedAccounts) / NULLIF(SUM(TotalAccounts),0) WHERE IsTest=0` |
| Overdrawn account report | `WHERE OverdrawnAccounts > 0 AND IsTest=0` |
| Program mix by entity | `WHERE BalanceDateID = ? GROUP BY Entity, Program ORDER BY SUM(TotalAccounts) DESC` |
| EUR vs GBP vs AUD split | `WHERE BalanceDateID = ? GROUP BY CurrencyIson` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_Dim_Account | `AccountSubProgramID = mda.AccountSubProgramID` | Enrich with GCID-level customer details |
| eMoney_EntityByCurrencyISO_MappingStatic | `CurrencyIson = mebcims.CurrencyISO` | Resolve CurrencyIson → currency name/entity |

### 3.4 Gotchas

- **BalanceDate ≠ Date**: The actual balance date is always 1 day before the ETL processing date. Use `BalanceDate` for financial reporting, `Date` for ETL lineage.
- **IsTest=1 rows**: Test accounts are included in all aggregations. Always filter `WHERE IsTest=0` for business metrics.
- **NULL AccountSubProgramID**: Rows where the account is not matched to eMoney_Dim_Account will have NULL AccountSubProgramID/AccountSubProgram. These represent accounts not yet provisioned in the full account dimension.
- **NULL EpmMethodID**: The EpmMethodID column comes from ETL_AccountSnapshot and can be NULL (empty string in some rows) when the payment method is not set.
- **ExistingUser=0 group**: These are provisioned-but-unmatched accounts. Exclude for customer-level reporting.
- **Incremental rollback**: The last 1-2 days of data may be reprocessed on each run. Do not treat the max BalanceDateID as final until confirmed by the next day's run.

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
| 1 | BalanceDate | date | YES | The actual account balance date — one day before the ETL snapshot date. Represents the day for which balances are being reported. Use this (not Date) for financial and regulatory reporting. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 2 | BalanceDateID | int | NO | Integer YYYYMMDD representation of BalanceDate. Distribution key. Enables partition-aware queries by balance date. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 3 | Date | date | YES | ETL processing/snapshot date — the day ETL_AccountSnapshot was populated, which is BalanceDate + 1. Use for ETL lineage tracing only. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 4 | DateID | int | YES | Integer YYYYMMDD of Date (ETL processing date). Matches ETL_AccountSnapshot.DateID. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 5 | WorkDate | datetime | YES | Tribe API processing timestamp from ETL_AccountSnapshot. Represents when Tribe generated the account snapshot. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 6 | Entity | varchar(50) | YES | eToro Money legal entity derived from CurrencyISO mapping. Values: eToro Money UK (GBP), eToro Money Malta (EUR/DKK), eToro Money AUS (AUD). (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance via eMoney_EntityByCurrencyISO_MappingStatic) |
| 7 | ProgramId | int | YES | Tribe program identifier for the account type. 39=UK CARD GBP, 175=UK IBANO, 176=EU TEST IBANO, 177=EU IBANO, 178=UK FTD, 179=EU FTD, 180=UK GBP FOR UAE, 181=EU TEST BC, 182=EU Card, 183=Banking Circle AUD Account, 184=Banking Circle DKK Account, 185=Banking Circle DKK Test, 186=Banking Circle AUD Test. See Program column for names. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 8 | Program | varchar(50) | NO | Human-readable program name mapped from ProgramId via SP CASE statement. 39=UK CARD GBP, 175=UK IBANO, 177=EU IBANO, 182=EU Card, 183=Banking Circle AUD Account, 184=Banking Circle DKK Account, and 8 others. 'NA' for unmapped ProgramIds. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 9 | AccountSubProgramID | int | YES | Sub-program identifier from eMoney_Dim_Account, matched via ProviderCurrencyBalanceID or ProviderHolderID. NULL when account is not matched to a known customer. FK to eMoney_Dictionary_AccountSubProgram. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance via eMoney_Dim_Account) |
| 10 | AccountSubProgram | varchar(50) | YES | Sub-program name from eMoney_Dim_Account. Examples: IBAN Black, IBAN Silver, Card Standard. NULL when account unmatched. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance via eMoney_Dim_Account) |
| 11 | EpmMethodID | int | YES | Electronic Payment Method ID from ETL_AccountSnapshot. Identifies the payment rail type for the account. NULL when not set by Tribe. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 12 | AccountStatus | nvarchar(max) | YES | Current account status from ETL_AccountSnapshot.AccountStatusDescription. Values: Active, Suspended, Blocked. Maps to eMoney_Dictionary_AccountStatus values (0=Active, 1=Suspended, 2=Deleted). (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 13 | ExistingUser | int | NO | Flag: 1 if the account's HolderId or AccountId matches a known eToro customer in eMoney_Dim_Account (GCID_Unique_Count=1); 0 for unmatched/provisioned-but-unverified accounts. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 14 | TotalAccounts | int | YES | Count of distinct AccountIds in this (BalanceDate × grouping) combination after row deduplication (latest Created per AccountId per BalanceDate). (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 15 | TotalIBANS | int | YES | Count of distinct BankAccountIds (IBAN assignments) in this grouping. Zero for card-only programs. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 16 | FundedAccounts | int | YES | Count of accounts with SettledBalance > 0 (positive balance) on BalanceDate. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 17 | FundedAbove5 | int | YES | Count of accounts with SettledBalance > 5 (meaningful funded threshold, e.g., excluding micro-balances and rounding artefacts). (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 18 | Active30 | int | YES | Count of accounts with AccountDateTimeUpdated within 30 days before BalanceDate. Measures accounts with recent activity or status changes. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 19 | Active90 | int | YES | Count of accounts with AccountDateTimeUpdated within 90 days before BalanceDate. 90-day activity window for dormancy/retention analysis. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 20 | NeverActive | int | YES | Count of accounts where AccountDateUpdated = AccountDateCreated — accounts that have never had any activity or status change since creation. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 21 | OverdrawnAccounts | int | YES | Count of accounts with SettledBalance < 0 on BalanceDate. Regulatory exception — should be zero in a healthy CASS-compliant state. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 22 | NegativeBalances | money | YES | Sum of settled balances for overdrawn accounts (SettledBalance WHERE SettledBalance < 0). Represents the total negative exposure. Expected to be 0 or near-zero for regulatory compliance. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 23 | CASSBalances | money | YES | Sum of settled balances for accounts with positive balance (SettledBalance WHERE SettledBalance >= 0). CASS = Client Asset Segregation Scheme — this is the client money that must be held in segregated bank accounts. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 24 | TotalBalances | money | YES | Net sum of all settled balances (CASSBalances + NegativeBalances). Equals the total Tribe-held balance for this entity/program/status combination. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 25 | UpdateDate | datetime | NO | ETL run timestamp — GETDATE() at INSERT time. Indicates when this row was last computed and inserted. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 26 | CurrencyIson | int | YES | ISO 4217 numeric currency code. 826=GBP (UK), 978=EUR (Malta), 36=AUD (Australia), 208=DKK (Denmark). Identifies the account currency within the entity. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance) |
| 27 | HolderCurrency | varchar(256) | YES | Currency name from eMoney_EntityByCurrencyISO_MappingStatic.CurrencyName, matched via CurrencyISO = CurrencyIson. Examples: GBP, EUR, AUD, DKK. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance via eMoney_EntityByCurrencyISO_MappingStatic) |
| 28 | IsTest | int | YES | 1 if the account is flagged as a test account in eMoney_Dim_Account.IsTestAccount; 0 for production accounts; NULL when account is not matched to eMoney_Dim_Account. Always exclude IsTest=1 from business reporting. (Tier 2 — SP_eMoney_Aggregated_Tribe_Balance via eMoney_Dim_Account) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|--------------|-----------|
| BalanceDate | ETL_AccountSnapshot | Date | DATEADD(dd,-1,Date) |
| Date | ETL_AccountSnapshot | Date | Direct (ETL processing date) |
| DateID | ETL_AccountSnapshot | DateID | Direct |
| ProgramId | ETL_AccountSnapshot | ProgramId | Direct |
| AccountStatus | ETL_AccountSnapshot | AccountStatusDescription | Renamed |
| EpmMethodID | ETL_AccountSnapshot | EpmMethodID | Direct |
| CurrencyIson | ETL_AccountSnapshot | CurrencyIson | Direct |
| Entity | eMoney_EntityByCurrencyISO_MappingStatic | Entity | JOIN on CurrencyISO |
| HolderCurrency | eMoney_EntityByCurrencyISO_MappingStatic | CurrencyName | JOIN on CurrencyISO |
| AccountSubProgramID | eMoney_Dim_Account | AccountSubProgramID | LEFT JOIN via ProviderCurrencyBalanceID |
| AccountSubProgram | eMoney_Dim_Account | AccountSubProgram | LEFT JOIN via ProviderCurrencyBalanceID |
| IsTest | eMoney_Dim_Account | IsTestAccount | LEFT JOIN, renamed |
| TotalAccounts–NegativeBalances | ETL_AccountSnapshot | SettledBalance, AccountId, etc. | Aggregated (COUNT/SUM) |

### 5.2 ETL Pipeline

```
FiatDwhDB (FiatAccount, FiatCurrencyBalances, FiatCards, FiatBankAccount)
  |-- Generic Pipeline (Bronze export) --|
  v
eMoney_dbo.ETL_AccountSnapshot  (internal staging — daily snapshot per account/currency)
  |
  +-- JOIN eMoney_dbo.eMoney_Dim_Account (SubProgram, IsTest via GCID_Unique_Count=1)
  |
  +-- JOIN eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic (Entity, HolderCurrency)
  |
  |-- SP_eMoney_Aggregated_Tribe_Balance @d DATE
  |   DELETE WHERE BalanceDateID >= last_partial_date
  |   INSERT aggregated metrics by entity/program/substatus/currency
  v
eMoney_dbo.eMoney_Aggregated_Tribe_Balance  (67,580 rows, daily, 2024-01-31 to 2026-04-11)
  |-- Generic Pipeline (Gold export) --|
  v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountSubProgramID | eMoney_dbo.eMoney_Dictionary_AccountSubProgram | Sub-program lookup |
| CurrencyIson | eMoney_dbo.eMoney_Currency_Mapping_ISO | ISO 4217 numeric → alpha code |
| Entity, HolderCurrency | eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Source for Entity/HolderCurrency |

### 6.2 Referenced By

No documented downstream DWH tables reference eMoney_Aggregated_Tribe_Balance directly. It is consumed by the Tableau "Aggregated Tribe Balance" dashboard and external CASS regulatory reporting processes.

---

## 7. Sample Queries

### Daily CASS balance by entity for the latest available date

```sql
SELECT
    BalanceDate,
    Entity,
    CurrencyIson,
    SUM(TotalAccounts)    AS total_accounts,
    SUM(FundedAccounts)   AS funded_accounts,
    SUM(CASSBalances)     AS cass_balances,
    SUM(NegativeBalances) AS negative_balances,
    SUM(OverdrawnAccounts) AS overdrawn_accounts
FROM [eMoney_dbo].[eMoney_Aggregated_Tribe_Balance]
WHERE BalanceDateID = (SELECT MAX(BalanceDateID) FROM [eMoney_dbo].[eMoney_Aggregated_Tribe_Balance])
  AND IsTest = 0
GROUP BY BalanceDate, Entity, CurrencyIson
ORDER BY Entity, CurrencyIson;
```

### 30-day account activity trend by entity

```sql
SELECT
    BalanceDate,
    Entity,
    SUM(TotalAccounts) AS total,
    SUM(Active30)      AS active_30d,
    SUM(NeverActive)   AS never_active,
    CAST(SUM(Active30) * 100.0 / NULLIF(SUM(TotalAccounts),0) AS DECIMAL(5,2)) AS pct_active_30d
FROM [eMoney_dbo].[eMoney_Aggregated_Tribe_Balance]
WHERE BalanceDateID >= 20260301
  AND IsTest = 0
  AND ExistingUser = 1
GROUP BY BalanceDate, Entity
ORDER BY BalanceDate, Entity;
```

### Program mix at latest date (production accounts only)

```sql
SELECT
    Entity,
    Program,
    AccountSubProgram,
    SUM(TotalAccounts)  AS accounts,
    SUM(FundedAbove5)   AS funded_above5,
    SUM(TotalBalances)  AS total_balance
FROM [eMoney_dbo].[eMoney_Aggregated_Tribe_Balance]
WHERE BalanceDateID = (SELECT MAX(BalanceDateID) FROM [eMoney_dbo].[eMoney_Aggregated_Tribe_Balance])
  AND IsTest = 0
GROUP BY Entity, Program, AccountSubProgram
ORDER BY Entity, SUM(TotalAccounts) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence pages or Jira tickets found specifically documenting `eMoney_Aggregated_Tribe_Balance`. The table is referenced in the CASS prudential reporting workstream and the "Aggregated Tribe Balance" Tableau dashboard. For regulatory context, see eToro Money CASS compliance documentation.

---

*Generated: 2026-04-21 | Quality: 8.9/10 | Phases: 13/14*
*Tiers: 0 T1, 28 T2, 0 T3, 0 T4 | Elements: 28/28, Logic: 4/10, ETL: documented*
*Object: eMoney_dbo.eMoney_Aggregated_Tribe_Balance | Type: Table | Production Source: ETL_AccountSnapshot (internal staging)*
