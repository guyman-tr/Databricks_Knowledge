# BI_DB_dbo.BI_DB_TIN_Gap

> 335K-row CID-level compliance table identifying eToro customers with TIN (Tax Identification Number) gaps under the TIN Gap Remediation project. Each row represents one customer from a frozen base population, enriched with up to 3 pivoted tax-country slots (TaxCountry/TaxCode/NoTIN_Reason/Ind per slot), a Group classification (A/B1/B2/B3/C) for prioritisation, and financial/activity context. Loaded daily via TRUNCATE+INSERT by SP_TIN_Gap (author: Adi Meidan).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_Bi_Output_Uploads_TIN_Gaps_Freeze6 + External_UserApiDB_Customer_ExtendedUserField (FieldId=6) + Dim_Customer + Dim_Country + V_Liabilities + BI_DB_PositionPnL + Fact_CustomerAction |
| **Refresh** | Daily -- TRUNCATE + INSERT (full snapshot, no @Date parameter -- uses GETDATE()-1 internally) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A -- not exported to Unity Catalog |

---

## 1. Business Meaning

`BI_DB_TIN_Gap` is the core output of the TIN Gap Remediation project, which identifies eToro customers who have incomplete or invalid Tax Identification Numbers required for CRS (Common Reporting Standard) compliance. The table holds approximately 335K customers drawn from a frozen base population (Freeze6), with each customer classified into one of three gap types or marked as "Done" (valid TIN).

The Group column segments customers into prioritisation tiers based on financial exposure and activity:
- **A** (209K) -- no open positions and equity < $10 (lowest risk)
- **B1** (24K) -- inactive and equity < $30
- **B2** (21K) -- inactive and equity >= $30
- **B3** (73K) -- active or logged in within last 12 months (highest priority among non-PI)
- **C** (8K) -- PI/Club members (PlayerLevelID 2, 6, 7)

Resolution status: 104K customers (31%) have Ind_Done=1 (all tax countries resolved); 232K (69%) remain with at least one unresolved gap.

Top regulations: CySEC (199K), FCA (90K), FSA Seychelles (25K), ASIC&GAML (12K), ASIC (7K).

---

## 2. Business Logic

### 2.1 TIN Gap Type Classification

**What**: Each customer in the base population is classified into one of three gap types, or "Done" if all TINs are valid.

**Columns Involved**: Ind_1, Ind_2, Ind_3, TaxCode_1/2/3, NoTIN_Reason1/2/3

**Rules**:
- **"No TIN"** -- customer has no ExtendedUserField record with FieldId=6 at all (field entirely absent)
- **"TIN Not Valid"** -- TIN field exists but validation failed
- **"TIN_Null_With_Reason"** -- TIN value is empty/null but a CRS no-TIN reason is provided; specific conditions apply, including a $5,000 lifetime deposit threshold for reason code 4
- **"Done"** -- customer appears in base population but not in any gap list (valid TIN for all declared tax countries)

### 2.2 Pivot Logic -- Up to 3 Tax Countries per CID

**What**: Each customer can have up to 3 tax country declarations. The SP pivots these into flat columns.

**Columns Involved**: TaxCountry_1/2/3, TaxCode_1/2/3, NoTIN_Reason1/2/3, Ind_1/2/3

**Rules**:
- Row-numbered by CID, producing slots 1, 2, 3
- TaxCountry_N = resolved country name from Dim_Country
- TaxCode_N = TIN value from ExtendedUserField
- NoTIN_Reason_N = CRS reason for missing TIN
- Ind_N = '1' if that slot is resolved; gap type string otherwise
- Slots 2 and 3 are NULL when the customer declares fewer than 2 or 3 tax countries

### 2.3 Group Classification

**What**: Customers are segmented into priority groups for remediation outreach.

**Columns Involved**: Group (char(2))

**Rules**:
- **C**: PlayerLevelID IN (2, 6, 7) -- PI (Popular Investor) or Club members; checked first
- **A**: Open Positions = 0 AND RealizedEquity < 10
- **B1**: NOT active in last 12 months AND RealizedEquity < 30
- **B2**: NOT active in last 12 months AND RealizedEquity >= 30
- **B3**: Active (traded or logged in within last 12 months)
- Activity is determined from Fact_CustomerAction (trading activity) and last login date

