# Trade.IsInstrumentInGroup

> Scalar function that checks whether an instrument belongs to a specific instrument group. Returns 1 if a row exists in Trade.InstrumentGroups for the (InstrumentID, GroupID) pair, else 0.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Return value (BIT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsInstrumentInGroup answers the question: "Is Instrument X in Group Y?" Instrument groups (Dictionary.TradingInstrumentGroups) classify instruments by type—e.g., GroupID 25 = futures, GroupID for forex, commodities, etc. Trade.InstrumentGroups maps (ProviderID, InstrumentID) to GroupID; this function checks existence for a given InstrumentID and GroupID without requiring ProviderID (it uses EXISTS with InstrumentID and GroupID only).

This function exists because many business rules depend on instrument classification. Trade.DelistStock uses it to detect futures instruments (GroupID=25) for delisting logic. Without it, every caller would need to write `SELECT 1 FROM Trade.InstrumentGroups WHERE InstrumentID=@InstrumentID AND GroupID=@GroupID` and interpret the result. The function encapsulates that pattern and returns a clean BIT.

Data flows: Callers pass @InstrumentID and @GroupID. The function runs `EXISTS (SELECT TOP 1 1 FROM Trade.InstrumentGroups WHERE InstrumentID=@InstrumentID AND GroupID=@GroupID)` and returns 1 if found, 0 otherwise. Trade.InstrumentGroups has composite PK (InstrumentID, GroupID) and FK to Dictionary.TradingInstrumentGroups; ProviderID is also in the table but the function does not filter by it—so an instrument in any provider's mapping for that group will match.

---

## 2. Business Logic

### 2.1 Group Membership Check

**What**: A single EXISTS check determines membership. No ProviderID filter—any provider mapping satisfies.

**Columns/Parameters Involved**: `@InstrumentID`, `@GroupID`, `InstrumentID`, `GroupID`

**Rules**:
- Trade.InstrumentGroups stores (ProviderID, InstrumentID, GroupID). The function filters only by InstrumentID and GroupID.
- If multiple rows exist (same instrument in same group across providers), EXISTS returns true once.
- GroupID references Dictionary.TradingInstrumentGroups. Common values: 25 = futures (per DelistStock usage).

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | The eToro instrument (Trade.Instrument.InstrumentID) to check. |
| 2 | @GroupID | int | NO | - | CODE-BACKED | The instrument group (Dictionary.TradingInstrumentGroups.GroupID). E.g., 25 = futures. |
| 3 | (return) | bit | NO | - | CODE-BACKED | 1 = instrument is in the group (row exists in Trade.InstrumentGroups), 0 = not in group. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentGroups | Implicit | InstrumentID column in WHERE. |
| @GroupID | Trade.InstrumentGroups | Implicit | GroupID column in WHERE. FK to Dictionary.TradingInstrumentGroups. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DelistStock | @IsFuturesInstrument | Reader | Checks if instrument is in futures group (25) for delisting logic. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsInstrumentInGroup (function)
└── Trade.InstrumentGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentGroups | Table | FROM — EXISTS check on InstrumentID, GroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DelistStock | Procedure | Calls to set @IsFuturesInstrument for delist logic |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if instrument is in futures group
```sql
SELECT Trade.IsInstrumentInGroup(100000, 25) AS IsFutures;
```

### 8.2 List instruments in a specific group
```sql
DECLARE @GroupID INT = 25;
SELECT I.InstrumentID, I.InstrumentDisplayName
FROM   Trade.Instrument I WITH (NOLOCK)
WHERE  Trade.IsInstrumentInGroup(I.InstrumentID, @GroupID) = 1
ORDER BY I.InstrumentID;
```

### 8.3 Filter procedures by instrument group (example)
```sql
-- Example: Only process futures instruments
IF Trade.IsInstrumentInGroup(@InstrumentID, 25) = 1
BEGIN
   -- Futures-specific logic
END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.IsInstrumentInGroup | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.IsInstrumentInGroup.sql*
