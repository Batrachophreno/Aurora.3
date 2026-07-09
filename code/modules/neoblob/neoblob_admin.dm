/proc/get_spawnable_neoblob_types()
	var/list/spawnable_types = list()
	for(var/type_path in subtypesof(/datum/neoblob_type))
		if(is_abstract(type_path))
			continue
		var/datum/neoblob_type/neoblob_type = type_path
		var/core_path = initial(neoblob_type.core_path)
		if(!ispath(core_path, /obj/effect/neoblob/core))
			continue
		spawnable_types += type_path
	return spawnable_types

/proc/spawn_neoblob_type_at_turf(var/turf/spawn_turf, var/neoblob_type_path = /datum/neoblob_type/astroclast)
	if(!spawn_turf || !ispath(neoblob_type_path, /datum/neoblob_type))
		return null
	if(is_abstract(neoblob_type_path))
		return null

	var/datum/neoblob_type/neoblob_type = new neoblob_type_path()
	var/core_path = neoblob_type.core_path
	if(!ispath(core_path, /obj/effect/neoblob/core))
		qdel(neoblob_type)
		return null

	var/obj/effect/neoblob/core/spawned_core = new core_path(spawn_turf, null, neoblob_type)
	return spawned_core

/client/proc/spawn_neoblob()
	set name = "Spawn Neoblob"
	set desc = "Spawn a neoblob core by type."
	set category = "Debug"

	if(!check_rights(R_SPAWN))
		return

	var/list/spawnable_types = get_spawnable_neoblob_types()
	if(!length(spawnable_types))
		to_chat(src, SPAN_WARNING("No spawnable neoblob types are available."))
		return

	var/neoblob_type_path = tgui_input_list(src, "Select a neoblob type to spawn.", "Spawn Neoblob", spawnable_types)
	if(!neoblob_type_path)
		return

	var/turf/spawn_turf = get_turf(mob)
	if(!spawn_turf)
		to_chat(src, SPAN_WARNING("Unable to find a valid turf to spawn the neoblob."))
		return

	var/obj/effect/neoblob/core/spawned_core = spawn_neoblob_type_at_turf(spawn_turf, neoblob_type_path)
	if(!spawned_core)
		to_chat(src, SPAN_WARNING("Failed to spawn [neoblob_type_path]."))
		return

	log_and_message_admins("spawned neoblob type [neoblob_type_path] at ([spawn_turf.x],[spawn_turf.y],[spawn_turf.z])", mob, spawn_turf)
	feedback_add_details("admin_verb", "SNB")

/client/proc/manage_neoblob_clusters()
	set name = "Manage Neoblob Clusters"
	set desc = "Open the admin control panel for an active neoblob cluster."
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return

	var/list/cluster_choices = list()
	var/list/cluster_by_choice = list()
	for(var/obj/effect/neoblob/core/master_core in world)
		if(master_core.neoblob_role != NEOBLOB_ROLE_CORE)
			continue
		if(!master_core.cluster || QDELETED(master_core.cluster))
			continue
		if(master_core.cluster.core != master_core)
			continue
		var/choice_name = "\ref[master_core.cluster] - [master_core.cluster.get_admin_display_name()]"
		cluster_choices += choice_name
		cluster_by_choice[choice_name] = master_core.cluster

	if(!length(cluster_choices))
		to_chat(src, SPAN_WARNING("No active neoblob clusters are available."))
		return

	var/choice = tgui_input_list(src, "Select a neoblob cluster to manage.", "Manage Neoblob Clusters", cluster_choices)
	var/datum/neoblob_cluster/chosen_cluster = cluster_by_choice[choice]
	if(!chosen_cluster || QDELETED(chosen_cluster))
		to_chat(src, SPAN_WARNING("The selected neoblob cluster is no longer valid."))
		return

	chosen_cluster.ui_interact(mob)
	feedback_add_details("admin_verb", "MNB")
