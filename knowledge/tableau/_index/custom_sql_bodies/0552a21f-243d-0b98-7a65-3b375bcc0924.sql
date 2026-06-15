SELECT cd.CampaignNumber,
cd.CampaignName,
cd.SendDateID,
COUNT(DISTINCT cd.GCID) AS User_Send,
SUM(cd.CountOpen) AS CountOpen,
SUM(cd.UniqueOpen) AS UniqueOpen,
SUM(cd.CountClicks) AS CountClicks,
SUM(cd.UniqueClicks) AS UniqueClicks,
COUNT(DISTINCT efa.Gcid) AS account_created,
COUNT(DISTINCT card_activation.GCID) AS cards_activated,
COUNT(DISTINCT did_trnsaction.GCID) AS did_transaction
FROM (SELECT CampaignNumber,CampaignName,CONVERT(date, convert(varchar(10), bdsr.SendDateID)) AS SendDateID
                                     ,bdsr.EmailName,bdsr.GCID,
CountOpen,
UniqueOpen,
CountClicks,
UniqueClicks

FROM BI_DB.dbo.BI_DB_SFMC_Report bdsr 
WHERE CampaignNumber IN ('5050','6439','9065','5729','6380','7384') AND bdsr.SendDateID>=20220202 AND Delivered<>0 ) cd

LEFT JOIN ETL_FiatAccount efa ---accounts that didnt created account
ON cd.CampaignNumber in('9065','5729') AND efa.Date>=cd.SendDateID AND cd.GCID=efa.Gcid

LEFT JOIN (
SELECT DISTINCT efc.GCID, efc.EventTimeStamp
from (SELECT c.GCID,cardstatus.Name ,cs.EventTimeStamp ,row_number() over (partition by cs.CardId order by cs.EventTimeStamp desc) as RN
FROM [dbo].[ETL_FiatCardStatuses] cs
join [dbo].[ETL_DictionaryCardStatuses] cardstatus on cardstatus.Id=cs.[CardStatusId]
join [dbo].[ETL_FiatCards] cards on cards.Id=cs.CardId
join [dbo].[ETL_FiatAccount] account on account.Id=cards.[AccountId]
join DWH.dbo.Dim_Customer c on c.GCID=account.Gcid
WHERE cs.DateID>='20211125') efc WHERE efc.RN=1 AND efc.Name='Activated'
) card_activation---accounts that didnt activated
ON cd.CampaignNumber in('5050','6439') AND card_activation.EventTimeStamp>=cd.SendDateID
                                                                  AND cd.GCID=card_activation.GCID

LEFT JOIN (
SELECT DISTINCT mft.GCID/*,mft.DateID*/
FROM eMoney_Fact_Transactions mft
INNER JOIN (SELECT DISTINCT bdsr.GCID,bdsr.SendDateID FROM BI_DB..BI_DB_SFMC_Report bdsr WHERE CampaignNumber in ('6380','7384')) AS cd
ON mft.DateID>=cd.SendDateID AND cd.GCID=mft.GCID
WHERE mft.DateID>='20211125' AND mft.TransactionType IN ('CardPayment', 'Contactless','OnlinePayment','CashWithdrawal')
--ORDER BY mft.GCID
)AS did_trnsaction
ON  cd.GCID=did_trnsaction.GCID
GROUP BY cd.CampaignNumber,
cd.CampaignName,
cd.SendDateID