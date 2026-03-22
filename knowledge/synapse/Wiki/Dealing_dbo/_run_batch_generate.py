"""Driver script: Dealing_dbo ALTER generation using _batch_generate_lib.

UC cache pre-populated from MCP bulk query results.
Run: python _run_batch_generate.py [--force] [--dry-run]
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import _batch_generate_lib as bgl

UC_CACHE = {
    "dealing_apexrecon_holdings": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings", "Standard"),
    "dealing_apexrecon_tradeactivity": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity", "Standard"),
    "dealing_bny_virtu_reconeodholding": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding", "Standard"),
    "dealing_boundary_cost": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_boundary_cost", "Standard"),
    "dealing_clicks_openclose_breakdown": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown", "Standard"),
    "dealing_duco_activityrecon": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon", "Standard"),
    "dealing_esmanetloss": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_esmanetloss", "Standard"),
    "dealing_islamic_daily_administrative_fee": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_administrative_fee", "Standard"),
    "dealing_islamic_daily_spot_price_adjustment": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_islamic_daily_spot_price_adjustment", "Standard"),
    "dealing_manipulationreport_realstocks": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks", "Standard"),
    "dealing_manipulationreport_realstocks_cid": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid", "Standard"),
    "dealing_marex_recon_eodholdings_futures": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures", "Standard"),
    "dealing_riskmatrix_v2": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2", "Standard"),
    "dealing_saxorecon_eodholdings": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings", "Standard"),
    "dealing_staking_summary": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary", "Standard"),
    "v_dealing_duco_eodrecon": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon", "Standard"),
    "dealing_dealingdashboard_clients": bgl.UCTarget("main", "bi_db", "gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients", "Non-standard"),
    "dealing_duco_eodrecon": bgl.UCTarget("main", "bi_db", "gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon", "Non-standard"),
    "dealing_nop_report": bgl.UCTarget("main", "bi_db", "gold_sql_dp_prod_we_dealing_dbo_dealing_nop_report", "Non-standard"),
    "dealing_numberofpositionsopened_agg": bgl.UCTarget("main", "bi_db", "gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg", "Non-standard"),
    "dealing_staking_results": bgl.UCTarget("main", "bi_db", "gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results", "Non-standard"),
    "dealing_staking_dailypool": bgl.UCTarget("main", "finance", "gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool", "Non-standard"),
    "dealing_staking_optedout": bgl.UCTarget("main", "finance", "gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout", "Non-standard"),
    "dealing_staking_parameters": bgl.UCTarget("main", "finance", "gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters", "Non-standard"),
    "dealing_commoditiesintrahour_clients": bgl.UCTarget("main", "general", "gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_clients", "Non-standard"),
    "dealing_commoditiesintrahour_etoro": bgl.UCTarget("main", "general", "gold_sql_dp_prod_we_dealing_dbo_dealing_commoditiesintrahour_etoro", "Non-standard"),
    "dealing_indiciesintrahour_clients": bgl.UCTarget("main", "general", "gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_clients", "Non-standard"),
    "dealing_indiciesintrahour_etoro": bgl.UCTarget("main", "general", "gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro", "Non-standard"),
    "dealing_employees_report": bgl.UCTarget("main", "trading", "gold_sql_dp_prod_we_dealing_dbo_dealing_employees_report", "Non-standard"),
    "v_dealing_duco_eodrecon": bgl.UCTarget("main", "dealing", "gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon", "Standard"),
}

if __name__ == "__main__":
    force = "--force" in sys.argv
    dry_run = "--dry-run" in sys.argv
    results = bgl.process_schema("Dealing_dbo", uc_cache=UC_CACHE, force=force, dry_run=dry_run)