### 2.4 Ind_Done Computation

**What**: Summary flag indicating whether all tax country slots for a customer are resolved.

**Columns Involved**: Ind_Done (int)

**Rules**:
- Ind_Done = 1 when Ind_1 = '1' AND Ind_2 = '1' AND Ind_3 = '1' (all declared tax countries have valid TIN)
- Ind_Done = 0 otherwise (at least one slot unresolved)
- For customers with fewer than 3 tax countries, NULL Ind slots are treated as resolved for this calculation

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with 335K rows. Small table -- broadcast-friendly for JOINs. Full scan is fast. No clustering index; no partition elimination needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Unresolved TIN gaps by regulation | `WHERE Ind_Done = 0 GROUP BY Regulation` |
| Group-level remediation progress | `GROUP BY [Group], Ind_Done` with COUNT(*) |
| High-priority unresolved (Group B3/C) | `WHERE [Group] IN ('B3','C') AND Ind_Done = 0` |
| Customers with specific gap type | `WHERE Ind_1 = 'No TIN'` (or 'TIN Not Valid', 'TIN_Null_With_Reason') |
| PI customers needing TIN remediation | `WHERE [Group] = 'C' AND Ind_Done = 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = CID | Additional customer attributes not in this table |
| DWH_dbo.V_Liabilities | CID = CID (+ date filter) | Current financial position beyond RealizedEquity |
| BI_DB_dbo.BI_DB_PositionPnL | CID = CID (+ DateID) | Position-level detail for open positions |

### 3.4 Gotchas

- **Group column is a reserved word**: Always quote as `[Group]` in T-SQL queries
- **Frozen base population**: The population comes from Freeze6, not live Dim_Customer. New customers registered after the freeze are NOT included, and closed accounts from the freeze may still appear
- **Email and TaxCode contain PII**: These columns hold personal data (email addresses, tax identification numbers). Apply appropriate access controls and do not expose in unsecured reports
- **Ind columns are varchar, not int**: Ind_1/2/3 contain '1' for resolved but gap type strings ('No TIN', 'TIN Not Valid', 'TIN_Null_With_Reason') for unresolved -- do not compare as integers
- **Lifetime Deposits threshold**: Reason code 4 for TIN_Null_With_Reason only applies when lifetime deposits >= $5,000. This threshold is baked into the SP logic
- **No date parameter**: SP uses GETDATE()-1 internally. You cannot backfill or re-run for historical dates without modifying the SP
- **TRUNCATE+INSERT**: The entire table is replaced daily. There is no history; yesterday's state is gone after refresh

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (Dim_Customer, Dim_Country, etc.) |
| Tier 2 | Derived from SP code, DDL, or DWH join logic |
| Tier 5 | Expert review needed -- limited traceability |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID -- platform-internal primary key. Assigned at registration. Unique within eToro DB. Used as the universal customer identifier across all tables. Base population key from Freeze6. (Tier 1 -- Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 -- Customer.CustomerStatic) |
| 3 | Email | varchar(100) | YES | Customer email address from Dim_Customer. PII -- handle with appropriate access controls. (Tier 1 -- Customer.CustomerStatic) |
| 4 | Client Language | varchar(100) | YES | Customer's preferred language from Dim_Customer. Used for localised remediation outreach. (Tier 1 -- Customer.CustomerStatic) |
| 5 | KYC_Country | varchar(100) | YES | Full country name in English for the customer's KYC country of residence. Resolved from Dim_Country.Name via Dim_Customer.CountryID. (Tier 1 -- Dictionary.Country) |
| 6 | TaxCountry_1 | varchar(100) | YES | Full country name in English for the customer's first declared tax country. Pivoted from ExtendedUserField and resolved via Dim_Country.Name. (Tier 1 -- Dictionary.Country) |
| 7 | TaxCountry_2 | varchar(100) | YES | Second declared tax country name. NULL if customer declares fewer than 2 tax countries. (Tier 1 -- Dictionary.Country) |
| 8 | TaxCountry_3 | varchar(100) | YES | Third declared tax country name. NULL if customer declares fewer than 3 tax countries. (Tier 1 -- Dictionary.Country) |
| 9 | TaxCode_1 | nvarchar(max) | YES | TIN value for first tax country from ExtendedUserField (FieldId=6). PII -- contains tax identification numbers. NULL or empty for gap types "No TIN" and "TIN_Null_With_Reason". (Tier 2 -- SP_TIN_Gap, External_UserApiDB_Customer_ExtendedUserField) |
| 10 | TaxCode_2 | nvarchar(max) | YES | TIN value for second tax country. NULL if fewer than 2 tax countries declared. (Tier 2 -- SP_TIN_Gap, External_UserApiDB_Customer_ExtendedUserField) |
| 11 | TaxCode_3 | nvarchar(max) | YES | TIN value for third tax country. NULL if fewer than 3 tax countries declared. (Tier 2 -- SP_TIN_Gap, External_UserApiDB_Customer_ExtendedUserField) |
| 12 | NoTIN_Reason1 | varchar(1000) | YES | CRS no-TIN reason for first tax country. Populated when customer has a gap with a declared reason (e.g., reason 4 requires $5K lifetime deposit threshold). (Tier 2 -- SP_TIN_Gap, External_UserApiDB_Customer_ExtendedUserField) |
| 13 | NoTIN_Reason2 | varchar(1000) | YES | CRS no-TIN reason for second tax country. NULL if fewer than 2 tax countries. (Tier 2 -- SP_TIN_Gap, External_UserApiDB_Customer_ExtendedUserField) |
| 14 | NoTIN_Reason3 | varchar(1000) | YES | CRS no-TIN reason for third tax country. NULL if fewer than 3 tax countries. (Tier 2 -- SP_TIN_Gap, External_UserApiDB_Customer_ExtendedUserField) |
| 15 | Player_Status | varchar(50) | YES | Customer player status name resolved from Dim_PlayerStatus.Name via Dim_Customer.PlayerStatusID. (Tier 1 -- Dictionary.PlayerStatus) |
| 16 | Account Manager | varchar(100) | YES | Assigned account manager from Dim_Customer. Relevant for PI/Club remediation outreach (Group C). (Tier 2 -- SP_TIN_Gap, DWH_dbo.Dim_Customer) |
| 17 | Group | char(2) | YES | Remediation priority group. A = no positions + equity < $10; B1 = inactive + equity < $30; B2 = inactive + equity >= $30; B3 = active/logged in last 12 months; C = PI/Club members (PlayerLevelID 2,6,7). Distribution: A=209K, B1=24K, B2=21K, B3=73K, C=8K. (Tier 2 -- SP_TIN_Gap, computed) |
| 18 | Club | varchar(20) | YES | Customer loyalty tier name resolved from Dim_PlayerLevel.Name via Dim_Customer.PlayerLevelID. (Tier 1 -- Dictionary.PlayerLevel) |
| 19 | Regulation | varchar(20) | YES | Regulatory entity short code resolved from Dim_Regulation.Name. Top values: CySEC (199K), FCA (90K), FSA Seychelles (25K), ASIC&GAML (12K), ASIC (7K). (Tier 1 -- Dictionary.Regulation) |
| 20 | Open Positions | int | YES | Count of open trading positions for this CID from BI_DB_PositionPnL. Used in Group classification (A requires 0). (Tier 2 -- SP_TIN_Gap, BI_DB_dbo.BI_DB_PositionPnL) |
| 21 | RealizedEquity | float | YES | Customer's realized equity from V_Liabilities. Used in Group classification thresholds ($10 for A, $30 for B1/B2). (Tier 2 -- SP_TIN_Gap, DWH_dbo.V_Liabilities) |
| 22 | Ind_1 | varchar(100) | YES | Gap indicator for first tax country slot. '1' = resolved (valid TIN); otherwise contains gap type string: 'No TIN', 'TIN Not Valid', or 'TIN_Null_With_Reason'. (Tier 2 -- SP_TIN_Gap, computed) |
| 23 | Ind_2 | varchar(100) | YES | Gap indicator for second tax country slot. Same values as Ind_1. NULL if fewer than 2 tax countries. (Tier 2 -- SP_TIN_Gap, computed) |
| 24 | Ind_3 | varchar(100) | YES | Gap indicator for third tax country slot. Same values as Ind_1. NULL if fewer than 3 tax countries. (Tier 2 -- SP_TIN_Gap, computed) |
| 25 | Ind_Done | int | YES | Overall resolution flag. 1 = all Ind columns are '1' (all tax countries resolved); 0 = at least one gap remains. Distribution: 0=232K, 1=104K. (Tier 2 -- SP_TIN_Gap, computed) |
| 26 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_TIN_Gap (GETDATE() at SP execution time). All rows share the same value per load. (Tier 5 -- Expert Review) |
| 27 | PendingClosureStatusName | varchar(50) | YES | Pending closure status from Dim_Customer. Indicates if the customer's account is in a closure pipeline. (Tier 2 -- SP_TIN_Gap, DWH_dbo.Dim_Customer) |
| 28 | LastLoggedIn | datetime | YES | Customer's last login timestamp. Used in Group classification (B3 includes customers who logged in within 12 months). (Tier 2 -- SP_TIN_Gap, DWH_dbo.Dim_Customer / login source) |
| 29 | Annual Income_KYC | nvarchar(max) | YES | KYC-declared annual income from Dim_Customer. Context field for remediation prioritisation. (Tier 2 -- SP_TIN_Gap, DWH_dbo.Dim_Customer) |
| 30 | Lifetime Deposits | float | YES | Total lifetime deposits for the customer. Used in TIN_Null_With_Reason classification ($5,000 threshold for reason 4). (Tier 2 -- SP_TIN_Gap, DWH_dbo.Fact_CustomerAction or V_Liabilities) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CID | External_Bi_Output_Uploads_TIN_Gaps_Freeze6 | CID | Base population key |
| GCID | Customer.CustomerStatic via Dim_Customer | GCID | Passthrough |
| Email | Customer.CustomerStatic via Dim_Customer | Email | Passthrough |
| Client Language | Customer.CustomerStatic via Dim_Customer | Language | Passthrough |
| KYC_Country | Dictionary.Country via Dim_Country | Name | JOIN on CountryID |
| TaxCountry_1/2/3 | Dictionary.Country via Dim_Country | Name | Pivoted, JOIN on tax country ID |
| TaxCode_1/2/3 | UserApiDB_Customer_ExtendedUserField | FieldValue (FieldId=6) | Pivoted TIN values |
| NoTIN_Reason1/2/3 | UserApiDB_Customer_ExtendedUserField | CRS reason | Pivoted no-TIN reasons |
| Player_Status | Dictionary.PlayerStatus via Dim_PlayerStatus | Name | JOIN on PlayerStatusID |
| Account Manager | Dim_Customer | AccountManager | Passthrough |
| Group | SP_TIN_Gap | computed | CASE on positions, equity, activity, club |
| Club | Dictionary.PlayerLevel via Dim_PlayerLevel | Name | JOIN on PlayerLevelID |
| Regulation | Dictionary.Regulation via Dim_Regulation | Name | JOIN on RegulationID |
| Open Positions | BI_DB_PositionPnL | COUNT(PositionID) | Aggregated per CID |
| RealizedEquity | V_Liabilities | RealizedEquity | Passthrough per CID |
| Ind_1/2/3 | SP_TIN_Gap | computed | Gap type or '1' per tax country slot |
| Ind_Done | SP_TIN_Gap | computed | 1 if all Ind = '1' |
| UpdateDate | SP_TIN_Gap | GETDATE() | ETL timestamp |
| PendingClosureStatusName | Dim_Customer | PendingClosureStatusName | Passthrough |
| LastLoggedIn | Dim_Customer / login source | LastLoggedIn | Passthrough |
| Annual Income_KYC | Dim_Customer | AnnualIncome | KYC field passthrough |
| Lifetime Deposits | Fact_CustomerAction or V_Liabilities | Lifetime deposit sum | Aggregated |

### 5.2 ETL Pipeline

```
External_Bi_Output_Uploads_TIN_Gaps_Freeze6 (frozen CID population)
  - Google Sheet exclusion list (specific CIDs removed)
  + External_UserApiDB_Customer_ExtendedUserField (FieldId=6 — TIN data)
  |-- classify: No TIN / TIN Not Valid / TIN_Null_With_Reason / Done
  |-- pivot up to 3 tax countries per CID → flat columns
  + DWH_dbo.Dim_Customer (email, GCID, language, status, level, regulation, AM)
  + DWH_dbo.Dim_Country (country name resolution)
  + DWH_dbo.V_Liabilities (RealizedEquity)
  + BI_DB_dbo.BI_DB_PositionPnL (open positions count)
  + DWH_dbo.Fact_CustomerAction (12-month activity flag)
  |
  v
  SP_TIN_Gap (TRUNCATE + INSERT, uses GETDATE()-1)
  |
  v
