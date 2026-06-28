---
name: domain-bizops

description: Contact-center chatbot and deflection KPIs from CRM silver layer.

required_tables:
  - main.crm.silver_conversations
  - main.crm.silver_messages
  - main.crm.silver_case_events

version: 1
owner: dataplatform
---

# Contact Center Deflection Performance

## Anchor Tables
- main.crm.silver_conversations
- main.crm.silver_messages
- main.crm.silver_case_events

## Scope
Measure chatbot containment, escalation, and agent handoff behavior across channels.

## Metrics
- deflection_rate = deflected_cases / total_cases
- escalation_rate = escalated_cases / total_cases