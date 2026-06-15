SELECT 
    CID,
	case when Regulation in ('eToroUS','FinCEN','FinCEN+FINRA') then 'FinCEN' 
	when Regulation in ('ASIC','ASIC & GAML') then 'ASIC' else Regulation end as [Regulation],
	YearMonth,
    DateID,
FundingType,
    month as Month,
    RealizedEquity as Balance,
    max_loss as Max_Loss,
    total_chargeback AS CHBK_Amount,
    total_refund AS RR_Amount,
    actual_loss AS Final,
    allocated_chb_loss AS CHBK_Loss,
    allocated_rr_loss AS RR_loss,
[Country By Reg Form]
FROM #allocated_losses