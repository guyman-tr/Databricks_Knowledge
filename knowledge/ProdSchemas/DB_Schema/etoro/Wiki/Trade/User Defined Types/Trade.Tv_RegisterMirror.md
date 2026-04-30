# Trade.Tv_RegisterMirror

> Table-valued type holding mirror registration data - used internally by Trade.RegisterMirror to pass mirror attributes (amount, SL, TPV, deposits, etc.) during mirror creation or reopen.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | H_M_MirrorID (int), H_M_CID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Tv_RegisterMirror carries the full set of attributes for a mirror (copy trading) entity. H_M_ prefix denotes "Header/Mirror" fields: MirrorID, CID, ParentCID, ParentUserName, Amount, Occurred, IsActive, MirrorTypeID, IsOpenOpen, GuruTPV, MirrorSL, RealizedEquity, MirrorSLPercentage, InitialInvestment, DepositSummary, WithdrawalSummary, NetProfit, MirrorCalculationType, ReferenceID, ExternalOperationType, MirrorOperationID, SessionID, PauseCopy, ClientRequestGuid.

The type exists as an internal table variable shape for Trade.RegisterMirror. The procedure builds a single row from scalar parameters, inserts into @TradeTv_RegisterMirror, then uses it for INSERT into the mirror target tables. It is not passed as a TVP parameter from callers.

The type flows within Trade.RegisterMirror only - scalar inputs are transformed into one row, inserted into the table variable, then the procedure SELECTs from it for downstream inserts.

---

## 2. Business Logic

Multi-column mirror entity: H_M_* columns represent mirror header data. Grouped as identity (MirrorID, CID, Parent*), financials (Amount, GuruTPV, MirrorSL, RealizedEquity, InitialInvestment, DepositSummary, WithdrawalSummary, NetProfit), and metadata (Occurred, IsActive, MirrorTypeID, SessionID, PauseCopy, ClientRequestGuid, etc.).

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers; this type is used as an internal table variable.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | H_M_MirrorID | int | YES | - | CODE-BACKED | Mirror identifier |
| 2 | H_M_CID | int | YES | - | CODE-BACKED | Customer (follower) identifier |
| 3 | H_M_ParentCID | int | YES | - | CODE-BACKED | Parent (guru) customer identifier |
| 4 | H_M_ParentUserName | varchar(50) | YES | - | CODE-BACKED | Parent user name |
| 5 | H_M_Amount | decimal(16,8) | YES | - | CODE-BACKED | Mirror amount |
| 6 | H_M_Occurred | datetime | YES | - | CODE-BACKED | When the mirror occurred |
| 7 | H_M_IsActive | tinyint | YES | - | CODE-BACKED | Active flag |
| 8 | H_M_MirrorTypeID | int | YES | - | CODE-BACKED | Mirror type identifier |
| 9 | H_M_IsOpenOpen | bit | YES | - | CODE-BACKED | Open-open flag |
| 10 | H_M_GuruTPV | money | YES | - | CODE-BACKED | Guru total position value |
| 11 | H_M_MirrorSL | money | YES | - | CODE-BACKED | Mirror stop-loss value |
| 12 | H_M_RealizedEquity | money | YES | - | CODE-BACKED | Realized equity |
| 13 | H_M_MirrorSLPercentage | money | YES | - | CODE-BACKED | Mirror stop-loss percentage |
| 14 | H_M_InitialInvestment | money | YES | - | CODE-BACKED | Initial investment |
| 15 | H_M_DepositSummary | money | YES | - | CODE-BACKED | Deposit summary |
| 16 | H_M_WithdrawalSummary | money | YES | - | CODE-BACKED | Withdrawal summary |
| 17 | H_M_NetProfit | money | YES | - | CODE-BACKED | Net profit |
| 18 | H_M_MirrorCalculationType | int | YES | - | CODE-BACKED | Mirror calculation type |
| 19 | H_M_ReferenceID | varchar(36) | YES | - | CODE-BACKED | Reference identifier |
| 20 | H_M_ExternalOperationType | int | YES | - | CODE-BACKED | External operation type |
| 21 | H_M_MirrorOperationID | int | YES | - | CODE-BACKED | Mirror operation identifier |
| 22 | H_M_SessionID | bigint | YES | - | CODE-BACKED | Session identifier |
| 23 | H_M_PauseCopy | bit | YES | - | CODE-BACKED | Pause copy flag |
| 24 | H_M_ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request GUID |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Semantic references to Customer.Customer (CID, ParentCID), Trade.Mirror.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.RegisterMirror | @TradeTv_RegisterMirror (internal) | Internal table variable | Holds mirror data built from scalar params, used for insert into mirror tables |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.RegisterMirror | Stored Procedure | Internal table variable for mirror registration data |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 RegisterMirror uses type internally (not called directly)
```sql
-- Trade.RegisterMirror receives scalar params and builds @TradeTv_RegisterMirror internally
EXEC Trade.RegisterMirror @CID = 100, @ParentCID = 200, @AmountInCents = 100000, @MirrorID = @MirrorID OUTPUT, @ParentUserName = 'guru1';
```

### 8.2 Declare table variable for testing
```sql
DECLARE @TradeTv_RegisterMirror Trade.Tv_RegisterMirror;
INSERT INTO @TradeTv_RegisterMirror (H_M_MirrorID, H_M_CID, H_M_ParentCID, H_M_Amount, H_M_Occurred)
VALUES (1, 100, 200, 1000.00, GETDATE());
```

### 8.3 Select from table variable
```sql
DECLARE @TradeTv_RegisterMirror Trade.Tv_RegisterMirror;
-- ... populated by RegisterMirror internal logic
SELECT * FROM @TradeTv_RegisterMirror;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Tv_RegisterMirror | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Tv_RegisterMirror.sql*
