# Trade.ExcludeFeeByFundID

> Whitelist of customer IDs (CIDs) exempt from overnight/rollover fee charging, typically used for Smart Portfolio (fund) accounts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID (PK, NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

This table maintains a list of customer accounts (CIDs) that should be excluded from overnight fee processing. When a CID appears in this table, both that customer's own positions and any positions copied from them (via Smart Portfolios / CopyTrader) are excluded from fee calculations.

The table exists to support fee exemptions for fund managers or Smart Portfolio accounts. Without it, the fee processing procedures would charge overnight fees indiscriminately to all eligible positions, including those belonging to accounts that have been granted special fee-exempt status.

Rows are added by database administrators or operational processes. The table is read by three fee-processing stored procedures (GetPositionsForFeeProcess, GetPositionsForFeeBulkGeneral, GetPositionsForFeeBulkGeneral_Aus) which filter out exempt CIDs and their child positions before calculating fees. The temporal versioning and computed DbLoginName column provide a full audit trail of who added or removed exemptions and when.

---

## 2. Business Logic

### 2.1 Fee Exemption Cascade

**What**: A CID in this table exempts both the customer's direct positions AND positions that were opened by copying from that customer's Smart Portfolio.

**Columns/Parameters Involved**: `CID`

**Rules**:
- Direct exclusion: `CID NOT IN (SELECT CID FROM Trade.ExcludeFeeByFundID)` filters out the customer's own positions from fee charging
- Cascading exclusion: Positions whose ParentPositionID belongs to an excluded CID are also removed (via a temp table join on Trade.Position)
- The exemption applies to all three fee processing paths: bulk general, bulk Australia-specific, and single-position fee process

**Diagram**:
```
CID in ExcludeFeeByFundID
  |
  +-- Direct positions (CID match) --> EXCLUDED from fees
  |
  +-- Copied positions (ParentPositionID belongs to excluded CID) --> EXCLUDED from fees
```

### 2.2 Temporal Audit Trail

**What**: Every change to the exemption list is tracked via system versioning with login name capture.

**Columns/Parameters Involved**: `DbLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- The INSERT trigger forces a self-update on insert, which ensures the temporal history captures the initial row version with the correct DbLoginName
- History is stored in History.ExcludeFeeByFundID for compliance and audit purposes
- DbLoginName is computed from SUSER_NAME(), capturing the Windows/SQL login that made the change

---

## 3. Data Overview

The table is currently empty (0 rows). When populated, each row represents a single customer account that has been granted fee exemption.

| CID | DbLoginName | Meaning |
|-----|-------------|---------|
| *(empty)* | *(empty)* | No CIDs are currently exempt from fee processing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID exempt from overnight/rollover fees. References Customer.Customer. When present, the customer's positions and their copied child positions are excluded from fee processing in GetPositionsForFeeProcess, GetPositionsForFeeBulkGeneral, and GetPositionsForFeeBulkGeneral_Aus. |
| 2 | DbLoginName | AS (suser_name()) | NO | Computed | VERIFIED | Computed column capturing the Windows/SQL login name of the user who inserted or last modified the row. Provides audit trail for who granted the fee exemption. Computed: `suser_name()`. |
| 3 | SysStartTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | VERIFIED | System-managed temporal column marking when this row version became effective. Used by SYSTEM_VERSIONING to track history in History.ExcludeFeeByFundID. |
| 4 | SysEndTime | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | VERIFIED | System-managed temporal column marking when this row version was superseded. Maximum datetime value (9999-12-31) indicates the current active version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer account granted fee exemption |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForFeeProcess | CID | Read (NOT IN) | Excludes exempt CIDs from single-position fee processing |
| Trade.GetPositionsForFeeBulkGeneral | CID | Read (NOT IN) | Excludes exempt CIDs from bulk fee processing |
| Trade.GetPositionsForFeeBulkGeneral_Aus | CID | Read (NOT IN) | Excludes exempt CIDs from Australia-specific bulk fee processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForFeeProcess | Stored Procedure | Reads CID list to exclude from fee charging |
| Trade.GetPositionsForFeeBulkGeneral | Stored Procedure | Reads CID list to exclude from bulk fee charging |
| Trade.GetPositionsForFeeBulkGeneral_Aus | Stored Procedure | Reads CID list to exclude from Australia bulk fee charging |
| History.ExcludeFeeByFundID | History Table | Stores temporal history of all changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CIDFee | NC PK | CID ASC | - | - | Active (FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CIDFee | PRIMARY KEY | Ensures each CID can only appear once in the exemption list |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | Tracks row validity period via SysStartTime/SysEndTime |
| SYSTEM_VERSIONING | TEMPORAL | Enables automatic history tracking to History.ExcludeFeeByFundID |
| Tr_T_ExcludeFeeByFundID_INSERT | TRIGGER (FOR INSERT) | Self-updates the inserted row to force temporal versioning to capture the initial state with the correct DbLoginName |

---

## 8. Sample Queries

### 8.1 Check if a customer is exempt from fees
```sql
SELECT CID, DbLoginName, SysStartTime
FROM   Trade.ExcludeFeeByFundID WITH (NOLOCK)
WHERE  CID = @CID
```

### 8.2 View history of fee exemption changes
```sql
SELECT CID, DbLoginName, SysStartTime, SysEndTime
FROM   History.ExcludeFeeByFundID WITH (NOLOCK)
ORDER BY CID, SysStartTime DESC
```

### 8.3 Find all currently exempt CIDs with customer details
```sql
SELECT e.CID,
       e.DbLoginName,
       e.SysStartTime AS ExemptSince
FROM   Trade.ExcludeFeeByFundID e WITH (NOLOCK)
ORDER BY e.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExcludeFeeByFundID | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ExcludeFeeByFundID.sql*
