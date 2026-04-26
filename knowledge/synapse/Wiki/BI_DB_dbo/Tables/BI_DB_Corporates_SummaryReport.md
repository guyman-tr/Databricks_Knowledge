# BI_DB_dbo.BI_DB_Corporates_SummaryReport

> 4,636-row daily snapshot of eToro corporate and SMSF account holders (AccountTypeID 2=Corporate, 14=SMSF), capturing current player status, club level, country, financial balance, total equity, and cumulative approved deposits. Built daily via SP_CorporatesSummaryReport (TRUNCATE+INSERT), covering account approvals from 2011-10-20 to 2026-04-12. Used for corporate client reporting and management dashboards.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (AccountTypeID IN 2,14) + DWH_dbo.Dim_Customer + DWH_dbo.V_Liabilities + BI_DB_dbo.BI_DB_AllDeposits via SP_CorporatesSummaryReport |
| **Refresh** | Daily (SP_CorporatesSummaryReport, TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Corporates_SummaryReport is a daily-refreshed snapshot of every eToro corporate and SMSF account holder visible in Fact_SnapshotCustomer (AccountTypeID IN 2=Corporate, 14=SMSF, with IsValidCustomer=1 filter applied on Dim_Customer). Each row represents one customer account — 4,636 total as of 2026-04-13 — with their earliest "approval date" (the first date their corporate/SMSF snapshot appeared in Dim_Range → Dim_Date), current player status, club tier, geographic segment, and financial position as of yesterday (@EndDateID = CONVERT(date, GETDATE()-1)).

The table serves as the primary source for corporate client management and compliance monitoring. Key financial metrics include `Balance` (V_Liabilities.Credit — actual credit balance as of yesterday) and `TotalEquity` (V_Liabilities.Liabilities + ActualNWA — combined liabilities and net worth). `TotalDeposits` aggregates all approved payments from BI_DB_AllDeposits (cumulative, not snapshot-date-bounded). 

The `AccountType` column reflects the **current** account type from Dim_AccountType — it may differ from the original population filter (IN 2,14) for accounts that subsequently changed type. The distribution shows 4,181 Corporate (~90%), 398 SMSF (~9%), plus rare edge cases (Private=31, Fund=8, Trust=3, etc.). The UK region dominates geographically (2,488 accounts, ~54%), followed by Australia (487, ~11%) and France (326, ~7%).

TRUNCATE+INSERT runs daily via SB_Daily (Service Broker orchestrator). No incremental merge — the entire table is rebuilt each day.

---

## 2. Business Logic

### 2.1 Corporate Population Filter

**What**: The SP identifies "corporate" customers based on historical Fact_SnapshotCustomer records.

**Columns Involved**: `GCID`, `RealCID`, `ApprovedDateTime`

**Rules**:
- Population = customers with ANY Fact_SnapshotCustomer row where AccountTypeID IN (2, 14)
- 2=Corporate: registered business entities with enhanced KYC and reporting requirements
- 14=SMSF: Self-Managed Super Funds (Australian retirement vehicles)
- `ApprovedDateTime` = MIN(Dim_Date.FullDate) for the first such snapshot — proxy for account approval date, derived through Dim_Range → Dim_Date chain (not a direct production timestamp)
- Earliest approval: 2011-10-20 (legacy accounts); latest: 2026-04-12

### 2.2 AccountType Current vs. Historical Mismatch

**What**: Current AccountType is joined from Dim_Customer, which may have changed since the historical corporate snapshot.

**Columns Involved**: `AccountType`

**Rules**:
- Population selected via Fact_SnapshotCustomer AccountTypeID IN (2,14) (historical)
- AccountType displayed = Dim_AccountType.Name via Dim_Customer.AccountTypeID (current)
- 57 rows (~1.2%) show non-Corporate/SMSF current types: Private=31, Affiliate Corporate Account=13, Fund=8, Trust=3, Affiliate Private Account=1, Employee Account=1
- These accounts held Corporate/SMSF status at some point but were reclassified

### 2.3 Player Status Distribution

**What**: Current regulatory/compliance status of corporate clients.

**Columns Involved**: `PlayerStatus`

**Rules**:
- Normal: 2,547 (~55%) — fully active corporate accounts
- Blocked: 1,557 (~34%) — access restricted by compliance/risk
- Blocked Upon Request: 284 (~6%) — client-requested block
- Warning: 87 (~2%), Deposit Blocked: 85 (~2%), Block Deposit & Trading: 43 (~1%)
- Trade & MIMO Blocked: 25, Pending Verification: 6, Copy Block: 2 (edge cases)
- Status reflects current Dim_Customer.PlayerStatusID at ETL time

### 2.4 Financial Position Computation

**What**: Balance and TotalEquity come from V_Liabilities, a DWH view of end-of-day positions.

**Columns Involved**: `Balance`, `TotalEquity`, `TotalDeposits`

**Rules**:
- `Balance` = ISNULL(V_Liabilities.Credit, 0) at DateID = yesterday's YYYYMMDD int
- `TotalEquity` = ISNULL(V_Liabilities.Liabilities + V_Liabilities.ActualNWA, 0) — total equity covering open positions
- `TotalDeposits` = SUM(BI_DB_AllDeposits.[Amount in $]) WHERE PaymentStatus='Approved' — ALL-TIME approved deposits, not snapshot-bounded
- Zero values (Balance=0, TotalEquity=0, TotalDeposits=0) seen for Blocked accounts with no positions

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. Suited for small daily snapshots (4,636 rows). No distribution key means:
- Any JOIN will broadcast the entire table — acceptable at this row count
- No clustered index — full scan on all queries
- Do not use this table for large-scale analytical aggregations; its purpose is display/export

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Corporate client overview by region | `GROUP BY Region, PlayerStatus ORDER BY COUNT(*) DESC` |
| High-value corporate clients | `WHERE TotalEquity > 100000 ORDER BY TotalEquity DESC` |
| Recently approved corporate accounts | `WHERE ApprovedDateTime >= '2025-01-01' ORDER BY ApprovedDateTime DESC` |
| Active SMSF accounts (Australian) | `WHERE AccountType = 'SMSF' AND PlayerStatus = 'Normal'` |
| Corporate clients with deposits > equity | `WHERE TotalDeposits > TotalEquity AND TotalDeposits > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON dc.RealCID = csr.RealCID` | Get full customer profile (not needed for most use cases — already denormalized) |
| BI_DB_dbo.BI_DB_AllDeposits | `ON bdad.CID = csr.RealCID` | Break down total deposits by payment method |

### 3.4 Gotchas

- **AccountType drift**: Population is historical (ever had AccountTypeID 2/14), but AccountType column is current. Do NOT assume AccountType='Corporate' for all rows — 57 accounts have different current types.
- **ApprovedDateTime is NOT a real approval date**: It is MIN(FullDate) from the first Dim_Range snapshot with AccountTypeID IN (2,14). Historical snapshots may predate actual approval workflow timestamps.
- **TotalDeposits is cumulative all-time**: Not bounded to a date range — includes deposits from account inception regardless of @EndDate.
- **Balance = 0 for Blocked accounts**: V_Liabilities returns Credit=0 for accounts with no active positions. Verify with Dim_Customer.PlayerStatusID if 0-balance seems unexpected.
- **PlayerStatus trailing spaces**: Live data shows "Blocked                                            " with trailing spaces (varchar(max) from Dim_PlayerStatus.Name). Trim before display or comparison.
- **UK dominance**: UK=2,488 rows (~54%). Any regional analysis without explicit filtering will be UK-skewed.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★★★ | Tier 1 | Upstream production wiki verbatim |
| ★★★ | Tier 2 | DWH SP code / ETL derivation |
| ★★ | Tier 3 | Live data sampling / structural inference |
| ★ | Tier 4 — Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 3 | ApprovedDateTime | datetime | YES | Proxy approval date: MIN(Dim_Date.FullDate) for the earliest Fact_SnapshotCustomer record where AccountTypeID IN (2=Corporate, 14=SMSF). Derived via Dim_Range → Dim_Date join chain, not a direct production approval timestamp. Range: 2011-10-20 to 2026-04-12. (Tier 2 — SP_CorporatesSummaryReport) |
| 4 | PlayerStatus | varchar(max) | YES | Current player status name, denormalized from DWH_dbo.Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID. 9 values: Normal=2,547, Blocked=1,557, Blocked Upon Request=284, Warning=87, Deposit Blocked=85, Block Deposit & Trading=43, Trade & MIMO Blocked=25, Pending Verification=6, Copy Block=2. Note: trailing spaces in varchar(max) output. (Tier 2 — SP_CorporatesSummaryReport) |
| 5 | PlayerLevel | varchar(max) | YES | Current club membership tier name, denormalized from DWH_dbo.Dim_PlayerLevel.Name via Dim_Customer.PlayerLevelID. 6 values: Bronze=2,773, Platinum Plus=811, Diamond=409, Platinum=300, Gold=296, Silver=47. (Tier 2 — SP_CorporatesSummaryReport) |
| 6 | Country | varchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) |
| 7 | Region | varchar(max) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Top regions in this table: UK=2,488, Australia=487, French=326, North Europe=311, German=250, Eastern Europe=218. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 8 | Balance | money | YES | Current account credit balance from DWH_dbo.V_Liabilities.Credit at @EndDateID (yesterday). ISNULL(Credit, 0) — zero for accounts with no positions or NULL in V_Liabilities. Represents available cash credit balance. (Tier 2 — SP_CorporatesSummaryReport) |
| 9 | TotalEquity | money | YES | Total equity = V_Liabilities.Liabilities + V_Liabilities.ActualNWA at @EndDateID (yesterday). ISNULL(sum, 0). Covers open position exposure plus net worth. May be substantially higher than Balance for accounts with large open positions. (Tier 2 — SP_CorporatesSummaryReport) |
| 10 | TotalDeposits | money | YES | Cumulative all-time sum of approved deposits from BI_DB_AllDeposits.[Amount in $] WHERE PaymentStatus='Approved', JOINed on CID=RealCID. Not bounded by any date — covers full account history. (Tier 2 — SP_CorporatesSummaryReport) |
| 11 | AccountType | varchar(max) | YES | CURRENT account type name from DWH_dbo.Dim_AccountType.Name via Dim_Customer.AccountTypeID. 8 observed values: Corporate=4,181, SMSF=398, Private=31, Affiliate Corporate Account=13, Fund=8, Trust=3, Affiliate Private Account=1, Employee Account=1. May differ from population filter (IN 2,14) for accounts that changed type. (Tier 2 — SP_CorporatesSummaryReport) |
| 12 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() on each daily TRUNCATE+INSERT run. (Tier 2 — SP_CorporatesSummaryReport) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | etoro.Customer.CustomerStatic (via Fact_SnapshotCustomer) | GCID | Passthrough |
| RealCID | etoro.Customer.CustomerStatic (via Fact_SnapshotCustomer) | RealCID | Passthrough |
| ApprovedDateTime | DWH Dim_Range → Dim_Date | FullDate | MIN — first corporate snapshot date |
| PlayerStatus | DWH Dim_PlayerStatus | Name | Denormalized lookup |
| PlayerLevel | DWH Dim_PlayerLevel | Name | Denormalized lookup |
| Country | etoro.Dictionary.Country (via Dim_Country) | Name | Passthrough |
| Region | etoro.Dictionary.MarketingRegion (via Dim_Country) | Name | Passthrough (AS Region) |
| Balance | DWH V_Liabilities | Credit | ISNULL(Credit, 0) at @EndDateID |
| TotalEquity | DWH V_Liabilities | Liabilities + ActualNWA | ISNULL(sum, 0) at @EndDateID |
| TotalDeposits | BI_DB_dbo.BI_DB_AllDeposits | [Amount in $] | SUM where PaymentStatus='Approved' |
| AccountType | etoro.Dictionary.AccountType (via Dim_AccountType) | Name | Current value lookup |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic + UserApiDB.Customer.CustomerIdentification
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.Fact_SnapshotCustomer (AccountTypeID IN 2, 14 — population filter)
DWH_dbo.Dim_Customer (current attributes: PlayerStatusID, PlayerLevelID, CountryID, AccountTypeID)
DWH_dbo.Dim_PlayerStatus + Dim_PlayerLevel + Dim_Country + Dim_AccountType (denormalize IDs→Names)
DWH_dbo.V_Liabilities (@EndDateID = yesterday) (Balance, TotalEquity)
BI_DB_dbo.BI_DB_AllDeposits (PaymentStatus='Approved') (TotalDeposits)
  |-- SP_CorporatesSummaryReport (TRUNCATE+INSERT, daily, SB_Daily) ---|
  v
