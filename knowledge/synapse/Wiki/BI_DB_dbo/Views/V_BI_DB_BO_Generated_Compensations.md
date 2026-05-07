# BI_DB_dbo.V_BI_DB_BO_Generated_Compensations

**Schema**: BI_DB_dbo | **UC Target**: `general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations`
**Row count**: ~27.5M (2021-01-01 → 2026-05-06) | **Refresh**: daily (Append generic pipeline)
**Type**: VIEW | **Base table**: `BI_DB_dbo.BI_DB_BO_Generated_Compensations`

---

## 1. Business Meaning

Spark-friendly **column-renaming view** over `BI_DB_BO_Generated_Compensations`. The base table holds back-office compensation events (CreditTypeID=6 from `etoro.History.Credit`) — manual or system-triggered credit entries applied to customer accounts by eToro's back-office operations team. One row per compensation event.

This view exists **solely** to rename the two space-containing columns of the base table to underscore-safe identifiers compatible with Spark/Unity Catalog and BI-tool SQL generators:

| Base column | View column |
|-------------|-------------|
| `[Player Level]` | `Player_level` |
| `[Country (Reg Form)]` | `Country_Reg_Form` |

All other 11 columns are passthrough — values are unchanged.

---

## 2. View Definition

```sql
CREATE VIEW [BI_DB_dbo].[V_BI_DB_BO_Generated_Compensations] AS
SELECT
    [CID]
  , [Amount]
  , [Type]
  , [Time]
  , [Description]
  , [Category]
  , [Reason]
  , [Manager]
  , [Affiliate]
  , [Player Level]            AS 'Player_level'
  , [Country (Reg Form)]      AS 'Country_Reg_Form'
  , [Regulation]
  , [UpdateDate]
FROM [BI_DB_dbo].[BI_DB_BO_Generated_Compensations];
```

No filter, no DISTINCT, no aggregation — pure column projection / rename.

---

## 3. Lineage

| Layer | Object |
|-------|--------|
| Source | `etoro.History.Credit` (CreditTypeID = 6) — production DB `etoroDB-REAL` |
| Stage | `BI_DB_dbo.External_etoro_History_Credit_Yesterday` |
| Writer | `BI_DB_dbo.SP_BO_Generated_Compensations` (daily, Priority 0) |
| Base table | `BI_DB_dbo.BI_DB_BO_Generated_Compensations` (~26.8M rows; HEAP, HASH(CID)) |
| **This view** | `V_BI_DB_BO_Generated_Compensations` — column rename only |
| Generic Pipeline | Append, daily → UC |
| UC target | `general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations` |

For full business context, ETL semantics, known SP bugs (e.g. `Manager` no-space concat, `Reason` ~87% NULL), category logic, and exclusions, see the base table wiki: [BI_DB_BO_Generated_Compensations.md](../Tables/BI_DB_BO_Generated_Compensations.md).

---

## 4. Query Advisory

### 4.1 Use This View From UC / Spark
This view is the **canonical UC entry point** for BO compensation data. The base table is not exposed to UC.

### 4.2 Column Renames are the Only Difference
- `Player_level` ⇔ `[Player Level]`
- `Country_Reg_Form` ⇔ `[Country (Reg Form)]`

Both columns hold identical data to the base. Refer to base wiki for value semantics (Player_level: e.g. 'Bronze', 'Silver'; Country_Reg_Form: full country name from registration form, not ISO code).

### 4.3 Manager Column — Known Bug
Inherited from base: `Manager` is `CONCAT(FirstName, '', LastName)` — empty separator (not space). Names appear like `'JohnDoe'`. Do not split on space.

### 4.4 Reason ~87% NULL
Inherited from base: `Reason` (from `Dim_MoveMoneyReason`) is sparsely populated. Always handle NULL.

### 4.5 Type Always 'Compensation'
Base SP filters CreditTypeID=6 only, so `Type` is functionally constant. No analytical use for segmentation.

### 4.6 Time vs UpdateDate
- `Time` = the compensation event datetime (from `History.Credit.Occurred`) — use for event-based analysis
- `UpdateDate` = batch ETL insert timestamp (`GETDATE()` at write time) — use only for ETL audit

---

## 5. Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | CID | int NOT NULL | Customer ID who received the compensation. Joins to `DWH_dbo.Dim_Customer.CID`. Distribution column on the base table. |
| 2 | Amount | decimal(16,2) | Compensation amount in customer-account currency (typically USD). CAST from `History.Credit.Payment`. |
| 3 | Type | varchar(50) | Credit type label — always 'Compensation' (CreditTypeID=6 filter applied at SP). LTRIM/RTRIM applied. |
| 4 | Time | datetime NOT NULL | Datetime of the compensation event. From `History.Credit.Occurred`. Primary event timestamp for analytics. |
| 5 | Description | varchar(255) | Free-text compensation description entered by the back-office agent. May be empty. |
| 6 | Category | varchar(MAX) | Compensation category label from the BO `CompensationReason` dictionary. NULL if `CompensationReasonID` not resolvable. |
| 7 | Reason | varchar(30) | Secondary reason label from `DWH_dbo.Dim_MoveMoneyReason`. ~87% NULL — only set when `MoveMoneyReasonID` is non-null on the source row. |
| 8 | Manager | nvarchar(202) | BO agent who issued the compensation — `CONCAT(FirstName, '', LastName)` (no space — known SP bug). Use as opaque string. |
| 9 | Affiliate | int | Affiliate ID associated with the customer at compensation time. From `Dim_Customer.AffiliateID`. NULL for unaffiliated customers. |
| 10 | Player_level | varchar(50) | Customer player-level name at compensation time (e.g., 'Bronze', 'Silver', 'Platinum'). Renamed from base `[Player Level]`. |
| 11 | Country_Reg_Form | varchar(50) | Country name from customer's registration form (full name, NOT ISO code). Renamed from base `[Country (Reg Form)]`. |
| 12 | Regulation | varchar(50) | Regulatory jurisdiction of the customer's account (e.g., 'CySEC', 'FCA', 'ASIC', 'FSA Seychelles'). |
| 13 | UpdateDate | datetime NOT NULL | Datetime when this row was inserted by the writer SP (`GETDATE()` at INSERT). ETL metadata, not the event time. |

---

## 6. Sample Queries

```sql
-- Daily compensation volume / amount
SELECT
    CAST(Time AS DATE) AS comp_date,
    COUNT(*) AS num_compensations,
    SUM(Amount) AS total_amount
FROM main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations
WHERE Time >= '2026-04-01'
GROUP BY CAST(Time AS DATE)
ORDER BY comp_date;
```

```sql
-- Top compensation categories by total amount (last 90 days)
SELECT Category, COUNT(*) AS n, SUM(Amount) AS total_amount
FROM main.general.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_bo_generated_compensations
WHERE Time >= current_date() - INTERVAL 90 DAYS
GROUP BY Category
ORDER BY total_amount DESC
LIMIT 20;
```

---

*Generated as part of Wave 2 medium-priority documentation effort. For full base-table context see [`BI_DB_BO_Generated_Compensations.md`](../Tables/BI_DB_BO_Generated_Compensations.md).*
