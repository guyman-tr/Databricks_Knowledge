# Trade.GetMirrorRegisterData

> Returns the data required by the Mirror Operation Engine (MOE) to validate and process a mirror registration request, joining Mirror, Customer, and BackOffice data to resolve regulation, country, and account-type eligibility for the copier.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID + @CID - identifies the specific leader-copier mirror |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorRegisterData` retrieves the combined mirror, customer, and back-office data needed by the Mirror Operation Engine (MOE) to validate and complete a mirror registration. When a user starts copying a leader, the MOE service calls this procedure via its `MirrorRegistrationRepository` to obtain information about the mirror relationship, the copier's regulatory jurisdiction, their country, registration date, and whether they are a Fund account.

The procedure joins three sources: `Trade.Mirror` for mirror-level data (amount, calculation type, IDs), `Customer.Customer` for the copier's country and registration date, and `BackOffice.Customer` for regulation and account type. It returns a single row representing the mirror between `@ParentCID` (leader) and `@CID` (copier).

Data flows: Called by the MOE service `MirrorRegistrationRepository` as part of the `RegisterMirror` flow. The MOE service receives a `MirrorRegisterRequest` message from RabbitMQ, and invokes `[Trade].[RegisterMirror]`, then reads back the result with this procedure to get validation data. After successful registration, a `MirrorRegisterNotification` is published to RabbitMQ, followed by the `openOpenPositions` phase.

---

## 2. Business Logic

### 2.1 Regulation Resolution

**What**: The effective regulation for the copier is resolved using a precedence rule: designated regulation overrides base regulation.

**Columns/Parameters Involved**: `RegulationID`, `DesignatedRegulationID` (from BackOffice.Customer)

**Rules**:
- `ISNULL(bc.DesignatedRegulationID, bc.RegulationID) AS RegulationID`
- If `DesignatedRegulationID` is set (non-NULL): use it. This is a manually assigned jurisdiction override used for specific regulatory compliance cases.
- If `DesignatedRegulationID` is NULL: fall back to `RegulationID` (the customer's base regulatory assignment).
- The resolved value is used by the MOE service to check if the copier is permitted to copy the leader under the applicable regulation.

**Diagram**:
```
BackOffice.Customer
  DesignatedRegulationID IS NOT NULL -> use DesignatedRegulationID
  DesignatedRegulationID IS NULL     -> use RegulationID
                              |
                              v
                    RegulationID (effective, returned to MOE for validation)
