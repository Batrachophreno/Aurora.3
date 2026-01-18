///////////////////////////////
//CONDUIT STRUCTURE
///////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////
/*
	Unlike standard Cable directions, which are defined by two terminal points (d1 + d2), Conduit directions are
	single static values. Because they are offset from the center of their tile, we can't just rotate them to
	cleanly connect them to their neighbors. Unlike Cables, which can only ever connect to two points, Conduits
	can instead each connect to a maximum of 5 directions (all cardinal directions and 0). Additionally, unlike
	with Cables, diagonal connections are disallowed for Conduits.

	>      1
	>      |
	>  8 - 0 - 4
	>      |
	>      2

	> z-level UP: 11
	> z_level DOWN: 12

	CONDUIT ID# : CONDUIT CONNECTION(S):
		0	:	0
		1	:	0-1
		2	:	0-2
		3	:	1-2
		4	:	0-4
		5	:	1-4
		6	:	2-4
		7	:	0-1-2-4
		8	:	0-8
		9	:	1-8
		10	:	2-8
		11	:	0-1-2-8
		12	:	4-8
		13	:	0-1-4-8
		14	:	0-2-4-8
		15	:	0-1-2-4-8
		16	:	0-11
		17	:	1-12
		18	:	2-12
		19	:	4-12
		20	:	8-12
*/

/obj/structure/conduit
	level = 1
	anchored = TRUE
	/// With what powernet is this conduit associated?
	var/datum/powernet/powernet
	name = "power conduit"
	desc = "A superconducting cable for heavy-duty electrical systems."
	icon = 'icons/obj/machinery/power/power_cond_hv.dmi'
	icon_state = "0"
	obj_flags = OBJ_FLAG_MOVES_UNSUPPORTED
	layer = EXPOSED_WIRE_LAYER
	color = COLOR_RED
	var/d1 = 0
	var/d2 = 1
	/// What voltage power does this conduit carry?
	var/voltage_level = POWER_VOLTAGE_ANY
	var/obj/machinery/power/breakerbox/breaker_box

/obj/structure/conduit/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	var/found_voltage_level = "variable"
	switch(voltage_level)
		if(POWER_VOLTAGE_LOW)
			found_voltage_level = "low"
		if(POWER_VOLTAGE_MEDIUM)
			found_voltage_level = "medium"
		if(POWER_VOLTAGE_HIGH)
			found_voltage_level = "high"
	. += "It is rated for <b>[found_voltage_level]-voltage</b> power transfer."

/obj/structure/conduit/drain_power(var/drain_check, var/surge, var/amount = 0)
	if(drain_check)
		return TRUE

	var/datum/powernet/PN = powernet
	if(!PN) return FALSE

	return PN.draw_power(amount)

/obj/structure/conduit/lv/yellow
	color = COLOR_YELLOW
/obj/structure/conduit/mv/yellow
	color = COLOR_YELLOW

/obj/structure/conduit/lv/green
	color = COLOR_LIME
/obj/structure/conduit/mv/green
	color = COLOR_LIME

/obj/structure/conduit/lv/blue
	color = COLOR_BLUE
/obj/structure/conduit/mv/blue
	color = COLOR_BLUE

/obj/structure/conduit/lv/pink
	color = COLOR_PINK
/obj/structure/conduit/mv/pink
	color = COLOR_PINK

/obj/structure/conduit/lv/orange
	color = COLOR_ORANGE
/obj/structure/conduit/mv/orange
	color = COLOR_ORANGE

/obj/structure/conduit/lv/cyan
	color = COLOR_CYAN
/obj/structure/conduit/mv/cyan
	color = COLOR_CYAN

/obj/structure/conduit/lv/white
	color = COLOR_WHITE
/obj/structure/conduit/mv/white
	color = COLOR_WHITE

/obj/structure/conduit/lv/black
	color = COLOR_GRAY30
/obj/structure/conduit/mv/black
	color = COLOR_GRAY30

// Needs to run before init or we have sad cable knots on away sites
/obj/structure/conduit/New()
	. = ..()
	// ensure d1 & d2 reflect the icon_state for entering and exiting cable
	var/dash = findtext(icon_state, "-")
	d1 = text2num(copytext(icon_state, 1, dash))
	d2 = text2num(copytext(icon_state, dash + 1))

