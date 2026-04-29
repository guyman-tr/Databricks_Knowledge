# BI_DB_dbo.BI_DB_AffData

> Dormant affiliate-customer mapping table with 0 rows. Designed to link customers (RealCID) to affiliate partners (AffiliateID) with affiliate profile attributes (registration date, login, email, contract, language, group, channel). No writer SP exists and the table is not populated — likely legacy or deprecated.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant) — no writer SP found; column naming suggests DWH_dbo.Dim_Affiliate as domain source |
| **Refresh** | None (table is empty, no ETL pipeline) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_AffData` is a dormant BI reporting table designed to store a denormalized mapping of customers to their affiliate partners, along with key affiliate profile attributes. The composite primary key `(RealCID, AffiliateID)` indicates it was meant to represent the customer-affiliate relationship — which customer was acquired through which affiliate partner.

The table currently has **0 rows** and has no stored procedure in the SSDT repo that writes to it. It is likely a legacy or deprecated table that was once part of the BI affiliate reporting pipeline but has since been superseded by direct JOINs between fact tables and `DWH_dbo.Dim_Affiliate` / `DWH_dbo.Dim_Customer`.

Column naming patterns (Aff_Registration, Aff_LoginName, Aff_Email, Aff_eLanguage) and structural overlap (ContractName, ContractType, AffGroup, Channel) strongly suggest the table was designed to hold a flattened subset of `DWH_dbo.Dim_Affiliate` attributes keyed by customer. The `Aff_Email` column has dynamic data masking (`default()`), confirming it was intended to hold PII.

---

## 2. Business Logic

### 2.1 Customer-Affiliate Relationship

**What**: Each row was designed to represent one customer's association with one affiliate partner.

**Columns Involved**: `RealCID`, `AffiliateID`

**Rules**:
- Composite PK `(RealCID, AffiliateID)` — NOT ENFORCED (Synapse limitation)
- A customer could theoretically appear with multiple affiliates, and an affiliate with multiple customers
- RealCID is the standard DWH customer identifier (maps to Dim_Customer.RealCID)
- AffiliateID is the AffWizz affiliate identifier (maps to Dim_Affiliate.AffiliateID)

### 2.2 PII Handling

**What**: The Aff_Email column contains personally identifiable information and is protected with dynamic data masking.

**Columns Involved**: `Aff_Email`

**Rules**:
- Dynamic data masking applied with `FUNCTION = 'default()'`
- UNMASK permission is granted to `DataplatformPII` role specifically for the `Aff_Email` column
- Standard users see masked values; only PII-authorized roles see raw email addresses

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table uses `ROUND_ROBIN` distribution with a `HEAP` storage (no index). Since the table is empty/dormant, distribution strategy is irrelevant for query planning. If the table were populated, ROUND_ROBIN would mean no co-location benefit for JOINs — fact tables distributed on CID/RealCID would not be co-located.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Affiliate details for a customer | Use `Dim_Customer.AffiliateID` JOIN to `Dim_Affiliate` instead — this table is empty |
| Customer list for an affiliate | Use `Dim_Customer WHERE AffiliateID = @id` instead |
| Affiliate contract information | Query `DWH_dbo.Dim_Affiliate` directly |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID = RealCID | Customer attributes (but table is empty) |
| DWH_dbo.Dim_Affiliate | ON AffiliateID = AffiliateID | Full affiliate profile (but table is empty) |

### 3.4 Gotchas

- **Table is empty/dormant**: 0 rows. Do not query this table for production analytics — use Dim_Customer + Dim_Affiliate JOINs instead
- **No writer SP exists**: No ETL pipeline populates this table. It appears to be deprecated
- **PK NOT ENFORCED**: The composite PK (RealCID, AffiliateID) is declared but not enforced (standard Synapse behavior)
- **ContractType is varchar(20)**: Unlike Dim_Affiliate.ContractType (tinyint), this column may have been designed to store the text label rather than the numeric code
- **Aff_Email is masked**: Dynamic data masking with `default()` — PII column

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 2 stars | Tier 3b — DDL structure | Description grounded in DDL column definition, type, constraints, and naming correlation with documented sibling tables |

> All columns are Tier 3b because no writer SP exists to trace code-level lineage. Descriptions are grounded in DDL structure (types, nullability, constraints, masking) and naming correlation with DWH_dbo.Dim_Affiliate and DWH_dbo.Dim_Customer.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID — platform-internal primary key assigned at registration. Part of composite PK (RealCID, AffiliateID). Standard DWH customer identifier used across all tables. Correlates with Dim_Customer.RealCID. (Tier 3b — DDL structure, correlated with Dim_Customer) |
| 2 | AffiliateID | int | NO | Affiliate partner identifier from the AffWizz system. Part of composite PK (RealCID, AffiliateID). Correlates with Dim_Affiliate.AffiliateID. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 3 | Aff_Registration | datetime | YES | Affiliate registration date. Naming pattern (Aff_ prefix) suggests this is the affiliate's registration/creation date in AffWizz, correlating with Dim_Affiliate.DateCreated. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 4 | Aff_LoginName | nvarchar(50) | YES | Affiliate login name in the AffWizz system. Naming pattern correlates with Dim_Affiliate.LoginName. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 5 | Aff_Email | varchar(50) | YES | Affiliate email address. **PII column** — dynamic data masking applied with `FUNCTION = 'default()'`. UNMASK granted to DataplatformPII role. Naming pattern correlates with Dim_Affiliate.Email. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 6 | ContractName | varchar(100) | YES | Free-text name of the affiliate's contract/payment agreement. Used in Dim_Affiliate as input for ContractType classification (e.g., "Rev Share + CPA", "CPL Standard"). (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 7 | ContractType | varchar(20) | YES | Affiliate payment model. In Dim_Affiliate this is a tinyint code (0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=Zero Commission, 8=CPL/CPR); here it is varchar(20) — may store the text label instead of the numeric code. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 8 | Aff_eLanguage | nvarchar(255) | YES | Affiliate's preferred language. Naming pattern (Aff_eLanguage) correlates with Dim_Affiliate.LanguageName. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 9 | AffGroup | nvarchar(50) | YES | Marketing group the affiliate belongs to. Correlates with Dim_Affiliate.AffiliatesGroupsName (abbreviated). (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 10 | Channel | varchar(50) | NO | Top-level marketing channel classification (e.g., "Paid", "Organic", "Affiliate"). NOT NULL constraint. Correlates with Dim_Affiliate.Channel — inherited from Ext_Dim_SubChannel_UnifyCode in the Dim_Affiliate pipeline. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| 11 | UpdateDate | datetime | YES | ETL load timestamp. Standard DWH pattern — set to GETDATE() during SP execution. Since no writer SP exists, this column was never populated. (Tier 3b — DDL structure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Probable Production Source | Source Column | Transform |
|---------------|--------------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic (via Dim_Customer) | CID | rename (inferred) |
| AffiliateID | fiktivo_dbo.tblaff_Affiliates (via Dim_Affiliate) | AffiliateID | passthrough (inferred) |
| Aff_Registration | fiktivo_dbo.tblaff_Affiliates (via Dim_Affiliate) | DateCreated | rename (inferred) |
| Aff_LoginName | fiktivo_dbo.tblaff_Affiliates (via Dim_Affiliate) | LoginName | rename (inferred) |
| Aff_Email | fiktivo_dbo.tblaff_Affiliates (via Dim_Affiliate) | Email | rename (inferred) |
| ContractName | fiktivo_dbo.tblaff_Affiliates (via Dim_Affiliate) | ContractName | passthrough (inferred) |
| ContractType | fiktivo_dbo.tblaff_Affiliates (via Dim_Affiliate) | ContractType | type change (inferred — varchar vs tinyint) |
| Aff_eLanguage | fiktivo_dbo.tblaff_Affiliates (via Dim_Affiliate) | LanguageName | rename (inferred) |
| AffGroup | fiktivo_dbo.tblaff_Affiliates (via Dim_Affiliate) | AffiliatesGroupsName | rename (inferred) |
| Channel | Ext_Dim_SubChannel_UnifyCode (via Dim_Affiliate) | Channel | passthrough (inferred) |
| UpdateDate | — | — | ETL timestamp (inferred) |

> **All lineage is inferred** — no writer SP exists. Production sources are deduced from naming correlation with DWH_dbo.Dim_Affiliate (whose lineage traces to fiktivo_dbo/AffWizz).

### 5.2 ETL Pipeline

```
fiktivo_dbo.tblaff_Affiliates (AffWizz, production)
  |-- Generic Pipeline (Bronze export) ---|
  v
