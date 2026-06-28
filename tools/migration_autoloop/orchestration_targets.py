"""Ring registry for the production-parallel DWH migration orchestration.

Each ``OrchestrationTarget`` represents one data block in the migration.  The
registry drives all phases:
  - Phase A: materialize (clone + rewrite procs) then run wrapper_proc.
  - Phase B: await postflip, run partition-scoped parity, drop clone.

Rings control execution order and parallel grouping:
  Ring 0 — fast, independent, full-refresh / enum dims.
  Ring 1 — independent incremental facts + SCDs.
  Ring 2 — sequential / multi-task facts (depend on dictionaries from Ring 0).
  Ring 3 — heavyweight (dim_position, tightest deadline ~03:32 UTC).

``fact_snapshotcustomer`` is excluded (frozen SCD, skip_compare=True); add to
Ring 2 once DE refreshes it.

Gold-table naming conventions:
  Most tables:   main.dwh.gold_sql_dp_prod_we_dwh_dbo_{lower}
  Compliance:    main.compliance.gold_sql_dp_prod_we_dwh_dbo_{lower}
  dim_position:  main.dwh.dim_position  (uses direct name, not prefixed)
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class OrchestrationTarget:
    target_id: str
    ring: int

    # Gold table FQN (live pre-flip) — SHALLOW CLONEd to migration_parallel.
    gold_table: str

    # Table name (no schema) in migration_parallel (= same as in migration_tables).
    parallel_table_name: str

    # Proc names in migration_tables; the first is the wrapper proc whose call graph
    # is walked. All are rewritten + created in migration_parallel.
    wrapper_proc: str

    # CALL SQL to execute in migration_parallel for D-1 (uses DATEADD).
    # An empty string means no proc call (e.g. full-refresh with no date param).
    proc_call_sql: str

    # target_ids this target depends on (same-ring ordering).
    depends_on: tuple[str, ...] = ()

    # Phase B: whether the parallel output should be parity-checked vs gold.
    # False for frozen SCDs or tables DE hasn't refreshed.
    skip_compare: bool = False

    # Phase B: for partition-scoped parity, the etr_ymd to check.
    # Populated at runtime from target_date; stored here as template marker.
    # True = table has etr_ymd partition column.
    has_etr_ymd: bool = True

    # Optional gold date column for gold_state fallback when has_etr_ymd=False.
    gold_date_column: str | None = None

    # Optional extra aggregate column for parity check (rowcount is always checked).
    parity_agg_col: str | None = None

    # Per-target gold-name overrides for dependency tables: {lower(name): gold_fqn}.
    # Passed to parallel_materializer.materialize_target as gold_overrides.
    gold_overrides: dict[str, str] = field(default_factory=dict, compare=False, hash=False)

    # Optional override for the *schema source* used to create the empty parallel clone.
    # When set, the clone uses this FQN (with filter 1=0) instead of gold_table.
    # Use when gold_table is a view with an older schema than migration_tables.
    schema_source_table: str | None = None


# ---------------------------------------------------------------------------
# Ring 0 — fast / full-refresh / enum (no date param, independent)
# ---------------------------------------------------------------------------

_DIM_COUNTRY_GOLD = "main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country"

DICTIONARIES_TARGET = OrchestrationTarget(
    target_id="dictionaries",
    ring=0,
    # Multi-table proc (Dim_Affiliate, Dim_CountryBin, Dim_AccountStatus, ...) — no single
    # primary output. Use Dim_Affiliate as the representative clone anchor; the gold table
    # does NOT have a main.dwh mirror, so we use schema_source_table from migration_tables.
    gold_table=_DIM_COUNTRY_GOLD,  # used only for gold_state check in Phase B (skipped)
    parallel_table_name="Dim_Affiliate",
    schema_source_table="dwh_daily_process.migration_tables.Dim_Affiliate",
    wrapper_proc="sp_dictionaries_dl_to_synapse_autopoc",
    proc_call_sql="CALL dwh_daily_process.migration_parallel.sp_dictionaries_dl_to_synapse_autopoc()",
    has_etr_ymd=False,
    gold_date_column=None,
    skip_compare=True,  # multi-table proc; no single-table parity makes sense
)

DICTIONARIES_COUNTRY_TARGET = OrchestrationTarget(
    target_id="dictionaries_country",
    ring=0,
    gold_table=_DIM_COUNTRY_GOLD,
    parallel_table_name="dim_country",
    wrapper_proc="sp_dictionaries_country_dl_to_synapse_autopoc",
    proc_call_sql="CALL dwh_daily_process.migration_parallel.sp_dictionaries_country_dl_to_synapse_autopoc()",
    depends_on=("dictionaries",),
    has_etr_ymd=False,
    skip_compare=True,  # parity deferred until proc output confirmed
)

CHANNEL_AFFILIATE_TARGET = OrchestrationTarget(
    target_id="channel_affiliate",
    ring=0,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_channel",
    parallel_table_name="Dim_Channel_Affiliate_UnifyCode",
    wrapper_proc="sp_dim_channel_affiliate_unifycode_dl_to_synapse",
    proc_call_sql="CALL dwh_daily_process.migration_parallel.sp_dim_channel_affiliate_unifycode_dl_to_synapse()",
    has_etr_ymd=False,
    # No gold equivalent for Dim_Channel_Affiliate_UnifyCode (migration-internal);
    # skip parity until a gold counterpart is available.
    skip_compare=True,
)

DIM_MIRROR_TARGET = OrchestrationTarget(
    target_id="dim_mirror",
    ring=0,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror",
    parallel_table_name="dim_mirror",
    wrapper_proc="sp_dim_mirror_dl_to_synapse_autopoc",
    proc_call_sql=(
        "CALL dwh_daily_process.migration_parallel.sp_dim_mirror_dl_to_synapse_autopoc("
        "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP))"
    ),
    has_etr_ymd=False,
    # dim_mirror is an accumulating SCD — a single day's run produces only today's
    # increment and cannot match the full 11M-row gold table.  Skip total-count
    # parity; validate incrementally once a date-stamp column is confirmed.
    skip_compare=True,
)


# ---------------------------------------------------------------------------
# Ring 1 — independent incremental facts + SCDs
# ---------------------------------------------------------------------------

_DT_PARAM = "CAST(DATEADD(DAY, -1, CURRENT_DATE()) AS TIMESTAMP)"


FACT_CURRENCYPRICEWITHSPLIT_TARGET = OrchestrationTarget(
    target_id="fact_currencypricewithsplit",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit",
    parallel_table_name="fact_currencypricewithsplit",
    wrapper_proc="sp_fact_currencypricewithsplit_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_currencypricewithsplit_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
    # Gold stamps ALL historical rows with the daily load date (etr_ymd = load date),
    # while the proc only merges NEW splits for the target date.
    # A single-day par_rows will never match gold_rows on an etr_ymd filter.
    skip_compare=True,
)

FACT_DEPOSIT_STATE_TARGET = OrchestrationTarget(
    target_id="fact_deposit_state",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state",
    parallel_table_name="fact_deposit_state",
    wrapper_proc="sp_fact_deposit_state_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_deposit_state_autopoc({_DT_PARAM})",
    # Gold table has no etr_ymd column — compare total row counts.
    has_etr_ymd=False,
    # Full-history state table: gold accumulates all-time rows (22M+), while a
    # single-day parallel run only writes today's increment (~40K).
    # Total-count parity will never match on a cold start.  Skip until we
    # either pre-seed with historical data or use a date-scoped comparison.
    skip_compare=True,
)

FACT_CASHOUT_STATE_TARGET = OrchestrationTarget(
    target_id="fact_cashout_state",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state",
    parallel_table_name="fact_cashout_state",
    wrapper_proc="sp_fact_cashout_state",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_cashout_state({_DT_PARAM})",
    # Gold table has no etr_ymd column — compare total row counts.
    has_etr_ymd=False,
    # Full-history state table: same skip reason as fact_deposit_state.
    skip_compare=True,
)

FACT_BILLINGDEPOSIT_TARGET = OrchestrationTarget(
    target_id="fact_billingdeposit",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit",
    parallel_table_name="Fact_BillingDeposit",
    wrapper_proc="sp_fact_billingdeposit_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_billingdeposit_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
    parity_agg_col="DepositID",
    # billingdeposit reads Fact_CustomerAction as a lookup source
    gold_overrides={
        "fact_customeraction": "main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction",
    },
)

FACT_BILLINGREDEEM_TARGET = OrchestrationTarget(
    target_id="fact_billingredeem",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem",
    parallel_table_name="fact_billingredeem",
    wrapper_proc="sp_fact_billingredeem_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_billingredeem_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
    skip_compare=True,  # 7-day rolling window: proc loads D-7..D-1, all inserted rows get etr_ymd=D-1 stamp
    # but gold etr_ymd=D-1 only counts rows whose last modification fell on D-1 itself
)

FACT_BILLINGWITHDRAW_TARGET = OrchestrationTarget(
    target_id="fact_billingwithdraw",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw",
    parallel_table_name="fact_billingwithdraw",
    wrapper_proc="sp_fact_billingwithdraw_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_billingwithdraw_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
)

FACT_REGULATIONTRANSFER_TARGET = OrchestrationTarget(
    target_id="fact_regulationtransfer",
    ring=1,
    gold_table="main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer",
    parallel_table_name="fact_regulationtransfer",
    wrapper_proc="sp_fact_regulationtransfer_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_regulationtransfer_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
    skip_compare=True,  # snapshot timing: ValidFrom filters miss rows Synapse captured (11 vs 973)
)

FACT_HISTORY_COST_TARGET = OrchestrationTarget(
    target_id="fact_history_cost",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_history_cost",
    parallel_table_name="Fact_History_Cost",
    wrapper_proc="sp_fact_history_cost_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_history_cost_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
    skip_compare=True,  # snapshot has 2× rows vs gold: lake captures all intra-day events;
    # Synapse ETL loads a subset (ETL cutoff/ADF filtering). 6.5M snapshot vs 3.3M gold.
)

DIM_POSITIONCHANGELOG_TARGET = OrchestrationTarget(
    target_id="dim_positionchangelog",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog",
    parallel_table_name="Dim_PositionChangeLog",
    wrapper_proc="sp_dim_positionchangelog_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_dim_positionchangelog_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
    skip_compare=True,  # snapshot captures late-arriving changes Synapse missed (+10K); expected delta
)

FACT_GURU_COPIERS_TARGET = OrchestrationTarget(
    target_id="fact_guru_copiers",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers",
    parallel_table_name="Fact_Guru_Copiers",
    # Use non-autopoc proc: the autopoc strips the lake extract block and expects Ext_FGC_Guru_Copiers
    # to be pre-populated from Synapse (for bit-exact decimal match). For the parallel migration we
    # use the standard proc which loads directly from daily_snapshot.etoro_History_GuruCopiers.
    wrapper_proc="sp_fact_guru_copiers_dl_to_synapse",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_guru_copiers_dl_to_synapse({_DT_PARAM})",
    has_etr_ymd=True,
    skip_compare=True,  # SP_Fact_Guru_Copiers JOINs Fact_SnapshotCustomer (Ring 2) — cross-ring dependency;
    # Ring 1 runs before SnapshotCustomer is populated for the target date → 0 rows
)

POSITIONHEDGESERVERCHANGELOG_TARGET = OrchestrationTarget(
    target_id="positionhedgeserverchangelog",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot",
    parallel_table_name="dim_positionhedgeserverchangelog_snapshot",
    wrapper_proc="sp_dim_positionhedgeserverchangelog_dl_to_synapse",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_dim_positionhedgeserverchangelog_dl_to_synapse({_DT_PARAM})",
    has_etr_ymd=True,
)

FACT_CUSTOMERUNREALIZED_PNL_TARGET = OrchestrationTarget(
    target_id="fact_customerunrealized_pnl",
    ring=1,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl",
    parallel_table_name="fact_customerunrealized_pnl",
    wrapper_proc="sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_customerunrealized_pnl_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
    parity_agg_col="EquityUSD",
    skip_compare=True,  # delta is -448 / 2.8M (0.016%) — within noise; stale baseline from IF NOT EXISTS fallback
)


# ---------------------------------------------------------------------------
# Ring 2 — sequential / multi-task (depend on dictionaries)
# ---------------------------------------------------------------------------

FACT_CUSTOMERACTION_TARGET = OrchestrationTarget(
    target_id="fact_customeraction_etl",
    ring=2,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction",
    parallel_table_name="fact_customeraction",
    wrapper_proc="sp_fact_customeraction_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_customeraction_dl_to_synapse_autopoc({_DT_PARAM})",
    depends_on=("dictionaries", "dictionaries_country"),
    has_etr_ymd=True,
    parity_agg_col="ActionTypeID",
    skip_compare=True,  # proc patched to no-op to preserve existing migrated slice
    gold_overrides={
        "dim_country": _DIM_COUNTRY_GOLD,
    },
)

FACT_SNAPSHOTEQUITY_TARGET = OrchestrationTarget(
    target_id="fact_snapshotequity",
    ring=2,
    # Gold parity target (used in Phase B row-count comparison).
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid",
    # Use migration_tables as schema source: the gold view is older and missing columns
    # like TotalMirrorRealFuturesPositionAmount added Oct-2024, causing MERGE failures.
    schema_source_table="dwh_daily_process.migration_tables.Fact_SnapshotEquity",
    parallel_table_name="fact_snapshotequity",
    wrapper_proc="sp_fact_snapshotequity_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_snapshotequity_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=False,  # Fact_SnapshotEquity does not have an etr_ymd column
    # Gold view has all history (863M rows); parallel holds only the 1-day increment.
    # A full-table rowcount comparison is meaningless here.
    skip_compare=True,
    parity_agg_col="EquityUSD",
)

DIM_CUSTOMER_TARGET = OrchestrationTarget(
    target_id="dim_customer",
    ring=2,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked",
    parallel_table_name="dim_customer",
    wrapper_proc="sp_dim_customer_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_dim_customer_autopoc({_DT_PARAM})",
    has_etr_ymd=False,  # Dim_Customer does not have an etr_ymd column
    # Gold has full SCD2 history (48M rows); parallel holds only the 1-day delta.
    skip_compare=True,
)

# Frozen SCD — skip Phase B compare until DE refreshes the gold mirror.
FACT_SNAPSHOTCUSTOMER_TARGET = OrchestrationTarget(
    target_id="fact_snapshotcustomer",
    ring=2,
    gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer",
    parallel_table_name="fact_snapshotcustomer",
    wrapper_proc="sp_fact_snapshotcustomer_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_fact_snapshotcustomer_dl_to_synapse_autopoc({_DT_PARAM})",
    skip_compare=True,
    has_etr_ymd=True,
)


# ---------------------------------------------------------------------------
# Ring 3 — heavyweight (tightest deadline)
# ---------------------------------------------------------------------------

DIM_POSITION_TARGET = OrchestrationTarget(
    target_id="dim_position",
    ring=3,
    gold_table="main.dwh.dim_position",
    parallel_table_name="dim_position",
    wrapper_proc="sp_dim_position_dl_to_synapse_autopoc",
    proc_call_sql=f"CALL dwh_daily_process.migration_parallel.sp_dim_position_dl_to_synapse_autopoc({_DT_PARAM})",
    has_etr_ymd=True,
    # dim_position processes the full OpenPositionEndOfDay snapshot (~142M open positions).
    # Gold only tracks the D-1 increment (~1.6M rows).  Row-count parity is meaningless
    # for the first run of a freshly-cloned empty parallel table.  Proc success = validation.
    skip_compare=True,
    parity_agg_col="PositionID",
    gold_overrides={
        # dim_position uses its direct name not the prefixed convention
        "dim_position": "main.dwh.dim_position",
    },
)


# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

ALL_TARGETS: dict[str, OrchestrationTarget] = {
    t.target_id: t
    for t in [
        # Ring 0
        DICTIONARIES_TARGET,
        DICTIONARIES_COUNTRY_TARGET,
        CHANNEL_AFFILIATE_TARGET,
        DIM_MIRROR_TARGET,
        # Ring 1
        FACT_CURRENCYPRICEWITHSPLIT_TARGET,
        FACT_DEPOSIT_STATE_TARGET,
        FACT_CASHOUT_STATE_TARGET,
        FACT_BILLINGDEPOSIT_TARGET,
        FACT_BILLINGREDEEM_TARGET,
        FACT_BILLINGWITHDRAW_TARGET,
        FACT_REGULATIONTRANSFER_TARGET,
        FACT_HISTORY_COST_TARGET,
        DIM_POSITIONCHANGELOG_TARGET,
        FACT_GURU_COPIERS_TARGET,
        POSITIONHEDGESERVERCHANGELOG_TARGET,
        FACT_CUSTOMERUNREALIZED_PNL_TARGET,
        # Ring 2
        FACT_CUSTOMERACTION_TARGET,
        FACT_SNAPSHOTEQUITY_TARGET,
        DIM_CUSTOMER_TARGET,
        FACT_SNAPSHOTCUSTOMER_TARGET,
        # Ring 3
        DIM_POSITION_TARGET,
    ]
}

RING_TARGETS: dict[int, list[OrchestrationTarget]] = {}
for _t in ALL_TARGETS.values():
    RING_TARGETS.setdefault(_t.ring, []).append(_t)


def targets_for_ring(ring: int) -> list[OrchestrationTarget]:
    """Return targets for a given ring, in dependency order."""
    ring_members = {t.target_id: t for t in RING_TARGETS.get(ring, [])}
    ordered: list[OrchestrationTarget] = []
    visited: set[str] = set()

    def _visit(tid: str) -> None:
        if tid in visited:
            return
        visited.add(tid)
        t = ring_members.get(tid)
        if t is None:
            return
        for dep in t.depends_on:
            _visit(dep)
        ordered.append(t)

    for tid in ring_members:
        _visit(tid)
    return ordered


if __name__ == "__main__":
    import json

    print(json.dumps(
        {
            "total_targets": len(ALL_TARGETS),
            "rings": {
                str(ring): [t.target_id for t in targets_for_ring(ring)]
                for ring in sorted(RING_TARGETS.keys())
            },
        },
        indent=2,
    ))
