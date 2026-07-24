//shuttle moving state defines are in setup.dm

/datum/shuttle
	var/name = ""
	/// Immutable registry and linkage identity. Defaults to the initial display name.
	var/shuttle_id
	/// Warmup duration in deciseconds.
	var/warmup_time = 0
	var/moving_status = SHUTTLE_IDLE
	/// Result and diagnostic state for the most recent movement operation.
	var/movement_result = SHUTTLE_MOVE_IDLE
	var/movement_error
	var/movement_phase = "idle"
	/// Persistent string diagnostics for the latest operation; safe if its landmarks are later deleted.
	var/movement_origin_tag
	var/movement_destination_tag
	var/movement_translation_size = 0
	/// Invalidates delayed callbacks from older or cancelled launches.
	var/launch_generation = 0
	var/warmup_timer
	var/obj/effect/shuttle_landmark/movement_origin
	var/obj/effect/shuttle_landmark/movement_destination
	var/obj/effect/shuttle_landmark/movement_interim
	var/list/pending_landmarks = list()
	var/datum/callback/movement_completion_callback

	var/list/shuttle_area //can be both single area type or a list of areas
	var/obj/effect/shuttle_landmark/current_location //This variable is type-abused initially: specify the landmark_tag, not the actual landmark.
	var/list/shuttle_computers = list()

	var/arrive_time = 0	//the time at which the shuttle arrives when long jumping
	var/flags = 0
	var/process_state = IDLE_STATE //Used with SHUTTLE_FLAGS_PROCESS, as well as to store current state.
	var/category = /datum/shuttle
	var/multiz = 0	//how many multiz levels, starts at 0

	var/ceiling_type = /turf/simulated/floor/airless/ceiling

	var/sound_takeoff = 'sound/effects/shuttle_takeoff.ogg'
	var/sound_landing = 'sound/effects/shuttle_landing.ogg'

	var/knockdown = TRUE //whether shuttle downs non-buckled_to people when it moves

	/**
	 * This shuttle will/won't be initialised automatically.
	 * If set to `TRUE`, you are responsible for initialzing the shuttle manually.
	 * Useful for shuttles that are initialed by map_template loading, or shuttles that are created in-game or not used.
	 */
	var/defer_initialisation = FALSE
	var/logging_home_tag   //Whether in-game logs will be generated whenever the shuttle leaves/returns to the landmark with this landmark_tag.
	var/logging_access     //Controls who has write access to log-related stuff; should correlate with pilot access.

	var/mothershuttle //immutable shuttle_id of mothership
	var/motherdock    //tag of mothershuttle landmark, defaults to starting location

	var/squishes = TRUE //decides whether or not things get squished when it moves.
	var/cargo_elevator = FALSE // Snowflake variable for the cargo elevator. Decides whether you will take fall damage or not

/datum/shuttle/New(_name, var/obj/effect/shuttle_landmark/initial_location)
	..()
	if(_name)
		src.name = _name
	if(!shuttle_id)
		shuttle_id = name
	if(!length(shuttle_id))
		CRASH("A shuttle was created without an immutable shuttle_id.")

	var/list/areas = list()
	if(!islist(shuttle_area))
		shuttle_area = list(shuttle_area)
	for(var/T in shuttle_area)
		var/area/A = locate(T)
		if(!istype(A))
			CRASH("Shuttle \"[name]\" couldn't locate area [T].")
		areas += A
		RegisterSignal(A, COMSIG_QDELETING, PROC_REF(remove_shuttle_area))
	shuttle_area = areas

	if(initial_location)
		current_location = initial_location
	else
		current_location = SSshuttle.get_landmark(current_location)
	if(!istype(current_location))
		CRASH("Shuttle \"[name]\" could not find its starting location.")

	if(SSshuttle.shuttles[shuttle_id])
		CRASH("A shuttle with the ID '[shuttle_id]' is already defined.")
	SSshuttle.shuttles[shuttle_id] = src
	for(var/obj/structure/machinery/computer/shuttle_control/SC as anything in SSshuttle.lonely_shuttle_computers)
		if(SC.shuttle_tag == shuttle_id)
			SSshuttle.lonely_shuttle_computers -= SC
			shuttle_computers += SC
	if(flags & SHUTTLE_FLAGS_PROCESS)
		SSshuttle.process_shuttles += src
	if(flags & SHUTTLE_FLAGS_SUPPLY)
		if(SScargo.shuttle)
			CRASH("A supply shuttle is already defined.")
		SScargo.shuttle = src