Ext_Dim_Channel_Affiliate_UnifyCode (staging)
  |-- SP_Dim_Affiliate ---|
  v
DWH_dbo.Dim_Affiliate (master dimension)
  |-- [NO SP FOUND] ---|
  v
BI_DB_dbo.BI_DB_AffData (0 rows — dormant, no ETL pipeline)
```

> The ETL chain from production to Dim_Affiliate is documented. The final step from Dim_Affiliate to BI_DB_AffData has no SP — the table was never populated or its ETL was removed.

```text
UPSTREAM SEARCH LOG — BI_DB_AffData:
  Lineage source objects (from .lineage.md):
    1. DWH_dbo.Dim_Affiliate (role: probable domain source — affiliate dimension)
    2. DWH_dbo.Dim_Customer (role: probable FK source — customer dimension)
  For each source:
    DWH_dbo.Dim_Affiliate
      (a) Local wiki search: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Affiliate.md -> FOUND
          Read tool issued: YES
      (b) Production wiki search: N/A (local wiki found)
      Effective upstream: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Affiliate.md
    DWH_dbo.Dim_Customer
      (a) Local wiki search: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md -> FOUND
          Read tool issued: YES (grep for RealCID)
      (b) Production wiki search: N/A (local wiki found)
      Effective upstream: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md
  Columns expected to inherit Tier 1 from each source:
    None — no writer SP exists to confirm column-level lineage. All mappings are inferred
    from DDL structure and naming patterns. Tier 3b assigned (DDL structure).
  Tier-1-eligible columns identified: 0 (no SP trace = no confirmed lineage = no Tier 1)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension — resolves customer attributes (implicit FK) |
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate dimension — resolves full affiliate profile (implicit FK) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No objects reference this dormant table |

