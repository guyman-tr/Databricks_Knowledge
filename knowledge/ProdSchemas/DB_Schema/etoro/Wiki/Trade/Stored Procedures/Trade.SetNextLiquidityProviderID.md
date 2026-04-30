# Trade.SetNextLiquidityProviderID

> Finds or creates an "Obsolete - Use Hedge Account" placeholder liquidity provider of the specified type, using gap-filling ID allocation, and returns the provider's ID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderTypeID (return value = LiquidityProviderID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a migration/compatibility helper that creates placeholder entries in Trade.LiquidityProviders when the system needs to provision liquidity accounts that map to the newer Hedge.Accounts infrastructure. The liquidity provider layer has been superseded by the Hedge Account system; this procedure creates "Obsolete! Use Hedge Account" stub entries so that older code paths referencing LiquidityProviderID can still function while the full migration to Hedge Accounts is complete.

The procedure exists to support `Trade.SetNextLiquidityAccountID`, which needs a LiquidityProviderID to pair with each new LiquidityAccount. Instead of hardcoding IDs, it uses gap-filling logic (finding the lowest unused ID in the sequence) to avoid conflicts.

When called, it first checks whether a stub provider for the given ProviderTypeID already exists (identified by the fixed name "Obsolete! Use Hedge Account"). If found, it returns the existing ID. If not found, it allocates the lowest available ID using gap analysis on the LiquidityProviderID sequence and inserts a new stub row.

---

## 2. Business Logic

### 2.1 Idempotent Find-or-Create Pattern

**What**: The procedure returns an existing stub provider if one exists, avoiding duplicate rows.

**Columns/Parameters Involved**: `Trade.LiquidityProviders.LiquidityProviderName`, `@Name = 'Obsolete! Use Hedge Account'`, `@ProviderTypeID`

**Rules**:
- Checks for an existing row with LiquidityProviderTypeID = @ProviderTypeID AND LiquidityProviderName = 'Obsolete! Use Hedge Account'
- If found: sets @ProviderID and skips INSERT
- If not found: proceeds to gap-filling allocation and INSERT
- The fixed name "Obsolete! Use Hedge Account" signals that this entry is a legacy compatibility stub

### 2.2 Gap-Filling ID Allocation

**What**: Allocates the lowest unused LiquidityProviderID to avoid wasted sequences.

**Columns/Parameters Involved**: `Trade.LiquidityProviders.LiquidityProviderID`, `@ProviderID`

**Rules**:
- MissingIDs CTE: self-join with left-join trick to find IDs that exist but whose successor does NOT exist
- Selects MIN(candidate) as the first gap, OR MAX(LiquidityProviderID)+1 if no gaps exist (COALESCE fallback)
- candidate > 0 filter excludes any negative or zero IDs

**Diagram**:
```
LiquidityProviders: IDs = {1, 2, 4, 5, 8}
  Gaps: 3, 6, 7, 9...
  MIN candidate = 3 --> use 3 as new LiquidityProviderID

LiquidityProviders: IDs = {1, 2, 3}
  No gaps
  MAX + 1 = 4 --> use 4 as new LiquidityProviderID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderTypeID | int | NO | - | CODE-BACKED | The liquidity provider type for which to find or create the placeholder stub. Used in WHERE LiquidityProviderTypeID = @ProviderTypeID to find an existing stub and as the value for INSERT. |
| Return value | RETURN @ProviderID | int | NO | - | CODE-BACKED | The LiquidityProviderID of the existing or newly created stub provider. Used by Trade.SetNextLiquidityAccountID as the caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderTypeID | Trade.LiquidityProviders | Reader + Writer | Reads to check for existing stub; inserts new stub row with gap-filled ID if not found |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetNextLiquidityAccountID | EXEC @ProviderID = Trade.SetNextLiquidityProviderID | CALLER | Called as a sub-procedure to obtain the LiquidityProviderID for a new liquidity account |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetNextLiquidityProviderID (procedure)
└── Trade.LiquidityProviders (table) [read for existence check + inserted into]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviders | Table | Read to find existing stub by ProviderTypeID + name; inserted into with new gap-filled ID if not found |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SetNextLiquidityAccountID | Procedure | Calls via EXEC @ProviderID = Trade.SetNextLiquidityProviderID to get the provider ID for account creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Fixed stub name | Business rule | Provider name is always 'Obsolete! Use Hedge Account' - signals this is a legacy compatibility stub |
| Gap-filling allocation | Implementation | Finds the lowest unused ID (not just MAX+1) for efficient ID space reuse |
| candidate > 0 guard | Safety | Ensures ID 0 or negative values are not assigned |

---

## 8. Sample Queries

### 8.1 Find or create provider stub for type 1

```sql
DECLARE @ProviderID INT;
EXEC @ProviderID = Trade.SetNextLiquidityProviderID @ProviderTypeID = 1;
SELECT @ProviderID AS AssignedProviderID;
```

### 8.2 Check existing stub providers

```sql
SELECT LiquidityProviderID, LiquidityProviderName, LiquidityProviderTypeID
FROM Trade.LiquidityProviders WITH (NOLOCK)
WHERE LiquidityProviderName = 'Obsolete! Use Hedge Account'
ORDER BY LiquidityProviderTypeID;
```

### 8.3 Find gaps in LiquidityProviderID sequence

```sql
SELECT t1.LiquidityProviderID + 1 AS candidate
FROM Trade.LiquidityProviders t1 WITH (NOLOCK)
LEFT JOIN Trade.LiquidityProviders t2 WITH (NOLOCK)
    ON t1.LiquidityProviderID + 1 = t2.LiquidityProviderID
WHERE t2.LiquidityProviderID IS NULL
AND t1.LiquidityProviderID + 1 > 0
ORDER BY candidate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller (Trade.SetNextLiquidityAccountID) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetNextLiquidityProviderID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetNextLiquidityProviderID.sql*
