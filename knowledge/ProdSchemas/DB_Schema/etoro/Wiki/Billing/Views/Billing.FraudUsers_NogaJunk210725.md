# Billing.FraudUsers_NogaJunk210725

> JUNK/deprecated cross-schema proxy view that was a backward-compatibility alias for Customer.FraudUsers - a table that paired suspected fraud-linked customer accounts with similarity scoring; both objects marked for deletion by Noga on 2025-07-21 and no longer deployed.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | N/A - view not deployed in live database |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.FraudUsers_NogaJunk210725` is a **deprecated** cross-schema proxy view - a SELECT * FROM Customer.FraudUsers wrapper that existed to preserve backward compatibility after the original `Billing.FraudUsers` table was migrated to the Customer schema. The code comment in the DDL confirms the intent: "Replace original table with view."

The underlying data concept (now also JUNK-marked) was a fraud detection result table that stored pairs of customer accounts identified as potentially linked through fraud analysis. Each row compared two customers (CID and CID2) across multiple personally-identifiable attributes - username, name, address, city, country, IP subnet, birth date - with similarity/distance scores for each attribute (e.g., `UserName_Dif`, `LastName_Dif`, `Address_Dif`). A `Fraud_Type`, `Status`, and `Recommendation` column tracked the investigation outcome.

Neither this view nor its base table (`Customer.FraudUsers` / `Customer.FraudUsers_NogaJunk210725`) is deployed in the current live database. Both are scheduled for removal as part of the 2025-07-21 cleanup by Noga. Any code referencing `Billing.FraudUsers` should be migrated to the authoritative fraud detection data source (likely Customer schema or a dedicated compliance system).

---

## 2. Business Logic

### 2.1 Customer Pair Similarity Analysis (Deprecated)

**What**: The underlying table held the results of a fraud matching algorithm that compared two customer accounts across PII fields to identify possible multi-accounting or identity fraud.

**Columns/Parameters Involved**: `CID`, `CID2`, `IP_Dif`, `Zip_Dif`, `UserName_Dif`, `BirthDateApart`, `FirstName_Dif`, `LastName_Dif`, `Address_Dif`, `City_Dif`, `Main_Scoring`

**Rules** (from DDL of Customer.FraudUsers_NogaJunk210725):
- `*_Dif` columns store integer difference/distance scores between the two customers' attribute values (0 = identical, higher = more different)
- `BirthDateApart` tracks days between the two customers' birth dates
- `Main_Scoring` is an aggregate similarity score combining the individual attribute differences
- `Fraud_Type` categorizes the type of fraud detected (e.g., "multi-account", "identity theft")
- `Status` tracks the investigation state of the flagged pair
- `Recommendation` records the recommended action (block/review/clear)
- All PII columns (UserName, FirstName, LastName, Address, City, Country) have Dynamic Data Masking applied (`MASKED WITH (FUNCTION = 'default()')`) - users without UNMASK permission see masked values

---

## 3. Data Overview

N/A - the view is not deployed in the live database (`Invalid object name 'Billing.FraudUsers_NogaJunk210725'` error on query). No live data available.

---

## 4. Elements

All elements are inherited from the underlying Customer.FraudUsers_NogaJunk210725 table via SELECT *:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | NAME-INFERRED | Funding/deposit transaction identifier that triggered the fraud match. Likely the FundingID from Billing.Funding that linked these two customers. |
| 2 | CID | int | NO | - | CODE-BACKED | First customer ID in the fraud-paired comparison. Indexed (IX_BillingFraudUsers_CID). References Customer schema. |
| 3 | CID2 | int | NO | - | CODE-BACKED | Second customer ID in the fraud-paired comparison - the account suspected to be linked to CID. Indexed (IX_BillingFraudUsers_CID2). |
| 4 | UserName | varchar(20) | NO | - | CODE-BACKED | Username of CID. MASKED - returns masked value to users without UNMASK permission. |
| 5 | UserName2 | varchar(20) | NO | - | CODE-BACKED | Username of CID2. MASKED. Used together with UserName for username similarity comparison. |
| 6 | FirstName | varchar(50) | YES | - | CODE-BACKED | First name of CID. MASKED. Used in name similarity scoring. |
| 7 | FirstName2 | varchar(50) | YES | - | CODE-BACKED | First name of CID2. MASKED. |
| 8 | LastName | varchar(50) | YES | - | CODE-BACKED | Last name of CID. MASKED. |
| 9 | LastName2 | varchar(50) | YES | - | CODE-BACKED | Last name of CID2. MASKED. |
| 10 | Address | varchar(100) | YES | - | CODE-BACKED | Registered address of CID. MASKED. |
| 11 | Address2 | varchar(100) | YES | - | CODE-BACKED | Registered address of CID2. MASKED. |
| 12 | City | varchar(50) | YES | - | CODE-BACKED | Registered city of CID. MASKED. |
| 13 | City2 | varchar(50) | YES | - | CODE-BACKED | Registered city of CID2. MASKED. |
| 14 | Country | varchar(50) | NO | - | CODE-BACKED | Registered country of CID. MASKED. Not nullable - all customers have a country. |
| 15 | Country2 | varchar(50) | NO | - | CODE-BACKED | Registered country of CID2. MASKED. |
| 16 | IP_Dif | int | NO | - | CODE-BACKED | Integer distance score for IP address similarity between CID and CID2. 0 = same IP subnet. Higher values indicate more dissimilar IP patterns. |
| 17 | Zip_Dif | int | NO | - | CODE-BACKED | Integer distance score for postal/zip code similarity. 0 = identical zip codes. |
| 18 | UserName_Dif | int | YES | - | CODE-BACKED | String similarity distance for username comparison. NULL if not computed. |
| 19 | BirthDateApart | int | NO | - | CODE-BACKED | Number of days between the two customers' birth dates. 0 = same birth date (strong fraud signal). |
| 20 | FirstName_Dif | int | YES | - | CODE-BACKED | String similarity distance for first name comparison. NULL if not computed. |
| 21 | LastName_Dif | int | YES | - | CODE-BACKED | String similarity distance for last name comparison. NULL if not computed. |
| 22 | Address_Dif | int | YES | - | CODE-BACKED | String similarity distance for address comparison. NULL if not computed. |
| 23 | City_Dif | int | YES | - | CODE-BACKED | String similarity distance for city comparison. NULL if not computed. |
| 24 | Main_Scoring | int | YES | - | CODE-BACKED | Composite fraud score combining individual attribute scores. Higher scores indicate stronger fraud signal. Used for prioritizing investigation queue. |
| 25 | SharedFund | int | NO | - | NAME-INFERRED | Number of shared funding sources (e.g., same credit card) between CID and CID2. Non-zero is a strong multi-accounting indicator. |
| 26 | Fraud_Type | varchar(25) | NO | - | CODE-BACKED | Category of fraud detected (e.g., "multi-account", "identity theft"). Populated by the fraud detection algorithm. |
| 27 | Status | varchar(25) | NO | - | CODE-BACKED | Current investigation status of this fraud pair (e.g., "Pending", "Confirmed", "Cleared"). Tracks where the compliance team is in the review process. |
| 28 | Recommendation | varchar(25) | NO | - | CODE-BACKED | Recommended action for this fraud pair (e.g., "Block", "Review", "Allow"). Output of the fraud analysis algorithm. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | Customer.FraudUsers | Source (FROM - cross-schema) | Full pass-through of all columns from Customer.FraudUsers (also JUNK-marked as Customer.FraudUsers_NogaJunk210725 in SSDT) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not deployed - no active consumers | - | - | View is undeployed; any historical consumers should be migrated |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FraudUsers_NogaJunk210725 (view - UNDEPLOYED/JUNK)
└── Customer.FraudUsers (table - UNDEPLOYED/JUNK, renamed to Customer.FraudUsers_NogaJunk210725 in SSDT)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.FraudUsers | Table | SELECT * source (not deployed in live DB; both objects are JUNK-marked) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No active dependents | - | View is deprecated |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. The underlying table had two NC indexes: IX_BillingFraudUsers_CID (on CID, includes CID2/Status/Recommendation) and IX_BillingFraudUsers_CID2 (on CID2, includes CID/Status/Recommendation).

### 7.2 Constraints

N/A for view. The underlying table had Dynamic Data Masking on all PII columns (UserName, FirstName, LastName, Address, City, Country and their *2 counterparts). No PK was defined on the base table.

---

## 8. Sample Queries

### 8.1 Query (will fail - object not deployed)

```sql
-- NOTE: This view is not deployed in the live database.
-- The following query will return "Invalid object name" error.
SELECT * FROM Billing.FraudUsers_NogaJunk210725 WITH (NOLOCK)
-- Use the authoritative fraud data source instead
```

### 8.2 Find high-confidence fraud pairs by scoring (if deployed)

```sql
SELECT CID, CID2, Main_Scoring, Fraud_Type, Status, Recommendation, SharedFund
FROM Billing.FraudUsers_NogaJunk210725 WITH (NOLOCK)
WHERE Main_Scoring >= 80
  AND Status = 'Pending'
ORDER BY Main_Scoring DESC
```

### 8.3 Find customers sharing the same birth date and IP subnet

```sql
SELECT CID, CID2, BirthDateApart, IP_Dif, SharedFund, Fraud_Type, Recommendation
FROM Billing.FraudUsers_NogaJunk210725 WITH (NOLOCK)
WHERE BirthDateApart = 0
  AND IP_Dif = 0
ORDER BY Main_Scoring DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.2/10 (Elements: 8.6/10, Logic: 7/10, Relationships: 5/10, Sources: 3/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FraudUsers_NogaJunk210725 | Type: View | Source: etoro/etoro/Billing/Views/Billing.FraudUsers_NogaJunk210725.sql*
