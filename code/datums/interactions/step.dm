ABSTRACT_TYPE(/datum/interaction_step)

/datum/interaction_step
	/// Stable id for diagnostics and future execution routing.
	var/id
	/// Short player-facing action name.
	var/name
	/// Broad category, such as construction or deconstruction.
	var/category = INTERACTION_CATEGORY_GENERAL
	/// Higher priority steps are selected first.
	var/priority = 0
	/// Optional complete hint text for consumers that do not need to compose requirements.
	var/hint_text
	/// Requirements are ANDed by the base check.
	var/list/requirements
	/// Query-only steps are not execution-authoritative yet.
	var/query_only = FALSE
	/// Aurora interaction flags returned by successful execution.
	var/item_interact_flags = ITEM_INTERACT_SUCCESS

/datum/interaction_step/New(id, name, category, priority, hint_text, list/requirements)
	if(!isnull(id))
		src.id = id
	if(!isnull(name))
		src.name = name
	if(!isnull(category))
		src.category = category
	if(!isnull(priority))
		src.priority = priority
	if(!isnull(hint_text))
		src.hint_text = hint_text
	if(requirements)
		src.requirements = requirements.Copy()

/datum/interaction_step/Destroy(force)
	QDEL_LIST(requirements)
	requirements = null
	return ..()

/datum/interaction_step/proc/add_requirement(datum/interaction_requirement/requirement)
	LAZYADD(requirements, requirement)
	return requirement

/datum/interaction_step/proc/is_visible(datum/interaction_context/context)
	return TRUE

/datum/interaction_step/proc/check_requirements(datum/interaction_context/context)
	for(var/datum/interaction_requirement/requirement as anything in requirements)
		if(!requirement.is_met(context))
			var/datum/interaction_result/failure = requirement.get_failure(context)
			failure.step = src
			return failure
	return new /datum/interaction_result(INTERACTION_RESULT_SUCCESS, step = src)

/datum/interaction_step/proc/get_missing_requirement_hints(datum/interaction_context/context)
	. = list()
	for(var/datum/interaction_requirement/requirement as anything in requirements)
		if(requirement.is_met(context))
			continue
		var/requirement_hint = requirement.render_hint(context)
		if(requirement_hint)
			. += requirement_hint

/datum/interaction_step/proc/try_execute(datum/interaction_context/context)
	if(query_only)
		return new /datum/interaction_result(INTERACTION_RESULT_NOT_IMPLEMENTED, "This interaction is query-only.", ITEM_INTERACT_BLOCKING, src)
	return new /datum/interaction_result(INTERACTION_RESULT_NOT_IMPLEMENTED, "This interaction has not been implemented.", ITEM_INTERACT_BLOCKING, src)

/datum/interaction_step/proc/render_hint(datum/interaction_context/context)
	return hint_text || name

/datum/interaction_step/proc/render_debug(datum/interaction_context/context)
	var/list/missing = get_missing_requirement_hints(context)
	return "[id || type] ([category], priority [priority]) - [length(missing) ? "missing [english_list(missing)]" : "available"]"
