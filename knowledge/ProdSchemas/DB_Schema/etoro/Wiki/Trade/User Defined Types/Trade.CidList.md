# Trade.CidList

> A table-valued parameter type for passing batches of Customer IDs (CIDs) to stored procedures, enabling bulk customer-level operations across the Trade platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.CidList is a table-valued parameter (TVP) type purpose-built for passing sets of Customer IDs (CIDs) into stored procedures. CID is the primary customer identifier across the eToro platform - an integer that uniquely identifies each trading account. This type enables bulk customer operations without row-by-row processing.

This type is critical for operations that act on groups of customers simultaneously: applying or removing trading restrictions, calculating interest across multiple accounts, fetching customer data for compliance reporting, and managing copy-trade relationships. Without it, each customer would need a separate procedure call.

Application services and jobs collect CID lists from various sources - compliance screens, batch job schedules, fund management systems - populate a CidList, and pass it to the relevant procedure. The procedure JOINs against the TVP to filter its working set to only the specified customers.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type specialized for the CID domain.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID - the primary account identifier across the eToro platform. Each CID maps to one trading account. Used across all customer-level operations: restrictions management, interest calculation, copy-trade queries, portfolio data retrieval, and compliance reporting. No primary key constraint, so a CID could theoretically appear twice (though consuming procedures typically use DISTINCT or JOIN semantics that handle this). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID semantically references Customer.CustomerTbl but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CustomerRestrictionSet_CIDs | @CIDs | Parameter (TVP) | Bulk-applies trading restrictions to a set of customers |
| Trade.CustomerRestrictionRemove_CIDs | @CIDs | Parameter (TVP) | Bulk-removes trading restrictions from a set of customers |
| Trade.CustomerRestrictionCIDs_Wrapper | @CIDs | Parameter (TVP) | Wrapper for customer restriction operations |
| Trade.CustomerRestrictionCIDs_Wrapper_MainJOB | @CIDs | Parameter (TVP) | Main job wrapper for customer restriction operations |
| Trade.GetActiveCopiersForParents | @ParentCIDs | Parameter (TVP) | Retrieves active copy-trade followers for a set of leader accounts |
| Trade.InterestGetDailyRawData | @CIDs | Parameter (TVP) | Fetches daily interest calculation data for specified customers |
| Trade.InterestGetDailyRawDataHistorical | @CIDs | Parameter (TVP) | Fetches historical interest data for specified customers |
| Trade.InterestGetDailyRawDataTest | @CIDs | Parameter (TVP) | Test version of daily interest data retrieval |
| Trade.InterestGetDailyRawDataNEWELAD | @CIDs | Parameter (TVP) | Development version of daily interest data retrieval |
| Trade.GetCustomersDataWithRestirctions | @CIDs | Parameter (TVP) | Fetches customer data with restriction flags for a batch |
| Trade.GetCustomersDataWithCopyRestirctions | @CIDs | Parameter (TVP) | Fetches customer data with copy-trade restriction flags |
| Trade.GetCustomersRestrictionsByTypesForAPI | @CIDs | Parameter (TVP) | Returns restriction details by type for API consumption |
| Trade.GetFundCidsBulk | @CIDs | Parameter (TVP) | Retrieves fund-associated CIDs in bulk |
| Trade.GetUserInfoByGCIDs | @CIDs | Parameter (TVP) | Fetches user info by GCID-mapped CIDs |
| Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount | @CIDs | Parameter (TVP) | Counts closed positions per CID for TAPI |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CustomerRestrictionSet_CIDs | Stored Procedure | READONLY parameter for bulk restriction application |
| Trade.CustomerRestrictionRemove_CIDs | Stored Procedure | READONLY parameter for bulk restriction removal |
| Trade.CustomerRestrictionCIDs_Wrapper | Stored Procedure | READONLY parameter for restriction wrapper |
| Trade.CustomerRestrictionCIDs_Wrapper_MainJOB | Stored Procedure | READONLY parameter for restriction job |
| Trade.GetActiveCopiersForParents | Stored Procedure | READONLY parameter for copy-trade leader lookup |
| Trade.InterestGetDailyRawData | Stored Procedure | READONLY parameter for interest calculation |
| Trade.InterestGetDailyRawDataHistorical | Stored Procedure | READONLY parameter for historical interest |
| Trade.GetCustomersDataWithRestirctions | Stored Procedure | READONLY parameter for customer data retrieval |
| Trade.GetCustomersDataWithCopyRestirctions | Stored Procedure | READONLY parameter for copy restriction data |
| Trade.GetCustomersRestrictionsByTypesForAPI | Stored Procedure | READONLY parameter for API restriction data |
| Trade.GetFundCidsBulk | Stored Procedure | READONLY parameter for fund CID lookup |
| Trade.GetUserInfoByGCIDs | Stored Procedure | READONLY parameter for user info lookup |
| Trade.TAPI_GetPrivateUsersHistoryClosedPositionsCount | Stored Procedure | READONLY parameter for TAPI position counts |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate a CidList for restriction operations

```sql
DECLARE @CIDs Trade.CidList;
INSERT INTO @CIDs (CID) VALUES (12345), (67890), (11111);
EXEC Trade.CustomerRestrictionSet_CIDs @CIDs = @CIDs, @RestrictionTypeID = 3;
```

### 8.2 Use CidList to fetch daily interest data for specific customers

```sql
DECLARE @CustomerIDs Trade.CidList;
INSERT INTO @CustomerIDs (CID)
SELECT  DISTINCT CID
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   IsReal = 1 AND OpenDateTime > DATEADD(DAY, -7, GETUTCDATE());

EXEC Trade.InterestGetDailyRawData @CIDs = @CustomerIDs;
```

### 8.3 Use CidList to get active copiers for a set of leader accounts

```sql
DECLARE @Leaders Trade.CidList;
INSERT INTO @Leaders (CID) VALUES (50001), (50002);
EXEC Trade.GetActiveCopiersForParents @ParentCIDs = @Leaders;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CidList | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CidList.sql*