---

## 7. Sample Queries

### 7.1 Check if table has data (dormancy check)

```sql
SELECT TOP 10 *
FROM [BI_DB_dbo].[BI_DB_AffData];
-- Expected: 0 rows (table is dormant)
```

### 7.2 Alternative: Customer-affiliate mapping via Dim_Customer

```sql
-- Since BI_DB_AffData is empty, use this pattern instead:
SELECT
    dc.RealCID,
    dc.AffiliateID,
    da.ContractName,
    da.ContractType,
    da.Channel,
    da.AffiliatesGroupsName AS AffGroup
FROM DWH_dbo.Dim_Customer dc
JOIN DWH_dbo.Dim_Affiliate da ON dc.AffiliateID = da.AffiliateID
WHERE da.AccountActivated = 1;
```

### 7.3 Affiliate profile lookup (use Dim_Affiliate directly)

```sql
SELECT
    a.AffiliateID,
    a.LoginName,
    a.Email,
    a.ContractName,
    a.ContractType,
    a.Channel,
    a.LanguageName
FROM DWH_dbo.Dim_Affiliate a
WHERE a.AffiliateID = @affiliateId;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched specifically for this dormant table. See `DWH_dbo.Dim_Affiliate` wiki for comprehensive Atlassian coverage of the affiliate domain, including:
- [Affiliates - System Document](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11497250033/Affiliates+-+System+Document) — AffWizz platform overview
- [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) — confirms fiktivo.dbo.tblaff_* as DWH affiliate sources

---

*Generated: 2026-04-27 | Quality: 3.5/10 (★★☆☆☆) | Phases: 7/14 (P4,P5,P7,P9,P9B,P10 skipped — dormant table)*
*Tiers: 0 T1, 0 T2, 0 T3, 11 T3b, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10*
*Object: BI_DB_dbo.BI_DB_AffData | Type: Table | Production Source: Unknown (dormant) — no writer SP found*
