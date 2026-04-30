# BackOffice.TBL_CashoutFeeGroup

> Table-valued parameter type for bulk-updating cashout fee group assignments for multiple customers in a single operation.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID + CashoutFeeGroupID (both NOT NULL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.TBL_CashoutFeeGroup` is a Table-Valued Type (TVT) that defines the schema for passing a batch of customer-to-cashout-fee-group assignments. Each row maps one customer (`CID`) to a new `CashoutFeeGroupID`, enabling a single stored procedure call to update the cashout fee group for multiple customers atomically.

Cashout Fee Groups control the fee structure applied when a customer withdraws funds (cashout). Different customer segments pay different cashout fee rates - for example, Popular Investors (high Guru Status) may be Exempt from fees, while standard users pay the Default rate. The fee group is auto-assigned based on a customer's Club Group (Player Level) and Guru Status changes, as documented in the "Cashout Fee Groups Auto Assignment Design" (Confluence MG space).

Data flows into this type from the cashout fee group assignment service (triggered by Player Level or Guru Status change events). The service computes the new `CashoutFeeGroupID` for each affected customer and bulk-passes the assignments to `BackOffice.CashoutFeeGroupBulkUpdate`, which applies the updates to `BackOffice.Customer.CashoutFeeGroupID` and returns any CIDs that failed to update.

---

## 2. Business Logic

### 2.1 Cashout Fee Group Auto-Assignment Logic

**What**: The consuming procedure applies the new fee group for each CID and returns any rows that could not be updated (e.g., customer not found in BackOffice.Customer).

**Columns/Parameters Involved**: `CID`, `CashoutFeeGroupID`

**Rules**:
- CashoutFeeGroupID is determined by the higher of: (a) the fee group mapped to the customer's Club Group tier, or (b) the fee group mapped to their Guru (Popular Investor) status.
- "Higher" means more exempt: if Club Group maps to Default but Guru Status maps to Exempt, the customer gets Exempt.
- The TVT does not enforce this logic - it's computed by the service layer before passing to the SP.
- `CashoutFeeGroupBulkUpdate` returns CIDs that were NOT updated (LEFT JOIN anti-pattern) - the caller can use this to retry failed updates.

**Diagram**:
```
Guru Status change event for CID=12345 (new GuruStatusID=5):
  Service computes: PlayerLevel -> FeeGroup A, GuruStatus -> FeeGroup C (higher)
  Selects: FeeGroup C (Exempt)

TVT row: (CID=12345, CashoutFeeGroupID=3)  <- 3 = Exempt

BackOffice.CashoutFeeGroupBulkUpdate(@tbl):
  UPDATE BackOffice.Customer
  SET CashoutFeeGroupID = 3
  WHERE CID = 12345

Returns: CIDs that were not found in BackOffice.Customer (unmatched rows)
```

---

## 3. Data Overview

N/A for User Defined Type. This is a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. Maps to BackOffice.Customer.CID. Identifies which customer's cashout fee group to update. NOT NULL. |
| 2 | CashoutFeeGroupID | int | NO | - | CODE-BACKED | The new cashout fee group to assign to this customer. Maps to BackOffice.Customer.CashoutFeeGroupID and Dictionary.CashoutFeeGroup. Determines the fee rate applied on customer withdrawals. Computed by the service as the higher of the Club Group tier fee group and the Guru Status fee group. NOT NULL. Per Confluence: typical groups include Default (standard fee), Exempt (no fee), and potentially intermediate tiers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer.CID | Implicit | Target customer record to update |
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | Implicit | The fee group classification to assign. Mapped from Billing.PlayerLevelToCashoutFeeGroup and Billing.GuruStatusToCashoutFeeGroup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CashoutFeeGroupBulkUpdate | @tbl parameter | Schema contract | Updates BackOffice.Customer.CashoutFeeGroupID for each CID row; returns unmatched CIDs via OUTPUT |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CashoutFeeGroupBulkUpdate | Stored Procedure | READONLY parameter @tbl - UPDATE JOINs BackOffice.Customer to apply CashoutFeeGroupID for each CID. Returns unmatched CIDs (those not found in BackOffice.Customer) so the caller can handle failures. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CID NOT NULL | Column constraint | Customer ID must always be provided |
| CashoutFeeGroupID NOT NULL | Column constraint | The new fee group must always be specified |

---

## 8. Sample Queries

### 8.1 Bulk update cashout fee groups for a set of customers

```sql
DECLARE @assignments BackOffice.TBL_CashoutFeeGroup;

-- Example: assign Exempt (3) to Popular Investors, Default (1) to others
INSERT INTO @assignments (CID, CashoutFeeGroupID)
VALUES (12345, 3),  -- Popular Investor -> Exempt
       (67890, 1),  -- Standard user -> Default
       (11111, 2);  -- Mid-tier -> Reduced

EXEC BackOffice.CashoutFeeGroupBulkUpdate @tbl = @assignments;
```

### 8.2 Build assignments from current Guru Status mapping

```sql
DECLARE @assignments BackOffice.TBL_CashoutFeeGroup;

INSERT INTO @assignments (CID, CashoutFeeGroupID)
SELECT bc.CID, gm.CashoutFeeGroupID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Billing.GuruStatusToCashoutFeeGroup gm WITH (NOLOCK)
    ON gm.GuruStatusID = bc.GuruStatusID
WHERE bc.GuruStatusID IS NOT NULL;

EXEC BackOffice.CashoutFeeGroupBulkUpdate @tbl = @assignments;
```

### 8.3 Inspect current cashout fee group assignments

```sql
SELECT bc.CID,
       bc.CashoutFeeGroupID,
       bc.GuruStatusID
FROM BackOffice.Customer bc WITH (NOLOCK)
WHERE bc.CashoutFeeGroupID IS NOT NULL
ORDER BY bc.CashoutFeeGroupID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Cashout Fee Groups Auto Assignment Design](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1242726429) | Confluence | Full business design: fee groups auto-assigned based on Club Group (Player Level) and Guru Status changes; higher (more exempt) fee group wins when both apply; related tables: Billing.PlayerLevelToCashoutFeeGroup, Billing.GuruStatusToCashoutFeeGroup |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.TBL_CashoutFeeGroup | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.TBL_CashoutFeeGroup.sql*
