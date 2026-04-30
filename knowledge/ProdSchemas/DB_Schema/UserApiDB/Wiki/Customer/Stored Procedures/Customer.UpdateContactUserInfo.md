# Customer.UpdateContactUserInfo

> Legacy contact update - delegates to dbo.Real_UpdateContactUserInfoRemote, optionally syncs email via P_UpdateEmail, and queues async demo update (ActionID=10).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC Real_UpdateContactUserInfoRemote + optional email sync + async demo queue |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateContactUserInfo is the legacy version of UpdateContactInfo. It performs three steps: (1) delegates the update to Real_UpdateContactUserInfoRemote, (2) optionally syncs the email via P_UpdateEmail (controlled by @ChangeEmailSts flag, default 0), and (3) queues an async action (ActionID=10) for demo environment sync. Includes SubRegion validation. Returns SELECT 1 for cache invalidation.

---

## 2. Business Logic

### 2.1 Three-Step Update Pipeline

**Rules**:
1. Validate SubRegion against Dictionary_SubRegion (same as UpdateContactInfo)
2. EXEC Real_UpdateContactUserInfoRemote (real account update)
3. If @email IS NOT NULL AND @ChangeEmailSts=1: EXEC P_UpdateEmail (STS email sync)
4. Build XML, INSERT into ActionsToExecute_Registration (ActionID=10) for demo sync

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2-17 | (Same contact params as UpdateContactInfo) | Various | YES | NULL | CODE-BACKED | Country, email, address, city, zip, phone fields, state, building, region, citizenship, POB, sub-region. |
| 18 | @ChangeEmailSts | bit | YES | 0 | CODE-BACKED | Controls STS email sync: 0=skip (default), 1=sync email via P_UpdateEmail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Real_UpdateContactUserInfoRemote | EXEC | Legacy update |
| @email | dbo.P_UpdateEmail | EXEC (conditional) | STS email sync |
| XML | dbo.ActionsToExecute_Registration | INSERT | Demo sync (ActionID=10) |
| @SubRegionId | dbo.Dictionary_SubRegion | Validation | Geographic check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy contact updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateContactUserInfo (procedure)
+-- dbo.Real_UpdateContactUserInfoRemote (procedure)
+-- dbo.P_UpdateEmail (procedure, conditional)
+-- dbo.ActionsToExecute_Registration (table)
+-- dbo.Dictionary_SubRegion (table, validation)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_UpdateContactUserInfoRemote | Procedure | EXEC |
| dbo.P_UpdateEmail | Procedure | EXEC (conditional) |
| dbo.ActionsToExecute_Registration | Table | INSERT |
| dbo.Dictionary_SubRegion | Table | Validation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Legacy callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR | Validation | SubRegion consistency |
| RAISERROR 50001 | Error handling | Separate error codes for real update, STS update, and demo update failures |

---

## 8. Sample Queries

### 8.1 Update contact (legacy)
```sql
EXEC Customer.UpdateContactUserInfo @gcid=12345, @countryId=234, @email='new@example.com'
```

### 8.2 Update with email sync
```sql
EXEC Customer.UpdateContactUserInfo @gcid=12345, @email='new@example.com', @ChangeEmailSts=1
```

### 8.3 Prefer new version
```sql
-- Use Customer.UpdateContactInfo for new development
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateContactUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateContactUserInfo.sql*