/datum/shuttle/Destroy()
	cancel_pending_movement("Shuttle was destroyed.", SHUTTLE_MOVE_CANCELLED)
	for(var/area/shuttle_section in shuttle_area)
		UnregisterSignal(shuttle_section, COMSIG_QDELETING)
	SSshuttle.shuttle_areas -= shuttle_area
	current_location = null

	if(SSshuttle.shuttles[shuttle_id] == src)
		SSshuttle.shuttles -= shuttle_id
	SSshuttle.process_shuttles -= src
	if(SScargo.shuttle == src)
		SScargo.shuttle = null

	. = ..()

/datum/shuttle/proc/short_jump(var/obj/effect/shuttle_landmark/destination, datum/callback/completion_callback)
	var/generation = begin_movement(destination, null, completion_callback)
	if(!generation)
		return FALSE
	if(sound_takeoff)
		playsound(current_location, sound_takeoff, 25, 20)
	warmup_timer = addtimer(CALLBACK(src, PROC_REF(complete_short_jump), generation, destination), warmup_time, TIMER_STOPPABLE)
	return TRUE

/datum/shuttle/proc/long_jump(var/obj/effect/shuttle_landmark/destination, var/obj/effect/shuttle_landmark/interim, var/travel_time, datum/callback/completion_callback)
	var/generation = begin_movement(destination, interim, completion_callback)
	if(!generation)
		return FALSE
	if(sound_takeoff)
		playsound(current_location, sound_takeoff, 50, 20)
	warmup_timer = addtimer(CALLBACK(src, PROC_REF(complete_long_jump), generation, destination, interim, travel_time), warmup_time, TIMER_STOPPABLE)
	return TRUE

/// Authoritative entrypoint for callers that need to choose short or long movement.
/datum/shuttle/proc/request_jump(obj/effect/shuttle_landmark/destination, obj/effect/shuttle_landmark/interim, travel_time, user, datum/callback/completion_callback)
	if(interim)
		return long_jump(destination, interim, travel_time, completion_callback)
	return short_jump(destination, completion_callback)

/// Synchronous administrative/debug translation that still publishes an exact terminal result.
/datum/shuttle/proc/direct_move(obj/effect/shuttle_landmark/destination, user)
	if(moving_status != SHUTTLE_IDLE || movement_result == SHUTTLE_MOVE_PENDING)
		movement_error = "Shuttle is already moving."
		return FALSE

	var/rejection_reason = get_move_rejection_reason(destination)
	if(rejection_reason)
		movement_result = SHUTTLE_MOVE_REJECTED
		movement_error = rejection_reason
		movement_phase = "rejected"
		return FALSE

	launch_generation++
	movement_origin = current_location
	movement_destination = destination
	movement_origin_tag = movement_origin.landmark_tag
	movement_destination_tag = movement_destination.landmark_tag
	movement_translation_size = 0
	track_pending_landmark(movement_origin)
	track_pending_landmark(movement_destination)
	movement_result = SHUTTLE_MOVE_PENDING
	movement_error = null
	movement_phase = "direct translation"
	moving_status = SHUTTLE_INTRANSIT

	if(attempt_move(destination))
		finish_movement(SHUTTLE_MOVE_SUCCESS)
		return TRUE
	finish_movement(SHUTTLE_MOVE_REJECTED, movement_error)
	return FALSE

/// Validates and owns one asynchronous movement operation.
/datum/shuttle/proc/begin_movement(obj/effect/shuttle_landmark/destination, obj/effect/shuttle_landmark/interim, datum/callback/completion_callback)
	if(moving_status != SHUTTLE_IDLE || movement_result == SHUTTLE_MOVE_PENDING)
		movement_error = "Shuttle is already moving."
		return FALSE

	var/rejection_reason = get_move_rejection_reason(destination)
	if(rejection_reason)
		movement_result = SHUTTLE_MOVE_REJECTED
		movement_error = rejection_reason
		movement_phase = "rejected"
		return FALSE
	if(interim)
		rejection_reason = get_move_rejection_reason(interim)
		if(rejection_reason)
			movement_result = SHUTTLE_MOVE_REJECTED
			movement_error = "Invalid interim landmark: [rejection_reason]"
			movement_phase = "rejected"
			return FALSE
	if(!fuel_check(TRUE))
		movement_result = SHUTTLE_MOVE_REJECTED
		movement_error = "Insufficient fuel."
		movement_phase = "rejected"
		return FALSE

	launch_generation++
	movement_origin = current_location
	movement_destination = destination
	movement_interim = interim
	movement_origin_tag = movement_origin.landmark_tag
	movement_destination_tag = movement_destination.landmark_tag
	movement_translation_size = 0
	track_pending_landmark(movement_origin)
	track_pending_landmark(destination)
	if(interim)
		track_pending_landmark(interim)
	movement_result = SHUTTLE_MOVE_PENDING
	movement_error = null
	movement_phase = "warmup"
	movement_completion_callback = completion_callback
	moving_status = SHUTTLE_WARMUP
	return launch_generation

