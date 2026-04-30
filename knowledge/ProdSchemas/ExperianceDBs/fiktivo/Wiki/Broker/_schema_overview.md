# Broker Schema Overview

> SQL Server Service Broker queue activation procedures for the affiliate commission event pipeline - dequeuing credit events, registration/lead notifications, and cleaning up conversation endpoints. **Being decommissioned** (PART-4246).

## Purpose

The Broker schema contains SQL Server Service Broker activation procedures that form the real-time messaging layer of the affiliate commission system. Service Broker provides asynchronous, reliable message delivery between the eToro trading platform (which generates events like registrations and credits) and the affiliate service (which processes commissions). Each procedure is paired with a Service Broker queue and activated when messages arrive.

**DECOMMISSIONING STATUS**: As of April 2025 (PART-4246 - DisableAffiliateServiceBroker), the Service Broker infrastructure is being phased out. actInitiator is already disabled. The replacement architecture uses AKS microservices (e.g., aff-clicksimp) and the ADF batch pipeline (BILoad schema) for the same commission processing workflows.

## Architecture

```
eToro Platform Event Sources
    |
    +-- Customer.RegisterReal/Demo --> Broker.queDynamics
    |                                      |
    |                                      v
    |                               Broker.actDynamics
    |                                      |
    |                                      v
    |                               Affiliate Server (lead tracking)
    |
    +-- Credit Events (deposits) --> Broker.queAffiliateTraderCreditReceiver
    |                                      |
    |                                      v
    |                               Broker.actAffiliateTraderCredit
    |                                      |
    |                                      v
    |                               Affiliate Service (commission calc)
    |
    +-- Dialog Cleanup          --> Broker.queInitiator
                                       |
                                       v
                                Broker.actInitiator (DISABLED)
```

## Object Summary

| Object | Type | Role | Status |
|--------|------|------|--------|
| actAffiliateTraderCredit | SP | Dequeues credit/deposit events for commission processing | Active |
| actDynamics | SP | Dequeues registration/lead events for affiliate tracking | Active |
| actInitiator | SP | Drains EndDialog messages for conversation cleanup | **DISABLED** (PART-4246) |

## Service Broker Queues (Referenced but not in SSDT)

| Queue | Consumer | Message Type |
|-------|----------|-------------|
| Broker.queAffiliateTraderCreditReceiver | actAffiliateTraderCredit | Affiliate trader credit event XML |
| Broker.queDynamics | actDynamics | Lead/registration event XML |
| Broker.queInitiator | actInitiator (disabled) | EndDialog system messages |

## Key Design Patterns

- **Single-message dequeue**: Each procedure RECEIVEs TOP(1) per invocation. External caller loops.
- **END CONVERSATION WITH CLEANUP**: Immediately frees conversation resources instead of waiting for normal lifecycle.
- **EXISTS guard**: actDynamics checks queue non-empty before starting a transaction.
- **Stale endpoint cleanup**: actAffiliateTraderCredit also cleans up 'CD' state conversations in sys.conversation_endpoints.

## Decommissioning Notes (PART-4246)

- actInitiator: Already disabled via RETURN statement (Apr 2025, Noga)
- Comment: "Before dropping PART-4246_DisableAffiliateServiceBroker"
- The replacement for real-time events is the AKS microservice architecture
- The replacement for batch processing is the ADF pipeline (BILoad schema)
- actAffiliateTraderCredit and actDynamics are still in the codebase but may be decommissioned next

## JIRA References

- **PART-4246**: DisableAffiliateServiceBroker - decommissioning the Service Broker infrastructure (Apr 2025, Noga)
