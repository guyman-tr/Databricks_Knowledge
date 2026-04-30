# Dictionary.RedeemType

> Lookup table defining redeem (copy-fund exit) transfer types — classifying the kind of fund transfer during redemption processing. Currently empty in production.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 0 (MCP verified — empty) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.RedeemType was designed to classify the type of fund transfer during redeem (copy-fund exit) processing. The `TransferType` column would hold labels describing how funds are moved during redemption — potentially distinguishing between different transfer mechanisms (internal transfer, external payout, reinvestment, etc.).

However, the table is **currently empty in production** — no rows exist. The consuming code compensates for this: Billing.Redeem and Billing.RedeemFeeSettings both define `RedeemTypeID` with a DEFAULT of 0, and procedures filter by `RedeemTypeID = 0` or `RedeemTypeID = 1` using hard-coded values rather than joining to this table. This suggests the classification was either planned but never fully implemented, or the values are managed at the application layer rather than in the database.

Despite being empty, the table is actively referenced across 15+ Billing procedures and multiple tables — the column infrastructure is fully wired but the lookup data is absent.

---

## 2. Business Logic

### 2.1 Known RedeemTypeID Values (from code)

**What**: RedeemTypeID values used in code despite the empty lookup table.

**Columns/Parameters Involved**: `ID`, `TransferType`

**Rules**:
- **RedeemTypeID = 0**: Default value. Used in Billing.GetRedeemFeeExtendedDetails (WHERE RedeemTypeID = 0). Standard/default redeem type. Set as DEFAULT in Billing.Redeem and Billing.RedeemFeeSettings.
- **RedeemTypeID = 1**: Used in Billing.GetNFDetailsByRedeemID, Billing.GetNFTRedeemStatus, Billing.GetNFTRedeemDetailsByOperationID (WHERE RedeemTypeID = 1). Appears to represent NFT-related redemptions based on procedure naming.

### 2.2 Usage Pattern

**What**: How RedeemTypeID flows through the system.

**Columns/Parameters Involved**: `RedeemTypeID` (Billing.Redeem, Billing.RedeemFeeSettings columns)

**Rules**:
- Billing.Redeem_Add: Accepts @RedeemTypeID parameter and INSERTs it
- Billing.GetRedeemFeeSettings: Accepts @RedeemTypeID to look up fee configuration per type
- Billing.GetRedeemRecords / GetRedeemRecordsDynamic: SELECT and ORDER BY RedeemTypeID
- Billing.RedeemPayoutProcess_GetNewRecords: ORDER BY RedeemTypeID for processing priority
- No procedure currently JOINs to Dictionary.RedeemType — all use the ID directly

---

## 3. Data Overview

The table is **empty** in production (0 rows). Based on code analysis, the intended values are:

| ID (inferred) | TransferType (inferred) | Evidence |
|---|---|---|
| 0 | (Standard/Default) | DEFAULT constraint on Billing.Redeem.RedeemTypeID; WHERE RedeemTypeID = 0 in GetRedeemFeeExtendedDetails |
| 1 | (NFT/Special) | WHERE RedeemTypeID = 1 in GetNFDetailsByRedeemID, GetNFTRedeemStatus, GetNFTRedeemDetailsByOperationID |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying the redeem transfer type. Table is currently empty. Code uses values 0 (standard) and 1 (NFT-related) without joining to this lookup. Stored in Billing.Redeem.RedeemTypeID and Billing.RedeemFeeSettings.RedeemTypeID. |
| 2 | TransferType | varchar(50) | YES | - | VERIFIED | Human-readable transfer type label. Nullable. No data currently exists. Would describe the fund transfer mechanism used during redemption processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Redeem | RedeemTypeID | Implicit (column, DEFAULT 0) | Main redeem table stores type — no formal FK |
| History.Redeem | RedeemTypeID | Implicit | Historical redeem records |
| Billing.RedeemFeeSettings | RedeemTypeID | Implicit (PK member, DEFAULT 0) | Fee settings per type — no formal FK |
| History.RedeemFeeSettings | RedeemTypeID | Implicit | Historical fee settings |
| Billing.Redeem_Add | @RedeemTypeID | Parameter INSERT | Sets type at redeem creation |
| Billing.GetRedeemFeeSettings | @RedeemTypeID | Parameter WHERE | Fee lookup by type |
| Billing.GetNFDetailsByRedeemID | RedeemTypeID | WHERE = 1 | NFT redeem detail lookup |
| Billing.GetNFTRedeemStatus | RedeemTypeID | WHERE = 1 | NFT redeem status |
| Billing.GetRedeemFeeExtendedDetails | RedeemTypeID | WHERE = 0 | Standard fee details |
| Billing.GetRedeemRecords | RedeemTypeID | SELECT, ORDER BY | Redeem record listing |
| Billing.GetRedeemRecordsDynamic | RedeemTypeID | SELECT | Dynamic redeem records |
| Billing.GetRedeemProcessingDetails | RedeemTypeID | SELECT | Processing details |
| Billing.RedeemPayoutProcess_GetNewRecords | RedeemTypeID | ORDER BY | Payout processing priority |
| BackOffice.GetRedeemsInfo | RedeemTypeID | SELECT | BackOffice redeem info |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.RedeemType (table) — EMPTY
  └── column RedeemTypeID exists in Billing.Redeem, Billing.RedeemFeeSettings
  └── consumed by 15+ Billing/BackOffice procedures (no JOIN to this table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | RedeemTypeID column (DEFAULT 0) |
| Billing.RedeemFeeSettings | Table | RedeemTypeID in PK (DEFAULT 0) |
| Billing.Redeem_Add | Stored Procedure | Sets type at creation |
| Billing.GetRedeemFeeSettings | Stored Procedure | Fee lookup by type |
| Billing.GetNFDetailsByRedeemID | Stored Procedure | NFT filter (type=1) |
| Billing.GetRedeemRecords | Stored Procedure | SELECT/ORDER BY type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RedeemType | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RedeemType | PRIMARY KEY | Unique type identifier, DICTIONARY filegroup |

---

## 8. Sample Queries

### 8.1 List all redeem types (currently empty)
```sql
SELECT  ID,
        TransferType
FROM    Dictionary.RedeemType WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Count redeems by type (uses hard-coded values)
```sql
SELECT  RedeemTypeID,
        COUNT(*)            AS RedeemCount
FROM    Billing.Redeem WITH (NOLOCK)
GROUP BY RedeemTypeID
ORDER BY RedeemTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning inferred from consuming code patterns — table is empty but the column infrastructure is actively used with hard-coded values 0 and 1.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RedeemType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RedeemType.sql*