/obj/structure/conduit/Initialize(mapload)
	. = ..()

	var/turf/T = src.loc			// hide if turf is not intact
	if(level == 1 && !T.is_hole)
		hide(!T.is_plating())

	GLOB.conduit_list += src

	if(mapload)
		var/image/I = image(icon, T, icon_state, dir, pixel_x, pixel_y)
		I.plane = ABOVE_LIGHTING_PLANE
		I.alpha = 125
		I.color = color
		LAZYADD(T.blueprints, I)

/obj/structure/conduit/Destroy()					// called when a cable is deleted
	if(powernet)
		cut_conduit_from_powernet()				// update the powernets
	GLOB.conduit_list -= src							//remove it from global cable list
	return ..()										// then go ahead and delete the cable

///////////////////////////////////
// General procedures
///////////////////////////////////

//If underfloor, hide the cable
/obj/structure/conduit/hide(var/i)
	if(istype(loc, /turf))
		set_invisibility(i ? 101 : 0)
	update_icon()

/obj/structure/conduit/hides_under_flooring()
	return TRUE

/obj/structure/conduit/update_icon()
	icon_state = "[d1]-[d2]"
	alpha = invisibility ? 127 : 255

//Telekinesis has no effect on conduit
/obj/structure/conduit/do_simple_ranged_interaction(var/mob/user)
	return

// Items usable on a conduit :
//   - Wirecutters : cut it!
//   - Conduit spool : merge conduits
//   - Multitool : get the power currently passing through the conduit
//
/obj/structure/conduit/attackby(obj/item/attacking_item, mob/user)

	var/turf/T = src.loc
	if(!T.can_have_cabling())
		return

	if(attacking_item.iswirecutter() || (attacking_item.sharp || attacking_item.edge))

		if(!attacking_item.iswirecutter())
			if(user.a_intent != I_HELP)
				return

			if(attacking_item.obj_flags & OBJ_FLAG_CONDUCTABLE)
				shock(user, 50, 0.7)

		if(d1 == 12 || d2 == 12)
			to_chat(user, SPAN_WARNING("You must cut this conduit from above."))
			return

		if(breaker_box)
			to_chat(user, SPAN_WARNING("This conduit is connected to a nearby breaker box. Use the breaker box to interact with it."))
			return

		if (shock(user, 50))
			return

		if(src.d1)	// 0-X cables are 1 unit, X-X cables are 2 units long
			new/obj/item/stack/cable_coil(T, 2, color)
		else
			new/obj/item/stack/cable_coil(T, 1, color)

		for(var/mob/O in viewers(src, null))
			O.show_message(SPAN_WARNING("[user] cuts the conduit."), 1)
			playsound(src.loc, 'sound/items/Wirecutter.ogg', 50, 1)

		if(d1 == 11 || d2 == 11)
			var/turf/turf = GET_TURF_BELOW(T)
			if(turf)
				for(var/obj/structure/conduit/c in turf)
					if(c.d1 == 12 || c.d2 == 12)
						qdel(c)

		investigate_log("was cut by [key_name(user, user.client)] in [user.loc.loc]","wires")

		qdel(src)
		return


	else if(attacking_item.iscoil())
		var/obj/item/stack/cable_coil/coil = attacking_item
		if (coil.get_amount() < 1)
			to_chat(user, "You don't have enough cable.")
			return
		coil.cable_join(src, user)

	else if(attacking_item.ismultitool())

		if(powernet && (powernet.avail > 0))		// is it powered?
			to_chat(user, SPAN_WARNING("[powernet.avail]W in power network."))

		else
			to_chat(user, SPAN_WARNING("The cable is not powered."))

		shock(user, 5, 0.2)

	src.add_fingerprint(user)

// shock the user with probability prb
/obj/structure/conduit/proc/shock(mob/user, prb, var/siemens_coeff = 1.0)
	if(!prob(prb))
		return FALSE
	if (electrocute_mob(user, powernet, src, siemens_coeff))
		spark(src, 5, GLOB.alldirs)
		if(user.stunned)
			return TRUE
	return FALSE

