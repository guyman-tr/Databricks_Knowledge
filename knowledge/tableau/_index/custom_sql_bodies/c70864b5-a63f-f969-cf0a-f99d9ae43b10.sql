select a.* ,
case when bw.WithdrawTypeID = 1 then 'Internal Transfer' else 'Other' end as InternalTransferOrOther,
DENSE_RANK() OVER (ORDER BY COAmount desc) AS RN
from 
main.bi_output_stg.bi_output_operations_opshighcashoutclientsemail a
join main.billing.bronze_etoro_billing_withdraw bw 
on bw.WithdrawID=a.WithdrawID