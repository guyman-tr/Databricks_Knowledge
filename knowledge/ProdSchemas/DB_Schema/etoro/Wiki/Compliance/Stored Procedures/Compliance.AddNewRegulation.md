# Compliance.AddNewRegulation

> Adds a new financial regulatory authority to the platform, inserting it into both the production and demo environments simultaneously.

| Property | Value |
|----------|-------|
| **Schema** | Compliance |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @regulationId (output: RegulationId) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure registers a new regulatory jurisdiction into eToro's regulation dictionary (`Dictionary.Regulation`), which governs which compliance rules, leverage limits, instrument availability, and legal entity apply to customers in that jurisdiction. Adding a regulation is a foundational system administration task performed when eToro enters a new regulated market or when a new entity structure is created.

Without this procedure, eToro's regulatory framework cannot be extended to new markets. Every customer account, instrument configuration, and compliance rule depends on the `Dictionary.Regulation` table to determine applicable rules. A missing regulation entry would leave newly onboarded customers or jurisdictions unclassifiable.

Data flows as follows: an operations or development team member calls this procedure with full regulatory details; the procedure inserts into `Dictionary.Regulation` (production) and simultaneously calls `dbo.Demo_AddNewRegulation` to mirror the same entry into the demo environment. It then returns the newly created record. The procedure has a comment in the DDL noting that it is intentionally different from a version in another database and must NOT be aligned.

---

## 2. Business Logic

### 2.1 Duplicate Regulation Guard

**What**: Prevents inserting a regulation ID that already exists.

**Columns/Parameters Involved**: `@regulationId`, `Dictionary.Regulation.ID`

**Rules**:
- Before inserting, the SP checks `IF EXISTS (SELECT 1 FROM Dictionary.Regulation WHERE ID = @regulationId)`
- If the ID already exists, `RAISERROR` is raised with severity 10 (informational - not a terminating error in SQL Server)
- Execution continues after this warning; the INSERT still runs
- A second `IF NOT EXISTS` check after the INSERT verifies the row was actually created; if not, a different RAISERROR fires

**Diagram**:
```
@regulationId provided
        |
        v
[EXISTS in Dictionary.Regulation?]
    YES -> RAISERROR (severity 10 - informational, execution continues)
    NO  -> continue
        |
        v
[INSERT into Dictionary.Regulation]
        |
        v
[EXISTS in Dictionary.Regulation now?]
    NO  -> RAISERROR 'Some information is missing'
    YES -> continue
```

### 2.2 Dual-Environment Synchronization

**What**: Every new regulation must exist in both production and demo environments.

**Columns/Parameters Involved**: All 8 parameters passed identically to `dbo.Demo_AddNewRegulation`

**Rules**:
- After the production insert succeeds, `dbo.Demo_AddNewRegulation` is called with identical parameters
- Result is captured in a `@DemoRegulation` table variable
- If the demo call returns 0 rows, a RAISERROR fires: 'Some information is missing - New regulation wasn''t added successfully on DEMO'
- This ensures demo trading always has the same regulation catalog as production