```

### 2.2 Fund Account Detection

**What**: Determines if the copying account is an eToro Fund (special account type 9).

**Columns/Parameters Involved**: `AccountTypeID`, `IsFund`

**Rules**:
- `IIF(bc.AccountTypeID = 9, 1, 0) AS IsFund`
- `AccountTypeID = 9`: Fund account. These have different minimum copy amounts and validation rules in the MOE service (configured as `DefaultMinCopyPositionAmountToCopyFundInCents`).
- `IsFund = 1`: Indicates the copier is copying into/from a Fund account - subject to different business rules.
- Both `IsFund` (derived flag) and `AccountTypeID` (raw value) are returned to allow the MOE to apply its own branching logic.

### 2.3 Amount Unit Conversion

**What**: Mirror amount is returned in cents.

**Columns/Parameters Involved**: `Amount`, `AmountInCents`

**Rules**:
- `m.Amount * 100 AS AmountInCents`: The mirror's investment amount in cents.
- Matches the convention used in `GetMirrorPositionData` and the MOE service, which works in cents.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The leader's customer ID. Together with @CID, uniquely identifies the mirror. Corresponds to Trade.Mirror.ParentCID. |
| 2 | @CID | INT | NO | - | CODE-BACKED | The copier's customer ID. Together with @ParentCID, uniquely identifies the mirror to fetch registration data for. |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Trade.Mirror | The copier's customer ID (mirrors @CID). |
| 2 | ParentCID | Trade.Mirror | The leader's customer ID (mirrors @ParentCID). |
| 3 | MirrorID | Trade.Mirror | The unique mirror identifier. Used by MOE to reference the mirror in subsequent operations. |
| 4 | CountryID | Customer.Customer | The copier's registered country ID. Used by MOE for geographic compliance checks. |
| 5 | RegulationID | ISNULL(BackOffice.Customer.DesignatedRegulationID, BackOffice.Customer.RegulationID) | The effective regulatory jurisdiction for this copier. Prefers DesignatedRegulationID if set; falls back to RegulationID. Used to validate registration eligibility. |
| 6 | Registered | Customer.Customer | The copier's account registration date. Used in MOE validation flows. |
| 7 | AmountInCents | Trade.Mirror.Amount * 100 | The mirror's total investment amount in cents (converted from dollars). |
| 8 | MirrorCalculationType | Trade.Mirror | The calculation type for this mirror (how proportional copying is computed). |
| 9 | IsFund | IIF(BackOffice.Customer.AccountTypeID = 9, 1, 0) | 1 = the copier account is an eToro Fund (AccountTypeID=9); 0 = regular account. Fund accounts have different minimum copy amounts and business rules in MOE. |
| 10 | AccountTypeID | BackOffice.Customer | Raw account type ID. 9 = Fund. Returned alongside IsFund for full account type context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ParentCID + @CID | Trade.Mirror | Primary read | Gets the mirror row for the leader-copier pair. |
| m.CID | Customer.Customer | JOIN | Resolves the copier's country and registration date. |
| m.CID | BackOffice.Customer | JOIN | Resolves the copier's regulation and account type. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MOE MirrorRegistrationRepository | @ParentCID, @CID | Called by | The Mirror Operation Engine calls this SP as part of the RegisterMirror flow to retrieve validation data after registration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorRegisterData (procedure)
├── Trade.Mirror (table)
├── Customer.Customer (table - cross-schema)
└── BackOffice.Customer (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Primary source - mirror data (Amount, MirrorID, ParentCID, CID, MirrorCalculationType) filtered by ParentCID + CID |
| Customer.Customer | Table (cross-schema) | JOIN on CID - provides CountryID, Registered |
| BackOffice.Customer | Table (cross-schema) | JOIN on CID - provides DesignatedRegulationID, RegulationID, AccountTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MOE MirrorRegistrationRepository | Application service | Called to retrieve mirror registration validation data during RegisterMirror flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get mirror registration data

```sql
EXEC Trade.GetMirrorRegisterData @ParentCID = 111111, @CID = 222222;
```

### 8.2 Verify regulation resolution directly

```sql
SELECT
    m.MirrorID,
    m.CID,
    m.ParentCID,
    bc.RegulationID,
    bc.DesignatedRegulationID,
    ISNULL(bc.DesignatedRegulationID, bc.RegulationID) AS EffectiveRegulationID,
    IIF(bc.AccountTypeID = 9, 1, 0) AS IsFund
FROM Trade.Mirror m WITH (NOLOCK)
INNER JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID = m.CID
WHERE m.ParentCID = 111111 AND m.CID = 222222;
```

### 8.3 Find all Fund copiers for a leader

```sql
SELECT m.MirrorID, m.CID, bc.AccountTypeID
FROM Trade.Mirror m WITH (NOLOCK)
INNER JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID = m.CID
WHERE m.ParentCID = 111111
  AND bc.AccountTypeID = 9;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Moe - Mirror Operation Engine](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12857836033/Moe+-+Mirror+Operation+Engine) | Confluence | GetMirrorRegisterData is used by MirrorRegistrationRepository in MOE service; called during RegisterMirror flow as part of MirrorRegisterRequestProcessor processing MirrorRegisterRequest RabbitMQ messages |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorRegisterData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorRegisterData.sql*
