#define DEFAULT_CAMERA_MAP_SIZE 15

/datum/component/camera_manager
	var/map_name
	var/atom/current
	var/atom/movable/screen/map_view/cam_screen
	var/atom/movable/screen/background/cam_background
	var/turf/last_camera_turf
	var/target_width
	var/target_height
	var/list/cam_plane_masters

/datum/component/camera_manager/Initialize()
	. = ..()
	map_name = "camera_manager_[REF(src)]_map"

	cam_screen = new
	cam_screen.icon = null
	cam_screen.name = "screen"
	cam_screen.assigned_map = map_name
	cam_screen.del_on_map_removal = FALSE
	cam_screen.screen_loc = "[map_name]:1,1"
	cam_screen.appearance_flags |= TILE_BOUND

	cam_background = new
	cam_background.assigned_map = map_name
	cam_background.del_on_map_removal = FALSE
	cam_background.appearance_flags |= TILE_BOUND

	cam_plane_masters = list()
	for(var/plane_type in subtypesof(/atom/movable/screen/plane_master) - /atom/movable/screen/plane_master/rendering_plate - /atom/movable/screen/plane_master/open_space)
		var/atom/movable/screen/plane_master/instance = new plane_type()
		add_plane(instance)

/datum/component/camera_manager/Destroy(force, ...)
	QDEL_LIST_ASSOC_VAL(cam_plane_masters)
	QDEL_NULL(cam_background)
	QDEL_NULL(cam_screen)
	if(current)
		UnregisterSignal(current, COMSIG_QDELETING)
	current = null
	last_camera_turf = null
	. = ..()

/datum/component/camera_manager/proc/add_plane(atom/movable/screen/plane_master/instance)
	instance.assigned_map = map_name
	instance.appearance_flags |= TILE_BOUND
	instance.del_on_map_removal = FALSE
	if(instance.blend_mode_override)
		instance.blend_mode = instance.blend_mode_override
	instance.screen_loc = "[map_name]:CENTER"
	cam_plane_masters["[instance.plane]"] = instance

/datum/component/camera_manager/proc/register(source, mob/user)
	SIGNAL_HANDLER
	var/client/user_client = user.client
	if(!user_client)
		return
	user_client.register_map_obj(cam_screen)
	user_client.register_map_obj(cam_background)
	for(var/plane_id in cam_plane_masters)
		user_client.register_map_obj(cam_plane_masters[plane_id])

/datum/component/camera_manager/proc/unregister(source, mob/user)
	SIGNAL_HANDLER
	user.client?.clear_map(map_name)

/datum/component/camera_manager/RegisterWithParent()
	. = ..()
	SEND_SIGNAL(parent, COMSIG_CAMERA_MAPNAME_ASSIGNED, map_name)
	RegisterSignal(parent, COMSIG_CAMERA_REGISTER_UI, PROC_REF(register))
	RegisterSignal(parent, COMSIG_CAMERA_UNREGISTER_UI, PROC_REF(unregister))
	RegisterSignal(parent, COMSIG_CAMERA_SET_TARGET, PROC_REF(set_camera))
	RegisterSignal(parent, COMSIG_CAMERA_CLEAR, PROC_REF(clear_camera))
	RegisterSignal(parent, COMSIG_CAMERA_REFRESH, PROC_REF(refresh_camera))

/datum/component/camera_manager/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_CAMERA_REGISTER_UI)
	UnregisterSignal(parent, COMSIG_CAMERA_UNREGISTER_UI)
	UnregisterSignal(parent, COMSIG_CAMERA_SET_TARGET)
	UnregisterSignal(parent, COMSIG_CAMERA_CLEAR)
	UnregisterSignal(parent, COMSIG_CAMERA_REFRESH)

/datum/component/camera_manager/proc/clear_camera()
	SIGNAL_HANDLER
	if(current)
		UnregisterSignal(current, COMSIG_QDELETING)
	current = null
	target_width = null
	target_height = null
	show_camera_static()

/datum/component/camera_manager/proc/refresh_camera()
	SIGNAL_HANDLER
	update_target_camera()

/datum/component/camera_manager/proc/set_camera(source, atom/target, width, height)
	SIGNAL_HANDLER
	if(current)
		UnregisterSignal(current, COMSIG_QDELETING)
	current = target
	target_width = width
	target_height = height
	RegisterSignal(current, COMSIG_QDELETING, PROC_REF(show_camera_static))
	update_target_camera()

/datum/component/camera_manager/proc/show_camera_static()
	SIGNAL_HANDLER
	if(length(cam_screen.vis_contents))
		cam_screen.vis_contents.Cut()
	last_camera_turf = null
	cam_background.fill_rect(1, 1, DEFAULT_CAMERA_MAP_SIZE, DEFAULT_CAMERA_MAP_SIZE)

/datum/component/camera_manager/proc/update_target_camera()
	var/obj/structure/machinery/camera/camera = current
	if(!istype(camera) || !camera.can_use())
		show_camera_static()
		return

	var/atom/cam_location = camera
	if(isliving(camera.loc))
		cam_location = camera.loc
	else if(istype(camera.loc, /obj/item/clothing))
		var/obj/item/clothing/clothing = camera.loc
		cam_location = clothing.loc

	var/turf/new_turf = get_turf(cam_location)
	if(last_camera_turf == new_turf)
		return
	last_camera_turf = new_turf

	var/list/visible_things = camera.isXRay() ? range(camera.view_range, cam_location) : view(camera.view_range, cam_location)
	render_objects(visible_things)

/datum/component/camera_manager/proc/render_objects(list/visible_things)
	var/list/visible_turfs = list()
	for(var/turf/visible_turf in visible_things)
		visible_turfs += visible_turf

	if(!length(visible_turfs))
		show_camera_static()
		return

	var/low_x = world.maxx
	var/low_y = world.maxy
	var/high_x = 1
	var/high_y = 1
	for(var/turf/visible_turf as anything in visible_turfs)
		low_x = min(low_x, visible_turf.x)
		low_y = min(low_y, visible_turf.y)
		high_x = max(high_x, visible_turf.x)
		high_y = max(high_y, visible_turf.y)

	cam_screen.vis_contents = visible_turfs
	cam_background.fill_rect(1, 1, high_x - low_x + 1, high_y - low_y + 1)

#undef DEFAULT_CAMERA_MAP_SIZE
