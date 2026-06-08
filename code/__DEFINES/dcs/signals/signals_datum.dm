// Datum signals. Format:
// When the signal is called: (signal arguments)
// All signals send the source datum of the signal as the first argument

// /datum signals
/// when a component is added to a datum: (/datum/component)
#define COMSIG_COMPONENT_ADDED "component_added"
/// before a component is removed from a datum because of ClearFromParent: (/datum/component)
#define COMSIG_COMPONENT_REMOVING "component_removing"

/// before a datum's Destroy() is called: (force), returning a nonzero value will cancel the qdel operation
/// you should only be using this if you want to block deletion
/// that's the only functional difference between it and COMSIG_QDELETING, outside setting QDELETING to detect
#define COMSIG_PREQDELETED "parent_preqdeleted"
/// just before a datum's Destroy() is called: (force), at this point none of the other components chose to interrupt qdel and Destroy will be called
#define COMSIG_QDELETING "parent_qdeleting"
/// from datum ui_act (usr, action)
#define COMSIG_UI_ACT "COMSIG_UI_ACT"

/// Camera map manager signals.
#define COMSIG_CAMERA_MAPNAME_ASSIGNED "camera_manager_mapname_assigned"
#define COMSIG_CAMERA_REGISTER_UI "camera_manager_register_ui"
#define COMSIG_CAMERA_UNREGISTER_UI "camera_manager_unregister_ui"
#define COMSIG_CAMERA_SET_TARGET "camera_manager_set_target"
#define COMSIG_CAMERA_CLEAR "camera_manager_clear_target"
#define COMSIG_CAMERA_REFRESH "camera_manager_refresh"

/// fires on the target datum when an element is attached to it (/datum/element)
#define COMSIG_ELEMENT_ATTACH "element_attach"
/// fires on the target datum when an element is attached to it  (/datum/element)
#define COMSIG_ELEMENT_DETACH "element_detach"
