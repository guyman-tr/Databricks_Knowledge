# Trade.GetTradingRiskStatus

> Returns the TradingRiskStatusID for a customer from BackOffice.Customer - a computed column that derives the customer's trading risk tier from their regulation, MiFID categorization, and Seychelles categorization. Single-row lookup by CID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the **trading risk status** for a customer - a regulatory tier that determines the leverage limits and protections applicable to their account. The value is derived from a computed column in `BackOffice.Customer` that maps the customer's regulatory classification (MiFID categorization, regulation, Seychelles categorization) to a risk tier integer (1-4).

**TradingRiskStatusID values** (derived from COINF-1394 computed column logic in BackOffice.Customer):
- **1**: Professional client (EU MiFID Professional, or Seychelles Category 1) - higher leverage limits permitted
- **2**: Elective professional or intermediate tier (specific RegulationID + MifidCategorizationID combinations)
- **3**: Retail client (standard regulatory restrictions apply - ESMA leverage caps, negative balance protection)
- **4**: Default/standard (test environments, uncategorized, or specific categorizations that default to standard)

The computed column logic in BackOffice.Customer:
- Test/QA database names always return 4
- Seychelles categorizations map: 0->3, 1->1, 2->4
- RegulationID=11 -> 3
- ASIC (RegulationID=4 or 10, AsicClassificationID NULL or =4) -> 3 (retail)
- EU (RegulationID=1 or 2) + MifidCategorizationID=4 -> 1 (professional)
- EU + MifidCategorizationID=1 -> 3 (retail)
- EU + MifidCategorizationID=5 -> 2
- EU + MifidCategorizationID=2 or 3 -> 4
- RegulationID=5 (ASIC with designated reg) + MifidCategorizationID=1 -> 3
- Default -> 4

**Usage**: The trading engine uses TradingRiskStatusID to apply the correct leverage limits, margin requirements, and regulatory protections for the customer's account type.

---

## 2. Business Logic

### 2.1 Computed Risk Status Lookup

**What**: Single-column point lookup - reads the pre-computed regulatory risk tier for one customer.

**Columns/Parameters Involved**: `@CID`, `BackOffice.Customer.TradingRiskStatusID`

**Rules**:
- `WHERE CID = @CID`: exact match on primary key
- `TradingRiskStatusID` is a computed column (not stored) - SQL Server evaluates the CASE expression at query time
- Returns 0 or 1 row (CID is the PK of BackOffice.Customer)
- NOLOCK: acceptable for risk status reads; the computed column's dependencies (RegulationID, MifidCategorizationID) rarely change

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to look up. PK of BackOffice.Customer. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | TradingRiskStatusID | INT (computed) | NO | - | CODE-BACKED | Customer's regulatory risk tier: 1=Professional (higher leverage), 2=Elective professional/intermediate, 3=Retail (standard ESMA/ASIC restrictions), 4=Default/standard (test environments, uncategorized). Computed from RegulationID, MifidCategorizationID, SeychellesCategorizationID, AsicClassificationID, DesignatedRegulationID. Added COINF-1394 (2022-11-08). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TradingRiskStatusID | BackOffice.Customer | Reader (cross-schema) | SELECT TradingRiskStatusID WHERE CID = @CID; NOLOCK; computed column |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading engine / risk service | @CID | Application call | Determines leverage limits and regulatory protections to apply for this customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTradingRiskStatus (procedure)
+-- BackOffice.Customer (table - cross-schema)
     +-- TradingRiskStatusID (computed from RegulationID, MifidCategorizationID,
         SeychellesCategorizationID, AsicClassificationID, DesignatedRegulationID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table (BackOffice schema) | SELECT TradingRiskStatusID WHERE CID = @CID; NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading engine / leverage service | External application | Reads regulatory risk tier for position opening, leverage validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| NOLOCK | Isolation hint | READ UNCOMMITTED; TradingRiskStatusID is a computed column, changes infrequently |
| Computed column | Design | TradingRiskStatusID is evaluated at query time from RegulationID, MifidCategorizationID, SeychellesCategorizationID, AsicClassificationID, DesignatedRegulationID and db_name() |

---

## 8. Sample Queries

### 8.1 Get trading risk status for a customer

```sql
EXEC Trade.GetTradingRiskStatus @CID = 12345;
```

### 8.2 Equivalent inline query

```sql
SELECT TradingRiskStatusID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Distribution of risk statuses across all customers

```sql
SELECT TradingRiskStatusID, COUNT(*) AS CustomerCount
FROM BackOffice.Customer WITH (NOLOCK)
GROUP BY TradingRiskStatusID
ORDER BY TradingRiskStatusID;
```

---

## 9. Atlassian Knowledge Sources

**Comment in BackOffice.Customer DDL**: "COINF-1394 TradingRiskStatusID - add new column and update calculation" (Yulia Kramer, 2022-11-08). Full Jira context not accessible (Jira MCP returning 410).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira (Jira MCP 410) | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetTradingRiskStatus | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTradingRiskStatus.sql*
