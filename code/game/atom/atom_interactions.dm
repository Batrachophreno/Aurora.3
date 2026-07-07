/**
 * Builds a short-lived context for interaction step queries or attempts.
 */
/atom/proc/build_interaction_context(mob/user, obj/item/active_item, list/modifiers, query_mode = INTERACTION_QUERY_EXAMINE)
	return new /datum/interaction_context(user, src, active_item, modifiers, query_mode)

/**
 * Override this on targets to append local interaction steps.
 *
 * Query implementations must not mutate state, consume resources, send chat, play sounds, or start timers.
 */
/atom/proc/gather_local_interaction_steps(datum/interaction_context/context, list/steps)
	return

/**
 * Gathers, externally extends, and sorts queryable interaction steps for this atom.
 */
/atom/proc/gather_interaction_steps(datum/interaction_context/context, list/steps)
	if(!steps)
		steps = list()
	gather_local_interaction_steps(context, steps)
	SEND_SIGNAL(src, COMSIG_ATOM_GATHER_INTERACTION_STEPS, context, steps)
	return sort_interaction_steps(steps)

/**
 * Returns the highest-priority visible step whose requirements are currently met.
 */
/atom/proc/select_interaction_step(datum/interaction_context/context, list/steps)
	if(!steps)
		return
	for(var/datum/interaction_step/step as anything in steps)
		if(!step.is_visible(context))
			continue
		var/datum/interaction_result/check = step.check_requirements(context)
		var/matches = check.succeeded()
		qdel(check)
		if(matches)
			return step

/**
 * Opt-in execution helper for migrated callers. This is not wired into legacy atom clicks yet.
 */
/atom/proc/try_interaction_steps(mob/living/user, obj/item/active_item, list/modifiers)
	var/datum/interaction_context/context = build_interaction_context(user, active_item, modifiers, INTERACTION_QUERY_EXECUTION)
	var/list/steps = gather_interaction_steps(context)
	var/datum/interaction_step/selected_step = select_interaction_step(context, steps)
	var/datum/interaction_result/result
	if(selected_step)
		result = selected_step.try_execute(context)
	else
		result = new /datum/interaction_result(INTERACTION_RESULT_NO_MATCH, "No matching interaction step was found.")
	if(result)
		result.step = null
	QDEL_LIST(steps)
	qdel(context)
	return result

/**
 * Renders visible interaction steps in a category for examine or other broad consumers.
 */
/atom/proc/render_interaction_hints(mob/user, category, query_mode = INTERACTION_QUERY_EXAMINE)
	. = list()
	var/datum/interaction_context/context = build_interaction_context(user, null, null, query_mode)
	var/list/steps = gather_interaction_steps(context)
	for(var/datum/interaction_step/step as anything in steps)
		if(step.category != category || !step.is_visible(context))
			continue
		var/hint = step.render_hint(context)
		if(hint)
			. += hint
	QDEL_LIST(steps)
	qdel(context)

/**
 * Dumps step selection details for VV/proccall diagnostics.
 */
/atom/proc/debug_interaction_steps(mob/user, obj/item/active_item, list/modifiers, query_mode = INTERACTION_QUERY_DIAGNOSTIC)
	. = list()
	var/datum/interaction_context/context = build_interaction_context(user, active_item, modifiers, query_mode)
	var/list/steps = gather_interaction_steps(context)
	for(var/datum/interaction_step/step as anything in steps)
		. += step.render_debug(context)
	QDEL_LIST(steps)
	qdel(context)

/proc/sort_interaction_steps(list/steps)
	if(length(steps) < 2)
		return steps

	var/list/sorted_steps = list()
	for(var/datum/interaction_step/step as anything in steps)
		var/inserted = FALSE
		for(var/i = 1 to length(sorted_steps))
			var/datum/interaction_step/existing_step = sorted_steps[i]
			if(step.priority > existing_step.priority)
				sorted_steps.Insert(i, step)
				inserted = TRUE
				break
		if(!inserted)
			sorted_steps += step

	steps.Cut()
	steps += sorted_steps
	return steps
