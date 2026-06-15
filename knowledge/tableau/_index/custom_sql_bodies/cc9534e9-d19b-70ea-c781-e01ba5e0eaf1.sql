select DateID,Year,YearMonth,CID,Amount,theoretical_PLayerLevelID, theoretical_group_name, actual_PlayerLevelID, actual_group_name,actual_Regulation from (
--select DateID, ind_right_club, count(*) from (
select base2.* 
,player.Name as actual_group_name
,reg.Name as actual_Regulation
,year(etr_ymd)*100 + month(etr_ymd) as YearMonth
,year(etr_ymd) as Year
, case when theoretical_PlayerLevelID= actual_PlayerLevelID then 1 else 0 end as ind_right_club
, case when theoretical_PlayerLevelID<> actual_PlayerLevelID and actual_PlayerLevelID =6 and theoretical_PLayerLevelID in (7) then 1
 when theoretical_PlayerLevelID<> actual_PlayerLevelID and actual_PlayerLevelID=2 and theoretical_PLayerLevelID in (7,6) then 1
 when theoretical_PlayerLevelID<> actual_PlayerLevelID and actual_PlayerLevelID= 3 and theoretical_PLayerLevelID in (7,6,2) then 1
 when theoretical_PlayerLevelID<> actual_PlayerLevelID and actual_PlayerLevelID= 5 and theoretical_PLayerLevelID in (7,6,2,3) then 1
 when theoretical_PlayerLevelID<> actual_PlayerLevelID and actual_PlayerLevelID= 1 and theoretical_PLayerLevelID in (7,6,2,3,5) then 1
 else 0 end as ind_should_upgrade
from (
select base1.* 
, dim_cust_hist.PlayerLevelID as actual_PlayerLevelID, dim_cust_hist.RegulationID as actual_RegulationID


from (

select base.*, dim_cust.RealCID as CID

, case when amount between -1E5 and 5E3 then 1
when amount between 5E3+0.01 and 10E3 then 5
when  amount between 10E3+ 0.01 and 25E3 then 3
when amount between 25E3 +0.01 and 50E3 then 2
when amount between 50E3+0.01 and 250E3 then 6
when amount between 250E3+0.01 and 1E8 then 7
when amount is null then 4 end as theoretical_PlayerLevelID

, case when amount between -1E5 and 5E3 then 'Bronze'
when amount between 5E3+0.01 and 10E3 then 'Silver'
when  amount between 10E3+ 0.01 and 25E3 then 'Gold'
when amount between 25E3 +0.01 and 50E3 then 'Platinum'
when amount between 50E3+0.01 and 250E3 then 'Platinum Plus'
when amount between 250E3+0.01 and 1E8 then 'Diamond'
when amount is null then 'Internal' end as theoretical_group_name

from
(select year(etr_ymd) *1E4 + month(etr_ymd)*1E2 + day(etr_ymd) as DateID,etr_ymd, GCID, round(sum(Amount),2) Amount 
from main.bi_db.bronze_clubservice_clubs_userbalances
where SourceType in (1,2,3)
and year(etr_ymd)*1E4 + month(etr_ymd)*1E2 + day(etr_ymd) in (SELECT DISTINCT DateKey FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date WHERE LOWER(IsFirstDayOfMonth) = 'y')
and etr_ymd >='2023-01-01'
group by 1,2,3
)base
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked as dim_cust
on base.GCID=dim_cust.GCID
)base1 
join dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked as dim_cust_hist
on base1.CID=dim_cust_hist.RealCID
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
ON dr.DateRangeID =  dim_cust_hist.DateRangeID
where 
base1.DateID in (SELECT DISTINCT DateKey FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date WHERE LOWER(IsFirstDayOfMonth) = 'y' and DateKey>=20230101)
and base1.DateID BETWEEN dr.FromDateID AND dr.ToDateID
)base2
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel player
on base2.actual_PlayerLevelId= player.PlayerLevelID
left join main.general.bronze_etoro_dictionary_regulation reg
on base2.actual_RegulationID= reg.ID
where actual_PlayerLevelID <> 4 -- not actual internal
--) base3 where DateID=20240401   group by 1,2
)base3  where  ind_right_club=0  and ind_should_upgrade=1


------------------------------------------------------------------------------------------
/*
select count(*) from dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_masked

select min(UpdateDate),max(UpdateDate) from dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_masked

select max(DateKey) from dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_masked

--bad
--select min(UpdateDate),max(UpdateDate) from dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_masked


--good
--select min(UpdateDate),max(UpdateDate) from dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
--select count(*) from dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked

---key to join

/*
SourceType:
1 - Balance without cfd
2 - emoney balance
3 - moneyfarm balance (ISA)
*/

*/