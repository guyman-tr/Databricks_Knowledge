# Customer.UpdateAccountInfo

> Updates account-level fields in Customer.AccountUserInfo (new-style) with session context for audit trail - supports partial updates via ISNULL pattern.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Customer.AccountUserInfo with session context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateAccountInfo updates account-level data in the normalized Customer.AccountUserInfo table. It supports partial updates - any NULL parameter is ignored (ISNULL preserves current value). The procedure sets session context (correlationId, clientRequestId, requestTime) for audit trail tracking via triggers. Returns SELECT 1 on success for cache invalidation signaling.

This is the Customer schema version. The legacy equivalent is UpdateAccountUserInfo (which delegates to dbo.Real_UpdateAccountUserInfoRemote).

---

## 2. Business Logic

### 2.1 Session Context for Audit Trail

**What**: Sets sp_set_session_context before UPDATE to enable trigger-based audit logging.

**Rules**:
- correlationId, clientRequestId, requestTime are set in session context
- History triggers on AccountUserInfo read these values to record who/when/why changes were made
- Sync triggers use these to populate PendingEntityEvents

### 2.2 Partial Update via ISNULL

**What**: Only non-NULL parameters are applied.

**Rules**:
- Each column: SET col = ISNULL(@param, col) - preserves existing value when param is NULL
- Allows updating a single field without specifying all others
- Returns SELECT 1 if @@RowCount > 0 (for UAPI cache invalidation)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @originalCid | int | YES | NULL | CODE-BACKED | Original CID. |
| 3 | @affiliateId | int | YES | NULL | CODE-BACKED | Affiliate serial ID. |
| 4 | @whiteLabelId | int | YES | NULL | CODE-BACKED | White label/brand. |
| 5 | @accountTypeId | int | YES | NULL | CODE-BACKED | Account type. |
| 6 | @tradeLevelId | int | YES | NULL | CODE-BACKED | Trading authorization level. |
| 7 | @currencyId | int | YES | NULL | CODE-BACKED | Account currency. |
| 8 | @pendingClosureStatusID | int | YES | NULL | CODE-BACKED | Pending closure status. |
| 9 | @accountStatusID | int | YES | NULL | CODE-BACKED | Account status. |
| 10 | @masterAccountCID | int | YES | NULL | CODE-BACKED | Master account for sub-accounts. |
| 11 | @managerID | int | YES | NULL | CODE-BACKED | Account manager. |
| 12 | @guruStatusID | int | YES | NULL | CODE-BACKED | Popular Investor status. |
| 13 | @KycState | int | YES | NULL | CODE-BACKED | KYC state machine value. |
| 14 | @createdOn | datetime | YES | NULL | CODE-BACKED | Registration date (not used in UPDATE - parameter exists for interface compatibility). |
| 15 | @correlationId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail: request correlation ID. |
| 16 | @clientRequestId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail: client request ID. |
| 17 | @requestTime | datetime | YES | NULL | CODE-BACKED | Audit trail: request timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.AccountUserInfo | UPDATE | Account data (new schema) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Account data updates (new path) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateAccountInfo (procedure)
+-- Customer.AccountUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.AccountUserInfo | Table | UPDATE with ISNULL pattern |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Application (new-style) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update guru status only
```sql
EXEC Customer.UpdateAccountInfo @gcid=12345, @guruStatusID=2
```

### 8.2 Update multiple fields with audit trail
```sql
EXEC Customer.UpdateAccountInfo @gcid=12345, @whiteLabelId=1, @tradeLevelId=3,
    @correlationId='abc-123', @clientRequestId='req-456', @requestTime=GETUTCDATE()
```

### 8.3 Compare with legacy
```sql
-- UpdateAccountInfo: updates Customer.AccountUserInfo directly (new)
-- UpdateAccountUserInfo: delegates to dbo.Real_UpdateAccountUserInfoRemote (legacy)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateAccountInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateAccountInfo.sql*
