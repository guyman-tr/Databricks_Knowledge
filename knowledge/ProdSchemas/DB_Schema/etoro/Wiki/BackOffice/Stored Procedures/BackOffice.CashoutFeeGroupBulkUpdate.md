# BackOffice.CashoutFeeGroupBulkUpdate

> Bulk-updates CashoutFeeGroupID on BackOffice.Customer for a batch of customers and returns any CIDs that could not be updated (customer not found).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @tbl (TVP of CID + CashoutFeeGroupID pairs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure applies bulk cashout fee group assignments to customers. It accepts a table-valued parameter containing one row per customer (CID + new CashoutFeeGroupID), performs an UPDATE on `BackOffice.Customer.CashoutFeeGroupID` for all matching CIDs, and returns the rows that were NOT updated - specifically the CIDs that had no matching record in `BackOffice.Customer`.

Cashout fee groups control what fee rate is applied when a customer withdraws (cashouts) funds. Different customer tiers pay different rates: standard users pay the Default fee, Popular Investors (high Guru Status) may be Exempt, and intermediate tiers exist in between. The fee group for each customer is computed by the caller (service layer) based on Club Group and Guru Status, using the "higher wins" rule (the more-exempt fee group takes precedence when both apply).

Data flows in from the cashout fee group assignment service, triggered by Player Level or Guru Status change events. The service computes the new `CashoutFeeGroupID` for each affected customer, populates a `BackOffice.TBL_CashoutFeeGroup` TVP, and calls this procedure. The procedure returns unmatched CIDs so the caller can handle or log failures (e.g., customer exists in the event queue but not yet in BackOffice.Customer).

---

## 2. Business Logic

### 2.1 Bulk Update with Failure Detection

**What**: Uses an OUTPUT clause to capture successfully updated CIDs, then anti-joins against the input to identify failures.

**Columns/Parameters Involved**: `@tbl.CID`, `@tbl.CashoutFeeGroupID`, `@Updated` (internal table variable)

**Rules**:
- UPDATE joins `BackOffice.Customer` to `@tbl` on CID, sets `CashoutFeeGroupID = t.CashoutFeeGroupID`
- OUTPUT Inserted.CID captures each successfully updated CID into `@Updated`
- Final SELECT: `LEFT JOIN @Updated u ON u.CID = t.CID WHERE u.CID IS NULL` returns rows from @tbl that had no matching CID in BackOffice.Customer
- Returns empty result set when all rows updated successfully
- Returns unmatched rows when any CID not found in BackOffice.Customer

**Diagram**:
```
@tbl (TVP input):                 BackOffice.Customer:
  CID=100, CashoutFeeGroupID=3      CID=100  -> EXISTS   -> UPDATED -> not in result
  CID=200, CashoutFeeGroupID=1      CID=200  -> EXISTS   -> UPDATED -> not in result
  CID=999, CashoutFeeGroupID=2      CID=999  -> MISSING  -> no update -> RETURNED in result

Result set: (CID=999, CashoutFeeGroupID=2) <- failure row for caller to handle
```

### 2.2 Cashout Fee Group Business Rules

**What**: The fee group values in @tbl are pre-computed by the service layer using the "higher wins" rule.

**Columns/Parameters Involved**: `CashoutFeeGroupID`

**Rules**:
- CashoutFeeGroupID is determined by the higher of: Club Group tier fee group vs Guru Status fee group
- "Higher" = more exempt from fees
- Service layer computes this before calling the SP; SP only applies the pre-computed value
- CashoutFeeGroupID values (from Confluence): Default (standard fee), Exempt (no fee), with possible intermediate tiers
- Per `BackOffice.TBL_CashoutFeeGroup` doc: maps to `Dictionary.CashoutFeeGroup`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @tbl | BackOffice.TBL_CashoutFeeGroup READONLY | NO | - | CODE-BACKED | Table-Valued Parameter containing one row per customer to update. Schema: CID INT NOT NULL, CashoutFeeGroupID INT NOT NULL. READONLY - no modification of input allowed. |

**Result Set - Failed Rows (customers not found in BackOffice.Customer):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID from the input @tbl row that could not be matched to a record in BackOffice.Customer. Caller should log or retry these. |
| 3 | CashoutFeeGroupID | INT | NO | - | CODE-BACKED | The CashoutFeeGroupID that was intended for this CID but could not be applied because the customer was not found. |

Note: Result set is empty when all input CIDs were found and updated successfully.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @tbl.CID | BackOffice.Customer | UPDATE (JOIN) | Updates CashoutFeeGroupID on the matching customer record |
| @tbl | BackOffice.TBL_CashoutFeeGroup | TVP Schema | Input parameter type - defines the CID + CashoutFeeGroupID structure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Cashout fee group assignment service | External | Direct call | Triggered by Player Level or Guru Status change events to bulk-apply new fee groups |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CashoutFeeGroupBulkUpdate (procedure)
|- BackOffice.Customer (table) [UPDATE target - CashoutFeeGroupID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE target: sets CashoutFeeGroupID for matching CIDs |
| BackOffice.TBL_CashoutFeeGroup | User Defined Type | Input parameter schema definition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Cashout fee group assignment service | External | Calls this SP when customer tier changes require fee group updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @tbl READONLY | Parameter | TVP cannot be modified inside the procedure |
| OUTPUT clause | Design | Tracks updated CIDs for anti-join failure detection |
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| No transaction | Design | No explicit transaction wrapper - single UPDATE statement is implicitly atomic for each row |

---

## 8. Sample Queries

### 8.1 Bulk update cashout fee groups and check for failures

```sql
DECLARE @assignments BackOffice.TBL_CashoutFeeGroup;
INSERT INTO @assignments (CID, CashoutFeeGroupID)
VALUES (12345, 3), (67890, 1), (11111, 2);

EXEC BackOffice.CashoutFeeGroupBulkUpdate @tbl = @assignments;
-- Empty result = all updated successfully
-- Non-empty result = CIDs not found in BackOffice.Customer
```

### 8.2 Inspect current cashout fee group assignments

```sql
SELECT bc.CID, bc.CashoutFeeGroupID, bc.GuruStatusID, bc.PlayerLevelID
FROM BackOffice.Customer bc WITH (NOLOCK)
WHERE bc.CashoutFeeGroupID IS NOT NULL
ORDER BY bc.CashoutFeeGroupID, bc.CID
```

### 8.3 Verify CashoutFeeGroupID values available

```sql
SELECT CashoutFeeGroupID, Name
FROM Dictionary.CashoutFeeGroup WITH (NOLOCK)
ORDER BY CashoutFeeGroupID
-- Shows valid fee group values that can be passed in @tbl
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Cashout Fee Groups Auto Assignment Design](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1242726429) | Confluence | Full business design: fee groups auto-assigned based on Club Group and Guru Status; higher (more exempt) fee group wins; related service and mapping tables described |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CashoutFeeGroupBulkUpdate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CashoutFeeGroupBulkUpdate.sql*
