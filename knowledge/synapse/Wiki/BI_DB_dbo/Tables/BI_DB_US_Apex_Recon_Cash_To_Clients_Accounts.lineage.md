# Lineage: BI_DB_US_Apex_Recon_Cash_To_Clients_Accounts

**Schema:** BI_DB_dbo  
**Writer SP:** `SP_US_Apex_Recon_Cash_To_Clients_Accounts`  
**Author:** Artyom Bogomolsky (2021-09-29; 5 revisions through 2021-10-26)  
**ETL Pattern:** DELETE WHERE ProcessDate=@Date → INSERT SELECT  
**Frequency:** Daily (SB_Daily, Priority 20)

## Column Lineage

| Target Column | Source Table | Source Column | Transformation |
|---|---|---|---|
| AccountNumber | External_Sodreconciliation_apex_EXT872_TradeActivity | AccountNumber | Driver table — every row is an EXT872 trade record |
| CID | External_USABroker_Apex_UserData | CID | LEFT JOIN via Apex_ApexData.GCID → Apex_UserData.GCID; NULL when no eToro customer mapping |
| GCID | External_USABroker_Apex_UserData | GCID | LEFT JOIN via Apex_ApexData.GCID; NULL when no eToro customer mapping |
| ProcessDate | EXT872_TradeActivity | ProcessDate | CAST to DATE; equals @Date SP parameter |
| CashFlowAmount | External_Sodreconciliation_apex_EXT869_CashActivity | Amount | SUM(Amount) WHERE TerminalID='OMJNL', Description='Journal from'; LEFT JOIN — NULL when no journal entry |
| Trade_Amount | External_Sodreconciliation_apex_EXT872_TradeActivity | NetAmount | SUM(NetAmount) — net of buys and sells for the day |
| FOFAmount | External_ExternalOperations_Funding_UserTransactionsAggregation | AggregatedAmount | SUM(AggregatedAmount) from ExternalOperations funding log; LEFT JOIN — NULL when no fund transfer |
| HWM | Computed from EXT872_TradeActivity | NetAmount | MAX(running cumulative net) across ordered intraday trades, HAVING MAX > 0; NULL when cumulative net ≤ 0 |
| UpdateDate | ETL runtime | GETDATE() | Always current ETL run timestamp |

## Source Tables

| Table | Role | Filter |
|---|---|---|
| `External_Sodreconciliation_apex_EXT872_TradeActivity` | Driver — trade activity (format 872) | ProcessDate=@Date, most recent SodFile |
| `External_Sodreconciliation_apex_EXT869_CashActivity` | Cash journals (format 869) | TerminalID='OMJNL', Description='Journal from', ProcessDate=@Date |
| `External_Sodreconciliation_apex_SodFiles` | File validation | ApexFormat IN(869,872), Status=2, ProcessDate=@Date — takes max ImportEndDate |
| `External_ExternalOperations_Funding_MoneyTransferRequestLog` | FOF transfer log | AggregationDate=@Date |
| `External_ExternalOperations_Funding_UserTransactionsAggregation` | FOF aggregated amounts | Joined to transfer log on AggregationID |
| `External_USABroker_Apex_ApexData` | Apex account → GCID mapping | ApexID = AccountNumber |
| `External_USABroker_Apex_UserData` | GCID → CID/GCID | Joined via ApexData.GCID |

## ETL Notes

- **Driver is EXT872**: All output rows are anchored to trade records. Accounts with journal entries (EXT869) but no trades do NOT appear.
- **MSB account excluded**: AccountNumber='3ET00001' explicitly filtered from INSERT.
- **File validation**: SP selects the most recently imported EXT869/EXT872 files for @Date (max ImportEndDate, Status=2) to ensure freshest data.
- **HWM = max intraday cumulative net**: Built by ordering EXT872 trades by ExecutionTime, computing running sum of NetAmount, then taking MAX where BuySellCode IN ('B','S'). HAVING MAX > 0 — so accounts that never had positive net cumulative are excluded from HWM.
- **Trade_Amount changed**: Originally Buy Amount only; changed 2021-10-13 to Net Amount (buys + sells net).
- **NULL patterns**: CashFlowAmount NULL (49% of rows) = account traded but had no EXT869 journal; FOFAmount NULL (45%) = no FOF transfer; HWM NULL (28%) = net position never went positive; CID NULL (21%) = Apex account not linked to eToro customer.
