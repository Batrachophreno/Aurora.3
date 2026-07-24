/datum/unit_test/shuttle_runtime_registries
	name = "SHUTTLE: Live shuttle and landmark registries shall be internally consistent."
	groups = list("map")

/datum/unit_test/shuttle_runtime_registries/start_test()
	var/test_status = UNIT_TEST_PASSED
	var/shuttles_checked = 0
	var/landmarks_checked = 0

	for(var/registered_id in SSshuttle.shuttles)
		var/datum/shuttle/shuttle = SSshuttle.shuttles[registered_id]
		if(!istype(shuttle) || QDELETED(shuttle))
			test_status = TEST_FAIL("Shuttle registry ID '[registered_id]' points to a missing or deleted shuttle.")
			continue

		shuttles_checked++
		if(!length(shuttle.shuttle_id) || shuttle.shuttle_id != registered_id)
			test_status = TEST_FAIL("Shuttle registry ID '[registered_id]' does not match immutable ID '[shuttle.shuttle_id]' on [shuttle].")
		if(!(shuttle.moving_status in list(SHUTTLE_IDLE, SHUTTLE_WARMUP, SHUTTLE_INTRANSIT)))
			test_status = TEST_FAIL("Shuttle '[registered_id]' has invalid movement state '[shuttle.moving_status]'.")
		if(!(shuttle.movement_result in list(
			SHUTTLE_MOVE_IDLE,
			SHUTTLE_MOVE_PENDING,
			SHUTTLE_MOVE_SUCCESS,
			SHUTTLE_MOVE_REJECTED,
			SHUTTLE_MOVE_CANCELLED,
			SHUTTLE_MOVE_ROLLED_BACK,
			SHUTTLE_MOVE_STRANDED
		)))
			test_status = TEST_FAIL("Shuttle '[registered_id]' has invalid movement result '[shuttle.movement_result]'.")
		if(shuttle.movement_result == SHUTTLE_MOVE_PENDING && shuttle.moving_status == SHUTTLE_IDLE)
			test_status = TEST_FAIL("Shuttle '[registered_id]' has pending movement while marked idle.")
		if(shuttle.movement_result != SHUTTLE_MOVE_PENDING && length(shuttle.pending_landmarks))
			test_status = TEST_FAIL("Shuttle '[registered_id]' retains movement landmark references after its movement completed.")

		var/obj/effect/shuttle_landmark/current_location = shuttle.current_location
		if(!istype(current_location) || QDELETED(current_location))
			test_status = TEST_FAIL("Shuttle '[registered_id]' has no live current landmark.")
		else if(SSshuttle.get_landmark(current_location.landmark_tag) != current_location)
			test_status = TEST_FAIL("Shuttle '[registered_id]' current landmark '[current_location.landmark_tag]' is not its registered landmark.")
		else if(!current_location.base_area)
			test_status = TEST_FAIL("Shuttle '[registered_id]' current landmark '[current_location.landmark_tag]' has no initialized base area.")

		if(shuttle.mothershuttle)
			var/datum/shuttle/mothership = SSshuttle.shuttles[shuttle.mothershuttle]
			if(!istype(mothership) || QDELETED(mothership))
				test_status = TEST_FAIL("Shuttle '[registered_id]' references missing mothership ID '[shuttle.mothershuttle]'.")

	for(var/landmark_tag in SSshuttle.registered_shuttle_landmarks)
		var/obj/effect/shuttle_landmark/landmark = SSshuttle.registered_shuttle_landmarks[landmark_tag]
		if(!istype(landmark) || QDELETED(landmark))
			test_status = TEST_FAIL("Landmark registry tag '[landmark_tag]' points to a missing or deleted landmark.")
			continue

		landmarks_checked++
		if(!length(landmark.landmark_tag) || landmark.landmark_tag != landmark_tag)
			test_status = TEST_FAIL("Landmark registry tag '[landmark_tag]' does not match landmark tag '[landmark.landmark_tag]' on [landmark].")
		if(landmark.shuttle_restricted && !SSshuttle.shuttles[landmark.shuttle_restricted])
			test_status = TEST_FAIL("Landmark '[landmark_tag]' is restricted to missing shuttle ID '[landmark.shuttle_restricted]'.")

	if(test_status == UNIT_TEST_PASSED)
		TEST_PASS("Validated [shuttles_checked] live shuttles and [landmarks_checked] live landmarks.")
	return test_status

