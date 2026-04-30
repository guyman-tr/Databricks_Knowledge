# Customer.FraudUsers_NogaJunk210725

> Fraud detection result table storing pairs of potentially linked customer accounts with similarity scoring metrics (IP, ZIP, birthdate, name proximity), shared funding amounts, and fraud classification - used by Customer.CheckFraudUsers_NogaJunk210725 to identify related accounts.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | None (no PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 2 (NC on CID, NC on CID2) |

---

## 1. Business Meaning

Customer.FraudUsers_NogaJunk210725 stores the output of a fraud detection algorithm that identifies pairs of customer accounts (CID + CID2) that share suspicious similarities. Each row represents a suspected relationship between two customer accounts, including similarity metrics on key identity fields (IP address, ZIP code, birth date, name, address), a shared funding amount (SharedFund), an aggregate fraud score (Main_Scoring), and a classification of the fraud type and status.

13,689 rows represent 13,689 suspicious account pairs. The dominant fraud type is "ip" (41.9%) - customers sharing the same IP address, followed by "s" (32.3% - likely "same", covering multiple matching criteria), and "Other Fraud" (25.3%). All rows have Status="Fraud" and Recommendation="Unchange", suggesting this is a static snapshot rather than a live enforcement queue.

PII columns (UserName, UserName2, FirstName, FirstName2, LastName, LastName2, Address, Address2, City, City2, Country, Country2) are protected with Dynamic Data Masking (default()).

The "_NogaJunk210725" suffix follows the same naming convention as other tagged tables (CountryRafConfiguration_NogaJunk210725, RafConfigurationModels_NogaJunk210725), indicating it was marked as an experiment or working dataset by Noga's team in July 2025 - but with 13,689 rows and an active consumer procedure, it is a working production fraud detection table.

FundingID links the pair to a specific funding transaction that was the focal point of the fraud investigation. The same FundingID can appear multiple times (multiple CID pairs implicated in the same fraudulent funding event).

---

## 2. Business Logic

### 2.1 Account Pair Similarity Scoring

**What**: Each row encodes similarity metrics between two customer accounts. A value of 0 means the fields match exactly; non-zero values indicate the degree of difference.

**Columns/Parameters Involved**: `IP_Dif`, `Zip_Dif`, `BirthDateApart`, `FirstName_Dif`, `LastName_Dif`, `Address_Dif`, `City_Dif`, `UserName_Dif`, `Main_Scoring`

**Rules**:
- IP_Dif = 0: accounts share the same IP address (high fraud signal)
- Zip_Dif = 0: same ZIP code (moderate signal)
- BirthDateApart = 0: same birth date (strong duplicate signal)
- FirstName_Dif, LastName_Dif, Address_Dif, City_Dif: edit distance or binary match metrics for name/address fields
- Main_Scoring: aggregate fraud score (higher = more suspicious). Top scores = 23 in sample data.
- SharedFund: total USD amount moved between accounts via the FundingID transaction

### 2.2 Fraud Type Classification

**What**: Fraud_Type categorizes the primary reason for flagging this account pair.

**Columns/Parameters Involved**: `Fraud_Type`, `Status`, `Recommendation`

**Rules**:
- "ip" (41.9%): primary signal is shared IP address
- "s" (32.3%): multiple shared signals (likely "same" across multiple fields)
- "Other Fraud" (25.3%): fraud detected but doesn't fit standard categories
- "zip" (0.4%): primary signal is shared ZIP
- Status="Fraud": all current rows classified as fraud (investigation complete)
- Recommendation="Unchange": accounts remain as-is (no immediate action taken) - either insufficient evidence to close or case under review
- Status and Recommendation are free-text varchar(25) - not FK-constrained to lookup tables

---

## 3. Data Overview

| FundingID | CID | CID2 | IP_Dif | BirthDateApart | Main_Scoring | SharedFund | Fraud_Type | Status |
|---|---|---|---|---|---|---|---|---|
| 813345 | 9763147 | 10835932 | 0 | 0 | 23 | 3,655 | Other Fraud | Fraud |
| 813345 | 9763147 | 10909239 | 0 | 0 | 23 | 3,655 | Other Fraud | Fraud |
| 813345 | 10744943 | 10908498 | 0 | 0 | 23 | 3,655 | on | Fraud |

*13,689 total rows. Fraud_Type distribution: "ip" 5,738, "s" 4,418, "Other Fraud" 3,467, "zip" 58, others 8. All Status="Fraud". FundingID 813345 appears in multiple rows - a single funding event implicated many account pairs.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Funding transaction ID that triggered this fraud investigation. Multiple rows can share the same FundingID (one funding event, multiple suspicious account pairs). |
| 2 | CID | int | NO | - | CODE-BACKED | First customer account in the suspected pair. Indexed via IX_BillingFraudUsers_CID. |
| 3 | CID2 | int | NO | - | CODE-BACKED | Second customer account in the suspected pair. Indexed via IX_BillingFraudUsers_CID2. |
| 4 | UserName | varchar(20) | NO | - | CODE-BACKED | Username of CID. **Dynamic Data Masking: default()** - PII protected. |
| 5 | UserName2 | varchar(20) | NO | - | CODE-BACKED | Username of CID2. **Dynamic Data Masking: default()** |
| 6 | FirstName | varchar(50) | YES | - | CODE-BACKED | First name of CID. **Dynamic Data Masking: default()** |
| 7 | FirstName2 | varchar(50) | YES | - | CODE-BACKED | First name of CID2. **Dynamic Data Masking: default()** |
| 8 | LastName | varchar(50) | YES | - | CODE-BACKED | Last name of CID. **Dynamic Data Masking: default()** |
| 9 | LastName2 | varchar(50) | YES | - | CODE-BACKED | Last name of CID2. **Dynamic Data Masking: default()** |
| 10 | Address | varchar(100) | YES | - | CODE-BACKED | Address of CID. **Dynamic Data Masking: default()** |
| 11 | Address2 | varchar(100) | YES | - | CODE-BACKED | Address of CID2. **Dynamic Data Masking: default()** |
| 12 | City | varchar(50) | YES | - | CODE-BACKED | City of CID. **Dynamic Data Masking: default()** |
| 13 | City2 | varchar(50) | YES | - | CODE-BACKED | City of CID2. **Dynamic Data Masking: default()** |
| 14 | Country | varchar(50) | NO | - | CODE-BACKED | Country of CID (text, not ID). **Dynamic Data Masking: default()** |
| 15 | Country2 | varchar(50) | NO | - | CODE-BACKED | Country of CID2. **Dynamic Data Masking: default()** |
| 16 | IP_Dif | int | NO | - | CODE-BACKED | IP address similarity: 0=same IP, >0=different. 0 is the primary signal for "ip" Fraud_Type. |
| 17 | Zip_Dif | int | NO | - | CODE-BACKED | ZIP code similarity: 0=same ZIP, >0=different. |
| 18 | UserName_Dif | int | YES | - | CODE-BACKED | Username similarity metric. Nullable. |
| 19 | BirthDateApart | int | NO | - | CODE-BACKED | Days between birth dates. 0=same birth date (strong duplicate signal). |
| 20 | FirstName_Dif | int | YES | - | CODE-BACKED | First name similarity metric (edit distance or binary). Nullable. |
| 21 | LastName_Dif | int | YES | - | CODE-BACKED | Last name similarity metric. Nullable. |
| 22 | Address_Dif | int | YES | - | CODE-BACKED | Address similarity metric. Nullable. |
| 23 | City_Dif | int | YES | - | CODE-BACKED | City similarity metric. Nullable. |
| 24 | Main_Scoring | int | YES | - | CODE-BACKED | Aggregate fraud score combining all similarity signals. Higher = more suspicious. Nullable. |
| 25 | SharedFund | int | NO | - | CODE-BACKED | Total USD amount of shared/transferred funds associated with this pair via FundingID. |
| 26 | Fraud_Type | varchar(25) | NO | - | CODE-BACKED | Primary fraud classification: "ip" (shared IP), "s" (multiple signals), "Other Fraud", "zip" (shared ZIP), and others. Free-text, not FK-constrained. |
| 27 | Status | varchar(25) | NO | - | CODE-BACKED | Investigation status: "Fraud" for all current rows. Free-text. |
| 28 | Recommendation | varchar(25) | NO | - | CODE-BACKED | Action recommendation: "Unchange" for all current rows (no account action taken). Free-text. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | First customer in pair; no FK |
| CID2 | Customer.CustomerStatic | Implicit | Second customer in pair; no FK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CheckFraudUsers_NogaJunk210725 | CID, CID2 | READER/WRITER | Fraud detection procedure that reads and potentially updates this table |

---

## 6. Dependencies

No FK dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_BillingFraudUsers_CID | NC | CID ASC | CID2, Status, Recommendation | - | Active |
| IX_BillingFraudUsers_CID2 | NC | CID2 ASC | CID, Status, Recommendation | - | Active |

### 7.2 Constraints

No constraints (no PK, no FKs, no defaults).

---

## 8. Sample Queries

### 8.1 Find all fraud pairs for a specific customer

```sql
SELECT
    FundingID,
    CID,
    CID2,
    IP_Dif,
    BirthDateApart,
    Main_Scoring,
    SharedFund,
    Fraud_Type,
    Status,
    Recommendation
FROM Customer.FraudUsers_NogaJunk210725 WITH (NOLOCK)
WHERE CID = 9763147 OR CID2 = 9763147
ORDER BY Main_Scoring DESC
```

### 8.2 Fraud type distribution

```sql
SELECT
    Fraud_Type,
    Status,
    COUNT(*) AS PairCount,
    SUM(SharedFund) AS TotalSharedFunds
FROM Customer.FraudUsers_NogaJunk210725 WITH (NOLOCK)
GROUP BY Fraud_Type, Status
ORDER BY PairCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.FraudUsers_NogaJunk210725 | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.FraudUsers_NogaJunk210725.sql*
