# Dictionary.FundingStatus

> Lookup table defining whether a user's account funding meets platform requirements (Partial vs Valid).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FundingStatusID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FundingStatus is a simple two-value lookup indicating whether a user's deposit history meets the platform's minimum funding requirements. This is used as a gate for certain features or trading capabilities.

The distinction between Partial and Valid typically relates to first-time-deposit (FTD) thresholds or minimum balance requirements that vary by regulation. A user in Partial status may have deposited but hasn't yet met the full requirement for unrestricted access.

FundingStatusID is stored in customer funding records and checked by procedures that gate feature access based on funding level.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| FundingStatusID | FundingStatusName | Meaning |
|---|---|---|
| 0 | Partial | User has deposited but hasn't met the full funding threshold. Some features may be restricted until the minimum is reached. The threshold varies by regulation and account type. |
| 1 | Valid | User has met or exceeded the minimum funding requirement. Full access to all funding-gated features. This is the target state for all active trading accounts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingStatusID | int | NO | - | CODE-BACKED | Primary key. 0=Partial (below minimum), 1=Valid (meets requirement). See [Funding Status](_glossary.md#funding-status). (Dictionary.FundingStatus) |
| 2 | FundingStatusName | nvarchar(100) | NO | - | CODE-BACKED | Human-readable label. Used in back-office reporting and customer status displays. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer funding tables | FundingStatusID | Implicit Lookup | Stores funding state per customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer funding tables | Table | Stores FundingStatusID per customer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed) | CLUSTERED PK | FundingStatusID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List funding statuses
```sql
SELECT FundingStatusID, FundingStatusName
FROM [Dictionary].[FundingStatus] WITH (NOLOCK) ORDER BY FundingStatusID;
```

### 8.2 Count customers by funding status
```sql
SELECT fs.FundingStatusName, COUNT(*) AS CustomerCount
FROM [Customer].[CustomerToFundingStatus] ctf WITH (NOLOCK)
JOIN [Dictionary].[FundingStatus] fs WITH (NOLOCK) ON ctf.FundingStatusID = fs.FundingStatusID
GROUP BY fs.FundingStatusName;
```

### 8.3 Find customers with partial funding
```sql
SELECT ctf.CID, fs.FundingStatusName
FROM [Customer].[CustomerToFundingStatus] ctf WITH (NOLOCK)
JOIN [Dictionary].[FundingStatus] fs WITH (NOLOCK) ON ctf.FundingStatusID = fs.FundingStatusID
WHERE ctf.FundingStatusID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.FundingStatus.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FundingStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FundingStatus.sql*
