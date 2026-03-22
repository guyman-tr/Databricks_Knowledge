"""Driver script: DWH_dbo ALTER generation using _batch_generate_lib.

UC cache pre-populated from MCP bulk query results (tables + views).
Run: python _run_batch_generate.py [--force] [--dry-run]
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import _batch_generate_lib as bgl

UC_CACHE = {
    # --- Tables (from previous run) ---
    "dim_accountstatus": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus", "Standard"),
    "dim_affiliate": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked", "PII Masked",
                                   "main", "pii_data", "gold_sql_dp_prod_we_dwh_dbo_dim_affiliate", "Email,City"),
    "dim_affiliatecosttype": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_affiliatecosttype", "Standard"),
    "dim_billingdepot": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot", "Standard"),
    "dim_cashoutreason": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason", "Standard"),
    "dim_cashoutstatus": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus", "Standard"),
    "dim_clientwithdrawreason": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason", "Standard"),
    "dim_closepositionreason": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason", "Standard"),
    "dim_compensationreason": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason", "Standard"),
    "dim_contacttype": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_contacttype", "Standard"),
    "dim_countryipanonymousproxytype": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_countryipanonymousproxytype", "Standard"),
    "dim_customer": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked", "PII Masked",
                                  "main", "pii_data", "gold_sql_dp_prod_we_dwh_dbo_dim_customer",
                                  "Email,FirstName,LastName,FullName,City,Address,PhoneNumber,MobileNumber,ZipCode,TaxId,BirthDate,NationalID,ExternalId,FullAddress"),
    "dim_customerchangetype": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_customerchangetype", "Standard"),
    "dim_desk": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_desk", "Standard"),
    "dim_historicallysplit": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_historicallysplit", "Standard"),
    "dim_historysplit": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_historysplit", "Standard"),
    "dim_historysplitratiorange": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratiorange", "Standard"),
    "dim_historysplitratio": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio", "Standard"),
    "dim_instrument": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_instrument", "Standard"),
    "dim_instrument_snapshot": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_instrument_snapshot", "Standard"),
    "dim_label": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_label", "Standard"),
    "dim_language": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_language", "Standard"),
    "dim_manager": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_manager", "Standard"),
    "dim_mifidcategorization": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization", "Standard"),
    "dim_mirror": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_mirror", "Standard"),
    "dim_mirrortype": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype", "Standard"),
    "dim_paymentstatus": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus", "Standard"),
    "dim_playerstatusreasons": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons", "Standard"),
    "dim_playerstatussubreasons": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons", "Standard"),
    "dim_position": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_position", "Standard"),
    "dim_positionchangelog": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog", "Standard"),
    "dim_positionhedgeserverchangelog_snapshot": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot", "Standard"),
    "dim_product": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_product", "Standard"),
    "dim_range": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_range", "Standard"),
    "dim_redeemreason": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason", "Standard"),
    "dim_redeemstatus": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_redeemstatus", "Standard"),
    "dim_regulation": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_regulation", "Standard"),
    "dim_riskclassification": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification", "Standard"),
    "dim_riskmanagementstatus": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_riskmanagementstatus", "Standard"),
    "dim_riskstatus": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_riskstatus", "Standard"),
    "dim_screeningstatus": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus", "Standard"),
    "dim_socialnetwork": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_dim_socialnetwork", "Standard"),
    "fact_currencypricewithsplit": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit", "Standard"),
    "fact_customeraction": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_fact_customeraction", "Standard"),
    "fact_deposit_state": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_fact_deposit_state", "Standard"),
    "fact_guru_copiers": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers", "Standard"),
    "fact_snapshotcustomer": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer_masked", "PII Masked",
                                           "main", "pii_data", "gold_sql_dp_prod_we_dwh_dbo_fact_snapshotcustomer", ""),
    "history_currencyprice": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_history_currencyprice", "Standard"),

    # --- Views (new) ---
    "v_dim_mirror": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror", "Standard"),
    "v_fact_snapshotcustomer": bgl.UCTarget("main", "pii_data", "gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer", "PII Only"),
    "v_fact_snapshotcustomer_fromdateid": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked", "PII Masked",
                                                        "main", "pii_data", "gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid", ""),
    "v_fact_snapshotequity_fromdateid": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid", "Standard"),
    "v_liabilities": bgl.UCTarget("main", "dwh", "gold_sql_dp_prod_we_dwh_dbo_v_liabilities", "Standard"),
}

if __name__ == "__main__":
    force = "--force" in sys.argv
    dry_run = "--dry-run" in sys.argv
    results = bgl.process_schema("DWH_dbo", uc_cache=UC_CACHE, force=force, dry_run=dry_run)
