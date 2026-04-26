# BI_DB_dbo.BI_DB_BO_Generated_Compensations

**Schema**: BI_DB_dbo | **UC Target**: `general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations`
**Row count**: ~26.8M total (2021-01-01 → 2026-04-12) | **Refresh**: daily, Priority 0
**Distribution**: HASH(CID) | **Structure**: HEAP

---

## 1. Business Meaning

Daily record of **back-office generated compensations** — manual or system-triggered credit events applied to customer accounts by eToro's back-office operations team. One row = one compensation event applied to a customer.

A compensation (CreditTypeID=6) is a credit entry in `etoro.History.Credit` representing money added to a customer's account outside of trading gains — e.g., to remedy a service issue, honor a promotion, or correct an error. This table is the DWH's authoritative view of that event log.

Each row captures who received the compensation (CID), how much (Amount), why (Category, Reason), who authorized it (Manager), when (Time), and contextual customer attributes (Affiliate, Player Level, Country, Regulation).

Excludes: PlayerLevelID=4 (internal/staff accounts) and CountryID=250 (a specific country exclusion). CreditTypeID filter is always exactly 6 — no other credit types appear.

The table feeds the UC Gold layer via view `V_BI_DB_BO_Generated_Compensations`, which renames the two space-containing columns for Spark compatibility: `[Player Level]` → `Player_level`, `[Country (Reg Form)]` → `Country_Reg_Form`.

---

## 2. Business Logic

### 2.1 ETL Pattern and Date Parameter
SP_BO_Generated_Compensations runs daily with `@Date` as the target date. It first calls `SP_Create_External_etoro_History_Credit @Date, 'Yesterday'` to stage the prior day's data, then deletes rows where `Time >= @Date AND Time < @Date+1` and inserts fresh.

### 2.2 CreditTypeID=6 Filter
The source table `etoro.History.Credit` contains all credit types. This SP and table are exclusively for CreditTypeID=6 (compensations). The column `Type` in the output always reflects the CreditTypeName for type 6 — functionally always 'Compensation'.

### 2.3 Manager Name Bug — No Space Separator
The `Manager` column is populated by `CONCAT(BMNG.FirstName, '', BMNG.LastName)` — using an empty string `''` instead of `' '` as the separator. This results in names like `'AdminNistrator'` instead of `'Admin Nistrator'`. This is a known production bug in the SP code. Do not attempt to split on space to recover first/last names.

### 2.4 Category vs Reason
`Category` is the primary classification label from the CompensationReason dictionary (resolved via HCRD.CompensationReasonID → BackOffice_CompensationReason.Name). `Reason` is a secondary optional label from DWH_dbo.Dim_MoveMoneyReason (resolved via HCRD.MoveMoneyReasonID → Dim_MoveMoneyReason.MoveMoneyReason). Reason is NULL in approximately 87% of rows.

### 2.5 UC Export via View
The table is exported to Unity Catalog via a Generic Pipeline (Append, daily) reading from view `V_BI_DB_BO_Generated_Compensations`. The view exists solely to rename the two space-containing columns (`[Player Level]`, `[Country (Reg Form)]`) to underscore-safe names. All column values are unchanged.

### 2.6 Exclusion Logic
Two hard exclusions are applied in the SP:
- `CCST.PlayerLevelID <> 4` — excludes internal/staff-level customers
- `CCST.CountryID <> 250` — excludes a specific country

---

## 3. Query Advisory

### 3.1 Column Names Contain Spaces — Use Brackets in SQL
Two columns have embedded spaces: `[Player Level]` and `[Country (Reg Form)]`. Always bracket these in T-SQL queries. In Unity Catalog (via the view), they are exposed as `Player_level` and `Country_Reg_Form`.

### 3.2 `Manager` Has No Space Between Names
`Manager` values are concatenated without a space separator (known SP bug). Do not split on space to recover first/last names. Use Manager as an opaque string. Values look like `'AdminNistrator'` or `'JohnDoe'`.

