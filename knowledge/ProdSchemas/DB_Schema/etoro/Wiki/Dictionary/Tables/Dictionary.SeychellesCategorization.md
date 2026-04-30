# Dictionary.SeychellesCategorization

## 1. Business Meaning

**What it is**: A lookup table defining client categorization levels under eToro's Seychelles regulatory entity (eToro (Seychelles) Ltd, regulated by FSA). Controls access tiers for customers registered under the Seychelles regulation.

**Why it exists**: The Seychelles Financial Services Authority (FSA) requires categorized client access based on verification and risk assessment. This table defines the progression tiers — from Basic (limited access) through Pending (awaiting verification) to Advanced (full access), with a NotInFlow state for customers exempt from this categorization.

**How it works**: The categorization is stored on `BackOffice.Customer.SeychellesCategorizationID` and managed through `BackOffice.UpdateRiskUserInfo` / `BackOffice.UpdateRiskUserInfoRemote`. The UserApiDB replicates this table for API-layer access checks. Customer risk assessment procedures read and update this value as part of KYC/risk processing. The `History.BackOfficeCustomer` table tracks historical changes.

---

## 2. Business Logic

### Categorization Levels
| ID | Name | Meaning |
|----|------|---------|
| 0 | Basic | Entry-level access — limited trading capabilities, basic KYC |
| 1 | Pending | Verification in progress — awaiting document review or additional checks |
| 2 | Advanced | Full access — complete KYC verified, all trading features unlocked |
| 3 | NotInFlow | Not subject to Seychelles categorization — customer under a different regulation |

### Lifecycle
```
NotInFlow (3) [non-Seychelles customers]
Basic (0) → Pending (1) → Advanced (2) [Seychelles customer progression]
```

---

## 3. Data Overview

| SeychellesCategorizationID | Name | Business Meaning |
|---------------------------|------|------------------|
| 0 | Basic | Limited access, basic KYC |
| 1 | Pending | Verification in progress |
| 2 | Advanced | Full access, KYC complete |
| 3 | NotInFlow | Not applicable (non-Seychelles) |

*4 rows — complete Seychelles regulatory categorization*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **SeychellesCategorizationID** | int | NOT NULL | — | Primary key. Categorization level: 0=Basic, 1=Pending, 2=Advanced, 3=NotInFlow. | `MCP` |
| **Name** | varchar(50) | NOT NULL | — | Human-readable categorization name used in BackOffice UI and risk reports. | `MCP` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| BackOffice.Customer | SeychellesCategorizationID | Implicit FK | Customer's Seychelles regulatory tier |
| History.BackOfficeCustomer | SeychellesCategorizationID | Implicit FK | Historical tracking of categorization changes |
| BackOffice.UpdateRiskUserInfo | @SeychellesCategorizationID | Parameter | Updates customer categorization during risk assessment |
| BackOffice.UpdateRiskUserInfoRemote | @SeychellesCategorizationID | Parameter | Remote update of categorization |
| UserApiDB.Customer.RiskUserInfo | SeychellesCategorizationID | Implicit FK | API-layer customer risk data |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `BackOffice.Customer` — customer categorization storage
- `BackOffice.UpdateRiskUserInfo` — risk assessment update
- `UserApiDB.Customer.RiskUserInfo` — API-layer replication
- 10+ UserApiDB aggregated info procedures

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `SeychellesCategorizationID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | DICTIONARY |
| Row Count | 4 |

---

## 8. Sample Queries

```sql
-- Get all categorizations
SELECT  SeychellesCategorizationID, Name
FROM    Dictionary.SeychellesCategorization WITH (NOLOCK)
ORDER BY SeychellesCategorizationID;

-- Customer distribution by Seychelles categorization
SELECT  SC.Name, COUNT(*) AS CustomerCount
FROM    BackOffice.Customer BC WITH (NOLOCK)
JOIN    Dictionary.SeychellesCategorization SC WITH (NOLOCK) ON SC.SeychellesCategorizationID = BC.SeychellesCategorizationID
GROUP BY SC.Name
ORDER BY CustomerCount DESC;

-- Find customers pending Seychelles verification
SELECT  BC.CID, BC.SeychellesCategorizationID
FROM    BackOffice.Customer BC WITH (NOLOCK)
WHERE   BC.SeychellesCategorizationID = 1;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Seychelles categorization is a regulatory compliance feature for the FSA-regulated entity.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (4 rows), codebase traced (BackOffice.Customer FK, 2+ update procedures, UserApiDB replication, 10+ consumer procedures)*
