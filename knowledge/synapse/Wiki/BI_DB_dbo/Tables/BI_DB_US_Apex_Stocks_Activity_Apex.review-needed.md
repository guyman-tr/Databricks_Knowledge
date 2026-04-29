# BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_Apex — Review Needed

## Questions for Reviewer

1. **"Recieved" spelling**: This is in the SP source code (CASE WHEN TradeSettleBasis='R' THEN 'Recieved'). Is this intentional or should an ALTER fix it?
2. **Trailer field**: What do the various Trailer values mean beyond "STOCK SPLIT"? Is there a Apex data dictionary for SOD 870 trailer codes?
3. **TerminalID "85"**: Most rows have TerminalID=85. What does this represent in Apex's system?
4. **CID NULL**: When the ApexData/UserData JOIN chain breaks, CID is NULL. How many rows are affected?
