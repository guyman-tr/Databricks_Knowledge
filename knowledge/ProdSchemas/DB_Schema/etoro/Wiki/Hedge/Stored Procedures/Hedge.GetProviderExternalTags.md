# Hedge.GetProviderExternalTags

> Returns all FIX protocol custom tag definitions for a specific liquidity provider type, providing the hedge engine with the provider-specific header/trailer tags required for FIX session message construction.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderTypeID - required filter; one provider's tag set per call |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetProviderExternalTags` loads the FIX protocol custom tag dictionary for a specific liquidity provider type. Different LPs require different sets of FIX custom tags in their order and session messages - proprietary tags that identify the eToro client, routing instructions, account identifiers, or other LP-specific metadata. This procedure provides the hedge engine with the exact tag set needed to build compliant FIX messages for a given provider.

The `TagID` is the FIX field number (e.g., 49=SenderCompID, 56=TargetCompID, but also LP-proprietary tags in the 5000-9999 range). The `TagValue` is the value to send for that tag. Some tags may be static (same value always - e.g., eToro's SenderCompID), while others may be dynamic (computed at runtime from account or order context - the `TagValue` in this case stores a template or key that the engine resolves at runtime).

The `LiquidityAccountID` column allows tag values to vary per LP account under the same provider type - eToro may have multiple accounts with the same LP (e.g., a primary account and a backup account), each requiring different account-identifier tag values.

Data flows as follows: on startup or when establishing a FIX connection to a new LP, the hedge engine calls this procedure with the provider's type ID. It loads all returned tags into its FIX session configuration. When building FIX messages (New Order Single, Order Cancel, etc.), the engine injects these tags into the appropriate message sections.

---

## 2. Business Logic

### 2.1 Provider-Scoped Tag Set Retrieval

**What**: Returns all FIX custom tag definitions for one provider type, scoped by `ProviderTypeID`. No further filtering is applied - all tags (all TagIDs, all LiquidityAccountIDs) for this provider type are returned.

**Columns/Parameters Involved**: `@ProviderTypeID`, `ProviderTypeID`, `TagID`, `TagValue`, `LiquidityAccountID`

**Rules**:
- WHERE ProviderTypeID = @ProviderTypeID: returns only tags for the specified provider type
- No TagID filter - all tags for this provider are returned in one call
- Multiple rows per ProviderTypeID are normal: one row per (ProviderTypeID, TagID, LiquidityAccountID) combination
- LiquidityAccountID is included in output so the hedge engine can apply per-account tag overrides
- SET TRAN ISOLATION LEVEL READ UNCOMMITTED: avoids blocking on the ProviderExternalTags table even if a concurrent write is in progress (configuration changes are rare and dirty reads acceptable for tag loading)

**Diagram**:
```
FIX session setup for ProviderTypeID=3 (e.g., Saxo Bank):
  GetProviderExternalTags(@ProviderTypeID=3)
       |
       v
  Returns: TagID=49, TagValue='ETORO_FIX', LiquidityAccountID=10
           TagID=56, TagValue='SAXO_FX',   LiquidityAccountID=10
           TagID=5001, TagValue='ACCT_001', LiquidityAccountID=10
           TagID=5001, TagValue='ACCT_002', LiquidityAccountID=11
       |
       v
  Hedge engine injects into FIX New Order Single:
    8=FIX.4.4|49=ETORO_FIX|56=SAXO_FX|5001=ACCT_001|...
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderTypeID | int | NO | - | VERIFIED | The liquidity provider type whose FIX tag set to retrieve. Required parameter - no default. Corresponds to Hedge.ProviderExternalTags.ProviderTypeID and a provider type lookup. Each distinct LP type (e.g., Saxo, FXCM, Currenex) has its own tag set. |

**Output columns** (from Hedge.ProviderExternalTags):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | ProviderTypeID | int | NO | - | VERIFIED | The liquidity provider type, echoed from the filter. Included in output for context when the hedge engine iterates over results. |
| 3 | TagID | int | NO | - | VERIFIED | FIX protocol field number. Standard FIX tags (1-999) correspond to the FIX 4.x specification. Proprietary LP tags (5000+) are custom extensions agreed with the LP. This identifies which FIX message field carries this value. |
| 4 | TagValue | varchar | YES | - | VERIFIED | The value to send in this FIX field. May be a static string (e.g., SenderCompID='ETORO_FIX'), a numeric code, or a dynamic template key that the hedge engine resolves at order time. NULL is not expected for active tags but is technically nullable. |
| 5 | LiquidityAccountID | int | YES | - | VERIFIED | The LP account this tag applies to. Allows per-account override: different eToro accounts with the same LP may require different tag values (e.g., different account identifiers in tag 1=Account). NULL may indicate a tag that applies to all accounts under this provider type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.ProviderExternalTags | SELECT | Source of all FIX custom tag definitions; filtered by ProviderTypeID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called when establishing a FIX connection to load provider-specific tag configuration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetProviderExternalTags (procedure)
└── Hedge.ProviderExternalTags (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ProviderExternalTags | Table | SELECTed at READ UNCOMMITTED isolation - source of all FIX custom tag definitions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - called at FIX session setup to load provider-specific message tag configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. The `Hedge.ProviderExternalTags` table has a composite PK of (ProviderTypeID, TagID, LiquidityAccountID). The WHERE ProviderTypeID=@ProviderTypeID filter will use this index efficiently for an index seek.

### 7.2 Constraints

N/A for Stored Procedure. The READ UNCOMMITTED isolation level is set session-wide via SET statement (not a table hint). This avoids any lock contention during FIX session initialization. Dirty reads are acceptable because the tag configuration changes infrequently and any inconsistency is corrected on the next FIX session reconnect.

---

## 8. Sample Queries

### 8.1 Load all FIX tags for a specific provider type
```sql
EXEC [Hedge].[GetProviderExternalTags] @ProviderTypeID = 3;
```

### 8.2 Direct table query showing all tags across all providers
```sql
SELECT  ProviderTypeID,
        TagID,
        TagValue,
        LiquidityAccountID
FROM    [Hedge].[ProviderExternalTags] WITH (NOLOCK)
ORDER BY ProviderTypeID, TagID, LiquidityAccountID;
```

### 8.3 Find which providers have custom tag 5001 configured
```sql
SELECT  DISTINCT ProviderTypeID
FROM    [Hedge].[ProviderExternalTags] WITH (NOLOCK)
WHERE   TagID = 5001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetProviderExternalTags | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetProviderExternalTags.sql*
