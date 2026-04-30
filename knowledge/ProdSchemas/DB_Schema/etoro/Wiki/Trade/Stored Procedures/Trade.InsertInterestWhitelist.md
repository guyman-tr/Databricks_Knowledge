# Trade.InsertInterestWhitelist

> Upserts customer interest-rate whitelist entries via MERGE: updates PlayerLevelID for existing CIDs or inserts new ones, enabling back-office operators to manually assign Platinum Plus (6) or Diamond (7) interest tiers that override a customer's actual loyalty level for daily interest calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InterestWhitelist TVP - CID drives MERGE match |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInterestWhitelist is the write endpoint for the Trade.InterestWhitelist override table. It accepts a batch of CID/PlayerLevelID pairs via TVP and synchronizes them into Trade.InterestWhitelist using a MERGE (upsert) pattern. The procedure is the exclusive mechanism for populating and updating the whitelist.

The whitelist exists to manually promote specific customers to Platinum Plus (PlayerLevelID=6) or Diamond (PlayerLevelID=7) interest tiers without changing their actual eToro Club loyalty status. The daily interest job Trade.GetInterestDaily_for_Azure uses `ISNULL(tiw.PlayerLevelID, cc.PlayerLevelID)` when calculating eligibility - whitelist entries override organic tier. Only PlayerLevels 6 and 7 qualify for the 1.8% yearly interest rate.

Data flow: Back-office admin / operations submits a list of CIDs and their target PlayerLevelIDs. This SP merges them into Trade.InterestWhitelist. On the next interest calculation run, whitelisted CIDs receive interest at the overridden tier rate rather than their actual loyalty level.

---

## 2. Business Logic

### 2.1 MERGE Upsert - Add or Update Whitelist Entries

**What**: A single MERGE statement handles both new whitelist entries and updates to existing ones in one atomic operation.

**Columns/Parameters Involved**: `@InterestWhitelist.CID`, `@InterestWhitelist.PlayerLevelID`, `Trade.InterestWhitelist.ModifyDate`, `Trade.InterestWhitelist.CreateDate`

**Rules**:
- WHEN MATCHED (CID already in whitelist): UPDATE PlayerLevelID to new value + refresh ModifyDate=GETDATE(). CreateDate is NOT updated (preserved from original insert).
- WHEN NOT MATCHED (new CID): INSERT (CID, PlayerLevelID, CreateDate=GETDATE(), ModifyDate=GETDATE()).
- Match key: CID. PlayerLevelID change is the only meaningful update - the procedure silently re-stamps ModifyDate even if PlayerLevelID is unchanged.
- Batch operation: entire TVP is merged in one statement - supports bulk loads of any size.
- No explicit transaction or error handling: runs auto-commit. Failure in the MERGE rolls back the entire batch implicitly.

**Diagram**:
```
@InterestWhitelist TVP (CID, PlayerLevelID)
         |
         v
   MERGE Trade.InterestWhitelist
         |
         +-- CID EXISTS? --> UPDATE PlayerLevelID + ModifyDate
         |
         +-- CID NEW?    --> INSERT (CID, PlayerLevelID, CreateDate, ModifyDate)
         |
         v
   Trade.InterestWhitelist (updated)
         |
         v
   Trade.GetInterestDaily_for_Azure (reads next run)
   ISNULL(whitelist.PlayerLevelID, customer.PlayerLevelID)
   --> Override in effect for whitelisted CIDs
```

### 2.2 Whitelist Effect on Interest Eligibility

**What**: Entries written by this SP directly affect whether a customer qualifies for interest and at which rate.

**Rules**:
- PlayerLevelID 6 (Platinum Plus) and 7 (Diamond) are the only levels that qualify for daily interest (1.8% yearly).
- A customer with organic PlayerLevelID=1 (Bronze) written to the whitelist with PlayerLevelID=7 will receive Diamond-rate interest on next calculation run.
- The whitelist only expands eligibility (promotes); setting a CID to PlayerLevelID=1 via this SP would override a Diamond customer's interest eligibility downward - but this is an operator error scenario, not a designed use case.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InterestWhitelist | Trade.InterestWhitelist (TVP) | NO | - | CODE-BACKED | Table-valued parameter (TVP) carrying the batch of CID/PlayerLevelID pairs to upsert. Defined as READONLY - cannot be modified within the procedure. Drives the MERGE source. Must conform to the Trade.InterestWhitelist user-defined table type (columns: CID INT, PlayerLevelID INT). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InterestWhitelist TVP | Trade.InterestWhitelist (UDT) | Type Reference | TVP parameter type defines the shape of input rows (CID, PlayerLevelID) |
| MERGE target | Trade.InterestWhitelist (table) | Write (MERGE/upsert) | Writes or updates whitelist entries - primary output destination |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by back-office administration workflows to manage interest rate overrides.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInterestWhitelist (procedure)
+-- Trade.InterestWhitelist (UDT) - TVP type
+-- Trade.InterestWhitelist (table) - MERGE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InterestWhitelist (UDT) | User Defined Table Type | @InterestWhitelist parameter type definition |
| Trade.InterestWhitelist (table) | Table | MERGE target - upserted by this procedure |

### 6.2 Objects That Depend On This

No dependents found in stored procedures. Called externally by back-office admin tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MERGE on CID | Upsert key | CID is the match key - one row per customer in the whitelist |
| READONLY TVP | Parameter constraint | @InterestWhitelist cannot be modified within the procedure |
| Auto-commit | Transaction | No explicit transaction; MERGE is atomic for the full TVP batch |

---

## 8. Sample Queries

### 8.1 Whitelist a customer for Diamond interest rate

```sql
DECLARE @whitelist Trade.InterestWhitelist;
INSERT INTO @whitelist (CID, PlayerLevelID) VALUES (12345, 7);
EXEC Trade.InsertInterestWhitelist @InterestWhitelist = @whitelist;
```

### 8.2 Bulk whitelist multiple customers for Platinum Plus

```sql
DECLARE @whitelist Trade.InterestWhitelist;
INSERT INTO @whitelist (CID, PlayerLevelID) VALUES
    (11111, 6),  -- Platinum Plus
    (22222, 7),  -- Diamond
    (33333, 6);  -- Platinum Plus
EXEC Trade.InsertInterestWhitelist @InterestWhitelist = @whitelist;
```

### 8.3 Verify whitelist entries after upsert

```sql
SELECT CID, PlayerLevelID, CreateDate, ModifyDate
FROM   Trade.InterestWhitelist WITH (NOLOCK)
WHERE  CID IN (11111, 22222, 33333)
ORDER  BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInterestWhitelist | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInterestWhitelist.sql*
