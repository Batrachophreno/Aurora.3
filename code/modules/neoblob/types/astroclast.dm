/**
 * The classic SS13 blob.
 */
/datum/neoblob_type/astroclast
	name = "astroclast"
	color = "#AAFF00"
	complementary_color = "#57787B"
	icon_state_overlays = list(
		"blob_core" = "blob_core_overlay",
		"blob_node" = "blob_node_overlay"
	)
	faction = "astroclast"
	attack_weapon = "astroclast tendril"

	mass_path = /obj/structure/neoblob/astroclast
	core_path = /obj/structure/neoblob/core/astroclast
	secondary_core_path = /obj/structure/neoblob/core/secondary/astroclast
	shield_path = /obj/structure/neoblob/shield/astroclast
	ravaging_path = /obj/structure/neoblob/ravaging/astroclast

	mass_name = "pulsating mass"
	mass_desc = "A pulsating mass of interwoven tendrils."
	core_name = "master nucleus"
	core_desc = "A massive, fragile nucleus guarded by a shield of thick tendrils."
	secondary_core_name = "auxiliary nucleus"
	secondary_core_desc = "An interwoven mass of tendrils. A glowing nucleus pulses at its center."
	shield_name = "shielding mass"
	shield_desc = "A pulsating mass of interwoven tendrils. These seem particularly robust, but not quite as active."
	ravaging_name = "ravaging mass"
	ravaging_desc = "A mass of interwoven tendrils. They thrash around haphazardly at anything in reach."

// Object defines
/obj/structure/neoblob/astroclast

/obj/structure/neoblob/core/astroclast

/obj/structure/neoblob/core/secondary/astroclast

/obj/structure/neoblob/shield/astroclast

/obj/structure/neoblob/ravaging/astroclast

/datum/neoblob_type/astroclast/attack_msg(var/obj/structure/neoblob/growth, var/atom/target)
	target.visible_message(SPAN_WARNING("A tendril flies out from \the [growth] and smashes into \the [target]!"), SPAN_DANGER("A tendril flies out from \the [growth] and smashes into you!"))
	playsound(get_turf(growth), 'sound/effects/attackblob.ogg', 50, TRUE)

/datum/neoblob_type/astroclast/can_expand_to(var/obj/structure/neoblob/growth, var/turf/target)
	if(!target)
		return FALSE
	if(istype(target, /turf/space) || (istype(target, /turf/simulated/mineral) && target.density))
		return FALSE
	if(istype(target, /turf/simulated/wall))
		return FALSE
	return TRUE

/// Used when the neoblob failed can_expand_to() on a blocked turf.
/datum/neoblob_type/astroclast/on_blocked_turf(var/obj/structure/neoblob/growth, var/turf/target)
	if(istype(target, /turf/simulated/wall))
		var/turf/simulated/wall/SW = target
		if(!target.should_use_health)
			return FALSE
		// Damage reinforced walls reasonably quickly, but don't one-shot every standard wall.
		target.add_damage((rand(10, 40) * .01 * target.maxhealth) + 20)
		return TRUE
	return FALSE

