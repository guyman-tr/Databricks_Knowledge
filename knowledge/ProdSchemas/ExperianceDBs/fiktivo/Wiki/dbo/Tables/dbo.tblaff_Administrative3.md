# dbo.tblaff_Administrative3

> System configuration table (singleton row) storing affiliate platform settings for optional field labels, custom field names, tier 2 literature, agreement links, and file path configuration.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.tblaff_Administrative3 is the third part of the affiliate system's singleton configuration tables (alongside tblaff_Administrative, tblaff_Administrative2, tblaff_Administrative4). It stores configurable labels for optional/custom fields in the Sales and Leads modules, the affiliate agreement URL, tier 2 marketing literature HTML, and file export path settings.

This table enables platform administrators to customize the affiliate portal's field labels and content without code changes. The `SalesOptional*` and `LeadsOptional*` fields control how optional columns (Optional1-3) in tblaff_Sales and tblaff_Leads are labeled in the UI. The `AffiliateCustom*` fields control custom field labels in the affiliate profile.

---

## 2. Business Logic

### 2.1 Dynamic Field Labeling

**What**: Optional/custom fields across multiple modules can be renamed via configuration.

**Columns/Parameters Involved**: `SalesOptional1-3`, `LeadsOptional1-3`, `AffiliateCustom1-5`

**Rules**:
- SalesOptional2 = "FirstTimeClosePosition" reveals that the Sales table's Optional2 column stores first-time close position data
- SalesOptional3 = "Customer ID" reveals that the Sales table's Optional3 column stores the CID
- LeadsOptional3 = "Customer ID" - same pattern for Leads
- AffiliateCustom1 = "Last Name" - affiliate profile custom field 1 stores surname

### 2.2 Tier 2 Marketing Content

**What**: HTML marketing literature shown to affiliates about the tier 2 sub-affiliate program.

**Columns/Parameters Involved**: `Tier2Literature`

**Rules**:
- Contains HTML describing the 10% second-tier commission structure
- Explains that tier 2 commissions are calculated on the default 25% Revenue Share plan
- Displayed in the affiliate portal's tier 2 recruitment section

---

## 3. Data Overview

| ID | AgreementLink | SalesOptional2 | LeadsOptional3 | AffiliateCustom1 | Meaning |
|---|---|---|---|---|---|
| 1 | http://www.etoro.com/partners/terms.html | FirstTimeClosePosition | Customer ID | Last Name | Singleton config: Terms link points to partner agreement. Sales Optional2 tracks first-position-close events. Custom1 = surname field. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Singleton primary key (always 1). NOT FOR REPLICATION. |
| 2 | SalesOptional1 | nvarchar(100) | YES | - | VERIFIED | UI label for tblaff_Sales.Optional1 column. Value: "Optional 1" (generic). |
| 3 | SalesOptional2 | nvarchar(100) | YES | - | VERIFIED | UI label for tblaff_Sales.Optional2 column. Value: "FirstTimeClosePosition" - reveals this optional field stores first close position data. |
| 4 | SalesOptional3 | nvarchar(100) | YES | - | VERIFIED | UI label for tblaff_Sales.Optional3 column. Value: "Customer ID" - confirms Optional3 stores CID across Sales/Leads tables. |
| 5 | LeadsOptional1 | nvarchar(100) | YES | - | VERIFIED | UI label for tblaff_Leads.Optional1. Value: "Optional 1" (generic). |
| 6 | LeadsOptional2 | nvarchar(100) | YES | - | VERIFIED | UI label for tblaff_Leads.Optional2. Value: "Optional 2" (generic). |
| 7 | LeadsOptional3 | nvarchar(100) | YES | - | VERIFIED | UI label for tblaff_Leads.Optional3. Value: "Customer ID". |
| 8 | AgreementLink | nvarchar(500) | YES | - | VERIFIED | URL to the affiliate program terms and conditions page. |
| 9 | AffiliateCustom1 | nvarchar(100) | YES | - | VERIFIED | UI label for tblaff_Affiliates.AffiliateCustom1. Value: "Last Name". |
| 10 | AffiliateCustom2 | nvarchar(100) | YES | - | CODE-BACKED | UI label for AffiliateCustom2. Currently blank. |
| 11 | AffiliateCustom3 | nvarchar(100) | YES | - | CODE-BACKED | UI label for AffiliateCustom3. Currently blank. |
| 12 | AffiliateCustom4 | nvarchar(100) | YES | - | CODE-BACKED | UI label for AffiliateCustom4. Currently blank. |
| 13 | AffiliateCustom5 | nvarchar(100) | YES | - | CODE-BACKED | UI label for AffiliateCustom5. Currently blank. |
| 14 | Tier2Literature | ntext | YES | - | VERIFIED | HTML content describing the tier 2 sub-affiliate program (10% second-tier commissions on 25% rev share). Displayed in the affiliate recruitment section. |
| 15 | PriorityFolderPath | nvarchar(350) | YES | - | CODE-BACKED | Local file system path for priority file exports. Value: "c:\\temp". |
| 16 | AffiliateFilenamePrefix | nvarchar(10) | YES | - | CODE-BACKED | Filename prefix for affiliate export files. Value: "sup". |
| 17 | TransactionFilenamePrefix | nvarchar(10) | YES | - | CODE-BACKED | Filename prefix for transaction export files. Value: "ty". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_Administrative3 | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Read all configuration
```sql
SELECT * FROM dbo.tblaff_Administrative3 WITH (NOLOCK)
```

### 8.2 Get optional field label mappings
```sql
SELECT SalesOptional1, SalesOptional2, SalesOptional3,
       LeadsOptional1, LeadsOptional2, LeadsOptional3
FROM dbo.tblaff_Administrative3 WITH (NOLOCK)
```

### 8.3 Get custom affiliate field labels
```sql
SELECT AffiliateCustom1, AffiliateCustom2, AffiliateCustom3,
       AffiliateCustom4, AffiliateCustom5
FROM dbo.tblaff_Administrative3 WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 8.2/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Administrative3 | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Administrative3.sql*
