# BackOffice.IsUSAUser

> Returns 1 if the customer's regulation is a USA regulation (Dictionary.Regulation.IsUSA = 1), 0 otherwise.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer ID); returns IsUS (0 or 1) as a result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`IsUSAUser` determines whether a given customer is regulated under a US regulatory framework by joining the customer's regulation record to the `Dictionary.Regulation` table and reading the `IsUSA` flag.

eToro's regulatory model segments customers by regulation (CySEC for EU customers, ASIC for Australian, FCA for UK, etc.). The USA regulatory regime has special handling in many areas - trading restrictions (CFD prohibition), compliance requirements (FINRA, SEC), and product availability (stocks only, no leverage). The `IsUSA` flag on the Regulation table is the canonical indicator for this.

The procedure returns a single row with `IsUS` as an INT (0 or 1). If the CID does not exist in BackOffice.Customer or has no matching regulation, no row is returned (the INNER JOIN will produce no result).

No SSDT callers found - called by external Back Office services that need to gate behaviour by US regulatory status.

---

## 2. Business Logic

### 2.1 USA Regulation Flag Check

**What**: Reads the IsUSA flag from the customer's regulation via a join to Dictionary.Regulation.

**Columns/Parameters Involved**: `@CID`, `BackOffice.Customer.RegulationID`, `Dictionary.Regulation.IsUSA`

**Rules**:
- INNER JOIN `BackOffice.Customer` (BC) ON `RegulationID` to `Dictionary.Regulation` (DR) ON `DR.ID = BC.RegulationID`
- WHERE `BC.CID = @CID`
- Returns `CAST(DR.IsUSA AS INT) AS IsUS`
- `Dictionary.Regulation.IsUSA` is TINYINT with DEFAULT 0; only USA-specific regulation records have IsUSA = 1
- If the customer does not exist in BackOffice.Customer: no row returned (INNER JOIN, not LEFT JOIN)
- CAST to INT: converts TINYINT to INT for the result column

**Diagram**:
```
@CID
  |
  v
BackOffice.Customer (CID = @CID)
  |
  INNER JOIN Dictionary.Regulation (RegulationID = ID)
  |
  SELECT CAST(IsUSA AS INT) AS IsUS
  --> 1 if USA regulation, 0 if non-USA regulation
  --> no row if CID not found
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to check. Joined to BackOffice.Customer to find the customer's RegulationID, which is then looked up in Dictionary.Regulation for the IsUSA flag. |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IsUS | INT | YES | - | CODE-BACKED | 1 = the customer's regulation has IsUSA=1 in Dictionary.Regulation (US-regulated customer). 0 = non-US regulation. NULL / no row = CID not found in BackOffice.Customer or no matching regulation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Lookup | CID = @CID to retrieve RegulationID |
| RegulationID | Dictionary.Regulation | Lookup | Joins to read IsUSA flag |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.IsUSAUser (procedure)
├── BackOffice.Customer (table) [SELECT RegulationID WHERE CID = @CID]
└── Dictionary.Regulation (table) [INNER JOIN to read IsUSA flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Lookup: RegulationID for given CID |
| Dictionary.Regulation | Table | INNER JOIN to read IsUSA (TINYINT, DEFAULT 0) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by external services for US-regulation gating |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WITH (NOLOCK) on BackOffice.Customer | Query hint | Dirty read on customer record |
| INNER JOIN (not LEFT JOIN) | Design | No row returned if CID not found - callers should handle empty result |
| CAST(IsUSA AS INT) | Type coercion | Converts TINYINT to INT for result column |
| No TRY/CATCH | Design | Errors propagate to caller |

---

## 8. Sample Queries

### 8.1 Check if a customer is US-regulated

```sql
EXEC [BackOffice].[IsUSAUser] @CID = 12345;
-- Returns: IsUS = 1 (USA) or IsUS = 0 (non-USA) or no rows (CID not found)
```

### 8.2 Check USA status directly via join

```sql
SELECT
    BC.CID,
    BC.RegulationID,
    DR.Name AS RegulationName,
    CAST(DR.IsUSA AS INT) AS IsUS
FROM BackOffice.Customer WITH (NOLOCK) BC
INNER JOIN Dictionary.Regulation DR ON DR.ID = BC.RegulationID
WHERE BC.CID = 12345;
```

### 8.3 Find all USA-regulated customers (batch)

```sql
SELECT BC.CID
FROM BackOffice.Customer WITH (NOLOCK) BC
INNER JOIN Dictionary.Regulation DR ON DR.ID = BC.RegulationID
WHERE DR.IsUSA = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.IsUSAUser | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.IsUSAUser.sql*
