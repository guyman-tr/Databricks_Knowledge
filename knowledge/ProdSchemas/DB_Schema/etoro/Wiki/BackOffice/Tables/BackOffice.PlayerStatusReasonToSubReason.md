# BackOffice.PlayerStatusReasonToSubReason

> Junction table defining which sub-reasons are valid under each player status reason, forming a two-level classification hierarchy for customer status changes.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BackOffice_PlayerStatusReasonToSubReason: PlayerStatusReasonID + PlayerStatusSubReasonID (NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (nonclustered PK) |

---

## 1. Business Meaning

`BackOffice.PlayerStatusReasonToSubReason` defines the permitted combinations of reasons and sub-reasons that can be applied when a customer's player status is changed by back-office staff. Player status changes (e.g., closing, suspending, or restricting an account) require a reason for audit and compliance tracking. The reason-to-sub-reason mapping enforces that only contextually appropriate sub-reasons can be selected under a given reason category.

This table exists to provide a validated dropdown hierarchy in back-office tools: when an agent selects a reason category (e.g., "Risk"), the UI can filter available sub-reasons to only those valid under that category. This prevents invalid combinations (e.g., "FATCA" sub-reason under a "Risk" reason) and ensures consistent classification of compliance actions.

Data is configuration/reference data managed by back-office administration. Currently 62 valid reason/sub-reason pairings across 11 reason categories. The table is consumed by `GetPlayerStatusReasonMapping` and `LoadPlayerStatusReasonMapping` procedures which return the full hierarchy for client-side rendering.

---

## 2. Business Logic

### 2.1 Two-Level Status Change Classification

**What**: The reason/sub-reason hierarchy provides a structured taxonomy for categorising why a customer's account status was changed.

**Columns/Parameters Involved**: `PlayerStatusReasonID`, `PlayerStatusSubReasonID`

**Rules**:
- A reason can map to multiple sub-reasons (one-to-many from reason to sub-reason).
- A sub-reason can appear under multiple reasons (e.g., sub-reason 25 "Selfie" appears under both Reason 4 "Risk" and Reason 10 "AML" and Reason 39 "KYC").
- The consuming SP `GetPlayerStatusReasonMapping` joins this table with `PlayerStatusToReason` to provide the full three-level hierarchy: PlayerStatus -> Reason -> SubReason.
- All valid combinations must exist in this table; combinations not listed here are forbidden.

**Diagram**:
```
PlayerStatus (e.g., Closed)
    |
    +-- Reason: Risk (4)
    |       +-- SubReason: Fraud (1)
    |       +-- SubReason: Fake docs (2)
    |       +-- SubReason: Attack (3)
    |       +-- SubReason: Affiliate Fraud (4)
    |       +-- SubReason: Selfie (25) [shared]
    |       +-- SubReason: 3rd party - FTD (46)
    |       +-- ... 13 total
    |
    +-- Reason: AML (10)
    |       +-- SubReason: Investigation (17)
    |       +-- SubReason: Cross Border (18)
    |       +-- SubReason: AML Trigger (19)
    |       +-- SubReason: Selfie (25) [shared]
    |       +-- ... 15 total
    |
    +-- Reason: Chargeback (5)
    |       +-- SubReason: Lost Funds (6)
    |       +-- SubReason: ACH CHBK (35)
    |       +-- SubReason: Credit Card CHBK (36)
    |       +-- ... 12 total
```

---

## 3. Data Overview

| PlayerStatusReasonID | PlayerStatusSubReasonID | Meaning |
|---------------------|------------------------|---------|
| 4 (Risk) | 1 (Fraud) | Risk cases involving fraudulent activity |
| 4 (Risk) | 2 (Fake docs) | Risk cases involving document forgery |
| 4 (Risk) | 25 (Selfie) | Risk cases requiring selfie identity verification |
| 5 (Chargeback) | 36 (Credit Card CHBK) | Chargeback raised via credit card payment method |
| 10 (AML) | 30 (HRC) | AML flag for High Risk Country origin |

Full mapping has 62 rows across 11 reason categories:
- Reason 4 (Risk): 13 sub-reasons
- Reason 5 (Chargeback): 12 sub-reasons
- Reason 10 (AML): 15 sub-reasons
- Reason 21 (Self-Service): 1 sub-reason (UAE PASS Reactivation)
- Reason 34 (Abusive Trading): 3 sub-reasons
- Reason 36 (Partners & PIs): 6 sub-reasons
- Reason 38 (Deposits): 5 sub-reasons
- Reason 39 (KYC): 3 sub-reasons
- Reason 41 (Tax): 4 sub-reasons (FATCA, CRS, W-8BEN)
- Reason 42 (Corporate): 4 sub-reasons
- Reason 43 (Gap): 2 sub-reasons

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusReasonID | int | NO | - | CODE-BACKED | Foreign key to Dictionary.PlayerStatusReasons.PlayerStatusReasonID. Identifies the reason category. Examples: 4=Risk, 5=Chargeback, 10=AML, 34=Abusive Trading, 39=KYC, 41=Tax, 42=Corporate. Part of composite PK. |
| 2 | PlayerStatusSubReasonID | int | NO | - | CODE-BACKED | Foreign key to Dictionary.PlayerStatusSubReasons.PlayerStatusSubReasonID. Identifies the specific sub-reason within the parent category. Examples: 1=Fraud, 25=Selfie, 30=HRC, 36=Credit Card CHBK, 66=FATCA. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons.PlayerStatusReasonID | FK (FK_BackOffice_PlayerStatusReasonToSubReason_PlayerStatusReasonID) | The reason category this row is valid under |
| PlayerStatusSubReasonID | Dictionary.PlayerStatusSubReasons.PlayerStatusSubReasonID | FK (FK_BackOffice_PlayerStatusReasonToSubReason_PlayerStatusSubReasonID) | The specific sub-reason permitted under the reason |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetPlayerStatusReasonMapping | LEFT JOIN | Reader | Joins with PlayerStatusToReason to return full 3-level hierarchy for client-side rendering (Jira RD-1752, 2227) |
| BackOffice.LoadPlayerStatusReasonMapping | LEFT JOIN | Reader | Alternative loading SP for the same hierarchy |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.PlayerStatusReasonToSubReason (table)
├── Dictionary.PlayerStatusReasons (table) [FK]
└── Dictionary.PlayerStatusSubReasons (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerStatusReasons | Table | FK: PlayerStatusReasonID must exist as a valid reason |
| Dictionary.PlayerStatusSubReasons | Table | FK: PlayerStatusSubReasonID must exist as a valid sub-reason |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetPlayerStatusReasonMapping | Stored Procedure | Reader - LEFT JOINs with PlayerStatusToReason for full hierarchy |
| BackOffice.LoadPlayerStatusReasonMapping | Stored Procedure | Reader - loads the full reason/sub-reason mapping |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_PlayerStatusReasonToSubReason | NONCLUSTERED PK | PlayerStatusReasonID ASC, PlayerStatusSubReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BackOffice_PlayerStatusReasonToSubReason_PlayerStatusReasonID | FK | PlayerStatusReasonID -> Dictionary.PlayerStatusReasons |
| FK_BackOffice_PlayerStatusReasonToSubReason_PlayerStatusSubReasonID | FK | PlayerStatusSubReasonID -> Dictionary.PlayerStatusSubReasons |

---

## 8. Sample Queries

### 8.1 Get all valid sub-reasons for a given reason category

```sql
SELECT r.Name AS Reason, s.Name AS SubReason, m.PlayerStatusSubReasonID
FROM BackOffice.PlayerStatusReasonToSubReason m WITH (NOLOCK)
JOIN Dictionary.PlayerStatusReasons r WITH (NOLOCK)
    ON r.PlayerStatusReasonID = m.PlayerStatusReasonID
JOIN Dictionary.PlayerStatusSubReasons s WITH (NOLOCK)
    ON s.PlayerStatusSubReasonID = m.PlayerStatusSubReasonID
WHERE m.PlayerStatusReasonID = 10  -- AML
ORDER BY s.Name;
```

### 8.2 Find all reasons a specific sub-reason belongs to

```sql
SELECT r.PlayerStatusReasonID, r.Name AS ReasonName, m.PlayerStatusSubReasonID
FROM BackOffice.PlayerStatusReasonToSubReason m WITH (NOLOCK)
JOIN Dictionary.PlayerStatusReasons r WITH (NOLOCK)
    ON r.PlayerStatusReasonID = m.PlayerStatusReasonID
WHERE m.PlayerStatusSubReasonID = 25;  -- Selfie
```

### 8.3 Full hierarchy for back-office dropdowns

```sql
SELECT
    ps.Name AS PlayerStatus,
    r.Name AS Reason,
    s.Name AS SubReason,
    ptr.PlayerStatusID,
    m.PlayerStatusReasonID,
    m.PlayerStatusSubReasonID
FROM BackOffice.PlayerStatusToReason ptr WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK)
    ON ps.PlayerStatusID = ptr.PlayerStatusID
JOIN Dictionary.PlayerStatusReasons r WITH (NOLOCK)
    ON r.PlayerStatusReasonID = ptr.PlayerStatusReasonID
LEFT JOIN BackOffice.PlayerStatusReasonToSubReason m WITH (NOLOCK)
    ON m.PlayerStatusReasonID = ptr.PlayerStatusReasonID
LEFT JOIN Dictionary.PlayerStatusSubReasons s WITH (NOLOCK)
    ON s.PlayerStatusSubReasonID = m.PlayerStatusSubReasonID
ORDER BY ptr.PlayerStatusID, m.PlayerStatusReasonID, m.PlayerStatusSubReasonID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-1752, RD-2227 (referenced in SP comment) | Jira | Ops0451 - reorg of PlayerStatus, reasons and sub-reasons - this table was created/modified as part of that initiative |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Live Data, FK Resolution, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.PlayerStatusReasonToSubReason | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.PlayerStatusReasonToSubReason.sql*
