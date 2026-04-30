# Customer.SetPlayerLevel

> Updates a customer's player level tier and the corresponding lot count group in Customer.Customer, atomically linking tier and trading lot-size configuration.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (input) - the customer being updated |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.SetPlayerLevel` is the write endpoint for changing a customer's player level (loyalty tier). It performs two coordinated updates: setting the `PlayerLevelID` and simultaneously resolving and setting the `LotCountGroupID` - the group that governs how many lot-count slots the customer can use for trading.

The procedure is called by both the automated tier-recalculation job (via `Customer.SetPlayerLevelNoLot`) and by manual/logout-triggered reassignments (History.LogOutByCID, History.LogOutByLoginID). By resolving `LotCountGroupID` automatically from `Dictionary.LotCountGroup` (keyed by `PlayerLevelID`), it ensures tier and lot configuration are always in sync - callers do not need to know the mapping.

---

## 2. Business Logic

### 2.1 Tier-to-LotCountGroup Mapping

**What**: Each player level is mapped to a lot count group that controls trading lot allocation.

**Columns/Parameters Involved**: `@PlayerLevelID`, `Dictionary.LotCountGroup.LotCountGroupID`

**Rules**:
- Before updating, looks up `Dictionary.LotCountGroup.LotCountGroupID WHERE PlayerLevelID = @PlayerLevelID`.
- If no mapping found (e.g., newer tiers not yet configured), @LotCountGroupID will be NULL.
- Updates Customer.Customer with BOTH PlayerLevelID and LotCountGroupID atomically.
- Current mapping (Dictionary.LotCountGroup):
  - PlayerLevelID 1 (Bronze) -> LotCountGroupID 0
  - PlayerLevelID 2 (Platinum) -> LotCountGroupID 3
  - PlayerLevelID 3 (Gold) -> LotCountGroupID 2
  - PlayerLevelID 4 (Internal) -> LotCountGroupID 4
  - PlayerLevelID 5 (Silver) -> LotCountGroupID 1
  - PlayerLevelID 6 (Platinum Plus), 7 (Diamond) -> no mapping (NULL)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to update. Written to Customer.Customer.PlayerLevelID and Customer.Customer.LotCountGroupID. |
| 2 | @PlayerLevelID | INT | NO | - | VERIFIED | New tier to assign: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (test), 5=Silver, 6=Platinum Plus, 7=Diamond. Resolved to LotCountGroupID via Dictionary.LotCountGroup. (Dictionary.PlayerLevel) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PlayerLevelID | Dictionary.LotCountGroup | Lookup | Resolves LotCountGroupID from the PlayerLevelID |
| @CID | Customer.Customer | UPDATE | Sets PlayerLevelID and LotCountGroupID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetPlayerLevelNoLot | EXEC | Caller | Calls when deposit-based tier upgrade is needed |
| History.LogOutByCID | EXEC | Caller | Recalculates tier on logout |
| History.LogOutByCID_OLD | EXEC | Caller | Legacy logout path |
| History.LogOutByLoginID | EXEC | Caller | Recalculates tier on logout by login ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetPlayerLevel (procedure)
├── Dictionary.LotCountGroup (table) [READ - resolve LotCountGroupID from PlayerLevelID]
└── Customer.Customer (view) [UPDATE - set PlayerLevelID and LotCountGroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.LotCountGroup | Table | READ - lookup LotCountGroupID by PlayerLevelID |
| Customer.Customer | View | UPDATE - writes PlayerLevelID and LotCountGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetPlayerLevelNoLot | Procedure | Calls SetPlayerLevel when deposit-based upgrade is detected |
| History.LogOutByCID | Procedure | Calls on logout to recalculate tier |
| History.LogOutByCID_OLD | Procedure | Legacy logout, calls SetPlayerLevel |
| History.LogOutByLoginID | Procedure | Calls on logout-by-login-ID to recalculate tier |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @@ERROR | Error return | Returns @@ERROR after the UPDATE; callers should check for non-zero return |

---

## 8. Sample Queries

### 8.1 Check current tier and lot count group for a customer

```sql
SELECT
    c.CID,
    c.PlayerLevelID,
    pl.Name AS TierName,
    c.LotCountGroupID,
    lcg.PlayerLevelID AS LotGroupTierID
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON pl.PlayerLevelID = c.PlayerLevelID
LEFT JOIN Dictionary.LotCountGroup lcg WITH (NOLOCK) ON lcg.LotCountGroupID = c.LotCountGroupID
WHERE c.CID = 12345
```

### 8.2 View the full tier-to-lot-group mapping

```sql
SELECT
    pl.PlayerLevelID,
    pl.Name AS TierName,
    pl.Sort,
    lcg.LotCountGroupID
FROM Dictionary.PlayerLevel pl WITH (NOLOCK)
LEFT JOIN Dictionary.LotCountGroup lcg WITH (NOLOCK) ON lcg.PlayerLevelID = pl.PlayerLevelID
ORDER BY pl.Sort
```

### 8.3 Find customers where tier and lot group are out of sync

```sql
SELECT
    c.CID,
    c.PlayerLevelID,
    c.LotCountGroupID,
    lcg.LotCountGroupID AS ExpectedLotCountGroupID
FROM Customer.Customer c WITH (NOLOCK)
LEFT JOIN Dictionary.LotCountGroup lcg WITH (NOLOCK) ON lcg.PlayerLevelID = c.PlayerLevelID
WHERE c.LotCountGroupID <> lcg.LotCountGroupID
   OR (c.LotCountGroupID IS NOT NULL AND lcg.LotCountGroupID IS NULL)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetPlayerLevel | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetPlayerLevel.sql*
