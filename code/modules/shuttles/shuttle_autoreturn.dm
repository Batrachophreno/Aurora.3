/datum/shuttle/autodock/ferry/autoreturn
	var/auto_return_time = 60 SECONDS
	category = /datum/shuttle/autodock/ferry/autoreturn

/datum/shuttle/autodock/ferry/autoreturn/arrived(var/user)
	if(waypoint_station == current_location)
		addtimer(CALLBACK(src, PROC_REF(announce_return)), 2 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(do_return)), auto_return_time)
	return ..(user)

/datum/shuttle/autodock/ferry/autoreturn/proc/announce_return()
	if(!location)
		for(var/area/A in shuttle_area)
			for(var/mob/M in A)
				if(ishuman(M))
					to_chat(M, SPAN_NOTICE("You have arrived at the [SSatlas.current_map.station_name]! The shuttle will return in [round(auto_return_time / 10)] seconds. Enjoy your stay!"))

/datum/shuttle/autodock/ferry/autoreturn/proc/do_return()
	launch(src)
