# Data Dictionary — BPI 2012 Retail Loan Dataset

## Table: cases
| Column | Type | Description |
|--------|------|-------------|
| case_id | integer | Unique loan application identifier |
| concept:name | string | Duplicate of case_id (process mining artifact) |
| REG_DATE | timestamp | Application registration date |
| AMOUNT_REQ | float | Loan amount requested by applicant (EUR) |

**Data quality note:** Case ID 90 has null REG_DATE and AMOUNT_REQ.
Excluded from all analysis — not present in events table (0.2% of cases).

## Table: events
| Column | Type | Description |
|--------|------|-------------|
| case_id | integer | Links to cases table |
| activity | string | Name of the process stage or action |
| lifecycle | string | SCHEDULE (system-queued) or COMPLETE (human-finished) |
| resource | integer | Agent ID who handled the event |
| ts | timestamp | Event timestamp |

**Data quality note:** 2,633 events (16.5%) have null resource.
These are SCHEDULE lifecycle events — system-created before agent assignment.
Excluded from resource workload analysis only.

## Table: stage_durations
| Column | Type | Description |
|--------|------|-------------|
| case_id | integer | Links to cases table |
| activity | string | Stage name |
| start_ts | timestamp | Task start timestamp |
| end_ts | timestamp | Task completion timestamp |
| duration_minutes | float | Task handling time in minutes (touch time only) |

**Data quality note:** All A_ prefix activities show 0 duration.
This is correct — automated system decisions with no human handling time.
Bottleneck analysis uses W_ prefix stages only.

## Activity Reference
| Original (Dutch) | English Translation | Type |
|-----------------|---------------------|------|
| A_SUBMITTED | Application Submitted | Automated |
| A_PREACCEPTED | Pre-Accepted | Automated |
| A_ACCEPTED | Formally Accepted | Automated |
| A_FINALIZED | Finalized | Automated |
| A_ACTIVATED | Loan Activated / Funded | Automated |
| A_DECLINED | Declined | Automated |
| A_CANCELLED | Cancelled | Automated |
| W_Valideren aanvraag | Validate Application | Human Task |
| W_Nabellen offertes | Offer Follow-Up Calls | Human Task |
| W_Completeren aanvraag | Complete Application Docs | Human Task |
| W_Nabellen incomplete dossiers | Chase Incomplete Files | Human Task |
| W_Afhandelen leads | Handle Leads | Human Task |
| W_Beoordelen fraude | Fraud Assessment | Human Task |
