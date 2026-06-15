select a.CID, a.MirrorID, b.Amount as Calc1, sum(a.Amount + a.PnLInDollars) Calc2
, mrr.nmi
from main.dwh.dim_position a
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror b
 on a.MirrorID=b.MirrorID
 join ( select mrr.MirrorID ,sum (case when mrr.MirrorOperationID = 2 then -1*mrr.Amount else mrr.Amount end )nmi
from main.trading.bronze_etoro_history_mirror mrr
 where  mrr.MirrorOperationID in (1,2,3)
 and mrr.ParentCID = 37890645
 group by mrr.MirrorID
 ) mrr
 on mrr.MirrorID = a.MirrorID 
where b.ParentCID = 37890645 -- Tactical edge
and a.CloseDateID = 0 
and a.OpenDateID >= 20240101
group by a.CID, a.MirrorID, b.Amount, mrr.nmi