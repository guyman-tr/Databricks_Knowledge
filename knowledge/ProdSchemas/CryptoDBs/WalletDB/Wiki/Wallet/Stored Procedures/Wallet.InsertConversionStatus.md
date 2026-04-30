# Wallet.InsertConversionStatus

> Appends a new status event to a conversion's lifecycle by looking up the conversion by CorrelationId, used by the conversion service to track swap progress.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.ConversionStatuses by CorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure appends a status change event to a conversion's lifecycle. The conversion service calls this as a swap progresses through states (e.g., Started -> FromLegSent -> ToLegReceived -> Completed or Failed). The conversion is identified by its CorrelationId (not its internal Id), which is the natural key the calling service has.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Resolves ConversionId from Conversions.CorrelationId, then INSERTs into ConversionStatuses.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID to identify the conversion. Matched against Conversions.CorrelationId. |
| 2 | @ConversionStatusId | tinyint | NO | - | VERIFIED | New status to append. FK to Dictionary.ConversionStatuses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.Conversions.CorrelationId | Lookup | Resolves ConversionId |
| - | Wallet.ConversionStatuses | INSERT | Appends status event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Conversion lifecycle tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertConversionStatus (procedure)
+-- Wallet.Conversions (table)
+-- Wallet.ConversionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | CorrelationId-to-Id resolution |
| Wallet.ConversionStatuses | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update conversion status
```sql
EXEC Wallet.InsertConversionStatus @CorrelationId = 'YOUR-GUID', @ConversionStatusId = 3; -- e.g., Completed
```

### 8.2 Check status history
```sql
SELECT cs.* FROM Wallet.ConversionStatuses cs WITH (NOLOCK) JOIN Wallet.Conversions c WITH (NOLOCK) ON c.Id = cs.ConversionId WHERE c.CorrelationId = 'YOUR-GUID' ORDER BY cs.Id;
```

### 8.3 Direct equivalent
```sql
INSERT INTO Wallet.ConversionStatuses (ConversionId, ConversionStatusId) SELECT Id, 3 FROM Wallet.Conversions WHERE CorrelationId = 'YOUR-GUID';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertConversionStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertConversionStatus.sql*
