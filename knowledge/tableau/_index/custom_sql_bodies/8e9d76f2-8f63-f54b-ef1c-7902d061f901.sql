(with previous as (
  select cid, group from main.bi_dealing_stg.bi_output_dealing_premier_customer_2026_new
  where InGroup = 1 and group in ('Investor', 'Top50') and date_trunc('MM', date) = date_trunc('MM', add_months(now(), -2))
)

select a.cid as lostCID, a.group, 'Churned' as status 
from main.bi_dealing_stg.bi_output_dealing_premier_customer_2026_new a 
join previous b on a.cid = b.cid
where a.ingroup = 0 and date_trunc('MM', date) = date_trunc('MM', now())
order by a.group)

union

select cid, group, 'New' as status from main.bi_dealing_stg.bi_output_dealing_premier_customer_2026_new a
group by group, cid
having min(date) = date_trunc('MM', now())