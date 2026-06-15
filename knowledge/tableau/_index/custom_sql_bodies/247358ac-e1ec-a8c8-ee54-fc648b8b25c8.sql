select CID, DateID, Date,
        PlayerStatus, Club, Regulation, ToRegulation, 
	--IsDLTUser, 
	/*
	sum(ISNULL(CompensationsApexUSStocks,0)) AS CompensationsApexUSStocks,
	sum(CASE WHEN Regulation IN  ('FinCEN+FINRA','NYDFSFINRA')
		then
			- 1 *
			(
			ISNULL(TotalRealStocksEquityChange,0) -
			ISNULL(UnrealizedPnLChangeStocksReal,0) -
			ISNULL(ClientBalanceRealizedPnLRealStocks,0)
			)
		else 0 
	END) AS intermediate_cal,
	*/
	sum(ISNULL(CompensationsApexUSStocks,0) + (
	CASE WHEN Regulation IN  ('FinCEN+FINRA','NYDFSFINRA')
    then
        - 1 *
        (
        ISNULL(TotalRealStocksEquityChange,0) -
        ISNULL(UnrealizedPnLChangeStocksReal,0) -
        ISNULL(ClientBalanceRealizedPnLRealStocks,0)
        )
	else 0 
	END
	)) AS cal_real_stock_invested_amount_cg_adj
from BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New with (nolock)
WHERE DateID >= 20250101
AND ToRegulation IN ('eToroUS','FinCEN','FinCEN+FINRA','FINRAONLY')
AND IsCreditReportValidCB=1
GROUP BY CID, DateID, Date, PlayerStatus, Club, Regulation, ToRegulation
	--IsDLTUser
HAVING sum(ISNULL(CompensationsApexUSStocks,0) + (
	CASE WHEN Regulation IN  ('FinCEN+FINRA','NYDFSFINRA')
    then
        - 1 *
        (
        ISNULL(TotalRealStocksEquityChange,0) -
        ISNULL(UnrealizedPnLChangeStocksReal,0) -
        ISNULL(ClientBalanceRealizedPnLRealStocks,0)
        )
	else 0 
	END
	))<>0