/datum/unit_test/shuttle_runtime_routes
	name = "SHUTTLE: Live shuttle routes shall resolve to registered landmarks."
	groups = list("map")

/datum/unit_test/shuttle_runtime_routes/start_test()
	var/test_status = UNIT_TEST_PASSED
	var/routes_checked = 0

	for(var/registered_id in SSshuttle.shuttles)
		var/datum/shuttle/autodock/shuttle = SSshuttle.shuttles[registered_id]
		if(!istype(shuttle) || QDELETED(shuttle))
			continue

		if(shuttle.landmark_transition)
			routes_checked++
			if(QDELETED(shuttle.landmark_transition) || SSshuttle.get_landmark(shuttle.landmark_transition.landmark_tag) != shuttle.landmark_transition)
				test_status = TEST_FAIL("Shuttle '[registered_id]' has an unregistered transition landmark.")

		if(shuttle.logging_home_tag)
			routes_checked++
			if(!SSshuttle.get_landmark(shuttle.logging_home_tag))
				test_status = TEST_FAIL("Shuttle '[registered_id]' has missing logging home landmark '[shuttle.logging_home_tag]'.")

		if(shuttle.next_location)
			routes_checked++
			if(QDELETED(shuttle.next_location) || SSshuttle.get_landmark(shuttle.next_location.landmark_tag) != shuttle.next_location)
				test_status = TEST_FAIL("Shuttle '[registered_id]' has an unregistered selected destination.")

		var/datum/shuttle/autodock/ferry/ferry_shuttle = shuttle
		if(istype(ferry_shuttle))
			routes_checked += 2
			if(!istype(ferry_shuttle.waypoint_station) || QDELETED(ferry_shuttle.waypoint_station) || SSshuttle.get_landmark(ferry_shuttle.waypoint_station.landmark_tag) != ferry_shuttle.waypoint_station)
				test_status = TEST_FAIL("Ferry shuttle '[registered_id]' has an unregistered station waypoint.")
			if(!istype(ferry_shuttle.waypoint_offsite) || QDELETED(ferry_shuttle.waypoint_offsite) || SSshuttle.get_landmark(ferry_shuttle.waypoint_offsite.landmark_tag) != ferry_shuttle.waypoint_offsite)
				test_status = TEST_FAIL("Ferry shuttle '[registered_id]' has an unregistered offsite waypoint.")

		var/datum/shuttle/autodock/multi/multi_shuttle = shuttle
		if(!istype(multi_shuttle))
			continue
		for(var/destination_tag in flatten_list(multi_shuttle.destination_tags))
			routes_checked++
			if(!SSshuttle.get_landmark(destination_tag))
				test_status = TEST_FAIL("Shuttle '[registered_id]' has missing configured destination landmark '[destination_tag]'.")

	if(test_status == UNIT_TEST_PASSED)
		TEST_PASS("Validated [routes_checked] configured route references on live shuttles.")
	return test_status

/**
 * Minimal non-world-moving shuttle used to exercise asynchronous authority state.
 * It deliberately skips normal registry and area initialization.
 */
/datum/shuttle/shuttle_authority_test
	var/fuel_available = TRUE
	var/list/failed_destinations = list()

/datum/shuttle/shuttle_authority_test/New(obj/effect/shuttle_landmark/origin)
	name = "Shuttle Authority Unit Test"
	shuttle_id = "__shuttle_authority_unit_test"
	current_location = origin
	shuttle_area = list()
	sound_takeoff = null
	sound_landing = null
	warmup_time = 10 MINUTES

/datum/shuttle/shuttle_authority_test/fuel_check(check_only = FALSE)
	return fuel_available

/datum/shuttle/shuttle_authority_test/get_move_rejection_reason(obj/effect/shuttle_landmark/destination)
	if(!istype(destination) || QDELETED(destination))
		return "Destination does not exist."
	if(!istype(current_location) || QDELETED(current_location))
		return "Current shuttle landmark does not exist."
	if(current_location == destination)
		return "Shuttle is already at that destination."
	return null

/datum/shuttle/shuttle_authority_test/attempt_move(obj/effect/shuttle_landmark/destination)
	if(destination in failed_destinations)
		movement_error = "Injected unit-test movement failure."
		return FALSE
	current_location = destination
	movement_error = null
	return TRUE

