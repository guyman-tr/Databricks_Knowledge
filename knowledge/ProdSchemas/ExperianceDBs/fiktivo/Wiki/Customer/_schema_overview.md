# Customer Schema Overview

> Linked server abstraction layer - a single synonym providing local access to the eToro platform's Customer table for affiliate reporting and lookup procedures.

## Purpose

The Customer schema in the fiktivo database contains a single synonym that bridges the affiliate system to the eToro trading platform's customer data. The actual Customer.Customer table resides on a remote SQL Server instance (AO-REAL-DB-ROR linked server), and this synonym provides transparent local access so affiliate procedures can reference customer data without four-part linked server naming.

## Architecture

```
fiktivo Database (local)
    |
    | Customer.Customer (synonym)
    |
    v
AO-REAL-DB-ROR (linked server - read-only replica)
    |
    | [etoro].[Customer].[Customer] (remote table)
    v
eToro Trading Platform Customer Data
```

## Object Summary

| Object | Type | Role |
|--------|------|------|
| Customer.Customer | Synonym | Alias for [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] |

## Consumers

- dbo.SSRS_ICMarketsNetRevenue - reporting procedure
- dbo.GetCustomerAccountDetails - customer lookup procedure
