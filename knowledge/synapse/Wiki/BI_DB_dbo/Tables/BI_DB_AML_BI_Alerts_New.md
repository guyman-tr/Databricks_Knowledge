# BI_DB_dbo.BI_DB_AML_BI_Alerts_New

> 273,100-row accumulating daily AML alert log tracking compliance rule violations per customer (2024-02-01 to 2026-04-12), generated daily by SP_AML_BI_Alerts_New (Pavlina Masoura). Each row is a single alert event: one customer triggering one alert rule on one date. The table accumulates over time — only that day's rows are deleted and re-inserted on each run, preserving the history. 30+ distinct alert types span 4 categories: OnBoarding, MIMO-Deposit, MIMO-Deposits, and MIMO-Cashouts.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: DWH_dbo.Fact_BillingDeposit, Fact_BillingWithdraw, Fact_SnapshotCustomer, BI_DB_KYC_Panel, eMoney_dbo.eMoney_Fact_Transaction_Status, External_RiskClassification |
| **Refresh** | Daily (SB_Daily); SP_AML_BI_Alerts_New @Date |
| **Load Pattern** | DELETE WHERE AlertDate=@Date + INSERT (accumulating — historical alert rows preserved) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **OpsDB Priority** | 0 (base layer, SB_Daily) |

---

## 1. Business Meaning

BI_DB_AML_BI_Alerts_New is the primary AML (Anti-Money Laundering) alert register for eToro's compliance team. It captures daily alert events where customers trigger AML monitoring rules. Each row represents one alert: one customer (CID), one alert type (e.g., "AML1014: 12 months Deposits > 100K$"), on one date. The table is accumulating — DELETE+INSERT only affects today's date, so the full alert history is preserved.

The table covers 13 regulatory jurisdictions, with CySEC leading at 53.8% of alerts, followed by FCA (17.7%), FSA Seychelles (11.1%), ASIC & GAML (9.9%), and FSRA (5.6%). The most common alert type is AML1015 (POB or Citizenship mismatches, 20.6%), followed by AML1005 (income/deposit mismatch, 14.4%) and OB14US (US incoming funds geo mismatch, 13.8%).

The SP was written and is actively maintained by Pavlina Masoura, with changes logged through 2026-03-30. Key changes include FSRA additions (2024-08-14), GEO005 proxy exclusion (2025-01-23), EEA/non-EEA medium risk logic for AML1014 (2026-02-06), new YOUNG_ETM and HIGHRISK001_ETM alerts (2026-02-16 refactor), and AML_NY001/002 structuring alerts (2026-02-26).

The alert feed is consumed by AML case management and compliance reporting workflows. `Total_Alerts_of_TheCategory` tracks how many times each alert has previously fired for a given customer+alert-type pair, enabling analysts to identify repeat offenders.

**Population filter**: Valid customers (IsValidCustomer=1), depositors (IsDepositor=1), VerificationLevelID ≥ 2, PlayerStatusID NOT IN (2, 4). Snapshots taken from Fact_SnapshotCustomer using SCD2 range.

---

## 2. Business Logic

### 2.1 Alert Architecture — DELETE+INSERT Accumulating Pattern

**What**: The SP deletes and re-inserts all rows for @Date. Prior dates are preserved in the table indefinitely, creating a full audit trail.
**Columns Involved**: AlertDate (deletion key), all columns (inserted)
**Rules**:
- DELETE WHERE AlertDate = @Date
- INSERT: generates all matching alerts for @Date across all active rule branches
- No TRUNCATE — rows for prior dates are never touched
- This means the table grows by the number of alerts triggered each day

### 2.2 Alert Categories

