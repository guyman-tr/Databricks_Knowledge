# BackOffice.ChangeCustomerRegulation

> Reassigns a customer's regulatory jurisdiction by updating BackOffice.Customer.RegulationID, with dual-existence validation to ensure both the customer and the target regulation are valid before applying the change.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure allows BackOffice operators to reassign a customer to a different regulatory jurisdiction. RegulationID in `BackOffice.Customer` determines which financial regulatory authority (CySEC, FCA, ASIC, FinCEN, etc.) governs the customer's account - it controls leverage limits, available instruments, KYC requirements, tax reporting, fund custody, and compliance reporting.

Regulation changes are a compliance-sensitive operation: they occur when a customer relocates to a different country, when eToro restructures its entity mappings for a region, or to correct a mis-assignment at registration. The procedure enforces a strict dual-existence guard: both the customer (@CID) must exist in BackOffice.Customer AND the target regulation (@RegulationID) must exist in Dictionary.Regulation before any update is applied. If either validation fails, the procedure exits silently without modifying any data and without returning an error code.

Key regulations: 1=CySEC (EU), 2=FCA (UK), 4=ASIC (Australia), 7=FinCEN (US crypto), 8=FinCEN+FINRA (US securities), 11=FSRA (Abu Dhabi), 13=MAS (Singapore).

---

## 2. Business Logic

### 2.1 Dual-Existence Guard Before Update

**What**: Both the customer and the target regulation must exist; silent no-op if either is missing.

**Columns/Parameters Involved**: `@CID`, `@RegulationID`, `BackOffice.Customer.CID`, `Dictionary.Regulation.ID`

**Rules**:
- Guard 1: `EXISTS (SELECT 1 FROM BackOffice.Customer WHERE CID=@CID)` - customer must be in BackOffice.Customer
- Guard 2: `EXISTS (SELECT 1 FROM Dictionary.Regulation WHERE ID=@RegulationID)` - regulation must be a valid ID (1-14)
- Both guards in a single IF: if EITHER fails -> no update, no error raised, procedure returns NULL (no RETURN statement)
- If BOTH pass -> `UPDATE BackOffice.Customer SET RegulationID=@RegulationID WHERE CID=@CID`
- No RETURN statement -> procedure always exits with NULL return code (caller cannot distinguish success from silent validation failure via RETURN)

**Diagram**:
```
CID exists in BackOffice.Customer?      NO -> silent exit (no update)
RegulationID exists in Dictionary.Regulation?  NO -> silent exit (no update)
Both YES -> UPDATE BackOffice.Customer SET RegulationID=@RegulationID WHERE CID=@CID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. The customer whose regulatory jurisdiction is being changed. Validated against BackOffice.Customer.CID before the update is applied. |
| 2 | @RegulationID | INT | NO | - | CODE-BACKED | The target regulatory jurisdiction ID. Validated against Dictionary.Regulation.ID before the update is applied. Key values: 1=CySEC (EU), 2=FCA (UK), 4=ASIC (Australia), 7=FinCEN (US crypto), 8=FinCEN+FINRA (US securities), 11=FSRA (Abu Dhabi), 13=MAS (Singapore). |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | (none) | No RETURN statement. Procedure always returns NULL. Caller cannot distinguish between success and silent validation failure via RETURN code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER | Updates RegulationID WHERE CID=@CID (only if both existence checks pass) |
| @CID | BackOffice.Customer | Lookup (EXISTS) | Validates that the customer exists before applying the update |
| @RegulationID | Dictionary.Regulation | Lookup (EXISTS) | Validates that the target regulation ID is a valid entry |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called directly from BackOffice customer management UI (jurisdiction reassignment workflow).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ChangeCustomerRegulation (procedure)
|- BackOffice.Customer (table) [EXISTS check + UPDATE target]
+-- Dictionary.Regulation (table) [EXISTS validation - cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | EXISTS guard: verifies CID exists; UPDATE: sets RegulationID WHERE CID=@CID |
| Dictionary.Regulation | Table | EXISTS guard: verifies @RegulationID is a valid jurisdiction (cross-schema) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice customer management UI | External | Calls this to reassign a customer to a different regulatory jurisdiction |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dual-existence guard | Application | Both CID in BackOffice.Customer AND RegulationID in Dictionary.Regulation must exist; either missing -> silent no-op |
| No RETURN code | Design | Procedure has no RETURN statement; callers cannot determine success vs. validation failure from the return value; must verify by re-reading BackOffice.Customer if needed |
| Compliance sensitivity | Business | RegulationID changes affect leverage, instruments, KYC requirements, and tax reporting; this is a high-impact update that must be tracked in audit logs |

---

## 8. Sample Queries

### 8.1 Reassign a customer to FCA (UK) regulation

```sql
EXEC BackOffice.ChangeCustomerRegulation
    @CID = 12345,
    @RegulationID = 2  -- 2 = FCA (UK)
-- Verify: SELECT RegulationID FROM BackOffice.Customer WITH (NOLOCK) WHERE CID = 12345
```

### 8.2 Verify the regulation change was applied

```sql
SELECT BC.CID, BC.RegulationID, DR.Name AS RegulationName
FROM BackOffice.Customer BC WITH (NOLOCK)
JOIN Dictionary.Regulation DR WITH (NOLOCK) ON BC.RegulationID = DR.ID
WHERE BC.CID = 12345
```

### 8.3 Check valid regulation IDs before calling

```sql
SELECT ID, Name, IsUSA
FROM Dictionary.Regulation WITH (NOLOCK)
ORDER BY ID
-- Use the ID from this list as @RegulationID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ChangeCustomerRegulation | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ChangeCustomerRegulation.sql*
