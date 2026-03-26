// Returns which access is relevant to passed network. Used by the program.
/proc/get_camera_access(var/network)
	if(!network)
		return FALSE

	. = SSatlas.current_map.get_network_access(network)
	if (.)
		return

	switch(network)
		if(NETWORK_THUNDER, NETWORK_NEWS)
			return FALSE
		if(NETWORK_REACTOR,NETWORK_ENGINEERING,NETWORK_ENGINEERING_OUTPOST,NETWORK_ALARM_ATMOS,NETWORK_ALARM_FIRE,NETWORK_ALARM_POWER)
			return ACCESS_ENGINE
		if(NETWORK_MEDICAL)
			return ACCESS_MEDICAL
		if(NETWORK_SECURITY)
			return ACCESS_SECURITY
		if(NETWORK_RESEARCH,NETWORK_RESEARCH_OUTPOST)
			return ACCESS_RESEARCH
		if(NETWORK_MINE,NETWORK_SUPPLY,NETWORK_CIVILIAN_WEST,NETWORK_EXPEDITION,NETWORK_CALYPSO,NETWORK_POD)
			return ACCESS_MAILSORTING // Cargo office - all cargo staff should have access here.
		if(NETWORK_COMMAND,NETWORK_TELECOM,NETWORK_CIVILIAN_EAST,NETWORK_CIVILIAN_MAIN,NETWORK_CIVILIAN_SURFACE, NETWORK_SERVICE, NETWORK_FIRST_DECK, NETWORK_SECOND_DECK, NETWORK_THIRD_DECK, NETWORK_INTREPID)
			return ACCESS_HEADS
		if(NETWORK_CRESCENT,NETWORK_ERT)
			return ACCESS_CENT_SPECOPS
		if(NETWORK_CRYO_OUTPOST)
			return ACCESS_CRYO_OUTPOST

	return ACCESS_SECURITY // Default for all other networks

/datum/computer_file/program/camera_monitor
	filename = "cammon"
	filedesc = "Camera Monitoring"
	program_icon_state = "cameras"
	program_key_icon_state = "yellow_key"
	extended_desc = "This program allows remote access to station's camera system. Some camera networks may have additional access requirements."
	size = 12
	available_on_ntnet = TRUE
	requires_ntnet = TRUE
	required_access_download = ACCESS_HEADS
	color = LIGHT_COLOR_ORANGE
	usage_flags = PROGRAM_CONSOLE | PROGRAM_LAPTOP
	tgui_id = "CameraMonitoring"
	var/obj/machinery/camera/current_camera
	var/current_network
	/// Used for camera monitor consoles from which this interface can be launched. If it exists, only provide that console's "console_networks" networks.
	var/list/monitored_networks = list()

	/// The turf where the camera was last updated.
	var/turf/last_camera_turf
	var/list/concurrent_users = list()

	/// Needed to render the map
	var/camera_map_name

	var/stay_connected = FALSE

/datum/computer_file/program/camera_monitor/New()
	. = ..()
	RegisterSignal(src, COMSIG_CAMERA_MAPNAME_ASSIGNED, PROC_REF(camera_mapname_update))

	// camera setup
	AddComponent(/datum/component/camera_manager)
	SEND_SIGNAL(src, COMSIG_CAMERA_CLEAR)

/datum/computer_file/program/camera_monitor/Destroy()
	current_camera = null
	UnregisterSignal(src, COMSIG_CAMERA_MAPNAME_ASSIGNED)
	last_camera_turf = null
	concurrent_users = null
	return ..()

/datum/computer_file/program/camera_monitor/proc/camera_mapname_update(source, value)
	camera_map_name = value

