# BI_DB_dbo.BI_DB_AffiliateFTDsAndURLS

Generated: 2026-04-21 | Writer SP: SP_AffiliateFTDsAndURLS | Batch 13 #3

## Business Meaning

Per-affiliate daily FTD and registration activity tracker, broken down by **regulatory entity** and **special countries** (Spain, France). Each row represents one affiliate's activity for a specific FTD date × registration date combination where at least one of those dates matches the SP parameter (`@Date`).

The table links each affiliate's **referred clients** (via BI_DB_CIDFirstDates) to their **FTD and registration events** on a given day, counting clients by regulation (EU, ASIC, US, FCA, FSA Seychelles, FSRA). It also records the affiliate's own eToro trading account (`CID` = `TradingAccount_RealCID` from Dim_Affiliate) and referral website (`WebSiteURL`).

**Changed from monthly to daily** frequency in February 2025 (Pavlina Masoura, 2025-02-17).

**Row count**: 371,656 | **FTD date range**: 1900-01-01 to 2026-04-12 (29,564 rows have 1900-01-01 = registration-only rows) | **Registration date range**: 2008-03-20 to 2026-04-12 | **Grain**: AffiliateID × SubChannel × WebSiteURL × FTD date × Registration date

---

## Business Logic

### Daily Refresh (DELETE + INSERT per Date)
The SP parameter `@Date` drives a targeted refresh: rows are **deleted** where `FirstDepositDate = @Date` OR `Registered = @Date`, then fresh aggregates are inserted. This means any rerun for a date fully replaces that date's data.

### Grain: Per-Affiliate × Per FTD/Reg Date Pair
The SP fetches all clients of each affiliate who had **either** a registration or an FTD on `@Date`. It then groups by `(AffiliateID, SubChannel, WebSiteURL, FirstDepositDate, Registered)`. This means:
- A client who registered on @Date but had their FTD on a different date creates a row with `Registered=@Date`, `FirstDepositDate=<other date>`.
- A client who had their FTD on @Date but registered earlier creates a row with `FirstDepositDate=@Date`, `Registered=<other date>`.
- Both events on the same day creates one combined row.

The result is that a single affiliate can have **multiple rows per run** for different date-pair combinations.

### Regulation Breakdown (DesignatedRegulationID)
FTD and Registration counts are split by `DesignatedRegulationID` from BI_DB_CIDFirstDates:

| Column Suffix | Regulation IDs | Entity |
|--------------|---------------|--------|
| _EU | 1 | EU regulation |
| _ASIC | 4, 10 | Australian Securities and Investments Commission |
| _US | 6, 7, 8 | US regulations |
| _FCA | 2 | UK Financial Conduct Authority |
| _FSA_Seychelles | 9 | Financial Services Authority (Seychelles) — FTDs only |
| _FSRA | 11 | Financial Services Regulatory Authority |

Spain and France are geographic breakdowns of FTDs only (no Registration_Spain/France columns).

### Channel Filter
The SP filters `fd.Channel = 'Affiliate'` — only affiliate-channel clients are counted. This is a **narrower filter** than Objects #1 and #2 in this batch, which also included 'Introducing Agents'.

### CID = Affiliate's Own Trading Account
The `CID` column stores `da.TradingAccount_RealCID` — the affiliate's **own** eToro real-money trading account CID, resolved from Dim_Affiliate. This is **not** a client CID. It is used to identify the affiliate entity in the eToro trading platform.

---

## Query Advisory

- **Filter `YEAR(FirstDepositDate) != 1900`** when analyzing FTD metrics. The 29,564 rows with `FirstDepositDate = 1900-01-01` are registration-only rows where no FTD occurred on `@Date`. Use `Registered` for registration analysis on those rows.
- **FTDs_Total and Registration_Total are inflated by 1** for registration-only / FTD-only rows respectively — the SP uses `ELSE 0` (not `ELSE NULL`) in `COUNT(DISTINCT CASE ...)`, causing 0 to be counted as a distinct non-NULL value. These metrics overcount by 1 on rows where the other event type didn't occur on `@Date`. See review notes.
- **One affiliate can have multiple rows per day** — an affiliate with both registering clients and depositing clients on the same date (from different original registration dates) will produce separate rows per FTD-date × Reg-date combination. Do not assume one row per affiliate per day.
- **CID is the affiliate's own CID**, not a client's CID. Do not join on `BI_DB_CIDFirstDates.CID` via this column.
- **ROUND_ROBIN distribution, HEAP** — no clustered index, suited for bulk load patterns. Full table scans are common; add `FirstDepositDate` or `Registered` predicates.