BI_DB_dbo.BI_DB_TIN_Gap (335K rows — daily full replace)
  |-- NOT exported to Unity Catalog (_Not_Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | External_Bi_Output_Uploads_TIN_Gaps_Freeze6 | Frozen base population |
| CID | DWH_dbo.Dim_Customer.CID | Customer attribute enrichment |
| KYC_Country, TaxCountry_1/2/3 | DWH_dbo.Dim_Country.Name | Country name resolution |
| Player_Status | DWH_dbo.Dim_PlayerStatus.Name | Status name lookup |
| Club | DWH_dbo.Dim_PlayerLevel.Name | Club tier name lookup |
| Regulation | DWH_dbo.Dim_Regulation.Name | Regulation short code lookup |
| TaxCode_1/2/3, NoTIN_Reason1/2/3 | External_UserApiDB_Customer_ExtendedUserField | TIN values and CRS reasons (FieldId=6) |
| Open Positions | BI_DB_dbo.BI_DB_PositionPnL | Open position count per CID |
| RealizedEquity | DWH_dbo.V_Liabilities | Customer financial position |
| Activity (Group logic) | DWH_dbo.Fact_CustomerAction | Trading activity last 12 months |

### 6.2 Referenced By

No known downstream tables directly reference BI_DB_TIN_Gap. It is consumed by compliance and remediation dashboards for the TIN Gap Remediation project.

---

## 7. Sample Queries

### TIN Gap Remediation Progress by Regulation

```sql
SELECT 
    Regulation,
    [Group],
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Ind_Done = 1 THEN 1 ELSE 0 END) AS resolved,
    SUM(CASE WHEN Ind_Done = 0 THEN 1 ELSE 0 END) AS unresolved,
    CAST(SUM(CASE WHEN Ind_Done = 1 THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,1)) AS pct_resolved
FROM [BI_DB_dbo].[BI_DB_TIN_Gap]
GROUP BY Regulation, [Group]
ORDER BY Regulation, [Group]
```

### High-Priority Unresolved Customers (Group B3 and C)

```sql
SELECT 
    CID,
    Email,
    KYC_Country,
    Regulation,
    [Group],
    Club,
    TaxCountry_1, Ind_1,
    TaxCountry_2, Ind_2,
    TaxCountry_3, Ind_3,
    RealizedEquity,
    [Open Positions]
FROM [BI_DB_dbo].[BI_DB_TIN_Gap]
WHERE [Group] IN ('B3', 'C')
  AND Ind_Done = 0
ORDER BY RealizedEquity DESC
```

### Gap Type Distribution

```sql
SELECT 
    Ind_1 AS gap_type,
    COUNT(*) AS customers
FROM [BI_DB_dbo].[BI_DB_TIN_Gap]
WHERE Ind_1 <> '1'
GROUP BY Ind_1
ORDER BY customers DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. The TIN Gap Remediation project context (Adi Meidan, Freeze6 population) may have associated Jira epics or Confluence pages not yet linked to this wiki.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 10 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 30/30, Logic: 8/10, ETL: confirmed, Data Evidence: context*
*Object: BI_DB_dbo.BI_DB_TIN_Gap | Type: Table | Production Source: External_Bi_Output_Uploads_TIN_Gaps_Freeze6 + ExtendedUserField*