**What**: 4 alert categories group related alert types for operational routing.
**Columns Involved**: AlertCategory, AlertType
**Rules**:
- `OnBoarding`: KYC/identity validation issues — AML1001, AML1004, AML1015, OB6US, OB12-FINRA, SOI001, SOI002, ALL0001, HIGHRISK001_ETM, YOUNG_ETM001, EP_ETM001, EP_ETM002, EP_ETM003
- `MIMO - Deposit`: Deposit flow monitoring — AML1002B, AML1002B_ASIC, AML1003, AML1006, AML1006_HRC, AML1014, AML_NY001, AML_NY002, DC2US variants, DEP001, DEP002, DEP004, GEO005, OB1US, OB14US, OB16US, RUS_LOG1 (deposits)
- `MIMO - Deposits`: AML1005 (income vs deposits), AML1018, SOI010, AGE001, RUS_LOG1 (deposit login variant)
- `MIMO - Cashouts`: AML1008 (KYC vs withdrawal country), RUS_LOG1 (cashouts)
- NOTE: SP has minor spacing inconsistency — 'MIMO - Deposit' vs 'MIMO - Deposits' are two distinct category strings; use exact match in WHERE clauses

### 2.3 Alert Type Firing Logic — First-Fire vs. Repeat

**What**: For some alert types, only first-ever triggers are inserted (Total_Alerts_of_TheCategory=1 filter). Others always insert regardless of history.
**Columns Involved**: Total_Alerts_of_TheCategory, AlertType
**Rules**:
- **First-fire only** (WHERE Total_Alerts_of_TheCategory=1): AML1001, AML1002B, AML1002B_ASIC, AML1015, AML1005, DEP001, DEP002, SOI001, SOI002, DC2US variants, SOI010, AGE001, OB6US, AML1004, HIGHRISK001_ETM, EP_ETM001, EP_ETM002, EP_ETM003
- **Always insert** (no first-fire filter): AML1014, ALL0001, GEO005, AML_NY001, AML_NY002, OB16US, OB1US, OB12-FINRA, DC4US, OB14US, AML1006_HRC, AML1006, AML1008, AML1018, AML1013, RUS_LOG1 variants, DEP004, AML1003, YOUNG_ETM001
- **Deactivated** (commented out in SP): HIGHRISK001, YOUNG001, EP001, EP002

### 2.4 Cumulative Alert Counter

**What**: Total_Alerts_of_TheCategory is a cumulative count of how many times this alert type has fired for this CID across all historical dates.
**Columns Involved**: Total_Alerts_of_TheCategory
**Rules**:
- Computed as: COUNT(existing BI_DB_AML_BI_Alerts_New rows WHERE CID=this AND AlertType=this) + 1
- Value 1 = first-ever alert for this customer+type combination
- Higher values indicate repeat offenders — useful for escalation prioritization
- Range in live data: 1 to 368+

### 2.5 Key Alert Rules (Selected)

