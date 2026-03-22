---
object: Dealing_PreviouslyIdentifiedAbusers
schema: Dealing_dbo
type: Table
description: Daily re-registration watch list: new accounts registered today whose first name + last name exactly match a hardcoded list of ~120 known trading abusers. Triggers email alert when matches are found.
etl_sp: Dealing_dbo.SP_PreviouslyIdentifiedAbusers
frequency: Daily
status: Active (last: 2026-03-10)
row_count: ~714
distribution: HASH(CID)
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_PreviouslyIdentifiedAbusers

Daily surveillance table that checks whether any new account registered today matches the name of a previously identified abuser. The abuser list is a hardcoded set of ~120 first/last name pairs maintained in the SP body. When a match is found, the CID and registration timestamp are stored here and an email is sent to the Trading team. Includes NULL sentinel rows on no-match days.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Customer` | Customers who registered today (RegisteredReal ∈ [@Date, @NextDate)) |
| Reference | Hardcoded `#Names` table in SP | ~120 (FirstName, LastName) pairs of known abusers |
| Dimension | `DWH_dbo.Dim_Date` | DateID for sentinel row on no-match days |
| Writer | `Dealing_dbo.SP_PreviouslyIdentifiedAbusers` | Daily, OpsDB Priority 0 |

**Author**: Jenia Simonovitch (2020-07-23), migrated to Synapse 2024-03-31 (SR-244805). Last name list update: 2024-06-27 (SR-259116, 2 Konstantinos-related entries added).

**Match logic**: EXACT case-sensitive JOIN on FirstName + LastName. No fuzzy matching. Multiple variations of the same person are each listed separately (e.g., "Nicholas Harper", "Nic Harper", "Nicholas Charles Harper" are all separate entries).

**NULL sentinel rows**: Same pattern as SuspiciousActivityTrading_24H — LEFT JOIN to Dim_Date ensures one NULL row on days with no matches. Filter `WHERE CID IS NOT NULL` for actual abuser re-registrations.

**Email alert**: Also writes to `Dealing_PreviouslyIdentifiedAbusers_Email` (TRUNCATE+INSERT) to trigger daily email to Trading@etoro.com.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | datetime | NULL | Report date (the @Date parameter). Note: datetime type, not date. NULL on sentinel rows. |
| `FirstName` | varchar(30) | NULL | First name from Dim_Customer matching the abuser list entry. NULL on sentinel rows. |
| `LastName` | varchar(30) | NULL | Last name from Dim_Customer. NULL on sentinel rows. |
| `CID` | int | NULL | RealCID of the newly registered account. HASH distribution key. NULL on sentinel rows. |
| `Registered` | datetime | NULL | RegisteredReal timestamp from Dim_Customer — when the matching account actually registered. NULL on sentinel rows. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2024-03-29 → 2026-03-10 (daily since Synapse migration), 714 rows total
- Very small table — most days have a sentinel NULL row; only occasional actual matches
- HASH(CID) distribution (unusual for a date-clustered table — ROUND_ROBIN would be more typical)
- ⚠️ **Critical operational caveat**: The abuser name list is HARDCODED in the SP body (INSERT INTO #Names VALUES ...). To add or remove a suspected individual, a Dealing developer must update the SP code. This is not a configurable reference table.
- 714 rows since March 2024 migration — includes sentinel rows, so actual matches are fewer

## Business Context

Second line of defense after the primary KYC/AML checks. When a known abuser is detected re-registering under their real name, the Dealing team can proactively review and restrict the account before any abuse occurs. The table name/schema makes it clear this is for compliance and fraud prevention — data is sensitive (contains real customer names).

## Data Sensitivity

⚠️ **SENSITIVE DATA**: This table contains real first names and last names of individuals identified as past abusers. Access should be restricted. Do not expose in public dashboards or reports.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_PreviouslyIdentifiedAbusers_Email` | Email buffer (skipped — 1K-row staging) |
| `Dealing_SuspiciousActivityTrading_24H` | Companion table — active abuse detection |

## Quality Score: 8.5/10
*Strong: hardcoded list caveat, sentinel row pattern, email trigger, data sensitivity all documented. Active confirmed.*
