---
object: Dealing_PreviouslyIdentifiedAbusers
lineage_type: DWH Detection → Alert Table
production_source: DWH_dbo.Dim_Customer (new registrations today vs. hardcoded name list)
---

# Dealing_PreviouslyIdentifiedAbusers — Lineage Map

## Data Flow

```
SP BODY: hardcoded INSERT INTO #Names (~120 FirstName/LastName pairs)
                │
DWH_dbo.Dim_Customer (RegisteredReal ∈ [@Date, @NextDate))
                │ → #CIDs_Data (FirstName, LastName, RegisteredReal, RealCID)
                │
INNER JOIN #Names ON FirstName + LastName (exact match)
                │ → #Abusers (Date, FirstName, LastName, CID, RegisteredReal)
                │
DWH_dbo.Dim_Date (DateKey = @DateID) → LEFT JOIN for sentinel row
                │
                ▼
        Dealing_PreviouslyIdentifiedAbusers (+ Dealing_PreviouslyIdentifiedAbusers_Email)
```

## Production Source
Customer registration data from DWH_dbo.Dim_Customer (mirrors production Trade.dbo.Customers).

## Refresh Schedule
Daily — SP_PreviouslyIdentifiedAbusers, OpsDB Priority 0, ProcessType 1 (SQL). Active.
