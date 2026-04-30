# AffiliateCommission.InsertCreditEventStateLog

> Logs the state of a credit event at a point in time for audit and debugging purposes, capturing the full event context or a minimal skeleton for system-level events.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into CreditEventStateLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertCreditEventStateLog records a snapshot of a credit event's processing state into an audit log table. This provides a complete history of state transitions during credit commission processing, enabling debugging and compliance auditing of the commission pipeline.

The procedure handles two cases: when a CreditID is provided, it logs the full event context (all financial and attribution fields). When CreditID is NULL, it logs a minimal skeleton with only the EventStateID, DateAdded, AdditionalData, and ServiceTypeID - used for system-level events not tied to a specific credit (e.g., pipeline start/stop, batch boundaries).

---

## 2. Business Logic

### 2.1 Dual-Mode Logging

**What**: Logs either a full credit event snapshot or a minimal system event.

**Columns/Parameters Involved**: `@CreditID`, `@EventStateID`, `@ServiceTypeID`

**Rules**:
- If @CreditID IS NULL: inserts a skeleton row with NULLs for all credit fields, only EventStateID + DateAdded + AdditionalData + ServiceTypeID are populated
- If @CreditID IS NOT NULL: inserts the full snapshot with all 22+ fields
- EventStateID identifies the state transition (e.g., received, processing, completed, failed)
- ServiceTypeID identifies which service/component logged the state

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditID | bigint (IN) | YES | NULL | CODE-BACKED | Credit being logged. NULL for system-level events. |
| 2 | @CreditDate | datetime (IN) | YES | NULL | CODE-BACKED | Credit event date. |
| 3 | @AffiliateID | int (IN) | YES | NULL | CODE-BACKED | Attributed affiliate. |
| 4 | @AffiliateCampaign | nvarchar(1024) (IN) | YES | NULL | CODE-BACKED | Campaign identifier. |
| 5 | @Amount | float (IN) | YES | NULL | CODE-BACKED | Credit amount. |
| 6 | @IsFirstDeposit | bit (IN) | YES | NULL | CODE-BACKED | First deposit flag. |
| 7 | @Type | tinyint (IN) | YES | NULL | CODE-BACKED | Credit type (maps to CreditTypeID). |
| 8 | @DownloadID | bigint (IN) | YES | NULL | CODE-BACKED | Mobile app download ID. |
| 9 | @BannerID | int (IN) | YES | NULL | CODE-BACKED | Banner/creative ID. |
| 10 | @CountryID | bigint (IN) | YES | NULL | CODE-BACKED | Customer's country. |
| 11 | @ProviderID | bigint (IN) | YES | NULL | CODE-BACKED | Current provider. |
| 12 | @RealProviderID | bigint (IN) | YES | NULL | CODE-BACKED | Actual executing provider. |
| 13 | @OriginalProviderID | bigint (IN) | YES | NULL | CODE-BACKED | Original provider. |
| 14 | @FunnelID | int (IN) | YES | NULL | CODE-BACKED | Registration funnel. |
| 15 | @LabelID | int (IN) | YES | NULL | CODE-BACKED | Label classification. |
| 16 | @PlayerLevelID | int (IN) | YES | NULL | CODE-BACKED | Player level. |
| 17 | @CID | bigint (IN) | YES | NULL | CODE-BACKED | Customer ID. |
| 18 | @OriginalCID | bigint (IN) | YES | NULL | CODE-BACKED | Original CID for legacy mapping. |
| 19 | @EventStateID | int (IN) | NO | - | CODE-BACKED | State transition identifier. Defines what happened to the credit event. |
| 20 | @DateAdded | datetime (IN) | NO | - | CODE-BACKED | When this state transition occurred. |
| 21 | @AdditionalData | nvarchar(max) (IN) | YES | NULL | CODE-BACKED | Free-form data for debugging context. |
| 22 | @ServiceTypeID | int (IN) | NO | - | CODE-BACKED | Identifies which service/component logged this state. |
| 23 | @Source | nvarchar(50) (IN) | YES | NULL | CODE-BACKED | Processing source identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditEventStateLog | WRITE (INSERT) | Appends state transition log entry |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the credit processing pipeline at each state transition.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.InsertCreditEventStateLog (procedure)
+-- AffiliateCommission.CreditEventStateLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEventStateLog | Table | INSERT (append-only log) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit processing pipeline) | External | Logs state transitions for audit |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Log a credit event state
```sql
EXEC [AffiliateCommission].[InsertCreditEventStateLog]
    @CreditID = 100, @CreditDate = '2026-04-12', @AffiliateID = 3,
    @Amount = 500.00, @IsFirstDeposit = 1, @Type = 1, @CID = 12345,
    @EventStateID = 1, @DateAdded = '2026-04-12 10:30:00',
    @ServiceTypeID = 1
```

### 8.2 View state history for a credit
```sql
SELECT EventStateID, DateAdded, ServiceTypeID, AdditionalData
FROM [AffiliateCommission].[CreditEventStateLog] WITH (NOLOCK)
WHERE CreditID = 100
ORDER BY DateAdded
```

### 8.3 Log a system-level event (no credit)
```sql
EXEC [AffiliateCommission].[InsertCreditEventStateLog]
    @EventStateID = 99, @DateAdded = '2026-04-12 00:00:00',
    @AdditionalData = 'Daily batch started', @ServiceTypeID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.InsertCreditEventStateLog | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.InsertCreditEventStateLog.sql*