**What**: Representative alert rule definitions from the SP.
**Columns Involved**: AlertType, AlertCategory
**Rules**:
- **AML1014**: 12-month gross deposits > $100K; covers EEA and non-EEA medium/high risk; includes FSRA (added 2024-08-14)
- **AML1015**: Place of Birth or Citizenship country ≠ KYC country on file
- **AML1005**: Annual income + liquid assets (KYC Q10+Q11) < yearly deposit amount
- **OB14US**: Incoming funds source country mismatches US MOP (all regulations vs US deposit)
- **AML1006/AML1006_HRC**: KYC country ≠ BIN card country (HRC = High Risk Country variant)
- **GEO005**: Recent logins from HRC Rank 1 countries (proxy-excluded after 2025-01-23)
- **EP_ETM001/002/003**: Lifetime net flows (including eTM) exceed economic profile threshold or $500K/$2M thresholds (uses KYC Panel Q10/Q11 for personalized threshold)
- **AML_NY001**: PWMB/wire structuring — ≥2 transactions in 72h, sum ≥$10K, each < $10K
- **AML_NY002**: PWMB/wire structuring — ≥3 transactions in 24h, sum ≥$10K, each < $10K
- **YOUNG_ETM001**: Net flows ≥ $50K with age ≤ 22 (changed from $500K threshold on 2026-03-30)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. No distribution key — this table has no dominant join column that would benefit from HASH distribution. The alerts table is queried by AML analysts who typically filter on AlertDate, AlertCategory, or AlertType, not CID primarily. For large date-range scans, performance is adequate given the ~273K total row count.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All active alerts for today | `WHERE AlertDate = CAST(GETDATE() AS DATE)` |
| First-ever alerts for a customer | `WHERE Total_Alerts_of_TheCategory = 1` |
| Repeat alerts (chronic offenders) | `WHERE Total_Alerts_of_TheCategory >= 5 AND AlertType = 'AML1014: ...'` |
| High-risk deposit flow alerts only | `WHERE AlertCategory = 'MIMO - Deposit'` |
| Active customer alerts by regulation | `WHERE Regulation = 'CySEC' AND AlertDate >= DATEADD(MONTH,-3,GETDATE())` |
| KYC onboarding issues | `WHERE AlertCategory = 'OnBoarding' AND AlertDate >= '2026-01-01'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON a.CID = dc.RealCID | Customer details (email, name, account manager) |
| DWH_dbo.Fact_SnapshotCustomer | ON a.CID = fsc.RealCID AND fsc.DateRangeID ... | Current customer state |
| BI_DB_dbo.BI_DB_AMLPeriodicReview | ON a.CID = pr.RealCID | Check if customer is already under periodic review |

### 3.4 Gotchas

- **AlertCategory spelling variants**: 'MIMO - Deposit' and 'MIMO - Deposits' are two distinct strings (different suffix 's'). One row has NULL/blank AlertCategory (data artefact).
- **AlertID is not stable**: NEWID() is generated fresh on each SP run. If the same alert fires on two different dates for the same customer, the AlertIDs are different.
- **Total_Alerts_of_TheCategory counts PRIOR rows only**: On the day of insertion, it reflects the count before today's INSERT. The current day's row is NOT included in the count.
- **Deactivated alerts**: HIGHRISK001, YOUNG001, EP001, EP002 are commented out in the SP and will NOT appear in new data from 2026-03-16 onward. However, older rows with these AlertTypes exist in the table from before deactivation.
- **NYDFSFINRA vs FinCEN+FINRA**: Two similar but distinct Regulation values exist for US-regulated customers. Added 'NYDFSFINRA' on 2026-01-07 (ticket SR-350874).
- **Accumulating pattern vs. date-scoped tables**: Unlike TRUNCATE+INSERT tables, this accumulates history. COUNT(*) includes all dates. Always filter on AlertDate for operational queries.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream wiki (DWH_dbo or production DB_Schema). Highest confidence. |
| Tier 2 | Derived from ETL SP code, DDL analysis, or DWH dimension join logic. High confidence. |
| Tier 3 | Inferred from column name, data sample, or business context. Medium confidence. |
| Tier 4 | Best available knowledge — limited confidence, requires review. |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. The customer who triggered the AML alert. Passthrough from DWH_dbo. (Tier 1 — Customer.CustomerStatic) |
| 2 | AlertID | nvarchar(max) | YES | Synthetic UUID (NEWID()) generated at INSERT time for each alert row. Not stable across runs — if the same alert re-fires on a different date, a new UUID is assigned. Used as a unique row identifier for case management workflow references. (Tier 2 — SP_AML_BI_Alerts_New) |
| 3 | AlertCategory | nvarchar(max) | YES | High-level AML process category grouping the alert. Values: 'OnBoarding' (KYC/identity validation, 36.5%), 'MIMO - Deposit' (deposit flow monitoring, 48.0%), 'MIMO - Deposits' (income vs deposit analysis, 14.6%), 'MIMO - Cashouts' (withdrawal monitoring, 1.0%). NOTE: 'Deposit' vs 'Deposits' are two distinct strings — use exact match. (Tier 2 — SP_AML_BI_Alerts_New) |
| 4 | AlertType | nvarchar(max) | YES | Specific AML alert rule code and description. 30+ active codes. Top values: 'AML1015: POB or Citizenship <> KYC country' (20.6%), 'AML1005: Liquid Assets + Annual Income less than YearlyDeposits' (14.4%), 'OB14US: Incoming Funds Geo Mismatch (ALL reg Vs US deposit, US MOP)' (13.8%), 'AML1006: KYCCountry <> BinCountry' (10.7%), 'AML1014: 12 months Deposits > 100K$' (9.5%), 'AML1001: High Risk Score and lifetime Depostits > 50K' (7.3%), 'GEO005: Logins from HRC Rank 1' (6.1%), 'ALL0001:All Alerts' (5.6%). Note 'Depostits' typo in AML1001 name — hardcoded in SP. (Tier 2 — SP_AML_BI_Alerts_New) |
| 5 | Total_Alerts_of_TheCategory | int | YES | Cumulative count of times this specific AlertType has previously fired for this CID, plus 1 for the current row. Value=1 means first-ever occurrence for this customer+alert-type pair. Range: 1–368+. High values indicate chronically alerted customers. Computed against existing table rows at INSERT time (self-reference). (Tier 2 — SP_AML_BI_Alerts_New) |
| 6 | AlertDate | date | YES | The date for which the alert was generated, equal to the @Date parameter passed to SP_AML_BI_Alerts_New. Represents the business date of the alert event. Range: 2024-02-01 to 2026-04-12. DELETE+INSERT uses AlertDate as the idempotency key. (Tier 2 — SP_AML_BI_Alerts_New) |
| 7 | Regulation | nvarchar(max) | YES | Customer's regulatory jurisdiction name at the time the alert was generated. Snapshot from DWH_dbo.Dim_Regulation.Name via Fact_SnapshotCustomer JOIN. Values: CySEC (53.8%), FCA (17.7%), FSA Seychelles (11.1%), ASIC & GAML (9.9%), FSRA (5.6%), FinCEN+FINRA (1.7%), ASIC (0.2%), MAS, BVI, NYDFSFINRA, FinCEN, eToroUS. (Tier 2 — SP_AML_BI_Alerts_New) |
| 8 | Country | nvarchar(max) | YES | Customer's KYC country name at the time the alert was generated. Snapshot from DWH_dbo.Dim_Country.Name via Fact_SnapshotCustomer JOIN. Reflects country at ETL run time, not at deposit/event time. (Tier 2 — SP_AML_BI_Alerts_New) |
| 9 | PlayerStatus | nvarchar(max) | YES | Customer's player status name at the time the alert was generated. Snapshot from DWH_dbo.Dim_PlayerStatus.Name. Population filter excludes PlayerStatusID 2 (Deactivated) and 4 (Cancelled). (Tier 2 — SP_AML_BI_Alerts_New) |
| 10 | Club | nvarchar(max) | YES | Customer's club/loyalty tier name at the time the alert was generated. Snapshot from DWH_dbo.Dim_PlayerLevel.Name. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 — SP_AML_BI_Alerts_New) |
| 11 | AccountType | nvarchar(max) | YES | Customer's account type name at the time the alert was generated. Snapshot from DWH_dbo.Dim_AccountType.Name. Primarily 'Private'; also Corporate and other types. (Tier 2 — SP_AML_BI_Alerts_New) |
| 12 | RiskScoreName | nvarchar(max) | YES | Customer's AML risk classification label from the Risk Classification service. Values: Low, Medium, High, or NULL (not yet classified). Sourced from External_RiskClassification_dbo_V_RiskClassificationDataLake at SP run time. NULL means no risk score available (LEFT JOIN). (Tier 2 — SP_AML_BI_Alerts_New) |
| 13 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Snapshot from DWH_dbo.Dim_Customer.HasWallet at alert generation time. Used in GEO005, AML1014, and other rule eligibility filters. Distribution: 0=81.4%, 1=18.6%. (Tier 1 — BackOffice.Customer) |
| 14 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT. (Tier — Blacklist/ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer (via Fact_SnapshotCustomer) | RealCID | Passthrough |
| HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough (current state) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Snapshot JOIN at alert time |
| Country | DWH_dbo.Dim_Country | Name | Snapshot JOIN at alert time |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Snapshot JOIN at alert time |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Snapshot JOIN at alert time |
| AccountType | DWH_dbo.Dim_AccountType | Name | Snapshot JOIN at alert time |
| RiskScoreName | External_RiskClassification | RiskScoreName | Passthrough (current score) |
| AlertID | ETL (NEWID()) | — | Synthetic UUID |
| AlertCategory, AlertType | SP rule branches | — | Hardcoded per rule |
| AlertDate | @Date parameter | — | = @Date |
| Total_Alerts_of_TheCategory | BI_DB_AML_BI_Alerts_New (self) | — | COUNT(prior)+1 |
| UpdateDate | ETL (GETDATE()) | — | GETDATE() |

### 5.2 ETL Pipeline

```
External_RiskClassification_dbo_V_RiskClassificationDataLake (#risk_score)
DWH_dbo.Fact_BillingDeposit (deposit cumulative amounts + threshold pivots)
DWH_dbo.Fact_BillingWithdraw (net flow calculations)
eMoney_dbo.eMoney_Fact_Transaction_Status (eTM net flows)
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (population snapshot @DateID)
DWH_dbo.Dim_Regulation/Country/PlayerStatus/PlayerLevel/AccountType/Customer
BI_DB_dbo.BI_DB_KYC_Panel (Q10/Q11 economic profile thresholds)
BI_DB_dbo.BI_DB_AML_BI_Alerts_New (self — Total_Alerts counter)
  |-- SP_AML_BI_Alerts_New @Date ---|
     30+ alert rule branches → #final UNION ALL
     DELETE WHERE AlertDate=@Date
     INSERT with Total_Alerts counter + UpdateDate=GETDATE()
  v
BI_DB_dbo.BI_DB_AML_BI_Alerts_New (273K rows, accumulating, 2024-02-01 to present)
  UC Target: Not Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer identity and profile |
| CID | DWH_dbo.Fact_SnapshotCustomer (RealCID) | Customer daily snapshot for eligibility filtering |
| CID | BI_DB_dbo.BI_DB_KYC_Panel | Q10/Q11 economic profile answers for EP threshold alerts |
| CID (self) | BI_DB_dbo.BI_DB_AML_BI_Alerts_New | Total_Alerts_of_TheCategory counter via self-JOIN |

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| BI_DB_dbo.BI_DB_AMLPeriodicReview | RealCID | Periodic review queue may be driven by alert history |
| AML case management systems | CID + AlertType | Alert feed consumed by compliance team workflows |

---

## 7. Sample Queries

### Today's OnBoarding Alerts (KYC Issues)
```sql
SELECT CID, AlertType, AlertDate, Country, Regulation, RiskScoreName
FROM [BI_DB_dbo].[BI_DB_AML_BI_Alerts_New]
WHERE AlertDate = CAST(GETDATE() AS DATE)
  AND AlertCategory = 'OnBoarding'
ORDER BY Total_Alerts_of_TheCategory DESC;
```

### Repeat High-Volume Deposit Offenders
```sql
SELECT CID, AlertType, MAX(Total_Alerts_of_TheCategory) AS MaxAlerts, 
       COUNT(*) AS AlertDates, MAX(AlertDate) AS LastAlertDate
FROM [BI_DB_dbo].[BI_DB_AML_BI_Alerts_New]
WHERE AlertCategory = 'MIMO - Deposit'
GROUP BY CID, AlertType
HAVING MAX(Total_Alerts_of_TheCategory) >= 10
ORDER BY MaxAlerts DESC;
```

### AML1014 Alert Trends by Month
```sql
SELECT EOMONTH(AlertDate) AS MonthEnd, Regulation, COUNT(*) AS AlertCount
FROM [BI_DB_dbo].[BI_DB_AML_BI_Alerts_New]
WHERE AlertType = 'AML1014: 12 months Deposits > 100K$'
  AND AlertDate >= '2025-01-01'
GROUP BY EOMONTH(AlertDate), Regulation
ORDER BY MonthEnd DESC, AlertCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence or Jira sources confirmed for this object. SP change log (in SP header) is the primary documentation source: SP_AML_BI_Alerts_New maintained by Pavlina Masoura from 2024-07-04 through 2026-03-30.

---

*Generated: 2026-04-22 | Quality: 9.2/10 | Phases: 13/14*
*Tiers: 2 T1, 11 T2, 0 T3, 0 T4 | Elements: 14/14 | Logic: 9/10 | Shape: 10/10*
*Object: BI_DB_dbo.BI_DB_AML_BI_Alerts_New | Type: Table | Production Source: SP_AML_BI_Alerts_New (multi-source DWH_dbo)*