BI_DB_dbo.BI_DB_Corporates_SummaryReport (4,636 rows, 2011-10-20 to 2026-04-12)
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID, RealCID | DWH_dbo.Fact_SnapshotCustomer | Population source — AccountTypeID IN (2,14) |
| RealCID | DWH_dbo.Dim_Customer | Current customer attributes |
| Country | DWH_dbo.Dim_Country | Country name lookup |
| Balance, TotalEquity | DWH_dbo.V_Liabilities | Financial position view at @EndDateID |
| TotalDeposits | BI_DB_dbo.BI_DB_AllDeposits | Approved payment aggregation |
| AccountType | DWH_dbo.Dim_AccountType | Account type name lookup |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in BI_DB_dbo at this time. Table is used directly for corporate client management reports.

---

## 7. Sample Queries

### Active Corporate Accounts by Region with High Equity

```sql
SELECT
    Region,
    AccountType,
    COUNT(*) AS CustomerCount,
    SUM(Balance) AS TotalBalance,
    SUM(TotalEquity) AS TotalEquity,
    SUM(TotalDeposits) AS TotalDeposits
FROM [BI_DB_dbo].[BI_DB_Corporates_SummaryReport]
WHERE PlayerStatus = 'Normal'
GROUP BY Region, AccountType
ORDER BY TotalEquity DESC;
```

