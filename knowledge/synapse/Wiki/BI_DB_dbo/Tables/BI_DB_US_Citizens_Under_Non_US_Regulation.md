# BI_DB_dbo.BI_DB_US_Citizens_Under_Non_US_Regulation

> 4,941-row compliance accumulation table identifying US citizens or US TIN holders who are registered under non-US regulatory jurisdictions, from November 2024 to present. Each row represents a customer detected as having US ties (POB=USA or TIN country=USA) while NOT being under US regulation (FinCEN/FINRA/NYDFS). Refreshed daily via SP_US_Citizens_Under_Non_US_Regulation with accumulation pattern (only new CIDs inserted).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (POB/regulation) + BI_DB_Tax_Compliance_TIN (TIN country) + BI_DB_CIDFirstDates (activity dates) + Dim_Regulation/Country/PlayerStatus |
| **Refresh** | Daily (SP_US_Citizens_Under_Non_US_Regulation, accumulation — only new CIDs inserted, SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateRelevance ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_US_Citizens_Under_Non_US_Regulation` is a 4,941-row compliance accumulation table designed to identify eToro customers who show US citizenship indicators but are registered under non-US regulatory jurisdictions. This is a regulatory risk flag — US citizens trading on non-US regulated entities may trigger SEC/FINRA compliance obligations.

The SP detects US ties through two independent signals:
1. **Place of Birth (POB)**: Dim_Customer.POBCountryID = 219 (USA)
2. **TIN Country**: BI_DB_Tax_Compliance_TIN.TIN_CountryID = 219 (USA)

Both paths exclude customers already under US regulation (RegulationID NOT IN 6,7,8,12 — which covers FinCEN, FINRA, FinCEN+FINRA, and NYDFS+FINRA). The FULL OUTER JOIN combines both detection paths, and the accumulation pattern only inserts NEW customers not already in the table. This means DateRelevance shows when the customer was first detected, creating a growing compliance watchlist.

Distribution: POB only=2,210, TIN only=2,475, both POB+TIN=256 customers.

---

## 2. Business Logic

### 2.1 Dual Detection Path

**What**: Two independent US indicator sources are combined.
**Columns Involved**: `POB`, `TaxCountry`
**Rules**:
- POB='Yes': Customer's Place of Birth country is USA (POBCountryID=219 in Dim_Customer)
- TaxCountry='Yes': Customer has a US TIN in BI_DB_Tax_Compliance_TIN (TIN_CountryID=219)
- Both can be 'Yes' (256 customers) — strongest US indicator
- FULL OUTER JOIN ensures customers detected by either path are included

### 2.2 Regulation Exclusion

**What**: Customers already under US regulation are excluded.
**Columns Involved**: `CurrentRegulation`
**Rules**:
- RegulationID NOT IN (6, 7, 8, 12):
  - 6 = FinCEN (US)
  - 7 = FINRA (US)
  - 8 = FinCEN+FINRA (US)
  - 12 = NYDFS+FINRA (US)
- Must also be: VerificationLevelID=3 (fully verified) AND IsValidCustomer=1

### 2.3 Accumulation Pattern (New CIDs Only)

**What**: Table grows over time — only NEW detections are inserted.
**Columns Involved**: `CID`, `DateRelevance`
**Rules**:
- LEFT JOIN to existing table WHERE u.CID IS NULL — only inserts CIDs not already present
- DateRelevance = @Date when the customer was first detected
- DELETE by DateRelevance=@Date allows same-day reprocessing, but does NOT delete historical rows
- This creates a historical watchlist: once a customer appears, they stay forever

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateRelevance ASC. Small table (5K rows) — full scan acceptable. Index supports date-range queries for "new detections this week/month."

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| New detections this month | `WHERE DateRelevance >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)` |
| US POB under CySEC regulation | `WHERE POB = 'Yes' AND CurrentRegulation = 'CySEC'` |
| Both POB and TIN indicators | `WHERE POB = 'Yes' AND TaxCountry = 'Yes'` |
| Active accounts (not blocked) | `WHERE PlayerStatus = 'Normal'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer attributes, current verification |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID | Full customer lifecycle data |

### 3.4 Gotchas