// NEOBLOB_TODO - not sure the best way to store this behavior yet. hivebots are going to be this destructive... but in different ways. maybe bite the bullet and duplicate a bunch of logic.
/datum/neoblob_type/astroclast/on_contact_atom(var/obj/structure/neoblob/growth, var/atom/target)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE

	// Check for structures first. This still sucks ass from original implementation but it'll do for now.
	for(var/obj/structure/generic_structure in target_turf)
		if(istype(generic_structure, /obj/structure/girder))
			var/obj/structure/girder/G = generic_structure
			G.add_damage(rand(40, 80))
		if(istype(generic_structure, /obj/structure/window))
			var/obj/structure/window/W = generic_structure
			W.shatter()
		if(istype(generic_structure, /obj/structure/machinery/light))
			var/obj/structure/machinery/light/L = generic_structure
			L.broken()
		if(istype(generic_structure, /obj/structure/grille))
			qdel(generic_structure)
		if(istype(generic_structure, /obj/structure/tank_wall))
			generic_structure.add_damage(rand(5,20))
		if(istype(generic_structure, /obj/structure/machinery/door))
			var/obj/structure/machinery/door/D = generic_structure
			if(!D.density)
				continue
			growth.attack_door(D)
			if(D.health <= 0)
				if(!D.open(TRUE))
					D.visible_message(SPAN_WARNING("\The [growth] bashes through \the [D], demolishing it!"))
					qdel(D)
			if(!QDELETED(D) && D.density)
				return TRUE
		if(istype(generic_structure, /obj/structure/foamedmetal))
			generic_structure.visible_message(SPAN_WARNING("\The [growth] lashes into \the [generic_structure], tearing it apart!"))
			generic_structure.add_damage(30)
		if(istype(generic_structure, /obj/structure/reagent_dispensers))
			generic_structure.visible_message(SPAN_WARNING("\The [growth] pierces into \the [generic_structure], blowing it apart!"))
			generic_structure.ex_act(2)
		if(istype(generic_structure, /obj/structure/inflatable))
			var/obj/structure/inflatable/IF = generic_structure
			IF.visible_message(SPAN_WARNING("\The [growth] rips into \the [IF], tearing a hole into it!"))
			IF.deflate(TRUE)
		if(istype(generic_structure, /obj/structure/machinery/camera))
			var/obj/structure/machinery/camera/C = generic_structure
			if(!(C.stat & BROKEN))
				C.add_damage(30)

	for(var/obj/vehicle/V in target_turf)
		V.ex_act(2)

	for(var/mob/living/L in target_turf)
		if(L.stat == DEAD)
			continue
		growth.attack_living(L)

	return FALSE

//produce
/obj/item/neoblob_tendril
	name = "astroclast tendril"
	desc = "A tendril removed from an astroclast. It's entirely lifeless."
	icon = 'icons/mob/neoblob/astroclast.dmi'
	icon_state = "tendril"
	item_state = "blob_tendril"
	w_class = WEIGHT_CLASS_BULKY
	reach = 2 // long range tentacle whips - geeves
	attack_verb = list("smacked", "smashed", "whipped")
	var/types_of_tendril = list(TENDRIL_SOLID, TENDRIL_FIRE)

/obj/item/neoblob_tendril/Initialize()
	. = ..()
	var/tendril_type = pick(types_of_tendril)
	switch(tendril_type)
		if(TENDRIL_SOLID)
			desc = "An incredibly dense, yet flexible, tendril, removed from an astroclast."
			// You put in the effort, you deserve it, champ.
			force = 30
			color = COLOR_BRONZE
			origin_tech = list(TECH_MATERIAL = 2, TECH_BIO = 2)
		if(TENDRIL_FIRE)
			desc = "A tendril removed from an astroclast. It's hot to the touch."
			damtype = DAMAGE_BURN
			// You put in the effort, you deserve it, champ.
			force = 30
			color = COLOR_AMBER
			origin_tech = list(TECH_POWER = 2, TECH_BIO = 2)

/obj/item/neoblob_tendril/afterattack(obj/O, mob/user)
	if(prob(50))
		force--
		if(force <= 0)
			visible_message(SPAN_NOTICE("\The [src] crumbles apart!"))
			user.drop_from_inventory(src)
			new /obj/effect/decal/cleanable/ash(get_turf(src))
			qdel(src)

/obj/item/neoblob_core
	name = "astroclast nucleus sample"
	desc = "A sample taken from an astroclast's nucleus. It pulses with energy."
	icon_state = "core_sample"
	item_state = "blob_core"
	w_class = WEIGHT_CLASS_NORMAL
	origin_tech = list(TECH_MATERIAL = 4, TECH_BLUESPACE = 5, TECH_BIO = 7)

/obj/item/neoblob_core/aux
	name = "astroclast auxiliary nucleus sample"
	desc = "A sample taken from an astroclast's auxiliary nucleus."
	icon_state = "core_sample_2"
	origin_tech = list(TECH_MATERIAL = 2, TECH_BLUESPACE = 3, TECH_BIO = 4)
