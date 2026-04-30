# BackOffice.SetLotCountGroupID

> Assigns a new lot count group to a customer and simultaneously updates their player level by resolving the PlayerLevelID from the Dictionary.LotCountGroup lookup table.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetLotCountGroupID assigns a customer to a specific lot count group, which determines the lot size thresholds used in their trading experience. The LotCountGroupID controls how many trades are required to advance to the next player level (gamification tier). Critically, this procedure also resolves and updates the PlayerLevelID - it does NOT require the caller to separately look up the correct player level for the group.

The procedure is used by BackOffice when manually assigning or overriding a customer's trading tier, for example as part of promotions, corrections, or VIP program management. The automatic PlayerLevelID resolution prevents inconsistency: the lot count group and player level are always set together in a single atomic update.

---

## 2. Business Logic

### 2.1 Two-Column Coordinated Update (LotCountGroup + PlayerLevel)

**What**: LotCountGroupID and PlayerLevelID are always updated together - they form a coordinated pair.

**Columns/Parameters Involved**: `@LotCountGroupID`, `@CID`, `@PlayerLevelID` (internal)

**Rules**:
- Step 1: SELECT @PlayerLevelID = PlayerLevelID FROM Dictionary.LotCountGroup WITH(NOLOCK) WHERE LotCountGroupID=@LotCountGroupID (resolve the correct player level for this group)
- Step 2: UPDATE Customer.Customer SET LotCountGroupID=@LotCountGroupID, PlayerLevelID=@PlayerLevelID WHERE CID=@CID
- If @LotCountGroupID not found in Dictionary.LotCountGroup: @PlayerLevelID remains NULL, and Customer.PlayerLevelID is set to NULL (no validation check in procedure)
- Returns @@ERROR (0=success)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | The customer whose lot count group and player level are being set. Must correspond to a CID in Customer.Customer. No FK validation - invalid CID causes a 0-row no-op. |
| 2 | @LotCountGroupID | INT | NO | - | VERIFIED | The lot count group to assign. FK semantics to Dictionary.LotCountGroup. The procedure resolves the associated PlayerLevelID from this table before updating the customer. Determines the lot-size thresholds and gamification tier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LotCountGroupID | Dictionary.LotCountGroup | Lookup (SELECT PlayerLevelID) | Resolves the correct PlayerLevelID for the given lot count group |
| @CID | Customer.Customer | MODIFIER (UPDATE LotCountGroupID + PlayerLevelID) | Sets both lot count group and player level together |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice lot count group management | - | Caller | Called to assign or override lot count groups for customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetLotCountGroupID (procedure)
├── Dictionary.LotCountGroup (table)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.LotCountGroup | Table | SELECT PlayerLevelID WHERE LotCountGroupID=@LotCountGroupID |
| Customer.Customer | Table | UPDATE: SET LotCountGroupID=@LotCountGroupID, PlayerLevelID=@PlayerLevelID WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice trading tier management | External | Assigns lot count groups for customer tier promotion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Assign a customer to a lot count group
```sql
DECLARE @Err INT
EXEC @Err = BackOffice.SetLotCountGroupID
    @CID           = 12345678,
    @LotCountGroupID = 3
SELECT @Err AS ErrorCode
```

### 8.2 Preview what PlayerLevelID would be resolved for a group
```sql
SELECT LotCountGroupID, PlayerLevelID
FROM Dictionary.LotCountGroup WITH (NOLOCK)
WHERE LotCountGroupID = 3
```

### 8.3 Find all customers in a specific lot count group
```sql
SELECT CID, LotCountGroupID, PlayerLevelID
FROM Customer.Customer WITH (NOLOCK)
WHERE LotCountGroupID = 3
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetLotCountGroupID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetLotCountGroupID.sql*
