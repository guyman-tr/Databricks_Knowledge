# Column Lineage — BI_DB_dbo.BI_DB_MarketingMonthlyRawData

**Writer SP**: `BI_DB_dbo.SP_Marketing_Cube` (@Date parameter, daily)
**ETL Pattern**: DELETE-INSERT — deletes YearMonthID ≥ last-month-start AND YearMonthID < year-5-years-back, then re-inserts
**Grain**: AffiliateID × CountryID × YearMonthID × Funnel (monthly aggregation of BI_DB_MarketingDailyRawData)
**Rolling window**: ~5 years (YearMonthID range: 202101 → 202604 as of Apr 2026 sample)
**Source**: Directly derived from `BI_DB_MarketingDailyRawData` — SELECT SUM(...) GROUP BY dimensions WHERE DateID >= @StartOfLastMonth

---

## Source Chain

```
BI_DB_dbo.BI_DB_MarketingDailyRawData (MRD)
  WHERE MRD.DateID >= @StartOfLastMonth
  GROUP BY AffiliateID, CountryID, CONVERT(VARCHAR(6), DateID), CONVERT(VARCHAR(7), Date),
           Funnel, CountryName, Region, Desk, DateCreated, Channel, SubChannel,
           Organic/Paid, Contact, ContractName, ContractType, AffiliatesGroupsName,
           AccountActivated, NewMarketingRegion
           ↓
DELETE WHERE YearMonthID >= @StartOfLastMonthIDForMonthly OR YearMonthID < @StartOfYear5YearsBack
INSERT INTO BI_DB_dbo.BI_DB_MarketingMonthlyRawData
           ↓
UPDATE Channel/SubChannel/Organic-Paid from current Dim_Channel (same as Daily retroactive update)
```

---

## Column-Level Lineage

All columns except YearMonthID and YearMonth are sourced from `BI_DB_MarketingDailyRawData` via SUM aggregation or GROUP BY passthrough.

| BI_DB Column | Source (Daily → Monthly) | Transform |
|-------------|--------------------------|-----------|
| AffiliateID | BI_DB_MarketingDailyRawData.AffiliateID | GROUP BY passthrough |
| CountryID | BI_DB_MarketingDailyRawData.CountryID | GROUP BY passthrough |
| YearMonthID | BI_DB_MarketingDailyRawData.DateID | CONVERT(VARCHAR(6), DateID, 112) → YYYYMM string |
| YearMonth | BI_DB_MarketingDailyRawData.Date | CONVERT(VARCHAR(7), Date, 126) → YYYY-MM string |
| Funnel | BI_DB_MarketingDailyRawData.Funnel | GROUP BY passthrough |
| CountryName | BI_DB_MarketingDailyRawData.CountryName | GROUP BY passthrough |
| Region | BI_DB_MarketingDailyRawData.Region | GROUP BY passthrough |
| Desk | BI_DB_MarketingDailyRawData.Desk | GROUP BY passthrough |
| DateCreated | BI_DB_MarketingDailyRawData.DateCreated | GROUP BY passthrough |
| Channel | BI_DB_MarketingDailyRawData.Channel | GROUP BY passthrough. Also retroactively updated by UPDATE pass |
| SubChannel | BI_DB_MarketingDailyRawData.SubChannel | GROUP BY passthrough. Also retroactively updated |
| Organic/Paid | BI_DB_MarketingDailyRawData.[Organic/Paid] | GROUP BY passthrough |
| Contact | BI_DB_MarketingDailyRawData.Contact | GROUP BY passthrough |
| ContractName | BI_DB_MarketingDailyRawData.ContractName | GROUP BY passthrough |
| ContractType | BI_DB_MarketingDailyRawData.ContractType | GROUP BY passthrough |
| AffiliatesGroupsName | BI_DB_MarketingDailyRawData.AffiliatesGroupsName | GROUP BY passthrough |
| AccountActivated | BI_DB_MarketingDailyRawData.AccountActivated | GROUP BY passthrough |
| TotalCost | BI_DB_MarketingDailyRawData.TotalCost | SUM |
| RevShare_Comm | BI_DB_MarketingDailyRawData.RevShare_Comm | SUM |
| Chargebacks | BI_DB_MarketingDailyRawData.Chargebacks | SUM |
| NumberOfChargebacks | BI_DB_MarketingDailyRawData.NumberOfChargebacks | SUM |
| CPA_Comm | BI_DB_MarketingDailyRawData.CPA_Comm | SUM |
| CPL_Comm | BI_DB_MarketingDailyRawData.CPL_Comm | SUM |
| eCost | BI_DB_MarketingDailyRawData.eCost | SUM |
| Lead_Comm | BI_DB_MarketingDailyRawData.Lead_Comm | SUM |
| Tier2Commition | BI_DB_MarketingDailyRawData.Tier2Commition | SUM |
| Tier3Commition | BI_DB_MarketingDailyRawData.Tier3Commition | SUM |
| Registration | BI_DB_MarketingDailyRawData.Registration | SUM |
| SameDayFTD | BI_DB_MarketingDailyRawData.SameDayFTD | SUM |
| FTD | BI_DB_MarketingDailyRawData.FTD | SUM |
| EFTD | BI_DB_MarketingDailyRawData.EFTD | SUM |
| FTDA | BI_DB_MarketingDailyRawData.FTDA | SUM |
| NetRevenues | BI_DB_MarketingDailyRawData.NetRevenues | SUM |
| VerificationLevelID2 | BI_DB_MarketingDailyRawData.VerificationLevelID2 | SUM |
| VerificationLevelID3 | BI_DB_MarketingDailyRawData.VerificationLevelID3 | SUM |
| Installs | BI_DB_MarketingDailyRawData.Installs | SUM |
| TotalDeposit | BI_DB_MarketingDailyRawData.TotalDeposit | SUM |
| DBRev | BI_DB_MarketingDailyRawData.DBRev | SUM |
| RAF_Comm | BI_DB_MarketingDailyRawData.RAF_Comm | SUM |
| IsRev | BI_DB_MarketingDailyRawData.IsRev | SUM |
| Redeposits | BI_DB_MarketingDailyRawData.Redeposits | SUM |
| PastGRevenue | 0 (hardcoded) | Always 0 — legacy field removed from SP computation |
| GLTV | BI_DB_MarketingDailyRawData.GLTV | SUM |
| totalGroupLTV | BI_DB_MarketingDailyRawData.totalGroupLTV | SUM |
| totalExtLTV | BI_DB_MarketingDailyRawData.totalExtLTV | SUM |
| FTDfromLTV | BI_DB_MarketingDailyRawData.FTDfromLTV | SUM |
| Rev10 | BI_DB_MarketingDailyRawData.Rev10 | SUM |
| UpdateDate | GETDATE() | SP execution timestamp |
| LTV_NoExtreme | BI_DB_MarketingDailyRawData.LTV_NoExtreme | NOT in SP insert list — populated by separate LTV SP (same as Daily) |
| NewMarketingRegion | BI_DB_MarketingDailyRawData.NewMarketingRegion | GROUP BY passthrough |
