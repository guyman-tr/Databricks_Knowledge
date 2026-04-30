# Customer.RiskUserInfo (UDT)

> Table-valued parameter type for bulk updating user risk profile data including regulation, player status, verification level, and document status.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | GCID (user identifier column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.RiskUserInfo is a TVP type for passing batches of risk profile updates to bulk procedures. It carries the key compliance-related fields: regulation, document verification status, phone verification, verification level, player status (with reason and sub-reason), and copy-trading suitability test status. Used by Customer.Bulk_UpdateRiskUserInfo.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Data transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | CODE-BACKED | Global Customer ID - unique user identifier. |
| 2 | RegulatingEntityId | int | YES | - | CODE-BACKED | Regulation assignment. Maps to Dictionary.Regulation.ID. 1=CySEC, 2=FCA, 4=ASIC, etc. |
| 3 | DocumentStatus | int | YES | - | CODE-BACKED | Document verification status for the user. |
| 4 | PhoneVerificationStatus | int | YES | - | CODE-BACKED | Phone number verification status. |
| 5 | VerificationLevel | int | YES | - | CODE-BACKED | Identity verification tier. Maps to Dictionary.VerificationLevel. 0-3. |
| 6 | PlayerStatus | int | YES | - | CODE-BACKED | Account status controlling user permissions. Maps to Dictionary.PlayerStatus. 1=Normal through 15. |
| 7 | CopySuitabilityTestStatus | int | YES | - | CODE-BACKED | Status of the copy-trading suitability assessment. |
| 8 | PlayerStatusReason | int | YES | - | CODE-BACKED | Reason for current player status. Maps to Dictionary.PlayerStatusReasons. 0-42. |
| 9 | PlayerStatusSubReason | int | YES | - | CODE-BACKED | Sub-reason detail. Maps to Dictionary.PlayerStatusSubReasons. 0-79. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.Bulk_UpdateRiskUserInfo | @BulkUpdateTable parameter | Parameter Type | TVP for bulk risk info updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.Bulk_UpdateRiskUserInfo | Stored Procedure | Uses as READONLY parameter type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk player status update
```sql
DECLARE @Updates Customer.RiskUserInfo
INSERT INTO @Updates (GCID, PlayerStatus, PlayerStatusReason) VALUES (12345, 2, 10), (67890, 1, 0)
EXEC Customer.Bulk_UpdateRiskUserInfo @BulkUpdateTable = @Updates
```

### 8.2 Bulk regulation change
```sql
DECLARE @Updates Customer.RiskUserInfo
INSERT INTO @Updates (GCID, RegulatingEntityId) VALUES (12345, 1)
```

### 8.3 Inspect type structure
```sql
DECLARE @Data Customer.RiskUserInfo
INSERT INTO @Data (GCID, PlayerStatus) VALUES (1, 1)
SELECT * FROM @Data
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: Customer.RiskUserInfo | Type: User Defined Type | Source: UserApiDB/UserApiDB/Customer/User Defined Types/Customer.RiskUserInfo.sql*
