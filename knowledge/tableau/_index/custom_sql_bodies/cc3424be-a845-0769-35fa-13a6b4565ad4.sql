select DateID,FullDate,total_equity,amount_cids, top_1_cid_weight as Value, 'top 1 CID' as type  from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_10_cid_weight as Value, 'top 10 CID' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_50_cid_weight as Value, 'top 50 CID' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_100_cid_weight as Value, 'top 100 CID' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_500_cid_weight as Value, 'top 500 CID' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_1000_cid_weight as Value, 'top 1,000 CID' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_5000_cid_weight as Value, 'top 5,000 CID' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_10000_cid_weight as Value, 'top 10,000 CID' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_0_5_perc_weight as Value, 'top 0.5% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_1_perc_weight as Value, 'top 1% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_2_perc_weight as Value, 'top 2% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_3_perc_weight as Value, 'top 3% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_5_perc_weight as Value, 'top 5% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_10_perc_weight as Value, 'top 10% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_20_perc_weight as Value, 'top 20% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_50_perc_weight as Value, 'top 50% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_70_perc_weight as Value, 'top 70% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_80_perc_weight as Value, 'top 80% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_90_perc_weight as Value, 'top 90% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_95_perc_weight as Value, 'top 95% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_99_perc_weight as Value, 'top 99% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, top_99_perc_weight as Value, 'top 99% CIDs' as type from risk.risk_output_rm_tables_concentration_equity
union
select DateID,FullDate,total_equity,amount_cids, 1.00 as Value, '100% CIDs' as type from risk.risk_output_rm_tables_concentration_equity