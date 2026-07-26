/**
 * 'Neoblobs' are the backend behavior providers for all enemy cluster/growth types.
 * Consumers of this behavior include classic SS13 blobs, renamed 'astroblasts', and any other future enemy types that want to use the same growth/cluster behavior.
 *
 * NEOBLOB ARCHITECTURE OVERVIEW:
 * * /datum/neoblob_type: Defines behavior hooks and role paths. This is the main entry point for defining new neoblob types.
 * * /datum/neoblob_cluster: Represents a single cluster of neoblobs. This is the main entry point for managing clusters of neoblobs.
 * * /obj/structure/neoblob: Represents a single neoblob growth. This is the main entry point for the actual map objects.
 *
 * NEOBLOB CREATION AND PROCESSING OVERVIEW
 * * Master nucleus is created and assigned a neoblob type. This creates a new cluster and assigns the master nucleus to it.
 * * Master nucleus begins processing, which includes pulsing to grow new growths, and attacking nearby mobs.
 * * New growths are created and assigned the same neoblob type as the master nucleus. They are also assigned to the same cluster.
 * * New growths begin processing, which includes pulsing to grow new growths, attacking nearby mobs, damaging nearby objs, whatever.
 * * Neoblob growths can be destroyed by players.
 *
 * NEOBLOB LIFECYCLE OVERVIEW (astroclast-only, currently):
 * * 1. Master nucleus obj is spawned -> grows shield objs around itself
 * * 2. Shield objs are spawned -> grow ravaging objs around themselves
 * * 3. Ravaging objs are spawned -> grow mass objs (generic) around themselves
 * * 4. Mass objs are spawned -> grow MORE mass objs around themselves
 * * This continues until one such mass obj passes prob(secondary_core_growth_chance), which will grow a secondary core instead of a mass. This secondary core will then grow shield objs around itself, and the cycle continues.
 * * Note that in near-future, mass objs will also have a prob to grow factory or resource nodes.
 */
/obj/structure/neoblob
	name = "spreading mass"
	desc = "A spreading mass."
	icon = 'icons/mob/neoblob/astroclast.dmi'
	icon_state = "blob"
	light_range = 3
	light_power = 4
	light_color = NEOBLOB_COLOR_PULS
	density = TRUE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	material_alteration = MATERIAL_ALTERATION_NONE
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	pass_flags_self = PASSSTRUCTURE|PASSNEOBLOB
	material = MATERIAL_DIONA
	build_amt = 0

	layer = NEOBLOB_SHIELD_LAYER

	should_use_health = TRUE
	maxhealth = 30
	hitsound = 'sound/effects/attackblob.ogg'
	armor = list(
		MELEE = ARMOR_MELEE_RESISTANT,
		BULLET = ARMOR_BALLISTIC_MAJOR,
		LASER = ARMOR_LASER_SMALL,
		ENERGY = 0,
		BOMB = ARMOR_BOMB_RESISTANT
	)

	var/regen_rate = 5

	// THIS RESIST SHIT NEEDS TO BE FIGURED OUT NOW THAT WE USE THE ACTUAL ARMOR COMPONENT- keep it as a modifier? idk. unwired from anything atm.
	/// Damage gets divided by these modifiers, based on damage type
	var/brute_resist = 4.3
	var/fire_resist = 0.8
	/// Special resist for laser based weapons - Emitters or handheld energy weaponry. Damage is divided by this and THEN by fire_resist.
	var/laser_resist = 2

	/// % chance to grow a secondary neoblob core instead of whatever was supposed to grow. Secondary cores are considerably weaker, but still nasty.
	var/secondary_core_growth_chance = 5
	var/damage_min = 15
	var/damage_max = 25
	var/pruned = FALSE
	var/product = /obj/item/neoblob_tendril
	var/attack_time = 0
	/// Time in deciseconds before next attack will occur
	var/attack_cooldown = 60

	/// The core this neoblob piece belongs to
	var/obj/structure/neoblob/parent_core
	/// Determines how to pass core inheritance
	var/is_core = FALSE
	var/neoblob_role = NEOBLOB_ROLE_MASS
	var/neoblob_type = /datum/neoblob_type
	var/datum/neoblob_type/strain
	var/datum/neoblob_cluster/cluster
	/// Tint applied to greyscale neoblob icon states, when unset does not recolor
	var/neoblob_color