/obj/structure/conduit/attack_generic(mob/user, damage, attack_message, environment_smash, armor_penetration, attack_flags, damage_type)
	//Let those rats (and other small things) nibble the cables
	if (issmall(user) && !isDrone(user))
		to_chat(user, SPAN_DANGER("You bite into \the [src]."))
		if(powernet && powernet.avail > 100) //100W should be sufficient to grill a rat
			spark(src)
			user.dust()
	..()

//explosion handling
/obj/structure/conduit/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if (prob(50))
				new/obj/item/stack/cable_coil(src.loc, src.d1 ? 2 : 1, color)
				qdel(src)

		if(3.0)
			if (prob(25))
				new/obj/item/stack/cable_coil(src.loc, src.d1 ? 2 : 1, color)
				qdel(src)
	return

/obj/structure/conduit/proc/cableColor(var/colorC)
	var/color_n = "#DD0000"
	if(colorC)
		color_n = colorC
	color = color_n

/////////////////////////////////////////////////
// Cable laying helpers
////////////////////////////////////////////////

//handles merging diagonally matching cables
//for info : direction^3 is flipping horizontally, direction^12 is flipping vertically
/obj/structure/conduit/proc/mergeDiagonalsNetworks(var/direction)

	//search for and merge diagonally matching cables from the first direction component (north/south)
	var/turf/T  = get_step(src, direction&3)//go north/south

	for(var/obj/structure/conduit/C in T)

		if(!C)
			continue

		if(src == C)
			continue

		if(C.d1 == (direction^3) || C.d2 == (direction^3)) //we've got a diagonally matching cable
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_conduit(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet,C.powernet)
			else
				C.powernet.add_conduit(src) //else, we simply connect to the matching cable powernet

	//the same from the second direction component (east/west)
	T  = get_step(src, direction&12)//go east/west

	for(var/obj/structure/conduit/C in T)

		if(!C)
			continue

		if(src == C)
			continue
		if(C.d1 == (direction^12) || C.d2 == (direction^12)) //we've got a diagonally matching cable
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_conduit(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet,C.powernet)
			else
				C.powernet.add_conduit(src) //else, we simply connect to the matching cable powernet

// merge with the powernets of power objects in the given direction
/obj/structure/conduit/proc/mergeConnectedNetworks(var/direction)

	var/fdir = (!direction)? 0 : turn(direction, 180) //flip the direction, to match with the source position on its turf

	if(!(d1 == direction || d2 == direction)) //if the cable is not pointed in this direction, do nothing
		return

	var/turf/TB  = get_step(src, direction)

	for(var/obj/structure/conduit/C in TB)

		if(!C)
			continue

		if(src == C)
			continue

		if(C.d1 == fdir || C.d2 == fdir) //we've got a matching cable in the neighbor turf
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_conduit(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet,C.powernet)
			else
				C.powernet.add_conduit(src) //else, we simply connect to the matching cable powernet

// merge with the powernets of power objects in the source turf
/obj/structure/conduit/proc/mergeConnectedNetworksOnTurf()
	var/list/to_connect = list()

	if(!powernet) //if we somehow have no powernet, make one (should not happen for cables)
		var/datum/powernet/newPN = new()
		newPN.add_conduit(src)

	//first let's add turf cables to our powernet
	//then we'll connect machines on turf with a node cable is present
	for(var/AM in loc)
		if(istype(AM,/obj/structure/conduit))
			var/obj/structure/conduit/C = AM
			if(C.d1 == d1 || C.d2 == d1 || C.d1 == d2 || C.d2 == d2) //only connected if they have a common direction
				if(C.powernet == powernet)	continue
				if(C.powernet)
					merge_powernets(powernet, C.powernet)
				else
					powernet.add_conduit(C) //the cable was powernetless, let's just add it to our powernet

		else if(istype(AM,/obj/machinery/power/apc))
			var/obj/machinery/power/apc/N = AM
			if(!N.terminal)	continue // APC are connected through their terminal

			if(N.terminal.powernet == powernet)
				continue

			to_connect += N.terminal //we'll connect the machines after all cables are merged

		else if(istype(AM,/obj/machinery/power)) //other power machines
			var/obj/machinery/power/M = AM

			if(M.powernet == powernet)
				continue

			to_connect += M //we'll connect the machines after all cables are merged

	//now that cables are done, let's connect found machines
	for(var/obj/machinery/power/PM in to_connect)
		if(!PM.connect_to_network())
			PM.disconnect_from_network() //if we somehow can't connect the machine to the new powernet, remove it from the old nonetheless

