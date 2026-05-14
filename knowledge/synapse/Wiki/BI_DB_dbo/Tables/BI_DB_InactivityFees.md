---
object: BI_DB_dbo.BI_DB_InactivityFees
type: table
schema: BI_DB_dbo
status: documented
quality: 8.8
batch: 27
documented_by: claude-sonnet-4-6
documented_date: 2026-04-22
---

# BI_DB_dbo.BI_DB_InactivityFees

## 1. Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Snapshot) |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Column Count** | 18 |
| **Row Count** | ~63,530 |
| **Grain** | One row per RealCID (inactivity-fee-eligible customer) |
| **Refresh Pattern** | TRUNCATE + INSERT — full snapshot refresh per SP run |
| **Writer SP** | `SP_Inactivity_Fees` |
| **Author** | Dana Shamsutdinova (2022-03-03) |
| **Last Updated** | 2024-03-06 (Adi Meidan — removed USA filter) |
| **FTD Date Range** | 2008-04-15 — 2025-08-20 |
| **Last SP Run** | 2026-04-13 |
| **UC Target** | Not Migrated |

---

## 2. Business Meaning

**BI_DB_InactivityFees** is the compliance operations snapshot of eToro customers who are currently eligible for an **inactivity fee** charge.

A customer qualifies if they meet all of the following criteria at the time the SP runs:
1. They hold a **balance (Liabilities) greater than $20** — there is something to charge against.
2. They **have not logged in for more than 1 year** (last `ActionTypeID=14` event > 365 days ago).
3. They have **no currently open positions** (CloseDateID=0 exclusion).
4. They are a **valid, active, depositing customer** — `IsValidCustomer=1`, account not closed (AccountStatusID≠2), not blocked (PlayerStatusID NOT IN 2,4), and `FirstDepositDate > 1900-01-01`.
5. They are **not Canadian** (CountryID=38 excluded). USA exclusion was removed 2024-03-06.

The table acts as a **work queue** for the inactivity fee collection process — every row represents a customer from whom a fee may be deducted.

**Grain**: One row per `RealCID`. 63,530 rows = 63,530 distinct eligible customers.

**Regulation distribution**: FCA (34.5%), CySEC (27.8%), FinCEN+FINRA (18.2%), FinCEN (12.1%), FSA Seychelles (3.0%), ASIC & GAML (2.8%), FSRA (1.1%), ASIC (0.5%).

---

## 3. Key Gotchas

### 3.1 Full Truncate — No History
The SP runs `TRUNCATE TABLE` before inserting. There is **no historical record** of prior eligibility sets — each run replaces the previous snapshot entirely. Do not use this table for trend analysis.

### 3.2 Liabilities ≠ Cash Balance
The `Liabilities` column comes from `DWH_dbo.V_Liabilities` — this is the **net liability** position (typically cash balance minus unrealized losses), not a simple cash deposit figure. The `Credit` column represents total credit. Both are sourced from the same view at `@DateID`.

### 3.3 LastLogin Filter Window
The SP excludes customers whose last login (`ActionTypeID=14`) was within 1 year of `@Date`. The exact cutoff is `LastLoggedIn <= DATEADD(DAY, 1, DATEADD(year, -1, @Date))` — note the +1 day buffer. Customers whose anniversary date falls on `@Date` itself are also excluded.

### 3.4 USA Removed in 2024
USA was previously excluded via `CountryID NOT IN (38, 219)` (Canada=38, USA=219). As of 2024-03-06 (Adi Meidan), USA was removed from the exclusion. FinCEN+FINRA and FinCEN accounts now appear in the table.

### 3.5 PlayerStatus Includes Partially Blocked
Despite `PlayerStatusID NOT IN (2, 4)` (Blocked Upon Request, Blocked), customers with partial blocking still appear: `Block Deposit & Trading` (2.2%), `Trade & MIMO Blocked` (0.7%), `Deposit Blocked` (0.4%). These are different PlayerStatusIDs not excluded by the filter.

