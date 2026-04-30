# Dictionary.SalesStatus

## 1. Business Meaning

**What it is**: A lookup table defining the sales pipeline status for customer accounts. Tracks where a customer stands in the sales/account management lifecycle — from initial registration through follow-up to closure.

**Why it exists**: eToro's BackOffice customer management system assigns each customer a sales status to track CRM pipeline progression. This enables sales teams and account managers to filter and report on customers by their engagement state. The status is stored on `BackOffice.Customer.SalesStatusID` and displayed in registration reports.

**How it works**: When a customer registers, they receive the default "New" status (ID 0). Account managers update the status as they engage with the customer. The `BackOffice.GetRegistrationReport` procedure joins this table to display the human-readable sales status name alongside customer registration data.

---

## 2. Business Logic

### Sales Pipeline States
| ID | Name | Business Meaning |
|----|------|------------------|
| 0 | New | Freshly registered — not yet contacted by sales |
| 1 | Follow Up | Sales team has initiated contact — customer requires follow-up |
| 2 | Close | Sales engagement complete — customer fully onboarded or disqualified |
| 3 | New-NA | New customer, Not Applicable — likely auto-classified as not requiring sales outreach |

### Lifecycle Flow
```
New (0) → Follow Up (1) → Close (2)
New-NA (3) [separate track — no sales engagement needed]
```

---

## 3. Data Overview

| SalesStatusID | Name | Business Meaning |
|---------------|------|------------------|
| 0 | New | Fresh registration, awaiting sales contact |
| 1 | Follow Up | Active sales engagement |
| 2 | Close | Sales cycle complete |
| 3 | New-NA | Not applicable for sales outreach |

*4 rows — complete sales pipeline enumeration*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **SalesStatusID** | int | NOT NULL | — | Primary key. Sales pipeline status identifier: 0=New, 1=Follow Up, 2=Close, 3=New-NA. | `MCP` |
| **Name** | varchar(50) | NOT NULL | — | Unique human-readable status label displayed in BackOffice registration reports and CRM views. Enforced unique by index `DSLS_NAME`. | `MCP+DDL` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| BackOffice.Customer | SalesStatusID | Implicit FK | Each customer has a sales pipeline status |
| BackOffice.GetRegistrationReport | SalesStatusID | JOIN | Registration report displays sales status name |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `BackOffice.Customer` — stores SalesStatusID per customer
- `BackOffice.GetRegistrationReport` — displays sales status in registration reports

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `SalesStatusID` (clustered) |
| Indexes | `DSLS_NAME` — unique nonclustered on `Name` |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | DICTIONARY |
| Fill Factor | 90% |
| Row Count | 4 |

---

## 8. Sample Queries

```sql
-- Get all sales statuses
SELECT  SalesStatusID, Name
FROM    Dictionary.SalesStatus WITH (NOLOCK)
ORDER BY SalesStatusID;

-- Count customers by sales status
SELECT  SS.Name AS SalesStatus, COUNT(*) AS CustomerCount
FROM    BackOffice.Customer BC WITH (NOLOCK)
JOIN    Dictionary.SalesStatus SS WITH (NOLOCK) ON SS.SalesStatusID = BC.SalesStatusID
GROUP BY SS.Name
ORDER BY CustomerCount DESC;

-- Find customers still in follow-up stage
SELECT  BC.CID, BC.SalesStatusID
FROM    BackOffice.Customer BC WITH (NOLOCK)
WHERE   BC.SalesStatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. Sales status management is a CRM feature within the BackOffice customer management system.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (4 rows), codebase traced (1 table consumer, 1 procedure consumer), unique index documented*
