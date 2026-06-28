# Migration status (2026-06-24)

Target = yesterday. Parity = migration matches gold on the common date.

---

## Proved working (parity passed)

**Facts / dims (block jobs)**
- `dictionaries`
- `fact_customeraction_etl`
- `dim_customer`
- `dim_mirror`
- `fact_snapshotcustomer`
- `fact_snapshotequity`
- `fact_currencypricewithsplit`
- `fact_deposit_state`
- `fact_cashout_state`
- `fact_regulationtransfer`
- `fact_customerunrealized_pnl`
- `fact_billingdeposit`
- `fact_billingredeem`
- `fact_billingwithdraw`
- `fact_history_cost`
- `dim_positionchangelog`
- `fact_guru_copiers`
- `dictionaries_country` — `Dim_Country` exact parity (251/251) ✅
- `channel_affiliate` — `Dim_Channel` exact parity (36/36) ✅
- `positionhedgeserverchangelog` — `Dim_PositionHedgeServerChangeLog_Snapshot` within 1-day source lag (-2,716 of 270M rows); proc proved ✅
- `fact_firstcustomeraction` — exact parity (17,808/17,808) after DE gold mirror resync ✅
- `dim_position` — new opens exact parity (1,740,243/1,740,243, $307M to the cent, 2026-06-23); closes 94.6% (1,480,866/1,565,740; -84,874 gap = historical positions not in seeded baseline); delta proc proved ✅

**SCD upstream (mirror / recompute also verified)**
- `Fact_SnapshotCustomer` — gold mirror matches at slice
- `v_fact_snapshotequity_fromdateid` — gold mirror matches at yesterday

---

## Parked (won't pursue / can't run)

| Item | Reason |
|------|--------|
| `fact_withdraw_fees` | Gold frozen at 2024-06-30; nothing current to compare |
| `fact_deposit_fees` | Data already matches gold; source table removed — no daily job possible |
| `fact_reverse_deposits` | Redundant — out of scope |
| `fact_cashout_rollback` | Redundant — out of scope |
| `_switch` tables | Synapse-only partition tables — not needed |
| `daily_marketpageviews` | DWH_pagetracking schema not mirrored — out of scope |
| `validation_cycle_gap` | QA/validation proc only, no output table — not a migration flow |

---

## Not yet addressed

None.
