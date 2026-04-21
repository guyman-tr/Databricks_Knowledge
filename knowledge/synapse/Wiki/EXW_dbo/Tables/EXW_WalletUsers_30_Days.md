# EXW_dbo.EXW_WalletUsers_30_Days

> Rolling 30-day activity snapshot of eToro Wallet users with geographic enrichment and binary flags for recent login and transaction activity, rebuilt from scratch on each SP run via TRUNCATE + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Rolling Snapshot) |
| **Writer SP** | EXW_dbo.SP_EXW_WalletUsers_30_Days |
| **Refresh** | Full refresh on each run (TRUNCATE + INSERT, no date parameter) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **Author / First Created** | Guy Manova, 2019-01-20 (migrated by Inessa 2024-04-02) |

---

## 1. Business Meaning

EXW_WalletUsers_30_Days provides a current-state view of wallet user activity over the trailing 30 days, enriched with geography (country, region, continent). Each row represents one wallet user with:
- Their KYC and club status (from EXW_DimUser)
- A flag indicating whether they logged in within the last 31 calendar days
- A flag indicating whether they made a non-internal transaction in the last 31 days
- Geographic attributes at country, marketing-region, and continent level

The table is a full-refresh snapshot — it is completely rebuilt from TRUNCATE on every SP run. There is no date column or DateID; the table always reflects the current state of active-30-day users. It feeds regional aggregation dashboards and active-user reporting.

---

## 2. Business Logic

### 2.1 LoggedIn30Days Flag

**What**: Indicates whether the user has logged in within the past ~31 days.

**Columns Involved**: LoggedIn30Days, GCID

**Rules**:
- Source: `BI_DB_dbo.BI_DB_CIDFirstDates.LastLoggedIn`
- LoggedIn30Days = 1 when `BI_DB_CIDFirstDates.LastLoggedIn >= CAST(GETDATE()-31 AS DATE)`
- LoggedIn30Days = 0 when no such record exists (LEFT JOIN miss)
- Window is rolling: recalculated on each SP run

### 2.2 Transaction30Days Flag

**What**: Indicates whether the user made at least one non-internal transaction in the past ~31 days.

**Columns Involved**: Transaction30Days, GCID

**Rules**:
- Source: `EXW_dbo.EXW_FactTransactions`
- Transaction30Days = 1 when any row in EXW_FactTransactions satisfies:
  - `TranDateID >= CAST(CONVERT(VARCHAR(8), GETDATE()-31, 112) AS INT)` (last 31 days)
  - `TransactionTypeID NOT IN(10,13)` (excludes internal/system transaction types 10 and 13)
- Transaction30Days = 0 when no such transactions exist (LEFT JOIN miss)
- Aggregated via MAX(TranDateID) — if any qualifying transaction exists, flag = 1

### 2.3 Continent Enrichment

**What**: Country-to-continent mapping from hardcoded ISO table.

**Columns Involved**: Continent, Country

**Rules**:
- Continent is resolved via `LEFT JOIN DWH_dbo.Dim_Country ON edu.CountryID = dc.CountryID`, then `LEFT JOIN #countryandcontinent ON dc.Abbreviation = c.CountryCode`
- `#countryandcontinent` is a 250-row ISO country→continent lookup table hardcoded in the SP
- Special case: `CASE WHEN Country = 'eToro' THEN 'eToro' ELSE Continent END` — internal/test accounts with Country='eToro' get Continent='eToro'
- Continent values: Asia, Europe, Africa, North America, South America, Oceania, Antarctica, eToro (internal)

---

## 3. Query Advisory

### 3.1 No Date Column — Always Current

This table has no Date or DateID column. It always reflects the state at the last SP run. For historical snapshots, use EXW_WalletEntity or other dated tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Active users in last 30 days | `WHERE LoggedIn30Days = 1 OR Transaction30Days = 1` |
| Transacting users by region | `WHERE Transaction30Days = 1 GROUP BY Region` |
| Fully verified active users | `WHERE VerificationLevelID = 3 AND LoggedIn30Days = 1` |
| Continental breakdown | `GROUP BY Continent ORDER BY COUNT(*) DESC` |
| Diamond club transacting users | `WHERE Club = 'Diamond' AND Transaction30Days = 1` |

### 3.3 Gotchas

