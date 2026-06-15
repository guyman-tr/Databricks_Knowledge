SELECT 
    ad.YearMonth,
    ad.Channel,
    ad.SubChannel,
    ad.Region,
    ad.Cost,
    r.Regs,
    ad.FTDs,
    ad.LTV,
    ad.LTV_FTDs,
    ad.LTV_LeadScore,
    ad.Users_LeadScore
FROM #alldata ad
LEFT JOIN #reg r ON ad.YearMonth = r.YearMonth 
    AND ad.Channel = r.Channel 
    AND ad.SubChannel = r.SubChannel 
    AND ad.Region = r.Region