/datum/computer_file/program/camera_monitor/ui_data(mob/user)
	var/list/data = initial_data()

	data["activeCamera"] = current_camera ? current_camera.camera_data() : null
	data["currentNetwork"] = current_network

	var/list/all_networks = list()
	var/list/available_networks = list()

	// If this UI was generated from a camera monitoring console, then only that console's networks will be available...
	if(monitored_networks && (length(monitored_networks) >= 1))
		available_networks = monitored_networks

	// ...otherwise (if it was launched from a standard modular computer), get all networks to which the user has access.
	else
		available_networks = SSatlas.current_map.station_networks

	for(var/network in available_networks)
		all_networks += list(
			list(
				"tag" = network,
				"has_access" = can_access_network(user, get_camera_access(network))
			)
		)

	all_networks = modify_networks_list(all_networks)

	data["allNetworks"] = all_networks

	return data

/datum/computer_file/program/camera_monitor/ui_static_data(mob/user)
	var/list/data = list()

	data["mapRef"] = camera_map_name
	var/list/cameras = get_available_cameras()
	data["cameras"] = list()
	for(var/i in cameras)
		var/obj/machinery/camera/C = cameras[i]
		data["cameras"] += list(list(
			name = C.c_tag,
		))
	if(current_camera)
		data["activeCamera"] = list(
			name = current_camera.c_tag,
			status = current_camera.status,
		)

	if(current_network)
		data["cameras"] = GLOB.camera_repository.cameras_in_network(current_network)

	return data

/datum/computer_file/program/camera_monitor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(action == "switch_camera")
		var/c_tag = params["name"]
		var/list/cameras = get_available_cameras()
		var/obj/machinery/camera/selected_camera
		selected_camera = cameras[c_tag]
		// Unicode breaks c_tags
		// Currently the only issues with character names comes from the improper or proper tags and so we strip and recheck if not found.
		if(!selected_camera)
			for(var/I in cameras)
				if(sanitize(I) == c_tag)
					selected_camera = cameras[I]
					break
		current_camera = selected_camera

		if(!selected_camera)
			return TRUE

		SEND_SIGNAL(src, COMSIG_CAMERA_SET_TARGET, selected_camera, selected_camera.view_range, selected_camera.view_range)

		return TRUE

/datum/computer_file/program/camera_monitor/ui_close(mob/user)
	var/user_ref = WEAKREF(user)
	var/is_living = isliving(user)
	// Living creature or not, we remove you anyway.
	concurrent_users -= user_ref
	// Unregister map objects
	SEND_SIGNAL(src, COMSIG_CAMERA_UNREGISTER_UI, user)
	// Turn off the console
	if(length(concurrent_users) == 0 && is_living && !stay_connected)
		current_camera = null
		SEND_SIGNAL(src, COMSIG_CAMERA_CLEAR)
		last_camera_turf = null

/datum/computer_file/program/camera_monitor/proc/modify_networks_list(var/list/networks)
	return networks

/datum/computer_file/program/camera_monitor/proc/check_network_access(var/mob/user, var/access)
	if(!access)
		return 1

	if(!istype(user))
		return 0

	var/obj/item/card/id/I = user.GetIdCard()
	if(!I)
		return 0

	if(access in I.access)
		return 1

	return 0

/datum/computer_file/program/camera_monitor/proc/can_access_network(var/mob/user, var/network_access)
	// No access passed, or 0 which is considered no access requirement. Allow it.
	if(!network_access)
		return TRUE

	return (check_network_access(user, ACCESS_SECURITY) && GLOB.security_level >= SEC_LEVEL_BLUE) || check_network_access(user, network_access)

// Returns the list of cameras accessible from this computer
/datum/computer_file/program/camera_monitor/proc/get_available_cameras()
	var/list/available_networks = list()

	// If this UI was generated from a camera monitoring console, then only that console's networks will be available...
	if(monitored_networks && (length(monitored_networks) >= 1))
		available_networks = monitored_networks

	// ...otherwise (if it was launched from a standard modular computer), get all networks to which the user has access.
	else
		available_networks = SSatlas.current_map.station_networks

	var/list/camera_list = list()
	for(var/network in available_networks)
		for(var/obj/machinery/camera/C in GLOB.camera_repository.cameras_in_network(network))
			camera_list |= C
	return camera_list

