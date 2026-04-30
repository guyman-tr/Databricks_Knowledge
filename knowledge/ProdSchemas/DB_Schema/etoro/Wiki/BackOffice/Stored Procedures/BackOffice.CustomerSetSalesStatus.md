# BackOffice.CustomerSetSalesStatus

> Updates the sales lifecycle status for a customer account in BackOffice.Customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - internal customer identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerSetSalesStatus sets the `SalesStatusID` on a customer's BackOffice profile, tracking where the customer stands in the sales lifecycle. SalesStatusID represents the current state of the sales team's engagement with the customer (e.g., new lead, contacted, active trader, dormant, churned), enabling the sales team and CRM systems to filter, prioritize, and report on customer portfolios.

The procedure is minimal by design - a direct UPDATE with no guard conditions - reflecting that sales status transitions are managed externally by CRM workflow logic before this procedure is called. It is called from CRM integration tooling and BackOffice agent workflows.

---

## 2. Business Logic

### 2.1 Direct Sales Status Update

**What**: Unconditional single-column UPDATE on BackOffice.Customer.

**Columns/Parameters Involved**: `@CID`, `@SalesStatusID`, `BackOffice.Customer.SalesStatusID`

**Rules**:
- UPDATE fires unconditionally - no change-guard, no validation.
- Returns @@ERROR to the caller. 0 = success.
- History recorded by BackOffice.Customer UPDATE trigger (History.BackOfficeCustomer).
- SalesStatusID values represent sales lifecycle stages - lookup table and value meanings defined at application/CRM layer.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Internal Customer ID. Targets the customer's row in BackOffice.Customer. |
| 2 | @SalesStatusID | INTEGER | NO | - | CODE-BACKED | The new sales lifecycle status to assign. Mapped to BackOffice.Customer.SalesStatusID. Values represent sales engagement stages (new lead, active, dormant, etc.) defined in the CRM/application layer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Modifier | UPDATE target - sets SalesStatusID for the customer's operational profile. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CRM/BackOffice tooling | EXEC | Caller | Called from sales workflow tools when progressing a customer through the sales funnel. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetSalesStatus (procedure)
└── BackOffice.Customer (table) - UPDATE SalesStatusID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE - sets SalesStatusID = @SalesStatusID WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CRM/BackOffice tooling | External | EXEC - sales workflow status progression |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @@ERROR return | Convention | Returns SQL error code. 0 = success. No transaction wrapping. |

---

## 8. Sample Queries

### 8.1 Set a customer's sales status
```sql
EXEC BackOffice.CustomerSetSalesStatus @CID = 12345678, @SalesStatusID = 3
```

### 8.2 Check current sales status for a customer
```sql
SELECT bc.CID, cs.UserName, bc.SalesStatusID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = bc.CID
WHERE bc.CID = 12345678
```

### 8.3 Count customers per sales status
```sql
SELECT SalesStatusID, COUNT(*) AS CustomerCount
FROM BackOffice.Customer WITH (NOLOCK)
WHERE SalesStatusID IS NOT NULL
GROUP BY SalesStatusID
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSetSalesStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetSalesStatus.sql*
