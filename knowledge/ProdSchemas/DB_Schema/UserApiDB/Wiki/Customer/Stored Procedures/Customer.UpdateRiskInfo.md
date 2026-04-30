# Customer.UpdateRiskInfo

> Updates risk/compliance fields in Customer.RiskUserInfo (new-style) with session context - also inserts EV results into Ev.CustomerResult when provided. Returns SELECT 1 on success.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Customer.RiskUserInfo + optional INSERT Ev.CustomerResult |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateRiskInfo is the new-style risk data update procedure. It updates all risk/compliance fields in Customer.RiskUserInfo (regulation, verification, player status, regulatory categorizations, trading risk) with session context for audit trail. If EV (electronic verification) results are provided (@EvStatusId and @EvProviderId both non-NULL), it also inserts a new Ev.CustomerResult record.

This is the Customer schema version. UpdateRiskUserInfo is the legacy equivalent (delegates to Real_UpdateRiskUserInfoRemote).

---

## 2. Business Logic

### 2.1 Conditional EV Result Insert

**What**: Optionally records a new electronic verification result.

**Rules**:
- If @EvStatusId IS NOT NULL AND @EvProviderId IS NOT NULL: INSERT into Ev.CustomerResult
- TransactionDate = GetDate()
- Otherwise: no EV insert (risk fields still updated)

### 2.2 Mixed NULL Handling

**What**: Some fields use ISNULL (preserve if NULL), others are overwritten directly.

**Rules**:
- ISNULL pattern: RegulationID, EvMatchStatus, MifidCategorizationID, DesignatedRegulationID, SeychellesCategorizationID, TradingRiskStatusID
- Direct overwrite: DocumentStatusID, PhoneVerifiedID, VerificationLevelID, SuitabilityTestStatusID, Verified, VerifiedBy, VerifiedByProvider, AsicClassificationID, PlayerStatusID (defaults to 1), PlayerStatusReasonID, PlayerStatusSubReasonID/Comment

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @regulatingEntityId | int | YES | NULL | CODE-BACKED | Regulation ID (ISNULL). |
| 3 | @documentStatusId | int | YES | NULL | CODE-BACKED | Document verification status. |
| 4 | @phoneVerificationStatusId | int | YES | NULL | CODE-BACKED | Phone verification status. |
| 5 | @verificationLevelId | int | YES | NULL | CODE-BACKED | KYC verification level. |
| 6 | @playerStatusId | int | YES | NULL | CODE-BACKED | Player status (defaults to 1 if NULL). |
| 7 | @EvStatusId | int | YES | NULL | CODE-BACKED | EV result status (triggers EV insert if non-NULL). |
| 8 | @EvProviderId | int | YES | NULL | CODE-BACKED | EV provider (triggers EV insert if non-NULL). |
| 9 | @TransactionId | varchar(50) | YES | NULL | CODE-BACKED | EV transaction ID. |
| 10 | @MifidCategorizationID | int | YES | 1 | CODE-BACKED | MiFID categorization (defaults to 1). |
| 11 | @DesignatedRegulationID | int | YES | NULL | CODE-BACKED | Designated regulation override (ISNULL). |
| 12 | @TradingRiskStatusID | int | YES | NULL | CODE-BACKED | Trading risk status (ISNULL). |
| 13 | @correlationId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail. |
| 14-28 | (remaining params) | Various | YES | - | CODE-BACKED | SuitabilityTestStatus, isVerified, VerifiedBy/Provider, playerStatusReason, EvMatchStatus, PlayerStatusSubReason/Comment, AsicClassification, SeychellesCategorization, VerificationType, countryByIp (unused). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.RiskUserInfo | UPDATE | Risk data (new schema) |
| @EvStatusId | Ev.CustomerResult | INSERT (conditional) | EV verification result |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Risk updates (new path) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateRiskInfo (procedure)
+-- Customer.RiskUserInfo (table)
+-- Ev.CustomerResult (table, conditional)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo | Table | UPDATE |
| Ev.CustomerResult | Table | INSERT (conditional) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Application (new path) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | Standard error logging and re-throw |

---

## 8. Sample Queries

### 8.1 Update risk info
```sql
EXEC Customer.UpdateRiskInfo @gcid=12345, @verificationLevelId=3, @playerStatusId=1,
    @correlationId='abc', @requestTime=GETUTCDATE()
```

### 8.2 Update with EV result
```sql
EXEC Customer.UpdateRiskInfo @gcid=12345, @verificationLevelId=3,
    @EvStatusId=1, @EvProviderId=2, @TransactionId='EV-123'
```

### 8.3 Compare with legacy
```sql
-- UpdateRiskInfo: Customer.RiskUserInfo (new, with session context)
-- UpdateRiskUserInfo: dbo.Real_UpdateRiskUserInfoRemote (legacy, with async designated reg queue)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateRiskInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateRiskInfo.sql*
