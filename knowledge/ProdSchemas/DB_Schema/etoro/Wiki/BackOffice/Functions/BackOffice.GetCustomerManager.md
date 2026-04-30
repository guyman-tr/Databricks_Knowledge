# BackOffice.GetCustomerManager

> Returns the ManagerID assigned to a customer during a specified date range, but only if the same manager was responsible throughout the entire period; returns NULL if the manager changed.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INTEGER - ManagerID or NULL |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomerManager resolves which BackOffice manager (sales agent, account manager) was responsible for a specific customer during a given date range. It queries the History.BackOfficeCustomer table - the temporal audit log that tracks how customer-to-manager assignments change over time - and returns a ManagerID only when the assignment was stable throughout the entire requested period.

This function serves reporting and attribution use cases: when analyzing a customer's trading activity or financial outcomes over a date range, it is important to know which manager was responsible throughout that window. If a customer was reassigned mid-period (different manager at @Date vs. @EndDate), the function returns NULL, signaling that the period cannot be cleanly attributed to a single manager. This design prevents incorrect commission or performance attribution to a manager who only covered part of the period.

The function appears to be consumed primarily by application-layer reporting logic or analytics queries outside the stored procedure layer, as no BackOffice stored procedures in the SSDT repo directly call it. It may be referenced by ad-hoc reporting tools or data warehouse ETL processes.

---

## 2. Business Logic

### 2.1 Stable-Period Manager Attribution

**What**: The function enforces "single-manager stability" for a date range - only returns a ManagerID if the same manager held the customer assignment at BOTH the start and end of the requested period.

**Parameters Involved**: `@CID`, `@Date`, `@EndDate`

**Rules**:
- Queries History.BackOfficeCustomer twice: once for the manager at @Date, once for the manager at @EndDate.
- Uses MAX(ManagerID) with a BETWEEN ValidFrom AND ValidTo filter. MAX() handles cases where multiple rows exist for the same validity period (defensive coding against data quality issues).
- Returns NULL in three cases: (1) no manager found at @Date, (2) no manager found at @EndDate, (3) different managers at @Date vs @EndDate.
- Returns ManagerID only when BOTH lookups find the same manager - the customer was with the same manager for the full period.
- The History.BackOfficeCustomer table uses an SCD Type 2 pattern: each row represents a time slice with ValidFrom and ValidTo dates. When a customer is reassigned, the old row gets a ValidTo = reassignment date, and a new row starts.

**Diagram**:
```
@Date                @EndDate
  |                     |
  v                     v
History.BackOfficeCustomer (SCD Type 2)
  CID + BETWEEN ValidFrom AND ValidTo

Manager at @Date = M1        Manager at @EndDate = M2
      |                              |
      v                              v
M1 IS NULL?  YES -> RETURN NULL
M2 IS NULL?  YES -> RETURN NULL
M1 != M2?    YES -> RETURN NULL (manager changed during period)
             NO  -> RETURN M1 (stable assignment)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. The customer whose manager is being looked up. FK to Customer.CustomerStatic.CID (cross-schema). |
| 2 | @Date | DATETIME | NO | - | CODE-BACKED | Start of the date range. The function checks which manager held this customer at this point in time by finding the History.BackOfficeCustomer row where @Date falls between ValidFrom and ValidTo. |
| 3 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the date range. The function independently looks up the manager at this date. If the manager differs from the one at @Date, NULL is returned to signal the assignment was not stable. |
| 4 | Return value | INTEGER | YES | - | CODE-BACKED | ManagerID of the manager responsible for this customer during the entire [@Date, @EndDate] period. Returns NULL if: no manager found at either endpoint, or different managers at the two endpoints (reassignment occurred during the period). FK to BackOffice.Manager.ManagerID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Lookup (cross-schema) | Customer being looked up. No join in function - parameter value. |
| Return value | BackOffice.Manager | Implicit FK | The returned ManagerID references BackOffice.Manager.ManagerID. |
| (internal) | History.BackOfficeCustomer | Table access | SCD Type 2 history table queried for manager assignment at each date point. |

### 5.2 Referenced By (other objects point to this)

No callers found in BackOffice stored procedures. Likely consumed by application code, analytics queries, or data warehouse ETL processes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerManager (scalar function)
└── History.BackOfficeCustomer (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.BackOfficeCustomer | Table (cross-schema) | JOINed twice via WHERE clause - finds ManagerID for CID at @Date and @EndDate within ValidFrom/ValidTo range |

### 6.2 Objects That Depend On This

No dependents found in BackOffice schema stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get the manager for a customer over a specific month
```sql
SELECT BackOffice.GetCustomerManager(
    12345,                          -- CID
    '2025-01-01 00:00:00',          -- Start of period
    '2025-01-31 23:59:59'           -- End of period
) AS ManagerID
-- Returns ManagerID if same manager held the account all month
-- Returns NULL if manager changed during January
```

### 8.2 Get manager name for a customer over a date range
```sql
SELECT
    c.CID,
    BackOffice.GetCustomerManager(c.CID, @StartDate, @EndDate) AS ManagerID,
    m.FirstName + ' ' + m.LastName AS ManagerName
FROM BackOffice.Customer c WITH (NOLOCK)
LEFT JOIN BackOffice.Manager m WITH (NOLOCK)
    ON m.ManagerID = BackOffice.GetCustomerManager(c.CID, @StartDate, @EndDate)
WHERE c.CID = 12345
```

### 8.3 Find customers whose manager changed during a period (NULL return)
```sql
DECLARE @Start DATETIME = '2025-01-01'
DECLARE @End   DATETIME = '2025-03-31'

SELECT
    bc.CID,
    bc.ManagerID AS CurrentManager,
    BackOffice.GetCustomerManager(bc.CID, @Start, @End) AS StableManager
FROM BackOffice.Customer bc WITH (NOLOCK)
WHERE BackOffice.GetCustomerManager(bc.CID, @Start, @End) IS NULL
  AND bc.ManagerID IS NOT NULL
-- Customers who had a manager change during the period
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10.0/10, Logic: 9.5/10, Relationships: 7.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerManager | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetCustomerManager.sql*