- **31 vs 30 days**: The SP uses `GETDATE()-31` not `GETDATE()-30`. The window is ~31 calendar days. "30 days" in the table name is a business approximation.
- **TransactionTypeID exclusions**: Types 10 and 13 are excluded from Transaction30Days. These are internal/system transactions. Check EXW_FactTransactions transaction type dictionary if exact types matter.
- **DISTINCT in INSERT**: The SP uses `SELECT DISTINCT` to deduplicate. If a user appears multiple times in EXW_DimUser (should not happen), only one row is kept.
- **HEAP distribution**: No cluster index — full scans are expected and the table is small enough to be fast.
- **Country='eToro'**: Internal accounts may appear with Country='eToro' and Continent='eToro'. Filter with `WHERE Country != 'eToro'` for user-facing analysis.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki (via EXW_DimUser passthrough) |
| Tier 2 | Derived from SP code or DWH-computed relay column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key for this table. Passthrough from EXW_DimUser. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from EXW_DimUser. (Tier 1 — Customer.CustomerStatic) |
| 3 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. Passthrough from EXW_DimUser. (Tier 1 — BackOffice.Customer) |
| 4 | Club | varchar(100) | YES | Player level club label from Dim_PlayerLevel.Name, joined on PlayerLevelID in SP_DimUser. Common values: Bronze, Silver, Gold, Platinum, Diamond. Passthrough of EXW_DimUser.Club. (Tier 2 — SP_DimUser) |
| 5 | Country | nvarchar(50) | YES | Denormalized country name from Dim_Country.Name, joined on CountryID in SP_DimUser. Use EXW_DimUser.CountryID for joins. Passthrough of EXW_DimUser.Country. (Tier 2 — SP_DimUser) |
| 6 | Region | nvarchar(50) | YES | Marketing region name from Dim_Country.Region, derived from CountryID in SP_DimUser. Corresponds to geographic marketing groupings. Passthrough of EXW_DimUser.Region. (Tier 2 — SP_DimUser) |
| 7 | Continent | nvarchar(256) | YES | Continent derived by joining DWH_dbo.Dim_Country (on CountryID) to a hardcoded 250-row ISO country-to-continent lookup table (`#countryandcontinent`) via Dim_Country.Abbreviation. Values: Asia, Europe, Africa, North America, South America, Oceania, Antarctica, eToro (for internal accounts). NULL for countries not in the ISO table. (Tier 2 — SP_EXW_WalletUsers_30_Days) |
| 8 | LoggedIn30Days | bit | YES | 1 if the user's LastLoggedIn in `BI_DB_dbo.BI_DB_CIDFirstDates` is >= GETDATE()-31; 0 otherwise. Reflects any login in the past ~31 calendar days. (Tier 2 — SP_EXW_WalletUsers_30_Days) |
| 9 | Transaction30Days | bit | YES | 1 if the user has at least one row in EXW_FactTransactions with `TranDateID >= GETDATE()-31` and `TransactionTypeID NOT IN(10,13)`; 0 otherwise. Excludes internal transaction types 10 and 13. (Tier 2 — SP_EXW_WalletUsers_30_Days) |
| 10 | UpdateDate | datetime | YES | ETL timestamp set to `GETDATE()` at INSERT time. Reflects when SP_EXW_WalletUsers_30_Days last rebuilt this row. (Tier 2 — SP_EXW_WalletUsers_30_Days) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID | etoro.Customer.CustomerStatic | GCID | Passthrough via EXW_DimUser |
| RealCID | etoro.Customer.CustomerStatic | RealCID | Passthrough via EXW_DimUser |
| VerificationLevelID | etoro.BackOffice.Customer | VerificationLevelID | Passthrough via EXW_DimUser |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough of EXW_DimUser.Club (SP_DimUser–computed) |
| Country | DWH_dbo.Dim_Country | Name | Passthrough of EXW_DimUser.Country (SP_DimUser–computed) |
| Region | DWH_dbo.Dim_Country | Region | Passthrough of EXW_DimUser.Region (SP_DimUser–computed) |
| Continent | Hardcoded ISO table | Continent | LEFT JOIN Dim_Country → #countryandcontinent via Abbreviation |
| LoggedIn30Days | BI_DB_dbo.BI_DB_CIDFirstDates | LastLoggedIn | CASE WHEN >= GETDATE()-31 THEN 1 ELSE 0 |
| Transaction30Days | EXW_dbo.EXW_FactTransactions | TranDateID, TransactionTypeID | CASE WHEN any row qualifies THEN 1 ELSE 0 |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic + BackOffice.Customer (production OLTP)
  └─ DWH_dbo.Dim_Customer → EXW_dbo.EXW_DimUser
       ├─ GCID, RealCID, VerificationLevelID, Club, Country, Region (passthrough)
       └─ CountryID → DWH_dbo.Dim_Country (Abbreviation) → #countryandcontinent → Continent

BI_DB_dbo.BI_DB_CIDFirstDates (LastLoggedIn >= GETDATE()-31) → #fca → LoggedIn30Days flag

EXW_dbo.EXW_FactTransactions (TranDateID >= GETDATE()-31, NOT IN(10,13)) → #tx → Transaction30Days flag

TRUNCATE TABLE EXW_dbo.EXW_WalletUsers_30_Days
INSERT INTO EXW_dbo.EXW_WalletUsers_30_Days (SELECT DISTINCT from #users)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | Primary source — all columns except flags come from EXW_DimUser |
| GCID | BI_DB_dbo.BI_DB_CIDFirstDates | Source of LoggedIn30Days flag |
| GCID | EXW_dbo.EXW_FactTransactions | Source of Transaction30Days flag |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| Regional aggregation dashboards | Active user counts by continent and region |
| Activity reporting | 30-day active user KPIs |

---

## 7. Sample Queries

### Active wallet users by continent

```sql
SELECT Continent,
       COUNT(*) AS total_users,
       SUM(LoggedIn30Days) AS logged_in,
       SUM(Transaction30Days) AS transacting
FROM [EXW_dbo].[EXW_WalletUsers_30_Days]
WHERE Country != 'eToro'  -- exclude internal accounts
GROUP BY Continent
ORDER BY total_users DESC;
```

### Verified users who have been active in last 30 days

```sql
SELECT Country, Region, COUNT(*) AS active_verified
FROM [EXW_dbo].[EXW_WalletUsers_30_Days]
WHERE VerificationLevelID = 3
  AND (LoggedIn30Days = 1 OR Transaction30Days = 1)
GROUP BY Country, Region
ORDER BY active_verified DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for EXW_WalletUsers_30_Days. Original author: Guy Manova (2019-01-20). Migrated to Synapse by Inessa (2024-04-02).

---

*Generated: 2026-04-20 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 3 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10*
*Object: EXW_dbo.EXW_WalletUsers_30_Days | Type: Table | Production Sources: etoro.Customer.CustomerStatic + BackOffice.Customer (via EXW_DimUser)*
