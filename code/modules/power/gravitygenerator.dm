#define POWER_IDLE 0
#define POWER_UP 1
#define POWER_DOWN 2

#define GRAV_OPERATIONAL 0
#define GRAV_NEEDS_SCREWDRIVER 1
#define GRAV_NEEDS_WELDING 2
#define GRAV_NEEDS_PLASTEEL 3
#define GRAV_NEEDS_WRENCH 4

#define AREA_ERRNONE 0
#define AREA_STATION 1
#define AREA_SPACE 2
#define AREA_SPECIAL 3

/obj/machinery/gravity_generator
	name = "gravity generator"
	desc = "A complex and energy-hungry device which produces a graviton field over a modest radius when active."
	// The /small variant is much more common and also, in general, less of a giant pain in the ass.
	// OR IT WILL BE ONCE ADDED
	icon = 'icons/obj/machinery/gravgen_small.dmi'
	idle_power_usage = 300
	active_power_usage = 30 KILO WATTS
	anchored = TRUE
	density = TRUE
	use_power = POWER_USE_OFF
	unacidable = 1
	light_color = LIGHT_COLOR_CYAN
	light_power = 1
	light_range = 6
	interact_offline = TRUE
	/// Whether the gravity generator is currently active.
	var/on = TRUE
	/// If the main breaker is on/off, to enable/disable gravity.
	var/breaker = TRUE
	/// If the generatir os idle, charging, or down.
	var/charging_state = POWER_IDLE
	/// How much charge the gravity generator has, goes down when breaker is shut, and shuts down at 0.
	var/charge_count = 100
	/// The gravity core overlay currently used.
	var/current_overlay = null
	/// Currently configured gravity strength.
	var/setting = STANDARD_GRAVITY
	/// Audio for when the gravgen is on
	var/datum/looping_sound/gravgen/soundloop
	/// Areas currently affected by the generator.
	var/list/localareas = list()
	/// We don't use the parent's panel_open var, because the gravgen needs a crowbar and not a screwdriver to open it.
	/// This may change if in the future machinery allows for different tools to toggle panel_open, but for now...
	var/panel_open_heavy = FALSE
	/// Legacy round start bug craziness, who knows. I wasn't going to fuck with it.
	var/round_start = 2
	/// Radiation generated during startup/shutdown. Mostly so small offships don't roast their entire ships.
	var/radiation_strength = 5

/obj/machinery/gravity_generator/large
	name = "wide-field gravity generator"
	desc = "A complex and energy-hungry device which produces a graviton field over a wide radius when active."
	// The /small variant is much more common and also, in general, less of a giant pain in the ass.
	// OR IT WILL BE ONCE ADDED
	icon = 'icons/obj/machinery/gravgen_large.dmi'
	idle_power_usage = 300
	active_power_usage = 600 KILO WATTS
	light_range = 8
	/// When broken, what stage it is at (GRAV_OPERATIONAL:0) (GRAV_NEEDS_SCREWDRIVER:1) (GRAV_NEEDS_WELDING:2) (GRAV_NEEDS_PLASTEEL:3) (GRAV_NEEDS_WRENCH:4)
	var/broken_state = GRAV_OPERATIONAL
	/// Whether or not the generator is currently affected by the Gravity Generator Failure event.
	var/event_active = FALSE
	radiation_strength = 20

/obj/machinery/gravity_generator/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "The emergency access panel can be pried [panel_open_heavy ? "opened" : "closed"] with a crowbar."

/obj/machinery/gravity_generator/large/assembly_hints(mob/user, distance, is_adjacent)
	. += ..()
	switch(broken_state)
		if(GRAV_NEEDS_SCREWDRIVER)
			. += "The remaining maintenance panels only need to be <b>screwed</b> closed."
		if(GRAV_NEEDS_WELDING)
			. += "Several of the new replacement parts will need to be <b>welded</b> into place to secure them."
		if(GRAV_NEEDS_PLASTEEL)
			. += "Replacing several broken components will require <b>ten sheets of plasteel</b>."
		if(GRAV_NEEDS_WRENCH)
			. += "Many of the generator's securing bolts will need to be <b>wrenched</b> back down to the floor plating."

// Generator which spawns with the station.
/obj/machinery/gravity_generator/large/station/Initialize()
	. = ..()
	AddOverlays("gravgen_core_active")
	update_gravity_for_localareas(TRUE)
	addtimer(CALLBACK(src, PROC_REF(round_startset)), 100)

/obj/machinery/gravity_generator/large/station/proc/round_startset()
	if(round_start >= 1)
		round_start--
		set_light(8,1,LIGHT_COLOR_CYAN)

// Generator an admin can spawn
/obj/machinery/gravity_generator/large/station/admin/Initialize()
	. = ..()
	round_start = 1



/obj/machinery/gravity_generator/large/proc/eventshutofftoggle() // Used by the gravity event. Bypasses charging and all of that stuff.
	breaker = 0
	set_state(event_active)
	sleep(20)
	charge_count = 0
	breaker = 1
	charging_state = POWER_UP
	set_power()
	event_active = !event_active
	addtimer(CALLBACK(src, PROC_REF(reset_event)), 100) // Because it takes 100 seconds for it to recharge. And we need to make sure we resen this var

/obj/machinery/gravity_generator/large/proc/reset_event()
	event_active = !event_active

// Functions governing condition of the generator
/obj/machinery/gravity_generator/Destroy()
	LOG_DEBUG("Gravity Generator Destroyed")
	investigate_log("was destroyed!", "gravity")
	on = 0
	QDEL_NULL(soundloop)
	update_gravity_for_localareas(TRUE)
	linked?.gravity_generator = null
	return ..()

/obj/machinery/gravity_generator/large/ex_act(severity)
	if(severity == 2) // Sturdy.
		set_broken()

/obj/machinery/gravity_generator/large/set_broken()
	stat |= BROKEN
	ClearOverlays()
	charge_count = 0
	breaker = 0
	set_power()
	set_state(0)
	investigate_log("has broken down.", "gravity")

/obj/machinery/gravity_generator/large/set_fix()
	stat &= ~BROKEN
	broken_state = GRAV_OPERATIONAL
	update_icon()
	set_power()

// Interaction
/// Open the panel on both large and small grav generators
/obj/machinery/gravity_generator/attackby(obj/item/attacking_item, mob/user)
	var/old_broken_state = broken_state
	switch(broken_state)
		if(GRAV_NEEDS_SCREWDRIVER)
			if(attacking_item.tool_behaviour == TOOL_SCREWDRIVER)
				to_chat(user, SPAN_NOTICE("You secure the screws of the framework."))
				attacking_item.play_tool_sound(get_turf(src), 50)
				broken_state++
		if(GRAV_NEEDS_WELDING)
			if(attacking_item.tool_behaviour == TOOL_WELDER)
				var/obj/item/weldingtool/WT = attacking_item
				if(WT.use(1, user))
					to_chat(user, SPAN_NOTICE("You mend the damaged framework."))
					playsound(src.loc, 'sound/items/welder_pry.ogg', 50, 1)
					broken_state++
		if(GRAV_NEEDS_PLASTEEL)
			if(istype(attacking_item, /obj/item/stack/material/plasteel))
				var/obj/item/stack/material/plasteel/PS = attacking_item
				if(PS.amount >= 10)
					PS.use(10)
					to_chat(user, SPAN_NOTICE("You add the plating to the framework."))
					playsound(src.loc, 'sound/machines/click.ogg', 75, 1)
					broken_state++
				else
					to_chat(user, SPAN_NOTICE("You need 10 sheets of plasteel."))
		if(GRAV_NEEDS_WRENCH)
			if(attacking_item.tool_behaviour == TOOL_WRENCH)
				to_chat(user, SPAN_NOTICE("You secure the plating to the framework."))
				attacking_item.play_tool_sound(get_turf(src), 75)
				set_fix()
		else
			..()
	if(attacking_item.tool_behaviour == TOOL_CROWBAR)
		if(panel_open_heavy)
			attacking_item.play_tool_sound(get_turf(src), 50)
			to_chat(user, SPAN_NOTICE("You replace the primary access panel."))
			panel_open_heavy = FALSE
		else
			attacking_item.play_tool_sound(get_turf(src), 50)
			to_chat(user, SPAN_NOTICE("You open the primary access  panel."))
			panel_open_heavy = TRUE

	if(old_broken_state != broken_state)
		update_icon()
