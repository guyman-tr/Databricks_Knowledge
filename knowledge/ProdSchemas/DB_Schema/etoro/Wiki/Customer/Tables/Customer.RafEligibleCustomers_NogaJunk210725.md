# Customer.RafEligibleCustomers_NogaJunk210725

> Temporary RAF eligibility staging table (Noga Rozen, July 2025): pre-computed referring/referred customer pairs with their regulation, country, player level, and RAF status at the time of batch processing.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (ReferringCID, ReferredCID) composite PK |
| **Partition** | No (DICTIONARY filegroup, PAGE compression) |
| **Indexes** | 1 (clustered composite PK only) |

---

## 1. Business Meaning

Customer.RafEligibleCustomers_NogaJunk210725 is a temporary work table created as part of the July 2025 RAF (Refer-A-Friend) program refactoring by Noga Rozen. The "_NogaJunk210725" suffix is a naming convention indicating this is a developer-created working table, potentially pending removal or promotion to a permanent table after the project phase completes.

Each row represents a (referring customer, referred customer) pair identified during a RAF eligibility batch scan, along with contextual data captured at the time of processing: regulation IDs, country IDs, player level of the referring customer, and the current RAF pipeline status for this pair. This context data helps the RAF compensation service determine what rules apply (regulation-specific eligibility, country-specific configurations) without re-querying customer data on each processing pass.

This table currently has 7 rows on this environment, consistent with a testing or dev environment for the July 2025 RAF project. Customer.RAFCompensationProcess_NogaJunk210725 is the primary orchestration procedure that interacts with this table.

---

## 2. Business Logic

### 2.1 RafStatus Pipeline States

**What**: RafStatus tracks the processing stage of each eligible RAF pair through the compensation pipeline.

**Columns/Parameters Involved**: `RafStatus`, `ReferringCID`, `ReferredCID`

**Rules**:
- NULL: not yet processed
- Customer.SetRafCompensation return codes (also used as RafStatus values): 0=Done, 1=Busy-retry, 2=LimitReached, 3=AlreadyGiven, 4=NotValid, 5=Failed
- Code comment: `UPDATE RafEligibleCustomers SET RafStatus=4 WHERE ReferringCID=@ReferringCID AND ReferredCID=@ReferredCID` (commented out in SetRafCompensation as of July 2025 - "not in use in new RAF compensation")

---

## 3. Data Overview

*7 rows in this environment (test/dev). Table stores eligible RAF pairs identified by RAFCompensationProcess_NogaJunk210725 for the July 2025 RAF project. Full data not queried to avoid PII exposure.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReferringCID | bigint | NO | - | VERIFIED | CID of the customer who made the referral. Part of composite PK. Uses bigint (vs int in RAFGiven) - possibly for compatibility with a data lake schema. |
| 2 | ReferredCID | bigint | NO | - | VERIFIED | CID of the newly registered referred customer. Part of composite PK. Bigint type. |
| 3 | ReferringRegulationId | int | YES | - | CODE-BACKED | Regulation ID applicable to the referring customer at time of RAF processing. Used to apply regulation-specific eligibility rules (e.g., US customers have different wait periods). |
| 4 | ReferringCountryId | int | YES | - | CODE-BACKED | Country ID of the referring customer. Captured at processing time for configuration lookup (Customer.CountryRafConfiguration_NogaJunk210725). |
| 5 | ReferringPlayerLevelId | int | YES | - | CODE-BACKED | Player level (e.g., Silver, Gold, Platinum) of the referring customer. Used for eligibility filtering - Platinum, Platinum Plus, and Diamond are excluded from fraud procedures (PART-3907). |
| 6 | ReferringPILevel | int | YES | - | NAME-INFERRED | Popular Investor level of the referring customer at processing time. May be used for RAF eligibility gating related to the PI program. |
| 7 | ReferredRegulationId | int | YES | - | CODE-BACKED | Regulation ID applicable to the referred customer. Used for regulation-specific minimum deposit and waiting period rules. |
| 8 | ReferredCountryId | int | YES | - | CODE-BACKED | Country ID of the referred customer. Used for country-specific RAF configuration lookup. |
| 9 | CreatedDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when this eligibility record was created by the batch process. Default = getutcdate(). |
| 10 | RafStatus | int | YES | - | CODE-BACKED | Current pipeline status for this pair. NULL = pending. Values mirror Customer.SetRafCompensation return codes: 0=Done, 1=Busy, 2=LimitReached, 3=AlreadyGiven, 4=NotValid, 5=Failed. The UPDATE path was commented out in July 2025 refactoring. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReferringCID, ReferredCID | Customer.CustomerStatic | Implicit | No FK enforced; CIDs reference registered customers |
| ReferringRegulationId | Dictionary (regulations) | Implicit | Regulation classification for RAF rule lookup |
| ReferringCountryId, ReferredCountryId | Dictionary.Country | Implicit | Country for RAF configuration lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RAFCompensationProcess_NogaJunk210725 | ReferringCID, ReferredCID | Writer + Reader | Primary write path; processes eligible pairs through compensation pipeline |
| Customer.RafViewCustomerStatus_NogaJunk210725 | ReferringCID, ReferredCID | View | Reads eligibility status for RAF status display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafEligibleCustomers_NogaJunk210725 (table)
```
No structural dependencies (no FKs).

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| No formal dependencies. | - | Implicit CID references via application logic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RAFCompensationProcess_NogaJunk210725 | Stored Procedure | Writer + Reader - RAF batch orchestration |
| Customer.RafViewCustomerStatus_NogaJunk210725 | View | Reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RafEligibleCustomers | Clustered PK | ReferringCID ASC, ReferredCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_RafEligibleCustomers_CreatedDate | DEFAULT | CreatedDate = getutcdate() |

---

## 8. Sample Queries

### 8.1 View all eligible RAF pairs and their pipeline status
```sql
SELECT
    rec.ReferringCID,
    rec.ReferredCID,
    rec.RafStatus,
    rec.ReferringRegulationId,
    rec.ReferredRegulationId,
    rec.CreatedDate
FROM Customer.RafEligibleCustomers_NogaJunk210725 rec WITH (NOLOCK)
ORDER BY rec.CreatedDate DESC;
```

### 8.2 Find pairs still pending processing (RafStatus NULL)
```sql
SELECT ReferringCID, ReferredCID, CreatedDate
FROM Customer.RafEligibleCustomers_NogaJunk210725 WITH (NOLOCK)
WHERE RafStatus IS NULL
ORDER BY CreatedDate;
```

### 8.3 Summary by RafStatus
```sql
SELECT
    ISNULL(CAST(RafStatus AS varchar(5)), 'NULL') AS Status,
    COUNT(*) AS Count
FROM Customer.RafEligibleCustomers_NogaJunk210725 WITH (NOLOCK)
GROUP BY RafStatus
ORDER BY RafStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED (ReferringPILevel) | Phases: 1,2,3,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (RAFCompensationProcess) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.RafEligibleCustomers_NogaJunk210725 | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.RafEligibleCustomers_NogaJunk210725.sql*
