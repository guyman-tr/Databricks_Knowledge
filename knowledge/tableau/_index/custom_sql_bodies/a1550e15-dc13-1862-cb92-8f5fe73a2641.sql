select a.CID, a.MirrorID, mrr.ParentCID,b.Amount as Calc1, sum(a.Amount + a.PnLInDollars) Calc2
, mrr.nmi, Mo MoneyOut, MI MonenyIn
from main.dwh.dim_position a
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror b
 on a.MirrorID=b.MirrorID
 join ( select mrr.MirrorID ,mrr.ParentCID ,sum (case when mrr.MirrorOperationID = 2 then -1*mrr.Amount else mrr.Amount end )nmi, 
 SUM(Case when mrr.MirrorOperationID =1 or (mirroroperationid =3 and mrr.amount >0 ) then mrr.Amount ELSE 0 END)  MI,
 SUM( case when mrr.MirrorOperationID =2  then -1*mrr.Amount WHEN 
    mirroroperationid =3 and mrr.amount <= 0  then mrr.Amount  ELSE 0 END ) MO
from main.trading.bronze_etoro_history_mirror mrr
 where  mrr.MirrorOperationID in (1,2,3)
 group by mrr.MirrorID, mrr.ParentCID
 ) mrr
 on mrr.MirrorID = a.MirrorID 
and a.CloseDateID = 0 
and a.OpenDateID >= 20250101
group by a.CID, a.MirrorID, b.Amount, mrr.nmi, mrr.ParentCID, MI, MO