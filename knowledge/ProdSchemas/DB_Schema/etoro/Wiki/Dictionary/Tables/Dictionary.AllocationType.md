# Dictionary.AllocationType

> Lookup table defining how a fund interval allocation is classified — Copy (investing via CopyTrading) or Asset (direct investment in an instrument). Used in Smart Portfolios / CopyFunds.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AllocationType (tinyint, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup with PAGE compression |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.AllocationType classifies the investment strategy behind a fund interval allocation: Copy (1) means the fund allocates by copying another user's portfolio via CopyTrading, while Asset (2) means the fund allocates by directly investing in a specific instrument. This distinction drives how Trade.FundIntervalAllocation rows are interpreted — Copy allocations follow a leader's portfolio composition, Asset allocations target a single symbol or instrument.

Without this lookup, the system could not differentiate between copy-based Smart Portfolios and asset-based funds. Trade.CreateNewFundAllocation defaults @AllocationType to 1 (Copy), and Trade.GetFundInfo exposes AllocationType for UI and reporting. The Rankings database (Fund.SetDailyAllocation, Fund.DailyAllocationType UDT) also uses this classification for daily allocation logic.

Data flows through Trade.CreateNewFundAllocation, which INSERTs into Trade.FundIntervalAllocation with @AllocationType. dbo.SSRS_Trade_CreateNewFundAllocation and dbo.AutomationFundAllocation pass the type to Trade.CreateNewFundAllocation. Trade.GetFundInfo SELECTs AllocationType when returning fund details. Rankings.Fund.SetDailyAllocation and the Fund.DailyAllocationType UDT consume the allocation type for interval-based allocation calculations.

---

## 2. Business Logic

### 2.1 Copy vs Asset Allocation

**What**: The two allocation strategies and their investment semantics.

**Columns/Parameters Involved**: `AllocationType`, `AllocationTypeDesc`

**Rules**:
- **Copy (1)**: Fund interval allocation follows CopyTrading — the fund copies another user's (leader's) portfolio. Composition is derived from the leader's positions, not a fixed instrument list.
- **Asset (2)**: Fund interval allocation targets a specific instrument or asset. Direct investment in a symbol rather than copying a leader.

**Diagram**:
```
Allocation Strategy Flow:

  Copy (1) ──────► Fund copies Leader Portfolio
                    (Trade.FundIntervalAllocation + leader reference)

  Asset (2) ─────► Fund invests in specific instrument
                    (Trade.FundIntervalAllocation + instrument/symbol)
```

### 2.2 Fund Creation Default

**What**: Default allocation type when creating new funds.

**Columns/Parameters Involved**: `AllocationType`

**Rules**:
- Trade.CreateNewFundAllocation declares `@AllocationType tinyint = 1`. New funds default to Copy allocation unless explicitly overridden.
- dbo.SSRS_Trade_CreateNewFundAllocation and dbo.AutomationFundAllocation pass @AllocationType (default 1) to Trade.CreateNewFundAllocation.

---

## 3. Data Overview

| AllocationType | AllocationTypeDesc | Meaning |
|---|---|---|
| 1 | Copy | CopyTrading-based allocation. Fund composition is driven by the leader's portfolio. Used for Smart Portfolios that mirror another user's strategy. Default when creating new funds via CreateNewFundAllocation. |
| 2 | Asset | Direct asset allocation. Fund invests in a specific instrument/symbol. Used when the fund targets a single or defined set of instruments rather than copying a leader. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AllocationType | tinyint | NO | - | CODE-BACKED | Primary key identifying the allocation strategy. 1=Copy (CopyTrading), 2=Asset (direct instrument). Referenced by Trade.FundIntervalAllocation via FK. Default value 1 in Trade.CreateNewFundAllocation. |
| 2 | AllocationTypeDesc | varchar(50) | YES | - | CODE-BACKED | Human-readable description. Values: 'Copy', 'Asset'. Nullable per DDL. Used in reports and UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FundIntervalAllocation | AllocationType | FK (FK_TFIA_AllocationType) | Fund interval allocations are classified by strategy |
| Trade.CreateNewFundAllocation | @AllocationType | Parameter (default 1) | Procedure INSERTs into FundIntervalAllocation with allocation type |
| Trade.GetFundInfo | AllocationType | SELECT | Returns allocation type in fund info result set |
| dbo.SSRS_Trade_CreateNewFundAllocation | @AllocationType | Parameter | Report proc passes type to CreateNewFundAllocation |
| dbo.AutomationFundAllocation | @AllocationType | Parameter | Automation proc passes type (default 1) |
| Rankings.Fund.SetDailyAllocation | - | Proc logic | Rankings DB uses allocation type for daily allocation |
| Rankings.Fund.DailyAllocationType | - | UDT | Rankings UDT references allocation type concept |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. Dictionary tables are leaf nodes with no code-level references.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FundIntervalAllocation | Table | FK — stores AllocationType per fund interval |
| Trade.CreateNewFundAllocation | Stored Procedure | INSERTs with @AllocationType |
| Trade.GetFundInfo | Stored Procedure | SELECTs AllocationType |
| dbo.SSRS_Trade_CreateNewFundAllocation | Stored Procedure | Passes @AllocationType to CreateNewFundAllocation |
| dbo.AutomationFundAllocation | Stored Procedure | Passes @AllocationType |
| Rankings.Fund.SetDailyAllocation | Stored Procedure | Uses allocation type in Rankings DB |
| Rankings.Fund.DailyAllocationType | User Defined Type | UDT in Rankings DB |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_AllocationType | CLUSTERED PK | AllocationType ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_AllocationType | PRIMARY KEY | Unique AllocationType. FILLFACTOR 95, DATA_COMPRESSION = PAGE, DICTIONARY filegroup. |

---

## 8. Sample Queries

### 8.1 List all allocation types
```sql
SELECT  AllocationType,
        AllocationTypeDesc
FROM    Dictionary.AllocationType WITH (NOLOCK)
ORDER BY AllocationType;
```

### 8.2 Fund interval allocations by strategy
```sql
SELECT  at.AllocationTypeDesc      AS Strategy,
        COUNT(*)                    AS FundCount
FROM    Trade.FundIntervalAllocation tfia WITH (NOLOCK)
JOIN    Dictionary.AllocationType at WITH (NOLOCK)
        ON tfia.AllocationType = at.AllocationType
GROUP BY at.AllocationTypeDesc
ORDER BY FundCount DESC;
```

### 8.3 Copy-type funds only
```sql
SELECT  tfia.*,
        at.AllocationTypeDesc
FROM    Trade.FundIntervalAllocation tfia WITH (NOLOCK)
JOIN    Dictionary.AllocationType at WITH (NOLOCK)
        ON tfia.AllocationType = at.AllocationType
WHERE   tfia.AllocationType = 1;  -- Copy
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AllocationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AllocationType.sql*