/// Landmark with no global registration or world translation side effects.
/obj/effect/shuttle_landmark/shuttle_authority_test

/obj/effect/shuttle_landmark/shuttle_authority_test/Initialize()
	SHOULD_CALL_PARENT(FALSE)
	clean_name = name
	return INITIALIZE_HINT_NORMAL

/obj/effect/shuttle_landmark/shuttle_authority_test/deploy_landing_indicators(datum/shuttle/shuttle)
	return TRUE

/obj/effect/shuttle_landmark/shuttle_authority_test/clear_landing_indicators()
	return

/datum/unit_test/shuttle_authority_state_machine
	name = "SHUTTLE: Movement authority shall reject, cancel, roll back, and invalidate stale launches."
	groups = list("generic")

/datum/unit_test/shuttle_authority_state_machine/proc/stop_warmup_timer(datum/shuttle/shuttle)
	if(shuttle.warmup_timer)
		deltimer(shuttle.warmup_timer)
		shuttle.warmup_timer = null

/datum/unit_test/shuttle_authority_state_machine/start_test()
	var/test_status = UNIT_TEST_PASSED
	var/obj/effect/shuttle_landmark/shuttle_authority_test/origin = new(null)
	var/obj/effect/shuttle_landmark/shuttle_authority_test/destination_one = new(null)
	var/obj/effect/shuttle_landmark/shuttle_authority_test/destination_two = new(null)
	var/obj/effect/shuttle_landmark/shuttle_authority_test/interim = new(null)
	origin.landmark_tag = "__shuttle_authority_origin"
	destination_one.landmark_tag = "__shuttle_authority_destination_one"
	destination_two.landmark_tag = "__shuttle_authority_destination_two"
	interim.landmark_tag = "__shuttle_authority_interim"

	var/datum/shuttle/shuttle_authority_test/shuttle = new(origin)
	shuttle.failed_destinations = list(destination_one)
	if(!shuttle.short_jump(destination_one))
		test_status = TEST_FAIL("A valid test launch was rejected before its injected translation failure.")
	else
		var/failed_generation = shuttle.launch_generation
		stop_warmup_timer(shuttle)
		shuttle.complete_short_jump(failed_generation, destination_one)
		if(shuttle.movement_result != SHUTTLE_MOVE_REJECTED || shuttle.moving_status != SHUTTLE_IDLE || shuttle.current_location != origin)
			test_status = TEST_FAIL("Failed short movement did not finish rejected, idle, and at its origin.")

	shuttle.failed_destinations.Cut()
	if(!shuttle.short_jump(destination_one))
		test_status = TEST_FAIL("First launch in the cancellation race was rejected.")
	else
		var/stale_generation = shuttle.launch_generation
		shuttle.cancel_pending_movement("Injected unit-test cancellation.")
		if(shuttle.movement_result != SHUTTLE_MOVE_CANCELLED || shuttle.moving_status != SHUTTLE_IDLE)
			test_status = TEST_FAIL("Cancellation did not return shuttle authority to a cancelled idle state.")
		if(!shuttle.short_jump(destination_two))
			test_status = TEST_FAIL("Relaunch after cancellation was rejected.")
		else
			var/current_generation = shuttle.launch_generation
			var/current_timer = shuttle.warmup_timer
			shuttle.complete_short_jump(stale_generation, destination_one)
			if(shuttle.launch_generation != current_generation || shuttle.movement_result != SHUTTLE_MOVE_PENDING || shuttle.warmup_timer != current_timer)
				test_status = TEST_FAIL("Stale launch callback mutated the active relaunch.")
			stop_warmup_timer(shuttle)
			shuttle.complete_short_jump(current_generation, destination_two)
			if(shuttle.movement_result != SHUTTLE_MOVE_SUCCESS || shuttle.current_location != destination_two)
				test_status = TEST_FAIL("Current relaunch did not complete after stale callback rejection.")

	shuttle.fuel_available = FALSE
	if(shuttle.short_jump(origin) || shuttle.movement_result != SHUTTLE_MOVE_REJECTED || shuttle.moving_status != SHUTTLE_IDLE || shuttle.warmup_timer)
		test_status = TEST_FAIL("Fuel rejection entered warmup or left movement authority non-idle.")

	var/datum/shuttle/shuttle_authority_test/rollback_shuttle = new(origin)
	rollback_shuttle.failed_destinations = list(destination_one)
	if(!rollback_shuttle.long_jump(destination_one, interim, 0))
		test_status = TEST_FAIL("Rollback test launch was rejected before movement.")
	else
		var/rollback_generation = rollback_shuttle.launch_generation
		stop_warmup_timer(rollback_shuttle)
		rollback_shuttle.complete_long_jump(rollback_generation, destination_one, interim, 0)
		if(rollback_shuttle.movement_result != SHUTTLE_MOVE_ROLLED_BACK || rollback_shuttle.moving_status != SHUTTLE_IDLE || rollback_shuttle.current_location != origin)
			test_status = TEST_FAIL("Failed long movement did not roll back to its origin.")

	var/datum/shuttle/shuttle_authority_test/stranded_shuttle = new(origin)
	stranded_shuttle.failed_destinations = list(destination_one, origin)
	if(!stranded_shuttle.long_jump(destination_one, interim, 0))
		test_status = TEST_FAIL("Stranding test launch was rejected before movement.")
	else
		var/stranded_generation = stranded_shuttle.launch_generation
		stop_warmup_timer(stranded_shuttle)
		stranded_shuttle.complete_long_jump(stranded_generation, destination_one, interim, 0)
		if(stranded_shuttle.movement_result != SHUTTLE_MOVE_STRANDED || stranded_shuttle.moving_status != SHUTTLE_IDLE || stranded_shuttle.current_location != interim)
			test_status = TEST_FAIL("Double movement failure did not report a stranded shuttle at the interim landmark.")

	var/obj/effect/shuttle_landmark/shuttle_authority_test/dynamic_landmark = new(null)
	dynamic_landmark.landmark_tag = "__shuttle_dynamic_registry_unit_test"
	var/registry_generation = SSshuttle.landmark_registry_generation
	SSshuttle.register_landmark(dynamic_landmark.landmark_tag, dynamic_landmark)
	if(SSshuttle.get_landmark(dynamic_landmark.landmark_tag) != dynamic_landmark || SSshuttle.landmark_registry_generation <= registry_generation)
		test_status = TEST_FAIL("Dynamic landmark did not register or invalidate route caches.")
	registry_generation = SSshuttle.landmark_registry_generation
	qdel(dynamic_landmark)
	if(SSshuttle.get_landmark("__shuttle_dynamic_registry_unit_test") || SSshuttle.landmark_registry_generation <= registry_generation)
		test_status = TEST_FAIL("Deleted dynamic landmark remained registered or did not invalidate route caches.")

	qdel(shuttle)
	qdel(rollback_shuttle)
	qdel(stranded_shuttle)
	qdel(origin)
	qdel(destination_one)
	qdel(destination_two)
	qdel(interim)

	if(test_status == UNIT_TEST_PASSED)
		TEST_PASS("Movement rejection, fuel failure, cancellation generation, rollback, stranding, and dynamic cleanup remained coherent.")
	return test_status

