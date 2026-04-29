# BI_DB_dbo.BI_DB_PI_Affiliate

> 366.5K-row daily snapshot tracking Popular Investors (PIs) who are also affiliates — measuring their affiliate FTD acquisition, copy-trading Money In/Out split between the PI's own copy fund and other PIs' funds, and Assets Under Management. 1,322 distinct PIs across 1,862 daily snapshots from January 2021 to present. Daily DELETE+INSERT by DateID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Affiliate + Dim_Customer + Fact_CustomerAction + History_GuruCopiers via `SP_PI_Affiliate` |
| **Refresh** | Daily (DELETE+INSERT by DateID, @yesterday parameter) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Dan (2021-03-10), migrated by Tom Boksenbojm (2023-12-01) |
| **Row Count** | ~366,546 (as of 2026-04-11) |

---

## 1. Business Meaning

`BI_DB_PI_Affiliate` identifies Popular Investors (PIs) who are simultaneously running affiliate programs and tracks their affiliate-sourced customer metrics and copy-trading financials. A PI is linked to an affiliate account by matching FirstName + LastName + BirthDate between Dim_Customer (PI) and Dim_Affiliate (affiliate account). Only active PIs (GuruStatusID IN 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro) who are depositors and valid customers are included.

For each PI-affiliate, the table tracks:
- **FTD acquisition**: How many first-time depositors their affiliate links brought (yesterday, last 30 days, quarter, year, lifetime)
- **Copy-trading MIMO**: Money In/Out for customers copying THIS PI specifically vs customers copying OTHER PIs (across 4 time windows: yesterday, last 30 days, last 364 days, year-to-date)
- **AUM**: Assets Under Management split between PI's own copy fund and others' copy funds

The PI-affiliate linkage is via PII matching (FirstName + LastName + BirthDate), not via a direct FK — one PI can have multiple affiliate IDs (aggregated with STRING_AGG). The customer population attributed to each PI comes from joining CIDFirstDates.SerialID to the affiliate's AffiliateID.

ActionTypeID values used for MIMO: 15=CopyStart, 16=CopyStop, 17=CopyAdjustUp, 18=CopyAdjustDown. Amounts are negated (`-Amount`) per the SP convention.

As of latest snapshot (2026-04-11): 781 PI-affiliates. 533 Cadet (68%), 173 Champion (22%), 64 Elite (8%), 11 Elite Pro (1%).

---

## 2. Business Logic

### 2.1 PI-Affiliate Matching

**What**: PIs are linked to affiliate accounts by PII matching, not foreign key.
**Columns Involved**: `PI_RealCID`, `AffiliateID`, `UserName`
**Rules**:
- Match: Dim_Customer.FirstName = Dim_Affiliate.FirstName AND LastName AND BirthDate
- Only 'Affiliate' and 'Friend Referral' channels (from Dim_Channel via SubChannelID)
- Only activated affiliate accounts (AccountActivated=1)
- CID 11101455 is explicitly excluded (known PI to skip)
- One PI can have multiple AffiliateIDs (STRING_AGG comma-separated)

### 2.2 MIMO Split: PI vs Others

**What**: Copy-trading money flows are attributed to either the PI's own copy fund or other PIs' copy funds.
**Columns Involved**: `MoneyIn/Out/Net PI_*` and `MoneyIn/Out/Net Others_*`
**Rules**:
- Customer invests in copying someone → Fact_CustomerAction with ActionTypeID 15-18
- If ParentCID = PI_RealCID → attributed to PI's fund (MoneyIn/Out PI columns)
- If ParentCID ≠ PI_RealCID → attributed to Others' funds (MoneyIn/Out Others columns)
- ActionTypeID 15,17 = Money In (copy start, adjust up); 16,18 = Money Out (copy stop, adjust down)
- Amounts are negated: `-Amount` (because Fact_CustomerAction stores debits as positive)

### 2.3 AUM Calculation