### 3.3 `Reason` Is NULL ~87% of Rows
`Reason` is only populated when `MoveMoneyReasonID` is non-null in the source. Always handle NULL. Do not filter `WHERE Reason IS NOT NULL` unless explicitly studying the minority of tagged compensations.

### 3.4 `Type` Is Always 'Compensation'
The CreditTypeID=6 filter means `Type` is functionally constant. It has no analytical value for segmentation within this table.

### 3.5 `Time` Is the Event Datetime
`Time` = the compensation event datetime from `etoro.History.Credit.Occurred`. Use `Time` for event-based analysis and filtering. `UpdateDate` is ETL metadata (GETDATE() at insert time).

### 3.6 `Amount` Is CAST to DECIMAL(16,2)
`Amount` is the `Payment` column from History.Credit, cast to DECIMAL(16,2). Values are in the customer account currency (typically USD).

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| CID | int | Customer ID. Identifies the customer who received the compensation. Distribution key. | Tier 2 — SP code | HASH distribution column |
| Amount | decimal(16,2) | Compensation amount in account currency. CAST from History.Credit.Payment. | Tier 2 — SP code | Renamed from Payment |
| Type | varchar(50) | Credit type name. Always 'Compensation' (CreditTypeID=6 filter). LTRIM/RTRIM applied. | Tier 2 — SP code | Functionally constant in this table |
| Time | datetime | Datetime of the compensation event. From History.Credit.Occurred. | Tier 2 — SP code | Primary event timestamp |
| Description | varchar(500) | Free-text compensation description entered by back-office. | Tier 2 — SP code | May be NULL or empty |
| Category | varchar(100) | Compensation category label from the CompensationReason dictionary. | Tier 2 — SP code | From BackOffice_CompensationReason.Name; NULL if CompensationReasonID not found |
| Reason | varchar(100) | Secondary reason label from Dim_MoveMoneyReason. NULL ~87% of rows. | Tier 2 — SP code | Only populated when MoveMoneyReasonID is set |
| Manager | varchar(100) | Full name of the back-office agent who issued the compensation (FirstName + LastName, no space). | Tier 2 — SP code | Known bug: no space separator — names appear like 'JohnDoe' |
| Affiliate | int | Affiliate ID associated with the customer at time of compensation. From Dim_Customer.AffiliateID. | Tier 2 — SP code | May be NULL for unaffiliated customers |
| [Player Level] | varchar(50) | Customer player-level name at time of compensation. From Dim_PlayerLevel.Name. | Tier 2 — SP code | In UC view exposed as Player_level |
| [Country (Reg Form)] | varchar(50) | Full country name from customer's registration form. From Dim_Country.Name via Dim_Customer.CountryID. | Tier 2 — SP code | Full name, not ISO code; in UC view exposed as Country_Reg_Form |
| Regulation | varchar(50) | Regulatory jurisdiction of the customer's account. From Dim_Regulation.Name via BackOffice_Customer.RegulationID. | Tier 2 — SP code | e.g., 'CySEC', 'FCA' |
| UpdateDate | datetime | Datetime when this row was written by the SP (GETDATE() at INSERT time). | Propagation — ETL metadata | datetime type (unlike AssignmentTool tables which use date) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Layer | Role |
|--------|-------|------|
| etoro.History.Credit (CreditTypeID=6) | Production DB (etoroDB-REAL) | Primary source — compensation credit events |
| BI_DB_dbo.External_etoro_History_Credit_Yesterday | BI_DB External | Staged prior-day credit data (CreditTypeID filter applied upstream) |
| BI_DB_dbo.External_etoro_BackOffice_Customer | BI_DB External | Customer RegulationID lookup |
| BI_DB_dbo.External_etoro_BackOffice_CompensationReason | BI_DB External | Category name dictionary |
| BI_DB_dbo.External_etoro_BackOffice_Manager | BI_DB External | Manager first/last name |
| DWH_dbo.Dim_Customer | DWH dimension | CID → AffiliateID, PlayerLevelID, CountryID |
| DWH_dbo.Dim_Regulation | DWH dimension | Regulation name |
| DWH_dbo.Dim_PlayerLevel | DWH dimension | Player Level name |
| DWH_dbo.Dim_Country | DWH dimension | Country name |
| DWH_dbo.Dim_MoveMoneyReason | DWH dimension | Reason label |