/datum/shuttle/proc/complete_short_jump(generation, obj/effect/shuttle_landmark/destination)
	if(generation != launch_generation || movement_result != SHUTTLE_MOVE_PENDING)
		return
	warmup_timer = null
	if(QDELETED(destination))
		finish_movement(SHUTTLE_MOVE_REJECTED, "Destination was destroyed during warmup.")
		return
	if(!fuel_check())
		finish_movement(SHUTTLE_MOVE_REJECTED, "Insufficient fuel at departure.")
		return

	moving_status = SHUTTLE_INTRANSIT
	movement_phase = "translation"
	if(attempt_move(destination))
		finish_movement(SHUTTLE_MOVE_SUCCESS)
	else
		finish_movement(SHUTTLE_MOVE_REJECTED, movement_error)

/datum/shuttle/proc/complete_long_jump(generation, obj/effect/shuttle_landmark/destination, obj/effect/shuttle_landmark/interim, travel_time)
	if(generation != launch_generation || movement_result != SHUTTLE_MOVE_PENDING)
		return
	warmup_timer = null
	if(QDELETED(destination) || QDELETED(interim))
		finish_movement(SHUTTLE_MOVE_REJECTED, "Destination or interim landmark was destroyed during warmup.")
		return
	if(!fuel_check())
		finish_movement(SHUTTLE_MOVE_REJECTED, "Insufficient fuel at departure.")
		return

	arrive_time = world.time + travel_time
	moving_status = SHUTTLE_INTRANSIT
	movement_phase = "interim translation"
	if(!attempt_move(interim))
		finish_movement(SHUTTLE_MOVE_REJECTED, movement_error)
		return

	on_move_interim()
	var/fwooshed = FALSE
	destination.deploy_landing_indicators(src)
	movement_phase = "transit"
	while(world.time < arrive_time)
		if(generation != launch_generation || movement_result != SHUTTLE_MOVE_PENDING)
			return
		if(QDELETED(destination))
			handle_pending_landmark_deleted()
			return
		if(!fwooshed && (arrive_time - world.time) < 10 SECONDS)
			fwooshed = TRUE
			playsound(destination, sound_landing, 50, 20)
		sleep(5)

	if(generation != launch_generation || movement_result != SHUTTLE_MOVE_PENDING)
		return
	movement_phase = "destination translation"
	if(attempt_move(destination))
		finish_movement(SHUTTLE_MOVE_SUCCESS)
		return

	var/final_failure = movement_error
	if(!QDELETED(destination))
		destination.clear_landing_indicators()
	movement_phase = "rollback"
	if(!QDELETED(movement_origin) && attempt_move(movement_origin))
		finish_movement(SHUTTLE_MOVE_ROLLED_BACK, "Destination move failed and shuttle returned to origin: [final_failure]")
	else
		finish_movement(SHUTTLE_MOVE_STRANDED, "Destination move failed and rollback failed: [final_failure]")

/datum/shuttle/proc/finish_movement(result, error)
	clear_pending_landmarks()
	warmup_timer = null
	arrive_time = 0
	moving_status = SHUTTLE_IDLE
	movement_result = result
	movement_error = error
	movement_phase = movement_result_name(result)
	movement_origin = null
	movement_destination = null
	movement_interim = null
	notify_movement_completion()

/datum/shuttle/proc/cancel_pending_movement(reason = "Movement cancelled.", result = SHUTTLE_MOVE_CANCELLED, notify_completion = TRUE)
	launch_generation++
	if(warmup_timer)
		deltimer(warmup_timer)
		warmup_timer = null
	if(movement_destination && !QDELETED(movement_destination))
		movement_destination.clear_landing_indicators()
	clear_pending_landmarks()
	arrive_time = 0
	moving_status = SHUTTLE_IDLE
	movement_result = result
	movement_error = reason
	movement_phase = movement_result_name(result)
	movement_origin = null
	movement_destination = null
	movement_interim = null
	if(notify_completion)
		notify_movement_completion()

