# Wallet.RemoveLimitationDefinition

> Deactivates a spending limitation definition by inserting a new version with IsActive=0, maintaining the full audit history of limitation configuration changes.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into LimitationsDefinitions with IsActive=0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure "removes" a limitation definition by inserting a new record with IsActive=0 (not by deleting). Limitation definitions are JSON-based spending rules configured by the back-office. Since the table is append-only (each change creates a new record), "removal" is a new entry that deactivates the definition. The @LastChangedBy parameter tracks who made the change for audit.

---

## 2. Business Logic

### 2.1 Append-Only Deactivation

**What**: Deactivates by inserting IsActive=0 rather than deleting.

**Rules**:
- INSERT with IsActive = 0, Occurred = GETUTCDATE()
- Previous active versions remain for audit history
- The latest version for a given definition determines whether it's active

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DefinitionJson | nvarchar(max) | NO | - | CODE-BACKED | JSON definition of the limitation to deactivate. |
| 2 | @LastChangedBy | nvarchar(100) | NO | - | CODE-BACKED | Operator/system that deactivated the definition. Audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.LimitationsDefinitions | INSERT | Deactivation record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Limitation management |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.RemoveLimitationDefinition (procedure)
+-- Wallet.LimitationsDefinitions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Deactivate a limitation
```sql
EXEC Wallet.RemoveLimitationDefinition @DefinitionJson='{"type":"daily","cryptoId":1,"maxAmount":10}', @LastChangedBy='admin@etoro.com';
```

### 8.2 Check active limitations
```sql
SELECT * FROM Wallet.LimitationsDefinitions WITH (NOLOCK) WHERE IsActive = 1 ORDER BY Occurred DESC;
```

### 8.3 Check deactivation history
```sql
SELECT * FROM Wallet.LimitationsDefinitions WITH (NOLOCK) WHERE IsActive = 0 ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.RemoveLimitationDefinition | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.RemoveLimitationDefinition.sql*