**Diagram**:
```
Production INSERT succeeds
        |
        v
EXEC dbo.Demo_AddNewRegulation (same 8 params)
        |
        v
[Demo returned >= 1 row?]
    NO  -> RAISERROR 'not added on DEMO'
    YES -> SELECT result and return
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @regulationId | INT | NO | - | CODE-BACKED | The unique integer ID to assign to the new regulation. Used as the `ID` PK in `Dictionary.Regulation`. Must not already exist - procedure checks and raises an informational warning if duplicate. See [Regulation](_glossary.md#regulation) for current values. |
| 2 | @regulationName | NVARCHAR(50) | NO | - | CODE-BACKED | Short display name for the regulation (e.g., 'CySEC', 'FCA', 'ASIC'). Maps to `Dictionary.Regulation.Name`. Used in UI and reporting as the primary label. |
| 3 | @isUSA | BIT | NO | - | CODE-BACKED | Flag indicating whether this regulation is a US jurisdiction. 1=US-regulated entity (triggers special compliance handling for NFA/FINRA/FinCEN rules), 0=non-US. Maps to `Dictionary.Regulation.IsUSA`. |
| 4 | @jurisdictionName | NVARCHAR(50) | NO | - | CODE-BACKED | Name of the eToro legal entity operating under this regulation (e.g., 'eToro (Europe) Ltd'). Maps to `Dictionary.Regulation.JurisdictionName`. Used in legal documents and account statements. |
| 5 | @bankId | INT | NO | - | CODE-BACKED | Reference to the banking partner ID responsible for client fund custody under this regulation. Maps to `Dictionary.Regulation.BankID`. |
| 6 | @regulationLongName | NVARCHAR(100) | NO | - | CODE-BACKED | Full formal name of the regulatory authority (e.g., 'Cyprus Securities and Exchange Commission'). Maps to `Dictionary.Regulation.RegulationLongName`. Used in official disclosures. |
| 7 | @regulationShortName | NVARCHAR(50) | NO | - | CODE-BACKED | Abbreviated name for the regulation (e.g., 'CySEC'). Maps to `Dictionary.Regulation.RegulationShortName`. Redundant with @regulationName in many cases but allows separate short/long abbreviations. |
| 8 | @defaultRegulationId | INT | NO | - | CODE-BACKED | ID of the fallback regulation to use when no specific regulation is assigned to a customer (typically BVI=5 for non-US, eToroUS=6 for US). Maps to `Dictionary.Regulation.DefaultRegulationID`. Points back to `Dictionary.Regulation`. |

**Return Result Set** (SELECT on success):

| # | Column | Type | Description |
|---|--------|------|-------------|
| R1 | RegulationId | INT | The ID of the newly created regulation (= @regulationId) |
| R2 | RegulationName | NVARCHAR | Short name of the regulation |
| R3 | IsUSA | BIT | Whether this is a US-regulated jurisdiction |
| R4 | JurisdictionName | NVARCHAR | Legal entity name |
| R5 | BankId | INT | Banking partner ID |
| R6 | RegulationLongName | NVARCHAR | Full formal name |
| R7 | RegulationShortName | NVARCHAR | Abbreviated name |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @regulationId | Dictionary.Regulation.ID | FK (INSERT target) | Inserts a new row into the regulation lookup table - the central authority for all customer regulation assignment |
| @defaultRegulationId | Dictionary.Regulation.ID | Self-Reference (Lookup) | Points to the fallback regulation for customers without a specific assignment; typically BVI (5) or eToroUS (6) |
| (via EXEC) | dbo.Demo_AddNewRegulation | Dependency | Mirrors the regulation insert into the demo environment with identical parameters |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in repo) | - | - | No stored procedures in the SSDT repo call this procedure. It appears to be called directly from application/ops tooling outside the repo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Compliance.AddNewRegulation (procedure)
├── Dictionary.Regulation (table) - INSERT + SELECT
└── dbo.Demo_AddNewRegulation (procedure) - EXEC (Demo environment mirror)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Regulation | Table | Target of INSERT; also queried with SELECT to validate existence before and after insert |
| dbo.Demo_AddNewRegulation | Stored Procedure | Called via INSERT...EXEC to mirror the new regulation into the demo environment |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT repo) | - | No dependents discovered. Called from external application or ops tooling. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Duplicate ID check | Application logic | RAISERROR (severity 10) if @regulationId already exists in Dictionary.Regulation - informational, does not halt execution |
| Insert verification | Application logic | RAISERROR if row not found after INSERT - guards against silent failures |
| Demo sync verification | Application logic | RAISERROR if dbo.Demo_AddNewRegulation returns 0 rows - ensures demo parity |

---

## 8. Sample Queries

### 8.1 Execute the procedure to add a new regulation

```sql
-- Add a new hypothetical regulation
EXEC [Compliance].[AddNewRegulation]
    @regulationId = 15,
    @regulationName = N'DFSA',
    @isUSA = 0,
    @jurisdictionName = N'eToro (Dubai) Ltd',
    @bankId = 3,
    @regulationLongName = N'Dubai Financial Services Authority',
    @regulationShortName = N'DFSA',
    @defaultRegulationId = 5;
```

### 8.2 Verify existing regulations before adding

```sql
-- Check current regulations to avoid ID conflicts
SELECT ID, Name, IsUSA, JurisdictionName, RegulationLongName, DefaultRegulationID
FROM [Dictionary].[Regulation] WITH (NOLOCK)
ORDER BY ID;
```

### 8.3 Confirm the regulation was added and check its default chain

```sql
-- Verify new regulation and its default fallback
SELECT r.ID, r.Name, r.JurisdictionName, r.IsUSA,
       def.Name AS DefaultRegulationName
FROM [Dictionary].[Regulation] r WITH (NOLOCK)
JOIN [Dictionary].[Regulation] def WITH (NOLOCK) ON r.DefaultRegulationID = def.ID
WHERE r.ID = 15;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Compliance API - Regular Deployment Checklist (Archived 2024-04-30) | Confluence (CR space, archived) | Found via search but archived deployment checklist - no substantive business logic for this SP extracted |

No active Atlassian documentation found for this object. Jira search unavailable (410 error during Phase 10).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira unavailable) | Procedures: 0 analyzed (no callers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Compliance.AddNewRegulation | Type: Stored Procedure | Source: etoro/etoro/Compliance/Stored Procedures/Compliance.AddNewRegulation.sql*
