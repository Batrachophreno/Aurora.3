#define BLUEPRINT_STATE 1
#define WIRING_STATE 2
#define CIRCUITBOARD_STATE 3
#define COMPONENT_STATE 4

//Circuit boards are in /code/game/objects/items/weapons/circuitboards/machinery
/obj/structure/machinery/constructable_frame //Made into a seperate type to make future revisions easier.
	name = "machine blueprint"
	desc = "A holo-blueprint for a machine."
	var/machine_description
	var/components_description
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "blueprint_0"
	density = FALSE
	anchored = FALSE
	use_power = POWER_USE_OFF
	obj_flags = OBJ_FLAG_ROTATABLE
	var/obj/item/circuitboard/circuit
	var/list/components = list()
	var/list/req_components = list()
	var/list/req_component_names = list()
	var/state = 1
	var/pitch_toggle = 1

/obj/structure/machinery/constructable_frame/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "A blueprint that allows the user to rotate the direction the final result will be built in."
	. += "Higher-quality components can improve the functionality of the machine in different ways."

/obj/structure/machinery/constructable_frame/assembly_hints(mob/user, distance, is_adjacent)
	. += ..()
	switch(state)
		if(BLUEPRINT_STATE)
			. += "Click on \the [src] to finalize its direction."
		if(WIRING_STATE)
			. += "Add cable coil to wire \the [src]."
		if(CIRCUITBOARD_STATE)
			. += "Add the desired circuitboard."
		if(COMPONENT_STATE)
			. += "Add the required components. Use the screwdriver to complete the machine."

/obj/structure/machinery/constructable_frame/disassembly_hints(mob/user, distance, is_adjacent)
	. += ..()
	switch(state)
		if(BLUEPRINT_STATE)
			. += "Use a wirecutter or a plasma cutter to disassemble \the [src]."
		if(WIRING_STATE)
			. += "Use a wrench or a plasma cutter to disassemble \the [src]."
		if(CIRCUITBOARD_STATE)
			. += "Use a wirecutter to remove the cables."
		if(COMPONENT_STATE)
			. += "Use a crowbar to pry out the circuitboard and the components out."

/obj/structure/machinery/constructable_frame/machine_frame/assembly_hints(mob/user, distance, is_adjacent)
	return render_interaction_hints(user, INTERACTION_CATEGORY_CONSTRUCTION)

/obj/structure/machinery/constructable_frame/machine_frame/disassembly_hints(mob/user, distance, is_adjacent)
	return render_interaction_hints(user, INTERACTION_CATEGORY_DECONSTRUCTION)

/obj/structure/machinery/constructable_frame/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	if(machine_description)
		. += "[machine_description]"
	if(components_description)
		. += "[components_description]"

/obj/structure/machinery/constructable_frame/proc/update_component_desc()
	var/D
	if(length(req_components))
		var/list/component_list = list()
		for(var/I in req_components)
			if(req_components[I] > 0)
				component_list += "<b>[num2text(req_components[I])] [req_component_names[I]]\s</b>"
		D = "Requires [english_list(component_list)]."
	components_description = D

/obj/structure/machinery/constructable_frame/machine_frame/gather_local_interaction_steps(datum/interaction_context/context, list/steps)
	..()
	switch(state)
		if(BLUEPRINT_STATE)
			steps += new /datum/interaction_step/machine_frame/finalize_blueprint
			steps += new /datum/interaction_step/machine_frame/scrap_blueprint/wirecutters
			steps += new /datum/interaction_step/machine_frame/scrap_blueprint/plasma_cutter
		if(WIRING_STATE)
			steps += new /datum/interaction_step/machine_frame/add_cable
			steps += new /datum/interaction_step/machine_frame/dismantle_wired/wrench
			steps += new /datum/interaction_step/machine_frame/dismantle_wired/plasma_cutter
		if(CIRCUITBOARD_STATE)
			steps += new /datum/interaction_step/machine_frame/add_circuitboard
			steps += new /datum/interaction_step/machine_frame/remove_cables
		if(COMPONENT_STATE)
			steps += new /datum/interaction_step/machine_frame/add_component
			steps += new /datum/interaction_step/machine_frame/complete_machine
			steps += new /datum/interaction_step/machine_frame/remove_board_and_components

