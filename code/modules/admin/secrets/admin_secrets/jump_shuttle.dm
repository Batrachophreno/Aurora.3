/datum/admin_secret_item/admin_secret/jump_shuttle
	name = "Jump a Shuttle"

/datum/admin_secret_item/admin_secret/jump_shuttle/can_execute(var/mob/user)
	if(!SSshuttle) return 0
	return ..()

/datum/admin_secret_item/admin_secret/jump_shuttle/execute(var/mob/user)
	. = ..()
	if(!.)
		return
	var/shuttle_tag = input(user, "Which shuttle do you want to jump?") as null|anything in SSshuttle.shuttles
	if(!shuttle_tag)
		return

	var/datum/shuttle/S = SSshuttle.shuttles[shuttle_tag]
	if(!istype(S) || QDELETED(S))
		log_and_message_admins("had a jump request for the [shuttle_tag] shuttle rejected because it is no longer registered.", user)
		return

	var/list/destinations = list()
	for(var/landmark_tag in SSshuttle.registered_shuttle_landmarks)
		var/obj/effect/shuttle_landmark/landmark = SSshuttle.registered_shuttle_landmarks[landmark_tag]
		if(istype(landmark) && !QDELETED(landmark))
			destinations += landmark
	if(!destinations.len)
		to_chat(user, SPAN_WARNING("There are no live registered shuttle landmarks."))
		return

	var/obj/effect/shuttle_landmark/destination = input(user, "Select the destination landmark.") as null|anything in destinations
	if(!destination)
		return

	var/jump_type = alert(user, "Should this jump use an interim landmark?", "Jump a Shuttle", "Yes", "No", "Cancel")
	if(!jump_type || jump_type == "Cancel")
		return

	var/obj/effect/shuttle_landmark/interim
	var/move_duration
	if(jump_type == "Yes")
		interim = input(user, "Select the interim landmark.") as null|anything in destinations
		if(!interim)
			return

		move_duration = input(user, "How many seconds should the jump take?", "Jump a Shuttle") as null|num
		if(isnull(move_duration))
			return
		if(move_duration <= 0)
			to_chat(user, SPAN_WARNING("Travel time must be greater than zero seconds."))
			return

	if(QDELETED(S) || SSshuttle.shuttles[shuttle_tag] != S)
		log_and_message_admins("had a jump request for the [shuttle_tag] shuttle rejected because it is no longer registered.", user)
		return

	var/destination_registered = FALSE
	var/interim_registered = !interim
	for(var/landmark_tag in SSshuttle.registered_shuttle_landmarks)
		var/obj/effect/shuttle_landmark/landmark = SSshuttle.registered_shuttle_landmarks[landmark_tag]
		if(landmark == destination)
			destination_registered = TRUE
		if(landmark == interim)
			interim_registered = TRUE
	if(QDELETED(destination) || !destination_registered)
		log_and_message_admins("had a jump request for the [shuttle_tag] shuttle rejected because the selected destination is no longer registered.", user)
		return
	if(interim && (QDELETED(interim) || !interim_registered))
		log_and_message_admins("had a jump request for the [shuttle_tag] shuttle rejected because the selected interim landmark is no longer registered.", user, get_turf(destination))
		return

	var/obj/effect/shuttle_landmark/origin = S.current_location
	var/completion_description
	if(interim)
		completion_description = "The [shuttle_tag] shuttle's long jump from [origin] to [destination] via [interim]"
	else
		completion_description = "The [shuttle_tag] shuttle's short jump from [origin] to [destination]"
	var/datum/callback/completion_callback = CALLBACK(
		GLOBAL_PROC,
		GLOBAL_PROC_REF(log_admin_shuttle_jump_completion),
		key_name(user),
		key_name_admin(user),
		completion_description,
		destination.x,
		destination.y,
		destination.z
	)
	var/accepted = S.request_jump(destination, interim, interim ? move_duration SECONDS : 0, user, completion_callback)

	if(!accepted)
		qdel(completion_callback)
		var/rejection_reason = S.movement_error || "The shuttle movement authority returned no rejection reason."
		if(interim)
			log_and_message_admins("had a long jump request for the [shuttle_tag] shuttle from [origin] to [destination] via [interim] rejected: [rejection_reason]", user, get_turf(destination))
		else
			log_and_message_admins("had a short jump request for the [shuttle_tag] shuttle from [origin] to [destination] rejected: [rejection_reason]", user, get_turf(destination))
		return

	if(interim)
		log_and_message_admins("had a long jump request accepted for the [shuttle_tag] shuttle from [origin] to [destination] via [interim], with [move_duration] seconds of travel time.", user, get_turf(destination))
	else
		log_and_message_admins("had a short jump request accepted for the [shuttle_tag] shuttle from [origin] to [destination].", user, get_turf(destination))

/proc/log_admin_shuttle_jump_completion(log_identity, admin_identity, jump_description, destination_x, destination_y, destination_z, datum/shuttle/shuttle, movement_result, movement_error)
	var/outcome
	switch(movement_result)
		if(SHUTTLE_MOVE_SUCCESS)
			outcome = "completed successfully."
		if(SHUTTLE_MOVE_REJECTED)
			outcome = "was rejected after acceptance."
		if(SHUTTLE_MOVE_CANCELLED)
			outcome = "was cancelled after acceptance."
		if(SHUTTLE_MOVE_ROLLED_BACK)
			outcome = "failed to reach its destination and rolled back."
		if(SHUTTLE_MOVE_STRANDED)
			outcome = "failed and left [shuttle] stranded at [shuttle.current_location]."
		else
			outcome = "finished with unknown movement result [movement_result]."

	var/message = "[jump_description] [outcome]"
	if(movement_error)
		message += " Reason: [movement_error]"
	var/jump_link = " (<a href='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[destination_x];Y=[destination_y];Z=[destination_z]'>JMP</a>)"
	log_admin("[log_identity] [message][jump_link]")
	message_admins("[admin_identity] [message][jump_link]")