/datum/computer_file/program/camera_monitor/proc/switch_to_camera(var/mob/user, var/obj/machinery/camera/C)
	//don't need to check if the camera works for AI because the AI jumps to the camera location and doesn't actually look through cameras.
	if(isAI(user))
		var/mob/living/silicon/ai/A = user
		// Only allow non-carded AIs to view because the interaction with the eye gets all wonky otherwise.
		if(!A.is_in_chassis())
			return FALSE

		A.eyeobj.setLoc(get_turf(C))
		A.client.eye = A.eyeobj
		return TRUE

	if(!is_contact_area(get_area(C)))
		to_chat(user, SPAN_NOTICE("This camera is too far away to connect to!"))
		return FALSE

	set_current(C)
	user.set_machine(ui_host())
	user.reset_view(current_camera)
	check_eye(user)

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.handle_vision()

	return TRUE

/datum/computer_file/program/camera_monitor/proc/set_current(var/obj/machinery/camera/C)
	if(current_camera == C)
		return

	if(current_camera)
		reset_current()

	current_camera = C
	if(current_camera)
		var/mob/living/L = current_camera.loc
		if(istype(L))
			L.tracking_initiated()

/datum/computer_file/program/camera_monitor/proc/reset_current()
	if(current_camera)
		var/mob/living/L = current_camera.loc
		if(istype(L))
			L.tracking_cancelled()
	current_camera = null

/datum/computer_file/program/camera_monitor/check_eye(var/mob/user as mob)
	var/obj/item/modular_computer/MC = user.machine
	if(istype(MC) && ui_host() == MC)
		if(!MC.working || user.blinded || user.stat)
			user.unset_machine()
			return -1
	if(!current_camera)
		return 0
	var/viewflag = current_camera.check_eye(user)
	if ( viewflag < 0 ) //camera doesn't work
		reset_current()
	return viewflag

/datum/computer_file/program/camera_monitor/grants_equipment_vision(mob/user)
	var/obj/item/modular_computer/MC = user.machine
	if(istype(MC) && ui_host() == MC)
		if(!MC.working || user.blinded || user.stat)
			return FALSE
	if(!current_camera)
		return FALSE
	var/viewflag = current_camera.check_eye(user)
	if (viewflag < 0) //camera doesn't work
		return FALSE
	return TRUE

// ERT Variant of the program
/datum/computer_file/program/camera_monitor/ert
	filename = "ntcammon"
	filedesc = "Advanced Camera Monitoring"
	extended_desc = "This program allows remote access to station's camera system. Some camera networks may have additional access requirements. This version has an integrated database with additional encrypted keys."
	size = 14
	nanomodule_path = /datum/nano_module/camera_monitor/ert
	available_on_ntnet = FALSE

/datum/nano_module/camera_monitor/ert
	name = "Advanced Camera Monitoring Program"
	available_to_ai = FALSE

// The ERT variant has access to ERT and crescent cams, but still checks for accesses. ERT members should be able to use it.
/datum/computer_file/program/camera_monitor/ert/modify_networks_list(var/list/networks)
	..()
	networks.Add(list(list("tag" = NETWORK_ERT, "has_access" = 1)))
	networks.Add(list(list("tag" = NETWORK_CRESCENT, "has_access" = 1)))
	return networks

/datum/computer_file/program/camera_monitor/news
	filename = "idcammon"
	filedesc = "Journalism Camera Monitoring"
	extended_desc = "This program allows remote access to station's camera system. Some camera networks may have additional access requirements. This version has has a connection to news networks."
	size = 2
	nanomodule_path = /datum/nano_module/camera_monitor/news
	required_access_download = null
	usage_flags = PROGRAM_ALL

/datum/nano_module/camera_monitor/news
	name = "Journalism Camera Monitoring Program"

/datum/computer_file/program/camera_monitor/news/modify_networks_list(var/list/networks)
	networks = list()
	networks.Add(list(list("tag" = NETWORK_NEWS, "has_access" = 1)))
	networks.Add(list(list("tag" = NETWORK_THUNDER, "has_access" = 1)))
	return networks