/proc/machine_frame_requirement_typepath(requirement_key)
	if(ispath(requirement_key))
		return requirement_key
	return text2path(requirement_key)

/datum/interaction_requirement/machine_frame_component
	id = "machine_frame_component"
	name = "a required component"
	failure_status = INTERACTION_RESULT_MISSING_ACTIVE_ITEM
	failure_message = "You need a required component."

/datum/interaction_requirement/machine_frame_component/is_met(datum/interaction_context/context)
	if(!istype(context?.target, /obj/structure/machinery/constructable_frame/machine_frame) || !context?.active_item)
		return FALSE
	var/obj/structure/machinery/constructable_frame/machine_frame/frame = context.target
	for(var/component_key in frame.req_components)
		if(frame.req_components[component_key] <= 0)
			continue
		var/component_path = machine_frame_requirement_typepath(component_key)
		if(component_path && istype(context.active_item, component_path))
			return TRUE
	return FALSE

/datum/interaction_requirement/machine_frame_components_installed
	id = "machine_frame_components_installed"
	name = "all required components installed"
	failure_status = INTERACTION_RESULT_MISSING_ACTIVE_ITEM
	failure_message = "The machine still needs components."

/datum/interaction_requirement/machine_frame_components_installed/is_met(datum/interaction_context/context)
	if(!istype(context?.target, /obj/structure/machinery/constructable_frame/machine_frame))
		return FALSE
	var/obj/structure/machinery/constructable_frame/machine_frame/frame = context.target
	for(var/component_key in frame.req_components)
		if(frame.req_components[component_key] > 0)
			return FALSE
	return TRUE

/datum/interaction_step/machine_frame
	query_only = TRUE
	var/required_state

/datum/interaction_step/machine_frame/New()
	..()
	add_requirement(new /datum/interaction_requirement/target_var_equals("state", required_state, "the correct machine frame state"))
	add_requirement(new /datum/interaction_requirement/adjacent)

/datum/interaction_step/machine_frame/proc/get_frame(datum/interaction_context/context)
	RETURN_TYPE(/obj/structure/machinery/constructable_frame/machine_frame)
	if(!istype(context?.target, /obj/structure/machinery/constructable_frame/machine_frame))
		return
	var/obj/structure/machinery/constructable_frame/machine_frame/frame = context.target
	return frame

/datum/interaction_step/machine_frame/is_visible(datum/interaction_context/context)
	var/obj/structure/machinery/constructable_frame/machine_frame/frame = get_frame(context)
	return frame && frame.state == required_state

/datum/interaction_step/machine_frame/finalize_blueprint
	id = "machine_frame_finalize_blueprint"
	name = "finalize blueprint"
	category = INTERACTION_CATEGORY_CONSTRUCTION
	priority = 100
	required_state = BLUEPRINT_STATE

/datum/interaction_step/machine_frame/finalize_blueprint/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_item_empty)

/datum/interaction_step/machine_frame/finalize_blueprint/render_hint(datum/interaction_context/context)
	return "Click on \the [context.target] to finalize its direction."

/datum/interaction_step/machine_frame/scrap_blueprint
	name = "scrap blueprint"
	category = INTERACTION_CATEGORY_DECONSTRUCTION
	priority = 90
	required_state = BLUEPRINT_STATE

/datum/interaction_step/machine_frame/scrap_blueprint/wirecutters
	id = "machine_frame_scrap_blueprint_wirecutters"

/datum/interaction_step/machine_frame/scrap_blueprint/wirecutters/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_tool(TOOL_WIRECUTTER, "wirecutters"))

