# BI_DB_dbo.BI_DB_Blocked_Customers

> 234,804-row pre-aggregated compliance snapshot of all customers with non-Normal player status (PlayerStatus ≠ 1) across 8 restricted status types and 14 regulations — 1,322,715 customers as of 2026-04-13. Groups customer attributes (regulation, country, club, account type, player status, verification level, etc.) into segment combinations with summed financial positions and a headcount. Loaded daily via TRUNCATE+INSERT by SP_Blocked_Customers sourcing from Dim_Customer + V_Liabilities.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (WHERE PlayerStatusID <> 1) + V_Liabilities + BI_DB_CIDFirstDates → SP_Blocked_Customers |
| **Refresh** | Daily (SB_Daily, Priority 20) — TRUNCATE + INSERT (full snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not exported to Unity Catalog |

---

## 1. Business Meaning

`BI_DB_Blocked_Customers` is a pre-aggregated compliance and risk analytics table capturing all customers with any non-Normal player status (PlayerStatusID ≠ 1). It holds 234,804 distinct customer segments with 1,322,715 total blocked/restricted customers as of 2026-04-13. Despite the "Blocked" name, the table covers 8 distinct player statuses: Blocked (649K), Blocked Upon Request (370K), Pending Verification (230K), Block Deposit & Trading (40K), Trade & MIMO Blocked (20K), Deposit Blocked (7K), Warning (6K), and Copy Block (0.6K).

Each row represents a unique combination of 25 customer attributes (regulation, country, club, account type, player status, player status reason, sub-reason, verification level, etc.) with summed financial metrics (UnRealizedEquity, RealizedEquity, Credit, TotalPositionsAmount, TotalPositionPnL) and a headcount (TotalCustomers). This design supports pivot-style reporting across any combination of dimensions without querying individual customer rows.

SP_Blocked_Customers runs daily and:
1. Computes financial positions via a temp table from `DWH_dbo.V_Liabilities` (Liabilities + ActualNWA = UnRealizedEquity)
2. Buckets LastLoggedIn age from `BI_DB_CIDFirstDates` (0-7, 8-15, 16-30, 31-60, 61+ days, N/A)
3. Joins Dim_Customer (WHERE PlayerStatusID ≠ 1) with 10+ dimension tables for name resolution
4. Groups by 25 dimension keys and aggregates financial metrics

CySEC (61%) and FCA (15%) dominate by customer count. Bronze tier accounts for 97% of restricted customers. Top restriction reasons: AML (28%), KYC (27%), and CloseAccountByUser (26%).

---

## 2. Business Logic

### 2.1 Population Filter — Non-Normal Customers Only

**What**: The SP filters `WHERE dc.PlayerStatusID <> 1` — only customers with a status other than Active/Normal (PlayerStatusID=1) are included.

**Columns Involved**: PlayerStatusID, PlayerStatus

**Rules**:
- PlayerStatusID=1 (Active/Normal) is EXCLUDED — these are working accounts
- All 8 non-normal statuses included: Blocked(2), Blocked Upon Request(4), Warning(5), Trade & MIMO Blocked(9), Deposit Blocked(10), Copy Block(12), Pending Verification(13), Block Deposit & Trading(15)
- The table name "Blocked_Customers" is broader than the "Blocked" status alone — it covers the full non-normal population

### 2.2 Segmentation and Aggregation

**What**: Each row is a unique combination of 25 GROUP BY dimensions with summed financials and a headcount.

**Columns Involved**: All 25 group-key columns + TotalCustomers + financial metrics

**Rules**:
- `TotalCustomers` = COUNT(DISTINCT RealCID) per segment — headcount within the combination
- Financial columns (UnRealizedEquity, RealizedEquity, Credit, TotalPositionsAmount, TotalPositionPnL) = SUM per segment; customers with no V_Liabilities row (not INNER JOINed) are excluded from the population
- `IsOpenPosition` = CASE WHEN TotalPositionsAmount <> 0 THEN 1 ELSE 0 END — reflects whether the SEGMENT has net non-zero positions; 0 when all customers in the segment have zero position amount

### 2.3 Financial Metrics Source (V_Liabilities)

**What**: Financial metrics come from `DWH_dbo.V_Liabilities` filtered to the run date. The INNER JOIN means customers without a V_Liabilities row are silently excluded.

**Columns Involved**: UnRealizedEquity, RealizedEquity, Credit, TotalPositionsAmount, TotalPositionPnL

**Rules**:
- `UnRealizedEquity` = V_Liabilities.Liabilities + V_Liabilities.ActualNWA (confusingly named — represents total position value including net worth adjustment)
- INNER JOIN to V_Liabilities — customers with no record for the run date are excluded from all financial columns and from TotalCustomers. This can cause undercounting if V_Liabilities doesn't cover all accounts for a given day
- Financial values are SUM aggregates — not per-customer amounts

### 2.4 LastLoggedIn Aging Buckets

**What**: Customers are bucketed by days-since-last-login for recency analysis.

**Columns Involved**: LastLoggedIn_Group

**Rules**:
- 0-7: Logged in within 1 week
- 8-15: 8-15 days ago
- 16-30: 16-30 days ago (within a month)
- 31-60: 31-60 days ago (1-2 months)
- 61+: More than 2 months ago (majority of blocked customers — 'set and forget' blocks)
- N/A: No LastLoggedIn record in BI_DB_CIDFirstDates (LEFT JOIN — customer never logged in or record missing)
- Calculated relative to GETDATE()-1 at SP run time — each daily run shifts all buckets by one day

### 2.5 PlayerStatusSubReason Handling

**What**: Sub-reason is optional (LEFT JOIN to Dim_PlayerStatusSubReasons). NULL values are replaced to ensure clean GROUP BY.

**Columns Involved**: PlayerStatusSubReasonID, PlayerStatusSubReasonName

**Rules**:
- `PlayerStatusSubReasonID`: ISNULL(..., 0) — 0 indicates "no sub-reason assigned"
- `PlayerStatusSubReasonName`: ISNULL(..., 'None') — 'None' string means no sub-reason
- HRC (High Risk Customer), Cross Border, Failed Verification are common sub-reasons from sample data

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with 234,804 rows. Moderate size — broadcast-friendly for JOINs. No clustering. Full scan is fast. Filter by PlayerStatusID, Regulation, or Country for dimension-level analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count of Blocked customers by regulation | GROUP BY RegulationID, Regulation, SUM(TotalCustomers) WHERE PlayerStatusID=2 |
| AML-blocked customers by country | WHERE PlayerStatusReasonID=10, GROUP BY CountryID, Country, SUM(TotalCustomers) |
| Total exposed equity for pending verification accounts | WHERE PlayerStatusID=13, SUM(UnRealizedEquity) |
| Compliance dashboard KPIs | SUM(TotalCustomers) filtered by PlayerStatusID IN (2,4,9,10,12,15) |
| Blocked customer recency | GROUP BY LastLoggedIn_Group, SUM(TotalCustomers) to see how recently blocked customers were active |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | If individual-level detail needed (bypass this table) |
| DWH_dbo.Dim_Regulation | RegulationID = DWHRegulationID | Regulation name already denormalized in this table |

### 3.4 Gotchas

- **Name is misleading**: Table contains ALL non-Normal statuses, not just PlayerStatusID=2 (Blocked). Use PlayerStatusID to filter for specific status types
- **INNER JOIN to V_Liabilities excludes some customers**: Customers without a daily V_Liabilities record are absent from TotalCustomers count. Total may undercount on dates where V_Liabilities has gaps
- **IsOpenPosition is segment-level**: A row with IsOpenPosition=0 means the aggregated TotalPositionsAmount for that segment is zero, not that every individual in the segment has zero positions
- **PlayerStatusSubReasonID=0 means NULL**: The SP replaces NULL with 0. Use PlayerStatusSubReasonName='None' for "no sub-reason" filter, not NULL checks
- **Regulation JOIN uses DWHRegulationID**: `Dim_Regulation.DWHRegulationID` is the join key, not `Dim_Regulation.RegulationID`. If JOINing manually, be aware of this non-obvious key
- **UnRealizedEquity ≠ unrealized PnL**: UnRealizedEquity = Liabilities + ActualNWA — a combined position metric, not just price-based unrealized profit/loss. Use TotalPositionPnL for P&L analysis

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (DWH_dbo.Dim_Customer wiki) |
| Tier 2 | Derived from SP code, DDL, or DWH join logic |
| Tier 3 | Inferred from column name, data patterns, or business context |
| Tier 4 | Best available — limited confidence, needs review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RegulationID | tinyint | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 2 | Regulation | varchar(50) | NO | Resolved regulation name from Dim_Regulation.Name. Values: CySEC (61%), FCA (15%), ASIC & GAML (8%), BVI (5%), FinCEN+FINRA (3%), FSA Seychelles (3%), ASIC (3%), others. (Tier 2 — SP_Blocked_Customers) |
| 3 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | Country | varchar(50) | NO | Resolved country name from Dim_Country.Name. NOT NULL constraint in DDL. (Tier 2 — SP_Blocked_Customers) |
| 5 | Club | varchar(50) | NO | Customer loyalty tier resolved from Dim_PlayerLevel. Values: Bronze (97%), Silver (1.2%), Gold (1.0%), Platinum (0.4%), Internal (0.3%), Platinum Plus (0.3%), Diamond (0.05%). NOT NULL constraint. (Tier 2 — SP_Blocked_Customers) |
| 6 | AccountStatusID | int | YES | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 7 | AccountStatusName | varchar(50) | YES | Resolved account status name from Dim_AccountStatus. (Tier 2 — SP_Blocked_Customers) |
| 8 | AccountTypeID | int | NO | Customer account classification. Default=1 (real retail account). NOT NULL constraint. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 9 | AccountType | varchar(50) | YES | Resolved account type name from Dim_AccountType. (Tier 2 — SP_Blocked_Customers) |
| 10 | MifidCategorizationID | int | YES | MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail, 4=Retail Pending, 5=Pending. Default=1. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 11 | MifidCategorizationName | varchar(50) | NO | Resolved MiFID categorization name from Dim_MifidCategorization. NOT NULL constraint. (Tier 2 — SP_Blocked_Customers) |
| 12 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Normal; other values indicate restricted, closed, banned, or special states. Default=0. This table contains ONLY PlayerStatusID <> 1. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 13 | PlayerStatus | varchar(50) | NO | Resolved player status name from Dim_PlayerStatus. Values: Blocked (649K), Blocked Upon Request (370K), Pending Verification (230K), Block Deposit & Trading (40K), Trade & MIMO Blocked (20K), Deposit Blocked (7K), Warning (6K), Copy Block (0.6K). NOT NULL. (Tier 2 — SP_Blocked_Customers) |
| 14 | PlayerStatusReasonID | int | YES | Reason code for current PlayerStatusID. Provides the why behind a non-Active status. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 15 | PlayerStatusReason | varchar(50) | YES | Resolved reason name from Dim_PlayerStatusReasons. Top values: AML (28%), KYC (27%), CloseAccountByUser (26%), Account Closed (9%), Other (3%). (Tier 2 — SP_Blocked_Customers) |
| 16 | PlayerStatusSubReasonID | int | NO | Sub-reason code for PlayerStatus (hierarchical). FK to Dictionary.PlayerStatusSubReasons. Added 2022 (COINF-1989). DWH note: ISNULL applied — 0 replaces NULL (no sub-reason assigned). NOT NULL. Passthrough from Dim_Customer with ISNULL transform. (Tier 1 — Customer.CustomerStatic) |
| 17 | PlayerStatusSubReasonName | varchar(50) | NO | Resolved sub-reason name from Dim_PlayerStatusSubReasons (LEFT JOIN). ISNULL applied: 'None' when no sub-reason. Sample values: HRC, Cross Border, Failed Verification - 15 Days. NOT NULL. (Tier 2 — SP_Blocked_Customers) |
| 18 | RiskGroupID | int | YES | Customer country risk group from Dim_Country. Used for AML risk stratification. (Tier 2 — DWH_dbo.Dim_Country) |
| 19 | EU | int | YES | Whether the customer's country is in the EU. From Dim_Country. 0=No, 1=Yes. (Tier 2 — DWH_dbo.Dim_Country) |
| 20 | IsEuropeanCountry | int | YES | Whether the customer's country is a European country (broader than EU). From Dim_Country. 0=No, 1=Yes. (Tier 2 — DWH_dbo.Dim_Country) |
| 21 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. Passthrough from Dim_Customer. (Tier 1 — BackOffice.Customer) |
| 22 | IsValidCustomer | int | YES | DWH-computed flag: 1 when not Internal (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Passthrough from Dim_Customer (Tier 2 origin in Dim_Customer). (Tier 2 — SP_Dim_Customer via Dim_Customer) |
| 23 | IsDepositor | bit | YES | Whether the customer has ever deposited. DEFAULT=0. Updated post-load from FTD data. Passthrough from Dim_Customer (Tier 2 origin in Dim_Customer). (Tier 2 — SP_Dim_Customer via Dim_Customer) |
| 24 | CurrAge | int | YES | Customer age in years at SP run time, computed as DATEDIFF(YEAR, BirthDate, GETDATE()-1). Refreshed daily — ages increment annually. Sample from data: range 36-73+ in sample rows. (Tier 2 — SP_Blocked_Customers) |
| 25 | LastLoggedIn_Group | varchar(5) | YES | Days-since-last-login aging bucket from BI_DB_CIDFirstDates. Values: '0-7', '8-15', '16-30', '31-60', '61+', 'N/A' (no login record or LEFT JOIN miss). Computed relative to GETDATE()-1 at run time. (Tier 2 — SP_Blocked_Customers) |
| 26 | IsOpenPosition | int | NO | Segment-level open position flag. CASE WHEN SUM(TotalPositionsAmount) <> 0 THEN 1 ELSE 0 END. 1 = at least one customer in the segment has open positions (non-zero total position amount). NOT NULL. (Tier 2 — SP_Blocked_Customers) |
| 27 | UnRealizedEquity | decimal(38,4) | YES | Sum of (V_Liabilities.Liabilities + V_Liabilities.ActualNWA) for all customers in the segment. Despite the name, equals total position value plus net worth adjustment — not a standard unrealized PnL metric. (Tier 2 — DWH_dbo.V_Liabilities) |
| 28 | RealizedEquity | money | YES | Sum of V_Liabilities.RealizedEquity for all customers in the segment. Represents realized cash equity across the segment. (Tier 2 — DWH_dbo.V_Liabilities) |
| 29 | Credit | money | YES | Sum of V_Liabilities.Credit for all customers in the segment. Credit balances granted to customers within this segment. (Tier 2 — DWH_dbo.V_Liabilities) |
| 30 | TotalPositionsAmount | money | YES | Sum of V_Liabilities.TotalPositionsAmount for all customers in the segment. Total notional value of open positions. (Tier 2 — DWH_dbo.V_Liabilities) |
| 31 | TotalPositionPnL | decimal(38,2) | YES | Sum of V_Liabilities.PositionPnL for all customers in the segment. Aggregate unrealized profit/loss on open positions. (Tier 2 — DWH_dbo.V_Liabilities) |
| 32 | TotalCustomers | int | YES | COUNT(DISTINCT RealCID) — headcount of customers in this segment combination. Customers excluded from V_Liabilities INNER JOIN are not counted. (Tier 2 — SP_Blocked_Customers) |

Note: UpdateDate is NOT in the DDL column list. The SP inserts it (GETDATE()) but the DDL defines it as column 33 — included in INSERT but implicit. Checking DDL: `UpdateDate [datetime] NOT NULL` is present. Apologies — it IS in the DDL. Adding:

| 33 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by SP_Blocked_Customers (GETDATE() at SP execution time). All rows share the same UpdateDate (TRUNCATE+INSERT). Last value: 2026-04-13. NOT NULL. (Tier 2 — SP_Blocked_Customers) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| RegulationID | BackOffice.Customer via DWH_dbo.Dim_Customer | RegulationID | Passthrough GROUP BY key |
| CountryID | Customer.CustomerStatic via DWH_dbo.Dim_Customer | CountryID | Passthrough GROUP BY key |
| AccountStatusID | Customer.CustomerStatic via DWH_dbo.Dim_Customer | AccountStatusID | Passthrough GROUP BY key |
| AccountTypeID | BackOffice.Customer via DWH_dbo.Dim_Customer | AccountTypeID | Passthrough GROUP BY key |
| MifidCategorizationID | BackOffice.Customer via DWH_dbo.Dim_Customer | MifidCategorizationID | Passthrough GROUP BY key |
| PlayerStatusID | Customer.CustomerStatic via DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough, filter: <> 1 |
| PlayerStatusReasonID | Customer.CustomerStatic via DWH_dbo.Dim_Customer | PlayerStatusReasonID | Passthrough GROUP BY key |
| PlayerStatusSubReasonID | Customer.CustomerStatic via DWH_dbo.Dim_Customer | PlayerStatusSubReasonID | ISNULL(..., 0) |
| VerificationLevelID | BackOffice.Customer via DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough GROUP BY key |
| Financial columns (5) | DWH_dbo.V_Liabilities (@DateID) | Liabilities, ActualNWA, RealizedEquity, Credit, TotalPositionsAmount, PositionPnL | SUM per segment |
| TotalCustomers | DWH_dbo.Dim_Customer | RealCID | COUNT(DISTINCT) per segment |
| LastLoggedIn_Group | BI_DB_dbo.BI_DB_CIDFirstDates | LastLoggedIn | DATEDIFF age bucket |
| CurrAge | Customer.CustomerStatic via Dim_Customer | BirthDate | DATEDIFF(YEAR, ..., GETDATE()-1) |

### 5.2 ETL Pipeline

```
Customer.CustomerStatic + BackOffice.Customer (production OLTP)
  |-- Generic Pipeline → DWH_staging ---|
  |-- SP_Dim_Customer → DWH_dbo.Dim_Customer ---|
                                          |
DWH_dbo.V_Liabilities (@DateID)          | 
BI_DB_dbo.BI_DB_CIDFirstDates            |
DWH_dbo.Dim_* (10 dimension tables)      |
  |------ SP_Blocked_Customers @Date ----|
     TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_Blocked_Customers (234,804 segment rows; 1,322,715 customers)
  |-- NOT exported to Unity Catalog (_Not_Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RegulationID | DWH_dbo.Dim_Regulation.DWHRegulationID | JOIN key for regulation name |
| CountryID | DWH_dbo.Dim_Country.CountryID | JOIN key for country name, EU, RiskGroupID |
| AccountStatusID | DWH_dbo.Dim_AccountStatus.AccountStatusID | JOIN key for status name |
| AccountTypeID | DWH_dbo.Dim_AccountType.AccountTypeID | JOIN key for type name |
| MifidCategorizationID | DWH_dbo.Dim_MifidCategorization.MifidCategorizationID | JOIN key for MiFID category name |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus.PlayerStatusID | JOIN key for status name |
| PlayerStatusReasonID | DWH_dbo.Dim_PlayerStatusReasons.PlayerStatusReasonID | JOIN key for reason name |
| PlayerStatusSubReasonID | DWH_dbo.Dim_PlayerStatusSubReasons.PlayerStatusSubReasonID | LEFT JOIN key for sub-reason name |
| (source) | DWH_dbo.Dim_Customer | Primary population source |
| (source) | DWH_dbo.V_Liabilities | Financial metrics source |
| (source) | BI_DB_dbo.BI_DB_CIDFirstDates | LastLoggedIn source |

### 6.2 Referenced By

No known downstream tables directly reference BI_DB_Blocked_Customers. It is consumed by Power BI compliance and CS dashboards.

---

## 7. Sample Queries

### Blocked Customer Count by Regulation and Status

```sql
SELECT 
    Regulation,
    PlayerStatus,
    SUM(TotalCustomers) AS total_customers,
    SUM(TotalPositionPnL) AS total_pnl,
    SUM(UnRealizedEquity) AS total_unrealized_equity
FROM [BI_DB_dbo].[BI_DB_Blocked_Customers]
GROUP BY Regulation, PlayerStatus
ORDER BY total_customers DESC
```

### AML-Blocked Customers by Country and Club

```sql
SELECT 
    Country,
    Club,
    PlayerStatusSubReasonName,
    SUM(TotalCustomers) AS customers,
    SUM(CASE WHEN IsDepositor=1 THEN TotalCustomers ELSE 0 END) AS depositor_customers
FROM [BI_DB_dbo].[BI_DB_Blocked_Customers]
WHERE PlayerStatusReasonID = 10  -- AML
  AND PlayerStatusID = 2         -- Blocked
GROUP BY Country, Club, PlayerStatusSubReasonName
ORDER BY customers DESC
```

### Pending Verification Customers by Verification Level and Last Login

```sql
SELECT 
    VerificationLevelID,
    LastLoggedIn_Group,
    SUM(TotalCustomers) AS pending_customers
FROM [BI_DB_dbo].[BI_DB_Blocked_Customers]
WHERE PlayerStatusID = 13  -- Pending Verification
GROUP BY VerificationLevelID, LastLoggedIn_Group
ORDER BY VerificationLevelID, LastLoggedIn_Group
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. Related compliance monitoring context may be found in the Confluence "Business & Regulatory Undertakings Monitoring Platform" page which uses Dim_Customer for similar filtering.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 9 T1, 24 T2, 0 T3, 0 T4 | Elements: 33/32 (UpdateDate found in DDL review — added), Logic: 9/10, ETL: confirmed, Data Evidence: live*
*Object: BI_DB_dbo.BI_DB_Blocked_Customers | Type: Table | Production Source: DWH_dbo.Dim_Customer (PlayerStatusID <> 1)*
