# Billing.CustomerToFunding_Get

> Retrieves the complete `Billing.CustomerToFunding` row for a specific customer-funding pair by composite PK lookup; returns all columns.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (composite PK lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_Get` is the point-lookup reader for a single row in `Billing.CustomerToFunding`. It returns all columns for a specific customer-to-payment-instrument association, allowing callers to check the current status, classification, block state, and timestamps for a particular CID+FundingID pair.

Created December 2016 by Geri Reshef (ticket 41987, "DB Instant payment phase2").

---

## 2. Business Logic

### 2.1 PK Lookup

**What**: Direct composite PK lookup returning all columns.

**Rules**:
- `WHERE CID = @CID AND FundingID = @FundingID` - uses the clustered PK (CID, FundingID) for O(1) retrieval
- Returns 0 rows if the CID+FundingID pair does not exist
- Returns 1 row if it exists
- `SELECT *` - returns all columns including IsBlocked, IsRefundExcluded, CustomerFundingStatusID, ManagerID, BlockedAt, BlockedDescription, IsVerified, BlockManagerID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID to retrieve the funding link for. Composite PK lookup component. |
| 2 | @FundingID | INT | NO | - | VERIFIED | Payment instrument ID to retrieve the link for. Composite PK lookup component. |

**Result set**: All columns from `Billing.CustomerToFunding` for the matching row. Key columns: `CID`, `FundingID`, `CustomerFundingStatusID` (0=Deactivated, 1=Active, 3=RemovedFromDeposit, 4=Extended-Active), `DepositTypeID`, `ReasonID`, `LastUsedDate`, `Occurred`, `IsBlocked`, `IsRefundExcluded`, `IsVerified`, `ManagerID`, `BlockedAt`, `BlockedDescription`, `BlockManagerID`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | Read | PK lookup of customer-funding association |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment service | @CID, @FundingID | Caller | Reads current state of a specific customer-funding link |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CustomerToFunding_Get (procedure)
+-- Billing.CustomerToFunding (table) [SELECT source]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | SELECT source - PK lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment service / admin tools | External | Point lookup of customer-funding state |

---

## 7. Technical Details

N/A for Stored Procedure. No explicit NOLOCK hint - reads at default READ COMMITTED isolation.

---

## 8. Sample Queries

### 8.1 Retrieve a customer-funding link

```sql
EXEC Billing.CustomerToFunding_Get @CID = 24186018, @FundingID = 12345
-- Returns all columns for this link, or 0 rows if not found
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_Get | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_Get.sql*