/datum/interaction_step/machine_frame/scrap_blueprint/wirecutters/render_hint(datum/interaction_context/context)
	return "Use wirecutters to disassemble \the [context.target]."

/datum/interaction_step/machine_frame/scrap_blueprint/plasma_cutter
	id = "machine_frame_scrap_blueprint_plasma_cutter"

/datum/interaction_step/machine_frame/scrap_blueprint/plasma_cutter/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_type(/obj/item/gun/energy/plasmacutter, "a plasma cutter"))

/datum/interaction_step/machine_frame/scrap_blueprint/plasma_cutter/render_hint(datum/interaction_context/context)
	return "Use a plasma cutter to disassemble \the [context.target]."

/datum/interaction_step/machine_frame/add_cable
	id = "machine_frame_add_cable"
	name = "wire blueprint"
	category = INTERACTION_CATEGORY_CONSTRUCTION
	priority = 100
	required_state = WIRING_STATE

/datum/interaction_step/machine_frame/add_cable/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_tool(TOOL_CABLECOIL, "cable coil"))
	add_requirement(new /datum/interaction_requirement/active_stack_amount(5, "lengths of cable"))

/datum/interaction_step/machine_frame/add_cable/render_hint(datum/interaction_context/context)
	return "Add five lengths of cable coil to wire \the [context.target]."

/datum/interaction_step/machine_frame/dismantle_wired
	name = "dismantle wired blueprint"
	category = INTERACTION_CATEGORY_DECONSTRUCTION
	priority = 90
	required_state = WIRING_STATE

/datum/interaction_step/machine_frame/dismantle_wired/wrench
	id = "machine_frame_dismantle_wired_wrench"

/datum/interaction_step/machine_frame/dismantle_wired/wrench/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_tool(TOOL_WRENCH, "a wrench"))

/datum/interaction_step/machine_frame/dismantle_wired/wrench/render_hint(datum/interaction_context/context)
	return "Use a wrench to disassemble \the [context.target]."

/datum/interaction_step/machine_frame/dismantle_wired/plasma_cutter
	id = "machine_frame_dismantle_wired_plasma_cutter"

/datum/interaction_step/machine_frame/dismantle_wired/plasma_cutter/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_type(/obj/item/gun/energy/plasmacutter, "a plasma cutter"))

/datum/interaction_step/machine_frame/dismantle_wired/plasma_cutter/render_hint(datum/interaction_context/context)
	return "Use a plasma cutter to disassemble \the [context.target]."

/datum/interaction_step/machine_frame/add_circuitboard
	id = "machine_frame_add_circuitboard"
	name = "add machine circuit board"
	category = INTERACTION_CATEGORY_CONSTRUCTION
	priority = 100
	required_state = CIRCUITBOARD_STATE

/datum/interaction_step/machine_frame/add_circuitboard/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_circuitboard(BOARD_MACHINE, "a machine circuit board"))

/datum/interaction_step/machine_frame/add_circuitboard/render_hint(datum/interaction_context/context)
	return "Add the desired machine circuit board."

/datum/interaction_step/machine_frame/remove_cables
	id = "machine_frame_remove_cables"
	name = "remove cables"
	category = INTERACTION_CATEGORY_DECONSTRUCTION
	priority = 90
	required_state = CIRCUITBOARD_STATE

/datum/interaction_step/machine_frame/remove_cables/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_tool(TOOL_WIRECUTTER, "wirecutters"))

/datum/interaction_step/machine_frame/remove_cables/render_hint(datum/interaction_context/context)
	return "Use wirecutters to remove the cables."

/datum/interaction_step/machine_frame/add_component
	id = "machine_frame_add_component"
	name = "add required component"
	category = INTERACTION_CATEGORY_CONSTRUCTION
	priority = 100
	required_state = COMPONENT_STATE

