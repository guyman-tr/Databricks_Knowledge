# Trade.CM_GetLeveragesRestrictionsWhiteList

> Retrieves leverage restriction whitelist entries for specified customers (by CID list or username list), including resolved leverage IDs and instrument metadata.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set: whitelist entries with leverage details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CM_GetLeveragesRestrictionsWhiteList is a read-only query used by Customer Management (CM) tools to display which customers have custom leverage limits. Operations staff can look up whitelist entries by customer ID (GCID) or by username, seeing the minimum, maximum, and default leverage allowed for each instrument.

The leverage whitelist system allows specific customers to trade with leverage limits that differ from the platform defaults. For example, a customer might be allowed higher leverage on certain instruments after a risk assessment, or restricted to lower leverage after a compliance review.

The procedure resolves raw leverage values (e.g., 2, 5, 10) back to their Dictionary.Leverage IDs for use by the admin UI. It also enriches the output with the customer's username and the instrument type.

---

## 2. Business Logic

### 2.1 Dual Input Resolution (CID + Username)

**What**: Accepts customers via CID list OR username list and merges them.

**Columns/Parameters Involved**: `@GCIDsListTable`, `@UsersNames`

**Rules**:
- @GCIDsListTable provides direct GCID lookups
- @UsersNames are resolved to GCIDs via Customer.CustomerStatic (UserName_LOWER = LOWER(UserName))
- Results are UNIONed to eliminate duplicates
- If a customer appears in both lists, they appear once in the output

### 2.2 Leverage ID Resolution

**What**: Maps raw leverage values to Dictionary.Leverage IDs.

**Rules**:
- MinLeverage, MaxLeverage, DefaultLeverage are stored as numeric values
- Subqueries resolve each to their LeverageID from Dictionary.Leverage
- Used by the admin UI which operates on LeverageIDs, not raw values

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCIDsListTable | Trade.CidList (TVP, READONLY) | NO | - | CODE-BACKED | List of customer GCIDs to look up leverage whitelist entries for. |
| 2 | @UsersNames | dbo.Typ_UserName (TVP, READONLY) | NO | - | CODE-BACKED | List of usernames to resolve to GCIDs and look up leverage whitelist entries for. Resolved via Customer.CustomerStatic.UserName_LOWER. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | GCID | INT | NO | - | CODE-BACKED | Customer's global CID from the whitelist entry. |
| 4 | UserName | NVARCHAR | NO | - | CODE-BACKED | Customer's username resolved from Customer.Customer. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument with custom leverage limits. FK to Trade.GetInstrument. |
| 6 | InstrumentTypeID | INT | NO | - | CODE-BACKED | Type of the instrument (Stocks, ETF, Crypto, etc.). From Trade.GetInstrument. |
| 7 | MinLeverage | INT | YES | - | CODE-BACKED | Minimum allowed leverage for this customer/instrument. |
| 8 | MaxLeverage | INT | YES | - | CODE-BACKED | Maximum allowed leverage for this customer/instrument. |
| 9 | DefaultLeverage | INT | YES | - | CODE-BACKED | Default leverage applied when the customer doesn't specify. |
| 10 | Comments | NVARCHAR | YES | '' | CODE-BACKED | Administrative notes about why this whitelist entry exists. |
| 11 | LastUpdateDate | DATETIME | YES | - | CODE-BACKED | When this whitelist entry was last modified. |
| 12 | MinLeverageID | INT | YES | - | CODE-BACKED | Dictionary.Leverage ID corresponding to MinLeverage value. |
| 13 | MaxLeverageID | INT | YES | - | CODE-BACKED | Dictionary.Leverage ID corresponding to MaxLeverage value. |
| 14 | DefaultLeverageID | INT | YES | - | CODE-BACKED | Dictionary.Leverage ID corresponding to DefaultLeverage value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.LeveragesRestrictionsWhiteList | SELECT | Source of whitelist entries |
| JOIN | Trade.GetInstrument | SELECT | Resolves InstrumentTypeID |
| JOIN | Customer.Customer | SELECT | Resolves GCID to UserName |
| JOIN | Customer.CustomerStatic | SELECT | Resolves UserName to GCID (for @UsersNames input) |
| Subquery | Dictionary.Leverage | SELECT | Maps leverage values to LeverageIDs |
| Type | Trade.CidList | Type | UDT for CID list parameter |
| Type | dbo.Typ_UserName | Type | UDT for username list parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer Management admin tools | External | EXEC | Displays leverage whitelist entries in the CM UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CM_GetLeveragesRestrictionsWhiteList (procedure)
+-- Trade.LeveragesRestrictionsWhiteList (table)
+-- Trade.GetInstrument (view/synonym)
+-- Customer.Customer (table)
+-- Customer.CustomerStatic (table)
+-- Dictionary.Leverage (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LeveragesRestrictionsWhiteList | Table | SELECT - whitelist data source |
| Trade.GetInstrument | View/Synonym | JOIN - InstrumentTypeID resolution |
| Customer.Customer | Table | JOIN - GCID to UserName mapping |
| Customer.CustomerStatic | Table | JOIN - UserName to GCID resolution |
| Dictionary.Leverage | Table | Subquery - value to ID mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer Management admin tools | External | Reads whitelist data for display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages for cleaner output |
| ORDER BY GCID, InstrumentTypeID, InstrumentID | Sorting | Results sorted for consistent display in admin UI |

---

## 8. Sample Queries

### 8.1 Look up whitelist entries for a specific customer

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @Users dbo.Typ_UserName;
INSERT INTO @CIDs (CID) VALUES (12345);
EXEC Trade.CM_GetLeveragesRestrictionsWhiteList @GCIDsListTable = @CIDs, @UsersNames = @Users;
```

### 8.2 Look up by username

```sql
DECLARE @CIDs Trade.CidList;
DECLARE @Users dbo.Typ_UserName;
INSERT INTO @Users (UserName) VALUES ('john_doe');
EXEC Trade.CM_GetLeveragesRestrictionsWhiteList @GCIDsListTable = @CIDs, @UsersNames = @Users;
```

### 8.3 View all leverage dictionary values

```sql
SELECT  LeverageID, Value
FROM    Dictionary.Leverage WITH (NOLOCK)
ORDER BY Value;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CM_GetLeveragesRestrictionsWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CM_GetLeveragesRestrictionsWhiteList.sql*
