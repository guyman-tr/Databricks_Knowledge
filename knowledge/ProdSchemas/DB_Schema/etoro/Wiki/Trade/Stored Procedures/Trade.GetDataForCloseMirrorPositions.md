# Trade.GetDataForCloseMirrorPositions

> Gathers all data needed to close a copy-trade mirror's positions for a specific customer: open positions, pending close orders, in-flight executions, delayed closes, country, and regulation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId + @cid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDataForCloseMirrorPositions collects all the information the trading engine needs before initiating a mass close of a customer's positions under a specific copy-trade mirror. It returns six result sets covering: open positions for the mirror, pending exit orders, in-flight close executions, delayed close orders, the customer's country, and their regulation. This multi-result-set approach avoids multiple round-trips.

This procedure exists because closing a mirror's positions is a complex operation that needs to check for conflicts (positions already being closed, delayed orders pending, etc.) and needs regulatory context (country/regulation) to determine fee structures and compliance rules.

Data flows from Trade.PositionTbl (open positions for the mirror), Trade.OrdersExit (pending exits - with dead code `AND 1=0`), Trade.CloseExecutionPlan + Trade.OrderForClose + Dictionary.OrderForExecutionStatus (non-terminal close executions), Trade.DelayedOrderForClose (pending delayed closes), Customer.CustomerStatic (country), and BackOffice.Customer (regulation).

---

## 2. Business Logic

### 2.1 Multi-Result-Set Pre-Close Validation

**What**: Provides all necessary context for the close-mirror-positions workflow in one call.

**Columns/Parameters Involved**: `@mirrorId`, `@cid`, `StatusID`, `IsTerminal`

**Rules**:
- Result Set 1: Open positions for this mirror + CID (StatusID=1)
- Result Set 2: Pending exit orders - currently disabled with `AND 1=0` (dead code, always returns empty)
- Result Set 3: In-flight close executions where the order status is non-terminal (os.IsTerminal=0)
- Result Set 4: Delayed close orders with StatusID=1 (pending)
- Result Set 5: Customer's CountryID from CustomerStatic
- Result Set 6: Customer's RegulationID (using DesignatedRegulationID if set, otherwise RegulationID)

### 2.2 Regulation Resolution

**What**: Determines the effective regulation for a customer.

**Columns/Parameters Involved**: `DesignatedRegulationID`, `RegulationID`

**Rules**:
- ISNULL(DesignatedRegulationID, RegulationID): DesignatedRegulationID overrides RegulationID when explicitly set
- This determines which fee/compliance rules apply to the close operation

**Diagram**:
```
Input: @mirrorId, @cid
  |
  RS1: Trade.PositionTbl (MirrorID=@mirrorId, CID=@cid, StatusID=1)
  RS2: Trade.OrdersExit (DEAD CODE - always empty via 1=0)
  RS3: CloseExecutionPlan + OrderForClose + OrderForExecutionStatus (IsTerminal=0)
  RS4: Trade.DelayedOrderForClose (CID=@cid, StatusID=1)
  RS5: Customer.CustomerStatic (CountryID)
  RS6: BackOffice.Customer (effective RegulationID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | int | NO | - | CODE-BACKED | Mirror (copy-trade) relationship ID. FK to Trade.Mirror. |
| 2 | @cid | int | NO | - | CODE-BACKED | Customer ID whose mirror positions are being closed. |

### Output - Result Set 1 (Open Mirror Positions)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Open position ID under this mirror. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument of the position. FK to Trade.Instrument. |

### Output - Result Set 2 (Exit Orders - Dead Code)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Always empty due to `AND 1=0` filter. Legacy exit order check. |

### Output - Result Set 3 (In-Flight Close Executions)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position with a non-terminal close execution in progress. |

### Output - Result Set 4 (Delayed Close Orders)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position with a pending delayed close order. |

### Output - Result Set 5 (Customer Country)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | YES | - | CODE-BACKED | Customer's country. FK to Dictionary.Country. |

### Output - Result Set 6 (Customer Regulation)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | int | YES | - | CODE-BACKED | Effective regulation: ISNULL(DesignatedRegulationID, RegulationID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID, CID | Trade.PositionTbl | FROM | Open positions under this mirror |
| MirrorID, CID | Trade.OrdersExit | FROM | Exit orders (dead code) |
| CID | Trade.CloseExecutionPlan | JOIN | In-flight close executions |
| OrderID | Trade.OrderForClose | JOIN | Close order details |
| StatusID | Dictionary.OrderForExecutionStatus | JOIN | Terminal status check |
| CID | Trade.DelayedOrderForClose | FROM | Pending delayed close orders |
| CID | Customer.CustomerStatic | FROM | Country lookup |
| CID | BackOffice.Customer | FROM | Regulation lookup |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDataForCloseMirrorPositions (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.OrdersExit (table)
+-- Trade.CloseExecutionPlan (table)
+-- Trade.OrderForClose (table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- Trade.DelayedOrderForClose (table)
+-- Customer.CustomerStatic (table)
+-- BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT - open positions for the mirror |
| Trade.OrdersExit | Table | SELECT - pending exit orders (dead code) |
| Trade.CloseExecutionPlan | Table | JOIN - in-flight close executions |
| Trade.OrderForClose | Table | JOIN - close order details |
| Dictionary.OrderForExecutionStatus | Table | JOIN - terminal status check |
| Trade.DelayedOrderForClose | Table | SELECT - delayed close orders |
| Customer.CustomerStatic | Table | SELECT - customer country |
| BackOffice.Customer | Table | SELECT - customer regulation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers discovered |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses TRY/CATCH with THROW for error propagation.

---

## 8. Sample Queries

### 8.1 Get close-mirror data for a specific mirror and customer

```sql
EXEC Trade.GetDataForCloseMirrorPositions @mirrorId = 5001, @cid = 12345;
```

### 8.2 Check how many open positions a mirror has

```sql
SELECT  COUNT(*) AS OpenPositions
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   MirrorID = 5001
        AND CID = 12345
        AND StatusID = 1;
```

### 8.3 Find non-terminal close executions for a customer

```sql
SELECT  cep.PositionID, ofc.OrderID, os.ID AS StatusID
FROM    Trade.CloseExecutionPlan cep WITH (NOLOCK)
INNER JOIN Trade.OrderForClose ofc WITH (NOLOCK) ON cep.OrderID = ofc.OrderID
INNER JOIN Dictionary.OrderForExecutionStatus os WITH (NOLOCK) ON ofc.StatusID = os.ID
WHERE   cep.CID = 12345
        AND os.IsTerminal = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDataForCloseMirrorPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDataForCloseMirrorPositions.sql*
