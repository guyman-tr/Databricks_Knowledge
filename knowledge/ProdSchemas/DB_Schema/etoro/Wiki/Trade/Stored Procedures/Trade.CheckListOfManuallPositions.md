# Trade.CheckListOfManuallPositions

> Validates a list of CID+PositionID pairs for manual position operations, returning sub-tree aggregates (units, amount), user profile details (fund/PI status, AUM), and flagging ineligible positions (China users, leveraged, copied).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @tbl (TVP Trade.CIDsAndPositionIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckListOfManuallPositions is used before performing manual position operations (such as manual closes or adjustments) to validate a batch of positions and gather context about them. It serves three purposes:

1. **Sub-tree aggregation**: For each position, it walks the copy-tree (via recursive CTE on ParentPositionID) to compute total units and amount across the entire sub-tree, along with the current market rate. Only positions with Leverage=1, non-China users (CountryID <> 44), and non-mirror positions (MirrorID=0) are included at the root level.

2. **CID mismatch detection**: Checks whether any input PositionID belongs to a different CID than the one provided, returning mismatches as a second result set.

3. **Ineligibility flagging**: Returns a third result set listing positions that fail eligibility rules: user from China (CountryID=44), position has leverage > 1, or position is a copied position (MirrorID > 0).

The procedure also computes AUM (Assets Under Management) for each input CID by recursively walking the mirror tree and summing mirror+position amounts.

---

## 2. Business Logic

### 2.1 Sub-Tree Position Aggregation

**What**: Recursively walks the position copy-tree to compute total units and amount.

**Columns/Parameters Involved**: `PositionID`, `ParentPositionID`, `AmountInUnitsDecimal`, `Amount`, `IsBuy`, `Bid`, `Ask`

**Rules**:
- Root: Trade.PositionTbl with Leverage=1, CountryID <> 44, MirrorID=0
- Recursive: Trade.Position joined on ParentPositionID
- Rate = Bid if IsBuy=1, Ask otherwise (from Trade.CurrencyPrice)
- SubTreeUnits = SUM(AmountInUnitsDecimal) across all tree nodes
- SubTreeAmount = SUM(Amount) across all tree nodes

### 2.2 AUM Calculation

**What**: Recursively walks mirror hierarchy to sum total AUM per CID.

**Columns/Parameters Involved**: `CID`, `ParentCID`, `Mirror.Amount`, `PositionTbl.Amount`

**Rules**:
- AUM = SUM(MirrorAmount + PositionAmount) across the entire mirror tree
- Starts from input CID and follows Trade.Mirror via ParentCID

### 2.3 CID Mismatch Detection

**What**: Identifies positions where the input CID does not match the actual position owner.

**Columns/Parameters Involved**: `Trade.GetPositionData.CID`, input `CID`

**Rules**:
- Joins input table to Trade.GetPositionData on PositionID WHERE CID differs
- Returns InputCID vs RealCID for each mismatch

### 2.4 Ineligibility Rules

**What**: Flags positions that cannot be manually operated on.

**Rules**:
- "User is from China": Customer.Customer.CountryID = 44
- "Position has leverage greater than 1": Trade.Position.Leverage > 1
- "The position is a copied position": Trade.Position.MirrorID > 0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @tbl | Trade.CIDsAndPositionIDs (TVP) | NO | - | CODE-BACKED | READONLY table of CID+PositionID pairs to validate. |

### Output Result Sets

**Result Set 1 - Position Details**: CID, PositionID, IsFund, IsPI, AUM, PositionID, InstrumentID, Rate, AmountInUnitsDecimal, Amount, SubTreeUnits, SubTreeAmount

**Result Set 2 - CID Mismatches** (conditional): PositionID, InputCID, RealCID

**Result Set 3 - Ineligible Positions**: CID, PositionID, Reason (text)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @tbl.PositionID | Trade.PositionTbl | JOIN | Root positions for sub-tree walk |
| @tbl.PositionID | Trade.Position | JOIN (recursive) | Child positions in copy-tree |
| InstrumentID | Trade.CurrencyPrice | JOIN | Current Bid/Ask rates |
| @tbl.CID | Customer.CustomerStatic | JOIN | CountryID filter (China exclusion) |
| @tbl.CID | BackOffice.Customer | JOIN | AccountTypeID (fund detection) and GuruStatusID (PI detection) |
| @tbl.CID | Trade.Mirror | JOIN (recursive) | Mirror tree for AUM calculation |
| @tbl.CID | Trade.PositionTbl | JOIN | Position amounts for AUM |
| @tbl.PositionID | Trade.GetPositionData | JOIN | CID ownership verification |
| @tbl.CID | Customer.Customer | JOIN | CountryID for China check in result set 3 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office tools | (external) | EXEC | Manual position validation before operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckListOfManuallPositions (procedure)
+-- Trade.CIDsAndPositionIDs (TVP type)
+-- Trade.PositionTbl (table)
+-- Trade.Position (table)
+-- Trade.CurrencyPrice (table)
+-- Customer.CustomerStatic (table)
+-- BackOffice.Customer (table)
+-- Trade.Mirror (table)
+-- Trade.GetPositionData (view/table)
+-- Customer.Customer (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CIDsAndPositionIDs | Table Type (TVP) | Input parameter type |
| Trade.PositionTbl | Table | Root position data |
| Trade.Position | Table | Recursive sub-tree walk |
| Trade.CurrencyPrice | Table | Current market rates |
| Customer.CustomerStatic | Table | Country filter |
| BackOffice.Customer | Table | Fund/PI status |
| Trade.Mirror | Table | AUM calculation |
| Trade.GetPositionData | View/Table | CID ownership verification |
| Customer.Customer | Table | Country check for ineligibility |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office tools | External | Manual position validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Recursive CTEs | Pattern | SubTreeDetails and AUMDetails both use recursive CTEs - may be expensive on deep trees |
| No NOLOCK hints | Concurrency | Procedure takes shared locks on all joined tables |
| Three result sets | API | Caller must handle multiple result sets |

---

## 8. Sample Queries

### 8.1 Validate a list of positions

```sql
DECLARE @tbl Trade.CIDsAndPositionIDs;
INSERT INTO @tbl (CID, PositionID) VALUES (12345, 67890);
EXEC Trade.CheckListOfManuallPositions @tbl = @tbl;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckListOfManuallPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckListOfManuallPositions.sql*
