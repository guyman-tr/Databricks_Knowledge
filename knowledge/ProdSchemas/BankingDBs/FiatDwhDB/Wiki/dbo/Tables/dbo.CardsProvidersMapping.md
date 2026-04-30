# dbo.CardsProvidersMapping

> Mapping table linking internal card IDs to provider-side (Tribe) card identifiers for cross-system reconciliation and API calls.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

CardsProvidersMapping links each internal card (dbo.FiatCards) to its identifier in the external provider system (Tribe). When the platform needs to interact with Tribe about a specific card (status checks, blocks, reissues), it uses this mapping to translate between internal and provider IDs.

Data is created by dbo.AddCardsProvidersMapping when a card is provisioned with the provider.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a straightforward ID mapping table.

---

## 3. Data Overview

N/A - mapping data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | CardId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCards.Id. The internal card being mapped. |
| 3 | ProviderId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.Providers. Currently 1=Tribe. See [Provider](../../_glossary.md#provider). |
| 4 | CardProviderId | nvarchar(128) | NO | - | CODE-BACKED | The provider's identifier for this card in their system. Used for provider API calls. |
| 5 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CardId | dbo.FiatCards | FK | The internal card |
| ProviderId | Dictionary.Providers | FK | The external provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddCardsProvidersMapping | INSERT | Writer | Creates card mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CardsProvidersMapping (table)
└── dbo.FiatCards (table)
    └── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCards | Table | FK from CardId |
| Dictionary.Providers | Table | FK from ProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddCardsProvidersMapping | Stored Procedure | Inserts mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CardsProvidersMapping | CLUSTERED | Id ASC | - | - | Active |
| IX_CardsProvidersMapping_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_CardsProvidersMapping_Cards | FK | CardId -> dbo.FiatCards.Id |
| FK_CardsProvidersMapping_Providers | FK | ProviderId -> Dictionary.Providers.Id |

---

## 8. Sample Queries

### 8.1 Find Tribe card ID for a card
```sql
SELECT CardProviderId FROM dbo.CardsProvidersMapping WITH (NOLOCK) WHERE CardId = 105279;
```

### 8.2 Find card by Tribe provider ID
```sql
SELECT c.CardGuid, a.Gcid, m.CardProviderId
FROM dbo.CardsProvidersMapping m WITH (NOLOCK)
JOIN dbo.FiatCards c WITH (NOLOCK) ON c.Id = m.CardId
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = c.AccountId
WHERE m.CardProviderId = '12345';
```

### 8.3 Count cards per provider
```sql
SELECT p.Name AS Provider, COUNT(*) AS CardCount
FROM dbo.CardsProvidersMapping m WITH (NOLOCK)
JOIN Dictionary.Providers p WITH (NOLOCK) ON p.Id = m.ProviderId
GROUP BY p.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CardsProvidersMapping | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.CardsProvidersMapping.sql*
