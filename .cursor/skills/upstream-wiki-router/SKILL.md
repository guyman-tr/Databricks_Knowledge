---
name: upstream-wiki-router
description: Route Synapse External table references to their Tier 1 source wiki. Use when encountering External_ tables in SPs, tracing column lineage through the data lake, or needing upstream column descriptions for DWH wiki enrichment. Maps External_{db}_{schema}_{table} → source repo → wiki file → column knowledge.
---

# Upstream Wiki Router

## Problem This Solves

Synapse DWH stored procedures reference **External tables** that pull data from the data lake. These tables are opaque in Synapse — no column descriptions, no business logic. But the data originates from **Tier 1 production databases** that have rich wiki documentation in locally cloned repos.

This skill teaches the agent how to trace an External table back to its source wiki and inherit column knowledge.

## The Chain

```
SP references External_{db}_{schema}_{table}
    ↓
External table DDL → LOCATION = 'Bronze/{db}/{schema}/{table}'
    ↓
_generic_pipeline_mapping.json → database_name + schema_name + table_name
    ↓
Routing table → repo_folder + database_name
    ↓
{repo}/{database}/Wiki/{schema}/Tables/{schema}.{table}.md   (or Views/)
    ↓
Read wiki → inherit column descriptions, business logic, relationships
```

## Dynamic Routing File

The routing is **not hardcoded**. A scanner script discovers all wikis dynamically:

```
python tools/scan_upstream_wikis.py          # generates the routing file
python tools/scan_upstream_wikis.py --stats  # prints coverage report
```

**Output**: `knowledge/synapse/Wiki/_upstream_wiki_routing.json`

This file maps every `database_name` to its repo path, wiki path, and available schemas.
Run it when repos are cloned or wikis are added. Phase 10A reads this file automatically.

## Step-by-Step Resolution

### Step 1: Parse the External Table Name

Pattern: `External_{database}_{schema}_{table}` or `External_{database}_{dbo}_{table}`

Sometimes the schema segment is `dbo` and omitted from the Synapse name, giving `External_{database}_{table}`. Use the External table DDL (in DataPlatform repo) to confirm:

```
DataPlatform/SynapseSQLPool1/sql_dp_prod_we/BI_DB_dbo/External Tables/BI_DB_dbo.External_{name}.sql
```

The DDL's `LOCATION` field gives the definitive lake path: `Bronze/{database}/{schema}/{table}`.

### Step 2: Look Up in Generic Pipeline Mapping

Read `knowledge/synapse/Wiki/_generic_pipeline_mapping.json` (key: `mappings`). Match by:
- `datalake_path` containing the LOCATION from Step 1, OR
- `database_name` + `schema_name` + `table_name` matching the parsed segments

The mapping also tells you:
- `copy_strategy`: "Override" means the table is fully reloaded daily (column comments get wiped)
- `uc_table`: the Unity Catalog equivalent (e.g., `bi_db.bronze_fiktivo_affiliatecommission_creditcommission`)
- `frequency_minutes`: refresh cadence

### Step 3: Route to Source Repo

Load the routing file:
```
Read: knowledge/synapse/Wiki/_upstream_wiki_routing.json
```

Look up `upstream_databases[{database_name}]`. If the file doesn't exist, run:
```
Shell: python tools/scan_upstream_wikis.py
```

If `database_name` is in `pipeline_coverage.uncovered`, there's no wiki — fall back to SSDT DDL.

### Step 4: Read the Wiki

Construct the path from routing file data:
```
{repo_path}/{wiki_path}/{schema}/Tables/{schema}.{table}.md
{repo_path}/{wiki_path}/{schema}/Views/{schema}.{table}.md
```

If the mapping's `table_name` ends in `VW`, check the Views folder. The underlying table wiki may also exist — read both.

### Step 5: Inherit Knowledge

From the source wiki, extract:
- **Column descriptions** (§4 Elements table) → use for DWH wiki column descriptions
- **Business logic** (§2) → reference in DWH wiki's business logic section
- **Confidence tier**: columns inherited from Tier 1 wikis are **Tier 1** confidence
- **Relationships** (§5) → may reveal additional context (e.g., what AffiliateID maps to)

When writing DWH wiki descriptions for columns that pass through External tables:
- Prefix with the transformation applied in the SP (if any)
- Reference the source: "From {database}.{schema}.{table} via data lake"
- If the column is used as-is (no transformation), inherit the Tier 1 description directly

## Routing Table

