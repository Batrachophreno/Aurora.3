/datum/shuttle/autodock/multi
	/// Tags of all the landmarks that this should can go to.
	/// Can contain nested lists, as it is flattened before use.
	var/list/destination_tags
	var/list/destinations_cache = list()
	var/last_cache_rebuild_generation = -1
	category = /datum/shuttle/autodock/multi

/datum/shuttle/autodock/multi/proc/set_destination(var/destination_key, mob/user)
	if(moving_status != SHUTTLE_IDLE || process_state != IDLE_STATE || in_use)
		return
	var/obj/effect/shuttle_landmark/destination = destinations_cache[destination_key]
	if(destination && !QDELETED(destination))
		next_location = destination

/datum/shuttle/autodock/multi/proc/get_destinations()
	if(last_cache_rebuild_generation != SSshuttle.landmark_registry_generation)
		build_destinations_cache()
	return destinations_cache

/datum/shuttle/autodock/multi/proc/build_destinations_cache()
	last_cache_rebuild_generation = SSshuttle.landmark_registry_generation
	destinations_cache.Cut()
	destination_tags = flatten_list(destination_tags)
	for(var/destination_tag in destination_tags)
		var/obj/effect/shuttle_landmark/landmark = SSshuttle.get_landmark(destination_tag)
		if(istype(landmark))
			destinations_cache["[landmark.name]"] = landmark

//Antag play announcements when they leave/return to their home area
/datum/shuttle/autodock/multi/antag
	warmup_time = 10 SECONDS //replaced the old move cooldown
	//This variable is type-abused initially: specify the landmark_tag, not the actual landmark.
	var/obj/effect/shuttle_landmark/home_waypoint

	var/cloaked = TRUE
	var/returned = FALSE
	var/return_warning_cooldown
	var/announcer
	var/arrival_message
	var/departure_message

	category = /datum/shuttle/autodock/multi/antag

/datum/shuttle/autodock/multi/antag/New()
	..()
	if(home_waypoint)
		home_waypoint = SSshuttle.get_landmark(home_waypoint)
	else
		home_waypoint = current_location

/datum/shuttle/autodock/multi/antag/shuttle_moved()
	if(current_location == home_waypoint)
		announce_arrival()
	else if(next_location == home_waypoint)
		announce_departure()
	..()

/datum/shuttle/autodock/multi/antag/arrived(var/user)
	if(current_location == home_waypoint)
		returned = TRUE
	return ..(user)

/datum/shuttle/autodock/multi/antag/launch(var/user)
	if(returned)
		if(user)
			to_chat(user, SPAN_WARNING("You don't have enough fuel for another launch!"))
		return FALSE //Nada, can't go back.
	return ..(user)

/datum/shuttle/autodock/multi/antag/proc/announce_departure()
	if(cloaked || isnull(departure_message))
		return
	command_announcement.Announce(departure_message, announcer || "[SSatlas.current_map.boss_name]")

/datum/shuttle/autodock/multi/antag/proc/announce_arrival()
	if(cloaked || isnull(arrival_message))
		return
	command_announcement.Announce(arrival_message, announcer || "[SSatlas.current_map.boss_name]")
