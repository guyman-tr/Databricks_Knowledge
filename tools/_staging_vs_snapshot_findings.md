# DWH_staging (Synapse) vs daily_snapshot (DBX) — full audit

Generated 2026-05-24 via `tools/_compare_staging_vs_snapshot.py`.
Detail CSV: `tools/_staging_vs_snapshot_diff.csv` (139 rows).

## Scoreboard

| verdict | count |
|---|---|
| MATCH (row counts identical, freshness identical where checked) | **131** |
| SYN_ONLY_MISSING (table exists only in DBX) | 4 |
| DBX_ONLY_MISSING (table exists only in Synapse) | 3 |
| DBX_SHORT (DBX < 50% of Synapse rows) | 1 |

131 / 135 common tables are bit-for-bit identical in row count, and where an
update-timestamp column exists they also match to the millisecond. The migration's
daily snapshot layer is in **very good shape overall**; the failures are localized.

---

## CRITICAL — drives observed Dim_Customer divergences

### 1. `customerfinancedb_customer_firsttimedeposits` is a VIEW pointing at the wrong source

- DBX has TWO objects with the same data signature:
  - **Table** `dwh_daily_process.daily_snapshot.customerfinancedb_customer_globalftds`
    = **1,074 rows** (min Gcid 1,663,695 / max 48,378,600 / sum_gcid 43,304,142,235)
  - **View**  `dwh_daily_process.daily_snapshot.customerfinancedb_customer_firsttimedeposits`
    = **5,566,497 rows** — body is `SELECT * FROM main.bi_db.bronze_customerfinancedb_customer_firsttimedeposits` (full history bronze)
- Synapse equivalent `DWH_staging.CustomerFinanceDB_Customer_FirstTimeDeposits`
  = **1,074 rows** (signature **identical** to the DBX table).

So the proper snapshot exists and matches Synapse exactly, but the view shadows
it with the historical bronze table. `sp_dim_customer_dl_to_synapse` reads
`...daily_snapshot.CustomerFinanceDB_Customer_FirstTimeDeposits` — hits the view
— and dumps 5.5M rows of historical FTDs into
`Ext_CustomerFinanceDB_Customer_FirstTimeDeposits` (vs 1,074 in Synapse).

This is the root cause of the `FTDPlatformID` reassignments
(−110k TradingPlatform / +89k eMoney) and the `IsDepositor` shortfall we observed
in `Dim_Customer`.

**Fix (one-liner):**
```sql
CREATE OR REPLACE VIEW dwh_daily_process.daily_snapshot.customerfinancedb_customer_firsttimedeposits
AS SELECT * FROM dwh_daily_process.daily_snapshot.customerfinancedb_customer_globalftds;
```
or drop the view and rename the table. Either way, no SP changes are needed.

### 2. `sts_audit_useroperationsdata` snapshot is **1 day deep**, Synapse is **8 days deep**

| side | rows | min(CreatedAt) | max(CreatedAt) | span |
|---|---:|---|---|---|
| Synapse `DWH_staging.STS_Audit_UserOperationsData` | 53,075,981 | 2026-05-16 00:00 | 2026-05-23 23:59:59 | **8 days** |
| DBX `daily_snapshot.sts_audit_useroperationsdata` | 6,879,309 | 2026-05-23 00:00 | 2026-05-23 23:59:59 | **0 days (1 file)** |

The 2FA INSERT does `ROW_NUMBER() OVER (PARTITION BY Gcid ORDER BY CreatedAt DESC)
... WHERE LoginTypeName in ('TwoFactor_UpdatedByUser','TwoFactor_UpdatedByAdmin')`.
If a user's last 2FA toggle happened before 2026-05-23, their state is invisible
in DBX → directly produces the `-87%` shortfall in `Ext_Dim_Customer_2FA`
(33,586 in Synapse vs 4,320 in DBX).

This is the second root cause of the `Dim_Customer` divergences.

**Fix:** extend the daily_snapshot retention for this table from 1 day to the
same window Synapse keeps (looks like rolling 7-day or longer). Note that the
SP's "latest 2FA toggle per Gcid" semantics arguably want **lifetime** retention
(or a pre-aggregated current-state view).

