/datum/neoblob_cluster
	var/datum/neoblob_type/neoblob_type
	var/obj/structure/neoblob/core/core
	var/list/growths
	var/list/cores
	var/list/nodes
	var/list/factories
	var/list/resources
	var/list/minions
	var/faction
	var/spawned_at
	var/last_activity
	var/expansion_paused = FALSE
	var/destroying_cluster = FALSE

/datum/neoblob_cluster/New(var/datum/neoblob_type/new_type)
	..()
	neoblob_type = new_type
	growths = list()
	cores = list()
	nodes = list()
	factories = list()
	resources = list()
	minions = list()
	spawned_at = world.time
	last_activity = spawned_at
	if(neoblob_type)
		faction = neoblob_type.faction

/datum/neoblob_cluster/Destroy()
	SStgui.close_uis(src)
	neoblob_type = null
	core = null
	QDEL_LIST(growths)
	QDEL_LIST(cores)
	QDEL_LIST(nodes)
	QDEL_LIST(factories)
	QDEL_LIST(resources)
	QDEL_LIST(minions)
	return ..()

/datum/neoblob_cluster/proc/register_growth(var/obj/structure/neoblob/growth)
	if(!growth || QDELETED(growth))
		return FALSE
	if(growth.cluster && growth.cluster != src && !QDELETED(growth.cluster))
		growth.cluster.unregister_growth(growth)
	growth.cluster = src
	growths |= growth
	switch(growth.neoblob_role)
		if(NEOBLOB_ROLE_CORE)
			cores |= growth
			if(istype(growth, /obj/structure/neoblob/core))
				core = growth
		if(NEOBLOB_ROLE_SECONDARY_CORE)
			cores |= growth
		if(NEOBLOB_ROLE_NODE)
			nodes |= growth
		if(NEOBLOB_ROLE_RESOURCE)
			resources |= growth
		if(NEOBLOB_ROLE_FACTORY)
			factories |= growth
	if(!neoblob_type)
		neoblob_type = growth.strain
	if(!neoblob_type)
		neoblob_type = growth.ensure_strain()
	if(!faction && neoblob_type)
		faction = neoblob_type.faction
	last_activity = world.time
	return TRUE

/datum/neoblob_cluster/proc/unregister_growth(var/obj/structure/neoblob/growth)
	if(!growth)
		return FALSE
	growths -= growth
	cores -= growth
	nodes -= growth
	factories -= growth
	resources -= growth
	if(growth == core)
		core = null
	if(growth.cluster == src)
		growth.cluster = null
	last_activity = world.time
	if(growths && !length(growths) && !destroying_cluster)
		qdel(src)
	return TRUE

/datum/neoblob_cluster/proc/register_minion(var/mob/living/minion)
	if(!minion || QDELETED(minion))
		return FALSE
	minions |= minion
	last_activity = world.time
	return TRUE

/datum/neoblob_cluster/proc/unregister_minion(var/mob/living/minion)
	if(!minion)
		return FALSE
	minions -= minion
	last_activity = world.time
	return TRUE

/datum/neoblob_cluster/proc/destroy_cluster()
	if(destroying_cluster)
		return FALSE
	destroying_cluster = TRUE
	if(!QDELETED(core))
		qdel(core)
	qdel(src)

/datum/neoblob_cluster/proc/toggle_expansion_paused()
	expansion_paused = !expansion_paused
	last_activity = world.time
	return expansion_paused

/datum/neoblob_cluster/proc/get_master_core_area_name()
	if(!core || QDELETED(core))
		return "Unknown Area"
	return get_area_display_name(get_area(core))

/datum/neoblob_cluster/proc/get_master_core_coordinates()
	if(!core || QDELETED(core))
		return "Unknown"
	return "[core.x], [core.y], [core.z]"

/datum/neoblob_cluster/proc/get_admin_display_name()
	var/type_name = neoblob_type ? "[neoblob_type.name]" : "unknown type"
	return "[type_name] cluster at [get_master_core_area_name()] ([get_master_core_coordinates()])"

/datum/neoblob_cluster/ui_state(mob/user)
	return GLOB.always_state

/datum/neoblob_cluster/ui_interact(mob/user, datum/tgui/ui)
	if(!check_rights(R_DEBUG, FALSE, user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NeoblobClusterPanel", "Neoblob Cluster", 480, 260)
		ui.open()

/datum/neoblob_cluster/ui_data(mob/user)
	var/list/data = list()
	if(!check_rights(R_DEBUG, FALSE, user))
		return data

	data["neoblob_type"] = neoblob_type ? "[neoblob_type.name] ([neoblob_type.type])" : "None"
	data["master_area"] = get_master_core_area_name()
	data["master_coordinates"] = get_master_core_coordinates()
	data["growth_count"] = growths ? length(growths) : 0
	data["expansion_paused"] = expansion_paused
	data["destroyed"] = destroying_cluster
	data["has_core"] = !!(core && !QDELETED(core))

	return data

/datum/neoblob_cluster/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(!check_rights(R_DEBUG, FALSE, user))
		return

	switch(action)
		if("toggle_expansion")
			var/paused = toggle_expansion_paused()
			var/status = paused ? "paused" : "resumed"
			log_and_message_admins("[status] neoblob cluster expansion for [get_admin_display_name()]", user, core)
			return TRUE
		if("destroy_cluster")
			log_and_message_admins("destroyed neoblob cluster [get_admin_display_name()]", user, core)
			destroy_cluster()
			return TRUE