/obj/structure/neoblob
	neoblob_type = /datum/neoblob_type/astroclast

/atom/proc/is_neoblob()
	return FALSE

/obj/structure/neoblob/is_neoblob()
	return TRUE

/obj/structure/neoblob/Initialize(mapload, new_health, var/new_strain, var/datum/neoblob_cluster/new_cluster)
	. = ..()
	if(isnum(new_health))
		health = clamp(new_health, 1, maxhealth)
	ensure_strain(new_strain)
	setup_cluster(new_cluster)
	apply_strain_appearance()
	update_icon()
	dir = pick(GLOB.cardinals)
	START_PROCESSING(SSprocessing, src)

/obj/structure/neoblob/Destroy()
	if(cluster && !QDELETED(cluster))
		cluster.unregister_growth(src)
	strain = null
	cluster = null
	parent_core = null
	return ..()

/obj/structure/neoblob/proc/setup_cluster(var/datum/neoblob_cluster/new_cluster)
	if(new_cluster && !QDELETED(new_cluster))
		cluster = new_cluster
	else if(parent_core && !QDELETED(parent_core) && parent_core.cluster && !QDELETED(parent_core.cluster))
		cluster = parent_core.cluster
	else if(neoblob_role == NEOBLOB_ROLE_CORE)
		if(!strain)
			ensure_strain()
		cluster = new /datum/neoblob_cluster(strain)
	if(cluster)
		cluster.register_growth(src)
	return cluster

/obj/structure/neoblob/proc/ensure_strain(var/new_strain)
	if(strain && !new_strain)
		return strain
	if(istype(new_strain, /datum/neoblob_type))
		strain = new_strain
	else if(ispath(new_strain, /datum/neoblob_type))
		strain = new new_strain()
	if(!strain && parent_core && !QDELETED(parent_core))
		strain = parent_core.strain
	if(!strain && ispath(neoblob_type, /datum/neoblob_type))
		strain = new neoblob_type()
	apply_strain_stats()
	return strain

/obj/structure/neoblob/proc/apply_strain_stats()
	if(!strain)
		return
	brute_resist = strain.brute_resist
	fire_resist = strain.fire_resist
	laser_resist = strain.laser_resist

/obj/structure/neoblob/proc/apply_strain_appearance()
	if(!strain)
		return
	icon = strain.icon
	name = strain.get_name(src)
	desc = strain.get_desc(src)
	if(neoblob_color)
		color = neoblob_color || strain.color
	if(light_range && light_power)
		set_light(light_range, light_power, light_color)

/obj/structure/neoblob/CanPass(atom/movable/mover, turf/target, height, air_group)
	if(mover?.movement_type & PHASING)
		return TRUE
	if(mover?.pass_flags & pass_flags_self)
		return TRUE
	if(air_group || height == 0)
		return TRUE
	return FALSE

/obj/structure/neoblob/update_icon()
	icon_state = get_neoblob_icon_state()
	ClearOverlays()
	apply_neoblob_overlays()

/obj/structure/neoblob/proc/get_neoblob_icon_state()
	return (health > maxhealth / 2) ? "blob" : "blob_damaged"

/obj/structure/neoblob/proc/apply_neoblob_overlays()
	if(!strain)
		return

	var/overlay_sources = strain.get_icon_state_overlays(src)
	if(!overlay_sources)
		return

	if(!islist(overlay_sources))
		overlay_sources = list(overlay_sources)

	var/list/overlays_to_add = list()
	for(var/overlay_source in overlay_sources)
		if(!overlay_source)
			continue
		if(istext(overlay_source))
			if(!icon_exists(icon, overlay_source, TRUE))
				continue
			overlays_to_add += overlay_image(icon, overlay_source, flags = RESET_COLOR)
		else
			overlays_to_add += overlay_source

	if(length(overlays_to_add))
		AddOverlays(overlays_to_add)

/obj/structure/neoblob/update_health()
	update_icon()