### 3.6 IsAffiliate is binary(1)
The `IsAffiliate` column is DDL `binary(1)`, not `bit`. Values observed as `\x00` (false) and `\x01` (true). Cast to `TINYINT` or compare as `0x00` / `0x01` in queries.

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | ID | uniqueidentifier | YES | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — Customer.CustomerStatic) |
| 3 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 4 | FTD_Month | date | YES | Last calendar day of the month in which the customer made their first deposit. Derived via EOMONTH(FirstDepositDate). Used for cohort grouping by first-deposit month. (Tier 2 — SP_Inactivity_Fees) |
| 5 | FTD_Date | date | YES | Exact date of customer's first deposit. CAST(Dim_Customer.FirstDepositDate AS DATE). (Tier 2 — SP_Inactivity_Fees) |
| 6 | Regulation | varchar(50) | YES | Regulatory jurisdiction for this customer. Resolved via Dim_Regulation.Name JOIN on Dim_Customer.RegulationID. Values: FCA, CySEC, FinCEN+FINRA, FinCEN, FSA Seychelles, ASIC & GAML, FSRA, ASIC. (Tier 2 — SP_Inactivity_Fees) |
| 7 | UKunderFCA | char(10) | YES | 'Yes' if the customer is regulated by FCA and is based in the UK (RegulationID=2 AND CountryID=218); 'No' otherwise. Compliance sub-segmentation for UK FCA inactivity-fee rules. (Tier 2 — SP_Inactivity_Fees) |
| 8 | AccountStatusName | varchar(50) | YES | Human-readable account status label. Joined from Dim_AccountStatus on Dim_Customer.AccountStatusID. 99.7% 'Open'; 0.3% 'N/A'. Closed accounts (AccountStatusID=2) are excluded upstream. (Tier 2 — SP_Inactivity_Fees) |
| 9 | PlayerStatus | varchar(50) | YES | Customer trading/access restriction status. Joined from Dim_PlayerStatus on Dim_Customer.PlayerStatusID. 95.5% 'Normal'; remainder are partially-blocked states not covered by exclusion filter. (Tier 2 — SP_Inactivity_Fees) |
| 10 | Club | varchar(50) | YES | Customer player-level tier. FK to DWH_dbo.Dim_PlayerLevel. Per dictionary (verified 2026-05-13): 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (in-house / eToro-employee accounts), 5=Silver, 6=Platinum Plus, 7=Diamond. NOT a Popular Investor signal (PI is tracked by GuruStatusID). NOT a demo flag (demo is AccountTypeID=2). Default=0. (Tier 2 - DWH_dbo.Dim_PlayerLevel)|
| 11 | AccountType | varchar(50) | YES | Customer account classification. Joined from Dim_AccountType on Dim_Customer.AccountTypeID. Values: Private, Corporate, etc. (Tier 2 — SP_Inactivity_Fees) |
| 12 | Country | varchar(50) | YES | Country of registration. Joined from Dim_Country on Dim_Customer.CountryID. Canada (CountryID=38) is excluded upstream. (Tier 2 — SP_Inactivity_Fees) |
| 13 | Language | varchar(50) | YES | Customer's preferred platform language. Joined from Dim_Language on Dim_Customer.LanguageID. (Tier 2 — SP_Inactivity_Fees) |
| 14 | LastLogin | date | YES | Date of the customer's most recent login event (ActionTypeID=14 in Fact_CustomerAction). All values are ≤ 1 year before the SP run date — this is an eligibility condition. (Tier 2 — SP_Inactivity_Fees) |
| 15 | UpdateDate | datetime | YES | ETL run timestamp. Set to GETDATE() at INSERT time. All rows share the same value within a single SP run. (Tier 3 — SP_Inactivity_Fees) |
| 16 | IsAffiliate | binary(1) | YES | 1 (0x01) if the customer also holds an affiliate account in Dim_Affiliate; 0 (0x00) otherwise. Stored as binary(1), not bit — cast to TINYINT for numeric comparison. (Tier 2 — SP_Inactivity_Fees) |
| 17 | Liabilities | money | YES | Net balance/liability position at @DateID from DWH_dbo.V_Liabilities. All values >$20 (SP entry filter). Represents the amount the fee would be charged against. (Tier 2 — SP_Inactivity_Fees) |
| 18 | Credit | money | YES | Total credit balance at @DateID from DWH_dbo.V_Liabilities. Co-sourced with Liabilities from the same view row. (Tier 2 — SP_Inactivity_Fees) |

