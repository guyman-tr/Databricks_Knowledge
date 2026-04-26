# Lineage: BI_DB_dbo.BI_DB_AML_PI_Abuse

**Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we + general schema (live transactional)

---

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | `DWH_dbo.Fact_SnapshotCustomer` | Fact | PI population gate (GuruStatusID≥2, IsValidCustomer=1, VerificationLevelID=3, IsDepositor=1); provides GuruStatusID, RegulationID, CountryID, PlayerStatusID, PlayerLevelID |
| 2 | `DWH_dbo.Dim_Customer` | Dim | PI PII fields (UserName, BirthDate, RegisteredReal, FirstDepositDate, Gender, IP, City, Zip, Address, FirstName, LastName, Email, Phone); also used for copier identity matching in abuse signal computation |
| 3 | `DWH_dbo.Dim_GuruStatus` | Dim | GuruStatusName lookup via GuruStatusID |
| 4 | `DWH_dbo.Dim_Country` | Dim | Country (Name), Region (MarketingRegionManualName) via Fact_SnapshotCustomer.CountryID |
| 5 | `DWH_dbo.Dim_PlayerStatus` | Dim | PlayerStatus (Name) via Fact_SnapshotCustomer.PlayerStatusID; also used in #Blocked: PlayerStatusID NOT IN (1,5) = restricted |
| 6 | `DWH_dbo.Dim_PlayerLevel` | Dim | Club (Name) via Fact_SnapshotCustomer.PlayerLevelID |
| 7 | `DWH_dbo.Dim_Regulation` | Dim | Regulation (Name) via Fact_SnapshotCustomer.RegulationID |
| 8 | `DWH_dbo.Dim_Range` | Dim | DateRangeID → Fact_SnapshotCustomer slice at @DateID |
| 9 | `DWH_dbo.V_Liabilities` | View | TotalEquity (Liabilities+ActualNWA), RealizedEquity, PositionPnL, Liabilities, Credit at @DateID; also Equity_Start_Copy (at StartCopy date) |
| 10 | `DWH_dbo.Dim_Position` | Dim | NumOfPositions, NumOfInstruments — COUNT(DISTINCT PositionID/InstrumentID) WHERE CloseDateID=0 AND OpenDateID≤@DateID |
| 11 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Copier relationships at @DateTime; AUC components (Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL); StartCopy for CIDs_Same_Start_Copy; copier CIDs for identity matching |
| 12 | `DWH_dbo.STS_User_Operations_Data_History` | Hist Table | ClientDeviceId (device fingerprints) for PI and copiers; date-filtered ≥20240101; excludes null-GUID (all zeros) |
| 13 | `DWH_dbo.Fact_BillingDeposit` | Fact | FundingID per PI (#PI_FID) and per copier (#Copy_FID); excludes FundingID IN (1–7) which represent generic/cash payment methods |
| 14 | `BI_DB_dbo.BI_DB_First5Actions` | BI Table | Investigation action history: FirstAction/Date, SecondAction/Date, ThirdAction/Date — LEFT JOIN on CID |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | CID | Fact_SnapshotCustomer | RealCID | rename RealCID→CID; PI's customer ID |
| 2 | UserName | Dim_Customer | UserName | passthrough via JOIN dc.RealCID = fsc.RealCID |
| 3 | RegisteredReal | Dim_Customer | RegisteredReal | passthrough |
| 4 | FirstDepositDate | Dim_Customer | FirstDepositDate | passthrough; DEFAULT='19000101' for non-depositors |
| 5 | PI_Age | Dim_Customer | BirthDate | `DATEDIFF(YEAR, dc.BirthDate, GETDATE())` — uses wall-clock, not @Date |
| 6 | Gender | Dim_Customer | Gender | passthrough |
| 7 | GuruStatusID | Fact_SnapshotCustomer | GuruStatusID | passthrough |
| 8 | GuruStatusName | Dim_GuruStatus | GuruStatusName | lookup via GuruStatusID |
| 9 | Country | Dim_Country | Name | `dc2.Name AS Country` via fsc.CountryID |
| 10 | Regulation | Dim_Regulation | Name | `dr.Name AS Regulation` via fsc.RegulationID |
| 11 | PlayerStatus | Dim_PlayerStatus | Name | `dps.Name AS PlayerStatus` via fsc.PlayerStatusID |
| 12 | Club | Dim_PlayerLevel | Name | `dpl.Name AS Club` via fsc.PlayerLevelID |
| 13 | Region | Dim_Country | MarketingRegionManualName | `dc2.MarketingRegionManualName AS Region` via fsc.CountryID |
| 14 | City | Dim_Customer | City | passthrough |
| 15 | Zip | Dim_Customer | Zip | passthrough |
| 16 | BirthDate | Dim_Customer | BirthDate | passthrough |
| 17 | TotalEquity | V_Liabilities | Liabilities, ActualNWA | `ISNULL(vl.Liabilities,0)+ISNULL(vl.ActualNWA,0)` at @DateID |
| 18 | RealizedEquity | V_Liabilities | RealizedEquity | passthrough, ISNULL→0 |
| 19 | PositionPnL | V_Liabilities | PositionPnL | passthrough, ISNULL→0 |
| 20 | Liabilities | V_Liabilities | Liabilities | passthrough, ISNULL→0 |
| 21 | Credit | V_Liabilities | Credit | passthrough, ISNULL→0 |
| 22 | NumOfPositions | Dim_Position | PositionID | `COUNT(DISTINCT PositionID)` WHERE CloseDateID=0 AND OpenDateID≤@DateID AND IsPartialCloseChild=0 |
| 23 | NumOfInstruments | Dim_Position | InstrumentID | `COUNT(DISTINCT InstrumentID)` same WHERE clause |
| 24 | Num_of_Blocked_copiers | Dim_Customer (copier) | PlayerStatusID | `SUM(Is_Blocked)` where Is_Blocked = `MAX(CASE WHEN dc.PlayerStatusID NOT IN (1,5) THEN 1 ELSE 0 END)` per copier — counts copiers in any non-Normal/non-Warning state |
| 25 | AUC | etoroGeneral_History_GuruCopiers | Cash, Investment, PnL, DetachedPosInvestment, Dit_PnL | `SUM(ISNULL(Cash,0)+ISNULL(Investment,0)+ISNULL(PnL,0)+ISNULL(DetachedPosInvestment,0)+ISNULL(Dit_PnL,0))` across all copiers per PI |
| 26 | NumOfCopiers | etoroGeneral_History_GuruCopiers | CID | `COUNT(DISTINCT CID)` among valid copiers (IsValidCustomer=1, IsDepositor=1, VerificationLevelID>1) |
| 27 | AUC_TopCopier | etoroGeneral_History_GuruCopiers | AUC | AUC of individual rank-1 copier by AUC DESC (rn=1 from #copy window) |
| 28 | AUC_Top2Copier | etoroGeneral_History_GuruCopiers | AUC | `SUM(AUC) WHERE rn < 3` — cumulative AUC of top 2 copiers |
| 29 | AUC_Top3Copier | etoroGeneral_History_GuruCopiers | AUC | `SUM(AUC) WHERE rn < 4` — cumulative AUC of top 3 copiers |
| 30 | AUC_Top4Copier | etoroGeneral_History_GuruCopiers | AUC | `SUM(AUC) WHERE rn < 5` — cumulative AUC of top 4 copiers |
| 31 | AUC_Top5Copier | etoroGeneral_History_GuruCopiers | AUC | `SUM(AUC) WHERE rn < 6` — cumulative AUC of top 5 copiers |
| 32 | Same_City_and_Zip_AS_PI | Dim_Customer (copier + PI) | City, Zip | `SUM(CASE WHEN dc.City=dc2.City AND dc.Zip=dc2.Zip THEN 1 ELSE 0 END)` |
| 33 | Same_DOB_AS_PI | Dim_Customer (copier + PI) | BirthDate | `SUM(CASE WHEN CAST(dc.BirthDate AS DATE)=CAST(dc2.BirthDate AS DATE) THEN 1 ELSE 0 END)` |
| 34 | Same_Phone_AS_PI | Dim_Customer (copier + PI) | Phone | `SUM(CASE WHEN dc.Phone LIKE dc2.Phone THEN 1 ELSE 0 END)` — LIKE not = (no wildcards; effectively equality) |
| 35 | Same_IP_AS_PI | Dim_Customer (copier + PI) | IP | `SUM(CASE WHEN dc.IP LIKE dc2.IP THEN 1 ELSE 0 END)` — registration IP match |
| 36 | Same_First_Name_AS_PI | Dim_Customer (copier + PI) | FirstName | `SUM(CASE WHEN UPPER(dc.FirstName) LIKE UPPER(dc2.FirstName) THEN 1 ELSE 0 END)` |
| 37 | Same_Last_Name_AS_PI | Dim_Customer (copier + PI) | LastName | `SUM(CASE WHEN UPPER(dc.LastName) LIKE UPPER(dc2.LastName) THEN 1 ELSE 0 END)` |
| 38 | Same_Middle_Name_AS_PI | Dim_Customer (copier + PI) | MiddleName | `SUM(CASE WHEN UPPER(dc.MiddleName) LIKE UPPER(dc2.MiddleName) THEN 1 ELSE 0 END)` |
| 39 | Same_Name_AS_PI | Dim_Customer (copier + PI) | FirstName, LastName, MiddleName | `SUM(CASE WHEN cross-name match: MiddleName=FirstName OR MiddleName=LastName OR FirstName=LastName [case-insensitive] THEN 1 ELSE 0 END)` |
| 40 | Same_First_Name | Dim_Customer (copiers) | FirstName | `COUNT(FirstName) - COUNT(DISTINCT FirstName)` per PI — count of duplicate first names among copiers (excess above unique) |
| 41 | Same_First_Name2 | Dim_Customer (copiers) | FirstName | `CASE WHEN (Same_First_Name+1)=1 THEN 0 ELSE (Same_First_Name+1) END` — zeroed when all copier first names are unique (Same_First_Name=0 → +1=1 → zeroed) |
| 42 | Same_Last_Name | Dim_Customer (copiers) | LastName | `COUNT(LastName) - COUNT(DISTINCT LastName)` |
| 43 | Same_Last_Name2 | Dim_Customer (copiers) | LastName | Same_Last_Name+1, zeroed if =1 |
| 44 | Same_City | Dim_Customer (copiers) | City | `COUNT(City) - COUNT(DISTINCT City)` |
| 45 | Same_City2 | Dim_Customer (copiers) | City | Same_City+1, zeroed if =1 |
| 46 | Same_Zip | Dim_Customer (copiers) | Zip | `COUNT(Zip) - COUNT(DISTINCT Zip)` |
| 47 | Same_Zip2 | Dim_Customer (copiers) | Zip | Same_Zip+1, zeroed if =1 |
| 48 | %TopCopier | Derived from AUC_TopCopier, AUC | — | `(AUC_TopCopier / NULLIF(AUC, 0)) * 100` — share of total AUC held by single largest copier |
| 49 | UpdateDate | — | — | `GETDATE()` at SP execution time |
| 50 | SameFID_AS_PI | Fact_BillingDeposit (PI + copier) | FundingID | `COUNT(*)-COUNT(DISTINCT pf.FundingID)` from #SameFID_AS_PI — **⚠️ CAUTION: fan-out bug: #SameFID_AS_PI grouped by (ParentCID, cf.CID) but LEFT JOINed on ParentCID only; causes ~11x row duplication per PI** |
| 51 | Same_FID_Copier | Fact_BillingDeposit (copiers) | FundingID | `COUNT(*)-COUNT(DISTINCT cf.FundingID)` per PI — inter-copier FID sharing count |
| 52 | SameDeviceID_Copiers | STS_User_Operations_Data_History | ClientDeviceId | `COUNT(*)-COUNT(DISTINCT Copy_DeviceID)` across copier devices per PI |
| 53 | SameDeviceID_Users_AS_PI | STS_User_Operations_Data_History | ClientDeviceId | `COUNT(*)-COUNT(DISTINCT PI_DeviceID)` where PI-owned devices appear in copier device history |
| 54 | CIDs_Same_Start_Copy | etoroGeneral_History_GuruCopiers | CID, StartCopy | `STRING_AGG(CID, ', ') WITHIN GROUP (ORDER BY CID)` per PI per StartCopy date, HAVING COUNT(CID)>1 — comma-delimited list of copiers who started on same calendar date |
| 55 | Equity_Start_Copy | V_Liabilities | Liabilities, ActualNWA | `ISNULL(vl.Liabilities,0)+ISNULL(vl.ActualNWA,0)` at `vl.FullDate = StartCopy` — PI's equity on the coordinated start-copy date |
| 56 | Address | Dim_Customer | Address | passthrough |
| 57 | FirstName | Dim_Customer | FirstName | passthrough |
| 58 | LastName | Dim_Customer | LastName | passthrough |
| 59 | Email | Dim_Customer | Email | passthrough |
| 60 | Phone | Dim_Customer | Phone | passthrough |
| 61 | FirstAction | BI_DB_First5Actions | FirstAction | LEFT JOIN on CID; NULL if no investigation history |
| 62 | FirstActionDate | BI_DB_First5Actions | FirstActionDate | LEFT JOIN on CID |
| 63 | SecondAction | BI_DB_First5Actions | SecondAction | LEFT JOIN on CID |
| 64 | SecondActionDate | BI_DB_First5Actions | SecondActionDate | LEFT JOIN on CID |
| 65 | ThirdAction | BI_DB_First5Actions | ThirdAction | LEFT JOIN on CID |
| 66 | ThirdActionDate | BI_DB_First5Actions | ThirdActionDate | LEFT JOIN on CID |

---

## ETL Flow

```
DWH_dbo.Fact_SnapshotCustomer (@DateID)
  + Dim_GuruStatus / Dim_Country / Dim_PlayerStatus / Dim_PlayerLevel / Dim_Regulation / Dim_Customer
    → Step 01: #pis (PI population gate: GuruStatusID≥2, IsValidCustomer=1, VL3, Depositor)

general.etoroGeneral_History_GuruCopiers (@DateTime)
  + Dim_Customer (copier identity)
    → Step 05/06: #copy (copier AUC, ranked by AUC DESC)
    → Step 04: #CopierIPs → #SameIPCopiers_Final (same-IP copier clusters)

DWH_dbo.V_Liabilities → Step 02: #Liabilities (PI equity snapshot)
DWH_dbo.Dim_Position → Step 03: #positions, #Inst (open position/instrument counts)
DWH_dbo.STS_User_Operations_Data_History → Step 07a: #PIsameDeviceID, #CopysameDeviceID → #sameDeviceID_AS_PI, #sameDeviceID_Copiers
DWH_dbo.Fact_BillingDeposit → Step 07b: #PI_FID, #Copy_FID → #SameFID_AS_PI, #SameFID_Copier
general.etoroGeneral_History_GuruCopiers → Step 07c: #StartCopy → #Susp_list (same start-date copier clusters)
  → Step 08: #TopCopier ... #Top5Copier (AUC ranked top N)
  → Step 08: #Blocked (restricted copier count)
  → Step 09: #finalpre → #final1 (fan-out JOIN) → GROUP BY CID
  → Step 10: #final2 = SELECT DISTINCT #final1 JOIN #pis (adds PII + BI_DB_First5Actions actions)
  → Step 12: TRUNCATE BI_DB_AML_PI_Abuse; INSERT FROM #final2

OpsDB: SP_AML_PI_Abuse | Priority 0 | Daily
```

*Batch 47 | Generated 2026-04-22*
