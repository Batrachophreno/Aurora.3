#define DOCK_ATTEMPT_TIMEOUT (20 SECONDS)

/datum/shuttle/autodock
	var/in_use = null  //tells the controller whether this shuttle needs processing, also attempts to prevent double-use
	var/last_dock_attempt_time = 0
	var/docking_error
	var/current_dock_target

	/// `id_tag`/`master_tag` of the docking controller of this shuttle.
	var/dock_target = null

	var/obj/effect/shuttle_landmark/next_location
	var/datum/computer/file/embedded_program/docking/active_docking_controller
	/// Keeps a successfully reached destination alive and observed until docking resolves.
	var/obj/effect/shuttle_landmark/docking_destination

	var/obj/effect/shuttle_landmark/landmark_transition
	/// Time spent in the transition area, in deciseconds.
	var/move_time = 4 MINUTES
	/// Minimum transition time for station-level moves, in deciseconds.
	var/minimum_move_time = 15 SECONDS

	category = /datum/shuttle/autodock
	flags = SHUTTLE_FLAGS_PROCESS | SHUTTLE_FLAGS_ZERO_G

/datum/shuttle/autodock/New(var/_name, var/obj/effect/shuttle_landmark/start_waypoint)
	..(_name, start_waypoint)

	//Initial dock
	update_docking_target(current_location)
	active_docking_controller = current_location.docking_controller
	current_dock_target = get_docking_target(current_location)
	dock()

	//Optional transition area
	if(landmark_transition)
		var/transition_tag = landmark_transition
		landmark_transition = SSshuttle.get_landmark(transition_tag)
		if(!landmark_transition)
			CRASH("Shuttle '[shuttle_id]' could not find its configured transition landmark '[transition_tag]'.")

/datum/shuttle/autodock/Destroy()
	clear_docking_destination()
	next_location = null
	active_docking_controller = null
	landmark_transition = null

	return ..()

/datum/shuttle/autodock/finish_movement(result, error)
	. = ..()
	clear_docking_destination()
	if(result == SHUTTLE_MOVE_SUCCESS && (process_state == WAIT_ARRIVE || process_state == WAIT_FINISH) && current_location && !QDELETED(current_location))
		docking_destination = current_location
		RegisterSignal(docking_destination, COMSIG_QDELETING, PROC_REF(handle_docking_destination_deleted))

/datum/shuttle/autodock/proc/clear_docking_destination()
	if(docking_destination)
		UnregisterSignal(docking_destination, COMSIG_QDELETING)
	docking_destination = null

/datum/shuttle/autodock/proc/handle_docking_destination_deleted()
	SIGNAL_HANDLER
	if(process_state != WAIT_ARRIVE && process_state != WAIT_FINISH)
		return
	clear_docking_destination()
	movement_result = SHUTTLE_MOVE_STRANDED
	movement_error = "Reached destination landmark was destroyed before docking completed."
	movement_phase = movement_result_name(movement_result)
	docking_error = movement_error
	next_location = null
	active_docking_controller = null
	current_dock_target = null

/datum/shuttle/autodock/shuttle_moved()
	force_undock() //bye!
	..()

/datum/shuttle/autodock/proc/update_docking_target(var/obj/effect/shuttle_landmark/location)
	if(location && !QDELETED(location) && location.special_dock_targets && location.special_dock_targets[shuttle_id])
		current_dock_target = location.special_dock_targets[shuttle_id]
	else
		current_dock_target = dock_target
	active_docking_controller = SSshuttle.docking_registry[current_dock_target]

/datum/shuttle/autodock/proc/get_docking_target(var/obj/effect/shuttle_landmark/location)
	if(location && !QDELETED(location) && location.special_dock_targets)
		if(location.special_dock_targets[shuttle_id])
			return location.special_dock_targets[shuttle_id]
	return dock_target
/*
	Docking stuff
*/
/datum/shuttle/autodock/proc/dock()
	if(active_docking_controller && !QDELETED(active_docking_controller))
		active_docking_controller.initiate_docking(current_dock_target)
		last_dock_attempt_time = world.time
		return TRUE
	return FALSE

