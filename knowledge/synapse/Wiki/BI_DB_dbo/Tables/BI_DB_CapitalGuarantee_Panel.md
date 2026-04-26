# BI_DB_dbo.BI_DB_CapitalGuarantee_Panel

> 60.6M-row daily-snapshot panel table tracking eToro Capital Guarantee Alpha investors who copy Smart Portfolio accounts — sourced from Dim_Mirror, Dim_Customer, Fact_CustomerAction, V_Liabilities, and BI_DB_PositionPnL, refreshed daily by `SP_Capital_Guarantee_Panel`. Covers the period 2025-01-01 to present (467 daily dates); one row per investor-SP pair per day, spanning 99,810 distinct investors across 247 Smart Portfolios.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Mirror + Dim_Customer + Fact_CustomerAction + V_Liabilities + BI_DB_PositionPnL via `SP_Capital_Guarantee_Panel` |
| **Refresh** | Daily (SB_Daily, @date param — overridden to GETDATE()-1 inside SP; DELETE WHERE DateID=@dateID + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (no index) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CapitalGuarantee_Panel` is the daily monitoring panel for the eToro Capital Guarantee Alpha program — a product that provides investors with some form of capital protection when copying Smart Portfolio (SP) accounts. A Smart Portfolio is an eToro-managed portfolio product (AccountTypeID=9 in BackOffice) where investors copy trades made by the SP manager.

The table tracks every investor who copied any Capital Guarantee-eligible SP on or after 2025-01-01 (the program's launch scope). Each row represents one investor-SP pair on one calendar date, capturing the investor's identity, position status (open/closed), balance, daily and cumulative money flows, deposit/cashout activity, and copy P&L.

The SP was created by Nitsan on 2025-02-12, then extended on 2025-03-03 (added GCID, Country, Regulation, Acc_NMI, Acc_MI, Acc_MO) and 2025-05-19 (added net profit to PnL calculation). Historical rows are preserved — the DELETE/INSERT pattern rebuilds only the current @date row while leaving earlier dates intact.

**Scope**: Only mirrors with `OpenOccurred >= '2025-01-01'` are included — hard-coded Capital Guarantee Alpha program scope. Investors who copied the SP before 2025 are excluded.

**Granularity**: One row per (InvestorCID, ParentCID) per date. Multiple copy positions between the same investor and SP are collapsed: `Positions` counts distinct MirrorIDs, `isOpen` indicates if any remain open.

**Status (2026-04-12 latest date, 250,335 rows)**: isOpen=1: 117,121 investors (46.8%); isOpen=0: 133,214 investors (53.2%). Average positions per row: ~1.3–1.7.

**Top geographies**: UK (18.4%), German (15.9%), Italian (14.1%), French (12.0%), CEE (9.9%). Top regulation: CySEC (66.3%), FCA (21.1%).

---

## 2. Business Logic

### 2.1 Smart Portfolio Parent Filter

**What**: Only Smart Portfolio accounts are included as ParentCID.

**Columns Involved**: `ParentCID`, `ParentUserName`

**Rules**:
- Smart Portfolio accounts have AccountTypeID=9 in Dim_Customer (BackOffice)
- The SP loads `#SP` as `SELECT * FROM Dim_Customer WHERE AccountTypeID=9` and then filters `#Investors` to `dm.ParentCID = s.RealCID`
- This captures all SP-type accounts — both active and inactive SP managers
- In DWH, SP accounts also appear in Dim_Mirror with `IsCopyFundMirror=1`
- 247 distinct SP parents observed in production data

### 2.2 Capital Guarantee Scope Filter

**What**: Only copy relationships opened on or after 2025-01-01 are considered.

**Columns Involved**: `FirstTimeOpen`, `Positions`

**Rules**:
- Filter: `dm.OpenOccurred >= '20250101'` in `#Investors` — hard-coded program start date
- Investors who started copying an SP before 2025-01-01 are excluded entirely, even if still active
- This scope filter aligns with the Capital Guarantee Alpha launch date

### 2.3 Daily @date Override

**What**: The @date parameter is always overridden to GETDATE()-1.

**Columns Involved**: `Date`, `DateID`

**Rules**:
- The SP has: `SET @date = GETDATE()-1` immediately after BEGIN
- Any @date value passed by the scheduler is silently discarded and replaced with yesterday's date
- This means the SP cannot be back-filled for specific dates by passing @date — it always processes yesterday
- DateID = CONVERT(CHAR(8), @date, 112) (YYYYMMDD integer)

### 2.4 DELETE + INSERT (Daily Snapshot Pattern)

**What**: Each daily run deletes the existing row for @dateID and re-inserts fresh data.

**Rules**:
- `DELETE FROM BI_DB_CapitalGuarantee_Panel WHERE DateID = @dateID` — removes any prior run for the same date
- Historical rows (prior dates) are preserved — the table is a growing daily snapshot
- If the SP runs successfully for a date and then re-runs, the second run cleanly replaces the first
- No TRUNCATE — all dates except the current run date are untouched

### 2.5 MoneyIn and MoneyOut (Mirror Cash Flow)

**What**: Daily money flows between the investor's account and their SP copy positions.

**Columns Involved**: `MoneyIn`, `MoneyOut`, `NMI`

**Rules**:
- `MoneyIn` = `COALESCE(SUM(CASE WHEN ActionTypeID IN (15,17) THEN -Amount END), 0)` for @date
- `MoneyOut` = `COALESCE(SUM(CASE WHEN ActionTypeID IN (16,18) THEN -Amount END), 0)` for @date
- `NMI` = `MoneyIn + MoneyOut` (Net Money Investment for the day)
- ActionTypeIDs 15/17 = mirror open/allocation events (money flows from investor wallet INTO the SP position — FCA Amount is negative, negation makes MoneyIn positive)
- ActionTypeIDs 16/18 = mirror close/deallocation events (money returns FROM the SP position — FCA Amount is positive, negation makes MoneyOut negative)
- NMI > 0 = net investment day; NMI < 0 = net withdrawal day; NMI = 0 = no activity
- The `#Actions` temp table filters `CAST(Occurred AS DATE) = @date` (datetime-to-date cast, not DateID lookup)

### 2.6 Acc_MoneyIn and Acc_MoneyOut (Cumulative Cash Flow)

**What**: Lifetime cumulative money flows for the investor-SP pair, from program start through @date.

**Columns Involved**: `Acc_MoneyIn`, `Acc_MoneyOut`, `Acc_NMI`

**Rules**:
- Same ActionTypeID logic (15/17 for in, 16/18 for out) but no date filter: `CAST(Occurred AS DATE) <= @date`
- Acc_NMI = Acc_MoneyIn + Acc_MoneyOut — total net capital committed to date
- The `#AccMimo` temp table computes these from the full Fact_CustomerAction history up to @date
- NOTE: the `#AccMimo` temp table uses `AND i.MirrorID = fca.MirrorID` — cumulative amounts are mirror-specific, not just investor+parent

### 2.7 CopyPnL

**What**: Combined unrealized and realized P&L for the investor's copy positions under this SP.

**Columns Involved**: `CopyPnL`

**Rules**:
- `CopyPnL` = `SUM(PositionPnL + RealziedPnL)` from `BI_DB_PositionPnL JOIN Dim_Mirror`
- Filter: `bdppl.DateID >= @dateID` (note: `>=` not `=` — includes all PositionPnL records from @dateID onward for this investor/parent combination; intended to capture current open positions but `>=` instead of `=` is a quirk worth verifying)
- `RealziedPnL` uses the typo spelling from Dim_Mirror DDL (authoritative spelling)
- NULL if the investor has no BI_DB_PositionPnL records (LEFT JOIN from `#Investment` to `#CopyPnL`)

### 2.8 AvailableBalance

**What**: The investor's available cash balance (credit) on @dateID.

**Columns Involved**: `AvailableBalance`

**Rules**:
- Source: `V_Liabilities.Credit` for CID = InvestorCID AND DateID = @dateID
- The JOIN to V_Liabilities is INNER — investors without a V_Liabilities record for @dateID are silently dropped from the final INSERT
- V_Liabilities excludes today's data (DateKey < today) — since @date = GETDATE()-1 (yesterday), this always resolves correctly

### 2.9 isOpen Flag

**What**: Binary indicator for whether the investor has at least one currently open copy position with this SP.

**Columns Involved**: `isOpen`

**Rules**:
- `CASE WHEN MIN(CloseDateID) = 0 THEN 1 ELSE 0 END` — open mirror sentinel in Dim_Mirror is CloseDateID=0
- `isOpen=1` if any mirror between this investor and this SP has CloseDateID=0 (still open)
- `isOpen=0` if all mirrors have CloseDateID > 0 (all closed), but the investor still appears because they had mirrors opened after 2025-01-01

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution — data is spread across distributions without a key. Given 60.6M rows, queries without a distribution predicate will require broadcast or shuffle for JOINs. **HEAP** — no clustered index. For date-filtered queries, always include a DateID filter to reduce scan range.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| "Current active Capital Guarantee investors" | `WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_CapitalGuarantee_Panel) AND isOpen = 1` |
| "Investors with net outflows today" | `WHERE DateID = @dateID AND NMI < 0` |
| "Cumulative investment by SP" | `WHERE DateID = @dateID GROUP BY ParentCID, ParentUserName; SUM(Acc_NMI)` |
| "Investors in a specific region" | `WHERE Region = 'UK' AND DateID = @dateID` |
| "Investors with positive CopyPnL" | `WHERE CopyPnL > 0 AND DateID = @dateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| `DWH_dbo.Dim_Customer` | `InvestorCID = Dim_Customer.RealCID` | Full investor profile (DOB, registration date, etc.) |
| `DWH_dbo.Dim_Mirror` | `InvestorCID = Dim_Mirror.CID AND ParentCID = Dim_Mirror.ParentCID` | Individual mirror details |
| `DWH_dbo.Dim_Date` | `DateID = Dim_Date.DateID` | Calendar metadata |

### 3.4 Gotchas

- **@date parameter is always overridden**: The SP ignores the @date passed and uses GETDATE()-1. You cannot back-fill specific dates by calling the SP with a custom @date.
- **Capital Guarantee scope only**: `OpenOccurred >= '20250101'` is hard-coded. Investors who copied these SPs before 2025 are not in this table even if they are still copying.
- **FirstTimeOpenID may not match FirstTimeOpen**: `FirstTimeOpen = MIN(OpenOccurred)` but `FirstTimeOpenID = MAX(OpenDateID)` — these are from different records when an investor has multiple positions. FirstTimeOpenID reflects the MOST RECENT copy open, not the first.
- **IsCreditReportValidCB is not stored**: Selected and used in GROUP BY within the SP temp tables but excluded from the final INSERT column list — not available in this table.
- **CopyPnL uses DateID >= @dateID**: The filter `WHERE bdppl.DateID >= @dateID` may include PositionPnL records beyond @dateID if future snapshots exist. Expected behavior is `= @dateID`; verify with data owner.
- **INNER JOIN to V_Liabilities**: Investors with no V_Liabilities record for @dateID (e.g., very new accounts) are silently dropped. This can cause undercounting on dates where V_Liabilities has gaps.
- **60.6M row scale**: Always filter by DateID. Full scans take 10+ seconds even on simple aggregates.
- **ROUND_ROBIN + HEAP**: No distribution or index optimization. Complex JOINs on InvestorCID or ParentCID will require data movement.
- **MoneyOut is negative when present**: MoneyOut = SUM(-Amount for exits). Values are zero (COALESCE) when no exit activity; negative when exits occurred. NMI = MoneyIn + MoneyOut net correctly.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki |
| Tier 2 | Description derived from SP code analysis and live data sampling |
| Tier 3 | Description inferred from available context; lower confidence |
| Propagation | ETL infrastructure column — canonical description from propagation blacklist |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date for this snapshot row. Always yesterday (GETDATE()-1) for the daily run, because the SP overrides the @date parameter internally. Minimum: 2025-01-01 (Capital Guarantee Alpha launch). (Tier 2 — SP_Capital_Guarantee_Panel) |
| 2 | DateID | int | YES | YYYYMMDD integer of Date. Computed as CONVERT(CHAR(8), @date, 112). The DELETE-before-INSERT key: `DELETE WHERE DateID = @dateID` before each daily run. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 3 | ParentCID | int | YES | Leader customer ID. The user whose trades are copied. Trade.GetActiveCopiersForParents filters by ParentCID. (Tier 1 — Trade.Mirror) DWH note: In this table, ParentCID is always a Smart Portfolio account (AccountTypeID=9). 247 distinct SPs in production. |
| 4 | ParentUserName | varchar(50) | YES | Leader username at mirror creation. Denormalized for display; Trade.RegisterMirror passes from caller. (Tier 1 — Trade.Mirror) DWH note: Username of the Smart Portfolio being copied. |
| 5 | InvestorCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) DWH note: The investor (copier) CID; equals Dim_Mirror.CID and Dim_Customer.RealCID. 99,810 distinct investors in production. |
| 6 | InvestorGCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) DWH note: GCID of the investor account. |
| 7 | UserName | varchar(50) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) DWH note: Username of the investor, not the SP. |
| 8 | Email | varchar(50) | YES | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic) DWH note: Email of the investor. |
| 9 | FirstTimeOpen | datetime | YES | The earliest datetime the investor opened a copy position with this SP, from MIN(Dim_Mirror.OpenOccurred) across all mirrors with this parent opened after 2025-01-01. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 10 | FirstTimeOpenID | int | YES | CAUTION: Named "FirstTimeOpenID" but computed as MAX(OpenDateID), not as the DateID of MIN(OpenOccurred). For investors with multiple copy positions, this reflects the MOST RECENT copy open date, not the first. For single-position investors, this equals the correct DateID. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 11 | Positions | int | YES | Count of distinct copy positions (MirrorIDs) between this investor and this SP opened after 2025-01-01. Includes both open and closed positions. Average ~1.3–1.7 per row in production data. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 12 | isOpen | int | YES | 1 if the investor has at least one currently open copy position with this SP (MIN(CloseDateID)=0); 0 if all positions are closed. Open/closed sentinel: CloseDateID=0 = open mirror in Dim_Mirror. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 13 | MaxClose | datetime | YES | Latest close datetime across all copy positions between this investor and this SP (MAX(CloseOccurred)). '1900-01-01' sentinel if no position has been closed yet. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 14 | MaxCloseID | int | YES | DateID of the most recent close across all copy positions (MAX(CloseDateID)). 0 if all positions remain open. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 15 | IsValidCustomer | int | YES | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) DWH note: Passthrough from Dim_Customer.IsValidCustomer. |
| 16 | Region | varchar(50) | YES | Manual override name for the marketing region from Dim_Country.MarketingRegionManualName. May differ from Dim_Country.Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. 14 distinct region values in production. (Tier 3 — Ext_Dim_Country live data) |
| 17 | Country | varchar(40) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) DWH note: The investor's country of residence from Dim_Country.Name. 118 distinct countries in production. |
| 18 | Club | varchar(50) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) DWH note: The investor's eToro Club loyalty tier. Top tiers in production: Bronze (30K), Gold (21K), Silver (18K). |
| 19 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation) DWH note: The investor's regulatory entity. Top values: CySEC (66.3%), FCA (21.1%), FSA Seychelles (5.3%). |
| 20 | ManagerID | int | YES | Auto-generated unique integer identifier for each BackOffice staff member. PK for the entire BackOffice authorization system. ManagerID=0 is the reserved System account; ManagerID=1 is the bootstrap Admin. All BackOffice action tables (BackOffice.Customer, Task, Downtime, etc.) store ManagerID as the 'acting staff' reference. (Tier 1 — BackOffice.Manager) DWH note: The investor's assigned account manager. |
| 21 | Manager | varchar(50) | YES | The investor's assigned account manager display name, computed as CONCAT(FirstName, ' ', LastName) from Dim_Manager. NULL if no matching Dim_Manager record. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 22 | AvailableBalance | float | YES | The investor's available cash credit balance on @dateID from V_Liabilities.Credit. Represents the customer's usable cash in their account (Credit component of total balance). Range in production: -9,025 to 4,187,000; average ~5,500. NULL if no V_Liabilities record exists for this CID/DateID combination (INNER JOIN). (Tier 2 — SP_Capital_Guarantee_Panel via V_Liabilities.Credit) |
| 23 | MoneyOut | float | YES | Daily money withdrawn from this SP copy position: COALESCE(SUM(CASE WHEN ActionTypeID IN (16,18) THEN -Amount END), 0) from Fact_CustomerAction for @date. ActionTypeIDs 16/18 = mirror close/deallocation events. Negative when exits occur (negation of positive FCA credits); 0 when no exit activity. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 24 | MoneyIn | float | YES | Daily money invested into this SP copy position: COALESCE(SUM(CASE WHEN ActionTypeID IN (15,17) THEN -Amount END), 0) from Fact_CustomerAction for @date. ActionTypeIDs 15/17 = mirror open/allocation events. Positive when investments occur (negation of negative FCA debits); 0 when no activity. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 25 | NMI | float | YES | Net Money Investment for the day: MoneyIn + MoneyOut. Positive = net new capital invested in this SP; negative = net capital withdrawn; 0 = no activity. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 26 | Deposit | float | YES | Total deposits made by the investor on @dateID: COALESCE(SUM(CASE WHEN ActionTypeID=7 THEN Amount END), 0). Reflects deposits to the main account (not SP-specific). (Tier 2 — SP_Capital_Guarantee_Panel) |
| 27 | Cashout | float | YES | Total cashouts by the investor on @dateID: COALESCE(SUM(CASE WHEN ActionTypeID=8 THEN -Amount END), 0). Reflects withdrawals from the main account (not SP-specific). (Tier 2 — SP_Capital_Guarantee_Panel) |
| 28 | CopyPnL | float | YES | Combined unrealized and realized P&L for the investor's copy positions under this SP: SUM(BI_DB_PositionPnL.PositionPnL + Dim_Mirror.RealziedPnL). Filter: PositionPnL.DateID >= @dateID (see gotcha: >= not =). NULL if no BI_DB_PositionPnL records exist for this investor/SP combination. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 29 | Acc_MoneyOut | float | YES | Cumulative money withdrawn from this SP copy position from all-time through @date: COALESCE(SUM(CASE WHEN ActionTypeID IN (16,18) THEN -Amount END), 0). Mirror-level granularity (includes MirrorID filter). (Tier 2 — SP_Capital_Guarantee_Panel) |
| 30 | Acc_MoneyIn | float | YES | Cumulative money invested into this SP copy position from all-time through @date: COALESCE(SUM(CASE WHEN ActionTypeID IN (15,17) THEN -Amount END), 0). Mirror-level granularity (includes MirrorID filter). (Tier 2 — SP_Capital_Guarantee_Panel) |
| 31 | Acc_NMI | float | YES | Cumulative net money investment from all-time through @date: Acc_MoneyIn + Acc_MoneyOut. Positive = investor has net committed capital in this SP; negative = investor has withdrawn more than invested over all time. (Tier 2 — SP_Capital_Guarantee_Panel) |
| 32 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. EXCEPTION: for frozen migration tables (DWH_Migration schema origin), this is the original production timestamp preserved from the legacy system — NOT set by GETDATE(). Run timestamp analysis (Phase 2 Tier A1) to determine which applies before using this description. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Date | ETL (@date param, overridden to GETDATE()-1) | — | Date |
| DateID | ETL (@date param) | — | CONVERT(CHAR(8), @date, 112) |
| ParentCID | DWH_dbo.Dim_Mirror | ParentCID | Passthrough |
| ParentUserName | DWH_dbo.Dim_Mirror | ParentUserName | Passthrough |
| InvestorCID | DWH_dbo.Dim_Mirror (= Dim_Customer.RealCID) | CID | Passthrough + rename |
| InvestorGCID | DWH_dbo.Dim_Customer | GCID | Passthrough + rename |
| UserName | DWH_dbo.Dim_Customer | UserName | Passthrough |
| Email | DWH_dbo.Dim_Customer | Email | Passthrough |
| FirstTimeOpen | DWH_dbo.Dim_Mirror | OpenOccurred | MIN aggregate |
| FirstTimeOpenID | DWH_dbo.Dim_Mirror | OpenDateID | MAX aggregate (mismatch with FirstTimeOpen) |
| Positions | DWH_dbo.Dim_Mirror | MirrorID | COUNT(DISTINCT) |
| isOpen | DWH_dbo.Dim_Mirror | CloseDateID | CASE WHEN MIN=0 THEN 1 ELSE 0 |
| MaxClose | DWH_dbo.Dim_Mirror | CloseOccurred | MAX aggregate |
| MaxCloseID | DWH_dbo.Dim_Mirror | CloseDateID | MAX aggregate |
| IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Passthrough + rename |
| Country | DWH_dbo.Dim_Country | Name | Passthrough + rename |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough + rename |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough + rename (JOIN on DWHRegulationID) |
| ManagerID | DWH_dbo.Dim_Manager | ManagerID | Passthrough |
| Manager | DWH_dbo.Dim_Manager | FirstName, LastName | CONCAT(FirstName, ' ', LastName) |
| AvailableBalance | DWH_dbo.V_Liabilities | Credit | Passthrough + rename |
| MoneyOut | DWH_dbo.Fact_CustomerAction | Amount | SUM(-Amount) WHERE ActionTypeID IN (16,18) for @date |
| MoneyIn | DWH_dbo.Fact_CustomerAction | Amount | SUM(-Amount) WHERE ActionTypeID IN (15,17) for @date |
| NMI | Computed | — | MoneyIn + MoneyOut |
| Deposit | DWH_dbo.Fact_CustomerAction | Amount | SUM(Amount) WHERE ActionTypeID=7 for @dateID |
| Cashout | DWH_dbo.Fact_CustomerAction | Amount | SUM(-Amount) WHERE ActionTypeID=8 for @dateID |
| CopyPnL | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Mirror | PositionPnL, RealziedPnL | SUM(PositionPnL + RealziedPnL) WHERE DateID >= @dateID |
| Acc_MoneyOut | DWH_dbo.Fact_CustomerAction | Amount | SUM(-Amount) WHERE ActionTypeID IN (16,18), Occurred <= @date |
| Acc_MoneyIn | DWH_dbo.Fact_CustomerAction | Amount | SUM(-Amount) WHERE ActionTypeID IN (15,17), Occurred <= @date |
| Acc_NMI | Computed | — | Acc_MoneyIn + Acc_MoneyOut |
| UpdateDate | ETL runtime | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (AccountTypeID=9) ← Smart Portfolio parents
DWH_dbo.Dim_Mirror (OpenOccurred >= '20250101') ← investor-SP copy relationships
  + DWH_dbo.Dim_Customer (investor: GCID, UserName, Email, IsValidCustomer, etc.)
  + DWH_dbo.Dim_Country (Region=MarketingRegionManualName, Country=Name)
  + DWH_dbo.Dim_PlayerLevel (Club=Name)
  + DWH_dbo.Dim_Manager (ManagerID, Manager=CONCAT)
  + DWH_dbo.Dim_Regulation (Regulation=Name)
  + DWH_dbo.V_Liabilities (AvailableBalance=Credit for @dateID)
  + DWH_dbo.Fact_CustomerAction (ActionTypeID 7,8,15,16,17,18)
  + BI_DB_dbo.BI_DB_PositionPnL (CopyPnL)
    |-- SP_Capital_Guarantee_Panel (@date=GETDATE()-1, Daily SB_Daily) ---|
    |-- DELETE WHERE DateID=@dateID + INSERT ---|
    v
BI_DB_dbo.BI_DB_CapitalGuarantee_Panel (60.6M rows, 2025-01-01 to 2026-04-12)
    |-- UC: _Not_Migrated ---|
    v
  (no downstream consumers identified)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| ParentCID | DWH_dbo.Dim_Customer (AccountTypeID=9) | Smart Portfolio parent account |
| InvestorCID | DWH_dbo.Dim_Customer | Investor profile (full customer details) |
| ParentCID + InvestorCID | DWH_dbo.Dim_Mirror | Individual mirror positions for the investor-SP pair |
| DateID | DWH_dbo.Dim_Date | Calendar metadata |
| ManagerID | DWH_dbo.Dim_Manager | Account manager profile |

### 6.2 Referenced By (other objects point to this)

No downstream SPs or views identified consuming this table.

---

## 7. Sample Queries

### Current Capital Guarantee Snapshot (Latest Date)

```sql
SELECT
    ParentUserName,
    COUNT(DISTINCT InvestorCID) AS investors,
    SUM(CASE WHEN isOpen = 1 THEN 1 ELSE 0 END) AS open_investors,
    SUM(AvailableBalance) AS total_balance,
    SUM(Acc_NMI) AS total_cumulative_nmi
FROM [BI_DB_dbo].[BI_DB_CapitalGuarantee_Panel]
WHERE DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_CapitalGuarantee_Panel])
GROUP BY ParentUserName
ORDER BY investors DESC
```

### Daily Net Flow by Region

```sql
SELECT
    DateID,
    Region,
    SUM(MoneyIn) AS daily_money_in,
    SUM(MoneyOut) AS daily_money_out,
    SUM(NMI) AS net_daily_flow,
    COUNT(DISTINCT InvestorCID) AS active_investors
FROM [BI_DB_dbo].[BI_DB_CapitalGuarantee_Panel]
WHERE DateID >= 20260101
GROUP BY DateID, Region
ORDER BY DateID DESC, net_daily_flow DESC
```

### Investors with Largest Cumulative Withdrawal

```sql
SELECT TOP 20
    InvestorCID,
    UserName,
    Country,
    ParentUserName,
    Acc_NMI,
    Acc_MoneyIn,
    Acc_MoneyOut,
    CopyPnL,
    isOpen
FROM [BI_DB_dbo].[BI_DB_CapitalGuarantee_Panel]
WHERE DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_CapitalGuarantee_Panel])
  AND Acc_NMI < 0
ORDER BY Acc_NMI ASC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this Capital Guarantee Alpha monitoring table.

---

*Generated: 2026-04-23 | Quality: 9.0/10 | Phases: 11/14*
*Tiers: 10 T1, 21 T2, 1 T3, 0 T4, 0 T5, 1 Propagation | Elements: 32/32, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_CapitalGuarantee_Panel | Type: Table | Production Source: DWH_dbo.Dim_Mirror + Fact_CustomerAction + V_Liabilities + BI_DB_PositionPnL*
