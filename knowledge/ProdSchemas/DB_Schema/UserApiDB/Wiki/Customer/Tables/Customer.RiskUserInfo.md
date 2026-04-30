# Customer.RiskUserInfo

> Core user profile table storing regulatory compliance data: regulation assignment, player status, verification level, MiFID/ASIC/Seychelles classification, and document verification status.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.RiskUserInfo is the most compliance-critical of the four core user profile tables. It stores every user's regulatory assignment, account restriction status, identity verification progress, and jurisdiction-specific classifications (MiFID for EU, ASIC for Australia, Seychelles for FSA). This table drives the platform's compliance engine - every action a user takes is checked against their RiskUserInfo.

The table has 8 explicit FK constraints to Dictionary tables and is the most heavily referenced table in the Customer schema. Its triggers maintain a full audit trail in History.RiskUserInfo and sync changes to Sync.PendingEntityEvents (EntityType=4 for RiskInfo). The INSERT trigger is ENABLED (unlike most other tables), ensuring the initial risk profile is always captured.

---

## 2. Business Logic

### 2.1 Regulatory Classification Matrix

**What**: Three parallel classification systems for different regulatory jurisdictions.

**Columns/Parameters Involved**: `RegulationID`, `MifidCategorizationID`, `AsicClassificationID`, `SeychellesCategorizationID`

**Rules**:
- RegulationID determines which classification system applies
- CySEC users (RegulationID=1) use MifidCategorizationID (1=Retail, 2=Professional, 3=Elective)
- ASIC users (RegulationID=4,10) use AsicClassificationID (1-5)
- FSA Seychelles users (RegulationID=9) use SeychellesCategorizationID (0-3)
- DesignatedRegulationID allows overriding the default regulation (e.g., during migration)

### 2.2 Account Status with Audit

**What**: Player status with mandatory reason and sub-reason tracking.

**Columns/Parameters Involved**: `PlayerStatusID`, `PlayerStatusReasonID`, `PlayerStatusSubReasonID`, `PlayerStatusSubReasonComment`

**Rules**:
- PlayerStatusID controls what the user can do (see Dictionary.PlayerStatus permission matrix)
- When status changes from Normal (1), a reason must be provided
- Sub-reason adds granularity (e.g., Reason=Chargeback, SubReason=ACH CHBK)
- PlayerStatusSubReasonComment allows free-text notes from compliance agents

---

## 3. Data Overview

