# BackOffice.GetPepReport

> Generates the Politically Exposed Person (PEP) compliance report from WorldCheck screening results - returns cases updated within a date range by specified agents, enriched with PEP status, risk status, verification level, match strength/category, and a direct link to the WorldCheck case portal.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @fromDate + @toDate + @updatedBy (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure generates eToro's PEP (Politically Exposed Person) compliance report, used by AML/compliance teams to review WorldCheck screening results. WorldCheck (now Refinitiv WorldCheck One, formerly Accelus) is a third-party screening service that matches customers against global PEP, sanctions, and adverse media databases.

The procedure returns all WorldCheck cases where the PEP status was updated within a specified date range by specified reviewers, enabling compliance managers to audit the screening workflow, track who reviewed which cases, and identify customers flagged as PEP or high-risk.

**Key features**:
- Generates deep-linked URLs to the WorldCheck case portal (`app.accelus.com`) for direct investigation
- Aggregates match strength and category across multiple WorldCheck hits per case
- Joins with eToro's risk system (`BackOffice.GetUserRisksByCID`) for current risk classification
- Performance-optimized: caches compliance reference tables into temp tables with compressed clustered indexes indexed by @@SPID to prevent concurrent session collision

**Change history**:
- 2018-05-02 Geri Reshef (51154): Initial PEP report
- 2018-05-16 Geri Reshef (51563): Added WorldCheck case URL link
- 2018-05-24 Geri Reshef (51659): Performance improvements
- 2018-10-08 Geri Reshef (RD-789, RD-916): PEP check report enhancement
- 2019-01-24 Avraham Lahmi (RD-2021): Added @regulations filter and Regulation output field
- 2019-06-04 Adi: Support for multiple RiskStatus per CID via OUTER APPLY

**Permission**: No active EXECUTE grants found in permission files. Accessed via BOUser or ad-hoc compliance investigation.

---

## 2. Business Logic

### 2.1 WorldCheck Case Loading and Filtering

**What**: Caches compliance reference data into temp tables and filters screening cases to the requested date range and reviewers.

**Columns/Parameters Involved**: @fromDate, @toDate, @updatedBy, Compliance_WorldCheckScreeningCase.PEPStatusUpdatedDate, WorldCheckUpdatedByID

**Rules**:
- `PEPStatusUpdatedDate BETWEEN @fromDate AND @toDate`: Filters to cases where the PEP status was last updated within the window.
- `WorldCheckUpdatedByID IN (SELECT ID FROM @updatedBy)`: Filters to cases updated by the specified reviewer IDs. TVP allows multi-reviewer filtering.
- Compliance tables are cached into session-scoped temp tables (names include @@SPID suffix for indexes) with compressed clustered indexes for query performance. This avoids repeated full scans of large compliance tables.

### 2.2 Match Strength Aggregation

**What**: Summarizes the WorldCheck match strength for each case.

**Columns/Parameters Involved**: Compliance_WorldCheckStrengthToCase, Dictionary_WorldCheckStrength.Name

**Rules**:
- `OUTER APPLY` subquery counts distinct strengths for each screening case:
  - 0 strengths -> NULL
  - 1 strength -> the strength name (e.g., "Strong Match", "Possible Match")
  - 2+ strengths -> 'multiple'
- Returns the MAX(Name) when exactly 1 - this is the single strength label.

### 2.3 Match Category Aggregation

**What**: Summarizes the WorldCheck match categories for each case.

**Columns/Parameters Involved**: Compliance_WorldCheckCategoriesToCase, Dictionary_WorldCheckCategories.Name

**Rules**:
- Same aggregation pattern as Strength:
  - 0 categories -> NULL
  - 1 category -> the category name (e.g., "PEP", "Sanctioned Entity", "Adverse Media")
  - 2+ categories -> 'multiple'

### 2.4 WorldCheck Portal Link Generation

**What**: Builds a deep link to the customer's case in the WorldCheck case portal.

**Columns/Parameters Involved**: WorldCheckInternalSystemCaseUID

**Rules**:
- `IIF(WorldCheckInternalSystemCaseUID IS NULL, NULL, FormatMessage('https://app.accelus.com/...', CAST(LOWER(UUID) AS VARCHAR)))`: Only generates a URL if the case has a WorldCheck system UID.
- The URL template encodes a JSON navigation payload as URL-encoded characters (`%%7B` = `{`, `%%22` = `"`, etc.) pointing to the WorldCheck case view.
- The platform is `app.accelus.com` (Refinitiv WorldCheck One / formerly Accelus).
- UUID is lowercased before embedding in the URL.

### 2.5 Regulation Filtering

**What**: Optional filters to restrict results by regulation.

**Columns/Parameters Involved**: @countryID, @designatedRegulation, @regulations

**Rules**:
- `@countryID IS NULL OR cust.CountryID = @countryID`: Single-country filter on Customer.Customer.
- `@designatedRegulation IS NULL OR cc.DesignatedRegulationID = @designatedRegulation`: Filter by designated (target) regulation.
- `@regulations IS NULL OR @regulations = '' OR cc.RegulationID IN (SELECT * FROM STRING_SPLIT(@regulations, ','))`: Multi-regulation filter via comma-separated string. Empty string treated as no filter.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | DATETIME | NO | - | CODE-BACKED | Start of the PEPStatusUpdatedDate filter range. Returns cases updated on or after this date. |
| 2 | @toDate | DATETIME | NO | - | CODE-BACKED | End of the PEPStatusUpdatedDate filter range. Returns cases updated on or before this date. |
| 3 | @updatedBy | dbo.PepUpdateByID (TVP) | NO | - | CODE-BACKED | Table-valued parameter of WorldCheckUpdatedByIDs. Filters to cases updated by specific compliance reviewers. |
| 4 | @countryID | INT | YES | NULL | CODE-BACKED | Optional filter by customer's registered country. NULL = all countries. |
| 5 | @designatedRegulation | INT | YES | NULL | CODE-BACKED | Optional filter by BackOffice.Customer.DesignatedRegulationID. NULL = all. |
| 6 | @regulations | VARCHAR(50) | YES | NULL | CODE-BACKED | Optional comma-separated list of RegulationIDs (e.g., '1,2,5'). Filters by BackOffice.Customer.RegulationID. NULL or empty = all regulations. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Select.. | BIT | NO | 0 | CODE-BACKED | UI checkbox placeholder (always false). For BackOffice grid bulk selection. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer account ID. |
| 3 | GCID | INT | YES | - | CODE-BACKED | Global Customer ID. |
| 4 | AlertDate | DATETIME | YES | - | CODE-BACKED | `WorldCheckResultsUpdated` - when the WorldCheck screening result was last received/updated. |
| 5 | PepCheckState | NVARCHAR | YES | - | CODE-BACKED | PEP status name from Dictionary_PepStatus (e.g., "PEP", "Not PEP", "Pending Review"). Reflects the compliance team's decision on this customer's PEP status. |
| 6 | VerificationLevel | NVARCHAR | YES | - | CODE-BACKED | KYC verification level from Dictionary.VerificationLevel (e.g., "Basic", "Advanced", "Full"). |
| 7 | RiskStatus | NVARCHAR | YES | - | CODE-BACKED | Current risk status name(s) from `BackOffice.GetUserRisksByCID(CID)`. May include multiple risk flags concatenated. |
| 8 | UpdatedBy | NVARCHAR | YES | - | CODE-BACKED | Name of the compliance reviewer who last updated the PEP status, from Dictionary_WorldCheckUpdatedBy. |
| 9 | Strength | NVARCHAR | YES | - | CODE-BACKED | WorldCheck match strength: single strength name if exactly one match, 'multiple' if >1, NULL if no strength data. Examples: "Strong Match", "Possible Match". |
| 10 | Category | NVARCHAR | YES | - | CODE-BACKED | WorldCheck match category: single category name if exactly one, 'multiple' if >1, NULL if none. Examples: "PEP", "Sanctioned Entity", "Adverse Media", "Law Enforcement". |
| 11 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Current regulation name from Dictionary.Regulation for BackOffice.Customer.RegulationID. |
| 12 | WchLink | NVARCHAR | YES | - | CODE-BACKED | Deep link URL to the customer's case in the WorldCheck portal (app.accelus.com). NULL if no WorldCheckInternalSystemCaseUID. Enables agents to navigate directly to the WorldCheck case for investigation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Core case data | Compliance_WorldCheckScreeningCase | Read (filtered into temp table) | WorldCheck screening case records; primary data source |
| Categories | Compliance_WorldCheckCategoriesToCase | Read (cached) | Case-to-category junction |
| Strengths | Compliance_WorldCheckStrengthToCase | Read (cached) | Case-to-strength junction |
| Case state labels | Dictionary_WorldCheckState | Read (cached) | WorldCheck state names |
| PEP status labels | Dictionary_PepStatus | Read (cached) | PEP status names |
| Reviewer names | Dictionary_WorldCheckUpdatedBy | Read (cached) | Compliance reviewer names |
| Strength names | Dictionary_WorldCheckStrength | Read (cached) | Match strength labels |
| Category names | Dictionary_WorldCheckCategories | Read (cached) | Match category labels |
| Current risk | BackOffice.GetUserRisksByCID | OUTER APPLY | Aggregated risk status for the customer |
| BackOffice profile | BackOffice.Customer | Left Join | RegulationID, DesignatedRegulationID, VerificationLevelID |
| Customer profile | Customer.Customer | Inner Join | CountryID for filter |
| Verification level | Dictionary.VerificationLevel | Left Join | Verification level name |
| Regulation name | Dictionary.Regulation | Left Join | Regulation display name |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPepReport (procedure)
+-- Compliance_WorldCheckScreeningCase (table - dbo/compliance schema)
+-- Compliance_WorldCheckCategoriesToCase (table)
+-- Compliance_WorldCheckStrengthToCase (table)
+-- Dictionary_WorldCheckState (table)
+-- Dictionary_PepStatus (table)
+-- Dictionary_WorldCheckUpdatedBy (table)
+-- Dictionary_WorldCheckStrength (table)
+-- Dictionary_WorldCheckCategories (table)
+-- BackOffice.GetUserRisksByCID (function - OUTER APPLY)
+-- BackOffice.Customer (table)
+-- Customer.Customer (table)
+-- Dictionary.VerificationLevel (table)
+-- Dictionary.Regulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Compliance_WorldCheckScreeningCase | Table | Core WorldCheck screening data (no schema prefix) |
| Compliance_WorldCheckCategoriesToCase | Table | Case-category mapping |
| Compliance_WorldCheckStrengthToCase | Table | Case-strength mapping |
| Dictionary_WorldCheckState | Table | State labels |
| Dictionary_PepStatus | Table | PEP status labels |
| Dictionary_WorldCheckUpdatedBy | Table | Reviewer names |
| Dictionary_WorldCheckStrength | Table | Match strength labels |
| Dictionary_WorldCheckCategories | Table | Match category labels |
| BackOffice.GetUserRisksByCID | Function | Current risk status aggregation |
| BackOffice.Customer | Table | RegulationID, DesignatedRegulationID, VerificationLevelID |
| Customer.Customer | Table | CountryID filter |
| Dictionary.VerificationLevel | Table | Verification level name |
| Dictionary.Regulation | Table | Regulation name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No EXECUTE grants; compliance team ad-hoc use |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @@SPID in index names | Concurrency | Prevents index name collision when multiple sessions run this SP simultaneously |
| Data_Compression=Page, FillFactor=90 | Performance | Compressed temp table indexes reduce I/O for large compliance tables |
| TRY/CATCH with THROW | Error handling | Exceptions propagate to caller without swallowing |
| STRING_SPLIT for @regulations | Flexibility | Supports comma-separated multi-regulation filtering in a single VARCHAR parameter |
| OUTER APPLY GetUserRisksByCID | Risk aggregation | Replaces commented-out single-value RiskStatusID join; supports customers with multiple concurrent risk flags |

---

## 8. Sample Queries

### 8.1 Get PEP report for all reviewers, last 30 days

```sql
DECLARE @updatedBy dbo.PepUpdateByID;
-- Empty TVP would need at least one value; check Dictionary_WorldCheckUpdatedBy for valid IDs
-- Example: INSERT INTO @updatedBy SELECT WorldCheckUpdatedByID FROM Dictionary_WorldCheckUpdatedBy;

EXEC BackOffice.GetPepReport
    @fromDate = DATEADD(DAY, -30, GETDATE()),
    @toDate = GETDATE(),
    @updatedBy = @updatedBy;
```

### 8.2 Check WorldCheck reviewer IDs

```sql
SELECT WorldCheckUpdatedByID, Name
FROM Dictionary_WorldCheckUpdatedBy
ORDER BY Name;
```

### 8.3 Check PEP status values

```sql
SELECT PEPStatusID, Name AS PepStatusName
FROM Dictionary_PepStatus
ORDER BY PEPStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPepReport | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPepReport.sql*