/obj/structure/neoblob/process()
	if(!parent_core || QDELETED(parent_core))
		add_damage(maxhealth / 4) // four processes to die if main core is deddo
		return
	regen()
	if(world.time < (attack_time + attack_cooldown))
		return
	attempt_attack()

/obj/structure/neoblob/add_damage(damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	if(strain)
		damage = strain.on_received_damage(src, damage, damage_flags, damage_type, armor_penetration, weapon)
	. = ..(damage, damage_flags, damage_type, armor_penetration, weapon)

/obj/structure/neoblob/on_death(damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	if(strain)
		strain.on_death(src, damage, damage_flags, damage_type, armor_penetration, weapon)
	if(strain?.sound_death)
		playsound(get_turf(src), strain.sound_death, 50, TRUE)
	qdel(src)

/obj/structure/neoblob/dismantle()
	qdel(src)

/obj/structure/neoblob/proc/regen()
	if(add_health(regen_rate))
		update_icon()

/obj/structure/neoblob/proc/has_nearby_core(var/turf/T)
	for(var/obj/structure/neoblob/growth in range(2, T))
		if(growth.is_core)
			return TRUE
	return FALSE

/obj/structure/neoblob/proc/expand(var/turf/T)
	if(!strain)
		return NEOBLOB_EXPAND_STOP
	if(cluster && cluster.expansion_paused)
		return NEOBLOB_EXPAND_STOP
	if(!can_expand_to(T))
		return handle_blocked_turf(T)
	if(handle_contact_atom(T))
		return NEOBLOB_EXPAND_STOP

	var/growth_path = choose_growth_path(T)
	if(!growth_path)
		return NEOBLOB_EXPAND_STOP
	var/obj/structure/neoblob/new_growth = create_growth(T, growth_path)
	if(!new_growth)
		return NEOBLOB_EXPAND_STOP
	return post_expand(new_growth, T)

/obj/structure/neoblob/proc/can_expand_to(var/turf/T)
	if(!strain)
		return FALSE
	return strain.can_expand_to(src, T)

/obj/structure/neoblob/proc/handle_blocked_turf(var/turf/T)
	if(strain)
		strain.on_blocked_turf(src, T)
	return NEOBLOB_EXPAND_STOP

/// We've expanded to a turf- do evil shit to the atoms on that turf.
/obj/structure/neoblob/proc/handle_contact_atom(var/turf/T)
	if(!strain)
		return FALSE
	return strain.on_contact_atom(src, T)

/obj/structure/neoblob/proc/choose_growth_path(var/turf/T)
	if(!strain)
		return null
	return strain.choose_growth_path(src, T)

/obj/structure/neoblob/proc/create_growth(var/turf/T, var/growth_path)
	if(!strain || !ispath(growth_path, /obj/structure/neoblob))
		return null
	var/obj/structure/neoblob/inherited_core = parent_core
	if(is_core)
		inherited_core = src
	var/growth_health = min(health, 30)
	if(growth_path == strain.secondary_core_path)
		growth_health = null
	var/datum/neoblob_cluster/inherited_cluster = cluster
	if(!inherited_cluster && inherited_core && inherited_core.cluster && !QDELETED(inherited_core.cluster))
		inherited_cluster = inherited_core.cluster
	var/obj/structure/neoblob/new_growth = new growth_path(T, growth_health, strain, inherited_cluster)
	new_growth.parent_core = inherited_core
	if(!new_growth.cluster && inherited_cluster && !QDELETED(inherited_cluster))
		new_growth.setup_cluster(inherited_cluster)
	return new_growth

/obj/structure/neoblob/proc/post_expand(var/obj/structure/neoblob/new_growth, var/turf/T)
	if(!strain || !new_growth)
		return NEOBLOB_EXPAND_STOP
	strain.after_expand(src, new_growth, T)
	return NEOBLOB_EXPAND_STOP

/obj/structure/neoblob/proc/pulse(var/forceLeft, var/list/dirs, var/bad_dir)
	sleep(4)
	var/list/available_dirs = dirs - bad_dir
	if(!length(available_dirs))
		return
	var/pushDir = pick(available_dirs)
	var/turf/T = get_step(src, pushDir)
	if(!T)
		return
	var/obj/structure/neoblob/B = locate() in T
	if(!B)
		if(prob(health))
			var/expand_result = expand(T)
			if(expand_result == NEOBLOB_EXPAND_CONTINUE)
				pulse(forceLeft - 1, dirs, pushDir)
			else if(expand_result == NEOBLOB_EXPAND_RETRY)
				pulse(forceLeft, dirs, bad_dir)
	else if(forceLeft)
		B.pulse(forceLeft - 1, dirs - get_dir(B, src))

/obj/structure/neoblob/proc/attack_msg(atom/source)
	if(strain)
		strain.attack_msg(src, source)

/obj/structure/neoblob/proc/attack_door(var/obj/structure/machinery/door/D)
	if(!D)
		return
	attack_msg(D)
	D.add_damage(rand(damage_min, damage_max))

/obj/structure/neoblob/proc/attack_living(var/mob/living/L)
	if(!L)
		return
	if(strain)
		strain.on_attack_living(src, L)

/obj/structure/neoblob/proc/attempt_attack()
	var/mob/living/victim = locate() in view(1, src)
	if(victim)
		if(victim.stat == DEAD)
			return
		attack_living(victim)
		attack_time = world.time

/obj/structure/neoblob/attackby(obj/item/attacking_item, mob/user, params)
	if(attacking_item.tool_behaviour == TOOL_WIRECUTTER)
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		user.do_attack_animation(src)
		playsound(get_turf(src), hitsound, 50, TRUE)
		if(!pruned)
			to_chat(user, SPAN_NOTICE("You collect a sample from \the [src]."))
			var/product_type = strain ? strain.get_pruned_product(src) : product
			if(product_type)
				var/obj/P = new product_type(get_turf(user))
				user.put_in_hands(P)
			pruned = TRUE
			return
		else
			to_chat(user, SPAN_WARNING("\The [src] has already been pruned."))
			return

	. = ..()

/obj/structure/neoblob/fire_act(exposed_temperature, exposed_volume)
	. = ..()

	add_damage(rand(5, 20), NONE, DAMAGE_BURN)

/obj/structure/neoblob/core
	name = "master nucleus"
	desc = "A massive, fragile nucleus guarded by a shield of thick tendrils."
	icon_state = "blob_core"
	maxhealth = 450
	damage_min = 25
	damage_max = 35
	product = /obj/item/neoblob_core
	is_core = TRUE
	neoblob_role = NEOBLOB_ROLE_CORE

	light_color = NEOBLOB_COLOR_CORE
	layer = NEOBLOB_CORE_LAYER

	var/may_process = TRUE
	var/reported_low_damage = FALSE
	/// How far the core can potentially grow in size
	var/pulse_power = 50
	var/times_to_pulse = 4

/obj/structure/neoblob/core/proc/get_health_percent()
	return ((health / maxhealth) * 100)

/obj/structure/neoblob/core/proc/process_core_health()
	var/health_percent = get_health_percent()
	if(health_percent > 75)
		if(reported_low_damage)
			report_shield_status(CORE_SHIELD_HIGH)
	else if(health_percent < 33)
		if(!reported_low_damage)
			report_shield_status(CORE_SHIELD_LOW)

/obj/structure/neoblob/core/proc/report_shield_status(var/status)
	if(status == CORE_SHIELD_LOW)
		visible_message(SPAN_DANGER("\The [src]'s internal tendril shield fails, leaving the nucleus vulnerable!"), 3)
		reported_low_damage = TRUE
	if(status == CORE_SHIELD_HIGH)
		visible_message(SPAN_DANGER("\The [src]'s internal tendril shield seems to have fully reformed."), 3)
		reported_low_damage = FALSE

/obj/structure/neoblob/core/verb/manage_neoblob_cluster()
	set name = "Manage Neoblob Cluster"
	set desc = "Open the admin control panel for this neoblob cluster."
	set category = "Debug"
	set src in view()

	if(!usr || !usr.client || !check_rights(R_DEBUG, FALSE, usr))
		return
	if(neoblob_role != NEOBLOB_ROLE_CORE)
		to_chat(usr, SPAN_WARNING("Only master nuclei can open the neoblob cluster panel."))
		return
	if(!cluster || QDELETED(cluster))
		to_chat(usr, SPAN_WARNING("\The [src] does not have a valid neoblob cluster."))
		return
	cluster.ui_interact(usr)

/// Rough icon state changes that reflect the core's health
/obj/structure/neoblob/core/get_neoblob_icon_state()
	switch(get_health_percent())
		if(66 to INFINITY)
			return "blob_core"
		if(33 to 66)
			return "blob_node"
		if(-INFINITY to 33)
			return "blob_factory"

/obj/structure/neoblob/core/process()
	set waitfor = 0
	if(!may_process)
		return
	may_process = FALSE
	process_core_health()
	regen()
	if(strain)
		strain.on_core_process(src)
	if(!cluster || !cluster.expansion_paused)
		for(var/i = 1 to times_to_pulse)
			pulse(pulse_power, GLOB.cardinals.Copy())
	may_process = TRUE
	if(world.time < (attack_time + attack_cooldown))
		return
	attempt_attack()

/// Blob has a very small probability of growing these when spreading. These will spread the blob further.
/obj/structure/neoblob/core/secondary
	name = "auxiliary nucleus"
	desc = "An interwoven mass of tendrils. A glowing nucleus pulses at its center."
	icon_state = "blob_node"
	maxhealth = 125
	regen_rate = 1
	damage_min = 15
	damage_max = 20
	layer = NEOBLOB_NODE_LAYER
	product = /obj/item/neoblob_core/aux
	neoblob_role = NEOBLOB_ROLE_SECONDARY_CORE
	pulse_power = 20 // Not as strong as big daddy core
	times_to_pulse = 4

/obj/structure/neoblob/core/secondary/process()
	if(!parent_core || QDELETED(parent_core))
		add_damage(maxhealth / 4) // four processes to die if main core is deddo
		return
	..()

/obj/structure/neoblob/core/secondary/process_core_health()
	return

/obj/structure/neoblob/core/secondary/get_neoblob_icon_state()
	return (health / maxhealth >= 0.5) ? "blob_node" : "blob_factory"

/obj/structure/neoblob/shield
	name = "shielding mass"
	desc = "A pulsating mass of interwoven tendrils. These seem particularly robust, but not quite as active."
	icon_state = "blob_shield"
	maxhealth = 120
	damage_min = 15
	damage_max = 25
	attack_cooldown = 45
	regen_rate = 4
	opacity = TRUE
	neoblob_role = NEOBLOB_ROLE_SHIELD
	light_color = NEOBLOB_COLOR_SHIELD
	armor = list(
		MELEE = ARMOR_MELEE_VERY_HIGH,
		BULLET = ARMOR_BALLISTIC_AP,
		LASER = ARMOR_LASER_MEDIUM,
		ENERGY = ARMOR_ENERGY_MINOR,
		BOMB = ARMOR_BOMB_RESISTANT
	)

/obj/structure/neoblob/shield/Initialize()
	. = ..()
	update_nearby_tiles()

/obj/structure/neoblob/shield/Destroy()
	density = FALSE
	update_nearby_tiles()
	return ..()

/obj/structure/neoblob/shield/get_neoblob_icon_state()
	return (health > maxhealth / 3) ? "blob_shield" : "blob_shield_damaged"

/obj/structure/neoblob/shield/CanPass(var/atom/movable/mover, var/turf/target, var/height = 0, var/air_group = 0)
	if(mover?.movement_type & PHASING)
		return TRUE
	if(mover?.pass_flags & pass_flags_self)
		return TRUE
	return !density

/obj/structure/neoblob/ravaging
	name = "ravaging mass"
	desc = "A mass of interwoven tendrils. They thrash around haphazardly at anything in reach."
	maxhealth = 20
	damage_min = 20
	damage_max = 25
	attack_cooldown = 30
	light_color = NEOBLOB_COLOR_RAV
	neoblob_role = NEOBLOB_ROLE_RAVAGING