/// Minimal autodock fixture that reports docking completion under test control.
/datum/shuttle/autodock/shuttle_docking_test
	var/list/failed_destinations = list()
	var/test_docked = FALSE
	var/arrival_count = 0

/datum/shuttle/autodock/shuttle_docking_test/New(obj/effect/shuttle_landmark/origin, obj/effect/shuttle_landmark/destination)
	name = "Shuttle Docking Unit Test"
	shuttle_id = "__shuttle_docking_unit_test"
	current_location = origin
	next_location = destination
	shuttle_area = list()
	sound_takeoff = null
	sound_landing = null
	warmup_time = 10 MINUTES

/datum/shuttle/autodock/shuttle_docking_test/get_travel_time()
	return 0

/datum/shuttle/autodock/shuttle_docking_test/get_move_rejection_reason(obj/effect/shuttle_landmark/destination)
	if(!istype(destination) || QDELETED(destination))
		return "Destination does not exist."
	if(!istype(current_location) || QDELETED(current_location))
		return "Current shuttle landmark does not exist."
	if(current_location == destination)
		return "Shuttle is already at that destination."
	return null

/datum/shuttle/autodock/shuttle_docking_test/attempt_move(obj/effect/shuttle_landmark/destination)
	if(destination in failed_destinations)
		movement_error = "Injected unit-test movement failure."
		return FALSE
	current_location = destination
	movement_error = null
	return TRUE

