# Column Lineage — BI_DB_dbo.BI_DB_LiveAcquisitionDashboard

**Writer SP**: `BI_DB_dbo.SP_H_LiveAcquisitionDashboard` (Priority 0 — Hourly)
**ETL Pattern**: TRUNCATE + INSERT (full refresh every hour)
**Population Filter**: PlayerLevelID ≠ 4, LabelID ≠ 30, CountryID ≠ 250
**Anchor**: `@MinDate` = MAX(CAST(Date AS DATE)) FROM `BI_DB_LiveAcquisitionDashboard_Daily`

**Note**: Live intraday data (≥ @MinDate+1 day) sourced from `External_etoro_DWH_V_CustomerCustomerHourly`; historical data (≤ @MinDate+1) from `BI_DB_LiveAcquisitionDashboard_Daily`. TRUNCATE+INSERT means no history in this table — it always reflects a rolling window (~90 days).

---

## Source Chain

```
External_etoro_DWH_V_CustomerCustomerHourly (a)
  (hourly lake copy of etoro.Customer.Customer)
                         │
SP_Create_External_etoro_billing_deposit_hourly_Range
  → LiveAcquisition_Billing_Deposit_Hourly_Range (b) ──→ JOIN on CID (IsFTD=1, PaymentStatusID=2)
                         │
BI_DB_LiveAcquisitionDashboard_Daily (b/dc) ─────────→ historical rows (≤ @MinDate+1)
  + DWH_dbo.Dim_Customer (dc, LEFT JOIN on RealCID=CID)   historical path enrichment
                         │
               #FTDs (intraday live FTDs UNION historical FTDs)
                         ↓
            #FTDs_Final  (adds Fast, Fast24H, RegToFTDBuckets, RegToFTD)
                         ↓
            #Final       (UNION #FTDs_Final + Registration rows [live UNION historical])
                         │
   DWH_dbo.Dim_Country ──┼── Region, Country
   DWH_dbo.Dim_Affiliate ─┼── AffiliatesGroupsName, Contact
   DWH_dbo.Dim_Channel ───┼── Channel, SubChannel
   DWH_dbo.Dim_Funnel ────┼── FunnelName (FunnelID), FunnelFromName (FunnelFromID)
   DWH_dbo.Dim_State_and_Province ─┼── State
                         ↓
         TRUNCATE TABLE BI_DB_dbo.BI_DB_LiveAcquisitionDashboard
         INSERT INTO    BI_DB_dbo.BI_DB_LiveAcquisitionDashboard
```

---

## Column-Level Lineage

| BI_DB Column | Source Table | Source Column | Transform |
|-------------|-------------|---------------|-----------|
| AffiliatesGroupsName | DWH_dbo.Dim_Affiliate (DA) | AffiliatesGroupsName | Direct. Joined via SerialID = AffiliateID. NULL for organic/unmatched |
| Contact | DWH_dbo.Dim_Affiliate (DA) | Contact | Direct. Same join |
| Channel | DWH_dbo.Dim_Channel (DC) | Channel | Direct. Dim_Affiliate.SubChannelID = Dim_Channel.SubChannelID |
| SubChannel | DWH_dbo.Dim_Channel (DC) | SubChannel | Direct. Same join |
| CID | External_etoro_DWH_V_CustomerCustomerHourly (a) | CID | Direct. Historical path: BI_DB_LiveAcquisitionDashboard_Daily.CID |
| Date | External_etoro_DWH_V_CustomerCustomerHourly (a) | ModificationDate / Registered | FTDs live: ModificationDate (deposit approval). Registration live: Registered. Historical: b.Date or dc.RegisteredReal |
| CountryID | External_etoro_DWH_V_CustomerCustomerHourly (a) | CountryID | Direct. Historical: dc.CountryID (Dim_Customer). Filter: ≠ 250 |
| Region | DWH_dbo.Dim_Country (country) | MarketingRegionManualName | Direct. Joined via CountryID |
| Country | DWH_dbo.Dim_Country (country) | Name | Direct. Same join |
| Fast | computed | Registered, Date | FTDs only: CASE WHEN DATEDIFF(DAY,Registered,Date)=1 THEN 1 ELSE 0. NULL for Registration rows |
| Fast24H | computed | Registered, Date | FTDs only: CASE WHEN DATEDIFF(HOUR,Registered,Date) BETWEEN 0 AND 24 THEN 1 ELSE 0. NULL for Registration rows |
| KPI | literal | — | 'FTDs' or 'Registration' — injected by SP control flow at temp table creation |
| FTDA | LiveAcquisition_Billing_Deposit_Hourly_Range (b) | Amount, ExchangeRate | Amount × ExchangeRate = deposit in USD. Historical: BI_DB_LiveAcquisitionDashboard_Daily.FTDA. NULL for Registration rows |
| SerialID | External_etoro_DWH_V_CustomerCustomerHourly (a) | SerialID | Direct. Historical: BI_DB_LiveAcquisitionDashboard_Daily.SerialID |
| SubSerialID | External_etoro_DWH_V_CustomerCustomerHourly (a) | SubSerialID | Direct. Historical path uses COLLATE Latin1_General_100_BIN |
| DownloadID | External_etoro_DWH_V_CustomerCustomerHourly (a) | DownloadID | Direct. Historical: BI_DB_LiveAcquisitionDashboard_Daily.DownloadID |
| FunnelName | DWH_dbo.Dim_Funnel (f) | Name | Joined via FunnelID from customer record (live: External.FunnelID; historical: dc.FunnelID) |
| FunnelFromName | DWH_dbo.Dim_Funnel (ff) | Name | Separate alias (ff) on same Dim_Funnel table, joined via FunnelFromID |
| RegToFTDBuckets | computed | Registered, Date | FTDs only: CASE DATEDIFF(DAY): 0→SameDay, 1→1 Day, 2→2Days, <7→Same Week, <30→Same Month, else→OldReg. NULL for Registration rows |
| RegToFTD | computed | Registered, Date | FTDs only: DATEDIFF(DAY,Registered,Date). Implicit INT→varchar(100) cast. NULL for Registration rows |
| State | DWH_dbo.Dim_State_and_Province (re) | Name | Joined via RegionID = RegionByIP_ID. NULL for ~91.7% of rows |
| UpdateDate | GETDATE() | — | ETL metadata: SP execution timestamp, refreshed every hour |
