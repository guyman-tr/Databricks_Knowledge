SELECT
  YearMonth,
  Year_,
  YearQ,
  Channel,
  SubChannel,
  Region,
  Country,
  Gender,
  Age_Tier,
  Platform_,
  SUM(FTDs) AS FTDs,
  SUM(Regs) AS Regs
FROM (
  SELECT
    YearMonth, Year_, YearQ, Channel, SubChannel, Region, Country, Gender, Age_Tier, Platform_,
    FTDs,
    0 AS Regs
  FROM #FTD
  UNION ALL
  SELECT
    YearMonth, Year_, YearQ, Channel, SubChannel, Region, Country, Gender, Age_Tier, Platform_,
    0 AS FTDs,
    Regs
  FROM #reg
) AS facts
GROUP BY
  YearMonth, Year_, YearQ, Channel, SubChannel, Region, Country, Gender, Age_Tier, Platform_