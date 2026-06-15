---
name: feedback-command
description: "Generates a pre-filled URL to the Genie Code Feedback App when
  the user types @feedback or /feedback. Extracts question, answer, skill, and
  SQL query from the last conversation exchange and encodes them as URL query
  parameters for one-click feedback submission."
triggers:
  - feedback
  - "@feedback"
  - "/feedback"
  - rate this answer
  - submit feedback
required_tables:
  - main.de_output.de_output_genie_code_skill_feedback
version: 1
owner: "dataplatform"
---

# Feedback Command

## When to Use

Load when the user types `@feedback` or `/feedback` in the conversation. Generates a pre-filled URL to the Genie Code Feedback App using context from the last Q&A exchange.

## Scope

In scope: URL generation for feedback app pre-fill, query param encoding, conversation context extraction (question, answer summary, skill names, SQL query)
Out of scope: Feedback app UI code, Delta table schema management, app deployment, SQL Alert notifications
Last verified: 2026-06-04

## Critical Warnings

1. URLs exceeding ~2000 characters will be truncated by browsers — always cap answer at ~400 chars and query at ~500 chars to prevent silent data loss.
2. Failing to URL-encode special characters (single quotes, parentheses, ampersands) produces broken links that 404 or pre-fill garbled text.
3. The app resolves user_email via current_user() on the SQL warehouse — when using SP auth this resolves to the SP client ID, not the analyst email.

## Procedure

When triggered, generate a clickable markdown link to the feedback app with the last QA exchange pre-filled:

### Step 1 — Extract from conversation context

 Parameter | Source | Max length |
 --- | --- | --- |
 question | The user last substantive question (the message BEFORE the assistant last response) | ~300 chars |
 answer | Concise summary of the assistant last response — key finding/number/conclusion, not full text | ~400 chars |
 skill | Skills disclosed in the Skills used line. Comma-separated if multiple. Empty string if none. | ~200 chars |
 query | The main SQL query executed (if any). Truncate if needed. Empty string if no SQL was run. | ~500 chars |

### Step 2 — Build the URL

- Base URL: https://genie-code-feedback-5142916747090026.6.azure.databricksapps.com
- Query params: ?question=<url_encoded>&answer=<url_encoded>&skill=<url_encoded>&query=<url_encoded>
- URL-encode all parameter values (spaces to + or %20, special chars percent-encoded)

### Step 3 — Output format

Render as:

[Rate this answer](<full_url>)

Click to open the feedback app — just rate (1-5 stars) and optionally comment.

## Edge Cases

- No skills disclosed: Set skill param to empty string — the app field pre-fills blank, user can manually type what skill SHOULD have been used
- No SQL executed: Set query param to empty string — field stays empty
- Multi-skill response: Comma-separate skill names (the app Dashboard tab uses EXPLODE SPLIT to count each individually)
- Very long SQL: Truncate to the main SELECT statement, omit CTEs if needed to stay under limit

## Feedback Table Schema

Table: main.de_output.de_output_genie_code_skill_feedback (EXTERNAL, ADLS-backed)
Location: abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Genie_Code/Skill_Feedback/

Columns: id BIGINT (IDENTITY), user_email STRING, question STRING, answer_summary STRING, rating INT (1-5), comment STRING, skill_used STRING (comma-separated), notebook_url STRING, generated_query STRING, created_at TIMESTAMP, UpdateDate TIMESTAMP
