/* Query modes for interaction contexts. */
#define INTERACTION_QUERY_EXAMINE "examine"
#define INTERACTION_QUERY_SCREEN_TIP "screen_tip"
#define INTERACTION_QUERY_EXECUTION "execution"
#define INTERACTION_QUERY_DIAGNOSTIC "diagnostic"

/* Broad categories consumed by examine, screen tips, diagnostics, and future guides. */
#define INTERACTION_CATEGORY_GENERAL "general"
#define INTERACTION_CATEGORY_CONSTRUCTION "construction"
#define INTERACTION_CATEGORY_DECONSTRUCTION "deconstruction"
#define INTERACTION_CATEGORY_REPAIR "repair"
#define INTERACTION_CATEGORY_WIRING "wiring"
#define INTERACTION_CATEGORY_CONFIGURATION "configuration"

/* Structured result statuses. */
#define INTERACTION_RESULT_SUCCESS "success"
#define INTERACTION_RESULT_NO_MATCH "no_match"
#define INTERACTION_RESULT_MISSING_ACTIVE_ITEM "missing_active_item"
#define INTERACTION_RESULT_MISSING_INACTIVE_ITEM "missing_inactive_item"
#define INTERACTION_RESULT_WRONG_TARGET_STATE "wrong_target_state"
#define INTERACTION_RESULT_BLOCKED "blocked"
#define INTERACTION_RESULT_INTERRUPTED "interrupted"
#define INTERACTION_RESULT_STATE_CHANGED "state_changed"
#define INTERACTION_RESULT_NOT_IMPLEMENTED "not_implemented"