//////////////////////////////////////////////
// Powernets handling helpers
//////////////////////////////////////////////

/// If powernetless_only = 1, will only get connections without powernet
/obj/structure/conduit/proc/get_connections(var/powernetless_only = FALSE)
	. = list()	// this will be a list of all connected power objects
	var/turf/T

	// Handle up/down conduits
	if(d1 == 11 || d2 == 11)
		var/turf/current_turf = get_turf(src)
		T = GET_TURF_BELOW(current_turf)
		if(T)
			. += power_list(T, src, 12, powernetless_only)

	if(d1 == 12 || d2 == 12)
		var/turf/current_turf = get_turf(src)
		T = GET_TURF_ABOVE(current_turf)
		if(T)
			. += power_list(T, src, 11, powernetless_only)

	// Handle standard conduits in adjacent turfs
	for(var/conduit_dir in list(d1, d2))
		if(conduit_dir == 11 || conduit_dir == 12 || conduit_dir == 0)
			continue
		var/reverse = REVERSE_DIR(conduit_dir)
		T = get_step(src, conduit_dir)
		if(T)
			for(var/obj/structure/conduit/C in T)
				if((C.d1 && C.d1 == reverse) || (C.d2 && C.d2 == reverse))
					. += C

	// Handle conduits on the same turf as us
	for(var/obj/structure/conduit/C in loc)
		if(C.d1 == d1 || C.d2 == d1 || C.d1 == d2 || C.d2 == d2) // if either of C's d1 and d2 match either of ours
			. += C

	if(d1 == 0)
		for(var/obj/machinery/power/P in loc)
			if(P.powernet == 0) continue // exclude APCs with powernet=0
			if(!powernetless_only || !P.powernet)
				. += P

	// if the caller asked for powernetless conduits only, dump the ones with powernets
	if(powernetless_only)
		for(var/obj/structure/conduit/C in .)
			if(C.powernet)
				. -= C

/obj/structure/conduit/proc/auto_propagate_cut_cable(obj/O)
	if(O && !QDELETED(O))
		var/datum/powernet/newPN = new()// creates a new powernet...
		propagate_network(O, newPN)//... and propagates it to the other side of the cable

/**
 * Called after placing a conduit which extends another conduit, creating a "smooth" cable that no longer terminates in the centre of a turf.
 * This is needed as this can, unlike other placements, disconnect conduits entirely.
 */
/obj/structure/conduit/proc/denode()
	var/turf/T1 = loc
	if(!T1) return

	var/list/powerlist = power_list(T1,src,0,0) //find the other conduits that ended in the centre of the turf, with or without a powernet
	if(powerlist.len>0)
		var/datum/powernet/PN = new()
		propagate_network(powerlist[1],PN) //propagates the new powernet beginning at the source cable

		if(PN.is_empty()) //can happen with machines made nodeless when smoothing conduits
			qdel(PN)

/// Cut the conduit's powernet at this conduit and update the powergrid
/obj/structure/conduit/proc/cut_conduit_from_powernet()
	var/turf/T1 = loc
	var/turf/T2
	var/list/P_list
	if(!T1)	return

	for(var/check_dir in list(d1, d2))
		if(check_dir)
			T2 = get_step(loc, check_dir)
			P_list += power_list(T2, src, turn(check_dir,180),0,conduit_only = TRUE)	// what adjacently joins on to cut conduit...

	P_list += power_list(loc, src, d1, 0, conduit_only = TRUE)//... and on turf

	// remove the cut conduit from its turf and powernet, so that it doesn't get count in propagate_network worklist
	loc = null
	powernet.remove_conduit(src) //remove the cut conduit from its powernet

	for(var/obj/machinery/power/P in T1)
		if(!P.connect_to_network()) //can't find a node conduit on a the turf to connect to
			P.disconnect_from_network() //remove from current network

	var/first = TRUE
	for(var/obj/O in P_list)
		if(first)
			first = FALSE
			continue
		addtimer(CALLBACK(O, PROC_REF(auto_propagate_cut_conduit), O), 0)
		// prevents rebuilding the powernet X times when an explosion cuts X conduits

///////////////////////////////////////////////
// The conduit spool object, used for laying conduit
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

#define MAXCOIL 30