---

## 5. Business Logic

### 5.1 Inactivity Eligibility Chain

```
V_Liabilities (DateID=@DateID, Liabilities>20)   → #LiabilitiesYesterday
Fact_CustomerAction (ActionTypeID=14, latest)     → #LastLogIn (≤1 yr ago)
Dim_Position (CloseDateID=0)                      → #OpenPositions (exclusion)

#finaltable = Dim_Customer
  JOIN #LiabilitiesYesterday ON RealCID=CID
  JOIN #LastLogIn ON CID
  NOT IN #OpenPositions
  WHERE IsValidCustomer=1
        AND AccountStatusID<>2
        AND PlayerStatusID NOT IN (2,4)
        AND CountryID NOT IN (38)
        AND FirstDepositDate > '1900-01-01'
```

### 5.2 Inactivity Threshold
`LastLoggedIn <= DATEADD(DAY, 1, DATEADD(year, -1, @Date))`

The extra +1 day means the cutoff is strictly more than 1 year before the run date. A customer who last logged in exactly 365 days ago would still qualify (they are within the 1-day buffer).

### 5.3 UKunderFCA Rule
FCA (RegulationID=2) encompasses both UK customers (CountryID=218) and non-UK customers regulated under FCA. The `UKunderFCA` flag distinguishes these for fee-schedule purposes — UK FCA customers may have different inactivity fee rules under FCA regulations.

### 5.4 Affiliate Flag
The affiliate check uses a `SELECT DISTINCT TradingAccount_RealCID FROM Dim_Affiliate WHERE TradingAccount_RealCID IS NOT NULL` subquery. Customers who are themselves affiliate account holders are flagged as `IsAffiliate=1` for potential exemption or different fee treatment.

---

## 6. Data Evidence

| Metric | Value | Source |
|--------|-------|--------|
| Row count | 63,530 | COUNT(*) live |
| Unique RealCIDs | 63,530 | COUNT(DISTINCT RealCID) — perfect grain |
| FTD date range | 2008-04-15 — 2025-08-20 | MIN/MAX |
| Last SP run | 2026-04-13 | MAX(UpdateDate) |
| Null Liabilities | 0 | live check |
| Null Credit | 0 | live check |
| Null GCID | 0 | live check |
| Regulation top 3 | FCA 34.5%, CySEC 27.8%, FinCEN+FINRA 18.2% | GROUP BY |
| PlayerStatus top value | Normal 95.5% | GROUP BY |
| AccountStatusName | Open 99.7%, N/A 0.3% | GROUP BY |

---

## 7. Source Objects

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Customer | Primary customer dimension |
| DWH_dbo.V_Liabilities | Balance view at @DateID |
| DWH_dbo.Fact_CustomerAction | Login event history (ActionTypeID=14) |
| DWH_dbo.Dim_Position | Open position set (exclusion filter) |
| DWH_dbo.Dim_Regulation | Regulation name |
| DWH_dbo.Dim_AccountStatus | Account status label |
| DWH_dbo.Dim_PlayerStatus | Player status label |
| DWH_dbo.Dim_PlayerLevel | Club label |
| DWH_dbo.Dim_AccountType | Account type label |
| DWH_dbo.Dim_Country | Country name |
| DWH_dbo.Dim_Language | Language name |
| DWH_dbo.Dim_Affiliate | Affiliate membership |

---

## 8. Dependencies & Usage

**Upstream dependencies**: SP_Inactivity_Fees → requires V_Liabilities and Fact_CustomerAction to be current for @Date before SP is run.

**No downstream tables** identified within BI_DB_dbo that read this table. It is primarily a **reporting/compliance export surface**.

**Typical query pattern**:
```sql
-- All FCA UK customers eligible for inactivity fee
SELECT RealCID, Liabilities, Credit, LastLogin, Club
FROM BI_DB_dbo.BI_DB_InactivityFees
WHERE Regulation = 'FCA' AND UKunderFCA = 'Yes'
ORDER BY Liabilities DESC;
```