/datum/shuttle/autodock/shuttle_docking_test/update_docking_target(obj/effect/shuttle_landmark/location)
	return

/datum/shuttle/autodock/shuttle_docking_test/dock()
	return TRUE

/datum/shuttle/autodock/shuttle_docking_test/undock()
	return

/datum/shuttle/autodock/shuttle_docking_test/force_undock()
	return

/datum/shuttle/autodock/shuttle_docking_test/check_undocked()
	return TRUE

/datum/shuttle/autodock/shuttle_docking_test/check_docked()
	return test_docked

/datum/shuttle/autodock/shuttle_docking_test/arrived(user)
	arrival_count++
	return ..(user)

/datum/unit_test/shuttle_docking_convergence
	name = "SHUTTLE: Autodock authority shall hold ownership through terminal docking."
	groups = list("generic")

/datum/unit_test/shuttle_docking_convergence/proc/complete_test_warmup(datum/shuttle/autodock/shuttle_docking_test/shuttle)
	var/generation = shuttle.launch_generation
	if(shuttle.warmup_timer)
		deltimer(shuttle.warmup_timer)
		shuttle.warmup_timer = null
	shuttle.complete_short_jump(generation, shuttle.next_location)

/datum/unit_test/shuttle_docking_convergence/start_test()
	var/test_status = UNIT_TEST_PASSED
	var/obj/effect/shuttle_landmark/shuttle_authority_test/origin = new(null)
	var/obj/effect/shuttle_landmark/shuttle_authority_test/destination = new(null)
	origin.landmark_tag = "__shuttle_docking_origin"
	destination.landmark_tag = "__shuttle_docking_destination"
	var/datum/shuttle/autodock/shuttle_docking_test/shuttle = new(origin, destination)
	var/owner = "__shuttle_docking_owner"

	if(!shuttle.launch(owner))
		test_status = TEST_FAIL("Autodock test launch was rejected.")
	else
		shuttle.process()
		if(shuttle.process_state != WAIT_ARRIVE || shuttle.movement_result != SHUTTLE_MOVE_PENDING || shuttle.in_use != owner)
			test_status = TEST_FAIL("Accepted launch did not enter owned movement state.")
		complete_test_warmup(shuttle)
		shuttle.process()
		if(shuttle.process_state != WAIT_FINISH || shuttle.in_use != owner || shuttle.arrival_count)
			test_status = TEST_FAIL("Successful translation released ownership or announced arrival before docking.")
		shuttle.process()
		if(shuttle.process_state != WAIT_FINISH || shuttle.in_use != owner)
			test_status = TEST_FAIL("Incomplete docking did not retain shuttle ownership.")
		shuttle.test_docked = TRUE
		shuttle.process()
		if(shuttle.process_state != IDLE_STATE || shuttle.in_use || shuttle.arrival_count != 1)
			test_status = TEST_FAIL("Completed docking did not release ownership and announce exactly one arrival.")

	shuttle.next_location = origin
	shuttle.failed_destinations = list(origin)
	shuttle.test_docked = FALSE
	if(!shuttle.launch(owner))
		test_status = TEST_FAIL("Autodock failure test launch was rejected before translation.")
	else
		shuttle.process()
		complete_test_warmup(shuttle)
		shuttle.process()
		if(shuttle.movement_result != SHUTTLE_MOVE_REJECTED || shuttle.process_state != WAIT_FINISH || shuttle.in_use != owner || shuttle.arrival_count != 1)
			test_status = TEST_FAIL("Rejected movement announced false arrival or released ownership before redocking.")
		shuttle.test_docked = TRUE
		shuttle.process()
		if(shuttle.process_state != IDLE_STATE || shuttle.in_use || shuttle.arrival_count != 1)
			test_status = TEST_FAIL("Failure redocking did not converge idle without a false arrival.")

	qdel(shuttle)
	qdel(origin)
	qdel(destination)

	if(test_status == UNIT_TEST_PASSED)
		TEST_PASS("Autodock success and failure retained ownership until docking convergence without false arrival.")
	return test_status