---

## Elements

| # | Column | Type | Description | Tier |
|---|--------|------|-------------|------|
| 1 | AffiliateID | BIGINT | Unique affiliate partner identifier from AffWizz system. Primary key. | Tier 1 — DWH_dbo.Dim_Affiliate |
| 2 | SubChannel | NVARCHAR(500) | Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. | Tier 2 |
| 3 | CID | INT | Affiliate's own eToro real-money CID, resolved via COALESCE across 4 username lookups against Ext_Dim_Affiliate_Customer. NULL if no match. This is the affiliate's trading account — not a client CID. | Tier 1 — DWH_dbo.Dim_Affiliate |
| 4 | WebSiteURL | NVARCHAR(MAX) | Affiliate's website URL used for referral traffic. | Tier 1 — DWH_dbo.Dim_Affiliate |
| 5 | FTDYear | INT | Calendar year of the FTD date (YEAR(FirstDepositDate)). 1900 for registration-only rows. | Tier 2 |
| 6 | FTDMonth | INT | Calendar month of the FTD date (MONTH(FirstDepositDate)). 1 for registration-only rows with 1900-01-01 date. | Tier 2 |
| 7 | FTDYearMonth | INT | Compact year-month of FTD date as integer: CONVERT(VARCHAR(6), FirstDepositDate, 112). E.g. 202604 for April 2026. 190001 for registration-only rows. | Tier 2 |
| 8 | FTDs_EU | BIGINT | Count of distinct clients (by CID) who made their FTD on @Date under EU regulation (DesignatedRegulationID=1). | Tier 2 |
| 9 | FTDs_ASIC | BIGINT | Count of distinct clients who made their FTD on @Date under ASIC regulation (DesignatedRegulationID IN (4,10)). | Tier 2 |
| 10 | FTDs_US | BIGINT | Count of distinct clients who made their FTD on @Date under US regulation (DesignatedRegulationID IN (6,7,8)). | Tier 2 |
| 11 | FTDs_FCA | BIGINT | Count of distinct clients who made their FTD on @Date under FCA regulation (DesignatedRegulationID=2). | Tier 2 |
| 12 | FTDs_Total | BIGINT | Count of distinct clients who made their FTD on @Date (all regulations). NOTE: inflated by 1 for rows with no FTDs on @Date due to ELSE 0 in COUNT DISTINCT — see review notes. | Tier 2 |
| 13 | Registration_US | BIGINT | Count of distinct clients who registered on @Date under US regulation (DesignatedRegulationID IN (6,7,8)). | Tier 2 |
| 14 | Registration_ASIC | BIGINT | Count of distinct clients who registered on @Date under ASIC regulation (DesignatedRegulationID IN (4,10)). | Tier 2 |
| 15 | Registration_EU | BIGINT | Count of distinct clients who registered on @Date under EU regulation (DesignatedRegulationID=1). | Tier 2 |
| 16 | Registration_FCA | INT | Count of distinct clients who registered on @Date under FCA regulation (DesignatedRegulationID=2). INT (not BIGINT like other Reg columns). | Tier 2 |
| 17 | Registration_Total | BIGINT | Count of distinct clients who registered on @Date (all regulations). NOTE: inflated by 1 for rows with no registrations on @Date due to ELSE 0 in COUNT DISTINCT — see review notes. | Tier 2 |
| 18 | UpdateDate | DATETIME | ETL metadata: timestamp when the row was inserted, set via GETDATE() at INSERT time. | Tier 5 |
| 19 | FTDs_Spain | BIGINT | Count of distinct clients whose Country='Spain' who made their FTD on @Date. | Tier 2 |
| 20 | FTDs_France | BIGINT | Count of distinct clients whose Country='France' who made their FTD on @Date. | Tier 2 |
| 21 | RegisteredYear | INT | Calendar year of the registration date (YEAR(registered)). | Tier 2 |
| 22 | RegisteredMonth | INT | Calendar month of the registration date (MONTH(registered)). | Tier 2 |
| 23 | RegisteredYearMonth | INT | Compact year-month of registration date: CONVERT(VARCHAR(6), registered, 112). E.g. 202604 for April 2026. | Tier 2 |
| 24 | FTDs_FSA_Seychelles | BIGINT | Count of distinct clients who made their FTD on @Date under FSA Seychelles regulation (DesignatedRegulationID=9). Added 2024-01-15. | Tier 2 |
| 25 | Registration_FSRA | BIGINT | Count of distinct clients who registered on @Date under FSRA regulation (DesignatedRegulationID=11). Added 2024-10-14. | Tier 2 |
| 26 | FTDs_FSRA | BIGINT | Count of distinct clients who made their FTD on @Date under FSRA regulation (DesignatedRegulationID=11). Added 2024-10-14. | Tier 2 |
| 27 | Registered | DATE | Client registration date cast to DATE (CAST(fd.registered AS DATE)). Rows triggered by registration events on @Date have Registered=@Date; rows triggered by FTD events may have Registered from a different day. | Tier 2 |
| 28 | FirstDepositDate | DATE | Client FTD date cast to DATE (CAST(fd.FirstDepositDate AS DATE)). 1900-01-01 for clients with no deposit (sentinel from BI_DB_CIDFirstDates). First successful deposit date; 1900-01-01 means no deposit. Filter with YEAR(FirstDepositDate) != 1900. | Tier 2 |

