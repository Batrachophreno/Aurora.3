/datum/interaction_context
	/// The mob querying or attempting the interaction.
	var/mob/user
	/// The atom being queried or manipulated.
	var/atom/target
	/// Item in the active hand, if any.
	var/obj/item/active_item
	/// Item in the inactive hand, if any.
	var/obj/item/inactive_item
	/// Normalized BYOND click modifier list.
	var/list/modifiers
	/// One of the INTERACTION_QUERY_* defines.
	var/query_mode = INTERACTION_QUERY_EXAMINE
	/// Cached adjacency for cheap consumers.
	var/is_adjacent = FALSE

/datum/interaction_context/New(mob/user, atom/target, obj/item/active_item, list/modifiers, query_mode = INTERACTION_QUERY_EXAMINE)
	src.user = user
	src.target = target
	src.active_item = active_item || user?.get_active_hand()
	src.inactive_item = user?.get_inactive_hand()
	src.modifiers = modifiers
	src.query_mode = query_mode
	src.is_adjacent = user && target && target.Adjacent(user)

/datum/interaction_context/Destroy(force)
	user = null
	target = null
	active_item = null
	inactive_item = null
	modifiers = null
	return ..()

/datum/interaction_context/proc/is_execution()
	return query_mode == INTERACTION_QUERY_EXECUTION

/datum/interaction_context/proc/is_alt_click()
	return text2num(LAZYACCESS(modifiers, ALT_CLICK))

/datum/interaction_context/proc/is_left_click()
	return !is_alt_click()