**What**: Assets Under Management for the PI's copiers, split by whose fund they're copying.
**Columns Involved**: `AUM_in_PI`, `AUM_in_Copy_Others`, `Total_AUM`
**Rules**:
- Source: etoroGeneral_History_GuruCopiers for the current date
- AUM = Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL
- AUM_in_PI: only copiers copying THIS PI (ParentCID = PI_RealCID)
- AUM_in_Copy_Others: copiers copying OTHER PIs (ParentCID ≠ PI_RealCID)
- Total_AUM = sum of all copier equity regardless of who they copy

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID ASC — efficient for date-range filters. No hash distribution key.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PI affiliate performance on latest day | `WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_PI_Affiliate)` |
| FTD trend for a specific PI | `WHERE PI_RealCID = {cid} ORDER BY DateID` |
| Top PIs by AUM | `WHERE DateID = MAX AND Total_AUM > 0 ORDER BY Total_AUM DESC` |
| PIs with copy money going to other PIs | `WHERE NetMIOthers_LastMonth > NetMIPI_LastMonth` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `PI_RealCID = RealCID` | Full PI profile |
| DWH_dbo.Dim_GuruStatus | `GuruStatusID = GuruStatusID` | PI tier details |

### 3.4 Gotchas

- **PII matching**: PI-affiliate link is via FirstName+LastName+BirthDate, NOT a direct FK. False positives possible for common names
- **PII columns dropped**: FirstName, LastName, BirthDate were removed from the table in March 2022 for PII compliance
- **AffiliateID is comma-separated**: One PI can have multiple IDs in a single field (STRING_AGG). Do NOT use direct equality — use LIKE or STRING_SPLIT
- **MIMO amounts are negated**: `-Amount` from Fact_CustomerAction. Positive = money flowing in, Negative = money flowing out
- **Time windows are rolling**: LastMonth = last 30 days (not calendar month), LastYear = last 364 days (not calendar year), YTD = from Jan 1st
- **CID 11101455 excluded**: Hard-coded exclusion in the SP
- **Only active PI tiers**: GuruStatusID IN (2,3,4,5,6) — excludes No (0), Certified (1), Removed (7), Rejected (8)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Snapshot date (@yesterday parameter). (Tier 2 — SP_PI_Affiliate) |
| 2 | DateID | int | YES | Integer date key (YYYYMMDD format) for the snapshot. Partition key for DELETE+INSERT. (Tier 2 — SP_PI_Affiliate) |
| 3 | UserName | varchar(20) | YES | Customer login username. Unique (case-insensitive). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | GuruStatusID | smallint | YES | PI program state ID. Values in this table: 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro. Passthrough from Dim_Customer. (Tier 1 — Dictionary.GuruStatus) |
| 5 | PITier | varchar(50) | NO | Human-readable PI tier name. Values: Cadet, Rising Star, Champion, Elite, Elite Pro. From Dim_GuruStatus.GuruStatusName. (Tier 1 — Dictionary.GuruStatus) |
| 6 | Manager | varchar(101) | YES | Account manager full name (FirstName + ' ' + LastName from Dim_Manager). (Tier 2 — SP_PI_Affiliate, Dim_Manager) |
| 7 | PI_RealCID | int | NO | CID of the Popular Investor. Primary key equivalent for the daily snapshot. (Tier 1 — Customer.CustomerStatic) |
| 8 | AffiliateID | nvarchar(max) | YES | Comma-separated list of affiliate IDs linked to this PI (STRING_AGG). One PI can have multiple affiliate accounts. (Tier 2 — SP_PI_Affiliate, Dim_Affiliate) |
| 9 | Aff_Channel | nvarchar(max) | YES | Comma-separated list of affiliate channel names ('Affiliate', 'Friend Referral'). From Dim_Channel. (Tier 2 — SP_PI_Affiliate, Dim_Channel) |
| 10 | Aff_WebSiteURL | nvarchar(max) | YES | Comma-separated list of affiliate website URLs. From Dim_Affiliate.WebSiteURL. (Tier 2 — SP_PI_Affiliate, Dim_Affiliate) |
| 11 | FTDYesterday | int | YES | First-time depositors attributed to this PI's affiliate links on the snapshot date. SUM across all affiliated accounts. (Tier 2 — SP_PI_Affiliate, Dim_Affiliate) |
| 12 | FTDLastMonth | int | YES | FTDs in the last 30 days. SUM across all affiliated accounts. (Tier 2 — SP_PI_Affiliate, Dim_Affiliate) |
| 13 | FTDLastQuarter | int | YES | FTDs in the last quarter. SUM across all affiliated accounts. (Tier 2 — SP_PI_Affiliate, Dim_Affiliate) |
| 14 | FTDLastYear | int | YES | FTDs in the last 364 days. SUM across all affiliated accounts. (Tier 2 — SP_PI_Affiliate, Dim_Affiliate) |
| 15 | FTDLifeTime | int | YES | Lifetime FTDs across all affiliated accounts. SUM from Dim_Affiliate.FTDLifeTime. (Tier 2 — SP_PI_Affiliate, Dim_Affiliate) |
| 16 | MoneyInPI_Yesterday | decimal(38,2) | NO | Copy money invested INTO this PI's fund on the snapshot date. SUM(-Amount) for ActionTypeID 15,17 WHERE ParentCID=PI. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 17 | MoneyOutPI_Yesterday | decimal(38,2) | NO | Copy money withdrawn FROM this PI's fund on the snapshot date. SUM(-Amount) for ActionTypeID 16,18 WHERE ParentCID=PI. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 18 | NetMIPI_Yesterday | decimal(38,2) | NO | Net money in/out for this PI's fund on the snapshot date. SUM(-Amount) for all copy actions WHERE ParentCID=PI. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 19 | MoneyInOthers_Yesterday | decimal(38,2) | NO | Copy money invested into OTHER PIs' funds by this PI's affiliate customers on the snapshot date. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 20 | NetMIOthers_Yesterday | decimal(38,2) | NO | Net money in/out for other PIs' funds from this PI's affiliate customers on the snapshot date. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 21 | MoneyOutOthers_Yesterday | decimal(38,2) | NO | Copy money withdrawn from OTHER PIs' funds by this PI's affiliate customers on the snapshot date. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 22 | MoneyInPI_LastMonth | decimal(38,2) | NO | Copy money invested INTO this PI's fund in the last 30 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 23 | MoneyOutPI_LastMonth | decimal(38,2) | NO | Copy money withdrawn FROM this PI's fund in the last 30 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 24 | NetMIPI_LastMonth | decimal(38,2) | NO | Net money in/out for this PI's fund in the last 30 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 25 | MoneyInOthers_LastMonth | decimal(38,2) | NO | Copy money invested into OTHER PIs' funds in the last 30 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 26 | MoneyOutOthers_LastMonth | decimal(38,2) | NO | Copy money withdrawn from OTHER PIs' funds in the last 30 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 27 | NetMIOthers_LastMonth | decimal(38,2) | NO | Net money in/out for other PIs' funds in the last 30 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 28 | MoneyInPI_LastYear | decimal(38,2) | NO | Copy money invested INTO this PI's fund in the last 364 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 29 | MoneyOutPI_LastYear | decimal(38,2) | NO | Copy money withdrawn FROM this PI's fund in the last 364 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 30 | NetMIPI_LastYear | decimal(38,2) | NO | Net money in/out for this PI's fund in the last 364 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 31 | MoneyInOthers_LastYear | decimal(38,2) | NO | Copy money invested into OTHER PIs' funds in the last 364 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 32 | MoneyOutOthers_LastYear | decimal(38,2) | NO | Copy money withdrawn from OTHER PIs' funds in the last 364 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 33 | NetMIOthers_LastYear | decimal(38,2) | NO | Net money in/out for other PIs' funds in the last 364 days. Default 0. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 34 | AUM_in_PI | money | NO | Assets Under Management in this PI's copy fund. SUM(Cash+Investment+PnL+DetachedPos+Dit_PnL) WHERE ParentCID=PI from History_GuruCopiers. Default 0. (Tier 2 — SP_PI_Affiliate, History_GuruCopiers) |
| 35 | AUM_in_Copy_Others | money | NO | AUM in OTHER PIs' copy funds from this PI's affiliate customers. Default 0. (Tier 2 — SP_PI_Affiliate, History_GuruCopiers) |
| 36 | Total_AUM | money | NO | Total AUM across all copy funds from this PI's affiliate customers. AUM_in_PI + AUM_in_Copy_Others. Default 0. (Tier 2 — SP_PI_Affiliate, History_GuruCopiers) |
| 37 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 2 — SP_PI_Affiliate) |
| 38 | MoneyInPI_YTD | decimal(38,2) | YES | Copy money invested INTO this PI's fund year-to-date (from Jan 1). (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 39 | MoneyOutPI_YTD | decimal(38,2) | YES | Copy money withdrawn FROM this PI's fund year-to-date. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 40 | NetMIPI_YTD | decimal(38,2) | YES | Net money in/out for this PI's fund year-to-date. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 41 | MoneyInOthers_YTD | decimal(38,2) | YES | Copy money invested into OTHER PIs' funds year-to-date. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 42 | MoneyOutOthers_YTD | decimal(38,2) | YES | Copy money withdrawn from OTHER PIs' funds year-to-date. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |
| 43 | NetMIOthers_YTD | decimal(38,2) | YES | Net money in/out for other PIs' funds year-to-date. (Tier 2 — SP_PI_Affiliate, Fact_CustomerAction) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| UserName | Customer.CustomerStatic | UserName | passthrough via Dim_Customer |
| GuruStatusID | Dictionary.GuruStatus | GuruStatusID | passthrough via Dim_Customer |
| PITier | Dictionary.GuruStatus | GuruStatusName | dim-lookup via Dim_GuruStatus |
| PI_RealCID | Customer.CustomerStatic | CID | passthrough via Dim_Customer |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (PIs: GuruStatusID IN 2-6, depositor, valid)
  + DWH_dbo.Dim_Affiliate (active affiliate accounts, Channel='Affiliate'/'Friend Referral')
  |-- PII match: FirstName + LastName + BirthDate → PI-Affiliate linkage
  |
  + DWH_dbo.Fact_CustomerAction (ActionTypeID 15-18, copy MIMO, last year)
  + DWH_dbo.Dim_Mirror (ParentCID for PI vs Others attribution)
  + general.etoroGeneral_History_GuruCopiers (AUM components)
  + BI_DB_dbo.BI_DB_CIDFirstDates (SerialID → AffiliateID customer linkage)
  + DWH_dbo.Dim_Manager (account manager name)
  + DWH_dbo.Dim_GuruStatus (PITier name)
  |
  |-- SP_PI_Affiliate @yesterday (daily DELETE+INSERT by DateID)
  |   Step 1: Find affiliate accounts (Dim_Affiliate + Dim_Channel)
  |   Step 2: Find active PIs (Dim_Customer + Dim_Manager)
  |   Step 3: Match PIs to affiliates by PII
  |   Step 4: Aggregate FTDs from Dim_Affiliate
  |   Step 5: Build customer population (CIDFirstDates.SerialID → AffiliateID)
  |   Step 6: Compute MIMO for 4 time windows (Yesterday/Month/Year/YTD) × PI/Others
  |   Step 7: Compute AUM from History_GuruCopiers × PI/Others
  |   Step 8: DELETE current date + INSERT
  v
BI_DB_dbo.BI_DB_PI_Affiliate (366.5K rows, ROUND_ROBIN CI(DateID))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PI_RealCID | DWH_dbo.Dim_Customer (RealCID) | PI's customer record |
| GuruStatusID, PITier | DWH_dbo.Dim_GuruStatus | PI tier classification |
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate account(s) |
| Manager | DWH_dbo.Dim_Manager | Account manager |
| FTD* | DWH_dbo.Dim_Affiliate | FTD acquisition counts |
| MIMO columns | DWH_dbo.Fact_CustomerAction | Copy-trading money flows |
| AUM columns | general.etoroGeneral_History_GuruCopiers | Assets under management |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Top PI-Affiliates by AUM (Latest Day)

```sql
SELECT PI_RealCID, UserName, PITier, Total_AUM, AUM_in_PI, AUM_in_Copy_Others, FTDLifeTime
FROM BI_DB_dbo.BI_DB_PI_Affiliate
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_PI_Affiliate)
  AND Total_AUM > 0
ORDER BY Total_AUM DESC
```

### 7.2 PI Net Money Flow Trend (Last 30 Days)

```sql
SELECT DateID, PI_RealCID, UserName, NetMIPI_Yesterday, NetMIOthers_Yesterday
FROM BI_DB_dbo.BI_DB_PI_Affiliate
WHERE PI_RealCID = {target_cid}
  AND DateID >= CAST(CONVERT(CHAR(8), DATEADD(DAY, -30, GETDATE()), 112) AS INT)
ORDER BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 5 T1, 38 T2, 0 T3, 0 T4, 0 T5 | Elements: 43/43, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_PI_Affiliate | Type: Table | Production Source: Dim_Affiliate + Dim_Customer + Fact_CustomerAction via SP_PI_Affiliate*