/datum/shuttle/proc/notify_movement_completion()
	var/datum/callback/completion_callback = movement_completion_callback
	movement_completion_callback = null
	if(completion_callback)
		completion_callback.Invoke(src, movement_result, movement_error)
		qdel(completion_callback)

/datum/shuttle/proc/track_pending_landmark(obj/effect/shuttle_landmark/landmark)
	if(!landmark || (landmark in pending_landmarks))
		return
	pending_landmarks += landmark
	RegisterSignal(landmark, COMSIG_QDELETING, PROC_REF(handle_pending_landmark_deleted))

/datum/shuttle/proc/clear_pending_landmarks()
	for(var/obj/effect/shuttle_landmark/landmark as anything in pending_landmarks)
		UnregisterSignal(landmark, COMSIG_QDELETING)
	pending_landmarks.Cut()

/datum/shuttle/proc/handle_pending_landmark_deleted()
	SIGNAL_HANDLER
	if(movement_result != SHUTTLE_MOVE_PENDING)
		return

	var/obj/effect/shuttle_landmark/origin = movement_origin
	var/was_in_transit = moving_status == SHUTTLE_INTRANSIT
	cancel_pending_movement("A required shuttle landmark was destroyed.", SHUTTLE_MOVE_REJECTED, FALSE)
	if(!was_in_transit || current_location == origin)
		notify_movement_completion()
		return
	if(!origin || QDELETED(origin))
		movement_result = SHUTTLE_MOVE_STRANDED
		movement_error = "A required shuttle landmark was destroyed, and the origin was unavailable for rollback."
		movement_phase = movement_result_name(movement_result)
		notify_movement_completion()
		return
	moving_status = SHUTTLE_INTRANSIT
	movement_phase = "emergency rollback pending"
	var/rollback_generation = launch_generation
	addtimer(CALLBACK(src, PROC_REF(attempt_emergency_rollback), rollback_generation, origin), 0)

/datum/shuttle/proc/attempt_emergency_rollback(rollback_generation, obj/effect/shuttle_landmark/origin)
	if(rollback_generation != launch_generation)
		return
	if(!origin || QDELETED(origin))
		moving_status = SHUTTLE_IDLE
		movement_result = SHUTTLE_MOVE_STRANDED
		movement_error = "A required shuttle landmark was destroyed, and the origin became unavailable before rollback."
		movement_phase = movement_result_name(movement_result)
		notify_movement_completion()
		return
	if(current_location == origin)
		moving_status = SHUTTLE_IDLE
		movement_result = SHUTTLE_MOVE_ROLLED_BACK
		movement_error = "A required shuttle landmark was destroyed; shuttle was already back at its origin."
		movement_phase = movement_result_name(movement_result)
		notify_movement_completion()
		return
	var/rollback_reason = movement_error
	moving_status = SHUTTLE_INTRANSIT
	movement_phase = "emergency rollback"
	if(attempt_move(origin))
		moving_status = SHUTTLE_IDLE
		movement_result = SHUTTLE_MOVE_ROLLED_BACK
		movement_error = "[rollback_reason] Shuttle returned to its origin."
		movement_phase = movement_result_name(movement_result)
	else
		moving_status = SHUTTLE_IDLE
		movement_result = SHUTTLE_MOVE_STRANDED
		movement_error = "[rollback_reason] Emergency rollback failed: [movement_error]"
		movement_phase = movement_result_name(movement_result)
	notify_movement_completion()

/datum/shuttle/proc/movement_result_name(result = movement_result)
	switch(result)
		if(SHUTTLE_MOVE_IDLE)
			return "idle"
		if(SHUTTLE_MOVE_PENDING)
			return "pending"
		if(SHUTTLE_MOVE_SUCCESS)
			return "success"
		if(SHUTTLE_MOVE_REJECTED)
			return "rejected"
		if(SHUTTLE_MOVE_CANCELLED)
			return "cancelled"
		if(SHUTTLE_MOVE_ROLLED_BACK)
			return "rolled back"
		if(SHUTTLE_MOVE_STRANDED)
			return "stranded"
	return "unknown"

