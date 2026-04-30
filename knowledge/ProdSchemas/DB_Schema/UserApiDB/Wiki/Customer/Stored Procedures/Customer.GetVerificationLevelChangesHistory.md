# Customer.GetVerificationLevelChangesHistory

> Returns the history of KYC verification level changes for a customer from the temporal back-office history table.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns verification level history with validity periods |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetVerificationLevelChangesHistory retrieves the complete history of a customer's KYC verification level changes. Each row represents a historical state with ValidFrom/ValidTo timestamps. This supports compliance audit requirements and investigation of when a customer was upgraded/downgraded in verification status.

Created by Serhii Poltava (COAKVU-1358). Resolves GCID to CID via Customer.CustomerIdentification, then reads from dbo.Real_HistoryBackOfficeCustomer (the temporal history table for back-office data).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple temporal history read.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | ValidFrom (output) | datetime2 | NO | - | CODE-BACKED | Start of this verification level period. |
| 3 | ValidTo (output) | datetime2 | NO | - | CODE-BACKED | End of this verification level period. |
| 4 | VerificationLevelID (output) | int | YES | - | CODE-BACKED | KYC verification level during this period. See [Verification Level](_glossary.md#verification-level). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | SELECT | CID resolution |
| CID | dbo.Real_HistoryBackOfficeCustomer | FROM | Temporal history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Compliance audit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetVerificationLevelChangesHistory (procedure)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_HistoryBackOfficeCustomer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | SELECT - CID |
| dbo.Real_HistoryBackOfficeCustomer | Table | FROM - history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Compliance audit |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get verification history
```sql
EXEC Customer.GetVerificationLevelChangesHistory @GCID = 12345
```

### 8.2 Direct query
```sql
DECLARE @CID int
SELECT @CID = CID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = @GCID
SELECT ValidFrom, ValidTo, VerificationLevelID
FROM dbo.Real_HistoryBackOfficeCustomer WITH (NOLOCK)
WHERE CID = @CID
ORDER BY ValidFrom DESC
```

### 8.3 Find when customer reached level 3
```sql
DECLARE @CID int
SELECT @CID = CID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = @GCID
SELECT MIN(ValidFrom) AS ReachedLevel3
FROM dbo.Real_HistoryBackOfficeCustomer WITH (NOLOCK)
WHERE CID = @CID AND VerificationLevelID = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetVerificationLevelChangesHistory | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetVerificationLevelChangesHistory.sql*
