/client
	/**
	 * Assoc list of active named maps and their registered screen objects.
	 *
	 * Format: list(<mapname> = list(/atom/movable/screen))
	 */
	var/list/screen_maps = list()

/atom/movable/screen
	/// Name of the BYOND map control this screen object is assigned to.
	var/assigned_map
	/// If TRUE, qdel this screen object when its assigned map is cleared.
	var/del_on_map_removal = TRUE

/atom/movable/screen/map_view
	layer = GAME_PLANE
	plane = GAME_PLANE

/atom/movable/screen/background
	name = "background"
	icon = null
	icon_state = null
	layer = GAME_PLANE
	plane = GAME_PLANE

/atom/movable/screen/proc/set_position(x, y, px = 0, py = 0)
	if(assigned_map)
		screen_loc = "[assigned_map]:[x]:[px],[y]:[py]"
	else
		screen_loc = "[x]:[px],[y]:[py]"

/atom/movable/screen/proc/fill_rect(x1, y1, x2, y2)
	if(assigned_map)
		screen_loc = "[assigned_map]:[x1],[y1] to [x2],[y2]"
	else
		screen_loc = "[x1],[y1] to [x2],[y2]"

/client/proc/register_map_obj(atom/movable/screen/screen_obj)
	if(!screen_obj.assigned_map)
		CRASH("Can't register [screen_obj] without an assigned_map.")
	if(!screen_maps[screen_obj.assigned_map])
		screen_maps[screen_obj.assigned_map] = list()
	var/list/screen_map = screen_maps[screen_obj.assigned_map]
	if(!(screen_obj in screen_map))
		screen_map += screen_obj
	if(!(screen_obj in screen))
		add_to_screen(screen_obj)

/client/proc/clear_map(map_name)
	if(!map_name || !screen_maps[map_name])
		return FALSE
	for(var/atom/movable/screen/screen_obj as anything in screen_maps[map_name])
		remove_from_screen(screen_obj)
		if(screen_obj.del_on_map_removal)
			qdel(screen_obj)
	screen_maps -= map_name
	return TRUE

/client/proc/clear_all_maps()
	for(var/map_name in screen_maps)
		clear_map(map_name)
