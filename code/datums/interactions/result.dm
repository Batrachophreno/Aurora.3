/datum/interaction_result
	/// One of the INTERACTION_RESULT_* defines.
	var/status = INTERACTION_RESULT_BLOCKED
	/// Optional human-readable reason for diagnostics or caller feedback.
	var/message
	/// Optional Aurora item interaction flags for execution callers.
	var/item_interact_flags = NONE
	/// Step that produced this result, when applicable.
	var/datum/interaction_step/step

/datum/interaction_result/New(status = INTERACTION_RESULT_BLOCKED, message, item_interact_flags = NONE, datum/interaction_step/step)
	src.status = status
	src.message = message
	src.item_interact_flags = item_interact_flags
	src.step = step

/datum/interaction_result/Destroy(force)
	step = null
	return ..()

/datum/interaction_result/proc/succeeded()
	return status == INTERACTION_RESULT_SUCCESS

/datum/interaction_result/proc/failed()
	return !succeeded()

/datum/interaction_result/proc/to_item_interact_flags()
	if(item_interact_flags)
		return item_interact_flags
	if(succeeded())
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING
