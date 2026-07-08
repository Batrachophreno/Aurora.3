/datum/event/astroclast
	// Quite a short fuse due to the potential severity of this event.
	announceWhen = 12
	ic_name = "a biohazard"

/datum/event/astroclast/announce()
	level_seven_announcement(affecting_z)

/datum/event/astroclast/start()
	..()

	// This stores the list of the possible number of astroclasts, weighted towards 2. Adjust if a different weighting if desired.
	var/alist/astroclast_count = alist(1 = 1, 2 = 2, 3 = 1)

	// We pick randomly from the list to determine how many we spawn.
	for(var/i = 1 to pickweight(astroclast_count))
		var/turf/T = pick_subarea_turf(/area/horizon/maintenance, list(/proc/is_station_turf, /proc/not_turf_contains_dense_objects))
		if(!T)
			// If we can't find a turf anywhere, we aren't going to find one in subsequent loops and we can call it here.
			log_and_message_admins("Astroclast event failed to find a viable turf.")
			kill(TRUE)
			return

		log_and_message_admins("Astroclast spawned at \the [get_area(T)]", location = T)
		// Spawn the astroclast in.
		var/obj/effect/neoblob/core/astroclast = new /obj/effect/neoblob/core(T)

		// Astroclasts receive a burst of growth from the moment they spawn!
		for(var/int = 1 to rand(3, 4))
			astroclast.process()