---

## HIGH — entirely missing tables in DBX

### 3. `IP2Location` — 5,311,956 rows in Synapse, missing in DBX
No object with this name exists anywhere in `main.*` or `dwh_daily_process.*`.
If any SP joins to it (typical use: IP → country/region lookup), that path is
silently broken.

### 4. `PriceLog_History_CurrencyPrice_Active_5_days` — 632,245,921 rows in Synapse, missing in DBX
The 1-day variant `PriceLog_History_CurrencyPrice_Active` (62M rows) is present
and matches exactly, but the 5-day rolling variant was never migrated. If any
mark-to-market / EOD pricing job depends on 5-day rolling pricing, it will fail
or fall back to 1-day.

---

## INFO — Synapse-only tables (exist in DBX but not in Synapse `DWH_staging`)

These do not point to drift, they're just objects that were either renamed
on migration or added later in DBX without a matching staging table:

| DBX-only table | DBX rows | note |
|---|---:|---|
| `customerfinancedb_customer_globalftds` | 1,074 | renamed version of the FTD table — see finding #1 |
| `etoro_backoffice_campaign` | 15,571 | new table, no Synapse equivalent in `DWH_staging` |
| `fiktivo_dbo_tblaff_affiliatesgroups` | 243 | likely overlap with the existing `fiktivo_affiliateadmin_affiliatesgroups` (248 rows) — verify before relying on either |
| `userapidb_dictionary_tanganystatus` | 6 | small dictionary table, likely fine |

---

## 131 MATCH tables — what "MATCH" means

Row count is identical to the row in Synapse, and where the script could find
a recognized update-timestamp column (`UpdateDate` / `ValidFrom` / `Occurred` /
`DateAdded` / `ModifiedDate` / `LastUpdateDate` / `CreatedAt` / `Updated`),
the MAX timestamp also matched to the millisecond.

Largest matched tables sanity-check well:

| table | rows |
|---|---:|
| `etoro_history_backofficecustomer` | 612,031,423 |
| `etoro_trade_openpositionendofday` | 138,584,405 |
| `etoro_history_withdrawtofundingaction` | 144,631,847 |
| `etoro_history_withdrawaction` | 102,137,787 |
| `etoro_trade_positionshedgeserverchangelog` | 84,651,136 |
| `etoro_history_mirror` | 70,616,948 |
| `pricelog_history_currencyprice_active` | 62,007,759 |
| `fiktivo_affiliatecommission_registrationcommission` | 50,346,420 |
| `etoro_customer_customer` / `etoro_customer_customerstatic` / `etoro_backoffice_customer` | 47,867,332 |
| `fiktivo_affiliatecommission_registration` | 47,444,166 |
| `etoro_backoffice_customerdocument` | 44,065,455 |
| `etoro_backoffice_customerdocumenttodocumenttype` | 41,629,657 |
| `etoro_backoffice_customeralltimeaggregateddata` | 40,776,256 |
| `fiktivo_affiliatecommission_credit` | 40,513,062 |

Caveat: row count + max timestamp match does not prove row-level content match.
Anything driven by a `WHERE …` filter that's wrong on either side could still
diverge. If a specific Dim/Fact downstream looks suspicious, do a hash/aggregate
spot-check on the relevant columns (as we did for FTD: `min/max/sum GCID`).

---

## Recommended next actions

1. **Repoint the FTD view** (1-line SQL fix) — fixes the `Dim_Customer.IsDepositor` and `FTDPlatformID` skew immediately.
2. **Backfill `sts_audit_useroperationsdata`** with the full Synapse window (or change snapshot retention to ≥ 7 days, ideally lifetime for 2FA semantics) — fixes the `2FA` shortfall.
3. **Decide on `IP2Location` and `PriceLog_History_CurrencyPrice_Active_5_days`** — either migrate them or audit which SPs/views still reference them and rewrite.
4. **Audit `dwh_daily_process.daily_snapshot.*` for other VIEW masks** — only one was found this round (`customerfinancedb_customer_firsttimedeposits`), but it's worth a one-time scan whenever new objects land.