/datum/interaction_step/machine_frame/add_component/New()
	..()
	add_requirement(new /datum/interaction_requirement/machine_frame_component)

/datum/interaction_step/machine_frame/add_component/is_visible(datum/interaction_context/context)
	if(!..())
		return FALSE
	var/obj/structure/machinery/constructable_frame/machine_frame/frame = get_frame(context)
	for(var/component_key in frame.req_components)
		if(frame.req_components[component_key] > 0)
			return TRUE
	return FALSE

/datum/interaction_step/machine_frame/add_component/proc/get_component_list(datum/interaction_context/context)
	. = list()
	var/obj/structure/machinery/constructable_frame/machine_frame/frame = get_frame(context)
	if(!frame)
		return
	for(var/component_key in frame.req_components)
		if(frame.req_components[component_key] <= 0)
			continue
		var/component_name = frame.req_component_names[component_key] || "[component_key]"
		. += "<b>[num2text(frame.req_components[component_key])] [component_name]\s</b>"

/datum/interaction_step/machine_frame/add_component/render_hint(datum/interaction_context/context)
	var/list/component_list = get_component_list(context)
	if(!length(component_list))
		return
	return "Add the required components: [english_list(component_list)]."

/datum/interaction_step/machine_frame/complete_machine
	id = "machine_frame_complete_machine"
	name = "complete machine"
	category = INTERACTION_CATEGORY_CONSTRUCTION
	priority = 80
	required_state = COMPONENT_STATE

/datum/interaction_step/machine_frame/complete_machine/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_tool(TOOL_SCREWDRIVER, "a screwdriver"))
	add_requirement(new /datum/interaction_requirement/machine_frame_components_installed)

/datum/interaction_step/machine_frame/complete_machine/render_hint(datum/interaction_context/context)
	var/obj/structure/machinery/constructable_frame/machine_frame/frame = get_frame(context)
	if(!frame)
		return
	var/all_components_installed = TRUE
	for(var/component_key in frame.req_components)
		if(frame.req_components[component_key] > 0)
			all_components_installed = FALSE
			break
	if(all_components_installed)
		return "Use a screwdriver to complete the machine."
	return "Use a screwdriver to complete the machine once all required components are installed."

/datum/interaction_step/machine_frame/remove_board_and_components
	id = "machine_frame_remove_board_and_components"
	name = "remove circuit board and components"
	category = INTERACTION_CATEGORY_DECONSTRUCTION
	priority = 90
	required_state = COMPONENT_STATE

/datum/interaction_step/machine_frame/remove_board_and_components/New()
	..()
	add_requirement(new /datum/interaction_requirement/active_tool(TOOL_CROWBAR, "a crowbar"))

/datum/interaction_step/machine_frame/remove_board_and_components/render_hint(datum/interaction_context/context)
	return "Use a crowbar to pry out the circuit board and the components."

/obj/structure/machinery/constructable_frame/machine_frame/attack_hand(mob/user)
	if(state == BLUEPRINT_STATE)
		to_chat(user, SPAN_NOTICE("You begin to finalize the blueprint..."))
		if(do_after(user, 2 SECONDS, src, do_flags = DO_REPAIR_CONSTRUCT))
			if(state != BLUEPRINT_STATE)
				return
			to_chat(user, SPAN_NOTICE("You finalize the blueprint."))
			playsound(get_turf(src), 'sound/items/poster_being_created.ogg', 75, TRUE)
			state = WIRING_STATE
	else
		..()

