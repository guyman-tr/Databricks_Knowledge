# History.RiskUserInfo

> Audit history table storing temporal snapshots of Customer.RiskUserInfo changes (regulation, player status, verification, MiFID/ASIC classification).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CustomerVersionID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + NC on GCID,CustomerVersionID DESC) |

---

## 1. Business Meaning

History.RiskUserInfo is the most compliance-critical history table. It stores every change to a user's regulatory profile: regulation assignment, player status (with reason/sub-reason), verification level, MiFID/ASIC/Seychelles classification, document status, and trading risk status. Essential for compliance auditing and regulatory inquiries.

---

## 2. Business Logic

Same temporal snapshot pattern. Populated by INSERT and UPDATE triggers on Customer.RiskUserInfo (both ENABLED).

---

## 3. Data Overview

N/A - large audit history table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerVersionID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Version identifier. |
| 2 | ValidFrom | datetime | NO | - | CODE-BACKED | Version start. |
| 3 | ValidTo | datetime | NO | - | CODE-BACKED | Version end. '3000-01-01' = current. |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 5 | RegulationID | int | NO | - | CODE-BACKED | Regulation at this point. See [Regulation](_glossary.md#regulation). |
| 6 | PlayerStatusID | int | NO | - | CODE-BACKED | Account status at this point. See [Player Status](_glossary.md#player-status). |
| 7 | VerificationLevelID | int | NO | - | CODE-BACKED | Verification tier at this point. |
| 8 | DocumentStatusID | int | YES | - | CODE-BACKED | Document verification status at this point. |
| 9 | PhoneVerifiedID | int | YES | - | CODE-BACKED | Phone verification status at this point. |
| 10 | SuitabilityTestStatusID | int | YES | - | CODE-BACKED | Copy-trading suitability test status at this point. |
| 11 | EvMatchStatus | int | YES | - | CODE-BACKED | EV match result at this point. |
| 12 | DesignatedRegulationID | int | YES | - | CODE-BACKED | Override regulation at this point. |
| 13 | MifidCategorizationID | int | NO | - | CODE-BACKED | MiFID classification at this point. See [MiFID Categorization](_glossary.md#mifid-categorization). |
| 14 | AsicClassificationID | int | YES | - | CODE-BACKED | ASIC classification at this point. |
| 15 | Verified | bit | NO | - | CODE-BACKED | Whether identity was verified at this point. |
| 16 | VerifiedBy | int | YES | - | CODE-BACKED | Who verified (agent CID or NULL for system). |
| 17 | VerifiedByProvider | int | YES | - | CODE-BACKED | EV provider that verified. |
| 18 | PlayerStatusReasonID | int | YES | - | CODE-BACKED | Status change reason at this point. See [Player Status Reason](_glossary.md#player-status-reason). |
| 19 | PlayerStatusSubReasonID | int | YES | - | CODE-BACKED | Status sub-reason at this point. |
| 20 | PlayerStatusSubReasonComment | varchar(64) | YES | - | CODE-BACKED | Agent comment at this point. |
| 21 | Trace | varchar(max) | YES | JSON | CODE-BACKED | Connection audit context. |
| 22 | SeychellesCategorizationID | int | YES | - | CODE-BACKED | Seychelles classification at this point. |
| 23 | TradingRiskStatusID | int | YES | - | CODE-BACKED | Trading risk status at this point. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK constraints.

### 5.2 Referenced By (other objects point to this)

Populated by triggers on Customer.RiskUserInfo. Read by Customer.GetVerificationLevelChangesHistory.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo triggers | Trigger | INSERT/UPDATE populate this table |
| Customer.GetVerificationLevelChangesHistory | SP | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryRiskUserInfo | CLUSTERED PK | CustomerVersionID | - | - | Active |
| Idx_HistoryRisk_GCID_CustomerVersionID | NONCLUSTERED | GCID ASC, CustomerVersionID DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_HistoryRiskUserInfo_Trace | DEFAULT | Connection context JSON |

---

## 8. Sample Queries

### 8.1 Player status change history
```sql
SELECT h.ValidFrom, ps.Name AS Status, psr.Name AS Reason
FROM History.RiskUserInfo h WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON h.PlayerStatusID = ps.PlayerStatusID
LEFT JOIN Dictionary.PlayerStatusReasons psr WITH (NOLOCK) ON h.PlayerStatusReasonID = psr.PlayerStatusReasonID
WHERE h.GCID = @GCID ORDER BY h.ValidFrom DESC
```

### 8.2 Regulation change history
```sql
SELECT h.ValidFrom, r.Name AS Regulation FROM History.RiskUserInfo h WITH (NOLOCK)
JOIN Dictionary.Regulation r WITH (NOLOCK) ON h.RegulationID = r.ID WHERE h.GCID = @GCID ORDER BY h.ValidFrom
```

### 8.3 Verification progression
```sql
SELECT h.ValidFrom, vl.Name AS VerLevel, h.Verified FROM History.RiskUserInfo h WITH (NOLOCK)
JOIN Dictionary.VerificationLevel vl WITH (NOLOCK) ON h.VerificationLevelID = vl.ID WHERE h.GCID = @GCID ORDER BY h.ValidFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.RiskUserInfo | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.RiskUserInfo.sql*