/obj/item/stack/conduit_spool
	name = "power conduit"
	icon = 'icons/obj/power.dmi'
	icon_state = "wire"
	item_state = "wire"
	desc = "A superconducting power conduit for heavy-duty electrical systems."
	singular_name = "length"
	gender = NEUTER
	amount = MAXCOIL
	max_amount = MAXCOIL
	color = COLOR_RED
	throwforce = 10
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 2
	throw_range = 5
	matter = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 20, MATERIAL_PHORON = 3)
	recyclable = TRUE
	obj_flags = OBJ_FLAG_CONDUCTABLE
	item_flags = ITEM_FLAG_HELD_MAP_TEXT
	slot_flags = SLOT_BELT
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stacktype = /obj/item/stack/cable_coil
	drop_sound = 'sound/items/drop/accessory.ogg'
	pickup_sound = 'sound/items/pickup/accessory.ogg'
	surgerysound = 'sound/items/surgery/fixovein.ogg'
	contained_sprite = TRUE
	build_from_parts = TRUE
	worn_overlay = "end"

/obj/item/stack/conduit_spool/iscoil()
	return TRUE

/obj/item/stack/conduit_spool/Initialize(mapload, amt, param_color = null)
	. = ..(mapload, amt)

	if(param_color) // It should be red by default, so only recolor it if parameter was specified.
		color = param_color

	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()
	update_wclass()

/obj/item/stack/conduit_spool/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	var/found_color_name = "Unknown"
	for(var/color_name in GLOB.conduit_spool_colors)
		var/color_value = GLOB.conduit_spool_colors[color_name]
		if(color == color_value)
			found_color_name = color_name
			break
	. += "This cable is: <span style='color:[color]'>[found_color_name]</span>"

	if(!uses_charge)
		. += "There [src.amount == 1 ? "is" : "are"] <b>[src.amount] [src.singular_name]\s</b> of conduit in the spool."
	else
		. += "You have enough charge to produce <b>[get_amount()]</b>."

/obj/item/stack/conduit_spool/update_icon()
	if(!color)
		color = pick(GLOB.conduit_spool_colors)
	name = "[initial(name)]"
	if(amount == 1)
		icon_state = "[initial(icon_state)]1"
		item_state = "[initial(icon_state)]1"
		name += " piece"
	else if(amount == 2)
		icon_state = "[initial(icon_state)]2"
		item_state = "[initial(icon_state)]2"
		name += " piece"
	else
		icon_state = "[initial(icon_state)]"
		item_state = "[initial(icon_state)]"
		name += " coil"
	update_held_icon()
	ClearOverlays()
	AddOverlays(overlay_image(icon, "[icon_state]_end", flags=RESET_COLOR))
	check_maptext(SMALL_FONTS(7, get_amount()))

/obj/item/stack/conduit_spool/attackby(obj/item/attacking_item, mob/user)
	if(attacking_item.ismultitool())
		choose_conduit_color(user)
	return ..()

/obj/item/stack/conduit_spool/proc/choose_conduit_color(var/user)
	var/selected_type = tgui_input_list(user, "Pick a new colour.", "Conduit Colour", GLOB.cable_coil_colours)
	set_conduit_color(selected_type, user)

/obj/item/stack/cable_coil/proc/set_conduit_color(selected_color, var/user)
	if(!selected_color)
		return

	var/final_color = GLOB.conduit_spool_colors[selected_color]
	if(!final_color)
		final_color = GLOB.conduit_spool_colors["Red"]
		selected_color = "Red"
	color = final_color
	to_chat(user, SPAN_NOTICE("You change \the [src]'s color to [lowertext(selected_color)]."))

/obj/item/stack/conduit_spool/proc/update_wclass()
	if(amount == 1)
		w_class = WEIGHT_CLASS_TINY
		slot_flags = SLOT_BELT
	else
		w_class = WEIGHT_CLASS_SMALL
		slot_flags = SLOT_BELT

/obj/item/stack/conduit_spool/cyborg
	name = "conduit spool synthesizer"
	desc = "A device that makes conduit."
	gender = NEUTER
	matter = null
	uses_charge = 1
	charge_costs = list(1)

/obj/item/stack/conduit_spool/cyborg/verb/set_colour()
	set name = "Change Colour"
	set category = "Object"
	set src in usr

	choose_cable_color(usr)