### Blocked Corporate Clients with Outstanding Balances

```sql
SELECT
    RealCID,
    GCID,
    Country,
    PlayerStatus,
    Balance,
    TotalEquity,
    TotalDeposits,
    ApprovedDateTime
FROM [BI_DB_dbo].[BI_DB_Corporates_SummaryReport]
WHERE PlayerStatus LIKE 'Block%'
  AND (Balance > 0 OR TotalEquity > 0)
ORDER BY TotalEquity DESC;
```

### Recently Approved Corporates (Last 12 Months)

```sql
SELECT
    AccountType,
    Country,
    Region,
    PlayerLevel,
    Balance,
    TotalEquity,
    TotalDeposits,
    ApprovedDateTime
FROM [BI_DB_dbo].[BI_DB_Corporates_SummaryReport]
WHERE ApprovedDateTime >= DATEADD(YEAR, -1, GETDATE())
ORDER BY ApprovedDateTime DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian (Confluence/Jira) sources searched in this batch. The table's business context is self-evident from SP code: corporate and SMSF account management reporting for the Compliance and Corporate Client teams.

---

*Generated: 2026-04-21 | Quality: 8.7/10 | Phases: 12/14*
*Tiers: 3 T1, 9 T2, 0 T3, 0 T4 | Elements: 9.5/10, Logic: 8.5/10, Relationships: 7.5/10, Sources: 9.0/10*
*Object: BI_DB_dbo.BI_DB_Corporates_SummaryReport | Type: Table | Production Source: Fact_SnapshotCustomer (AccountTypeID IN 2,14) + Dim_Customer + V_Liabilities + BI_DB_AllDeposits*