/// Fixing the gravity generator.
/obj/machinery/gravity_generator/large/attackby(obj/item/attacking_item, mob/user)
	var/old_broken_state = broken_state
	switch(broken_state)
		if(GRAV_NEEDS_SCREWDRIVER)
			if(attacking_item.tool_behaviour == TOOL_SCREWDRIVER)
				to_chat(user, SPAN_NOTICE("You secure the screws of the framework."))
				attacking_item.play_tool_sound(get_turf(src), 50)
				broken_state++
		if(GRAV_NEEDS_WELDING)
			if(attacking_item.tool_behaviour == TOOL_WELDER)
				var/obj/item/weldingtool/WT = attacking_item
				if(WT.use(1, user))
					to_chat(user, SPAN_NOTICE("You mend the damaged framework."))
					playsound(src.loc, 'sound/items/welder_pry.ogg', 50, 1)
					broken_state++
		if(GRAV_NEEDS_PLASTEEL)
			if(istype(attacking_item, /obj/item/stack/material/plasteel))
				var/obj/item/stack/material/plasteel/PS = attacking_item
				if(PS.amount >= 10)
					PS.use(10)
					to_chat(user, SPAN_NOTICE("You add the plating to the framework."))
					playsound(src.loc, 'sound/machines/click.ogg', 75, 1)
					broken_state++
				else
					to_chat(user, SPAN_NOTICE("You need 10 sheets of plasteel."))
		if(GRAV_NEEDS_WRENCH)
			if(attacking_item.tool_behaviour == TOOL_WRENCH)
				to_chat(user, SPAN_NOTICE("You secure the plating to the framework."))
				attacking_item.play_tool_sound(get_turf(src), 75)
				set_fix()
		else
			..()
	if(attacking_item.tool_behaviour == TOOL_CROWBAR)
		if(panel_open_heavy)
			attacking_item.play_tool_sound(get_turf(src), 50)
			to_chat(user, SPAN_NOTICE("You replace the primary access panel."))
			panel_open_heavy = FALSE
		else
			attacking_item.play_tool_sound(get_turf(src), 50)
			to_chat(user, SPAN_NOTICE("You open the primary access  panel."))
			panel_open_heavy = TRUE

	if(old_broken_state != broken_state)
		update_icon()

/obj/machinery/gravity_generator/attack_hand(mob/user as mob)
	if(!..())
		return interact(user)

/obj/machinery/gravity_generator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GravityGenerator", name)
		ui.open()

/obj/machinery/gravity_generator/ui_data(mob/user)
	var/list/data = list()

	data["breaker"] = breaker
	data["charge_count"] = charge_count
	data["charging_state"] = charging_state
	data["on"] = on
	data["operational"] = (stat & BROKEN) ? FALSE : TRUE

	return data

/obj/machinery/gravity_generator/large/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("gentoggle")
			breaker = !breaker
			set_power()
			. = TRUE

/obj/machinery/gravity_generator/large/interact(mob/user as mob)
	if(stat & BROKEN)
		return
	var/dat = "Gravity Generator Breaker: "
	if(!event_active)
		if(breaker)
			dat += "<span class='linkOn'>ON</span> <A href='byond://?src=[REF(src)];gentoggle=1'>OFF</A>"
		else
			dat += "<A href='byond://?src=[REF(src)];gentoggle=1'>ON</A> <span class='linkOn'>OFF</span> "
		if(panel_open_heavy)
			dat += "<br>Emergency shutoff:<br>"
			dat += "<A href='byond://?src=[REF(src)];eshutoff=1'>Red Button</A>"

		dat += "<br>Generator Status:<br><div class='statusDisplay'>"
		if(charging_state != POWER_IDLE)
			dat += "<font class='bad'>WARNING</font> Radiation Detected. <br>[charging_state == POWER_UP ? "Charging..." : "Discharging..."]"
		else if(on)
			dat += "Powered."
		else
			dat += "Unpowered."

		dat += "<br>Gravity Charge: [charge_count]%</div>"
	else
		dat += "<h3><font class='bad'>ERROR: SYSTEM MALFUNCTION. PLEASE WAIT...</font></h3>"
	var/datum/browser/popup = new(user, "gravgen", name)
	popup.set_content(dat)
	popup.open()

/obj/machinery/gravity_generator/large/Topic(href, href_list)

	if(..())
		return

	if(href_list["gentoggle"])
		breaker = !breaker
		investigate_log("was toggled [breaker ? "<font color='green'>ON</font>" : SPAN_WARNING("OFF")] by [usr.key].", "gravity")
		set_power()
		src.updateUsrDialog()
	else if(href_list["eshutoff"])
		investigate_log("was shut off by [usr.key].", "gravity")
		eshutoff()

/obj/machinery/gravity_generator/power_change()
	..()
	breaker = (stat & NOPOWER) ? FALSE : TRUE
	set_power()
	investigate_log("has [stat & NOPOWER ? "lost" : "regained"] power.", "gravity")

