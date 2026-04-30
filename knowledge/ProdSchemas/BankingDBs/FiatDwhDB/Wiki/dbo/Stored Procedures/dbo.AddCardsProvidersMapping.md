# dbo.AddCardsProvidersMapping

> Upsert procedure that links an internal card to its provider-side (Tribe) card identifier, with idempotent deduplication.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into CardsProvidersMapping, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddCardsProvidersMapping creates or retrieves the mapping between an internal card (FiatCards) and its Tribe provider card ID. Uses UPDLOCK/HOLDLOCK for concurrency-safe upsert. Returns existing ID if CardId already mapped, otherwise inserts and returns new ID.

---

## 2. Business Logic

### 2.1 Idempotent Card-Provider Mapping

**What**: Ensures exactly one provider mapping per CardId.

**Rules**:
- Transaction with UPDLOCK, HOLDLOCK for safe concurrent access
- Deduplicates on CardId (not CardProviderId)
- Returns existing Id if already mapped

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCards.Id. The card to map. |
| 2 | @ProviderId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.Providers (1=Tribe). See [Provider](../../_glossary.md#provider). |
| 3 | @CardProviderId | nvarchar(128) | NO | - | CODE-BACKED | Tribe's card identifier. |
| 4 | @Created | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the mapping event. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.CardsProvidersMapping | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddCardsProvidersMapping (procedure)
└── dbo.CardsProvidersMapping (table)
    └── dbo.FiatCards (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.CardsProvidersMapping | Table | Upsert target |

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

### 8.1 Call the procedure
```sql
EXEC dbo.AddCardsProvidersMapping @CardId = 105279, @ProviderId = 1, @CardProviderId = 'TRIBE-CARD-12345', @Created = SYSUTCDATETIME();
```

### 8.2 Verify the mapping
```sql
SELECT * FROM dbo.CardsProvidersMapping WITH (NOLOCK) WHERE CardId = 105279;
```

### 8.3 Resolve card to account via mapping
```sql
SELECT c.CardGuid, a.Gcid, m.CardProviderId
FROM dbo.CardsProvidersMapping m WITH (NOLOCK)
JOIN dbo.FiatCards c WITH (NOLOCK) ON c.Id = m.CardId
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = c.AccountId
WHERE m.CardId = 105279;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddCardsProvidersMapping | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddCardsProvidersMapping.sql*