/datum/shuttle/autodock/proc/undock()
	if(active_docking_controller && !QDELETED(active_docking_controller))
		active_docking_controller.initiate_undocking()

/datum/shuttle/autodock/proc/force_undock()
	if(active_docking_controller && !QDELETED(active_docking_controller))
		active_docking_controller.force_undock()

/datum/shuttle/autodock/proc/check_docked()
	if(active_docking_controller && !QDELETED(active_docking_controller))
		return active_docking_controller.docked()
	return TRUE

/datum/shuttle/autodock/proc/check_undocked()
	if(active_docking_controller && !QDELETED(active_docking_controller))
		return active_docking_controller.can_launch()
	return TRUE

/*
	Please ensure that long_jump() and short_jump() are only called from here. This applies to subtypes as well.
	Doing so will ensure that multiple jumps cannot be initiated in parallel.
*/
/datum/shuttle/autodock/process()
	switch(process_state)
		if (WAIT_LAUNCH)
			if(check_undocked())
				process_launch()

		if (FORCE_LAUNCH)
			process_launch()

		if (WAIT_ARRIVE)
			if(moving_status != SHUTTLE_IDLE || movement_result == SHUTTLE_MOVE_PENDING)
				return
			if(movement_result == SHUTTLE_MOVE_SUCCESS)
				process_arrived()
			else
				process_failed_movement()
			set_process_state(WAIT_FINISH)

		if (WAIT_FINISH)
			var/docking_timed_out = active_docking_controller && !QDELETED(active_docking_controller) && world.time > last_dock_attempt_time + DOCK_ATTEMPT_TIMEOUT
			if(docking_timed_out || check_docked())
				if(docking_timed_out)
					docking_error = "Docking controller timed out after movement reached its destination."
					movement_result = SHUTTLE_MOVE_STRANDED
					movement_error = docking_error
					movement_phase = movement_result_name(movement_result)
				var/completion_user = in_use
				clear_docking_destination()
				set_process_state(IDLE_STATE)
				in_use = null
				if(movement_result == SHUTTLE_MOVE_SUCCESS)
					arrived(completion_user)

//not to be confused with the arrived() proc
/datum/shuttle/autodock/proc/process_arrived()
	if(!next_location || QDELETED(next_location))
		movement_result = SHUTTLE_MOVE_REJECTED
		movement_error = "Destination was destroyed before docking setup."
		process_failed_movement()
		return
	update_docking_target(next_location)
	active_docking_controller = next_location.docking_controller
	current_dock_target = get_docking_target(next_location)
	docking_error = null
	if(active_docking_controller && QDELETED(active_docking_controller))
		docking_error = "Destination docking controller was deleted before docking began."
		movement_result = SHUTTLE_MOVE_STRANDED
		movement_error = docking_error
		movement_phase = movement_result_name(movement_result)
		active_docking_controller = null
		current_dock_target = null
		next_location = null
		return
	dock()

	next_location = null

/datum/shuttle/autodock/proc/process_failed_movement()
	clear_docking_destination()
	force_undock()
	if(!current_location || QDELETED(current_location))
		active_docking_controller = null
		current_dock_target = null
		docking_error = "Movement failed without a live current landmark."
		return
	update_docking_target(current_location)
	active_docking_controller = current_location.docking_controller
	current_dock_target = get_docking_target(current_location)
	docking_error = null
	dock()

/datum/shuttle/autodock/proc/get_travel_time()
	if(current_location && next_location && !QDELETED(current_location) && !QDELETED(next_location) && is_station_level(current_location.z) && is_station_level(next_location.z) && move_time > minimum_move_time)
		return minimum_move_time
	else
		return move_time

