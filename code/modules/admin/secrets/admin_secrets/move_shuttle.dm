/datum/admin_secret_item/admin_secret/move_shuttle
	name = "Move a Shuttle"

/datum/admin_secret_item/admin_secret/move_shuttle/can_execute(var/mob/user)
	if(!SSshuttle)
		return 0
	return ..()

/datum/admin_secret_item/admin_secret/move_shuttle/execute(var/mob/user)
	. = ..()
	if(!.)
		return
	var/confirm = alert(user, "This command directly moves a shuttle to a registered landmark. DO NOT USE THIS UNLESS YOU ARE DEBUGGING A SHUTTLE AND YOU KNOW WHAT YOU ARE DOING.", "Are you sure?", "Ok", "Cancel")
	if(confirm != "Ok")
		return

	var/shuttle_tag = input(user, "Which shuttle do you want to move?") as null|anything in SSshuttle.shuttles
	if(!shuttle_tag)
		return

	var/datum/shuttle/S = SSshuttle.shuttles[shuttle_tag]
	if(!istype(S) || QDELETED(S))
		log_and_message_admins("had a direct move request for the [shuttle_tag] shuttle rejected because it is no longer registered.", user)
		return

	var/list/destinations = list()
	for(var/landmark_tag in SSshuttle.registered_shuttle_landmarks)
		var/obj/effect/shuttle_landmark/landmark = SSshuttle.registered_shuttle_landmarks[landmark_tag]
		if(istype(landmark) && !QDELETED(landmark))
			destinations += landmark
	if(!destinations.len)
		to_chat(user, SPAN_WARNING("There are no live registered shuttle landmarks."))
		return

	var/obj/effect/shuttle_landmark/destination = input(user, "Select the destination.") as null|anything in destinations
	if(!destination)
		return

	if(QDELETED(S) || SSshuttle.shuttles[shuttle_tag] != S)
		log_and_message_admins("had a direct move request for the [shuttle_tag] shuttle rejected because it is no longer registered.", user)
		return

	var/destination_registered = FALSE
	for(var/landmark_tag in SSshuttle.registered_shuttle_landmarks)
		if(SSshuttle.registered_shuttle_landmarks[landmark_tag] == destination)
			destination_registered = TRUE
			break
	if(QDELETED(destination) || !destination_registered)
		log_and_message_admins("had a direct move request for the [shuttle_tag] shuttle rejected because the selected destination is no longer registered.", user)
		return
	if(!istype(S.current_location) || QDELETED(S.current_location))
		log_and_message_admins("had a direct move request for the [shuttle_tag] shuttle rejected because it has no live current landmark.", user, get_turf(destination))
		return

	if(!S.direct_move(destination, user))
		var/rejection_reason = S.movement_error || "The shuttle movement authority returned no rejection reason."
		log_and_message_admins("had a direct move request for the [shuttle_tag] shuttle to [destination] rejected: [rejection_reason]", user, get_turf(destination))
		return

	log_and_message_admins("moved the [shuttle_tag] shuttle to [destination].", user, get_turf(destination))