/obj/machinery/gravity_generator/proc/eshutoff()
	if(charge_count > 0)
		charge_count = 0
		playsound(src.loc, 'sound/effects/EMPulse.ogg', 100, 1)
		SSradiation.radiate(src, 100)
		set_state(0)
		ClearOverlays()
		if(prob(1)) //It will spawn a small one and eat the generator. Won't cause any other issues considering it's a 1x1 and will go away on it's own.
			new /obj/singularity(src.loc)
		if(prob(33)) //Releasing all that power at once is dangerous.
			empulse(src.loc, 2, 4)
		set_light(10,1,LIGHT_COLOR_FLARE)
		sleep(5)
		set_light(5,0.5,LIGHT_COLOR_FIRE)
		sleep(5)
		set_light(0,0,"#000000")

/obj/machinery/gravity_generator/update_icon()
	..()
	ClearOverlays()
	if(on)
		AddOverlays("gravgen_lights")
	if(panel_open_heavy)
		AddOverlays("gravgen_open")
	var/overlay_state = null
	switch(charge_count)
		if(0 to 20)
			overlay_state = null
		if(21 to 40)
			overlay_state = "gravgen_core_startup"
		if(41 to 60)
			overlay_state = "gravgen_core_idle"
		if(61 to 80)
			overlay_state = "gravgen_core_activating"
		if(81 to 100)
			overlay_state = "gravgen_core_active"

	if(overlay_state && (overlay_state != current_overlay))
		AddOverlays(overlay_state)

	current_overlay = overlay_state

/// Only the large gravity generator has various broken icon_states.
/obj/machinery/gravity_generator/large/update_icon()
	..()
	if(stat & BROKEN)
		icon_state = "gravgen_fix[min(broken_state, 3)]"

/// Set the charging state based on power/breaker.
/obj/machinery/gravity_generator/proc/set_power()
	var/new_state = 0
	if(stat & (NOPOWER|BROKEN) || !breaker)
		new_state = 0
	else if(breaker)
		new_state = 1

	charging_state = new_state ? POWER_UP : POWER_DOWN // Startup sequence animation.
	investigate_log("is now [charging_state == POWER_UP ? "charging" : "discharging"].", "gravity")
	update_icon()

// Set the state of the gravity.
/obj/machinery/gravity_generator/proc/set_state(var/new_state)
	charging_state = POWER_IDLE
	var/gravity_changed = (on != new_state)
	on = new_state
	update_use_power(on ? POWER_USE_ACTIVE : POWER_USE_IDLE)
	// Sound the alert if gravity was just enabled or disabled.
	var/alert = 0
	var/area/area = get_area(src)
	var/areadisplayname = get_area_display_name(area)
	if(new_state) // If we turned on
		if(!area.has_gravity())
			alert = 1
			soundloop.start(src)
			investigate_log("was brought online and is now producing gravity for this level.", "gravity")
			message_admins("The gravity generator was brought online. (<A href='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[x];Y=[y];Z=[z]'>[areadisplayname]</a>)")
	else
		if(area.has_gravity())
			alert = 1
			soundloop.stop(src)
			investigate_log("was brought offline and there is now no gravity for this level.", "gravity")
			message_admins("The gravity generator was brought offline with no backup generator. (<A href='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[x];Y=[y];Z=[z]'>[areadisplayname]</a>)")

	update_icon()
	update_gravity_for_localareas(gravity_changed)
	src.updateUsrDialog()
	if(alert)
		shake_everyone()

// Charge/Discharge and turn on/off gravity when you reach 0/100 percent.
// Also emit radiation and handle the overlays.
/obj/machinery/gravity_generator/process()
	if(stat & BROKEN)
		return
	if(charging_state != POWER_IDLE)
		if(charging_state == POWER_UP && charge_count >= 100)
			set_state(1)
		else if(charging_state == POWER_DOWN && charge_count <= 0)
			set_state(0)
		else
			if(charging_state == POWER_UP)
				charge_count += rand(1,5)
			else if(charging_state == POWER_DOWN)
				charge_count -= rand(1,5)

			if(charge_count % 4 == 0 && prob(75)) // Let them know it is charging/discharging.
				playsound(src.loc, 'sound/effects/phasein.ogg', 100, 1)

			updateDialog()
			if(prob(30)) // To help stop "Your clothes feel warm" spam.
				SSradiation.radiate(src, radiation_strength)

	var/overlay_state = null
	switch(charge_count)
		if(0 to 20)
			overlay_state = null
			set_light(0,0,"#000000")
		if(21 to 40)
			overlay_state = "gravgen_core_startup"
			set_light(4,0.2,LIGHT_COLOR_BLUE)
		if(41 to 60)
			overlay_state = "gravgen_core_idle"
			set_light(6,0.5,"#7D9BFF")
		if(61 to 80)
			overlay_state = "gravgen_core_activating"
			set_light(6,0.8,"#7DC3FF")
		if(81 to 100)
			overlay_state = "gravgen_core_active"
			set_light(8,1,LIGHT_COLOR_CYAN)

	if(overlay_state != current_overlay)
		update_icon()

