# Trade.GetCustomerRealPositionsData

> Checks whether a set of customers (by GCID and country) have any real-stock (non-CFD) open positions, grouped by instrument type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCIDs + @CountryIDs (customer filter via TVPs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCustomerRealPositionsData determines which customers have real stock positions (actual share ownership, not CFD) currently open, grouped by instrument type (stocks, indices, crypto, etc.). It takes two table-valued parameters - a list of Global Customer IDs (GCIDs) and a list of Country IDs - and returns one row per CID/InstrumentTypeID combination where at least one real position exists.

This procedure exists to support compliance or regulatory workflows that need to know whether specific customers in specific countries hold real stock positions. Real positions (IsSettled=1) carry different regulatory treatment than CFD positions - for example, real stock owners have shareholder rights and different tax obligations. The procedure answers: "Do these customers own actual shares, and in which asset classes?"

Data flows through the RealCustomersDemoLSRealLocal synonym (pointing to Customer.Customer) joined with the @GCIDs TVP on GCID, filtered by @CountryIDs on CountryID. Open positions come from the RealOpenPositions synonym (pointing to Trade.PositionTbl with StatusID=1 filter). Trade.InstrumentMetaData provides the InstrumentTypeID classification. The IsSettled=1 filter restricts to real stock positions only.

---

## 2. Business Logic

### 2.1 Real Position Detection

**What**: Identifies customers who own actual shares (real stock positions) vs those who only have CFD exposure.

**Columns/Parameters Involved**: `IsSettled`, `InstrumentTypeID`, `@GCIDs`, `@CountryIDs`

**Rules**:
- IsSettled = 1 filters to real stock positions only (customer owns actual shares). IsSettled = 0 would be CFD positions (excluded).
- Results are grouped by InstrumentTypeID and CID, producing one flag row per asset class where the customer holds real positions.
- The constant `1 AS IsExists` serves as a boolean existence flag - the procedure only reports presence, not counts or amounts.
- Country filtering via @CountryIDs enables jurisdiction-specific queries (e.g., US-regulated customers only).

**Diagram**:
```
@GCIDs (GCID list) --> Customer.Customer (via synonym)
  |                          |
  +-- Filter: CountryID IN @CountryIDs
  |
  +-- LEFT JOIN RealOpenPositions (open positions)
  |     |
  |     +-- Filter: IsSettled = 1 (real stock only)
  |     |
  |     +-- JOIN InstrumentMetaData -> InstrumentTypeID
  |
  +-- GROUP BY CID, InstrumentTypeID
  |
  +-- Output: CID, InstrumentTypeID, IsExists=1
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCIDs | dbo.IdIntList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing Global Customer IDs to check. Joined to RealCustomersDemoLSRealLocal.GCID. |
| 2 | @CountryIDs | dbo.IdIntList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing Country IDs to filter customers by jurisdiction. Joined to RealCustomersDemoLSRealLocal.CountryID. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID from Customer.Customer (via synonym). Identifies which customer has real positions. |
| 2 | InstrumentTypeID | int | YES | - | CODE-BACKED | Asset class of the real positions. FK to Dictionary.InstrumentType (4=Index, 5=Stock, etc.). From Trade.InstrumentMetaData. |
| 3 | IsExists | int | NO | - | CODE-BACKED | Constant 1 - existence flag indicating the customer has at least one real position in this instrument type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| customer.* | RealCustomersDemoLSRealLocal (synonym -> Customer.Customer) | FROM | Customer base filtered by GCID and Country |
| pt.* | RealOpenPositions (synonym -> Trade.PositionTbl, StatusID=1) | LEFT JOIN | Open positions for the customer |
| i.InstrumentTypeID | Trade.InstrumentMetaData | JOIN | Instrument type classification for the position's instrument |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomerRealPositionsData (procedure)
+-- RealCustomersDemoLSRealLocal (synonym -> Customer.Customer) (table)
+-- RealOpenPositions (synonym -> Trade.PositionTbl) (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RealCustomersDemoLSRealLocal | Synonym (Customer.Customer) | FROM - customer lookup by GCID |
| RealOpenPositions | Synonym (Trade.PositionTbl) | LEFT JOIN - open positions lookup |
| Trade.InstrumentMetaData | Table | JOIN - instrument type classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers discovered |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute with a set of GCIDs and country IDs

```sql
DECLARE @GCIDs dbo.IdIntList;
DECLARE @CountryIDs dbo.IdIntList;
INSERT INTO @GCIDs (ID) VALUES (100001), (100002), (100003);
INSERT INTO @CountryIDs (ID) VALUES (1), (44), (81);
EXEC Trade.GetCustomerRealPositionsData @GCIDs, @CountryIDs;
```

### 8.2 Check real positions for a single GCID across all countries

```sql
DECLARE @GCIDs dbo.IdIntList;
DECLARE @CountryIDs dbo.IdIntList;
INSERT INTO @GCIDs (ID) VALUES (100001);
INSERT INTO @CountryIDs (ID) SELECT CountryID FROM Dictionary.Country WITH (NOLOCK);
EXEC Trade.GetCustomerRealPositionsData @GCIDs, @CountryIDs;
```

### 8.3 Inline equivalent with instrument type names

```sql
SELECT  c.CID, it.Name AS InstrumentType, 1 AS IsExists
FROM    Customer.Customer c WITH (NOLOCK)
INNER JOIN Trade.PositionTbl pt WITH (NOLOCK) ON c.CID = pt.CID AND pt.StatusID = 1
INNER JOIN Trade.InstrumentMetaData i WITH (NOLOCK) ON pt.InstrumentID = i.InstrumentID
INNER JOIN Dictionary.InstrumentType it WITH (NOLOCK) ON i.InstrumentTypeID = it.InstrumentTypeID
WHERE   pt.IsSettled = 1
        AND c.GCID IN (100001, 100002)
GROUP BY c.CID, it.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomerRealPositionsData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomerRealPositionsData.sql*