N/A - transactional table with millions of rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID. |
| 2 | RegulationID | int | NO | 0 | CODE-BACKED | FK to Dictionary.Regulation. Primary regulatory jurisdiction: 0=None, 1=CySEC, 2=FCA, 4=ASIC, 7=FinCEN, etc. Default: 0. See [Regulation](_glossary.md#regulation). |
| 3 | PlayerStatusID | int | NO | 0 | CODE-BACKED | FK to Dictionary.PlayerStatus. Account permission status: 1=Normal, 2=Blocked, 9=Trade&MIMO Blocked, 13=Pending Verification, etc. Default: 0. See [Player Status](_glossary.md#player-status). |
| 4 | VerificationLevelID | int | NO | 0 | CODE-BACKED | FK to Dictionary.VerificationLevel. Identity verification tier: 0=unverified, 1=basic, 2=standard, 3=enhanced. Default: 0. See [Verification Level](_glossary.md#verification-level). |
| 5 | DocumentStatusID | int | YES | - | CODE-BACKED | Document verification status (uploaded, approved, rejected, etc.). |
| 6 | PhoneVerifiedID | int | YES | - | CODE-BACKED | Phone number verification status. |
| 7 | SuitabilityTestStatusID | int | YES | - | CODE-BACKED | Status of the copy-trading suitability assessment. |
| 8 | EvMatchStatus | int | YES | - | CODE-BACKED | Electronic Verification match result. Maps to Dictionary.EvMatchStatus values (0-3). See [EV Match Status](_glossary.md#ev-match-status). |
| 9 | DesignatedRegulationID | int | YES | - | CODE-BACKED | FK to Dictionary.Regulation. Override/target regulation for migration scenarios. NULL when not in migration. |
| 10 | MifidCategorizationID | int | NO | 1 | CODE-BACKED | FK to Dictionary.MifidCategorization. EU client classification: 0=None, 1=Retail, 2=Professional, 3=Elective. Default: 1 (Retail). See [MiFID Categorization](_glossary.md#mifid-categorization). |
| 11 | AsicClassificationID | int | YES | - | CODE-BACKED | FK to Dictionary.AsicClassification. Australian client classification: 1=RetailPending, 2=Sophisticated, 3=Wholesale, 4=Retail. See [ASIC Classification](_glossary.md#asic-classification). |
| 12 | Verified | bit | NO | 0 | CODE-BACKED | Whether the user's identity has been verified (any method). Default: 0 (unverified). |
| 13 | VerifiedBy | int | YES | - | CODE-BACKED | Who verified the user. Compliance agent CID for manual verification, NULL for system verification. |
| 14 | VerifiedByProvider | int | YES | - | CODE-BACKED | Which EV provider verified the user. Maps to Dictionary.EvProvider. |
| 15 | PlayerStatusReasonID | int | YES | - | CODE-BACKED | FK to Dictionary.PlayerStatusReasons. Why the account was restricted: 0=None, 5=Chargeback, 10=AML, etc. See [Player Status Reason](_glossary.md#player-status-reason). |
| 16 | PlayerStatusSubReasonID | int | YES | - | CODE-BACKED | FK to Dictionary.PlayerStatusSubReasons. Granular sub-reason: 1=Fraud, 14=Sanctions, 36=Credit Card CHBK, etc. See [Player Status Sub Reason](_glossary.md#player-status-sub-reason). |
| 17 | PlayerStatusSubReasonComment | varchar(64) | YES | - | CODE-BACKED | Free-text note from compliance agent about the status change. Max 64 chars. |
| 18 | SeychellesCategorizationID | int | YES | - | CODE-BACKED | FK to Dictionary.SeychellesCategorization. Seychelles client classification: 0=Basic, 1=Pending, 2=Advanced, 3=NotInFlow. See [Seychelles Categorization](_glossary.md#seychelles-categorization). |
| 19 | TradingRiskStatusID | int | YES | 4 | CODE-BACKED | Trading risk assessment status. Default: 4. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegulationID | Dictionary.Regulation | Explicit FK | Primary regulation |
| DesignatedRegulationID | Dictionary.Regulation | Explicit FK | Override regulation |
| PlayerStatusID | Dictionary.PlayerStatus | Explicit FK | Account permission status |
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons | Explicit FK | Status change reason |
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons | Explicit FK | Status change sub-reason |
| VerificationLevelID | Dictionary.VerificationLevel | Explicit FK | Verification tier |
| MifidCategorizationID | Dictionary.MifidCategorization | Explicit FK | EU client classification |
| AsicClassificationID | Dictionary.AsicClassification | Explicit FK | Australian classification |
| SeychellesCategorizationID | Dictionary.SeychellesCategorization | Explicit FK | Seychelles classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.RiskUserInfo | GCID | Trigger-written | Audit trail |
| Sync.PendingEntityEvents | GCID | Trigger-written | Sync queue (EntityType=4) |
| Customer.GetRiskInfo | GCID | SP reads | Returns risk profile |
| Customer.UpdateRiskInfo | GCID | SP writes | Updates risk profile |
| Customer.GetSingleAggregatedInfo | GCID | SP reads | Included in aggregated info |
| Customer.UpdateRiskUserInfo | GCID | SP writes | Updates risk profile (new API) |
| Customer.GetUsersPlayerStatus | GCID | SP reads | Returns player status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RiskUserInfo (table)
  +-- Dictionary.Regulation (table) [done] (2 FKs)
  +-- Dictionary.PlayerStatus (table) [done]
  +-- Dictionary.PlayerStatusReasons (table) [done]
  +-- Dictionary.PlayerStatusSubReasons (table) [done]
  +-- Dictionary.VerificationLevel (table) [done]
  +-- Dictionary.MifidCategorization (table) [done]
  +-- Dictionary.AsicClassification (table) [done]
  +-- Dictionary.SeychellesCategorization (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Regulation | Table | FK: RegulationID, DesignatedRegulationID |
| Dictionary.PlayerStatus | Table | FK: PlayerStatusID |
| Dictionary.PlayerStatusReasons | Table | FK: PlayerStatusReasonID |
| Dictionary.PlayerStatusSubReasons | Table | FK: PlayerStatusSubReasonID |
| Dictionary.VerificationLevel | Table | FK: VerificationLevelID |
| Dictionary.MifidCategorization | Table | FK: MifidCategorizationID |
| Dictionary.AsicClassification | Table | FK: AsicClassificationID |
| Dictionary.SeychellesCategorization | Table | FK: SeychellesCategorizationID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.RiskUserInfo | Table | Trigger writes audit rows |
| Customer.GetRiskInfo | Stored Procedure | Reads from |
| Customer.UpdateRiskInfo | Stored Procedure | Writes to |
| Customer.GetUsersPlayerStatus | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RiskUserInfo | CLUSTERED PK | GCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_RiskUserInfo_RegulationID | DEFAULT | (0) |
| DF_RiskUserInfo_PlayerStatusID | DEFAULT | (0) |
| DF_RiskUserInfo_VerificationLevelID | DEFAULT | (0) |
| DF_RiskUserInfo_MifidCategorizationID | DEFAULT | (1) - Retail |
| DF_RiskUserInfo_Verified | DEFAULT | (0) - unverified |
| (unnamed) | DEFAULT | (4) for TradingRiskStatusID |
| 8 Foreign Key constraints | FOREIGN KEY | See Section 5.1 |

---

## 8. Sample Queries

### 8.1 Get full risk profile for a user
```sql
SELECT r.GCID, reg.Name AS Regulation, ps.Name AS PlayerStatus, psr.Name AS StatusReason,
       vl.Name AS VerificationLevel, mc.Name AS MifidCategory, r.Verified
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.Regulation reg WITH (NOLOCK) ON r.RegulationID = reg.ID
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON r.PlayerStatusID = ps.PlayerStatusID
LEFT JOIN Dictionary.PlayerStatusReasons psr WITH (NOLOCK) ON r.PlayerStatusReasonID = psr.PlayerStatusReasonID
JOIN Dictionary.VerificationLevel vl WITH (NOLOCK) ON r.VerificationLevelID = vl.ID
JOIN Dictionary.MifidCategorization mc WITH (NOLOCK) ON r.MifidCategorizationID = mc.MifidCategorizationID
WHERE r.GCID = @GCID
```

### 8.2 Find blocked users with reasons
```sql
SELECT r.GCID, ps.Name AS Status, psr.Name AS Reason, pssr.Name AS SubReason, r.PlayerStatusSubReasonComment
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON r.PlayerStatusID = ps.PlayerStatusID
LEFT JOIN Dictionary.PlayerStatusReasons psr WITH (NOLOCK) ON r.PlayerStatusReasonID = psr.PlayerStatusReasonID
LEFT JOIN Dictionary.PlayerStatusSubReasons pssr WITH (NOLOCK) ON r.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
WHERE ps.IsBlocked = 1
```

### 8.3 User distribution by regulation
```sql
SELECT reg.Name, COUNT(*) AS UserCount
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.Regulation reg WITH (NOLOCK) ON r.RegulationID = reg.ID
GROUP BY reg.Name ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.RiskUserInfo | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.RiskUserInfo.sql*
