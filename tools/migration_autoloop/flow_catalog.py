"""Shared migration flow catalog for autoloop runners."""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class FlowDef:
    flow_id: str
    pipeline_name: str
    migration_table: str
    synapse_table: str
    gold_table: str
    procedure_name: str
    has_date_param: bool
    date_slice_column: str = ""
    compare_on_common_date: bool = False
    done_flow: bool = False


@dataclass(frozen=True)
class MultiTaskChildDef:
    flow_id: str
    migration_table: str
    synapse_table: str
    gold_table: str
    procedure_name: str
    has_date_param: bool
    date_slice_column: str = ""
    compare_on_common_date: bool = False


@dataclass(frozen=True)
class MultiTaskFlowDef:
    flow_id: str
    pipeline_name: str
    databricks_job_name: str
    children: tuple[MultiTaskChildDef, ...]


PIPELINE_NAME = "DWH_Daily_Process_-_Entry_Point"


FLOW_CATALOG: dict[str, FlowDef] = {
    "fcupnl": FlowDef(
        flow_id="fcupnl",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_customerunrealized_pnl",
        synapse_table="DWH_dbo.Fact_CustomerUnrealized_PnL",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customerunrealized_pnl",
        procedure_name="sp_fact_customerunrealized_pnl_autopoc",
        has_date_param=True,
        done_flow=True,
    ),
    "dim_mirror": FlowDef(
        flow_id="dim_mirror",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.dim_mirror",
        synapse_table="DWH_dbo.Dim_Mirror",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror",
        procedure_name="sp_dim_mirror_dl_to_synapse_autopoc",
        has_date_param=True,
    ),
    "fact_currencypricewithsplit": FlowDef(
        flow_id="fact_currencypricewithsplit",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_currencypricewithsplit",
        synapse_table="DWH_dbo.Fact_CurrencyPriceWithSplit",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit",
        procedure_name="sp_fact_currencypricewithsplit_dl_to_synapse_autopoc",
        has_date_param=True,
    ),
    "fact_deposit_state": FlowDef(
        flow_id="fact_deposit_state",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_deposit_state",
        synapse_table="DWH_dbo.Fact_Deposit_State",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state",
        procedure_name="sp_fact_deposit_state_autopoc",
        has_date_param=True,
        date_slice_column="ModificationDateID",
        compare_on_common_date=True,
    ),
    "fact_cashout_state": FlowDef(
        flow_id="fact_cashout_state",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_cashout_state",
        synapse_table="DWH_dbo.Fact_Cashout_State",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_cashout_state",
        procedure_name="sp_fact_cashout_state",
        has_date_param=True,
        date_slice_column="ModificationDateID",
        compare_on_common_date=True,
    ),
    "fact_snapshotcustomer": FlowDef(
        flow_id="fact_snapshotcustomer",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_snapshotcustomer",
        synapse_table="DWH_dbo.Fact_SnapshotCustomer",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer",
        procedure_name="sp_fact_snapshotcustomer_dl_to_synapse_autopoc",
        has_date_param=True,
        date_slice_column="DateRangeID",
    ),
    "fact_snapshotcustomercloseyear": FlowDef(
        flow_id="fact_snapshotcustomercloseyear",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_snapshotcustomer",
        synapse_table="DWH_dbo.Fact_SnapshotCustomer",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer",
        procedure_name="sp_fact_snapshotcustomercloseyear",
        has_date_param=True,
        date_slice_column="DateRangeID",
        compare_on_common_date=True,
    ),
    "fact_snapshotequity": FlowDef(
        flow_id="fact_snapshotequity",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_snapshotequity",
        synapse_table="DWH_dbo.v_Fact_SnapshotEquity_FromDateID",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid",
        procedure_name="sp_fact_snapshotequity_dl_to_synapse_autopoc",
        has_date_param=True,
        date_slice_column="DateRangeID",
    ),
    "dim_historysplitratio": FlowDef(
        flow_id="dim_historysplitratio",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.dim_historysplitratio",
        synapse_table="DWH_dbo.Dim_HistorySplitRatio",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio",
        procedure_name="sp_dim_historysplitratio_dl_to_synapse",
        has_date_param=False,
    ),
    "fact_regulationtransfer": FlowDef(
        flow_id="fact_regulationtransfer",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_regulationtransfer",
        synapse_table="DWH_dbo.Fact_RegulationTransfer",
        gold_table="main.compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer",
        procedure_name="sp_fact_regulationtransfer_dl_to_synapse_autopoc",
        has_date_param=True,
        date_slice_column="DateID",
        compare_on_common_date=True,
    ),
    "validation_cycle_gap": FlowDef(
        flow_id="validation_cycle_gap",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.util_resultsliabilities_cycle",
        synapse_table="DWH_dbo.Util_ResultsLiabilities_Cycle",
        gold_table="main.dwh.util_resultsliabilities_cycle",
        procedure_name="sp_validation_cycle_gap_dl_to_synapse",
        has_date_param=True,
        date_slice_column="DateID",
        compare_on_common_date=True,
    ),
    "daily_marketpageviews": FlowDef(
        flow_id="daily_marketpageviews",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.fact_marketpageviews_switch_single",
        synapse_table="DWH_dbo.Fact_MarketPageViews",
        gold_table="main.mixpanel.gold_mixpanel_marketpageviews",
        procedure_name="sp_daily_marketpageviews_dl_to_synapse",
        has_date_param=True,
        date_slice_column="DateID",
        compare_on_common_date=True,
    ),
    "dim_customer": FlowDef(
        flow_id="dim_customer",
        pipeline_name=PIPELINE_NAME,
        migration_table="dwh_daily_process.migration_tables.dim_customer",
        synapse_table="DWH_dbo.Dim_Customer",
        gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked",
        procedure_name="sp_dim_customer",
        has_date_param=False,
    ),
}


