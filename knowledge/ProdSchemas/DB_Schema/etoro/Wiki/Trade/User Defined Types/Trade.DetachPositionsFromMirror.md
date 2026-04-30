# Trade.DetachPositionsFromMirror

> Memory-optimized TVP carrying full mirror (copy-trade) relationship data for the detach operation - used when a copier stops copying a leader and their positions must be detached while preserving the position itself.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | MirrorID (int) |
| **Partition** | N/A |
| **Indexes** | 1 nonclustered hash (MirrorID) |

---

## 1. Business Meaning

Trade.DetachPositionsFromMirror is a memory-optimized table-valued parameter (TVP) that carries the complete mirror relationship state needed for copy-trade detach operations. When a copier stops following a leader, their open positions must be "detached" - the mirror relationship is dissolved but the position remains as an independent position. This type bundles CID/ParentCID relationship, financial state (amount, equity, SL, investments), operational flags (IsActive, PauseCopy), and tracking metadata (SessionID, ClientRequestGuid).

The type exists to support bulk detach operations where multiple mirror relationships or positions are processed in one procedure call. Trade.DetachPositionsFromMirror and Trade.DetachPositionsByCountryAndInstrument consume this TVP. Without it, detach logic would need row-by-row processing and complex temp table setup.

Application flows detect detach conditions (user stops copying, compliance action, country/instrument restrictions), populate this TVP with mirror state, and pass it to the detach procedure. The hash index on MirrorID with bucket count 1 optimizes single-mirror detach scenarios.

---

## 2. Business Logic

### 2.1 Mirror Detach State Bundle

**What**: The TVP bundles mirror relationship identity, financial snapshot, operational flags, and audit data for the detach lifecycle.

**Columns/Parameters Involved**: `MirrorID`, `CID`, `ParentCID`, `Amount`, `GuruTPV`, `MirrorSL`, `RealizedEquity`, `IsActive`, `PauseCopy`, `SessionID`, `ClientRequestGuid`

**Rules**:
- MirrorID identifies the mirror relationship being detached
- CID/ParentCID define the copier-leader relationship
- Amount, GuruTPV, MirrorSL, RealizedEquity capture financial state at detach time
- IsActive and PauseCopy indicate operational status at detach
- SessionID and ClientRequestGuid provide audit trail for the operation