### 5.2 ETL Pipeline

```
etoro.History.Credit (production, server: etoroDB-REAL)
  |-- SP_Create_External_etoro_History_Credit @Date, 'Yesterday' --|
  v
BI_DB_dbo.External_etoro_History_Credit_Yesterday  (CreditTypeID=6 filter)
  |-- JOIN External_etoro_BackOffice_Customer (RegulationID) --|
  |-- JOIN External_etoro_BackOffice_CompensationReason (Category name) --|
  |-- JOIN External_etoro_BackOffice_Manager (Manager: no-space CONCAT) --|
  |-- JOIN DWH_dbo.Dim_Customer (AffiliateID, PlayerLevelID, CountryID) --|
  |-- JOIN DWH_dbo.Dim_Regulation (Regulation name) --|
  |-- JOIN DWH_dbo.Dim_PlayerLevel (Player Level name) --|
  |-- JOIN DWH_dbo.Dim_Country (Country name) --|
  |-- JOIN DWH_dbo.Dim_MoveMoneyReason (Reason) --|
  |-- EXCLUDE: PlayerLevelID=4, CountryID=250 --|
  |-- SP_BO_Generated_Compensations @Date (daily, P0) --|
  |-- DELETE WHERE Time>=@Date AND Time<@Date+1 + INSERT --|
  v
BI_DB_dbo.BI_DB_BO_Generated_Compensations (26.8M rows)
  |-- View: V_BI_DB_BO_Generated_Compensations --|
  |--   renames [Player Level] → Player_level --|
  |--   renames [Country (Reg Form)] → Country_Reg_Form --|
  |-- Generic Pipeline (Gold export, Append, daily) --|
  v
general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations
```

---

## 6. Relationships

| Related Table | Join | Notes |
|--------------|------|-------|
| BI_DB_dbo.BI_DB_BODailyCompensations | CID, Time (date) | Sibling daily aggregation of compensations; this table is the row-level source |
| DWH_dbo.Dim_Customer | CID | Customer details, affiliate, player level |
| DWH_dbo.Dim_Regulation | Regulation (name match) | Regulatory entity metadata |
| DWH_dbo.Dim_Country | [Country (Reg Form)] (name match) | Country metadata |

---

## 7. Sample Queries

**Daily compensation volume and total amount**
```sql
SELECT
    CAST(Time AS DATE) comp_date,
    COUNT(*) num_compensations,
    SUM(Amount) total_amount
FROM BI_DB_dbo.BI_DB_BO_Generated_Compensations
WHERE Time >= '2026-04-01'
  AND Time < '2026-05-01'
GROUP BY CAST(Time AS DATE)
ORDER BY comp_date
```

**Compensation breakdown by category**
```sql
SELECT
    Category,
    COUNT(*) compensations,
    SUM(Amount) total_amount,
    AVG(Amount) avg_amount
FROM BI_DB_dbo.BI_DB_BO_Generated_Compensations
WHERE Time >= '2026-01-01'
GROUP BY Category
ORDER BY total_amount DESC
```

**Compensation by regulation**
```sql
SELECT
    Regulation,
    COUNT(*) compensations,
    SUM(Amount) total_amount
FROM BI_DB_dbo.BI_DB_BO_Generated_Compensations
WHERE Time >= '2026-04-01'
  AND Time < '2026-05-01'
GROUP BY Regulation
ORDER BY total_amount DESC
```

---

## 8. Atlassian / Change History

| Reference | Date | Author | Change |
|-----------|------|--------|--------|
| Original | ~2021-01-01 | Unknown | Initial creation — BO compensation log from History.Credit CreditTypeID=6 |
