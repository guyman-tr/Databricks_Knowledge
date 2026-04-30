# Trade.IsUsUser

> Inline table-valued function that determines whether a customer is classified as a US user based on their regulation assignment AND country group membership.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Parameters** | @CID INT |
| **Returns** | TABLE (IsUsUser BIT) |
| **Status** | Active |

---

## 1. Business Meaning

Trade.IsUsUser is a critical classification function used across the Trade schema to determine if a customer should be treated as a US user. US customers are subject to different regulatory rules (e.g., no CFDs, different leverage limits, specific tax reporting requirements). This function is called by many position lifecycle procedures (open, close, edit SL, dividend processing, position splitting, reopen validation) to apply US-specific logic.

The function performs a **dual check**: the customer must BOTH have a US-linked regulation AND belong to CountryGroupID = 4 (US country group). Having only one of these conditions is insufficient.

---

## 2. Business Logic

### 2.1 US User Classification

**What**: Determines US user status via regulation + country group.

**Parameters**: `@CID INT` - Customer ID

**Rules**:
1. Query `Customer.CustomerStatic` and `BackOffice.Customer` for the given CID
2. Determine effective regulation: `ISNULL(bc.DesignatedRegulationID, bc.RegulationID)` -- DesignatedRegulationID takes priority, falls back to RegulationID
3. LEFT JOIN to `Trade.vGetUsRegulationIds` to check if the effective regulation is a US regulation
4. OUTER APPLY to `Dictionary.CountryToCountryGroup` to check if the customer's CountryID belongs to CountryGroupID = 4
5. **Result**: IsUsUser = 1 only when BOTH conditions are met:
   - `usReg.ID IS NOT NULL` (regulation is US-linked)
   - `cg.CountryGroupID = 4` (country is in the US group)

### 2.2 Regulation Priority

**What**: DesignatedRegulationID overrides RegulationID.

**Rules**:
- `ISNULL(bc.DesignatedRegulationID, bc.RegulationID)` ensures that if a customer has been specifically designated to a regulation, that takes precedence over the default system-assigned regulation

---

## 3. Data Overview

Returns a single row with a single BIT column (IsUsUser: 0 or 1) for any valid CID.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IsUsUser | bit | NO | 0 | CODE-BACKED | 1 if customer has US regulation AND US country group, 0 otherwise. |

### 4.1 Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CID | int | Customer ID to evaluate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| cc | Customer.CustomerStatic | INNER JOIN (NOLOCK) | Customer country info |
| bc | BackOffice.Customer | INNER JOIN (NOLOCK) | Customer regulation info |
| usReg | Trade.vGetUsRegulationIds | LEFT JOIN | US regulation ID lookup |
| cg | Dictionary.CountryToCountryGroup | OUTER APPLY (TOP 1) | Country group membership |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Trade.DailyDigest | Stored Procedure | US user filtering for daily digest |
| Trade.AlertForOrphanedPositions | Stored Procedure | US-specific orphan position detection |
| Trade.ChangeIsSettledForASYCUsers | Stored Procedure | Settlement type changes for US |
| Trade.GetPositionsForDividendSnapshot | Stored Procedure | Dividend eligibility by jurisdiction |
| Trade.PositionCloseWithTimeout | Stored Procedure | Close logic branching for US |
| Trade.PositionEditSLWithTimeout | Stored Procedure | SL edit rules for US |
| Trade.PositionOpenWithTimeout | Stored Procedure | Open position rules for US |
| Trade.PositionsIsUS | Stored Procedure | Batch US classification |
| Trade.SplitOpenPositions | Stored Procedure | Stock split handling for US |
| Trade.ReopenOperationValidation | Stored Procedure | Reopen validation for US |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsUsUser (function)
+-- Customer.CustomerStatic (table) [cross-schema]
+-- BackOffice.Customer (table) [cross-schema]
+-- Trade.vGetUsRegulationIds (view)
+-- Dictionary.CountryToCountryGroup (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | INNER JOIN - CountryID |
| BackOffice.Customer | Table | INNER JOIN - RegulationID, DesignatedRegulationID |
| Trade.vGetUsRegulationIds | View | LEFT JOIN - US regulation list |
| Dictionary.CountryToCountryGroup | Table | OUTER APPLY - CountryGroupID=4 check |

### 6.2 Objects That Depend On This

10 stored procedures across position lifecycle operations.

---

## 7. Technical Details

### 7.1 Function Type

Inline TVF (RETURNS TABLE AS RETURN SELECT...) -- the optimizer can inline this into calling queries for efficient execution. No multi-statement overhead.

### 7.2 NOLOCK Hints

Applied to Customer.CustomerStatic and BackOffice.Customer to avoid locking contention, since this function is called within high-frequency position operations.

---

## 8. Sample Queries

### 8.1 Check if a customer is US
```sql
SELECT  IsUsUser
FROM    Trade.IsUsUser(12345);
```

### 8.2 Use in a position query
```sql
SELECT  p.PositionID, p.CID, us.IsUsUser
FROM    Trade.PositionTbl p WITH (NOLOCK)
        CROSS APPLY Trade.IsUsUser(p.CID) us
WHERE   p.StatusID = 1 AND us.IsUsUser = 1;
```

### 8.3 Bulk check for multiple customers
```sql
SELECT  DISTINCT c.CID, us.IsUsUser
FROM    Customer.Customer c WITH (NOLOCK)
        CROSS APPLY Trade.IsUsUser(c.CID) us
WHERE   c.CID IN (100, 200, 300);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Core regulatory classification function.

---

*Generated: 2026-03-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 referencing | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsUsUser | Type: Function | Source: etoro/etoro/Trade/Functions/Trade.IsUsUser.sql*
