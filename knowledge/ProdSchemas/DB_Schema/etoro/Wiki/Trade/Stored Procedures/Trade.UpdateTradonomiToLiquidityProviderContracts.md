# Trade.UpdateTradonomiToLiquidityProviderContracts

> Applies XML-driven ADD and DELETE operations to the Trade.TradonomiToLiquidityProviderContracts mapping table within a single atomic transaction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @XML input; modifies Trade.TradonomiToLiquidityProviderContracts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Tradonomi contracts are agreements between eToro and liquidity providers that govern how orders are routed to the market. This procedure manages the many-to-many mapping between Tradonomi contracts and Liquidity Provider contracts - defining which liquidity providers are eligible to fulfill trades under a given Tradonomi agreement.

The procedure acts as the write interface for the TradonomiToLiquidityProviderContracts table, accepting changes via an XML payload that specifies records to add and records to delete. Using XML as the protocol allows a single call to carry a mixed batch of additions and deletions atomically - either all succeed or all roll back. This is the standard eToro pattern for XML-driven configuration updates.

The procedure is accessible to PROD_BIadmins, indicating it is used by operations/BI admin processes when liquidity provider routing configurations change - for example, when a new liquidity provider is onboarded under a Tradonomi agreement, or when an existing routing is retired.

---

## 2. Business Logic

### 2.1 XML-Driven Batch Processing

**What**: A single XML document can carry both ADD and DELETE operations, processed in order within one transaction.

**Columns/Parameters Involved**: `@XML`, `TradonomiContractID`, `LiquidityProviderContractID`

**Rules**:
- XML root element is `<ROOT>`
- `<ADD>` child nodes trigger INSERT INTO Trade.TradonomiToLiquidityProviderContracts
- `<DELETE>` child nodes trigger DELETE FROM Trade.TradonomiToLiquidityProviderContracts (matched on both TradonomiContractID AND LiquidityProviderContractID - composite key match)
- ADDs are processed before DELETEs in the procedure flow
- Both TradonomiContractID and LiquidityProviderContractID are extracted as INT attributes from the XML nodes

**Diagram**:
```
@XML input:
<ROOT>
  <ADD TradonomiContractID="1" LiquidityProviderContractID="3"/>   -> INSERT
  <ADD TradonomiContractID="2" LiquidityProviderContractID="5"/>   -> INSERT
  <DELETE TradonomiContractID="1" LiquidityProviderContractID="2"/> -> DELETE
</ROOT>

BEGIN TRAN
  -> INSERT all ADD nodes
  -> DELETE all DELETE nodes (CTE match on composite key)
COMMIT / ROLLBACK on error
```

### 2.2 Transactional Atomicity

**What**: All ADD and DELETE operations succeed or fail together.

**Rules**:
- Wrapped in BEGIN TRY / BEGIN TRAN ... COMMIT TRAN
- On any error: ROLLBACK TRAN, RETURN(-1)
- On success: COMMIT TRAN, RETURN(0)
- Return code 0 = success, -1 = failure (caller should check return code)
- NOCOUNT ON prevents rowcount messages from interfering with the return code

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @XML | XML | NO | - | CODE-BACKED | XML document specifying the contract mapping changes to apply. Must follow the structure `<ROOT><ADD TradonomiContractID="N" LiquidityProviderContractID="N"/><DELETE TradonomiContractID="N" LiquidityProviderContractID="N"/></ROOT>`. ADD nodes create new mappings; DELETE nodes remove existing mappings matched by composite key (TradonomiContractID + LiquidityProviderContractID). Both attributes are required for each node and are parsed as INT. |

**Return values:**
- RETURN(0): All operations committed successfully
- RETURN(-1): An error occurred; all changes rolled back

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/DELETE target | Trade.TradonomiToLiquidityProviderContracts | Writer + Deleter | Adds and removes rows in the Tradonomi-to-LiquidityProvider contract mapping table based on the XML input |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Permission grant | BI/OPS admin processes call this when updating liquidity provider routing configurations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateTradonomiToLiquidityProviderContracts (procedure)
└── Trade.TradonomiToLiquidityProviderContracts (table - INSERT/DELETE target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiToLiquidityProviderContracts | Table | INSERT (ADD nodes) and DELETE (DELETE nodes) target - manages the Tradonomi-to-LP contract mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins role | Permission | Execute access for BI admin processes managing liquidity provider configurations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XML attribute parsing | Business logic | TradonomiContractID and LiquidityProviderContractID extracted via `.value('(@AttributeName)[1]', 'INT')` - both must be valid integers or the procedure will throw |
| Composite key DELETE | Business logic | DELETE matches on BOTH TradonomiContractID AND LiquidityProviderContractID via CTE INNER JOIN - a partial match does not delete |
| TRY/CATCH atomicity | Business logic | All changes atomic - partial success is not possible |

---

## 8. Sample Queries

### 8.1 View all active Tradonomi-to-LP contract mappings

```sql
SELECT
    ttlpc.TradonomiContractID,
    ttlpc.LiquidityProviderContractID
FROM Trade.TradonomiToLiquidityProviderContracts ttlpc WITH (NOLOCK)
ORDER BY ttlpc.TradonomiContractID, ttlpc.LiquidityProviderContractID
```

### 8.2 Find all LP contracts mapped to a specific Tradonomi contract

```sql
SELECT
    TradonomiContractID,
    LiquidityProviderContractID
FROM Trade.TradonomiToLiquidityProviderContracts WITH (NOLOCK)
WHERE TradonomiContractID = 1
ORDER BY LiquidityProviderContractID
```

### 8.3 Add a new LP contract mapping and remove an old one via XML

```sql
DECLARE @xml XML = N'<ROOT>
    <ADD TradonomiContractID="3" LiquidityProviderContractID="7"/>
    <DELETE TradonomiContractID="3" LiquidityProviderContractID="2"/>
</ROOT>'

DECLARE @result INT
EXEC @result = Trade.UpdateTradonomiToLiquidityProviderContracts @XML = @xml
SELECT @result AS ReturnCode  -- 0 = success, -1 = failure
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateTradonomiToLiquidityProviderContracts | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateTradonomiToLiquidityProviderContracts.sql*
