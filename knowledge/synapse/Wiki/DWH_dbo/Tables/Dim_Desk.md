# DWH_dbo.Dim_Desk

> Mapping table that assigns each (CountryID, LanguageID) customer combination to a named customer-facing desk (e.g., English, Russian, South & Central America) — used in Tableau Revenue Churn and BI reporting to segment customers by their support/CRM desk assignment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Legacy DWH SQL Server (via DWH_Migration — frozen one-time migration) |
| **Refresh** | None — frozen data, no active ETL |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (LanguageID ASC, CountryID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_Desk` is a composite-key mapping table that assigns each (CountryID, LanguageID) combination to a customer-facing desk. A "desk" is a regional customer relationship management or support team responsible for handling customers from that country/language segment (e.g., Russian-speaking customers regardless of country get the "Russian" desk; customers from France get the "French" desk).

The table contains 6,526 rows covering all supported (CountryID, LanguageID) combinations. There are 10 distinct desks (CFKey 1-10), identified by their CFDesk name: Arabic, China, English, French, German, Italian, Russian, South & Central America, Spanish, and Israel. English is by far the largest desk (3,465 rows — the default for most countries with LanguageID=0).

The table was migrated from the legacy on-premises DWH SQL Server via a one-time DWH_Migration load. InsertDate and UpdateDate are NULL for all rows — no active ETL refreshes this table. It is actively used in the GCP/Tableau Revenue Churn reporting pipeline (`GCP_DataSet_RevenueChurn.Tableau_RevenueChurn_Revenues`), which JOINs it to customer data to segment revenue metrics by desk. Historical BI_DB SPs (SP_CIDFirstDates, SP_ReverseCO_Report, SP_NewContactActivityPerRep, SP_NewBonusReport) also reference it; SP_CIDFirstDates removed Dim_Desk in 2019 in favor of Dim_Country.

---

## 2. Business Logic

### 2.1 Country-Language to Desk Assignment

**What**: Maps the (CountryID, LanguageID) pair from a customer record to the customer-facing desk responsible for that customer segment.

**Columns Involved**: `CountryID`, `LanguageID`, `CFKey`, `CFDesk`

**Rules**:
- The natural key is (CountryID, LanguageID) — the combination determines desk assignment.
- LanguageID=0 appears to be the default (most rows use LanguageID=0 with country-specific desk assignments).
- CFKey is the numeric desk identifier; CFDesk is the human-readable desk name.
- When a customer does not match any row in this table, the LEFT JOIN in reporting SPs returns NULL (no desk assigned).

**Desk Value Map**:
```
CFKey | CFDesk                    | Row Count
  1   | Arabic                    |  234
  2   | China                     |  104
  3   | English                   | 3465
  4   | French                    |  633
  5   | German                    |  318
  6   | Italian                   |  297
  7   | Russian                   |  312
  8   | South & Central America   |  902
  9   | Spanish                   |  235
 10   | Israel                    |   26
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on (LanguageID ASC, CountryID ASC). REPLICATE is correct — 6,526 rows is still a small dimension. The composite clustered index directly matches the typical JOIN pattern `ON CountryID = d.CountryID AND LanguageID = d.LanguageID`.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is exported daily to `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk` as Parquet. No partitioning expected for a 6,526-row reference table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What desk is a customer assigned to? | `LEFT JOIN Dim_Desk d ON c.CountryID = d.CountryID AND c.LanguageID = d.LanguageID` |
| Revenue by desk | JOIN pattern above + `GROUP BY d.CFDesk` |
| Which countries are in the Russian desk? | `WHERE CFDesk = 'Russian'`, JOIN to Dim_Country to get country names |
| Count customers per desk | JOIN Dim_Customer/Dim_CustomerChangeType via CountryID + LanguageID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON Dim_Customer.CountryID = Dim_Desk.CountryID AND Dim_Customer.LanguageID = Dim_Desk.LanguageID | Assign a desk to each customer |
| DWH_dbo.Dim_Country | ON Dim_Country.CountryID = Dim_Desk.CountryID | Enrich desk rows with country name/region |

### 3.4 Gotchas

- **No PK column**: The natural key is the (LanguageID, CountryID) composite. There is no single-column ID for this table. JOINs must use both columns.
- **Static data**: All rows have NULL InsertDate and UpdateDate. The table reflects the desk structure as of the DWH_Migration date (2024-09-16). If desk assignments change in production, this table must be manually updated.
- **SP_CIDFirstDates history**: As of 2019-01-14, Dim_Desk was removed from SP_CIDFirstDates and replaced with Dim_Country. This confirms the table has been partially deprecated — verify which SPs still actively rely on it before making changes.
- **LanguageID=0 as default**: Most rows use LanguageID=0, suggesting language-based desk splitting is the exception rather than the rule. A customer with LanguageID=0 (default) is routed by country only.
- **"CF" prefix meaning**: CFKey and CFDesk likely stand for "Customer Facing" — the customer-facing regional desk in the CRM/CRO organization.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ★★ | Tier 3 | Live data / sampling — verified from actual Synapse table rows |
| ★★ | Tier 3b | DDL structure from SSDT repo — inferred from column name and type |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LanguageID | int | NO | Part of composite natural key. Customer language identifier — matches LanguageID in Dim_Customer. LanguageID=0 is the default (country-only assignment). (Tier 3 — live data, DWH_dbo.Dim_Desk) |
| 2 | CountryID | int | NO | Part of composite natural key. Customer country identifier — matches CountryID in Dim_Customer and Dim_Country. (Tier 3 — live data, DWH_dbo.Dim_Desk) |
| 3 | CFKey | int | NO | Numeric identifier for the customer-facing desk. Values 1-10; see Section 2.1 for the complete value map. "CF" = Customer Facing. (Tier 3 — live data, DWH_dbo.Dim_Desk) |
| 4 | CFDesk | varchar(50) | NO | Human-readable name of the customer-facing desk. Values: Arabic, China, English, French, German, Italian, Russian, South & Central America, Spanish, Israel. Used directly in reports for desk segmentation. (Tier 3 — live data, DWH_dbo.Dim_Desk) |
| 5 | InsertDate | datetime | YES | ETL insert timestamp — always NULL (static migration load, no active ETL). (Tier 3b — SSDT DDL) |
| 6 | UpdateDate | datetime | YES | ETL update timestamp — always NULL (static migration load, no active ETL). (Tier 3b — SSDT DDL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| LanguageID | DWH_Migration.Dim_Desk | LanguageID | Passthrough |
| CountryID | DWH_Migration.Dim_Desk | CountryID | Passthrough |
| CFKey | DWH_Migration.Dim_Desk | CFKey | Passthrough |
| CFDesk | DWH_Migration.Dim_Desk | CFDesk | Passthrough |
| InsertDate | DWH_Migration.Dim_Desk | InsertDate | Passthrough (always NULL) |
| UpdateDate | DWH_Migration.Dim_Desk | UpdateDate | Passthrough (always NULL) |

No upstream production wiki. Source: legacy on-premises DWH SQL Server (migrated September 2024). No etoro DB equivalent found.

### 5.2 ETL Pipeline

```
Legacy DWH SQL Server (on-prem)
  -> One-time DWH_Migration load (2024-09-16)
    -> DWH_Migration.Dim_Desk (staging)
      -> DWH_dbo.Dim_Desk (6526 rows, frozen)
        -> [No active ETL refresh]
        -> Generic Pipeline (daily) -> Gold/sql_dp_prod_we/DWH_dbo/Dim_Desk/
          -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_desk (UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Dim_Desk.CountryID references country dimension for geographic context |
| LanguageID | DWH_dbo.Dim_Language | Dim_Desk.LanguageID references language dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| GCP_DataSet_RevenueChurn.Tableau_RevenueChurn_Revenues | CountryID, LanguageID | LEFT JOIN to assign desk to customers in Tableau Revenue Churn reporting |
| BI_DB_dbo.SP_ReverseCO_Report | CountryID, LanguageID | Desk-level segmentation in reverse cashout report |
| BI_DB_dbo.SP_NewContactActivityPerRep | CountryID, LanguageID | Desk-level segmentation in contact activity reports |
| BI_DB_dbo.SP_NewBonusReport | CountryID, LanguageID | Desk-level segmentation in bonus reporting |

---

## 7. Sample Queries

### 7.1 View desk distribution summary

```sql
SELECT CFKey, CFDesk, COUNT(*) AS CountryLanguageCombinations
FROM DWH_dbo.Dim_Desk
GROUP BY CFKey, CFDesk
ORDER BY CFKey
```

### 7.2 Find which desk handles a specific country

```sql
SELECT d.CFDesk, d.CFKey, d.LanguageID, d.CountryID, c.CountryName
FROM DWH_dbo.Dim_Desk d
JOIN DWH_dbo.Dim_Country c ON d.CountryID = c.CountryID
WHERE d.LanguageID = 0  -- default language assignment
ORDER BY d.CFKey, c.CountryName
```

### 7.3 Enrich customer data with desk assignment

```sql
SELECT
    cust.CID,
    cust.CountryID,
    cust.LanguageID,
    COALESCE(d.CFDesk, 'No Desk Assigned') AS Desk,
    d.CFKey
FROM DWH_dbo.Dim_Customer cust
LEFT JOIN DWH_dbo.Dim_Desk d
    ON cust.CountryID = d.CountryID
    AND cust.LanguageID = d.LanguageID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — static migration table; desk structure may be documented in internal sales/CRM wikis not available via Atlassian MCP.)

---

*Generated: 2026-03-19 | Quality: 7.8/10 (★★★★☆) | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 0 T2b, 4 T3, 2 T3b, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Desk | Type: Table | Production Source: Legacy DWH SQL Server (DWH_Migration)*
