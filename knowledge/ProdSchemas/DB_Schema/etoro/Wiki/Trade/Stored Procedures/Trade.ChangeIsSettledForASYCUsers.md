# Trade.ChangeIsSettledForASYCUsers

> Converts positions from IsSettled=1 (real stock) to IsSettled=0 (CFD) for ASIC (Australian) and FSA Seychelles regulated users who are not US users, including all positions in their copy-trade trees.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters - batch conversion job) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangeIsSettledForASYCUsers is a regulatory compliance batch job that converts real-stock positions (IsSettled=1) to CFD positions (IsSettled=0) for customers under specific regulatory jurisdictions. ASIC-regulated users (RegulationID=4) in Australia and FSA Seychelles-regulated users (RegulationID=9) are subject to regulations that restrict real stock ownership for certain instrument types.

This procedure exists because regulatory changes required eToro to convert existing real-stock positions to CFD positions for affected users. ASIC users cannot hold real stocks in crypto (InstrumentTypeID=10), while FSA Seychelles users cannot hold real stocks in stocks or ETFs (InstrumentTypeID IN (5,6)). The conversion preserves the position itself but changes the settlement type, affecting PnL calculation, fees, and corporate action eligibility.

The procedure walks the copy-trade tree to ensure ALL positions in the tree are converted (not just the root). It uses Trade.PositionTbl_SetIsSettled to change each position individually, processing row-by-row via a WHILE loop. Errors on individual positions are silently caught to allow the batch to continue.

---

## 2. Business Logic

### 2.1 Regulatory Filtering

**What**: Identifies positions that must be converted from real to CFD based on regulation and instrument type.

**Columns/Parameters Involved**: `RegulationID`, `InstrumentTypeID`, `IsSettled`, `LabelID`, `IsUsUser`

**Rules**:
- LabelID IN (1, 2, 9, 29) - specific customer label categories
- RegulationID = 4 (ASIC): All instrument types EXCEPT crypto (InstrumentTypeID != 10) must be CFD
- RegulationID = 9 (FSA Seychelles): All instrument types EXCEPT stocks and ETFs (InstrumentTypeID NOT IN (5, 6)) must be CFD
- Only InstrumentTypeID IN (5, 6, 10) - Stocks, ETFs, Crypto are in scope
- US users (Trade.IsUsUser = 1) are excluded
- Only positions with IsSettled = 1 and not in redeem process (RedeemStatus = 0 or NULL)

### 2.2 Copy-Trade Tree Traversal

**What**: Finds all positions in the same copy-trade tree as the affected positions to ensure consistent conversion.

**Columns/Parameters Involved**: `TreeID`, `ParentPositionID`, `PositionID`

**Rules**:
- First identifies "Level Zero" positions (direct matches to the regulatory criteria)
- Then finds ALL positions sharing the same TreeID as any Level Zero position
- Uses a recursive CTE walking ParentPositionID to find the complete tree
- Only positions with IsSettled = 1 are included (already-converted positions are skipped)

**Diagram**:
```
[Level Zero: Direct regulatory matches]
    |
    v
[Find all TreeIDs for Level Zero positions]
    |
    v
[Recursive CTE: Walk ParentPositionID chain]
    |
    v
[Filter: IsSettled = 1 only]
    |
    v
[WHILE loop: EXEC Trade.PositionTbl_SetIsSettled for each]
```

### 2.3 Row-by-Row Conversion

**What**: Converts each position individually using Trade.PositionTbl_SetIsSettled.

**Rules**:
- Processes positions in ascending PositionID order
- Calls Trade.PositionTbl_SetIsSettled with @NewIsSettled = 0 for each
- TRY/CATCH per position: errors are silently caught (SELECT @CurrPositionID outputs the failed ID)
- Allows the batch to continue even if individual positions fail

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It is a self-contained batch job.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | Parameterless batch procedure. All filtering criteria are hardcoded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Customer.CustomerStatic | SELECT | Gets LabelID for customer filtering |
| JOIN | BackOffice.Customer | SELECT | Gets RegulationID for regulatory filtering |
| FROM | Trade.PositionTbl | SELECT | Source of positions to evaluate and convert |
| JOIN | Trade.GetInstrument | SELECT | Filters by InstrumentTypeID (Stocks, ETFs, Crypto) |
| JOIN | Trade.InstrumentMetaData | SELECT | Gets ExchangeID for instruments |
| APPLY | Trade.IsUsUser | FUNCTION | Excludes US users from conversion |
| EXEC | Trade.PositionTbl_SetIsSettled | EXEC | Changes IsSettled flag for each individual position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled | EXEC | Runs as a scheduled compliance job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangeIsSettledForASYCUsers (procedure)
+-- Customer.CustomerStatic (table)
+-- BackOffice.Customer (table)
+-- Trade.PositionTbl (table)
+-- Trade.GetInstrument (view/synonym)
+-- Trade.InstrumentMetaData (table)
+-- Trade.IsUsUser (function)
+-- Trade.PositionTbl_SetIsSettled (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT - LabelID filtering |
| BackOffice.Customer | Table | JOIN - RegulationID filtering |
| Trade.PositionTbl | Table | SELECT - positions to evaluate and convert |
| Trade.GetInstrument | View/Synonym | JOIN - InstrumentTypeID filtering |
| Trade.InstrumentMetaData | Table | JOIN - ExchangeID data |
| Trade.IsUsUser | Function | CROSS APPLY - US user exclusion |
| Trade.PositionTbl_SetIsSettled | Procedure | EXEC - individual position conversion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Compliance scheduled job | External | Runs this periodically for regulatory compliance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Clustered index on #Cid(CID) | Performance | Speeds up the join to Trade.PositionTbl |
| Clustered index on #PositionsToConvert(ParentPositionID) | Performance | Speeds up the recursive CTE tree walk |
| Index on #Positions(PositionID) | Performance | Speeds up the WHILE loop iteration |
| TRY/CATCH per position | Error handling | Individual failures do not block the batch |

---

## 8. Sample Queries

### 8.1 Preview positions that would be affected (dry run)

```sql
SELECT  p.PositionID, p.CID, p.InstrumentID, p.IsSettled,
        bc.RegulationID, gi.InstrumentTypeID
FROM    Trade.PositionTbl p WITH (NOLOCK)
JOIN    BackOffice.Customer bc WITH (NOLOCK) ON p.CID = bc.CID
JOIN    Trade.GetInstrument gi WITH (NOLOCK) ON p.InstrumentID = gi.InstrumentID
JOIN    Customer.CustomerStatic cs WITH (NOLOCK) ON p.CID = cs.CID
CROSS APPLY Trade.IsUsUser(p.CID) iu
WHERE   p.IsSettled = 1
        AND ISNULL(p.RedeemStatus, 0) = 0
        AND cs.LabelID IN (1, 2, 9, 29)
        AND bc.RegulationID IN (4, 9)
        AND gi.InstrumentTypeID IN (5, 6, 10)
        AND iu.IsUsUser = 0
        AND ((bc.RegulationID = 4 AND gi.InstrumentTypeID != 10)
             OR (bc.RegulationID = 9 AND gi.InstrumentTypeID NOT IN (5, 6)));
```

### 8.2 Check conversion history for a specific CID

```sql
SELECT  PositionID, IsSettled, SettlementTypeID, InstrumentID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   CID = 12345 AND IsSettled = 0;
```

### 8.3 Execute the batch conversion

```sql
EXEC Trade.ChangeIsSettledForASYCUsers;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 8.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChangeIsSettledForASYCUsers | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChangeIsSettledForASYCUsers.sql*
