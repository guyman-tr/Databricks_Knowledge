# BackOffice.PlayerStatusToReason

> Junction table defining which reasons are valid for each player account status, forming the first level of a three-tier status classification hierarchy (Status -> Reason -> SubReason).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BackOffice_PlayerStatusToReason: PlayerStatusID + PlayerStatusReasonID (NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (nonclustered PK) |

---

## 1. Business Meaning

`BackOffice.PlayerStatusToReason` maps each player account status to the set of reasons that are valid for applying that status. When a back-office agent changes a customer's account status (e.g., blocks or restricts an account), they must select a reason from the predefined list. This table defines which reasons are permissible for each status, preventing nonsensical combinations (e.g., "Underage" reason cannot be used for a status that means "blocked upon request").

This table exists to enforce consistency in the compliance audit trail. Each player status change recorded elsewhere in the system references a (status, reason) pair - those pairs must be valid per this mapping. It also drives the UI dropdown that lets back-office agents select a reason when changing a customer's status.

Data is configuration/reference data managed by back-office administrators. It is consumed by `GetPlayerStatusReasonMapping` and `LoadPlayerStatusReasonMapping` which join this table with `PlayerStatusReasonToSubReason` to return the full three-level hierarchy to the client application.

---

## 2. Business Logic

### 2.1 Three-Level Status Classification Hierarchy

**What**: This table is Level 1 of a three-level classification system for account status changes.

**Columns/Parameters Involved**: `PlayerStatusID`, `PlayerStatusReasonID`

**Rules**:
- Level 1: PlayerStatus -> Reason (this table)
- Level 2: Reason -> SubReason (BackOffice.PlayerStatusReasonToSubReason)
- A status can map to multiple reasons. Status 2 (Blocked) maps to 12+ reasons.
- Status 1 (Normal) maps only to Reason 0 (None) - no reason required for normal status.
- The combination is unique (enforced by PK).

**Diagram**:
```
PlayerStatus (Dictionary.PlayerStatus)
    |
    +-- 1 = Normal
    |       -> 0 = None
    |
    +-- 2 = Blocked
    |       -> 4  = Risk      -> (13 sub-reasons)
    |       -> 5  = Chargeback -> (12 sub-reasons)
    |       -> 8  = Underage
    |       -> 9  = Deceased
    |       -> 10 = AML       -> (15 sub-reasons)
    |       -> 19 = Other
    |       -> 33 = eToro Money Restriction
    |       -> 36 = Partners & PIs -> (6 sub-reasons)
    |       -> 39 = KYC       -> (3 sub-reasons)
    |       -> 40 = Account Closed
    |       -> 41 = Tax       -> (4 sub-reasons)
    |       -> 42 = Corporate -> (4 sub-reasons)
    |
    +-- 4 = Blocked Upon Request
            -> 3  = CloseAccountByUser
            -> 19 = Other
```

---

## 3. Data Overview

| PlayerStatusID | PlayerStatusReasonID | PlayerStatus | Reason | Meaning |
|----------------|---------------------|-------------|--------|---------|
| 1 | 0 | Normal | None | Standard active account with no restriction - no reason classification needed |
| 2 | 4 | Blocked | Risk | Account blocked due to risk/fraud concerns (most common block reason in practice) |
| 2 | 10 | Blocked | AML | Account blocked for anti-money laundering investigation |
| 2 | 8 | Blocked | Underage | Account blocked because customer is below legal trading age |
| 4 | 3 | Blocked Upon Request | CloseAccountByUser | Customer voluntarily requested account closure (self-exclusion or standard close) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusID | int | NO | - | CODE-BACKED | FK to Dictionary.PlayerStatus.PlayerStatusID. The account status this reason is valid for. Known values: 1=Normal, 2=Blocked, 4=Blocked Upon Request. Part of composite PK. |
| 2 | PlayerStatusReasonID | int | NO | - | CODE-BACKED | FK to Dictionary.PlayerStatusReasons.PlayerStatusReasonID. The reason permitted for this status. Examples: 0=None, 4=Risk, 5=Chargeback, 8=Underage, 10=AML, 39=KYC, 41=Tax. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerStatusID | Dictionary.PlayerStatus.PlayerStatusID | FK (FK_BackOffice_PlayerStatusToReason_PlayerStatusID) | The account status this mapping applies to |
| PlayerStatusReasonID | Dictionary.PlayerStatusReasons.PlayerStatusReasonID | FK (FK_BackOffice_PlayerStatusToReason_PlayerStatusReasonID) | The reason permitted under this status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetPlayerStatusReasonMapping | FROM | Reader | Joins this with PlayerStatusReasonToSubReason for full three-level hierarchy |
| BackOffice.LoadPlayerStatusReasonMapping | FROM | Reader | Alternative loader for the same full hierarchy |
| BackOffice.PlayerStatusReasonToSubReason | PlayerStatusReasonID | Related | Second-level mapping that further classifies reasons into sub-reasons |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.PlayerStatusToReason (table)
├── Dictionary.PlayerStatus (table) [FK]
└── Dictionary.PlayerStatusReasons (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerStatus | Table | FK: PlayerStatusID must exist as a valid status |
| Dictionary.PlayerStatusReasons | Table | FK: PlayerStatusReasonID must exist as a valid reason |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetPlayerStatusReasonMapping | Stored Procedure | FROM - provides the status-to-reason mappings for the full hierarchy |
| BackOffice.LoadPlayerStatusReasonMapping | Stored Procedure | FROM - loads full reason mapping for client |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_PlayerStatusToReason | NONCLUSTERED PK | PlayerStatusID ASC, PlayerStatusReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BackOffice_PlayerStatusToReason_PlayerStatusID | FK | PlayerStatusID -> Dictionary.PlayerStatus |
| FK_BackOffice_PlayerStatusToReason_PlayerStatusReasonID | FK | PlayerStatusReasonID -> Dictionary.PlayerStatusReasons |

---

## 8. Sample Queries

### 8.1 Get all valid reasons for a given status

```sql
SELECT ps.Name AS PlayerStatus, r.Name AS Reason
FROM BackOffice.PlayerStatusToReason ptr WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON ps.PlayerStatusID = ptr.PlayerStatusID
JOIN Dictionary.PlayerStatusReasons r WITH (NOLOCK) ON r.PlayerStatusReasonID = ptr.PlayerStatusReasonID
WHERE ptr.PlayerStatusID = 2  -- Blocked
ORDER BY r.Name;
```

### 8.2 Full three-level hierarchy for client UI

```sql
EXEC BackOffice.GetPlayerStatusReasonMapping;
```

### 8.3 All statuses a specific reason can apply to

```sql
SELECT ps.Name AS PlayerStatus, r.Name AS Reason
FROM BackOffice.PlayerStatusToReason ptr WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON ps.PlayerStatusID = ptr.PlayerStatusID
JOIN Dictionary.PlayerStatusReasons r WITH (NOLOCK) ON r.PlayerStatusReasonID = ptr.PlayerStatusReasonID
WHERE ptr.PlayerStatusReasonID = 10  -- AML
ORDER BY ptr.PlayerStatusID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| RD-1752, RD-2227 (referenced in consuming SP comments) | Jira | Ops0451 - reorg of PlayerStatus, reasons and sub-reasons - this mapping table was created/restructured as part of that initiative |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Live Data, FK Resolution, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.PlayerStatusToReason | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.PlayerStatusToReason.sql*
