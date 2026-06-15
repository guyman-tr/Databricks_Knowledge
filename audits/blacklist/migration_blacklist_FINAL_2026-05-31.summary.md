# Migration blacklist — FINAL (2026-05-31)

**Total blacklisted: 385** procedure->table pairs

- Phase A0 (auto: disabled / dead 6m / failing-only): **234**
- Phase A3 (user-confirmed from freshness review):    **151**

## By blacklist reason

| reason | count |
|---|---:|
| `A4_DAILY_365D` | 133 |
| `A3_USER_OVERRIDE` | 90 |
| `A4_DAILY_90D` | 49 |
| `A4_NEVER_SUCCEEDED` | 27 |
| `A3_DAILY_365D` | 23 |
| `A3_DAILY_90D` | 13 |
| `A0_DISABLED` | 12 |
| `A3_DAILY_30D` | 9 |
| `A3_MONTHLY_STALE` | 7 |
| `A4_HOURLY` | 6 |
| `A4_MONTHLY` | 4 |
| `A3_TABLE_MISSING` | 4 |
| `A4_DAILY_30D` | 3 |
| `A3_WEEKLY_STALE` | 3 |
| `A3_HOURLY_STALE` | 2 |

## By table schema

| schema | count |
|---|---:|
| `BI_DB_dbo` | 168 |
| `Dealing_staging` | 109 |
| `(none)` | 37 |
| `Dealing_dbo` | 31 |
| `CopyFromLake` | 14 |
| `general` | 4 |
| `main` | 4 |
| `DE_dbo` | 3 |
| `DWH_pagetracking` | 2 |
| `DWH_watchlists` | 2 |
| `eMoney_dbo` | 2 |
| `bi_output` | 2 |
| `[Dealing_dbo]` | 1 |
| `SalesForce_dbo` | 1 |
| `RawData` | 1 |
| `EXW_dbo` | 1 |
| `EXW_Wallet` | 1 |
| `[DE_dbo]` | 1 |
| `DWH_dbo` | 1 |

## By frequency

| FrequencySP | count |
|---|---:|
| `Daily` | 358 |
| `Monthly` | 15 |
| `Hourly` | 8 |
| `Weekly Sunday` | 2 |
| `(none)` | 1 |
| `Weekly Wednesday` | 1 |

_Source CSV: `audits/blacklist/migration_blacklist_FINAL_2026-05-31.csv`_