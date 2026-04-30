# Trade.InterestWhitelist

> Override table that whitelists specific customers to receive daily interest payments at a PlayerLevel tier different from their actual loyalty level, enabling manual qualification for Platinum Plus (6) or Diamond (7) interest rates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Row Count** | 0 (MCP verified - currently empty) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Trade.InterestWhitelist is an override table that allows back-office operators to manually assign a PlayerLevel to specific customers for the purpose of daily interest calculations. When a customer appears in this table, the interest calculation process uses the whitelisted PlayerLevelID instead of the customer's actual PlayerLevel from Customer.Customer.

Without this table, only customers who organically reach Platinum Plus (6) or Diamond (7) through the eToro Club loyalty program would earn daily interest on their cash balance. This table enables manual qualification - for example, promoting a VIP customer to Diamond-level interest rates without changing their actual club tier.

Data is managed via Trade.InsertInterestWhitelist, which uses a MERGE pattern (upsert) accepting a TVP (Trade.InterestWhitelist UDT). The daily interest job Trade.GetInterestDaily_for_Azure LEFT JOINs to this table and uses `ISNULL(tiw.PlayerLevelID, cc.PlayerLevelID)` to apply the override when present. Only PlayerLevels 6 (Platinum Plus) and 7 (Diamond) qualify for interest (1.8% yearly rate).

---

## 2. Business Logic

### 2.1 PlayerLevel Override for Interest Eligibility

**What**: Overrides a customer's natural eToro Club tier specifically for interest payment qualification.

**Columns/Parameters Involved**: `CID`, `PlayerLevelID`

**Rules**:
- Trade.GetInterestDaily_for_Azure uses `ISNULL(tiw.PlayerLevelID, cc.PlayerLevelID)` - whitelist value takes precedence over actual level
- Only PlayerLevelID 6 (Platinum Plus) and 7 (Diamond) qualify for interest payments
- Interest rate is 1.8% yearly for both qualifying tiers
- Additional eligibility filters apply: PlayerStatus.GetsInterest=1, CountryID not 250, AccountTypeID not in (7,8,9,10,11,13) which are employee and fund accounts
- The whitelist expands the eligible population: `WHERE (cc.PlayerLevelID IN (6,7) OR tiw.PlayerLevelID IN (6,7))`

**Diagram**:
```
Daily Interest Calculation:
  Customer.Customer.PlayerLevelID = 1 (Bronze - no interest)
       |
       +-- LEFT JOIN Trade.InterestWhitelist
       |       |
       |       +-- Found: Use whitelist PlayerLevelID (e.g., 7 = Diamond)
       |       +-- Not found: Use actual PlayerLevelID (1 = Bronze, no interest)
       |
       v
  ISNULL(tiw.PlayerLevelID, cc.PlayerLevelID) = effective level
       |
       +-- Level 6 or 7 --> Qualifies for 1.8% yearly interest
       +-- Level 1-5    --> No interest
```

### 2.2 Upsert Pattern for Whitelist Management

**What**: Manages whitelist entries using MERGE for insert-or-update in a single operation.

**Columns/Parameters Involved**: `CID`, `PlayerLevelID`, `InsertDate`, `ModifyDate`

**Rules**:
- Trade.InsertInterestWhitelist accepts a TVP (Trade.InterestWhitelist type) for bulk operations
- MERGE pattern: if CID exists, updates PlayerLevelID and ModifyDate; if not, inserts new row with InsertDate=GETDATE()
- This allows changing a customer's whitelist level without deleting and re-inserting

---

## 3. Data Overview

Table is currently empty (0 rows). When populated, rows represent:

