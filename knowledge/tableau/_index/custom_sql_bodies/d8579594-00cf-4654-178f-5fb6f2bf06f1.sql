select a.*,ds.Name as Status
from
(
select
case 
when Cashier_ID__c like 'd%' then 'deposit'
when Cashier_ID__c like 'w%' then 'withdraw'
when Cashier_ID__c like 'b%' and  CompensationReason__c is not null then 'compensation'
when Cashier_ID__c like 'b%' and  CompensationReason__c is null then 'bonus'
end as cashier_type,
CONCAT(
        CASE
            WHEN rc.PaymentStatus__c IS NOT NULL THEN 'd'
            WHEN rc.CashoutStatus__c IS NOT NULL THEN 'w'
        END,
        COALESCE(rc.PaymentStatus__c, rc.CashoutStatus__c)
    ) AS StatusCode,
rc.*,
cc.Player_Level__c,
cc.BillingCountry,
dr.Name
from Force.vRecentCashier_History rc
join force.vCustomerCustomer cc
	on rc.CID__c = cc.CID
join etoro.Batch_BackOfficeCustomer boc
	on boc.CID = rc.CID__c
join DataPlatform.Dictionary_etoro_Dictionary_Regulation dr
	on boc.RegulationID = dr.ID
) a
left join DataPlatform.Dictionary_etoro_Dictionary_Status ds
	on ds.statusID = a.StatusCode
where a.RecordCreationDate__c >>='2023-07-01'