# Trade.ChangeMirrorCalculationType

> Updates the PnL calculation type for a CopyTrader mirror and logs the change to History.Mirror with MirrorOperationID=11.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @MirrorID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ChangeMirrorCalculationType changes the MirrorCalculationType field on a CopyTrader mirror. This setting controls how the mirror's profit and loss is calculated - the calculation type determines the PnL formula used for the copy-trade relationship (e.g., proportional vs fixed-amount copying).

This procedure exists because eToro supports different calculation methods for copy trading, and the method can be changed on an existing mirror without closing and reopening it. The procedure updates Trade.Mirror and records the change in History.Mirror with MirrorOperationID=11 (Update MirrorCalculationType).

The operation is transactional and validates CID+MirrorID ownership. If no matching row is found, error 60125 is raised.

---

## 2. Business Logic

### 2.1 Calculation Type Update

**What**: Changes the PnL calculation method for a mirror.

**Columns/Parameters Involved**: `@MirrorCalculationType`, `@MirrorID`, `@CID`

**Rules**:
- Updates Trade.Mirror.MirrorCalculationType to the new value
- Validated by CID + MirrorID combination (both must match)
- Error 60125 if no matching row found (invalid MirrorID or CID mismatch)
- Full mirror state snapshot is written to History.Mirror with MirrorOperationID=11

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must match Trade.Mirror.CID for the given mirror. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | CopyTrader mirror to update. |
| 3 | @MirrorCalculationType | INT | NO | - | CODE-BACKED | New calculation type to set. Controls PnL formula for the copy-trade relationship. |
| 4 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session ID for audit trail. Written to History.Mirror. |
| 5 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation GUID from client request for tracing. Written to History.Mirror. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | UPDATE | Sets MirrorCalculationType |
| (writes) | History.Mirror | INSERT | Logs full mirror snapshot with MirrorOperationID=11 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | (external) | EXEC | Called when user changes copy calculation method |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ChangeMirrorCalculationType (procedure)
+-- Trade.Mirror (table)
+-- History.Mirror (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | UPDATE MirrorCalculationType, SELECT for History snapshot |
| History.Mirror | Table | INSERT audit record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application services | External | Called for calculation type changes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | BEGIN TRAN / COMMIT / ROLLBACK | Atomic update + history insert |
| Error 60125 | Validation | MirrorID + CID combination not found |

---

## 8. Sample Queries

### 8.1 Check current calculation type for a mirror

```sql
SELECT MirrorID, CID, MirrorCalculationType, IsActive
FROM   Trade.Mirror WITH (NOLOCK)
WHERE  MirrorID = @MirrorID;
```

### 8.2 View calculation type change history

```sql
SELECT MirrorID, MirrorOperationID, MirrorCalculationType, Occurred
FROM   History.Mirror WITH (NOLOCK)
WHERE  MirrorID = @MirrorID
       AND MirrorOperationID = 11
ORDER BY Occurred DESC;
```

### 8.3 Find all mirrors using a specific calculation type

```sql
SELECT MirrorID, CID, ParentCID, Amount, IsActive
FROM   Trade.Mirror WITH (NOLOCK)
WHERE  MirrorCalculationType = @MirrorCalculationType
       AND IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ChangeMirrorCalculationType | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ChangeMirrorCalculationType.sql*