/// Shake everyone on the z level to let them know that gravity was enagaged/disenagaged.
/obj/machinery/gravity_generator/proc/shake_everyone()
	var/turf/our_turf = get_turf(src)
	var/list/connected_z_levels = GetConnectedZlevels(our_turf.z)
	for(var/mob/living/M in GLOB.mob_list)
		if(M.z in connected_z_levels)
			M.update_gravity(M.mob_has_gravity())
			if(M.client)
				if(!M)	return
				shake_camera(M, 5, 1)
				M.playsound_local(our_turf, 'sound/effects/alert.ogg', 100, vary = TRUE, falloff_distance = 0.5)

/// Update the current gravity in all areas in localareas.
/obj/machinery/gravity_generator/proc/update_gravity_for_localareas(var/gravity_changed = FALSE)
	var/turf/T = get_turf(src.loc)
	if(T)
		if(!SSmachinery.gravity_generators)
			SSmachinery.gravity_generators = list()

		if(on && gravity_changed)
			for(var/area/A in localareas)
				A.gravitychange(TRUE)
			SSmachinery.gravity_generators += src
		else if (!on)
			for(var/area/A in localareas)
				A.gravitychange(FALSE)
			SSmachinery.gravity_generators -= src

/obj/machinery/gravity_generator/Initialize()
	. = ..()
	soundloop = new(src, start_immediately = FALSE)
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/gravity_generator/LateInitialize()
	..()
	if(SSatlas.current_map.use_overmap && !linked)
		var/my_sector = GLOB.map_sectors["[z]"]
		if (istype(my_sector, /obj/effect/overmap/visitable))
			attempt_hook_up(my_sector)
	if(linked)
		linked.gravity_generator = src
		updateareas()

/obj/machinery/gravity_generator/proc/updateareas()
	for(var/area/A in GLOB.the_station_areas)
		if(!(get_area_type(A) == AREA_STATION))
			continue
		localareas += A

/obj/machinery/gravity_generator/proc/get_area_type(var/area/A = get_area(src))
	if (A.name == "Space")
		return AREA_SPACE
	else if(A.alwaysgravity == TRUE || A.nevergravity == TRUE)
		return AREA_SPECIAL
	else
		return AREA_STATION

/obj/machinery/gravity_generator/proc/throw_up_and_down()
	to_world("<h2 class='alert'>Station Announcement:</h2>")
	to_world(SPAN_DANGER("Warning! Localized Gravity Failure. Brace for dangerous gravity change!"))
	addtimer(CALLBACK(src, PROC_REF(set_state), FALSE), 5 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(throw_carbons_down)), 3 SECONDS)

/// Sort of like set_state(TRUE), but angrily. In the future maybe we have an additional argument that modulates the strength with which gravity is reasserted.
/obj/machinery/gravity_generator/proc/throw_carbons_down()
	set_state(TRUE)
	var/turf/our_turf = get_turf(src)
	var/list/connected_z_levels = GetConnectedZlevels(src.z)
	for(var/mob/living/M in GLOB.mob_list)
		if(M.z in connected_z_levels)
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				var/obj/item/clothing/shoes/magboots/boots = H.get_equipped_item(slot_shoes)
				if(istype(boots))
					continue
			to_chat(M, SPAN_DANGER("The gravity abruptly cuts back in after reversing, but with such initial force that it slams you back down to the floor!"))
			M.fall_impact(1)

#undef POWER_IDLE
#undef POWER_UP
#undef POWER_DOWN

#undef GRAV_NEEDS_SCREWDRIVER
#undef GRAV_NEEDS_WELDING
#undef GRAV_NEEDS_PLASTEEL
#undef GRAV_NEEDS_WRENCH

#undef AREA_ERRNONE
#undef AREA_STATION
#undef AREA_SPACE
#undef AREA_SPECIAL