**The authoritative routing table is dynamically generated**, not hardcoded in this skill.

```
File: knowledge/synapse/Wiki/_upstream_wiki_routing.json
Generator: python tools/scan_upstream_wikis.py
```

The routing file contains:
- `upstream_databases` — every database with a wiki, mapped to repo + path + schemas
- `pipeline_coverage.covered` — pipeline databases that have wikis
- `pipeline_coverage.uncovered` — pipeline databases with NO wiki (95 as of last scan)
- `dwh_wiki_schemas` — this repo's DWH wiki schemas (DWH_dbo, BI_DB_dbo, Dealing_dbo)

### Current Coverage (14 databases across 6 repos, ~6,800 wiki files)

| database_name | repo_folder | wiki files |
|---------------|-------------|------------|
| etoro | DB_Schema | 4,177 |
| fiktivo | ExperianceDBs | 727 |
| WalletDB | CryptoDBs | 584 |
| UserApiDB | DB_Schema | 473 |
| FiatDwhDB | BankingDBs | 245 |
| USABroker | ComplianceDBs | 141 |
| RecurringManager | PaymentsDBs | 106 |
| WalletConversionDB | CryptoDBs | 66 |
| Sodreconciliation | DB_Schema | 60 |
| MoneyBusDB | PaymentsDBs | 57 |
| RiskClassification | ComplianceDBs | 56 |
| MoneyTransfer | PaymentsDBs | 40 |
| CalendarDB | DB_Schema | 35 |
| WalletBalancesReportDB | CryptoDBs | 30 |

### Databases Without Wikis

95 pipeline databases have no wiki. When encountered, the routing file's `pipeline_coverage.uncovered` lists them. Fall back to SSDT DDL for column names/types only.

### Refreshing the Routing Table

Run the scanner whenever:
- A new repo is cloned
- A new wiki is built (Bonnie runs the batch pipeline on a new database)
- The pipeline encounters an unknown `database_name` not in the routing file

```
python tools/scan_upstream_wikis.py         # write routing file
python tools/scan_upstream_wikis.py --stats # print coverage report
```

## Naming Gotchas

| Issue | Example | Resolution |
|-------|---------|------------|
| VW suffix | `External_fiktivo_AffiliateCommission_CreditCommission` → LOCATION points to `CreditCommissionVW` | Check both Tables/ and Views/ wiki folders |
| dbo schema omitted | `External_UserApiDB_SomeTable` | Try `dbo` schema: `UserApiDB/Wiki/dbo/Tables/dbo.SomeTable.md` |
| Case mismatch | `external_walletdb_Wallet_Balance` | Normalize case when matching against routing table |
| Underscores in db name | `External_WalletBalancesReportDB_dbo_Foo` | Use longest-match: `WalletBalancesReportDB` is the database |
| Schema = database name | `fiktivo/Wiki/fiktivo/` | Some DBs have a schema with the same name as the database |
| Spelling | `ExperianceDBs` not `ExperienceDBs` | Known repo naming — use exactly `ExperianceDBs` |

## Example: Full Trace

**Input**: SP references `[BI_DB_dbo].[External_fiktivo_AffiliateCommission_CreditCommission]`

1. **Parse**: db=`fiktivo`, schema=`AffiliateCommission`, table=`CreditCommission`
2. **DDL**: `LOCATION = 'Bronze/fiktivo/AffiliateCommission/CreditCommissionVW'` → actual object is the VW
3. **Mapping**: `database_name=fiktivo, schema_name=AffiliateCommission, table_name=CreditCommissionVW`
4. **Route**: `fiktivo` → `ExperianceDBs` repo
5. **Wiki**: `ExperianceDBs/fiktivo/Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md`
6. **Inherit**: CreditID = "Credit event identifier", Commission = "Commission amount", etc.

## When to Use This Skill

- **During Phase 9/11 of DWH wiki pipeline**: When reading SP logic and encountering External_ table references
- **During Phase 10A (Upstream Wiki Bridge)**: The primary mechanism for Tier 1 inheritance
- **During column description enrichment**: To get CODE-BACKED descriptions for pass-through columns
- **When building lineage**: External tables are the bridge between Synapse and the data lake/source DBs

## Maintaining the Routing Table

When new Tier 1 repos are cloned or new wikis are built:
1. Clone the repo to `C:\Users\guyman\Documents\github\`
2. Run `python tools/scan_upstream_wikis.py` — the scanner discovers it automatically
3. No manual edits needed — the routing JSON is regenerated from disk
