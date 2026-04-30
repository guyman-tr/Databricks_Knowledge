# Trade.SetNextLiquidityProviderID

> Get-or-create utility for "Obsolete! Use Hedge Account" placeholder providers: finds the existing placeholder row for the given provider type, or inserts a new one using the lowest available gap-filled ID, and returns the LiquidityProviderID via RETURN code.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderTypeID (determines which placeholder to find or create) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.SetNextLiquidityProviderID` is a **migration-era utility procedure** that manages placeholder entries in `Trade.LiquidityProviders` to mark provider slots as obsolete. As eToro transitioned from direct liquidity provider routing to the Hedge Account model, provider references that were previously pointing to real LiquidityProviders needed to be redirected. This procedure creates a named placeholder row - `'Obsolete! Use Hedge Account'` - for a given provider type, signalling to any consumer of that LiquidityProviderID that the routing has been superseded and they should look at the Hedge Account assignment instead.

The procedure is idempotent per provider type: if an "Obsolete! Use Hedge Account" row already exists for the given type, the existing ID is returned without any insert. If no such row exists, a new one is created using a gap-filling algorithm to find the lowest unused `LiquidityProviderID`, keeping the ID space compact.

Data flows as follows: a migration script or admin tool calls this procedure with a `@ProviderTypeID`. The procedure returns (via RETURN code) the `LiquidityProviderID` for the "Obsolete" placeholder of that type. The caller then uses this ID to update references (e.g., foreign keys or application configuration) to point to the placeholder, effectively tombstoning the old direct-provider references.

---

## 2. Business Logic

### 2.1 Get-or-Create for "Obsolete! Use Hedge Account" Placeholder

**What**: For each provider type, at most one "Obsolete" placeholder row exists. The procedure finds it or creates it.

**Columns/Parameters Involved**: `@ProviderTypeID`, `@ProviderID`

**Rules**:
- Look up: `SELECT LiquidityProviderID FROM Trade.LiquidityProviders WHERE LiquidityProviderTypeID = @ProviderTypeID AND LiquidityProviderName = 'Obsolete! Use Hedge Account'`
- If found: @ProviderID is set; skip INSERT. The existing placeholder row is returned.
- If not found (@ProviderID IS NULL): run gap-finding CTE and insert new row.
- Returns @ProviderID via `RETURN @ProviderID` (not an OUTPUT parameter - callers must use `EXEC @result = Trade.SetNextLiquidityProviderID @ProviderTypeID = X`).

### 2.2 Gap-Filling ID Allocation Algorithm

**What**: When a new placeholder must be created, the ID is allocated using a self-join gap-finder to keep the LiquidityProviderID sequence compact.

**Columns/Parameters Involved**: `LiquidityProviderID` (in Trade.LiquidityProviders)

**Rules**:
- CTE `MissingIDs`: `SELECT t1.LiquidityProviderID + 1 AS candidate FROM LiquidityProviders t1 LEFT JOIN LiquidityProviders t2 ON t1.ID + 1 = t2.ID WHERE t2.ID IS NULL` - finds all IDs that are not in the table but follow an existing ID.
- Selects `MIN(candidate)` where `candidate > 0` - the lowest positive gap.
- Fallback: `COALESCE(MIN(candidate), MAX(LiquidityProviderID) + 1)` - if no gaps exist, use MAX+1.
- Inserted row: `LiquidityProviderID = @ProviderID, LiquidityProviderName = 'Obsolete! Use Hedge Account', LiquidityProviderSettingsXML = '<settings />', LiquidityProviderTypeID = @ProviderTypeID`

**Diagram**:
```
Existing IDs: 0, 1, 2, 3, 5, 7
MissingIDs candidates: 1+1=2(exists), 2+1=3(exists), 3+1=4(NOT exists)->4, 5+1=6(NOT exists)->6, 7+1=8(NOT exists)->8
MIN(candidate) > 0 = 4 --> new placeholder gets ID=4
```

### 2.3 RETURN Code Output Pattern

**What**: The procedure returns the LiquidityProviderID via `RETURN @ProviderID`, not via an OUTPUT parameter.

**Rules**:
- Callers must use the EXEC assignment syntax: `EXEC @myVar = Trade.SetNextLiquidityProviderID @ProviderTypeID = 5`
- Standard `EXEC Trade.SetNextLiquidityProviderID @ProviderTypeID = 5` without assignment discards the result.
- No result set is returned.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderTypeID | int | NO | - | CODE-BACKED | The provider type for which to get-or-create an "Obsolete! Use Hedge Account" placeholder. FK to Trade.LiquidityProviderType.LiquidityProviderTypeID. Determines which type-specific placeholder row is being managed. |

**Return value** (via RETURN code):

| # | Return | Type | Description |
|---|--------|------|-------------|
| 1 | @ProviderID | int | The LiquidityProviderID of the "Obsolete! Use Hedge Account" row for the given @ProviderTypeID. Either the ID of an existing row (no INSERT happened) or the newly allocated gap-filled ID (INSERT was performed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderTypeID | Trade.LiquidityProviderType | Lookup | Identifies which provider type's placeholder is being managed |
| (SELECT + INSERT target) | Trade.LiquidityProviders | READER + WRITER | Reads to find existing placeholder; inserts new row if not found |

### 5.2 Referenced By (other objects point to this)

No callers found within the SSDT repository. Called externally by migration scripts or admin tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetNextLiquidityProviderID (procedure)
+-- Trade.LiquidityProviders (table) [READER + conditional WRITER]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviders | Table | Read to find existing "Obsolete" placeholder; INSERT target for new placeholder row using gap-filled ID |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called externally by migration scripts.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Idempotent per type | Design | Calling twice with the same @ProviderTypeID returns the same ID; the second call finds the existing row and does not insert. |
| No transaction | Atomicity | No explicit transaction; the INSERT is implicitly transactional. Race condition possible if called concurrently for the same @ProviderTypeID. |
| RETURN (not OUTPUT) | Interface | Result is via RETURN code - must use `EXEC @var = ...` to capture. |
| candidate > 0 | Safety guard | Prevents allocating ID=0 or negative IDs; ID 0 already exists in LiquidityProviders ('ACT'). |

---

## 8. Sample Queries

### 8.1 Get or create "Obsolete" placeholder for provider type 2 (FXCM)
```sql
DECLARE @PlaceholderID INT;
EXEC @PlaceholderID = [Trade].[SetNextLiquidityProviderID] @ProviderTypeID = 2;
SELECT @PlaceholderID AS ObsoleteProviderID; -- e.g., returns the assigned LiquidityProviderID
```

### 8.2 Check if an "Obsolete" placeholder already exists for a type
```sql
SELECT LiquidityProviderID, LiquidityProviderName, LiquidityProviderTypeID
FROM   [Trade].[LiquidityProviders] WITH (NOLOCK)
WHERE  LiquidityProviderTypeID = 2
  AND  LiquidityProviderName   = 'Obsolete! Use Hedge Account';
```

### 8.3 View all "Obsolete" placeholder rows (migration markers)
```sql
SELECT lp.LiquidityProviderID, lp.LiquidityProviderName, lp.LiquidityProviderTypeID,
       lpt.LiquidityProviderTypeName
FROM   [Trade].[LiquidityProviders]     lp  WITH (NOLOCK)
JOIN   [Trade].[LiquidityProviderType]  lpt WITH (NOLOCK) ON lpt.LiquidityProviderTypeID = lp.LiquidityProviderTypeID
WHERE  lp.LiquidityProviderName = 'Obsolete! Use Hedge Account'
ORDER BY lp.LiquidityProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetNextLiquidityProviderID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetNextLiquidityProviderID.sql*