/datum/shuttle/autodock/proc/process_launch()
	if(!next_location || QDELETED(next_location))
		movement_result = SHUTTLE_MOVE_REJECTED
		movement_error = "Selected destination no longer exists."
		process_failed_movement()
		set_process_state(WAIT_FINISH)
		return FALSE

	var/jump_accepted
	if(get_travel_time() && landmark_transition && !QDELETED(landmark_transition))
		jump_accepted = long_jump(next_location, landmark_transition, get_travel_time())
	else
		jump_accepted = short_jump(next_location)
	if(!jump_accepted)
		process_failed_movement()
		set_process_state(WAIT_FINISH)
		return FALSE
	set_process_state(WAIT_ARRIVE)
	return TRUE

/datum/shuttle/autodock/request_jump(obj/effect/shuttle_landmark/destination, obj/effect/shuttle_landmark/interim, travel_time, user, datum/callback/completion_callback)
	if(moving_status != SHUTTLE_IDLE || movement_result == SHUTTLE_MOVE_PENDING || process_state != IDLE_STATE || in_use)
		movement_error = "Shuttle authority is busy."
		return FALSE

	next_location = destination
	in_use = user ? user : src
	force_undock()
	var/accepted = ..(destination, interim, travel_time, user, completion_callback)
	if(!accepted)
		process_failed_movement()
		set_process_state(WAIT_FINISH)
		return FALSE
	set_process_state(WAIT_ARRIVE)
	return TRUE

/datum/shuttle/autodock/direct_move(obj/effect/shuttle_landmark/destination, user)
	if(moving_status != SHUTTLE_IDLE || movement_result == SHUTTLE_MOVE_PENDING || process_state != IDLE_STATE || in_use)
		movement_error = "Shuttle authority is busy."
		return FALSE

	next_location = destination
	in_use = user ? user : src
	force_undock()
	set_process_state(WAIT_ARRIVE)
	return ..(destination, user)

/*
	Guards
*/
/datum/shuttle/autodock/proc/can_launch()
	return (next_location && !QDELETED(next_location) && moving_status == SHUTTLE_IDLE && movement_result != SHUTTLE_MOVE_PENDING && process_state == IDLE_STATE && !in_use)

/datum/shuttle/autodock/proc/can_force()
	return (next_location && !QDELETED(next_location) && moving_status == SHUTTLE_IDLE && process_state == WAIT_LAUNCH)

/datum/shuttle/autodock/proc/can_cancel()
	return (moving_status == SHUTTLE_WARMUP || process_state == WAIT_LAUNCH || process_state == FORCE_LAUNCH)

/*
	"Public" procs
*/
/datum/shuttle/autodock/proc/launch(var/user)
	if(!can_launch())
		return FALSE

	in_use = user ? user : src	//obtain an exclusive lock even for automatic launches

	set_process_state(WAIT_LAUNCH)
	undock()
	return TRUE

/datum/shuttle/autodock/proc/force_launch(var/user)
	if(!can_force())
		return FALSE

	in_use = user ? user : src	//obtain an exclusive lock even for automatic launches

	set_process_state(FORCE_LAUNCH)
	return TRUE

/datum/shuttle/autodock/proc/cancel_launch(var/user)
	if(!can_cancel())
		return FALSE

	cancel_pending_movement("Launch cancelled.", SHUTTLE_MOVE_CANCELLED)
	set_process_state(WAIT_FINISH)

	//whatever we were doing with docking: stop it, then redock
	force_undock()
	if(current_location && !QDELETED(current_location))
		update_docking_target(current_location)
		active_docking_controller = current_location.docking_controller
		current_dock_target = get_docking_target(current_location)
		dock()
	return TRUE

//returns 1 if the shuttle is getting ready to move, but is not in transit yet
/datum/shuttle/autodock/proc/is_launching()
	return (moving_status == SHUTTLE_WARMUP || process_state == WAIT_LAUNCH || process_state == FORCE_LAUNCH)

//This gets called when the shuttle finishes arriving at it's destination
//This can be used by subtypes to do things when the shuttle arrives.
//Note that this is called when the shuttle leaves the WAIT_FINISHED state, the proc name is a little misleading
/datum/shuttle/autodock/proc/arrived(var/user)
	return	//do nothing for now

#undef DOCK_ATTEMPT_TIMEOUT
