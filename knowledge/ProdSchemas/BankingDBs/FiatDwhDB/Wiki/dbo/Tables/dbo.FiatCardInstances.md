# dbo.FiatCardInstances

> Represents physical or virtual card instances issued under a card entity, tracking PAN, expiration, and virtual/physical status.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

FiatCardInstances represents the physical or virtual card instance associated with a logical card (dbo.FiatCards). A single card entity can have multiple instances over time - when a card is reissued, replaced, or when both a physical and virtual card exist. Each instance has its own masked PAN, expiration date, and virtual/physical flag.

Data is created by dbo.AddFiatCardInstances. The CardInstanceId is referenced by dbo.FiatCardStatuses to track which specific instance a status event applies to.

---

## 2. Business Logic

### 2.1 Physical vs Virtual Card Instances

**What**: Cards can exist as physical plastic cards or virtual (digital wallet) cards.

**Columns/Parameters Involved**: `IsVirtual`, `MaskedPAN`, `CardExpirationDate`

**Rules**:
- IsVirtual=1: Digital card for mobile wallet/online use
- IsVirtual=0: Physical plastic card
- MaskedPAN shows last 4 digits of the card number (masked for security)
- A card may have both a physical and virtual instance active simultaneously

---

## 3. Data Overview

N/A - PII-adjacent data (card details).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Referenced by FiatCardStatuses.CardInstanceId. |
| 2 | CardId | bigint | NO | - | CODE-BACKED | Implicit FK to dbo.FiatCards.Id. The logical card this instance belongs to. No explicit FK constraint in DDL. |
| 3 | MaskedPAN | nvarchar(128) MASKED | NO | - | CODE-BACKED | Masked card number showing only last digits. Dynamic data masking protects the full PAN. |
| 4 | IsVirtual | bit | NO | - | CODE-BACKED | Whether this is a virtual (digital wallet) card: 1=virtual, 0=physical plastic card. |
| 5 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this instance was recorded. |
| 6 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Links this instance creation to the triggering business operation for distributed tracing. |
| 7 | Name | nvarchar(128) MASKED | YES | - | CODE-BACKED | Cardholder name printed on the card. Masked for PII protection. |
| 8 | CardExpirationDate | datetime2(7) | YES | - | CODE-BACKED | Expiration date of this card instance. NULL for instances where expiration is not yet set. |
| 9 | CardInstanceGuid | uniqueidentifier | YES | - | CODE-BACKED | External-facing GUID for this card instance. Used in API interactions. Nullable for legacy instances created before this field was added. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CardId | dbo.FiatCards | Implicit | The logical card this instance belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.FiatCardStatuses | CardInstanceId | Implicit | Card status events reference the specific instance |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatCardInstances (table)
└── dbo.FiatCards (table) [implicit]
    └── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCards | Table | Implicit reference from CardId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCardStatuses | Table | Implicit ref from CardInstanceId |
| dbo.AddFiatCardInstances | Stored Procedure | Inserts card instances |
| dbo.GetFiatCardInstanceIdByGuid | Stored Procedure | Reads by GUID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CardInstances | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK). No explicit FK to FiatCards despite the logical relationship.

---

## 8. Sample Queries

### 8.1 Find all instances for a card
```sql
SELECT Id, MaskedPAN, IsVirtual, CardExpirationDate, Created
FROM dbo.FiatCardInstances WITH (NOLOCK)
WHERE CardId = 105279 ORDER BY Created;
```

### 8.2 Find instance by GUID
```sql
SELECT * FROM dbo.FiatCardInstances WITH (NOLOCK)
WHERE CardInstanceGuid = 'A1B2C3D4-0000-0000-0000-000000000001';
```

### 8.3 Count virtual vs physical instances
```sql
SELECT CASE WHEN IsVirtual = 1 THEN 'Virtual' ELSE 'Physical' END AS CardType, COUNT(*) AS Cnt
FROM dbo.FiatCardInstances WITH (NOLOCK)
GROUP BY IsVirtual;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | CardInstances referenced in FiatCustodianDB card queries pattern |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatCardInstances | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatCardInstances.sql*
