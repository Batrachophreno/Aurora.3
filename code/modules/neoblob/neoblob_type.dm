/datum/neoblob_type
	var/name = "infestation"
	var/color = COLOR_WHITE
	var/complementary_color = COLOR_WHITE
	var/icon = 'icons/mob/neoblob/astroclast.dmi'
	var/list/icon_state_overlays
	var/faction = "infestation"
	var/attack_weapon = "writhing mass"

	/// Generic mass
	var/mass_path = /obj/structure/neoblob
	/// The master nucleus: only one can exist per cluster.
	var/core_path = /obj/structure/neoblob/core
	/// Auxiliary nuclei: these are smaller than the master nucleus, and can exist in multiples per cluster.
	var/secondary_core_path = /obj/structure/neoblob/core/secondary
	var/shield_path = /obj/structure/neoblob/shield
	var/ravaging_path = /obj/structure/neoblob/ravaging
	var/node_path
	var/factory_path
	var/resource_path

	var/mass_name = "spreading mass"
	var/mass_desc = "A spreading mass."
	var/core_name = "central mass"
	var/core_desc = "A large mass directing the infestation's spread."
	var/secondary_core_name = "auxiliary mass"
	var/secondary_core_desc = "A smaller mass directing nearby infestation growth."
	var/shield_name = "shielding mass"
	var/shield_desc = "A robust section of spreading mass."
	var/ravaging_name = "ravaging mass"
	var/ravaging_desc = "A section of spreading mass lashing out at anything in reach."

	/// todo- modify armor component behavior? idk
	var/brute_resist = 4.3
	var/fire_resist = 0.8
	var/laser_resist = 2

	var/sound_death = 'sound/effects/splat.ogg'

/datum/neoblob_type/proc/get_name(var/obj/structure/neoblob/growth)
	switch(growth.neoblob_role)
		if(NEOBLOB_ROLE_CORE)
			return core_name
		if(NEOBLOB_ROLE_SECONDARY_CORE)
			return secondary_core_name
		if(NEOBLOB_ROLE_SHIELD)
			return shield_name
		if(NEOBLOB_ROLE_RAVAGING)
			return ravaging_name
	return mass_name

/datum/neoblob_type/proc/get_desc(var/obj/structure/neoblob/growth)
	switch(growth.neoblob_role)
		if(NEOBLOB_ROLE_CORE)
			return core_desc
		if(NEOBLOB_ROLE_SECONDARY_CORE)
			return secondary_core_desc
		if(NEOBLOB_ROLE_SHIELD)
			return shield_desc
		if(NEOBLOB_ROLE_RAVAGING)
			return ravaging_desc
	return mass_desc

/datum/neoblob_type/proc/get_icon_state_overlays(var/obj/structure/neoblob/growth)
	if(!growth || !length(icon_state_overlays))
		return null
	return icon_state_overlays[growth.icon_state]

/datum/neoblob_type/proc/attack_msg(var/obj/structure/neoblob/growth, var/atom/target)
	target.visible_message(SPAN_WARNING("\The [growth] lashes out at \the [target]!"), SPAN_DANGER("\The [growth] lashes out at you!"))
	playsound(get_turf(growth), 'sound/effects/attackblob.ogg', 50, TRUE)

/datum/neoblob_type/proc/on_attack_living(var/obj/structure/neoblob/growth, var/mob/living/victim)
	var/infestation_damage = pick(DAMAGE_BRUTE, DAMAGE_BURN)
	attack_msg(growth, victim)
	victim.apply_damage(rand(growth.damage_min, growth.damage_max), infestation_damage, used_weapon = attack_weapon)

/datum/neoblob_type/proc/on_received_damage(var/obj/structure/neoblob/growth, damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	return damage

/datum/neoblob_type/proc/on_death(var/obj/structure/neoblob/growth, damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	return

/datum/neoblob_type/proc/on_expand(var/obj/structure/neoblob/growth, var/obj/structure/neoblob/new_growth, var/turf/target)
	return

/datum/neoblob_type/proc/can_expand_to(var/obj/structure/neoblob/growth, var/turf/target)
	return !isnull(target)

/datum/neoblob_type/proc/on_blocked_turf(var/obj/structure/neoblob/growth, var/turf/target)
	return FALSE

/// Called on expansion to an open turf. Iterate through what you've just landed on, and fuck them all up (probably).
/datum/neoblob_type/proc/on_contact_atom(var/obj/structure/neoblob/growth, var/turf/target)
	return FALSE

/// Certain growth types will always grow into a specific type of growth, regardless of the target turf. This is used for things like cores always growing shields, and shields always growing ravaging growths.
/datum/neoblob_type/proc/get_default_growth_path(var/obj/structure/neoblob/growth)
	switch(growth.neoblob_role)
		if(NEOBLOB_ROLE_CORE, NEOBLOB_ROLE_SECONDARY_CORE)
			return shield_path
		if(NEOBLOB_ROLE_SHIELD)
			return ravaging_path
	return mass_path

/datum/neoblob_type/proc/choose_growth_path(var/obj/structure/neoblob/growth, var/turf/target)
	if(!growth.has_nearby_core(target) && secondary_core_path && prob(growth.secondary_core_growth_chance))
		return secondary_core_path
	return get_default_growth_path(growth)

/datum/neoblob_type/proc/after_expand(var/obj/structure/neoblob/growth, var/obj/structure/neoblob/new_growth, var/turf/target)
	on_expand(growth, new_growth, target)

/datum/neoblob_type/proc/on_core_process(var/obj/structure/neoblob/growth)
	return

/datum/neoblob_type/proc/get_pruned_product(var/obj/structure/neoblob/growth)
	return growth.product