// Items usable on a cable coil :
//   - Wirecutters : cut them duh !
//   - Cable coil : merge cables
/obj/item/stack/conduit_spool/proc/can_merge(var/obj/item/stack/cable_coil/C)
	return color == C.color

/obj/item/stack/conduit_spool/cyborg/can_merge()
	return TRUE

/obj/item/stack/conduit_spool/transfer_to(obj/item/stack/cable_coil/S)
	if(!istype(S))
		return
	if(!can_merge(S))
		return

	..()

/obj/item/stack/conduit_spool/use()
	. = ..()
	update_icon()
	return

/obj/item/stack/conduit_spool/add()
	. = ..()
	update_icon()
	return

///////////////////////////////////////////////
// Cable laying procedures
//////////////////////////////////////////////

// called when cable_coil is clicked on a turf/simulated/floor
/obj/item/stack/conduit_spool/proc/turf_place(turf/F, mob/user)
	if(!isturf(user.loc))
		return

	if(get_amount() < 1) // Out of conduit
		to_chat(user, "There is no conduit left.")
		return

	if(get_dist(F,user) > 1) // Too far
		to_chat(user, "You can't lay conduit at a place that far away.")
		return

	if (!F.can_lay_cable())
		if (istype(F, /turf/simulated/floor))
			to_chat(user, "You can't lay conduit there unless the floor tiles are removed.")
		else
			to_chat(user, "You can't lay conduit there unless there is plating or a catwalk.")
		return

	else
		var/dirn

		if(user.loc == F)
			dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
		else
			dirn = get_dir(F, user)

		for(var/obj/structure/conduit/LC in F)
			if((LC.d1 == dirn && LC.d2 == 0 ) || ( LC.d2 == dirn && LC.d1 == 0))
				to_chat(user, SPAN_WARNING("There's already a conduit at that position."))
				return
///// Z-Level Stuff
		// check if the target is open space
		if(isopenturf(F))
			for(var/obj/structure/conduit/LC in F)
				if((LC.d1 == dirn && LC.d2 == 11 ) || ( LC.d2 == dirn && LC.d1 == 11))
					to_chat(user, SPAN_WARNING("There's already a conduit at that position."))
					return

			var/obj/structure/conduit/C = new(F)
			var/obj/structure/conduit/D = new(GET_TURF_BELOW(F))

			C.conduitColor(color)

			C.d1 = 11
			C.d2 = dirn
			C.add_fingerprint(user)
			C.update_icon()

			var/datum/powernet/PN = new()
			PN.add_conduit(C)

			C.mergeConnectedNetworks(C.d2)
			C.mergeConnectedNetworksOnTurf()

			D.conduitColor(color)

			D.d1 = 12
			D.d2 = 0
			D.add_fingerprint(user)
			D.update_icon()

			PN.add_conduit(D)
			D.mergeConnectedNetworksOnTurf()

		// do the normal stuff
		else
