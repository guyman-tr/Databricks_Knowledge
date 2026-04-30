# Dictionary.ServiceType

> Lookup table classifying the types of affiliate service events that trigger commission processing - Credit, Registration, or Sale.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ServiceTypeID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ServiceType classifies the three fundamental event categories that trigger affiliate commission processing. Each commission-generating event falls into one of these categories: a financial credit event (deposit or bonus), a customer registration event, or a trading sale event. This classification determines which commission calculation pipeline processes the event.

Without this table, the commission event router would not know which processing pipeline to invoke for each event. Credit events follow the deposit/chargeback pipeline, registration events follow the signup attribution pipeline, and sale events follow the trading activity pipeline.

This is static reference data used by the commission event state logging system. The AffiliateCommission.CreditEventStateLog table stores ServiceTypeID alongside EventStateID to classify events by both their category and their processing state.

---

## 2. Business Logic

### 2.1 Commission Event Categories

**What**: Three fundamental event categories that map to distinct commission calculation pipelines.

**Columns/Parameters Involved**: `ServiceTypeID`, `Description`

**Rules**:
- ID=1 (Credit) covers financial credit events: deposits, bonuses, and chargebacks. Processed through the credit commission pipeline
- ID=2 (Registration) covers customer signup events. Processed through the registration attribution pipeline (CPA/CPL models)
- ID=3 (Sale) covers trading activity events. Processed through the revenue share / spread-based commission pipeline
- Each service type maps to a different commission model: CPA (registration), revenue share (sale), or deposit-based (credit)

---

## 3. Data Overview

| ServiceTypeID | Description | Meaning |
|---|---|---|
| 1 | Credit | Financial credit event - customer deposit, platform bonus, or chargeback. The most common event type. Triggers deposit-based commission calculations where affiliates earn a percentage or fixed amount per deposit |
| 2 | Registration | Customer registration event. Triggers CPA (Cost Per Acquisition) or CPL (Cost Per Lead) commission models where affiliates earn a one-time payment for each qualified signup |
| 3 | Sale | Trading activity or sale event. Triggers revenue share or spread-based commission models where affiliates earn ongoing commissions based on their referred customers' trading activity |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ServiceTypeID | int | NO | - | VERIFIED | Primary key identifying the commission event category. Values: 1=Credit, 2=Registration, 3=Sale. See [Service Type](../../_glossary.md#service-type) for full definitions. Determines which commission calculation pipeline processes the event. |
| 2 | Description | nvarchar(250) | NO | - | VERIFIED | Human-readable label for the service type. Used in event state logs and commission processing diagnostics. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.CreditEventStateLog | ServiceTypeID | Implicit FK | Classifies each event state log entry by service type |
| AffiliateCommission.InsertCreditEventStateLog | Parameter | Lookup | Tags state log entries with service type when inserting |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditEventStateLog | Table | Stores ServiceTypeID for each event log entry |
| AffiliateCommission.InsertCreditEventStateLog | Stored Procedure | WRITER - inserts event log entries with service type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryServiceType | CLUSTERED PK | ServiceTypeID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all service types
```sql
SELECT ServiceTypeID, Description
FROM Dictionary.ServiceType WITH (NOLOCK)
ORDER BY ServiceTypeID
```

### 8.2 Count event state logs by service type
```sql
SELECT st.ServiceTypeID, st.Description, COUNT(*) AS LogCount
FROM AffiliateCommission.CreditEventStateLog log WITH (NOLOCK)
JOIN Dictionary.ServiceType st WITH (NOLOCK) ON log.ServiceTypeID = st.ServiceTypeID
GROUP BY st.ServiceTypeID, st.Description
ORDER BY LogCount DESC
```

### 8.3 View recent events with service type and state
```sql
SELECT TOP 20
    log.CreditEventID,
    st.Description AS ServiceType,
    es.Description AS EventState,
    es.GroupID AS ProcessingStage
FROM AffiliateCommission.CreditEventStateLog log WITH (NOLOCK)
JOIN Dictionary.ServiceType st WITH (NOLOCK) ON log.ServiceTypeID = st.ServiceTypeID
JOIN Dictionary.EventState es WITH (NOLOCK) ON log.EventStateID = es.EventStateID
ORDER BY log.CreditEventID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ServiceType | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.ServiceType.sql*
