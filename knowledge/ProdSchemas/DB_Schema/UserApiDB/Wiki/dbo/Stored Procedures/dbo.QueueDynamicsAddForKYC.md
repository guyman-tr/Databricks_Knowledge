# dbo.QueueDynamicsAddForKYC

> Wrapper procedure that forwards KYC document queue requests to the Real_QueueDynamicsAddForKYC synonym (external database).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FilePath (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.QueueDynamicsAddForKYC is a thin wrapper that calls the Real_QueueDynamicsAddForKYC synonym, which points to an external database procedure for queuing KYC document processing in Dynamics CRM.

---

## 2. Business Logic

No logic. Direct EXEC passthrough to synonym.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int (IN) | NO | - | CODE-BACKED | Customer ID. |
| 2 | @FilePath | nvarchar(300) (IN) | NO | - | CODE-BACKED | Document file path. |
| 3 | @Comment | nvarchar(1000) (IN) | NO | - | CODE-BACKED | Document comment/description. |
| 4 | @ManagerID | int (IN) | YES | 0 | CODE-BACKED | Manager ID. Default: 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Real_QueueDynamicsAddForKYC | EXEC (synonym) | Forwards to external DB |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.QueueDynamicsAddForKYC (procedure)
  +-- dbo.Real_QueueDynamicsAddForKYC (synonym, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_QueueDynamicsAddForKYC | Synonym | EXEC |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Queue a KYC document
```sql
EXEC dbo.QueueDynamicsAddForKYC @CID = 12345, @FilePath = N'/docs/id_front.jpg', @Comment = N'ID front uploaded'
```

### 8.2 With manager
```sql
EXEC dbo.QueueDynamicsAddForKYC @CID = 12345, @FilePath = N'/docs/poa.pdf', @Comment = N'Proof of address', @ManagerID = 100
```

### 8.3 Direct synonym call
```sql
EXEC dbo.Real_QueueDynamicsAddForKYC @CID = 12345, @FilePath = N'/docs/id.jpg', @Comment = N'test', @ManagerID = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.QueueDynamicsAddForKYC | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.QueueDynamicsAddForKYC.sql*
