# BI_DB_dbo.BI_DB_UsersEngagement

> 490K-row rolling 2-year social engagement tracking table capturing every Post, Comment, Like, and Share action by eToro users from 2024-04-12 to present. Enriched with customer demographics (country, region, channel), trading activity flags (ActiveTrader, ActiveUser from monthly panel), and last cashout metrics. Daily DELETE+INSERT+2 UPDATEs via SP_UsersEngagement.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_Social_Activity + Dim_Customer + Dim_Country + BI_DB_CIDFirstDates + BI_DB_CID_MonthlyPanel_FullData + Fact_CustomerAction via `SP_UsersEngagement` |
| **Refresh** | Daily (DELETE+INSERT yesterday's actions + 2 UPDATEs + DELETE >2yr cleanup) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (ActionDateID ASC) + NCI(DateCreated) + NCI(RealCID) + NCI(LastCODate) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Ofir Chloe Gal (last change: 2024-01-30) |
| **Row Count** | ~489,527 (as of 2026-04-27) |

---

## 1. Business Meaning

`BI_DB_UsersEngagement` tracks social feed activity for eToro users — every post, comment, like, and share (excluding ActionTypeID=5, which is filtered out). Each row represents a single social action enriched with:

- **Customer identity**: RealCID, UserName from Dim_Customer
- **Demographics**: Country and marketing Region from Dim_Country
- **Acquisition context**: Channel (Direct, Affiliate, SEM, etc.) and Blocked status from BI_DB_CIDFirstDates
- **Trading activity**: ActiveTrader (closed ≥1 position this month) and ActiveUser (EOM equity > 0) from BI_DB_CID_MonthlyPanel_FullData
- **Cashout history**: LastCODate and LastCOAmount from Fact_CustomerAction (ActionTypeID=8)
- **Lifetime engagement**: LT_Engagement — cumulative count of distinct actions across the user's full social history

The SP loads yesterday's social actions, enriches them with demographics and trading flags, then runs two post-INSERT UPDATEs:
1. Updates LastCODate/LastCOAmount from Fact_CustomerAction (latest cashout event)
2. Updates LT_Engagement with the running count of distinct social actions

The table maintains a 2-year rolling window — rows older than 2 years from @date are deleted at the end of each run. CID 5052186 is explicitly excluded (test/internal account).

Action distribution: Like (43%), Comment (33%), Post (23%), Share (1%). TotalDeposit is hardcoded NULL since 2024-01-30 (BI_DB_User_Segment dependency was removed). LastCODate sentinel value '1990-01-01' means no cashout found (28% of rows).

---

## 2. Business Logic

### 2.1 Social Action Ingestion

**What**: Loads yesterday's social feed actions excluding a specific action type.
**Columns Involved**: `ActionID`, `ActionType`, `ActionDate`, `ActionDateID`, `MessageText`
**Rules**:
- Source: BI_DB_Social_Activity WHERE ActionDateID = @YesterdayDateID AND ActionTypeID <> 5
- ActionType resolved from BI_DB_Social_Activity_Type.ActionName via ActionTypeID JOIN
- CID 5052186 explicitly excluded (test/internal account)

### 2.2 Customer Demographics Enrichment

**What**: Adds customer profile and geographic context to each social action.
**Columns Involved**: `RealCID`, `UserName`, `Country`, `Region`
**Rules**:
- RealCID and UserName from Dim_Customer (INNER JOIN on RealCID)
- Country = Dim_Country.Name via Dim_Customer.CountryID
- Region = Dim_Country.Region (marketing region grouping)

### 2.3 Acquisition and Status Context

**What**: Adds channel, blocked status, and first deposit date from the CIDFirstDates snapshot.
**Columns Involved**: `Channel`, `Blocked`, `FirstDepositDate`
**Rules**:
- LEFT JOIN to BI_DB_CIDFirstDates on RealCID
- Channel: marketing acquisition channel (Direct, Affiliate, SEM, etc.). NULL if CID not in CIDFirstDates
- Blocked: 1 if PlayerStatusID IN (2,4,6,7,8,9), 0 otherwise. NULL if no match.

### 2.4 Monthly Trading Activity Flags

**What**: Indicates whether the user was an active trader or active user in the action's month.
**Columns Involved**: `ActiveTrader`, `ActiveUser`
**Rules**:
- LEFT JOIN to BI_DB_CID_MonthlyPanel_FullData on CID and CalendarYearMonth alignment (Dim_Date.CalendarYearMonth = CONVERT(VARCHAR(7), ActiveDate, 126))
- ActiveTrader = ISNULL(Active, 0): 1 if customer closed ≥1 position in that month
- ActiveUser = ISNULL(ActiveUser, 0): 1 if EOM equity > 0 in that month

### 2.5 Last Cashout Metrics (Post-INSERT UPDATE)

**What**: Finds the most recent cashout (ActionTypeID=8) and updates all rows for that CID.
**Columns Involved**: `LastCODate`, `LastCOAmount`
**Rules**:
- #Fact_CustomerAction_8: Fact_CustomerAction WHERE ActionTypeID=8
- LastCODate = MAX(DateID) converted to datetime via CONVERT(datetime, convert(char(8), LastCODate))
- LastCOAmount = Amount at LastCODate
- Initial values: LastCODate='1990-01-01' (sentinel), LastCOAmount=0

### 2.6 Lifetime Engagement (Post-INSERT UPDATE)

**What**: Running count of distinct social actions across the user's entire engagement history.
**Columns Involved**: `LT_Engagement`
**Rules**:
- COUNT(DISTINCT ActionID) from BI_DB_Social_Activity joined with BI_DB_UsersEngagement on RealCID
- Only actions with ActionTypeID <> 5 and ActionDateID <= @DateID
- Updated for yesterday's rows only (ActionDateID = @YesterdayDateID)

### 2.7 Rolling Window Cleanup

**What**: Maintains a 2-year rolling window by deleting old rows.
**Columns Involved**: `ActionDateID`
**Rules**:
- DELETE WHERE ActionDateID < DATEADD(YEAR, -2, @date) converted to YYYYMMDD integer

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on ActionDateID — efficient for date-range scans. Three NCIs on DateCreated, RealCID, and LastCODate for common filter patterns.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Engagement for a specific user | `WHERE RealCID = X ORDER BY ActionDate DESC` |
| Daily action counts by type | `SELECT ActionDateID, ActionType, COUNT(*) GROUP BY ActionDateID, ActionType` |
| Active traders who engage socially | `WHERE ActiveTrader = 1 GROUP BY RealCID` |
| Users who never cashed out | `WHERE LastCODate = '1990-01-01'` |
| Most engaged users | `SELECT RealCID, MAX(LT_Engagement) ... ORDER BY MAX(LT_Engagement) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_Social_Activity | `ActionID = ActionID` | Full action details |
| BI_DB_dbo.BI_DB_CIDFirstDates | `RealCID = CID` | Extended customer lifecycle dates |

### 3.4 Gotchas

- **TotalDeposit is always NULL**: Hardcoded to NULL since 2024-01-30 (BI_DB_User_Segment dependency removed). Do not use this column.
- **LastCODate sentinel**: '1990-01-01' means no cashout found — do not treat as an actual date. 28% of rows have this sentinel.
- **ActionTypeID=5 excluded**: Whatever social action type 5 is, it's filtered out. The 4 remaining types are: Post, Comment, Like, Share.
- **LT_Engagement is cumulative**: Updated across ALL rows for a CID when yesterday's engagement is loaded. Values can be very high (1,600+ distinct actions observed).
- **Rolling 2-year window**: Old data is actively deleted. Do not expect historical data beyond 2 years.
- **CID 5052186 excluded**: Hardcoded test/internal account exclusion.
- **ActiveTrader/ActiveUser are monthly**: These flags reflect the month of the social action, not the current month. A user active in January may show ActiveTrader=0 for February actions.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateCreated | date | YES | Date when this row was inserted into the engagement table. CAST(GETDATE() AS DATE) at SP execution time. (Tier 5 — ETL metadata) |
| 2 | ActionID | bigint | NO | Unique identifier for the social action from BI_DB_Social_Activity. Each post, comment, like, or share has a distinct ActionID. (Tier 2 — SP_UsersEngagement) |
| 3 | ActionType | varchar(50) | YES | Social action type name from BI_DB_Social_Activity_Type.ActionName. 4 values: Post, Comment, Like, Share (ActionTypeID=5 excluded). (Tier 2 — SP_UsersEngagement) |
| 4 | ActionDate | datetime | NO | Timestamp when the social action occurred. From BI_DB_Social_Activity.ActionDate. (Tier 2 — SP_UsersEngagement) |
| 5 | RealCID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 6 | UserName | varchar(20) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 7 | MessageText | nvarchar(max) | YES | Text content of the social action (post body, comment text). From BI_DB_Social_Activity.MessageText. NULL for Likes and Shares. (Tier 2 — SP_UsersEngagement) |
| 8 | Country | varchar(50) | NO | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 9 | Region | varchar(50) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. Passthrough from Dim_Country. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 10 | Channel | nvarchar(500) | YES | Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Dim_Channel) |
| 11 | Blocked | int | YES | Account blocked flag. CASE WHEN PlayerStatusID IN (2,4,6,7,8,9) THEN 1 ELSE 0. 2=Suspended, 4=AccountClosed, 6=BlockedByBO, 7=BlockedByRisk, 8=BlockedByPayment, 9=BlockedByCompliance. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates) |
| 12 | FirstDepositDate | datetime | YES | First successful deposit date. Read directly from Dim_Customer.FirstDepositDate, which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override logic in SP_Dim_Customer. 1900-01-01 means no deposit (sentinel). Filter with `YEAR(FirstDepositDate) != 1900`. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_Dim_Customer) |
| 13 | TotalDeposit | decimal(38,2) | YES | Deprecated — always NULL. Was from BI_DB_User_Segment (commented out 2024-01-30). Do not use. (Tier 2 — SP_UsersEngagement) |
| 14 | LT_Engagement | int | NO | Lifetime engagement count. Initially 0, then updated to COUNT(DISTINCT ActionID) across all historical social actions (ActionTypeID <> 5) for this CID. Cumulative across the full 2-year window. (Tier 2 — SP_UsersEngagement) |
| 15 | LastCODate | datetime | YES | Date of the customer's most recent cashout. MAX(DateID) from Fact_CustomerAction WHERE ActionTypeID=8, converted to datetime. Sentinel: 1990-01-01 = no cashout found. (Tier 2 — SP_UsersEngagement) |
| 16 | LastCOAmount | decimal(11,2) | YES | Amount of the customer's most recent cashout. From Fact_CustomerAction.Amount at LastCODate WHERE ActionTypeID=8. Default: 0 if no cashout. (Tier 2 — SP_UsersEngagement) |
| 17 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. Updated on INSERT and on both post-INSERT UPDATEs. (Tier 5 — ETL metadata) |
| 18 | ActiveTrader | int | YES | 1 if customer closed ≥1 position in the action's calendar month. From BI_DB_CID_MonthlyPanel_FullData.Active. ISNULL to 0. Monthly granularity — reflects the month of the social action. (Tier 2 — Fact_CustomerAction) |
| 19 | ActiveUser | int | YES | 1 if EOM_Equity > 0 in the action's calendar month (customer has any portfolio value at month end). From BI_DB_CID_MonthlyPanel_FullData.ActiveUser. ISNULL to 0. Broader than ActiveTrader. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 20 | ActionDateID | int | YES | Action date in YYYYMMDD integer format. From BI_DB_Social_Activity.ActionDateID. Clustered index key. Used for DELETE+INSERT partitioning and 2-year rolling window cleanup. (Tier 2 — SP_UsersEngagement) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateCreated | — | — | ETL-computed (GETDATE()) |
| ActionID | BI_DB_Social_Activity | ActionID | Passthrough |
| ActionType | BI_DB_Social_Activity_Type | ActionName | Rename (ActionName → ActionType) |
| ActionDate | BI_DB_Social_Activity | ActionDate | Passthrough |
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| UserName | DWH_dbo.Dim_Customer | UserName | Passthrough |
| MessageText | BI_DB_Social_Activity | MessageText | Passthrough |
| Country | DWH_dbo.Dim_Country | Name | Rename (Name → Country) |
| Region | DWH_dbo.Dim_Country | Region | Passthrough |
| Channel | BI_DB_CIDFirstDates | Channel | Passthrough |
| Blocked | BI_DB_CIDFirstDates | Blocked | Passthrough |
| FirstDepositDate | BI_DB_CIDFirstDates | FirstDepositDate | Passthrough |
| TotalDeposit | — | — | Hardcoded NULL |
| LT_Engagement | BI_DB_Social_Activity | ActionID | COUNT(DISTINCT) across history |
| LastCODate | Fact_CustomerAction | DateID | MAX WHERE ActionTypeID=8, convert to datetime |
| LastCOAmount | Fact_CustomerAction | Amount | At MAX DateID WHERE ActionTypeID=8 |
| UpdateDate | — | — | ETL-computed (GETDATE()) |
| ActiveTrader | BI_DB_CID_MonthlyPanel_FullData | Active | ISNULL(,0) |
| ActiveUser | BI_DB_CID_MonthlyPanel_FullData | ActiveUser | ISNULL(,0) |
| ActionDateID | BI_DB_Social_Activity | ActionDateID | Passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Social_Activity (social feed actions, ActionTypeID <> 5)
  + BI_DB_Social_Activity_Type (action type name lookup)
  + DWH_dbo.Dim_Customer (customer identity: RealCID, UserName)
  + DWH_dbo.Dim_Country (Country name, Region via CountryID)
  + BI_DB_CIDFirstDates (Channel, Blocked, FirstDepositDate)
  + DWH_dbo.Dim_Date (CalendarYearMonth for monthly panel alignment)
  + BI_DB_CID_MonthlyPanel_FullData (ActiveTrader, ActiveUser by month)
  |
  |-- SP_UsersEngagement @date ---|
  |-- Step 1: DELETE WHERE ActionDateID = @YesterdayDateID ---|
  |-- Step 2: INSERT (yesterday's social actions enriched) ---|
  |-- Step 3: UPDATE LastCODate/LastCOAmount from Fact_CustomerAction ---|
  |-- Step 4: UPDATE LT_Engagement = COUNT(DISTINCT ActionID) ---|
  |-- Step 5: DELETE WHERE ActionDateID < 2 years ago ---|
  v
BI_DB_dbo.BI_DB_UsersEngagement (~490K rows, rolling 2-year window)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer.RealCID | Customer identifier |
| ActionID | BI_DB_dbo.BI_DB_Social_Activity.ActionID | Source social action |
| Country | DWH_dbo.Dim_Country.Name | Country name via CountryID |
| Region | DWH_dbo.Dim_Country.Region | Marketing region |
| Channel | BI_DB_dbo.BI_DB_CIDFirstDates.Channel | Acquisition channel |

### 6.2 Referenced By (other objects point to this)

No known consumer tables or views reference this table directly.

---

## 7. Sample Queries

### 7.1 Daily Engagement by Action Type

```sql
SELECT
    ActionDateID,
    ActionType,
    COUNT(*) AS action_count,
    COUNT(DISTINCT RealCID) AS unique_users
FROM [BI_DB_dbo].[BI_DB_UsersEngagement]
WHERE ActionDateID >= 20250101
GROUP BY ActionDateID, ActionType
ORDER BY ActionDateID DESC, action_count DESC
```

### 7.2 Most Engaged Active Traders

```sql
SELECT TOP 20
    RealCID,
    UserName,
    Country,
    MAX(LT_Engagement) AS lifetime_actions,
    COUNT(*) AS recent_actions
FROM [BI_DB_dbo].[BI_DB_UsersEngagement]
WHERE ActiveTrader = 1
GROUP BY RealCID, UserName, Country
ORDER BY lifetime_actions DESC
```

### 7.3 Engagement by Region and Channel

```sql
SELECT
    Region,
    Channel,
    ActionType,
    COUNT(*) AS action_count,
    COUNT(DISTINCT RealCID) AS unique_users
FROM [BI_DB_dbo].[BI_DB_UsersEngagement]
WHERE ActionDateID >= 20250101
  AND Channel IS NOT NULL
GROUP BY Region, Channel, ActionType
ORDER BY action_count DESC
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 3 T1, 15 T2, 0 T3, 0 T4, 2 T5 | Elements: 20/20, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_UsersEngagement | Type: Table | Production Source: BI_DB_Social_Activity via SP_UsersEngagement*
