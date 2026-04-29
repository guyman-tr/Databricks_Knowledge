# BI_DB_dbo.BI_DB_Vulnerable_Customers

> 20.6K-row daily snapshot of self-identified vulnerable customers — those who answered "Yes" to KYC question 32 (vulnerability self-declaration, AnswerId=151) since 2021-04-01. Enriched with verification level, dual regulation codes, financial metrics (realized/unrealized equity, closed PnL, open PnL), and MiFID II appropriateness restriction status. TRUNCATE+INSERT daily via SP_Vulnerable_Customers.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_KYC_Questions_Answers_Row_Data + DWH_dbo.Dim_Customer + Dim_Regulation + Dim_Country + BI_DB_CIDFirstDates + V_Liabilities + Dim_Position + ComplianceStateDB via `SP_Vulnerable_Customers` |
| **Refresh** | Daily (TRUNCATE + INSERT — full rebuild) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~20,632 (as of 2026-04-27) |

---

## 1. Business Meaning

`BI_DB_Vulnerable_Customers` tracks customers who have self-identified as vulnerable through the KYC questionnaire. MiFID II and FCA regulations require brokers to identify and monitor vulnerable clients — those whose personal circumstances may negatively impact their ability to manage their trading accounts.

The population is defined by KYC QuestionId=32 with AnswerId=151 (the "Yes, I am a vulnerable client" response) from `BI_DB_KYC_Questions_Answers_Row_Data`, limited to answers since 2021-04-01. Each customer appears once (per GCID) with their latest answer date and enriched financial and compliance data.

The table provides compliance teams with:
- **Customer identity**: GCID and CID for cross-referencing
- **KYC context**: Answer date, answer text (the vulnerability self-declaration)
- **Verification state**: Current verification level, VL2 and VL3 dates
- **Dual regulation**: Both RegulationID (primary) and DesignatedRegulationID (secondary/override) from Dim_Regulation
- **Financial position**: Realized equity, unrealized equity, open PnL from V_Liabilities at yesterday; closed PnL from Dim_Position over the last 365 days
- **Compliance status**: Appropriateness restriction status from ComplianceStateDB (RestrictionStatusReasonID=14, since 2020-05-01) — "Passed" or "Failed"

As of 2026-04-27: 20.6K self-identified vulnerable customers. Answer dates range from 2022-07-06 to 2026-04-10.

---

## 2. Business Logic

### 2.1 Vulnerable Customer Population

**What**: Identifies customers who self-declared as vulnerable via KYC questionnaire.
**Columns Involved**: `GCID`, `CID`, `AnswerText`, `Answer_Date`
**Rules**:
- Source: BI_DB_KYC_Questions_Answers_Row_Data WHERE QuestionId=32 AND AnswerId=151
- OccurredAt >= '20210401' (since April 2021)
- Joined to Dim_Customer via GCID
- AnswerText is the full vulnerability self-declaration text (always the same standard text)

### 2.2 Dual Regulation

**What**: Shows both primary and designated (override) regulation for the customer.
**Columns Involved**: `Regulation`, `DesignatedRegulation`
**Rules**:
- Regulation: Dim_Regulation.Name via Dim_Customer.RegulationID → DWHRegulationID
- DesignatedRegulation: Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID → DWHRegulationID
- Customers may have different primary and designated regulations (e.g., BVI primary, FCA designated)

### 2.3 Financial Position

**What**: Current equity and recent PnL for risk assessment.
**Columns Involved**: `RealizedEquity`, `UnrealizedEquity`, `Opened_PNL`, `Closed_PNL_Last_Year`
**Rules**:
- RealizedEquity: V_Liabilities.RealizedEquity at yesterday's DateID
- UnrealizedEquity: ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) from V_Liabilities
- Opened_PNL: V_Liabilities.PositionPnL (unrealized profit/loss on open positions)
- Closed_PNL_Last_Year: SUM(Dim_Position.NetProfit) WHERE CloseDateID >= 365 days ago

### 2.4 Appropriateness Restriction