MULTI_TASK_FLOW_CATALOG: dict[str, MultiTaskFlowDef] = {
    "fact_customeraction_etl": MultiTaskFlowDef(
        flow_id="fact_customeraction_etl",
        pipeline_name=PIPELINE_NAME,
        databricks_job_name="DWH_Daily_Process__Fact_CustomerAction_ETL",
        children=(
            MultiTaskChildDef(
                flow_id="dictionaries_country",
                migration_table="dwh_daily_process.migration_tables.dim_country",
                synapse_table="DWH_dbo.Dim_Country",
                gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country",
                procedure_name="sp_dictionaries_country_dl_to_synapse_autopoc",
                has_date_param=False,
            ),
            MultiTaskChildDef(
                flow_id="fact_customeraction",
                migration_table="dwh_daily_process.migration_tables.fact_customeraction",
                synapse_table="DWH_dbo.Fact_CustomerAction",
                gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction",
                procedure_name="sp_fact_customeraction_dl_to_synapse_autopoc",
                has_date_param=True,
                date_slice_column="DateID",
                compare_on_common_date=True,
            ),
            MultiTaskChildDef(
                flow_id="fact_firstcustomeraction",
                migration_table="dwh_daily_process.migration_tables.fact_firstcustomeraction",
                synapse_table="DWH_dbo.Fact_FirstCustomerAction",
                gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_firstcustomeraction",
                procedure_name="sp_fact_firstcustomeraction_dl_to_synapse_autopoc",
                has_date_param=True,
                date_slice_column="DateID",
                compare_on_common_date=True,
            ),
            MultiTaskChildDef(
                flow_id="fact_billingdeposit",
                migration_table="dwh_daily_process.migration_tables.fact_billingdeposit",
                synapse_table="DWH_dbo.Fact_BillingDeposit",
                gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit",
                procedure_name="sp_fact_billingdeposit_dl_to_synapse_autopoc",
                has_date_param=True,
            ),
            MultiTaskChildDef(
                flow_id="fact_billingwithdraw",
                migration_table="dwh_daily_process.migration_tables.fact_billingwithdraw",
                synapse_table="DWH_dbo.Fact_BillingWithdraw",
                gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw",
                procedure_name="sp_fact_billingwithdraw_dl_to_synapse_autopoc",
                has_date_param=True,
            ),
            MultiTaskChildDef(
                flow_id="fact_billingredeem",
                migration_table="dwh_daily_process.migration_tables.fact_billingredeem",
                synapse_table="DWH_dbo.Fact_BillingRedeem",
                gold_table="main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingredeem",
                procedure_name="sp_fact_billingredeem_dl_to_synapse_autopoc",
                has_date_param=True,
            ),
        ),
    )
}