**Diagram**:
```
MirrorID (relationship) -> CID, ParentCID (copier-leader)
         |
         +-> Amount, GuruTPV, MirrorSL, RealizedEquity (financial state)
         |
         +-> IsActive, PauseCopy (operational flags)
         |
         +-> SessionID, ClientRequestGuid (audit)
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | int | YES | - | CODE-BACKED | Mirror relationship identifier. Primary lookup key for detach operations. Hash index on this column with BUCKET_COUNT=1 optimizes single-mirror lookups. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID of the copier whose positions are being detached from the mirror. |
| 3 | ParentCID | int | YES | - | CODE-BACKED | Customer ID of the leader being uncopied. Defines the copier-leader relationship that is being dissolved. |
| 4 | ParentUserName | varchar(50) | YES | - | CODE-BACKED | Leader's username for display or logging at detach time. |
| 5 | Amount | decimal(16,8) | YES | - | CODE-BACKED | Position amount or unit count at detach. Financial snapshot for audit and reconciliation. |
| 6 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the detach request or event occurred. |
| 7 | IsActive | tinyint | YES | - | CODE-BACKED | Mirror activity flag at detach time. 1=active, 0=inactive. Indicates whether mirror was actively copying when detach was requested. |
| 8 | MirrorOperationID | int | YES | - | CODE-BACKED | Operation identifier for the mirror detach event. Links to mirror operation tracking. |
| 9 | IsOpenOpen | bit | YES | - | CODE-BACKED | Indicates whether the position is open-to-open (copied at open) vs open-to-copy (copied after open). Affects PnL and unit handling at detach. |
| 10 | GuruTPV | money | YES | - | CODE-BACKED | Leader (guru) take-profit value at detach. Reference for aligning copier TP after detach. |
| 11 | MirrorSL | money | YES | - | CODE-BACKED | Stop-loss value for the mirror/copier position. Preserved through detach. |
| 12 | RealizedEquity | money | YES | - | CODE-BACKED | Realized equity snapshot at detach. Used for PnL and settlement calculations. |
| 13 | PauseCopy | bit | YES | - | CODE-BACKED | Whether copy was paused at detach time. 1=paused, 0=actively copying. |
| 14 | MirrorSLPercentage | money | YES | - | CODE-BACKED | Stop-loss expressed as percentage. Alternative representation of mirror SL. |
| 15 | InitialInvestment | money | YES | - | CODE-BACKED | Initial investment amount for the copied position at detach. |
| 16 | DepositSummary | money | YES | - | CODE-BACKED | Total deposits into the mirror/copy relationship. Audit trail for fund flow. |
| 17 | WithdrawalSummary | money | YES | - | CODE-BACKED | Total withdrawals from the mirror/copy relationship. Audit trail for fund flow. |
| 18 | SessionID | bigint | YES | - | CODE-BACKED | Session identifier for the detach request. Audit and correlation. |
| 19 | MIMOOperationTypeID | tinyint | YES | - | CODE-BACKED | Mirror In/Mirror Out operation type. Classifies the detach in the MIMO operation taxonomy. |
| 20 | MirrorDividendID | int | YES | - | CODE-BACKED | Dividend record ID if detach occurred around dividend distribution. Links to dividend handling. |
| 21 | ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client-provided request GUID for idempotency and request correlation across systems. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerTbl | Implicit | Copier customer |
| ParentCID | Customer.CustomerTbl | Implicit | Leader customer |
| MirrorOperationID | Trade.MirrorOperation (if exists) | Implicit | Mirror operation tracking |
| MIMOOperationTypeID | Dictionary lookup | Implicit | MIMO operation type classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DetachPositionsFromMirror | @MirrorData | Parameter (TVP) | Main detach procedure |
| Trade.DetachPositionsByCountryAndInstrument | TVP parameter | Parameter (TVP) | Bulk detach by country/instrument filter |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DetachPositionsFromMirror | Stored Procedure | READONLY parameter for mirror detach |
| Trade.DetachPositionsByCountryAndInstrument | Stored Procedure | READONLY parameter for bulk detach |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IDX | Nonclustered HASH | MirrorID | - | - | Active |

BUCKET_COUNT = 1, optimized for single-mirror detach.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Populate and pass DetachPositionsFromMirror to detach procedure

```sql
DECLARE @MirrorData Trade.DetachPositionsFromMirror;
INSERT INTO @MirrorData (MirrorID, CID, ParentCID, Amount, Occurred, IsActive, MirrorOperationID, GuruTPV, MirrorSL, RealizedEquity, SessionID, ClientRequestGuid)
SELECT  m.MirrorID, m.CID, m.ParentCID, p.Amount, GETUTCDATE(), 1, @OpID, p.GuruTPV, p.MirrorSL, p.RealizedEquity, @SessionID, @RequestGuid
FROM    Trade.MirrorTbl m WITH (NOLOCK)
JOIN    Trade.PositionTbl p WITH (NOLOCK) ON p.MirrorID = m.MirrorID
WHERE   m.CID = @CopierCID AND m.ParentCID = @LeaderCID AND p.IsOpen = 1;

EXEC Trade.DetachPositionsFromMirror @MirrorData = @MirrorData;
```

### 8.2 Build mirror detach TVP from mirror table for bulk detach

```sql
DECLARE @DetachData Trade.DetachPositionsFromMirror;
INSERT INTO @DetachData (MirrorID, CID, ParentCID, ParentUserName, Amount, Occurred, IsActive, GuruTPV, MirrorSL, RealizedEquity, PauseCopy, InitialInvestment, DepositSummary, WithdrawalSummary)
SELECT  m.MirrorID, m.CID, m.ParentCID, u.UserName, ISNULL(p.Amount, 0), m.LastModified, m.IsActive, p.GuruTPV, p.MirrorSL, p.RealizedEquity, m.PauseCopy, p.InitialInvestment, m.DepositSummary, m.WithdrawalSummary
FROM    Trade.MirrorTbl m WITH (NOLOCK)
JOIN    Customer.UserTbl u WITH (NOLOCK) ON u.CID = m.ParentCID
LEFT JOIN Trade.PositionTbl p WITH (NOLOCK) ON p.MirrorID = m.MirrorID AND p.IsOpen = 1
WHERE   m.ParentCID IN (SELECT CID FROM @LeaderCIDs);

EXEC Trade.DetachPositionsByCountryAndInstrument @MirrorData = @DetachData, @CountryID = @CountryID;
```

### 8.3 Minimal detach payload for single mirror

```sql
DECLARE @Data Trade.DetachPositionsFromMirror;
INSERT INTO @Data (MirrorID, CID, ParentCID, ClientRequestGuid)
VALUES (@MirrorID, @CID, @ParentCID, @RequestGuid);
EXEC Trade.DetachPositionsFromMirror @MirrorData = @Data;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DetachPositionsFromMirror | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DetachPositionsFromMirror.sql*