///// Z-Level Stuff
			for(var/obj/structure/conduit/LC in F)
				if((LC.d1 == dirn && LC.d2 == 0 ) || ( LC.d2 == dirn && LC.d1 == 0))
					to_chat(user, "There's already a cable at that position.")
					return

			var/obj/structure/conduit/C = new(F)

			C.conduitColor(color)

			//set up the new cable
			C.d1 = 0 //it's a O-X node cable
			C.d2 = dirn
			C.add_fingerprint(user)
			C.update_icon()

			//create a new powernet with the cable, if needed it will be merged later
			var/datum/powernet/PN = new()
			PN.add_conduit(C)

			C.mergeConnectedNetworks(C.d2) //merge the powernet with adjacents powernets
			C.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets

			if(C.d2 & (C.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
				C.mergeDiagonalsNetworks(C.d2)


			use(1)
			if (C.shock(user, 50))
				if (prob(50)) //fail
					new/obj/item/stack/conduit_spool(C.loc, 1, C.color)
					qdel(C)

// called when cable_coil is click on an installed obj/cable
// or click on a turf that already contains a "node" cable
/obj/item/stack/conduit_spool/proc/conduit_join(obj/structure/conduit/C, mob/user)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T) || !T.can_have_cabling())		// sanity checks, also stop use interacting with T-scanner revealed cable
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		to_chat(user, "You can't lay cable at a place that far away.")
		return


	if(U == T) //if clicked on the turf we're standing on, try to put a cable in the direction we're facing
		turf_place(T,user)
		return

	var/dirn = get_dir(C, user)

	// one end of the clicked cable is pointing towards us
	if(C.d1 == dirn || C.d2 == dirn)
		if(!T.can_have_cabling())						// can't place a cable if the floor is complete
			to_chat(user, "You can't lay cable there unless the floor tiles are removed.")
			return
		else
			// cable is pointing at us, we're standing on an open tile
			// so create a stub pointing at the clicked cable on our tile

			var/fdirn = turn(dirn, 180)		// the opposite direction

			for(var/obj/structure/conduit/LC in U)		// check to make sure there's not a cable there already
				if(LC.d1 == fdirn || LC.d2 == fdirn)
					to_chat(user, "There's already a cable at that position.")
					return

			var/obj/structure/conduit/NC = new(U)
			NC.conduitColor(color)

			NC.d1 = 0
			NC.d2 = fdirn
			NC.add_fingerprint()
			NC.update_icon()

			//create a new powernet with the cable, if needed it will be merged later
			var/datum/powernet/newPN = new()
			newPN.add_conduit(NC)

			NC.mergeConnectedNetworks(NC.d2) //merge the powernet with adjacents powernets
			NC.mergeConnectedNetworksOnTurf() //merge the powernet with on turf powernets

			if(NC.d2 & (NC.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
				NC.mergeDiagonalsNetworks(NC.d2)

			use(1)

			if (NC.shock(user, 50))
				if (prob(50)) //fail
					new/obj/item/stack/conduit_spool(NC.loc, 1, NC.color)
					qdel(NC)

			return

	// exisiting cable doesn't point at our position, so see if it's a stub
	else if(C.d1 == 0)
							// if so, make it a full cable pointing from it's old direction to our dirn
		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn


		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2


		for(var/obj/structure/conduit/LC in T)		// check to make sure there's no matching cable
			if(LC == C)			// skip the cable we're interacting with
				continue
			if((LC.d1 == nd1 && LC.d2 == nd2) || (LC.d1 == nd2 && LC.d2 == nd1) )	// make sure no cable matches either direction
				to_chat(user, "There's already a conduit at that position.")
				return


		C.conduitColor(color)

		C.d1 = nd1
		C.d2 = nd2

		C.add_fingerprint()
		C.update_icon()


		C.mergeConnectedNetworks(C.d1) //merge the powernets...
		C.mergeConnectedNetworks(C.d2) //...in the two new cable directions
		C.mergeConnectedNetworksOnTurf()

		if(C.d1 & (C.d1 - 1))// if the cable is layed diagonally, check the others 2 possible directions
			C.mergeDiagonalsNetworks(C.d1)

		if(C.d2 & (C.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
			C.mergeDiagonalsNetworks(C.d2)

		use(1)

		if (C.shock(user, 50))
			if (prob(50)) //fail
				new/obj/item/stack/conduit_spool(C.loc, 2, C.color)
				qdel(C)
				return

		C.denode()// this call may have disconnected some cables that terminated on the centre of the turf, if so split the powernets.
		return

//////////////////////////////
// Misc.
/////////////////////////////

/obj/item/stack/conduit_spool/cut
	item_state = "coil2"

/obj/item/stack/conduit_spool/cut/Initialize(mapload)
	. = ..()
	src.amount = rand(1,2)
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	update_icon()
	update_wclass()

/obj/item/stack/conduit_spool/yellow
	color = COLOR_YELLOW

/obj/item/stack/conduit_spool/blue
	color = COLOR_BLUE

/obj/item/stack/conduit_spool/green
	color = COLOR_GREEN

/obj/item/stack/conduit_spool/pink
	color = COLOR_PINK

/obj/item/stack/conduit_spool/orange
	color = COLOR_ORANGE

/obj/item/stack/conduit_spool/cyan
	color = COLOR_CYAN

/obj/item/stack/conduit_spool/white
	color = COLOR_WHITE

/obj/item/stack/conduit_spool/random/Initialize()
	var/color_name = pick(GLOB.conduit_spool_colors)
	color = GLOB.conduit_spool_colors[color_name]
	return ..()
