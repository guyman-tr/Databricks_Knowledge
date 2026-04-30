# Monitoring.GetEtoroXTermsAndConditionsSigned

> Retrieves recent eToroX Terms and Conditions sign events, showing which customers accepted the eToroX legal entity's terms within a specified lookback window.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns T&C sign events for eToroX legal entity |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetEtoroXTermsAndConditionsSigned monitors the rate of eToroX Terms and Conditions acceptance events. eToroX is the crypto exchange entity, and customers must accept its terms before they can use wallet features. This procedure tracks recent sign events for operational visibility - a sudden drop or spike could indicate UX issues, a new T&C rollout, or a system problem.

Without this procedure, the team would have no real-time visibility into T&C acceptance rates, making it difficult to monitor the impact of T&C version changes or detect onboarding flow disruptions.

The procedure joins CustomerTermsAndConditions (sign records), TermsAndConditions (version info), and Dictionary.EtoroLegalEntities to filter specifically for eToroX (entity Id=1).

---

## 2. Business Logic

### 2.1 eToroX Entity Filtering

**What**: Isolates T&C sign events for the eToroX legal entity specifically.

**Columns/Parameters Involved**: `EtoroLegalEntities.Id`, `TermsAndConditions.TypeId`

**Rules**:
- Dictionary.EtoroLegalEntities.Id = 1 identifies the eToroX entity
- TermsAndConditions.TypeId links to the legal entity
- Results ordered by sign time descending (most recent first)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBack | INT | NO | 24 | CODE-BACKED | Lookback window in hours. Default 24 hours for daily monitoring. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | CustomerTermsAndConditions record ID. |
| 2 | Gcid | INT | NO | - | CODE-BACKED | Customer who signed the T&C. |
| 3 | TermsAndConditionId | INT | NO | - | CODE-BACKED | FK to the specific T&C version signed. |
| 4 | TermsVersion | NVARCHAR | NO | - | CODE-BACKED | Version string of the T&C document. From TermsAndConditions.Version. |
| 5 | SignedAt | DATETIME2 | NO | - | CODE-BACKED | When the customer accepted the terms. From CustomerTermsAndConditions.Occured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.CustomerTermsAndConditions | FROM (read) | Customer T&C sign events |
| Query body | Wallet.TermsAndConditions | JOIN | T&C version details |
| Query body | Dictionary.EtoroLegalEntities | JOIN | Filters to eToroX entity (Id=1) |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetEtoroXTermsAndConditionsSigned (procedure)
  ├── Wallet.CustomerTermsAndConditions (table)
  ├── Wallet.TermsAndConditions (table)
  └── Dictionary.EtoroLegalEntities (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerTermsAndConditions | Table | FROM - sign event records |
| Wallet.TermsAndConditions | Table | JOIN - version info |
| Dictionary.EtoroLegalEntities | Table | JOIN - entity filter (Id=1) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check last 24 hours (default)
```sql
EXEC Monitoring.GetEtoroXTermsAndConditionsSigned;
```

### 8.2 Check last week
```sql
EXEC Monitoring.GetEtoroXTermsAndConditionsSigned @HoursBack = 168;
```

### 8.3 Count T&C signups by version
```sql
SELECT tnc.Version, COUNT(*) AS SignCount
FROM Wallet.CustomerTermsAndConditions ctc WITH (NOLOCK)
JOIN Wallet.TermsAndConditions tnc WITH (NOLOCK) ON tnc.Id = ctc.TermsAndConditionId
JOIN Dictionary.EtoroLegalEntities ele WITH (NOLOCK) ON ele.Id = tnc.TypeId
WHERE ele.Id = 1
GROUP BY tnc.Version ORDER BY SignCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetEtoroXTermsAndConditionsSigned | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetEtoroXTermsAndConditionsSigned.sql*
