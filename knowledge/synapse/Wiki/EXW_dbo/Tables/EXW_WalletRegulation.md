# EXW_dbo.EXW_WalletRegulation

> Tracks each eToro Wallet user's current and immediately prior regulatory entity based on accepted Terms & Conditions versions. One or two rows per user per regulation type (TypeID 1–5), with IsCurrent=1 for the active regulation and IsCurrent=0 for the previous. 717,733 rows. Full reload daily from WalletDB T&C acceptance data.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions (T&C acceptance events) |
| **Writer SP** | EXW_dbo.SP_EXW_WalletRegulation |
| **Refresh** | Daily (full reload: DELETE entire table, then INSERT) |
| **Row Count** | 717,733 rows |
| **Date Range** | FromDate: 2018-08-20 to 2026-04-11 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | CLUSTERED INDEX (FromDateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not exported to data lake |

---

## 1. Business Meaning

This table tracks the regulatory entity that each Wallet user operates under, as determined by their accepted Terms & Conditions (T&C) versions. Different regulatory frameworks govern eToro Wallet operations in different jurisdictions, and users transition between frameworks when they accept updated T&C for a different entity.

For each user (GCID) and regulation type (TypeID), the table stores at most two rows:
- **IsCurrent=1**: The user's most recently accepted regulation — FromDate = when they last accepted this type's T&C; ToDate = '2999-01-01' (open-ended)
- **IsCurrent=0**: The user's second-most-recent regulation — ToDate = current.FromDate - 1 day

The five regulatory types are: 1=eToroX (main Wallet entity), 2=US, 3=Germany, 4=eToro DA, 5=eToro SEY. eToroX is the dominant regulation with 419,719 current rows.

The SP performs a full DELETE of the entire table before INSERT on every run — there is no incremental or date-partitioned logic. This means a single failed run produces an empty table until the next successful run.

No downstream SP consumers were found in the SSDT repo — this table is likely consumed directly from BI tools or ad-hoc analyst queries.

---

## 2. Business Logic

### 2.1 Full Reload Pattern

**What**: The entire table is dropped and rebuilt on each SP run.

**Columns Involved**: All columns

**Rules**:
- DELETE FROM EXW_dbo.EXW_WalletRegulation (no WHERE clause — full table wipe)
- INSERT from #union (current + previous regulation rows for all users in EXW_DimUser)
- If SP fails after DELETE and before INSERT, the table is empty until the next run

### 2.2 Current and Previous Regulation Derivation

**What**: For each user per regulation type, identify the current and immediately prior regulation period.

**Columns Involved**: GCID, TypeID, WalletRegulation, FromDate, ToDate, IsCurrent, Occurred

**Rules**:
- From CustomerTermsAndConditions: group by GCID + TypeId + WalletRegulation → take MAX(DateOccurred) as the most recent acceptance date per regulation group
- ROW_NUMBER() OVER (PARTITION BY GCID ORDER BY MaxDatePerRegulation DESC): Rn=1 → latest, Rn=2 → previous
- Current row (Rn=1): FromDate = MaxDatePerRegulation; ToDate = '2999-01-01'; IsCurrent = 1
- Previous row (Rn=2): PrevFromDate = MaxDatePerRegulation; PrevToDate = DATEADD(dd,-1, current.FromDate); IsCurrent = 0
- Users with only one accepted regulation have no previous row
- FromDate defaults to '1900-01-01' when ISNULL — for users with no dated acceptance

### 2.3 WalletRegulation Name Mapping

**What**: TypeID is mapped to a human-readable regulation entity name in the SP.

**Columns Involved**: TypeID, WalletRegulation

**Rules**:
- CASE WHEN TypeId: 1 → 'eToroX', 2 → 'US', 3 → 'Germany', 4 → 'eToro DA', 5 → 'eToro SEY'
- SP comment: "at the moment those are types for regulatory tnc, might be more types in the future, we need to have tnc IsRegulatory in this table"
- TypeIDs not in 1–5 are excluded from the SP WHERE clause

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with CLUSTERED INDEX (FromDateID ASC). The clustered index on FromDateID supports range scans by date when filtering on GCID (co-distributed with EXW_DimUser). Date-range queries on FromDate without a GCID filter will still require cross-distribution scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current regulation for a user | `SELECT WalletRegulation, FromDate FROM EXW_dbo.EXW_WalletRegulation WHERE GCID = @gcid AND IsCurrent = 1` |
| All users under a specific regulation today | `SELECT GCID FROM EXW_dbo.EXW_WalletRegulation WHERE WalletRegulation = 'US' AND IsCurrent = 1` |
| Users who changed regulation | `SELECT GCID, WalletRegulation, FromDate, ToDate FROM EXW_dbo.EXW_WalletRegulation WHERE IsCurrent = 0 ORDER BY FromDate DESC` |
| Regulation distribution by type | `SELECT TypeID, WalletRegulation, COUNT(*) AS users FROM EXW_dbo.EXW_WalletRegulation WHERE IsCurrent = 1 GROUP BY TypeID, WalletRegulation ORDER BY TypeID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `EXW_DimUser.GCID = EXW_WalletRegulation.GCID` | User profile enrichment |

### 3.4 Gotchas

- **Full table reload = no history beyond 2 rows per user per type**: Only current and immediately previous regulation are stored. Full T&C acceptance history is in WalletDB_Wallet_CustomerTermsAndConditions.
- **DELETE with no WHERE = empty table on failure**: If SP_EXW_WalletRegulation fails after the DELETE step, the table is empty. This is a single-point-of-failure pattern without a swap/staging strategy.
- **IsCurrent=0 rows are a minority**: Most users have only one regulation acceptance → only IsCurrent=1 rows exist for them.
- **FromDate='1900-01-01' means no dated T&C**: ISNULL handles users where no date was captured — treat these as "unknown acceptance date" rather than "accepted on 1900-01-01".
- **TypeID filter is hardcoded**: Only TypeIDs 1–5 are loaded. New regulatory T&C types added to WalletDB without an SSDT SP update will be silently ignored.
- **GCID NOT NULL at DDL level**: Unlike other EXW tables, GCID has a NOT NULL constraint — this table cannot contain rows with unknown users.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (source-to-target mapping confirmed in code) |
| Tier 3 | Inferred from column name, type, and surrounding context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Group Customer ID - cross-product identity key. NOT NULL (DDL constraint). Scoped to EXW_DimUser via INNER JOIN; only confirmed Wallet users appear here. HASH distribution key. (Tier 2 — SP_EXW_WalletRegulation) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Sourced from EXW_DimUser via INNER JOIN on GCID. (Tier 1 — Customer.CustomerStatic) |
| 3 | TypeID | int | YES | Regulatory T&C type identifier. Values: 1=eToroX, 2=US, 3=Germany, 4=eToro DA, 5=eToro SEY. Sourced from WalletDB_Wallet_TermsAndConditions.TypeId; SP filters to only these 5 regulatory types. (Tier 2 — SP_EXW_WalletRegulation) |
| 4 | WalletRegulation | nvarchar(124) | YES | Human-readable regulation entity name. SP-computed CASE WHEN from TypeID: 1=eToroX, 2=US, 3=Germany, 4=eToro DA, 5=eToro SEY. (Tier 2 — SP_EXW_WalletRegulation) |
| 5 | FromDate | date | YES | Start date of this regulation period — the date the user most recently accepted T&C for this TypeID. Defaults to '1900-01-01' via ISNULL when no dated acceptance exists. (Tier 2 — SP_EXW_WalletRegulation) |
| 6 | ToDate | date | YES | End date of this regulation period. '2999-01-01' for current rows (IsCurrent=1). For previous rows (IsCurrent=0): DATEADD(dd,-1, current row's FromDate). (Tier 2 — SP_EXW_WalletRegulation) |
| 7 | FromDateID | int | YES | FromDate as YYYYMMDD integer: CAST(CONVERT(VARCHAR(8), FromDate, 112) AS INT). Clustered index key — supports date-range scans. (Tier 2 — SP_EXW_WalletRegulation) |
| 8 | ToDateID | int | YES | ToDate as YYYYMMDD integer: CAST(CONVERT(VARCHAR(8), ToDate, 112) AS INT). For open-ended current rows: 29990101. (Tier 2 — SP_EXW_WalletRegulation) |
| 9 | IsCurrent | int | YES | Flag indicating whether this row represents the user's current (latest) regulation. 1 = current (latest T&C acceptance for this TypeID); 0 = immediately prior period. (Tier 2 — SP_EXW_WalletRegulation) |
| 10 | Occurred | datetime | YES | Timestamp of the most recent T&C acceptance event for this user + TypeID + WalletRegulation combination. Source: MAX(WalletDB_Wallet_CustomerTermsAndConditions.Occured). (Tier 2 — SP_EXW_WalletRegulation) |
| 11 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() at INSERT. Reflects when SP_EXW_WalletRegulation wrote this row. (Tier 2 — SP_EXW_WalletRegulation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID | EXW_dbo.EXW_DimUser | GCID | INNER JOIN scope filter |
| RealCID | etoro.Customer.CustomerStatic (via EXW_DimUser) | RealCID | Passthrough from EXW_DimUser |
| TypeID | WalletDB_Wallet_TermsAndConditions | TypeId | Passthrough; filtered to 1–5 |
| WalletRegulation | WalletDB_Wallet_TermsAndConditions | TypeId | CASE WHEN mapped to name string |
| FromDate | WalletDB_Wallet_CustomerTermsAndConditions | Occured | MAX(DateOccurred) per group; ISNULL → '1900-01-01' |
| ToDate | — | — | '2999-01-01' (current) or DATEADD(dd,-1, FromDate) (previous) |
| FromDateID | — | — | CAST(CONVERT(VARCHAR(8), FromDate, 112) AS INT) |
| ToDateID | — | — | CAST(CONVERT(VARCHAR(8), ToDate, 112) AS INT) |
| IsCurrent | — | — | ROW_NUMBER() Rn=1 → 1, Rn=2 → 0 |
| Occurred | WalletDB_Wallet_CustomerTermsAndConditions | Occured | MAX(Occurred) per group |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
CopyFromLake.WalletDB_Wallet_TermsAndConditions
  (T&C type registry: TypeId IN (1,2,3,4,5))
  |-- #map: TypeId → WalletRegulation name (CASE WHEN)
  v
CopyFromLake.WalletDB_Wallet_CustomerTermsAndConditions
  (user T&C acceptance events: Occured <= @end_date)
  |-- JOIN #map on TermsAndConditionId=VersionID
  |-- GROUP BY GCID + TypeId + WalletRegulation → MAX(DateOccurred), MAX(Occurred)
  |-- ROW_NUMBER() OVER (PARTITION BY GCID ORDER BY MaxDatePerRegulation DESC)
  |-- Rn=1 → #userlastregulation (current regulation)
  |-- Rn=2 → #userprevregulation (previous regulation)
  v
EXW_dbo.EXW_DimUser
  |-- INNER JOIN on GCID → adds RealCID; restricts to Wallet users
  |-- #current: IsCurrent=1, ToDate='2999-01-01'
  |-- #prev: IsCurrent=0, PrevToDate=DATEADD(dd,-1,current.FromDate)
  |-- UNION → #union
  |-- DELETE FROM EXW_dbo.EXW_WalletRegulation (entire table)
  v
EXW_dbo.EXW_WalletRegulation

Note: No downstream SP consumers found in SSDT repo.
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_dbo.EXW_DimUser | Scope and RealCID source |
| TypeID | WalletDB_Wallet_TermsAndConditions | T&C type registry |

### 6.2 Referenced By (other objects point to this)

No SP or view consumers found in the SSDT repo. Table may be consumed directly by BI tools.

---

## 7. Sample Queries

### Current regulation for all users

```sql
SELECT GCID, RealCID, TypeID, WalletRegulation, FromDate, Occurred
FROM [EXW_dbo].[EXW_WalletRegulation]
WHERE IsCurrent = 1
ORDER BY WalletRegulation, FromDate DESC;
```

### Users who recently changed regulation (previous regulation history)

```sql
SELECT GCID, WalletRegulation AS prev_regulation, FromDate AS prev_from, ToDate AS prev_to
FROM [EXW_dbo].[EXW_WalletRegulation]
WHERE IsCurrent = 0
ORDER BY ToDate DESC;
```

### Count of current users by regulation type

```sql
SELECT TypeID, WalletRegulation, COUNT(*) AS user_count
FROM [EXW_dbo].[EXW_WalletRegulation]
WHERE IsCurrent = 1
GROUP BY TypeID, WalletRegulation
ORDER BY TypeID;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Regulatory T&C framework details (TypeID 1–5 entity descriptions, compliance scope) may be in Confluence under Compliance or Legal workspaces.

---

*Generated: 2026-04-20 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 1 T1, 10 T2, 0 T3, 0 T4, 0 T5 | Elements: 11/11, Logic: 8/10, Source: WalletDB_Wallet_CustomerTermsAndConditions*
*Object: EXW_dbo.EXW_WalletRegulation | Type: Table | Production Source: WalletDB (via CopyFromLake pipeline)*
