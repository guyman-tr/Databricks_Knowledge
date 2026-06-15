select final_both.*
, case when ind_success=0 then amount_trans else 0 end as amount_trans_numerator
from
(

---failures


(
select YearMonth,InstrumentID,CBH_HBC,ind_success,IsCopy,amount_trans,InstrumentType, InstrumentDisplayName_
from
(
select YearMonth,InstrumentID,CBH_HBC, ind_success, IsCopy,InstrumentType, InstrumentDisplayName_, count(*) as amount_trans
from
(

select  YearMonth,InstrumentID,CBH_HBC,0 as 'ind_success',IsCopy, InstrumentType, InstrumentDisplayName_
from
(

select  final1.* from (
select final.*
,row_number() over (partition by Date, CID, InstrumentID,ErrorCode,IsCopy order by FailOccurred) as rn
from (
select fail.* 
, year(fail.Date)*100 + month(fail.Date) as YearMonth
,di.InstrumentType,di.Name, di.InstrumentDisplayName as InstrumentDisplayName_
, case when HedgeServerID in (2,5,9,13,21,22,24,25,81,83,101,110,111,112,120,122,125,126,127,128,129,130,5000) then 'CBH'
--when HedgeServerID= '81b' then 'CBH'
when HedgeServerID in (6,8,82,84,102,124) then 'HBC'
when HedgeServerID=0 then 'HS_zero'
when HedgeServerID is null then 'HS null'
else 'not defined' end as 'CBH_HBC'
----variable 1
,case when ErrorCode=606 and lower(FailReason) not like '%execution%' 
and lower(FailReason) not like '%timeout expired%' then 'eToro'
when ErrorCode=607 and lower(FailReason) not like '%db failure%' then 'eToro' 
when ErrorCode=612 then 'eToro'
when ErrorCode=609 then 'eToro'
when ErrorCode=945
and 
(lower(FailReason)like '%no default is define for that instrument%'
or lower(FailReason)like '%ordervalidation - execution did not pass max deal size validation%'
or lower(FailReason)like '%providerunkown%'
) then 'eToro'
when ErrorCode=787 and lower(FailReason) like '%have pending full orders%' then 'eToro'
when ErrorCode in (607,613) and lower(FailReason) like '%db failure%' then 'eToro'
when ErrorCode=606 and lower(FailReason) like '%execution%' then 'eToro'
when ErrorCode=741 and lower(FailReason) not like 'failed%' then 'eToro'
when ErrorCode=741 and lower(FailReason) like 'failed%' then 'eToro'
when ErrorCode=772 then 'eToro'
--when ErrorCode=606 and lower(FailReason) like '%timeout expired%'
--and lower(FailReason) not like '%execution%' then 'eToro'
when ErrorCode in (619,640,714,715,717,720,721,716,808,951,818) then 'eToro'
when ErrorCode =816 and lower(FailReason) not like '%the user is blocked from closing the position%' then 'eToro'
when ErrorCode= 710 then 'eToro or client'
else 'others' end as 'etoro_client'

----variable 2
,case when ErrorCode=606 and lower(FailReason) not like '%execution%' 
and lower(FailReason) not like '%timeout expired%' then 'system'
when ErrorCode=607 and lower(FailReason) not like '%db failure%' then 'system' 
when ErrorCode=612 then 'system'
when ErrorCode=609 then 'manual'
when ErrorCode=945
and 
(lower(FailReason)like '%no default is define for that instrument%'
or lower(FailReason)like '%ordervalidation - execution did not pass max deal size validation%'
or lower(FailReason)like '%providerunkown%'
) then 'manual'
when ErrorCode=787 and lower(FailReason) like '%have pending full orders%' then 'system'
when ErrorCode in (607,613) and lower(FailReason) like '%db failure%' then 'system'
when ErrorCode=606 and lower(FailReason) like '%execution%' then 'system'
when ErrorCode=741 and lower(FailReason) not like 'failed%' then 'system'
when ErrorCode=741 and lower(FailReason) like 'failed%' then 'manual'
when ErrorCode=772 then 'system'
--when ErrorCode=606 and lower(FailReason) like '%timeout expired%'
--and lower(FailReason) not like '%execution%' then 'system'
when ErrorCode in (619,640,714,715,717,720,721,716,808,951,818) then 'manual'
when ErrorCode =816 and lower(FailReason) not like '%the user is blocked from closing the position%' then 'manual'
when ErrorCode= 710 then 'system'
else 'others' end as 'Type'

----variable 3
,case when ErrorCode=606 and lower(FailReason) not like '%execution%' 
and lower(FailReason) not like '%timeout expired%' then 'DB Failure'
when ErrorCode=607 and lower(FailReason) not like '%db failure%' then 'DB Failure' 
when ErrorCode=612 then 'DB Failure'
when ErrorCode=609 then 'Human error'
when ErrorCode=945
and 
(lower(FailReason)like '%no default is define for that instrument%'
or lower(FailReason)like '%ordervalidation - execution did not pass max deal size validation%'
or lower(FailReason)like '%providerunkown%'
) then 'Human error'
when ErrorCode=787 and lower(FailReason) like '%have pending full orders%' then 'Hedge Server/LP'
when ErrorCode in (607,613) and lower(FailReason) like '%db failure%' then 'DB Failure/Redis'
when ErrorCode=606 and lower(FailReason) like '%execution%' then 'Hedge Server/LP'
when ErrorCode=741 and lower(FailReason) not like 'failed%' then 'DB Failure'
when ErrorCode=741 and lower(FailReason) like 'failed%' then 'Hedge Server'
when ErrorCode=772 then 'DB Failure'
--when ErrorCode=606 and lower(FailReason) like '%timeout expired%'
--and lower(FailReason) not like '%execution%' then 'Hedge Server/LP'
when ErrorCode in (619,640,714,715,717,720,721,716,808,951,818) then 'Configuration Manager'
when ErrorCode =816 and lower(FailReason) not like '%the user is blocked from closing the position%' then 'Configuration Manager'
when ErrorCode= 710 then 'Trade Server'
else 'others' end as 'System'



----variable 4
,case when ErrorCode=606 and lower(FailReason) not like '%execution%'
and lower(FailReason) not like '%timeout expired%' then 'DB not accurate'
when ErrorCode=607 and lower(FailReason) not like '%db failure%' then 'DB not accurate' 
when ErrorCode=612 then 'DB not accurate'
when ErrorCode=609 then 'Not defined configurations'
when ErrorCode=945
and 
(lower(FailReason)like '%no default is define for that instrument%'
or lower(FailReason)like '%ordervalidation - execution did not pass max deal size validation%'
or lower(FailReason)like '%providerunkown%'
) then 'Not defined configurations'
when ErrorCode=787 and lower(FailReason) like '%have pending full orders%' then 'Pending issues to execute'
when ErrorCode in (607,613) and lower(FailReason) like '%db failure%' then 'DB not accurate' 
when ErrorCode=606 and lower(FailReason) like '%execution%' then 'LP Settings/Bad connecton'
when ErrorCode=741 and lower(FailReason) not like 'failed%' then 'Position was not recorded,found or already closed'
when ErrorCode=741 and lower(FailReason) like 'failed%' then 'Failed to send to execution to LP'
when ErrorCode=772 then 'DB not accurate'
--when ErrorCode=606 and lower(FailReason) like '%timeout expired%'
--and lower(FailReason) not like '%execution%' then  'Time expired to Execute'
when ErrorCode in (619,640,714,715,717,720,721,716,808,951,818) then 'Internal Settings were rejected'
when ErrorCode= 710 then 'Instrument is in inactive state'
else 'others' end as 'Reason'

----variable 5
,case when ErrorCode=606 and lower(FailReason) not like '%execution%'
and lower(FailReason) not like '%timeout expired%' then 'Position not found/recorded/not exist'
when ErrorCode=607 and lower(FailReason) not like '%db failure%' then 'Position not found/recorded/not exist' 
when ErrorCode=612 then 'Position not found/recorded/not exist'
when ErrorCode=609 then 'Object reference not set to an instance of an object'
when ErrorCode=945
and 
(lower(FailReason)like '%no default is define for that instrument%'
or lower(FailReason)like '%ordervalidation - execution did not pass max deal size validation%'
or lower(FailReason)like '%providerunkown%'
) then 'Object reference not set to an instance of an object'
when ErrorCode=787 and lower(FailReason) like '%have pending full orders%' then 'Close Multiple positions Failures given validation of LP Limits'
when ErrorCode in (607,613) and lower(FailReason) like '%db failure%' then ' wrong balance'
when ErrorCode=606 and lower(FailReason) like '%execution%' then 'Time expired to Execute'
when ErrorCode=741 and lower(FailReason) not like 'failed%' then 'Position was not recorded or already closed'
when ErrorCode=741 and lower(FailReason) like 'failed%' then 'Failed create execution context to send to LP'
when ErrorCode=772 then 'Unable to retrieve the data'
--when ErrorCode=606 and lower(FailReason) like '%timeout expired%'
--and lower(FailReason) not like '%execution%' then 'Time expired to Execute'
when ErrorCode in (619,640,714,715,717,720,721,716,808,951,818) then 'Settings'
when ErrorCode =816 and lower(FailReason) not like '%the user is blocked from closing the position%' then 'Settings'
when ErrorCode= 710 then 'UI Mistake'
else 'others' end as 'Cause'

----variable 6
,case when ErrorCode=606 and lower(FailReason) not like '%execution%' 
and lower(FailReason) not like '%timeout expired%' then 'Internal'
when ErrorCode=607 and lower(FailReason) not like '%db failure%' then 'Internal' 
when ErrorCode=612 then 'Internal'
when ErrorCode=609 then 'Internal'
when ErrorCode=945
and 
(lower(FailReason)like '%no default is define for that instrument%'
or lower(FailReason)like '%ordervalidation - execution did not pass max deal size validation%'
or lower(FailReason)like '%providerunkown%'
) then 'Internal'
when ErrorCode=787 and lower(FailReason) like '%have pending full orders%' then 'External'
when ErrorCode in (607,613) and lower(FailReason) like '%db failure%' then 'Internal'
when ErrorCode=606 and lower(FailReason) like '%execution%' then 'Internal/External'
when ErrorCode=741 and lower(FailReason) not like 'failed%' then 'Internal'
when ErrorCode=741 and lower(FailReason) like 'failed%' then 'Internal'
when ErrorCode=772 then 'Internal'
--when ErrorCode=606 and lower(FailReason) like '%timeout expired%'
--and lower(FailReason) not like '%execution%' then 'Internal'
when ErrorCode in (619,640,714,715,717,720,721,716,808,951,818) then 'Internal'
when ErrorCode =816 and lower(FailReason) not like '%the user is blocked from closing the position%' then 'Internal'
when ErrorCode= 710 then 'Internal'
else 'others' end as 'Internal_External'

----variable 7
,case when ErrorCode=606 and lower(FailReason) not like '%execution%' 
and lower(FailReason) not like '%timeout expired%' then 'Trading R&D'
when ErrorCode=607 and lower(FailReason) not like '%db failure%' then 'Trading R&D' 
when ErrorCode=612 then 'Trading R&D'
when ErrorCode=609 then 'Trading Ops/Dealing'
when ErrorCode=945
and 
(lower(FailReason)like '%no default is define for that instrument%'
or lower(FailReason)like '%ordervalidation - execution did not pass max deal size validation%'
or lower(FailReason)like '%providerunkown%'
) then 'Trading Ops/Dealing'
when ErrorCode=787 and lower(FailReason) like '%have pending full orders%' then 'Trading R&D'
when ErrorCode in (607,613) and lower(FailReason) like '%db failure%' then 'Trading R&D'
when ErrorCode=606 and lower(FailReason) like '%execution%' then 'Trading R&D/LP'
when ErrorCode=741 and lower(FailReason) not like 'failed%' then 'Trading R&D'
when ErrorCode=741 and lower(FailReason) like 'failed%' then 'Human error'
when ErrorCode=772 then 'Trading R&D'
--when ErrorCode=606 and lower(FailReason) like '%timeout expired%'
--and lower(FailReason) not like '%execution%' then 'R&D or LP(Internal or External)'
when ErrorCode in (619,640,714,715,717,720,721,716,808,951,818) then 'Trading Ops/Dealing'
when ErrorCode =816 and lower(FailReason) not like '%the user is blocked from closing the position%' then 'Trading Ops/Dealing'
when ErrorCode= 710 then 'User Experience'
else 'others' end as 'Department'
from
Dealing_dbo.Dealing_Fails_PI fail
inner join DWH_dbo.Dim_Customer dm
on (fail.CID=dm.RealCID and dm.PlayerStatusID=1)
left join DWH_dbo.Dim_Instrument di
on fail.InstrumentID=di.InstrumentID
where 
-- IsCopy=0 and
 Date>='2023-01-01'
and ErrorCode is not null

----Population
and 
(
(ErrorCode=606 and lower(FailReason) not like '%execution%' 
and lower(FailReason) not like '%timeout expired%' )
or
(ErrorCode=607 and lower(FailReason) not like '%db failure%')
or
(ErrorCode in (612,609,772,619,640,714,715,717,720,721,716,808,951,818,710))
or
(ErrorCode=787 and lower(FailReason) like '%have pending full orders%')
or
(ErrorCode in (607,613) and lower(FailReason) like '%db failure%' )
or
(ErrorCode=606 and lower(FailReason) like '%execution%')
or
(ErrorCode=741 and lower(FailReason) not like 'failed%' )
or
(ErrorCode=741 and lower(FailReason) like 'failed%')
or
(ErrorCode =816 and lower(FailReason) not like '%the user is blocked from closing the position%')

or
(
ErrorCode=945
and 
(lower(FailReason)like '%no default is define for that instrument%'
or lower(FailReason)like '%ordervalidation - execution did not pass max deal size validation%'
or lower(FailReason)like '%providerunkown%'
)
)
or
(
ErrorCode in (768,953,949,1044,956,1029,1000,764,789,1005,796,749,766,1006,773,1024,1014,967,711,770,769,1019,759,957,1045,1012,942,1011,628,693,1049,771,814,733,966,1002,775,1050)
)
)


)final 
)final1
where rn=1
)final2
)final3
group by YearMonth,InstrumentID,CBH_HBC, ind_success,IsCopy, InstrumentType, InstrumentDisplayName_
)final4
)

union all

--success

(select final_succ1.* 
,di.InstrumentType, di.InstrumentDisplayName as InstrumentDisplayName_
from
(

select YearMonth,InstrumentID, CBH_HBC,ind_success,IsCopy, sum(amount_trans) as amount_trans
  from
  (

  (
  select YearMonth, InstrumentID, CBH_HBC,ind_success,IsCopy, count(*) amount_trans
  from
  (

select  left(OpenDateID,6) as YearMonth, InstrumentID
,case when MirrorID=0 then 0 else 1 end as 'IsCopy'
, case when HedgeServerID in (2,5,9,13,21,22,24,25,81,83,101,110,111,112,120,122,125,126,127,128,129,130,5000) then 'CBH'
--when HedgeServerID= '81b' then 'CBH'
when HedgeServerID in (6,8,82,84,102,124) then 'HBC'
when HedgeServerID=0 then 'HS_zero'
when HedgeServerID is null then 'HS null'
else 'not defined' end as 'CBH_HBC'
,1 as 'ind_success'
from DWH_dbo.Dim_Position
where OpenDateID>=20230101
and CID in (select distinct RealCID from DWH_dbo.Dim_Customer where PlayerStatusID=1 )
)base_open
group by YearMonth, InstrumentID, CBH_HBC,ind_success,IsCopy
)
union all
(  select YearMonth, InstrumentID, CBH_HBC,ind_success,IsCopy, count(*) amount_trans
from
(
select  left(CloseDateID,6) as YearMonth, InstrumentID
,case when MirrorID=0 then 0 else 1 end as 'IsCopy'
, case when HedgeServerID in (2,5,9,13,21,22,24,25,81,83,101,110,111,112,120,122,125,126,127,128,129,130,5000) then 'CBH'
--when HedgeServerID= '81b' then 'CBH'
when HedgeServerID in (6,8,82,84,102,124) then 'HBC'
when HedgeServerID=0 then 'HS_zero'
when HedgeServerID is null then 'HS null'
else 'not defined' end as 'CBH_HBC'
,1 as 'ind_success'
from DWH_dbo.Dim_Position
where CloseDateID>=20230101
and CID in (select distinct RealCID from DWH_dbo.Dim_Customer where PlayerStatusID=1 )
)base_close
group by YearMonth, InstrumentID, CBH_HBC,ind_success,IsCopy
)
)final_succ
group by YearMonth,InstrumentID, CBH_HBC,ind_success,IsCopy
)final_succ1

left join DWH_dbo.Dim_Instrument di
on final_succ1.InstrumentID=di.InstrumentID
)
)final_both
where InstrumentType is not null