**Tier legend**: Tier 1 = value/description inherited verbatim from upstream DWH_dbo wiki. Tier 2 = derived by SP/ETL logic. Tier 5 = canonical ETL metadata column (UpdateDate, ETL timestamp).

**Note**: DDL defines 28 columns. Columns FTDs_FSA_Seychelles (added Jan 2024), Registration_FSRA, and FTDs_FSRA (added Oct 2024) were added incrementally. There is a column-order discrepancy between INSERT and SELECT in the SP for FTDs_FSA_Seychelles and FTDs_FSRA — see review notes.

---

## Lineage

See [BI_DB_AffiliateFTDsAndURLS.lineage.md](BI_DB_AffiliateFTDsAndURLS.lineage.md) for full ETL chain and column lineage table.

```
DWH_dbo.Dim_Affiliate
  |-- JOIN BI_DB_CIDFirstDates (Channel='Affiliate', registered=@Date OR FTD=@Date)
  |-- GROUP BY AffiliateID × SubChannel × WebSiteURL × FTD_date × Reg_date
  |-- COUNT DISTINCT CID per (RegID / Country) WHERE date=@Date
  v
SP_AffiliateFTDsAndURLS (@Date — Daily, SB_Daily, Priority 20)
  DELETE WHERE FirstDepositDate=@Date
  DELETE WHERE Registered=@Date
  INSERT
  v
BI_DB_AffiliateFTDsAndURLS (371,656 rows)
  v [UC Target: _Not_Migrated]
```

**Distribution**: ROUND_ROBIN | **Index**: HEAP | **UC Target**: _Not_Migrated

---

## Relationships

| Object | Schema | Type | Join Key | Purpose |
|--------|--------|------|----------|---------|
| Dim_Affiliate | DWH_dbo | Source/dimension | AffiliateID | AffiliateID, CID (TradingAccount_RealCID), WebSiteURL |
| BI_DB_CIDFirstDates | BI_DB_dbo | Source | SerialID = AffiliateID | Client FTD/registration dates, DesignatedRegulationID, Country, SubChannel |

---

## Sample Queries

```sql
-- Daily FTD breakdown by regulation for a specific date
SELECT
    AffiliateID,
    WebSiteURL,
    FTDs_EU,
    FTDs_ASIC,
    FTDs_US,
    FTDs_FCA,
    FTDs_FSA_Seychelles,
    FTDs_FSRA,
    FTDs_Spain,
    FTDs_France,
    FTDs_Total
FROM BI_DB_dbo.BI_DB_AffiliateFTDsAndURLS
WHERE FirstDepositDate = '2026-04-12'
ORDER BY FTDs_Total DESC;

-- Registration activity on a date (registration-only rows)
SELECT
    AffiliateID,
    SubChannel,
    Registration_EU,
    Registration_ASIC,
    Registration_US,
    Registration_FCA,
    Registration_FSRA,
    Registration_Total
FROM BI_DB_dbo.BI_DB_AffiliateFTDsAndURLS
WHERE Registered = '2026-04-12'
ORDER BY Registration_Total DESC;

-- Monthly FTD summary per affiliate (exclude 1900 sentinel dates)
SELECT
    AffiliateID,
    WebSiteURL,
    FTDYearMonth,
    SUM(FTDs_Total) AS total_ftds
FROM BI_DB_dbo.BI_DB_AffiliateFTDsAndURLS
WHERE FTDYear != 1900
GROUP BY AffiliateID, WebSiteURL, FTDYearMonth
ORDER BY total_ftds DESC;
```

---

## Atlassian

**Confluence**: [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033/Affiliates+-+System+Document) — AffWizz/affiliate platform overview relevant to AffiliateID, WebSiteURL fields.
**Jira**: No open tickets identified.

---

Quality: 8.0/10
