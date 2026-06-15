SELECT  
mda.CurrencyBalanceID , mda.Country
 ,mda.CardCreateDate, mda.CardID, mda.CardStatus,
 mda.CardStatusID, mda.CardStatusExpirationTime,
 mda.HasCard, mda.Region, mda.AccountCreateDate, mda.CardStatusTime, mda.BankAccountIBAN
FROM eMoney_dbo.eMoney_Dim_Account mda
WHERE 
       mda.IsValidETM = 1
    AND mda.GCID_Unique_Count = 1
    AND mda.CountryID IN (
        165, 112, 164, 168, 32, 79, 143, 184, 185, 95, 
        118, 55, 100, 72, 54, 191, 82, 197, 52, 19, 
        126, 102, 74, 13, 117, 154, 196, 57, 67, 
        135, 119, 94
    )