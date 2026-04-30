# Customer.UpdateRiskUserInfo

> Legacy risk update - delegates to dbo.Real_UpdateRiskUserInfoRemote, inserts EV results, and queues async designated regulation update for demo (ActionID=12).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC Real_UpdateRiskUserInfoRemote + EV + async regulation queue |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateRiskUserInfo is the legacy version of UpdateRiskInfo. It resolves GCID to CID, delegates to Real_UpdateRiskUserInfoRemote, optionally queues an async designated regulation update for the demo environment (ActionID=12), and inserts EV results. Includes additional fields not in UpdateRiskInfo: @isCopyBlocked, @EIDStatusID, @OnboardingRiskClassificationID.

---

## 2. Business Logic

### 2.1 Async Designated Regulation Sync

**What**: Queues demo environment regulation update when DesignatedRegulationID changes.

**Rules**:
- If @DesignatedRegulationID IS NOT NULL: builds XML, INSERTs ActionID=12 into ActionsToExecute_Registration
- Demo regulation sync happens asynchronously

### 2.2 EV Result Insert

**Rules**: Same as UpdateRiskInfo - conditional INSERT into Ev.CustomerResult when both EvStatusId and EvProviderId are non-NULL.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2-24 | (Same risk params as UpdateRiskInfo) | Various | YES | - | CODE-BACKED | Regulation, doc status, phone verified, verification level, player status/reasons, EV fields, MiFID, ASIC, Seychelles, designated regulation, trading risk. |
| 25 | @isCopyBlocked | bit | YES | NULL | CODE-BACKED | Copy trading block flag (legacy-only field). |
| 26 | @EIDStatusID | int | YES | NULL | CODE-BACKED | Electronic ID status (legacy-only). |
| 27 | @OnboardingRiskClassificationID | int | YES | NULL | CODE-BACKED | Onboarding risk classification (legacy-only). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | dbo.Real_UpdateRiskUserInfoRemote | EXEC | Legacy remote update |
| EV params | Ev.CustomerResult | INSERT (conditional) | EV result |
| @DesignatedRegulationID | dbo.ActionsToExecute_Registration | INSERT (conditional) | Async demo sync (ActionID=12) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy risk updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateRiskUserInfo (procedure)
+-- dbo.Real_Customer (table, CID lookup)
+-- dbo.Real_UpdateRiskUserInfoRemote (procedure)
+-- Ev.CustomerResult (table, conditional)
+-- dbo.ActionsToExecute_Registration (table, conditional)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | SELECT - CID resolution |
| dbo.Real_UpdateRiskUserInfoRemote | Procedure | EXEC |
| Ev.CustomerResult | Table | INSERT (conditional) |
| dbo.ActionsToExecute_Registration | Table | INSERT (conditional, ActionID=12) |

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
| TRY/CATCH | Error handling | Standard error logging and re-throw |

---

## 8. Sample Queries

### 8.1 Update risk (legacy)
```sql
EXEC Customer.UpdateRiskUserInfo @gcid=12345, @verificationLevelId=3, @playerStatusId=1
```

### 8.2 Prefer new version
```sql
-- Use Customer.UpdateRiskInfo for new development
```

### 8.3 Check async queue
```sql
SELECT * FROM dbo.ActionsToExecute_Registration WITH (NOLOCK)
WHERE ActionID = 12 ORDER BY InsertedToQueue DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 27 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateRiskUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateRiskUserInfo.sql*