/datum/shuttle/proc/fuel_check(check_only = FALSE)
	return 1 //fuel check should always pass in non-overmap shuttles (they have magic engines)

/*****************
* Shuttle Moved Handling * (Observer Pattern Implementation: Shuttle Moved)
* Shuttle Pre Move Handling * (Observer Pattern Implementation: Shuttle Pre Move)
*****************/

/datum/shuttle/proc/attempt_move(var/obj/effect/shuttle_landmark/destination)
	var/rejection_reason = get_move_rejection_reason(destination)
	if(rejection_reason)
		movement_error = rejection_reason
		movement_phase = "rejected"
		return FALSE

	movement_phase = "building translation"
	testing("[src] moving to [destination]. Areas are [english_list(shuttle_area)]")
	var/list/translation = list()
	for(var/area/A in shuttle_area)
		testing("Moving [A]")
		translation += get_turf_translation(get_turf(current_location), get_turf(destination), A.contents)
	movement_translation_size = length(translation)
	testing("Shuttle ID '[shuttle_id]' prepared [movement_translation_size] turf translations from '[current_location.landmark_tag]' to '[destination.landmark_tag]' during phase '[movement_phase]'.")
	var/old_location = current_location
	GLOB.shuttle_pre_move_event.raise_event(src, old_location, destination)
	movement_phase = "translation commit"
	shuttle_moved(destination, translation)
	movement_phase = "post-commit observers"
	GLOB.shuttle_moved_event.raise_event(src, old_location, destination)
	destination.shuttle_arrived(src)
	movement_error = null
	return TRUE

/datum/shuttle/proc/get_move_rejection_reason(var/obj/effect/shuttle_landmark/destination)
	if(!istype(destination) || QDELETED(destination))
		return "Destination does not exist."
	if(!istype(current_location) || QDELETED(current_location))
		return "Current shuttle landmark does not exist."
	if(current_location == destination)
		return "Shuttle is already at that destination."
	if(!destination.is_valid(src))
		return "Destination is obstructed or otherwise invalid."
	var/departure_rejection = current_location.cannot_depart(src)
	if(departure_rejection)
		return istext(departure_rejection) ? departure_rejection : "Current landmark rejected departure."
	return null

