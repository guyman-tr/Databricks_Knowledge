# Dictionary.SuitabilityTestStatus

> Classifies the outcome of MiFID II suitability assessments for customer trading eligibility.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SuitabilityTestStatusID (int, PK) |
| **Row Count** | 3 |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

### What It Is
Dictionary.SuitabilityTestStatus is a lookup table containing the possible outcomes of the MiFID II suitability assessment that regulated customers must complete before trading certain financial instruments.

### Why It Exists
Under EU MiFID II regulations, brokers must assess whether customers have sufficient experience and whether investment objectives align with the products they want to trade. This table codifies the three possible assessment outcomes, enabling the platform to enforce appropriate trading restrictions or warnings for customers deemed unsuitable.

### How It Works
The `SuitabilityTestStatusID` is stored in `BackOffice.Customer` and `BackOffice.Suitability` tables. When a customer completes the suitability questionnaire, the result is classified as Suitable, NotSuitableXp (insufficient experience), or NotSuitableObjectives (mismatched investment objectives). Procedures like `BackOffice.UpdateRiskUserInfo` write this status, and `Billing.GetUserRegulationAndSuitabiltyTest` reads it to determine trading eligibility and warnings.

---

## 2. Business Logic

### Value Map (Complete — 3 rows)

| SuitabilityTestStatusID | Name | Business Meaning |
|-------------------------|------|------------------|
| 1 | Suitable | Customer has adequate experience AND appropriate investment objectives for the requested instruments |
| 2 | NotSuitableXp | Customer lacks sufficient trading experience — may receive warnings or restrictions on complex products |
| 3 | NotSuitableObjectives | Customer's stated investment objectives don't align with the risk profile of the requested instruments |

### Regulatory Context
- **MiFID II Article 25(2)**: Requires suitability assessment for investment advice and portfolio management
- Two independent failure axes: experience (Xp) and objectives — a customer can fail on either dimension independently
- "Suitable" is the only status that allows unrestricted access to all available instruments

---

## 3. Data Overview

| SuitabilityTestStatusID | Name | Scenario |
|-------------------------|------|----------|
| 1 | Suitable | Experienced retail trader with growth objectives → approved for CFD trading |
| 2 | NotSuitableXp | New user with no prior trading experience → warning shown before CFD trades |
| 3 | NotSuitableObjectives | Conservative investor seeking capital preservation → flagged for leveraged products |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SuitabilityTestStatusID | int | NO | — | HIGH | Primary key identifying the suitability outcome. `1`=Suitable, `2`=NotSuitableXp, `3`=NotSuitableObjectives. Referenced by BackOffice.Customer and BackOffice.Suitability. |
| 2 | Name | varchar(50) | NO | — | HIGH | Assessment outcome label. Used in BackOffice UI and regulatory reporting. |

---

## 5. Relationships

### Referenced By (Implicit — no declared FK)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| BackOffice.Customer | SuitabilityTestStatusID | Implicit FK → SuitabilityTestStatusID | Column in BackOffice customer table |
| BackOffice.Suitability | SuitabilityTestStatusID | Implicit FK → SuitabilityTestStatusID | Dedicated suitability tracking table |
| History.BackOfficeCustomer | SuitabilityTestStatusID | Implicit FK → SuitabilityTestStatusID | Historical BackOffice customer snapshots |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| BackOffice.UpdateRiskUserInfo | UPDATE | Sets suitability status after assessment |
| BackOffice.UpdateRiskUserInfoRemote | UPDATE | Remote version of risk info update |
| BackOffice.Bulk_UpdateRiskUserInfoRemote | UPDATE (bulk) | Bulk suitability status updates |
| Billing.GetUserRegulationAndSuitabiltyTest | SELECT | Reads suitability status for billing/trading eligibility checks |
| Customer.GetRiskUserInfo | SELECT | Returns suitability status as part of risk profile |

### Type Consumers

| User Defined Type | Context |
|-------------------|---------|
| BackOffice.RiskUserInfo | TVP that includes SuitabilityTestStatusID for bulk operations |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `BackOffice.Customer` — stores suitability status per customer
- `BackOffice.Suitability` — dedicated suitability assessment table
- `History.BackOfficeCustomer` — historical customer data
- 5+ procedures for risk assessment and billing

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| (unnamed PK) | CLUSTERED PK | SuitabilityTestStatusID ASC | Default PK constraint |

---

## 8. Sample Queries

```sql
-- Get all suitability statuses
SELECT  SuitabilityTestStatusID,
        Name
FROM    Dictionary.SuitabilityTestStatus WITH (NOLOCK)
ORDER BY SuitabilityTestStatusID;

-- Count customers by suitability outcome
SELECT  sts.Name AS SuitabilityStatus,
        COUNT(*) AS CustomerCount
FROM    BackOffice.Customer bc WITH (NOLOCK)
JOIN    Dictionary.SuitabilityTestStatus sts WITH (NOLOCK)
        ON bc.SuitabilityTestStatusID = sts.SuitabilityTestStatusID
GROUP BY sts.Name
ORDER BY CustomerCount DESC;

-- Find customers with unsuitable experience
SELECT  bc.CID,
        sts.Name AS SuitabilityStatus
FROM    BackOffice.Customer bc WITH (NOLOCK)
JOIN    Dictionary.SuitabilityTestStatus sts WITH (NOLOCK)
        ON bc.SuitabilityTestStatusID = sts.SuitabilityTestStatusID
WHERE   sts.SuitabilityTestStatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `SuitabilityTestStatus`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.SuitabilityTestStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.SuitabilityTestStatus.sql*