**What**: MiFID II appropriateness test restriction status from ComplianceStateDB.
**Columns Involved**: `Appropriatness_Status`
**Rules**:
- Source: ComplianceStateDB.Compliance.CustomerRestrictions WHERE RestrictionStatusReasonID=14 AND BeginTime >= '20200501'
- Joined via GCID
- Values: "Passed" or "Failed" (from Dictionary.RestrictionStatus)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — small table (20.6K rows). No index needed for this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Vulnerable customers with losses | `WHERE Closed_PNL_Last_Year < 0 ORDER BY Closed_PNL_Last_Year ASC` |
| By regulation breakdown | `SELECT Regulation, DesignatedRegulation, COUNT(*) GROUP BY Regulation, DesignatedRegulation` |
| Failed appropriateness test | `WHERE Appropriatness_Status = 'Failed'` |
| Recent self-declarations | `WHERE Answer_Date >= '2026-01-01' ORDER BY Answer_Date DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_Vulnerability_LifetimeMetrics | `CID = RealCID` | Trading metrics for vulnerability dashboard |

### 3.4 Gotchas

- **FirstDepositDate sentinel removal**: SP nullifies dates < 2000-01-01 (the Dim_Customer sentinel). NULL means no deposit.
- **AnswerText is always the same**: The standard vulnerability self-declaration text. Not a free-text field.
- **Typo in column name**: `Appropriatness_Status` (missing 'e' — should be "Appropriateness"). Preserved from SP.
- **Dual regulation**: Always check DesignatedRegulation alongside Regulation — a BVI-regulated customer may be FCA-designated.
- **DWHRegulationID vs ID**: The SP joins on DWHRegulationID (not ID) from Dim_Regulation. These may differ for some regulations.
- **GCID vs CID**: GCID is from KYC system (global customer ID), CID is from Dim_Customer.RealCID. Both identify the same customer but in different systems.

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
| 1 | GCID | int | YES | Global Customer ID from the KYC questionnaire system (BI_DB_KYC_Questions_Answers_Row_Data). Used to join to ComplianceStateDB. Maps to Dim_Customer.GCID. (Tier 2 — SP_Vulnerable_Customers) |
| 2 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 3 | AnswerText | varchar(200) | YES | KYC questionnaire answer text for QuestionId=32 (vulnerability self-declaration). Always the standard text: "A vulnerable client with characteristics or personal circumstances that might negatively impact my ability to operate my account..." (Tier 2 — SP_Vulnerable_Customers) |
| 4 | Answer_Date | date | YES | Date when the customer answered the vulnerability question. CAST(OccurredAt AS DATE) from BI_DB_KYC_Questions_Answers_Row_Data. Range: 2022-07-06 to present. (Tier 2 — SP_Vulnerable_Customers) |
| 5 | FirstDepositDate | date | YES | Date of first deposit. NULL if no deposit or if original date was < 2000-01-01 (sentinel removed by SP). From Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 6 | VerificationLevelID | int | YES | Current KYC verification level from Dim_Customer. 2=partially verified, 3=fully verified. (Tier 2 — SP_Vulnerable_Customers) |
| 7 | VerificationLevel2Date | date | YES | Date when customer reached verification level 2. From BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates) |
| 8 | VerificationLevel3Date | date | YES | Date when customer reached verification level 3 (fully verified). From BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates) |
| 9 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation via RegulationID. (Tier 1 — Dictionary.Regulation) |
| 10 | DesignatedRegulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation via DesignatedRegulationID. (Tier 1 — Dictionary.Regulation) |
| 11 | Country | varchar(100) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 12 | Closed_PNL_Last_Year | decimal(16,2) | YES | Sum of realized profit/loss from positions closed in the last 365 days. SUM(Dim_Position.NetProfit) WHERE CloseDateID >= @YearBeforeID. NULL if no closed positions. (Tier 2 — SP_Vulnerable_Customers) |
| 13 | RealizedEquity | decimal(16,2) | YES | Current realized equity (cash + closed-position value) from V_Liabilities at yesterday's DateID. (Tier 2 — SP_Vulnerable_Customers) |
| 14 | UnrealizedEquity | decimal(16,2) | YES | Current unrealized equity. ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) from V_Liabilities at yesterday. Represents total portfolio including unrealized positions. (Tier 2 — SP_Vulnerable_Customers) |
| 15 | Opened_PNL | decimal(16,2) | YES | Unrealized profit/loss on open positions. V_Liabilities.PositionPnL at yesterday's DateID. Positive = net gain, negative = net loss. (Tier 2 — SP_Vulnerable_Customers) |
| 16 | Appropriatness_Status | varchar(100) | YES | MiFID II appropriateness test restriction status from ComplianceStateDB. WHERE RestrictionStatusReasonID=14 AND BeginTime >= 2020-05-01. Values: "Passed" or "Failed". Column name has typo (missing 'e'). (Tier 2 — SP_Vulnerable_Customers) |
| 17 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID | BI_DB_KYC_Questions_Answers_Row_Data | GCID | Passthrough |
| CID | DWH_dbo.Dim_Customer | RealCID | Rename |
| AnswerText | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | Passthrough |
| Answer_Date | BI_DB_KYC_Questions_Answers_Row_Data | OccurredAt | CAST AS DATE |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Sentinel removal (< 2000 → NULL) |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Lookup via RegulationID |
| DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | Lookup via DesignatedRegulationID |
| Country | DWH_dbo.Dim_Country | Name | Lookup via CountryID |
| Closed_PNL_Last_Year | DWH_dbo.Dim_Position | NetProfit | SUM last 365 days |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | At yesterday |
| UnrealizedEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | Computed sum |
| Opened_PNL | DWH_dbo.V_Liabilities | PositionPnL | At yesterday |
| Appropriatness_Status | ComplianceStateDB | RestrictionStatus.Name | WHERE ReasonID=14 |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (QuestionId=32, AnswerId=151, since 2021-04-01)
  + DWH_dbo.Dim_Customer (GCID JOIN → CID, FirstDepositDate, VerificationLevelID)
  + DWH_dbo.Dim_Regulation (×2: RegulationID + DesignatedRegulationID → Names)
  + DWH_dbo.Dim_Country (CountryID → Name)
  + BI_DB_CIDFirstDates (VL2Date, VL3Date)
  |
  → #pop (self-identified vulnerable customers)
  |
  + V_Liabilities (equity and PnL at yesterday)
  + Dim_Position (SUM NetProfit last 365 days)
  + ComplianceStateDB (appropriateness restriction, ReasonID=14)
  |
  |-- SP_Vulnerable_Customers (TRUNCATE + INSERT) ---|
  v
BI_DB_dbo.BI_DB_Vulnerable_Customers (~20.6K rows, daily snapshot)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer identifier |
| GCID | DWH_dbo.Dim_Customer.GCID | Global customer identifier |
| Regulation | DWH_dbo.Dim_Regulation.Name | Primary regulation |
| DesignatedRegulation | DWH_dbo.Dim_Regulation.Name | Secondary/override regulation |
| Country | DWH_dbo.Dim_Country.Name | Country name |

### 6.2 Referenced By (other objects point to this)

No known consumer tables or views reference this table directly.

---

## 7. Sample Queries

### 7.1 Vulnerable Customers with Significant Losses

```sql
SELECT
    CID,
    Country,
    Regulation,
    DesignatedRegulation,
    Closed_PNL_Last_Year,
    RealizedEquity,
    Appropriatness_Status
FROM [BI_DB_dbo].[BI_DB_Vulnerable_Customers]
WHERE Closed_PNL_Last_Year < -1000
ORDER BY Closed_PNL_Last_Year ASC
```

### 7.2 Vulnerability Dashboard Summary by Regulation

```sql
SELECT
    DesignatedRegulation,
    COUNT(*) AS vulnerable_count,
    SUM(CASE WHEN Appropriatness_Status = 'Failed' THEN 1 ELSE 0 END) AS failed_appropriateness,
    AVG(Closed_PNL_Last_Year) AS avg_closed_pnl,
    AVG(RealizedEquity) AS avg_realized_equity
FROM [BI_DB_dbo].[BI_DB_Vulnerable_Customers]
GROUP BY DesignatedRegulation
ORDER BY vulnerable_count DESC
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 4 T1, 12 T2, 0 T3, 0 T4, 1 T5 | Elements: 17/17, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Vulnerable_Customers | Type: Table | Production Source: KYC_Questions_Answers + Dim_Customer via SP_Vulnerable_Customers*