/obj/structure/machinery/constructable_frame/machine_frame/attackby(obj/item/attacking_item, mob/user)
	switch(state)
		if(BLUEPRINT_STATE)
			if(attacking_item.tool_behaviour == TOOL_WIRECUTTER || istype(attacking_item, /obj/item/gun/energy/plasmacutter))
				playsound(get_turf(src), 'sound/items/poster_ripped.ogg', 75, TRUE)
				to_chat(user, SPAN_NOTICE("You decide to scrap the blueprint."))
				new /obj/item/stack/material/steel(get_turf(src), 2)
				qdel(src)
				return TRUE
		if(WIRING_STATE)
			if(attacking_item.tool_behaviour == TOOL_CABLECOIL)
				var/obj/item/stack/cable_coil/C = attacking_item
				if(C.get_amount() < 5)
					to_chat(user, SPAN_WARNING("You need five lengths of cable to add them to the blueprint."))
					return TRUE
				playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, TRUE)
				to_chat(user, SPAN_NOTICE("You start wiring up the blueprint..."))
				if(do_after(user, 2 SECONDS, src, do_flags = DO_REPAIR_CONSTRUCT))
					if(state == WIRING_STATE && C.use(5))
						to_chat(user, SPAN_NOTICE("You wire up the blueprint."))
						state = CIRCUITBOARD_STATE
						icon_state = "blueprint_1"
				return TRUE
			else
				if(attacking_item.tool_behaviour == TOOL_WRENCH)
					attacking_item.play_tool_sound(get_turf(src), 75)
					to_chat(user, SPAN_NOTICE("You dismantle the blueprint."))
					new /obj/item/stack/material/steel(get_turf(src), 2)
					qdel(src)
					return TRUE
				else if(istype(attacking_item, /obj/item/gun/energy/plasmacutter))
					var/obj/item/gun/energy/plasmacutter/PC = attacking_item
					if(PC.check_power_and_message(user))
						return TRUE
					PC.use_resource(1)
					playsound(get_turf(src), PC.fire_sound, 75, TRUE)
					to_chat(user, SPAN_NOTICE("You dismantle the blueprint."))
					new /obj/item/stack/material/steel(get_turf(src), 2)
					qdel(src)
					return TRUE
		if(CIRCUITBOARD_STATE)
			if(istype(attacking_item, /obj/item/circuitboard))
				var/obj/item/circuitboard/B = attacking_item
				if(B.board_type == BOARD_MACHINE)
					playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, TRUE)
					to_chat(user, SPAN_NOTICE("You add the circuit board to the blueprint."))
					circuit = attacking_item
					user.drop_from_inventory(attacking_item, src)
					var/obj/machine = new circuit.build_path
					name = "[machine.name] blueprint"
					desc = "A holo-blueprint for a [machine.name]."
					machine_description = "This blueprint will become a <b>[capitalize_first_letters(machine.name)]</b>: [machine.desc]"
					qdel(machine)
					icon_state = "blueprint_2"
					state = COMPONENT_STATE
					components = list()
					req_components = circuit.req_components.Copy()
					for(var/A in circuit.req_components)
						req_components[A] = circuit.req_components[A]
					req_component_names = circuit.req_components.Copy()
					for(var/A in req_components)
						var/cp = text2path(A)
						var/obj/ct = new cp() // have to quickly instantiate it get name
						req_component_names[A] = ct.name
					update_component_desc()
					to_chat(user, SPAN_NOTICE("[components_description]"))
				else
					to_chat(user, SPAN_WARNING("This blueprint does not accept circuit boards of this type!"))
				return TRUE
			else
				if(attacking_item.tool_behaviour == TOOL_WIRECUTTER)
					playsound(get_turf(src), attacking_item.usesound, 50, TRUE, pitch_toggle)
					to_chat(user, SPAN_NOTICE("You remove the cables."))
					state = WIRING_STATE
					icon_state = "blueprint_0"
					var/obj/item/stack/cable_coil/A = new /obj/item/stack/cable_coil(get_turf(src))
					A.amount = 5
					A.update_icon()
					return TRUE

		if(COMPONENT_STATE)
			if(attacking_item.tool_behaviour == TOOL_CROWBAR)
				attacking_item.play_tool_sound(get_turf(src), 50)
				state = CIRCUITBOARD_STATE
				circuit.forceMove(get_turf(src))
				circuit = null
				if(components.len == 0)
					to_chat(user, SPAN_NOTICE("You remove the circuit board."))
				else
					to_chat(user, SPAN_NOTICE("You remove the circuit board and other components."))
					for(var/obj/item/W in components)
						W.forceMove(get_turf(src))
				desc = initial(desc)
				machine_description = null
				components_description = null
				req_components = list()
				components = list()
				icon_state = "blueprint_2"
				return TRUE
			else
				if(attacking_item.tool_behaviour == TOOL_SCREWDRIVER)
					var/component_check = TRUE
					for(var/R in req_components)
						if(req_components[R] > 0)
							component_check = FALSE
							break
					if(component_check)
						attacking_item.play_tool_sound(get_turf(src), 50)
						var/obj/structure/machinery/new_machine = new circuit.build_path(loc, dir, FALSE)
						if(istype(circuit, /obj/item/circuitboard/unary_atmos))
							var/obj/item/circuitboard/unary_atmos/U = circuit
							U.init_dirs = dir
							U.machine_dir = U
						if(istype(new_machine))
							if(new_machine.component_parts)
								new_machine.component_parts.Cut()
							else
								new_machine.component_parts = list()
							circuit.construct(new_machine)

							for(var/obj/O in src)
								if(circuit.contain_parts) // things like disposal don't want their parts in them
									O.forceMove(new_machine)
								else
									O.forceMove(null)
								new_machine.component_parts += O

							if(circuit.contain_parts)
								circuit.forceMove(new_machine)
							else
								circuit.forceMove(null)

							new_machine.RefreshParts()
							new_machine.anchored = TRUE
						qdel(src)
					return TRUE
				else
					if(istype(attacking_item, /obj/item))
						for(var/I in req_components)
							if(istype(attacking_item, text2path(I)) && (req_components[I] > 0))
								playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, TRUE)
								if(istype(attacking_item, /obj/item/stack))
									var/obj/item/stack/CP = attacking_item
									if(CP.get_amount() > 1)
										var/camt = min(CP.amount, req_components[I]) // amount of cable to take, idealy amount required, but limited by amount provided
										var/obj/item/stack/CC = new CP.type(src)
										CC.amount = camt
										CC.update_icon()
										CP.use(camt)
										components += CC
										req_components[I] -= camt
										update_component_desc()
										break
								user.drop_from_inventory(attacking_item,src)
								components += attacking_item
								req_components[I]--
								update_component_desc()
								break
						to_chat(user, SPAN_NOTICE("[components_description]"))
						if(attacking_item?.loc != src && !istype(attacking_item, /obj/item/stack))
							to_chat(user, SPAN_WARNING("You cannot add that component to the machine!."))
						return TRUE


/obj/structure/machinery/constructable_frame/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(!mover)
		return TRUE
	if(mover.movement_type & PHASING)
		return TRUE
	if(istype(mover,/obj/projectile) && density)
		if(prob(50))
			return TRUE
		else
			return FALSE
	else if(mover.pass_flags & PASSTABLE) // Animals can run under them, lots of empty space
		return TRUE
	return ..()

/obj/structure/machinery/constructable_frame/temp_deco
	name = "machine frame"
	desc = "An old and dusty machine frame that once housed a machine of some kind."
	icon_state = "box_0"
	anchored = TRUE
	density = TRUE

/obj/structure/machinery/constructable_frame/temp_deco/attackby(obj/item/attacking_item, mob/user)
	if(attacking_item.tool_behaviour == TOOL_WRENCH)
		attacking_item.play_tool_sound(get_turf(src), 75)
		to_chat(user, SPAN_NOTICE("You dismantle \the [src]."))
		new /obj/item/stack/material/steel(get_turf(src), 5)
		qdel(src)
		return TRUE

#undef BLUEPRINT_STATE
#undef WIRING_STATE
#undef CIRCUITBOARD_STATE
#undef COMPONENT_STATE
