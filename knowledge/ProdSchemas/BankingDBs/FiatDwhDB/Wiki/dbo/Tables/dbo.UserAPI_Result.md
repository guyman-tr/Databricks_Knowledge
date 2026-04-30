# dbo.UserAPI_Result

> Result/output staging table that combines customer account data with KYC financial profile data, likely produced by joining FiatDwhDB account info with UserAPI KYC data.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap table) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

UserAPI_Result is an output staging table that merges customer fiat account information (Gcid, AccountId, ProviderHolderId, TCLACurrencyISON) with KYC financial profile data (AnswerText, MinThreshold, MaxThreshold, AnswerId, TCLAAmount, Occupation). It appears to be the result of joining dbo.FiatAccount/AccountsProviderHoldersMapping data with dbo.UserAPI_prod data, producing a combined dataset for downstream processing or export.

This table exists as an intermediate result set for a data pipeline that enriches fiat account records with customer KYC information. It may be consumed by external reporting systems, compliance tools, or data exports.

Note: All non-GCID columns are nvarchar(500), suggesting this is a flexible output table designed for export rather than querying. No PK constraint allows duplicate records.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a derived output table.

---

## 3. Data Overview

N/A - output staging table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. The only typed column (bigint vs nvarchar for others). |
| 2 | AccountId | nvarchar(500) | NO | - | CODE-BACKED | Fiat account identifier, stored as string. Sourced from dbo.FiatAccount. |
| 3 | ProviderHolderId | nvarchar(500) | NO | - | CODE-BACKED | Provider-side holder identifier from dbo.AccountsProviderHoldersMapping. Identifies the customer in Tribe's system. |
| 4 | TCLACurrencyISON | nvarchar(500) | NO | - | NAME-INFERRED | ISO currency code for the TCLA assessment. Indicates which currency the TCLA amount is denominated in. |
| 5 | AnswerText | nvarchar(500) | NO | - | NAME-INFERRED | KYC questionnaire answer text. Sourced from UserAPI_prod. |
| 6 | MinThreshold | nvarchar(500) | NO | - | NAME-INFERRED | Minimum income threshold from KYC. |
| 7 | MaxThreshold | nvarchar(500) | NO | - | NAME-INFERRED | Maximum income threshold from KYC. |
| 8 | AnswerId | nvarchar(500) | NO | - | NAME-INFERRED | KYC answer option identifier. |
| 9 | TCLAAmount | nvarchar(500) | NO | - | NAME-INFERRED | Total Credit Limit Assessment amount. |
| 10 | Occupation | nvarchar(500) | NO | - | NAME-INFERRED | Customer's declared occupation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Gcid | dbo.FiatAccount (via Gcid) | Implicit | Links to customer's fiat account |
| ProviderHolderId | dbo.AccountsProviderHoldersMapping | Implicit | Provider-side customer identifier |

### 5.2 Referenced By (other objects point to this)

No objects reference this output staging table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up a customer's combined data
```sql
SELECT * FROM dbo.UserAPI_Result WITH (NOLOCK) WHERE Gcid = 12345;
```

### 8.2 Check for duplicate GCIDs
```sql
SELECT Gcid, COUNT(*) AS Cnt
FROM dbo.UserAPI_Result WITH (NOLOCK)
GROUP BY Gcid HAVING COUNT(*) > 1;
```

### 8.3 Count rows by currency
```sql
SELECT TCLACurrencyISON, COUNT(*) AS Cnt
FROM dbo.UserAPI_Result WITH (NOLOCK)
GROUP BY TCLACurrencyISON ORDER BY Cnt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.0/10 (Elements: 5.4/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.UserAPI_Result | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.UserAPI_Result.sql*