//just moves the shuttle from A to B, if it can be moved
//A note to anyone overriding move in a subtype. shuttle_moved() must absolutely not, under any circumstances, fail to move the shuttle.
//If you want to conditionally cancel shuttle launches, that logic must go in short_jump(), long_jump() or attempt_move()
/datum/shuttle/proc/shuttle_moved(var/obj/effect/shuttle_landmark/destination, var/list/turf_translation)

	if((flags & SHUTTLE_FLAGS_ZERO_G))
		var/new_grav = 1
		if(destination.landmark_flags & SLANDMARK_FLAG_ZERO_G)
			var/area/new_area = get_area(destination)
			new_grav = new_area.has_gravity
		for(var/area/our_area in shuttle_area)
			if(our_area.has_gravity != new_grav)
				our_area.gravitychange(new_grav)

	for(var/turf/src_turf in turf_translation)
		var/turf/dst_turf = turf_translation[src_turf]
		if((squishes || cargo_elevator) && src_turf.is_solid_structure()) //in case someone put a hole in the shuttle and you were lucky enough to be under it
			for(var/atom/movable/AM in dst_turf)
				if(AM.movable_flags & MOVABLE_FLAG_DEL_SHUTTLE)
					qdel(AM)
					continue
				if(!AM.simulated)
					continue
				if(isliving(AM))
					var/mob/living/safety_hater = AM
					if(squishes)
						safety_hater.gib()
					else if(cargo_elevator)
						safety_hater.visible_message(
							SPAN_WARNING("[safety_hater] falls down the cargo elevator hatch!"),
							SPAN_WARNING("You fall down the cargo elevator hatch!")
						)
						shake_camera(safety_hater, 10, 1)
						safety_hater.fall_impact(1)
						safety_hater.apply_damage(20, DAMAGE_PAIN)
				else
					if(squishes)
						qdel(AM) //it just gets atomized I guess? TODO throw it into space somewhere, prevents people from using shuttles as an atom-smasher
	var/list/powernets = list()
	for(var/area/A in shuttle_area)
		// if there was a zlevel above our origin, erase our ceiling now we're leaving
		var/turf/T = get_turf(current_location)
		if(GET_TURF_ABOVE(T))
			for(var/turf/TO in A.contents)
				var/turf/TA = GET_TURF_ABOVE(TO)
				if(istype(TA, ceiling_type))
					TA.ChangeTurf(get_base_turf_by_area(TA), 1, 1)
		if(knockdown)
			for(var/mob/living/carbon/M in A)
				spawn(0)
					if(M.buckled_to)
						to_chat(M, SPAN_WARNING("Sudden acceleration presses you into your chair!"))
						shake_camera(M, 3, 1)
					else if(M.Check_Shoegrip(FALSE))
						to_chat(M, SPAN_WARNING("You feel immense pressure in your feet as you cling to the floor!"))
						M.apply_damage(10, DAMAGE_PAIN, BP_L_FOOT)
						M.apply_damage(10, DAMAGE_PAIN, BP_R_FOOT)
						shake_camera(M, 5, 1)
					else
						to_chat(M, SPAN_WARNING("The floor lurches beneath you!"))
						shake_camera(M, 10, 1)
						M.visible_message(SPAN_WARNING("[M.name] is tossed around by the sudden acceleration!"))
						M.throw_at_random(FALSE, 4, 1)
						M.Weaken(3)

		for(var/obj/structure/cable/C in A)
			powernets |= C.powernet

	translate_turfs(turf_translation, current_location.base_area, current_location.base_turf, TRUE)
	current_location = destination
	movement_phase = "location committed"

	// if there's a zlevel above our destination, paint in a ceiling on it so we retain our air
	var/turf/T = get_turf(current_location)
	if(GET_TURF_ABOVE(T))
		for(var/area/A in shuttle_area)
			for(var/turf/TD in A.contents)
				TD.update_above()
				TD.update_icon()
				var/turf/TA = GET_TURF_ABOVE(TD)
				if(istype(TA, get_base_turf_by_area(TA)) || (istype(TA) && TA.is_open()))
					if(get_area(TA) in shuttle_area)
						continue
					TA.ChangeTurf(ceiling_type, TRUE, TRUE, TRUE)

	for(var/area/sub_area in shuttle_area)
		for(var/atom/movable/movable in sub_area)
			movement_phase = "post-commit movable callbacks"
			movable.afterShuttleMove(destination)

	// Remove all powernets that were affected, and rebuild them.
	var/list/cables = list()
	for(var/datum/powernet/P in powernets)
		cables |= P.cables
		qdel(P)
	for(var/obj/structure/cable/C in cables)
		if(!C.powernet)
			var/datum/powernet/NewPN = new()
			NewPN.add_cable(C)
			propagate_network(C,C.powernet)

	if(mothershuttle)
		var/datum/shuttle/mothership = SSshuttle.shuttles[mothershuttle]
		if(mothership)
			if(current_location.landmark_tag == motherdock)
				mothership.shuttle_area |= shuttle_area
			else
				mothership.shuttle_area -= shuttle_area

//returns 1 if the shuttle has a valid arrive time
/datum/shuttle/proc/has_arrive_time()
	return (moving_status == SHUTTLE_INTRANSIT)

/datum/shuttle/proc/find_children()
	. = list()
	for(var/shuttle_name in SSshuttle.shuttles)
		var/datum/shuttle/shuttle = SSshuttle.shuttles[shuttle_name]
		if(shuttle.mothershuttle == shuttle_id)
			. += shuttle

//Returns those areas that are not actually child shuttles.
/datum/shuttle/proc/find_childfree_areas()
	. = shuttle_area.Copy()
	for(var/datum/shuttle/child in find_children())
		. -= child.shuttle_area

/datum/shuttle/autodock/proc/get_location_name()
	if(moving_status == SHUTTLE_INTRANSIT)
		return "In transit"
	return current_location.name

/datum/shuttle/autodock/proc/get_destination_name()
	if(!next_location)
		return "None"
	return next_location.name

/datum/shuttle/proc/set_process_state(var/new_state)
	process_state = new_state
	for(var/obj/structure/machinery/computer/shuttle_control/SC as anything in shuttle_computers)
		SC.update_helmets(src)

/datum/shuttle/proc/on_move_interim()
	return

/datum/shuttle/proc/remove_shuttle_area(area/area_to_remove)
	UnregisterSignal(area_to_remove, COMSIG_QDELETING)
	SSshuttle.shuttle_areas -= area_to_remove
	shuttle_area -= area_to_remove
	if(!length(shuttle_area))
		qdel(src)
