# Customer.OTPAbusers

> Single-column blocklist of customer IDs who have abused OTP (One-Time Password) verification, stored on the DICTIONARY filegroup and not accessible in the current database environment.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | CID (int, PK) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

Customer.OTPAbusers is a simple blocklist: any CID in this table has been flagged as an OTP (One-Time Password) abuser - a customer who has attempted to misuse or bypass the OTP phone/email verification mechanism through repeated or suspicious verification attempts.

The table resides on the DICTIONARY filegroup (not MAIN or PRIMARY), which co-locates it with reference/dictionary data for read performance. This is a pattern used for frequently-read lookup tables that require fast JOIN performance.

**This table is not accessible in the current database environment** (query returns "Invalid object name"). It may be on a different filegroup not mounted in this environment, or it may be replicated to SettingsDB for distributed lookup enforcement.

When a CID exists in OTPAbusers, the OTP verification flow likely blocks further verification attempts or applies additional scrutiny. No stored procedure consumers were found in the SSDT Customer schema, suggesting this table is consumed by application-layer code or procedures in other schemas (possibly BackOffice or Trade).

---

## 2. Business Logic

### 2.1 Blocklist Pattern

**What**: Presence of CID in this table = OTP abuser flag. Single-column design for fast existence checks.

**Rules**:
- IF EXISTS (SELECT 1 FROM Customer.OTPAbusers WHERE CID = @CID): customer is flagged as OTP abuser
- CID PK ensures one row per customer (no duplicates possible)
- The table name and DICTIONARY filegroup co-location suggest it is used in high-frequency verification path lookups

---

## 3. Data Overview

*Not accessible in current database environment (DICTIONARY filegroup not mounted). Row count unknown.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID flagged as an OTP abuser. Primary key - one row per flagged customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer identity; no FK constraint |

### 5.2 Referenced By (other objects point to this)

No stored procedure consumers identified in SSDT Customer schema. Likely consumed by application-layer OTP verification code.

---

## 6. Dependencies

No dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_OTPAbusers | CLUSTERED | CID ASC | - | - | Active (when accessible) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_OTPAbusers | PRIMARY KEY | CID must be unique - one row per blocked customer |

---

## 8. Sample Queries

### 8.1 Check if a customer is an OTP abuser

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Customer.OTPAbusers WITH (NOLOCK)
    WHERE CID = @CID
) THEN 1 ELSE 0 END AS IsOTPAbuser
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 6.5/10 (Elements: 7/10, Logic: 6/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.OTPAbusers | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.OTPAbusers.sql*