- **Accumulation, not snapshot**: Unlike most BI_DB tables, this table accumulates over time. DateRelevance is the detection date, not the current date. Historical rows are not deleted
- **NYDFS+FINRA in sample data**: Some recent rows show CurrentRegulation='NYDFS+FINRA' — these may have been re-regulated AFTER initial detection under a non-US regulation
- **Designated_Regulation_DB**: This is the regulation assigned to the customer's KYC country (not the customer's personal regulation). Different from DesignatedRegulation

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL infrastructure / standard metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Customer ID — platform-internal primary key. COALESCE(POB.RealCID, TIN.RealCID). From Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | LastLoggedIn | datetime | YES | Last login timestamp. From BI_DB_CIDFirstDates.LastLoggedIn. Snapshot at time of detection, not updated. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation, BI_DB_CIDFirstDates) |
| 3 | VerificationLevel3Date | datetime | YES | Date customer reached full verification (Level 3). From BI_DB_CIDFirstDates. Snapshot at detection time. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation, BI_DB_CIDFirstDates) |
| 4 | PlayerStatus | varchar(200) | YES | eToro platform account status at detection time. From Dim_PlayerStatus.Name. Normal, Blocked, Blocked Upon Request, etc. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation, Dim_PlayerStatus) |
| 5 | CurrentRegulation | varchar(200) | YES | Customer's primary regulatory jurisdiction at detection time. From Dim_Regulation.Name via RegulationID. Always non-US (filtered: NOT IN 6,7,8,12). Examples: CySEC, BVI, ASIC & GAML, FCA. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation, Dim_Regulation) |
| 6 | DesignatedRegulation | varchar(200) | YES | Customer's designated regulatory jurisdiction at detection time. From Dim_Regulation.Name via DesignatedRegulationID. May differ from CurrentRegulation. NULL if no designated regulation. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation, Dim_Regulation) |
| 7 | POB | varchar(50) | YES | Place of Birth USA indicator. 'Yes' if POBCountryID=219 (USA) in Dim_Customer. 'No' otherwise. 2,466 customers have POB='Yes'. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation) |
| 8 | TaxCountry | varchar(50) | YES | US TIN indicator. 'Yes' if customer has TIN_CountryID=219 in BI_DB_Tax_Compliance_TIN. 'No' otherwise. 2,731 customers have TaxCountry='Yes'. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation) |
| 9 | DateRelevance | date | YES | Date when this customer was first detected as a US citizen under non-US regulation. Accumulation anchor — not updated on subsequent runs. Range: 2024-11-16 to present. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation) |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted (GETDATE()). (Tier 5 — SP_US_Citizens_Under_Non_US_Regulation) |
| 11 | Designated_Regulation_DB | varchar(250) | YES | Country-level regulation name. From Dim_Regulation.Name via Dim_Country.RegulationID for the customer's KYC country. Different from DesignatedRegulation (which is the customer's personal designation). (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation, Dim_Country → Dim_Regulation) |
| 12 | KYC_Country | varchar(250) | YES | Customer's KYC country name. From Dim_Country.Name via CountryID. Examples: Spain, Australia, United States, United Kingdom. (Tier 2 — SP_US_Citizens_Under_Non_US_Regulation, Dim_Country) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID | Dim_Customer | RealCID | COALESCE from two detection paths |
| LastLoggedIn | BI_DB_CIDFirstDates | LastLoggedIn | COALESCE |
| VerificationLevel3Date | BI_DB_CIDFirstDates | VerificationLevel3Date | COALESCE |
| PlayerStatus | Dim_PlayerStatus | Name | JOIN |
| CurrentRegulation | Dim_Regulation | Name | JOIN on RegulationID |
| DesignatedRegulation | Dim_Regulation | Name | JOIN on DesignatedRegulationID |
| POB | Derived | POBCountryID=219 | 'Yes'/'No' |
| TaxCountry | Derived | TIN_CountryID=219 | 'Yes'/'No' |
| DateRelevance | Derived | @Date | Detection date |
| Designated_Regulation_DB | Dim_Regulation | Name | JOIN on Dim_Country.RegulationID |
| KYC_Country | Dim_Country | Name | JOIN on CountryID |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
Path 1: POB Detection                       Path 2: TIN Detection
DWH_dbo.Dim_Customer                        BI_DB_dbo.BI_DB_Tax_Compliance_TIN
  WHERE POBCountryID=219                      WHERE TIN_CountryID=219
  AND RegulationID NOT IN (6,7,8,12)          + DWH_dbo.Dim_Customer (same filters)
  |                                           |
  |-- #pob --|                                |-- #tin --|
             |                                          |
             |------- FULL OUTER JOIN on RealCID -------|
             v
           #final → exclude existing CIDs → #new
             |
             |-- SP_US_Citizens_Under_Non_US_Regulation @date (daily, accumulation) --|
             v
BI_DB_dbo.BI_DB_US_Citizens_Under_Non_US_Regulation (4,941 rows, growing)
  |
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (POB, regulation) |
| TaxCountry | BI_DB_dbo.BI_DB_Tax_Compliance_TIN | US TIN detection |
| LastLoggedIn / VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | Customer lifecycle dates |

### 6.2 Referenced By (other objects point to this)

No known consumers.

---

## 7. Sample Queries

### 7.1 New US Citizen Detections This Month

```sql
SELECT
    CID, POB, TaxCountry,
    CurrentRegulation, DesignatedRegulation,
    PlayerStatus, KYC_Country,
    DateRelevance
FROM BI_DB_dbo.BI_DB_US_Citizens_Under_Non_US_Regulation
WHERE DateRelevance >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
ORDER BY DateRelevance DESC
```

### 7.2 Active Accounts with Both US Indicators

```sql
SELECT
    CID, CurrentRegulation, KYC_Country,
    LastLoggedIn, VerificationLevel3Date
FROM BI_DB_dbo.BI_DB_US_Citizens_Under_Non_US_Regulation
WHERE POB = 'Yes' AND TaxCountry = 'Yes'
    AND PlayerStatus = 'Normal'
ORDER BY LastLoggedIn DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 1 T1, 10 T2, 0 T3, 0 T4, 1 T5 | Elements: 12/12, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_US_Citizens_Under_Non_US_Regulation | Type: Table | Production Source: Dim_Customer (POB) + Tax_Compliance_TIN (TIN) + CIDFirstDates*
