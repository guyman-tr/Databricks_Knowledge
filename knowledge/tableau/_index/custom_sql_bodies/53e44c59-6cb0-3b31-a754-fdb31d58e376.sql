SELECT 
  COALESCE(r.Country, ftd.Country, v1.Country, v2.Country, v3.Country, fa.Country, ff.Country) AS Country,
  COALESCE(r.Region, ftd.Region, v1.Region, v2.Region, v3.Region, fa.Region, ff.Region) AS Region,
  COALESCE(r.RegMonth, ftd.FirstDeposit, v1.V1Date, v2.V2Date, v3.V3Date, fa.FirstActionDate, ff.FirstFundedDate) AS ActiveDate,
  COALESCE(r.Channel, ftd.Channel, v1.Channel, v2.Channel, v3.Channel, fa.Channel, ff.Channel) AS Channel,
  COALESCE(r.SubChannel, ftd.SubChannel, v1.SubChannel, v2.SubChannel, v3.SubChannel, fa.SubChannel, ff.SubChannel) AS SubChannel,
  r.CIDs AS Registrations,
  ftd.CIDs AS FTD,
  v1.CIDs AS V1,
  v2.CIDs AS V2,
  v3.CIDs AS V3,
  fa.CIDs AS FirstAction,
  ff.CIDs AS FirstFunded,
  COALESCE(r.[Platform], ftd.[Platform], v1.[Platform], v2.[Platform], v3.[Platform], fa.[Platform], ff.[Platform]) AS Platform_,
COALESCE(r.[AffiliateID], ftd.[AffiliateID], v1.[AffiliateID], v2.[AffiliateID], v3.[AffiliateID], fa.[AffiliateID], ff.[AffiliateID]) AS AffiliateID
FROM #Registrations r
FULL OUTER JOIN #FTDs ftd
  ON r.Country = ftd.Country
  AND r.Region = ftd.Region 
  AND r.RegMonth = ftd.FirstDeposit
  AND r.Channel = ftd.Channel 
  AND r.SubChannel = ftd.SubChannel
  AND r.[Platform] = ftd.[Platform] 
  and r.AffiliateID=ftd.AffiliateID
FULL OUTER JOIN #V1 v1
  ON COALESCE(r.Country, ftd.Country) = v1.Country
  AND COALESCE(r.Region, ftd.Region) = v1.Region
  AND COALESCE(r.RegMonth, ftd.FirstDeposit) = v1.V1Date
  AND COALESCE(r.Channel, ftd.Channel) = v1.Channel
  AND COALESCE(r.SubChannel, ftd.SubChannel) = v1.SubChannel
  AND COALESCE(r.[Platform], ftd.[Platform]) = v1.[Platform]
and COALESCE(r.[AffiliateID], ftd.[AffiliateID]) = v1.[AffiliateID]
FULL OUTER JOIN #V2 v2
  ON COALESCE(r.Country, ftd.Country, v1.Country) = v2.Country
  AND COALESCE(r.Region, ftd.Region, v1.Region) = v2.Region
  AND COALESCE(r.RegMonth, ftd.FirstDeposit, v1.V1Date) = v2.V2Date
  AND COALESCE(r.Channel, ftd.Channel, v1.Channel) = v2.Channel
  AND COALESCE(r.SubChannel, ftd.SubChannel, v1.SubChannel) = v2.SubChannel
  AND COALESCE(r.[Platform], ftd.[Platform], v1.[Platform]) = v2.[Platform] 
  AND COALESCE(r.[AffiliateID], ftd.[AffiliateID], v1.[AffiliateID]) = v2.[AffiliateID] 
FULL OUTER JOIN #V3 v3
  ON COALESCE(r.Country, ftd.Country, v1.Country, v2.Country) = v3.Country
  AND COALESCE(r.Region, ftd.Region, v1.Region, v2.Region) = v3.Region
  AND COALESCE(r.RegMonth, ftd.FirstDeposit, v1.V1Date, v2.V2Date) = v3.V3Date
  AND COALESCE(r.Channel, ftd.Channel, v1.Channel, v2.Channel) = v3.Channel
  AND COALESCE(r.SubChannel, ftd.SubChannel, v1.SubChannel, v2.SubChannel) = v3.SubChannel
  AND COALESCE(r.[Platform], ftd.[Platform], v1.[Platform], v2.[Platform]) = v3.[Platform]
  AND COALESCE(r.[AffiliateID], ftd.[AffiliateID], v1.[AffiliateID], v2.[AffiliateID]) = v3.[AffiliateID]
FULL OUTER JOIN #FirstAction fa
  ON COALESCE(r.Country, ftd.Country, v1.Country, v2.Country, v3.Country) = fa.Country
  AND COALESCE(r.Region, ftd.Region, v1.Region, v2.Region, v3.Region) = fa.Region
  AND COALESCE(r.RegMonth, ftd.FirstDeposit, v1.V1Date, v2.V2Date, v3.V3Date) = fa.FirstActionDate
  AND COALESCE(r.Channel, ftd.Channel, v1.Channel, v2.Channel, v3.Channel) = fa.Channel
  AND COALESCE(r.SubChannel, ftd.SubChannel, v1.SubChannel, v2.SubChannel, v3.SubChannel) = fa.SubChannel
  AND COALESCE(r.[Platform], ftd.[Platform], v1.[Platform], v2.[Platform], v3.[Platform]) = fa.[Platform] 
 AND COALESCE(r.[AffiliateID], ftd.[AffiliateID], v1.[AffiliateID], v2.[AffiliateID], v3.[AffiliateID]) = fa.[AffiliateID] 
FULL OUTER JOIN #FirstFunded ff
  ON COALESCE(r.Country, ftd.Country, v1.Country, v2.Country, v3.Country, fa.Country) = ff.Country
  AND COALESCE(r.Region, ftd.Region, v1.Region, v2.Region, v3.Region, fa.Region) = ff.Region
  AND COALESCE(r.RegMonth, ftd.FirstDeposit, v1.V1Date, v2.V2Date, v3.V3Date, fa.FirstActionDate) = ff.FirstFundedDate
  AND COALESCE(r.Channel, ftd.Channel, v1.Channel, v2.Channel, v3.Channel, fa.Channel) = ff.Channel
  AND COALESCE(r.SubChannel, ftd.SubChannel, v1.SubChannel, v2.SubChannel, v3.SubChannel, fa.SubChannel) = ff.SubChannel
  AND COALESCE(r.[Platform], ftd.[Platform], v1.[Platform], v2.[Platform], v3.[Platform], fa.[Platform]) = ff.[Platform]
 AND COALESCE(r.[AffiliateID], ftd.[AffiliateID], v1.[AffiliateID], v2.[AffiliateID], v3.[AffiliateID], fa.[AffiliateID]) = ff.[AffiliateID]