| CID | PlayerLevelID | InsertDate | ModifyDate | Meaning |
|---|---|---|---|---|
| (example) 12345 | 7 (Diamond) | 2025-01-15 | 2025-01-15 | Customer 12345 manually whitelisted for Diamond-level interest (1.8% yearly) regardless of their actual eToro Club tier |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer identifier (PK). References Customer.Customer.CID. One row per whitelisted customer. The daily interest job LEFT JOINs on CID to check for overrides. |
| 2 | PlayerLevelID | int | NO | - | CODE-BACKED | Override eToro Club tier for interest eligibility. FK to Dictionary.PlayerLevel. Meaningful values: 6=Platinum Plus, 7=Diamond (both earn 1.8% yearly interest). Used via `ISNULL(tiw.PlayerLevelID, cc.PlayerLevelID)` in Trade.GetInterestDaily_for_Azure to override the customer's actual tier. |
| 3 | InsertDate | datetime | YES | getdate() | CODE-BACKED | Timestamp when the customer was first added to the whitelist. Set to GETDATE() on initial INSERT via the MERGE pattern in Trade.InsertInterestWhitelist. Not updated on subsequent modifications. |
| 4 | ModifyDate | datetime | YES | getdate() | CODE-BACKED | Timestamp of the last modification to this whitelist entry. Updated to GETDATE() on every MERGE-matched UPDATE in Trade.InsertInterestWhitelist. Used to track when the override was last changed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerLevelID | Dictionary.PlayerLevel | Explicit FK (FK_InterestWhitelist_) | Maps to the eToro Club tier: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. Only 6 and 7 are meaningful for interest eligibility. |
| CID | Customer.Customer | Implicit (no declared FK) | References the customer whose interest tier is being overridden |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInterestDaily_for_Azure | CID, PlayerLevelID | LEFT JOIN | Daily interest calculation - uses whitelist PlayerLevel to override actual tier |
| Trade.InsertInterestWhitelist | CID, PlayerLevelID | MERGE (Writer) | Upserts whitelist entries from TVP |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InterestWhitelist (table)
└── Dictionary.PlayerLevel (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerLevel | Table | FK target - PlayerLevelID references PlayerLevelID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInterestDaily_for_Azure | Stored Procedure | Reader - LEFT JOIN for interest tier override |
| Trade.InsertInterestWhitelist | Stored Procedure | Writer - MERGE upsert from TVP |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InterestWhitelist | CLUSTERED PK | CID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InterestWhitelist | PRIMARY KEY | Unique customer per whitelist entry |
| FK_InterestWhitelist_ | FOREIGN KEY | PlayerLevelID -> Dictionary.PlayerLevel(PlayerLevelID). WITH CHECK |
| DF_InterestWhitelistInsertDate | DEFAULT | InsertDate defaults to getdate() |
| DF_ModifyDate | DEFAULT | ModifyDate defaults to getdate() |

---

## 8. Sample Queries

### 8.1 List all whitelisted customers with their override tier
```sql
SELECT  iw.CID,
        pl.Name              AS OverrideTier,
        iw.InsertDate,
        iw.ModifyDate
FROM    Trade.InterestWhitelist iw WITH (NOLOCK)
JOIN    Dictionary.PlayerLevel pl WITH (NOLOCK)
        ON iw.PlayerLevelID = pl.PlayerLevelID
ORDER BY iw.ModifyDate DESC;
```

### 8.2 Find customers whitelisted for Diamond interest
```sql
SELECT  iw.CID,
        cc.PlayerLevelID     AS ActualLevel,
        iw.PlayerLevelID     AS WhitelistLevel
FROM    Trade.InterestWhitelist iw WITH (NOLOCK)
JOIN    Customer.Customer cc WITH (NOLOCK)
        ON iw.CID = cc.CID
WHERE   iw.PlayerLevelID = 7;
```

### 8.3 Check effective interest tier for a specific customer
```sql
DECLARE @CID INT = 12345;

SELECT  cc.CID,
        pl_actual.Name       AS ActualTier,
        pl_override.Name     AS WhitelistTier,
        ISNULL(iw.PlayerLevelID, cc.PlayerLevelID) AS EffectiveLevelID
FROM    Customer.Customer cc WITH (NOLOCK)
LEFT JOIN Trade.InterestWhitelist iw WITH (NOLOCK)
        ON cc.CID = iw.CID
JOIN    Dictionary.PlayerLevel pl_actual WITH (NOLOCK)
        ON cc.PlayerLevelID = pl_actual.PlayerLevelID
LEFT JOIN Dictionary.PlayerLevel pl_override WITH (NOLOCK)
        ON iw.PlayerLevelID = pl_override.PlayerLevelID
WHERE   cc.CID = @CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from procedure logic analysis (Trade.GetInterestDaily_for_Azure shows the ISNULL override pattern and interest rate configuration).

---

*Generated: 2026-03-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InterestWhitelist | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InterestWhitelist.sql*
