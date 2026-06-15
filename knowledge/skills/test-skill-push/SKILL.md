---
id: test-skill-push
name: "Test Skill Push"
description: "Phony test skill for validating the skill-push slash command end-to-end. Covers nothing real — exists only to exercise the push workflow, branch naming validation, skill-creator CI gate, and PR creation against the DataPlatform repo. Load when the user explicitly references skill-push end-to-end testing or DD-0000 dry-run validation. Safe to delete after the test PR is reviewed."
triggers:
  - skill-push test
  - phony skill
  - DD-0000 dry-run
  - skill-push end-to-end
required_tables:
  - main.test_sandbox.test_skill_push_fixture
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-27"
---

# Test Skill Push

## When to Use
Load only when the user explicitly references end-to-end testing of the skill-push
slash command, the DD-0000 dry-run flow, or wants to verify branch naming and PR
creation mechanics against the DataPlatform repository. This skill answers zero real
business questions and should never trigger on revenue, payments, customer, or any
substantive analytical prompt.

## Scope
In scope: main.test_sandbox.test_skill_push_fixture (phony placeholder table), the literal string "test-skill-push", the skill-push workflow trigger.
Out of scope: Any real analytical or business question. Any non-test skill. Anything the user actually wants answered.
Last verified: 2026-05-27

## Critical Warnings
1. Do not let this skill match real business questions. If it appears in find_skills results alongside a real domain skill for a real prompt, that is a Tier 1 false positive — narrow the description further or delete the skill.
2. The referenced table main.test_sandbox.test_skill_push_fixture does not exist in Unity Catalog. Any SQL drafted off this skill will fail at parse time. That is by design — Tier 2 aggregate inflation cannot occur because no rows ever return.
3. Delete this skill folder once the skill-push workflow has been validated end-to-end against the DD-0000_test_skill_push branch. Long-lived test skills pollute the embedding corpus — Tier 3 hygiene concern.

## Core Concepts

| Concept | What It Is | Aliases |
| --- | --- | --- |
| **skill-push** | The slash command being tested by this skill's existence | push to dataplatform, ship skill |
| **DD-0000** | The placeholder Jira ticket used for dry-run pushes | placeholder ticket, dry-run ticket |
| **CI gate** | The skill-creator validation phase that runs before any git operation | phase 1 gate, validation gate |
| **Anti-swap check** | The Phase 7 verification that PR head, base, and title each match the canonical strings | head-ref check, title check |

## Why This Exists

The skill-push workflow has eight phases and several anti-swap checkpoints (branch name vs commit subject vs PR title). Testing it on a real domain skill is risky because a malformed PR could land on dev and corrupt the data-skills corpus. This skill is the safe fixture: minimal content, obviously phony triggers, harmless if accidentally merged, trivial to revert.

When the test passes, delete this skill folder in a follow-up commit on the same branch, or open a separate cleanup PR. Either way the deletion should also flow through skill-push so the round-trip is exercised both ways.
