# apex.GetClosedAccounts

> Stored procedure that retrieves closed account data from the EXT538_ClosedAccounts table for a specific SOD file import, returning account numbers and restriction reason codes.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Stored Procedure |
| **Parameters** | @SodFileId (uniqueidentifier) |
| **Returns** | Result set: SodFileId, ApexId, RestrictReasonCode |

---

## 1. Business Meaning

This stored procedure provides a clean interface for retrieving closed account data from the EXT538_ClosedAccounts table for a specific SOD file import. It takes a SodFileId parameter (corresponding to a specific EXT538 file import in apex.SodFiles) and returns the list of closed accounts with their Apex account numbers (aliased as "ApexId") and restriction reason codes.

The procedure is used as part of the account lifecycle management workflow. After an EXT538 file is imported, downstream systems call this procedure to get the list of newly closed accounts, which are then processed to update internal eToro account statuses, trigger notification workflows, and ensure regulatory reporting is updated.

The procedure uses SET NOCOUNT ON to suppress row count messages, reducing network overhead when called from application code.

---

## 2. Business Logic

### 2.1 Simple Lookup by SodFileId

**What**: Returns closed accounts for a specific file import.

**Parameters Involved**: `@SodFileId`

**Rules**:
- Filters EXT538_ClosedAccounts by the provided SodFileId
- Returns three columns: SodFileId (passed through), AccountNumber aliased as ApexId, and RestrictReasonCode
- No additional filtering or aggregation is applied
- Returns all rows for that SodFileId (no TOP or ORDER BY)

---

## 3. Data Overview

N/A - Returns data from the Apex Clearing EXT538 daily extract.

---

## 4. Elements

### 4.1 Parameters

| # | Parameter | Type | Direction | Default | Description |
|---|-----------|------|-----------|---------|-------------|
| 1 | @SodFileId | uniqueidentifier | IN | (required) | The SodFiles.Id of the EXT538 file import to query. |

### 4.2 Result Set Columns

| # | Column | Source Element | Alias | Description |
|---|--------|---------------|-------|-------------|
| 1 | SodFileId | EXT538_ClosedAccounts.SodFileId | SodFileId | The SodFileId parameter value (pass-through for caller reference). |
| 2 | AccountNumber | EXT538_ClosedAccounts.AccountNumber | ApexId | Apex customer account number (aliased as ApexId for downstream consumption). |
| 3 | RestrictReasonCode | EXT538_ClosedAccounts.RestrictReasonCode | RestrictReasonCode | Restriction reason code indicating why the account was closed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SodFileId | apex.SodFiles | Parameter filter | Filters by SodFileId, though no explicit FK in the SP itself |
| FROM clause | apex.EXT538_ClosedAccounts | Table read | Reads all columns needed from this table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Relationship Type | Description |
|--------------|-------------------|-------------|
| Application code | API call | Called by downstream systems to retrieve closed account lists after EXT538 import |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.GetClosedAccounts (stored procedure)
  └── apex.EXT538_ClosedAccounts (table)
        └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.EXT538_ClosedAccounts | Table | SELECT from this table filtered by SodFileId |

### 6.2 Objects That Depend On This

No known dependents in the database schema. Called by application code.

---

## 7. Technical Details

### 7.1 SET Options

| Option | Value | Purpose |
|--------|-------|---------|
| ANSI_NULLS | ON | Standard NULL comparison behavior |
| QUOTED_IDENTIFIER | ON | Allows quoted identifiers |
| NOCOUNT | ON | Suppresses row count messages for cleaner application consumption |

### 7.2 Performance Notes

- No explicit locking hints (no WITH (NOLOCK)) -- uses default read committed isolation
- No indexes are explicitly hinted; relies on IX_EXT538_ClosedAccounts_SodFileId index for efficient SodFileId filtering
- No pagination or ordering -- returns all matching rows

---

## 8. Sample Queries

### 8.1 Call the stored procedure

```sql
-- Get the latest EXT538 SodFileId
DECLARE @FileId uniqueidentifier;
SELECT TOP 1 @FileId = Id
FROM apex.SodFiles WITH (NOLOCK)
WHERE ApexFormat = 538 AND Status = 2
ORDER BY ProcessDate DESC;

-- Execute the SP
EXEC apex.GetClosedAccounts @SodFileId = @FileId;
```

### 8.2 Call with a known SodFileId

```sql
EXEC apex.GetClosedAccounts @SodFileId = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX';
```

### 8.3 Equivalent inline query (for comparison)

```sql
SELECT SodFileId,
       AccountNumber AS ApexId,
       RestrictReasonCode
FROM apex.EXT538_ClosedAccounts WITH (NOLOCK)
WHERE SodFileId = @SodFileId;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: apex.GetClosedAccounts | Type: Stored Procedure | Source: Sodreconciliation/Sodreconciliation/apex/Stored Procedures/apex.GetClosedAccounts.sql*
