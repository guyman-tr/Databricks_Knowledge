# Billing.ACHWhiteListCID

> Whitelist of customer accounts explicitly approved for ACH (US domestic bank transfer) transactions, with a tiered approval classification.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | CID (PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR 95) |

---

## 1. Business Meaning

`Billing.ACHWhiteListCID` is a customer-level access control table for ACH funding. Each row represents a customer (CID) who has been explicitly approved to use ACH as a payment method, along with a classification (`TransactionApprovalType`) that indicates the level or tier of their ACH approval. The composite meaning is: "this customer is allowed to use ACH, and their approval tier is N."

This table exists because ACH transactions in the US carry elevated risk (chargebacks take weeks, fraud is possible via stolen bank credentials). Not every customer is eligible - only those who have been vetted and explicitly added to this whitelist. The `TransactionApprovalType` column likely governs which ACH transaction limits or processing paths apply to the customer, though its values are not referenced in any SQL stored procedure in the current codebase.

The table exists across four database objects (Billing schema and dbo schema in both etoro and tradonomi databases) but no stored procedure queries it in the SSDT repo. It may be consumed directly by an application service or the Routing Tool.

---

## 2. Business Logic

### 2.1 Tiered ACH Approval

**What**: Approved customers are assigned one of three ACH transaction tiers.

**Columns/Parameters Involved**: `CID`, `TransactionApprovalType`

**Rules**:
- The PK on CID means each customer can only hold one ACH approval tier at a time.
- `TransactionApprovalType` values: 1 (most common, 86% of entries), 2 (11%), 3 (3%).
- Higher tier numbers appear rarer - consistent with escalating privilege or limit levels.
- No SSDT stored procedure references this table - queries originate from application code or admin tools.

**Diagram**:
```
ACH Funding Request
        |
        v
Check Billing.ACHWhiteListCID WHERE CID = @CID
        |
        +-- Not found: customer NOT approved for ACH
        |
        +-- Found: customer IS approved
                |
                +-- TransactionApprovalType = 1 (Standard, 86%)
                +-- TransactionApprovalType = 2 (Enhanced, 11%)
                +-- TransactionApprovalType = 3 (Premium/Special, 3%)
```

---

## 3. Data Overview

| CID | TransactionApprovalType | Meaning |
|-----|------------------------|---------|
| 9270377 | 2 | Customer approved for ACH at tier 2 (enhanced approval). |
| 9272840 | 1 | Customer approved for ACH at standard tier 1 - the most common approval level. |
| 9278257 | 3 | Customer approved for ACH at tier 3 - rarest category, likely highest ACH privileges or limit. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier for the ACH-whitelisted customer. PK - each customer appears once at most. Implicit FK to Customer.CustomerStatic.CID. A customer's presence in this table means they are approved for ACH transactions. |
| 2 | TransactionApprovalType | int | NO | - | NAME-INFERRED | Tier or level of ACH transaction approval assigned to this customer. Observed values: 1 (standard, 86% of rows), 2 (enhanced, 11%), 3 (premium/special, 3%). No lookup table or stored procedure code was found in the SSDT repo to confirm the exact business meaning of each value. Possibly governs transaction limits, processing path, or risk tier for ACH transactions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Identifies the customer approved for ACH. No explicit FK constraint. |

### 5.2 Referenced By (other objects point to this)

No SQL stored procedures or views reference this table in the SSDT repo. Consumed by application code or admin tooling (not discoverable from repo).

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ACHWhiteListCID | CLUSTERED PK | CID ASC | - | - | Active |

FILLFACTOR=95 applied. Stored on PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ACHWhiteListCID | PRIMARY KEY | CID - ensures each customer has at most one ACH approval entry |

---

## 8. Sample Queries

### 8.1 Check if a customer is ACH-approved

```sql
SELECT CID, TransactionApprovalType
FROM [Billing].[ACHWhiteListCID] WITH (NOLOCK)
WHERE CID = @CID;
-- Returns row if approved, empty if not
```

### 8.2 Count customers by approval tier

```sql
SELECT TransactionApprovalType, COUNT(*) AS CustomerCount
FROM [Billing].[ACHWhiteListCID] WITH (NOLOCK)
GROUP BY TransactionApprovalType
ORDER BY TransactionApprovalType;
```

### 8.3 List all ACH-approved customers at tier 2 or above

```sql
SELECT CID, TransactionApprovalType
FROM [Billing].[ACHWhiteListCID] WITH (NOLOCK)
WHERE TransactionApprovalType >= 2
ORDER BY TransactionApprovalType, CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 6.0/10 (Elements: 5/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ACHWhiteListCID | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ACHWhiteListCID.sql*
