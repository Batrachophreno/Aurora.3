/**
 * 'Neoblobs' are the backend behavior providers for all enemy cluster/growth types.
 * Consumers of this behavior include classic SS13 blobs, renamed 'astroblasts', and any other future enemy types that want to use the same growth/cluster behavior.
 *
 * NEOBLOB ARCHITECTURE OVERVIEW:
 * * /datum/neoblob_type: Defines behavior hooks and role paths. This is the main entry point for defining new neoblob types.
 * * /datum/neoblob_cluster: Represents a single cluster of neoblobs. This is the main entry point for managing clusters of neoblobs.
 * * /obj/effect/neoblob: Represents a single neoblob growth. This is the main entry point for the actual map objects.
 *
 * NEOBLOB CREATION AND PROCESSING OVERVIEW
 * * Master nucleus is created and assigned a neoblob type. This creates a new cluster and assigns the master nucleus to it.
 * * Master nucleus begins processing, which includes pulsing to grow new growths, and attacking nearby mobs.
 * * New growths are created and assigned the same neoblob type as the master nucleus. They are also assigned to the same cluster.
 * * New growths begin processing, which includes pulsing to grow new growths, and attacking nearby mobs.
 * * Neoblob growths can be destroyed by players, which will remove them from the cluster and stop their processing.
 *
 * NEOBLOB LIFECYCLE OVERVIEW:
 * * 1. Master nucleus obj is spawned -> grows shield objs around itself
 * * 2. Shield objs are spawned -> grow ravaging objs around themselves
 * * 3. Ravaging objs are spawned -> grow mass objs (generic) around themselves
 * * 4. Mass objs are spawned -> grow MORE mass objs around themselves
 * * This continues until one such mass obj passes prob(secondary_core_growth_chance), which will grow a secondary core instead of a mass. This secondary core will then grow shield objs around itself, and the cycle continues.
 * * Note that in near-future, mass objs will also have a prob to grow factory or resource nodes.
 */
/obj/effect/neoblob
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

	layer = NEOBLOB_SHIELD_LAYER

	should_use_health = TRUE
	maxhealth = 30

	var/regen_rate = 5

	/// Damage gets divided by these modifiers, based on damage type
	var/brute_resist = 4.3
	var/fire_resist = 0.8
	/// Special resist for laser based weapons - Emitters or handheld energy weaponry. Damage is divided by this and THEN by fire_resist.
	var/laser_resist = 2

	/// Compatibility fallback while growth paths migrate to /datum/neoblob_type.
	var/expandType = /obj/effect/neoblob
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
	var/obj/effect/neoblob/parent_core
	/// Determines how to pass core inheritance
	var/is_core = FALSE
	var/neoblob_role = NEOBLOB_ROLE_MASS
	var/neoblob_type = /datum/neoblob_type
	var/datum/neoblob_type/strain
	var/datum/neoblob_cluster/cluster
	/// Compatibility fallback while growth paths migrate to /datum/neoblob_type
	var/secondary_core_growth_type

/obj/effect/neoblob
	neoblob_type = /datum/neoblob_type/astroclast
	secondary_core_growth_type = /obj/effect/neoblob/core/secondary

/atom/proc/is_neoblob()
	return FALSE

/obj/effect/neoblob/is_neoblob()
	return TRUE

/obj/effect/neoblob/Initialize(mapload, new_health, var/new_strain, var/datum/neoblob_cluster/new_cluster)
	. = ..()
	if(isnum(new_health))
		health = clamp(new_health, 1, maxhealth)
	ensure_strain(new_strain)
	setup_cluster(new_cluster)
	apply_strain_appearance()
	update_icon()
	dir = pick(GLOB.cardinals)
	START_PROCESSING(SSprocessing, src)

/obj/effect/neoblob/Destroy()
	if(cluster && !QDELETED(cluster))
		cluster.unregister_growth(src)
	strain = null
	cluster = null
	parent_core = null
	return ..()

/obj/effect/neoblob/proc/setup_cluster(var/datum/neoblob_cluster/new_cluster)
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

/obj/effect/neoblob/proc/ensure_strain(var/new_strain)
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

/obj/effect/neoblob/proc/apply_strain_stats()
	if(!strain)
		return
	brute_resist = strain.brute_resist
	fire_resist = strain.fire_resist
	laser_resist = strain.laser_resist

/obj/effect/neoblob/proc/apply_strain_appearance()
	if(!strain)
		return
	icon = strain.icon
	name = strain.get_name(src)
	desc = strain.get_desc(src)
	color = strain.color
	light_color = strain.color
	if(light_range && light_power)
		set_light(light_range, light_power, strain.color)

/obj/effect/neoblob/CanPass(atom/movable/mover, turf/target, height, air_group)
	if(mover?.movement_type & PHASING)
		return TRUE
	if(air_group || height == 0)
		return TRUE
	return FALSE

/obj/effect/neoblob/ex_act(var/severity)
	switch(severity)
		if(1)
			add_damage(rand(100, 120) / brute_resist)
		if(2)
			add_damage(rand(60, 100) / brute_resist)
		if(3)
			add_damage(rand(20, 60) / brute_resist)

/obj/effect/neoblob/update_icon()
	if(health > maxhealth / 2)
		icon_state = "blob"
	else
		icon_state = "blob_damaged"

/obj/effect/neoblob/update_health()
	update_icon()

/obj/effect/neoblob/process()
	if(!parent_core || QDELETED(parent_core))
		add_damage(maxhealth / 4) // four processes to die if main core is deddo
		return
	regen()
	if(world.time < (attack_time + attack_cooldown))
		return
	attempt_attack()

/obj/effect/neoblob/add_damage(damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	if(strain)
		damage = strain.on_received_damage(src, damage, damage_flags, damage_type, armor_penetration, weapon)
	. = ..(damage, damage_flags, damage_type, armor_penetration, weapon)

/obj/effect/neoblob/on_death(damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	if(strain)
		strain.on_death(src, damage, damage_flags, damage_type, armor_penetration, weapon)
	playsound(get_turf(src), strain.sound_death, 50, TRUE)
	. = ..()

/obj/effect/neoblob/proc/regen()
	if(add_health(regen_rate))
		update_icon()

/obj/effect/neoblob/proc/has_nearby_core(var/turf/T)
	for(var/obj/effect/neoblob/growth in range(2, T))
		if(growth.is_core)
			return TRUE
	return FALSE

/obj/effect/neoblob/proc/expand(var/turf/T)
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
	var/obj/effect/neoblob/new_growth = create_growth(T, growth_path)
	if(!new_growth)
		return NEOBLOB_EXPAND_STOP
	return post_expand(new_growth, T)

/obj/effect/neoblob/proc/can_expand_to(var/turf/T)
	if(!strain)
		return FALSE
	return strain.can_expand_to(src, T)

/obj/effect/neoblob/proc/handle_blocked_turf(var/turf/T)
	if(strain)
		strain.on_blocked_turf(src, T)
	return NEOBLOB_EXPAND_STOP

/// We've expanded to a turf- do evil shit to the atoms on that turf.
/obj/effect/neoblob/proc/handle_contact_atom(var/turf/T)
	if(!strain)
		return FALSE
	return strain.on_contact_atom(src, T)

/obj/effect/neoblob/proc/choose_growth_path(var/turf/T)
	if(!strain)
		return null
	return strain.choose_growth_path(src, T)

/obj/effect/neoblob/proc/create_growth(var/turf/T, var/growth_path)
	if(!strain || !ispath(growth_path, /obj/effect/neoblob))
		return null
	var/obj/effect/neoblob/inherited_core = parent_core
	if(is_core)
		inherited_core = src
	var/growth_health = min(health, 30)
	if(growth_path == strain.secondary_core_path || growth_path == secondary_core_growth_type)
		growth_health = null
	var/datum/neoblob_cluster/inherited_cluster = cluster
	if(!inherited_cluster && inherited_core && inherited_core.cluster && !QDELETED(inherited_core.cluster))
		inherited_cluster = inherited_core.cluster
	var/obj/effect/neoblob/new_growth = new growth_path(T, growth_health, strain, inherited_cluster)
	new_growth.parent_core = inherited_core
	if(!new_growth.cluster && inherited_cluster && !QDELETED(inherited_cluster))
		new_growth.setup_cluster(inherited_cluster)
	return new_growth

/obj/effect/neoblob/proc/post_expand(var/obj/effect/neoblob/new_growth, var/turf/T)
	if(!strain || !new_growth)
		return NEOBLOB_EXPAND_STOP
	strain.after_expand(src, new_growth, T)
	return NEOBLOB_EXPAND_STOP

/obj/effect/neoblob/proc/pulse(var/forceLeft, var/list/dirs, var/bad_dir)
	sleep(4)
	var/list/available_dirs = dirs - bad_dir
	if(!length(available_dirs))
		return
	var/pushDir = pick(available_dirs)
	var/turf/T = get_step(src, pushDir)
	if(!T)
		return
	var/obj/effect/neoblob/B = locate() in T
	if(!B)
		if(prob(health))
			var/expand_result = expand(T)
			if(expand_result == NEOBLOB_EXPAND_CONTINUE)
				pulse(forceLeft - 1, dirs, pushDir)
			else if(expand_result == NEOBLOB_EXPAND_RETRY)
				pulse(forceLeft, dirs, bad_dir)
	else if(forceLeft)
		B.pulse(forceLeft - 1, dirs - get_dir(B, src))

/obj/effect/neoblob/proc/attack_msg(atom/source)
	if(strain)
		strain.attack_msg(src, source)

/obj/effect/neoblob/proc/attack_door(var/obj/structure/machinery/door/D)
	if(!D)
		return
	attack_msg(D)
	D.add_damage(rand(damage_min, damage_max))

/obj/effect/neoblob/proc/attack_living(var/mob/living/L)
	if(!L)
		return
	if(strain)
		strain.on_attack_living(src, L)

/obj/effect/neoblob/proc/attempt_attack()
	var/mob/living/victim = locate() in view(1, src)
	if(victim)
		if(victim.stat == DEAD)
			return
		attack_living(victim)
		attack_time = world.time

/obj/effect/neoblob/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit)
	. = ..()
	if(. != BULLET_ACT_HIT)
		return .

	if(!hitting_projectile)
		return

	switch(hitting_projectile.damage_type)
		if(DAMAGE_BRUTE)
			add_damage(hitting_projectile.damage / brute_resist)
		if(DAMAGE_BURN)
			add_damage((hitting_projectile.damage / laser_resist) / fire_resist)

/obj/effect/neoblob/attackby(obj/item/attacking_item, mob/user)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.do_attack_animation(src)
	playsound(get_turf(src), 'sound/effects/attackblob.ogg', 50, TRUE)
	if(attacking_item.tool_behaviour == TOOL_WIRECUTTER)
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

	var/damage = 0
	switch(attacking_item.damtype)
		if(DAMAGE_BURN)
			damage = (attacking_item.force / fire_resist)
			if(attacking_item.tool_behaviour == TOOL_WELDER)
				playsound(get_turf(src), 'sound/items/Welder.ogg', 100, TRUE)
		if(DAMAGE_BRUTE)
			damage = (attacking_item.force / brute_resist)

	add_damage(damage)

/obj/effect/neoblob/fire_act(exposed_temperature, exposed_volume)
	. = ..()

	add_damage(rand(5, 20) / fire_resist)

/obj/effect/neoblob/core
	name = "master nucleus"
	desc = "A massive, fragile nucleus guarded by a shield of thick tendrils."
	icon_state = "blob_core"
	maxhealth = 450
	damage_min = 25
	damage_max = 35
	expandType = /obj/effect/neoblob/shield
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

/obj/effect/neoblob/core/proc/get_health_percent()
	return ((health / maxhealth) * 100)

/obj/effect/neoblob/core/proc/process_core_health()
	var/health_percent = get_health_percent()
	if(health_percent > 75)
		if(reported_low_damage)
			report_shield_status(CORE_SHIELD_HIGH)
	else if(health_percent < 33)
		if(!reported_low_damage)
			report_shield_status(CORE_SHIELD_LOW)

/obj/effect/neoblob/core/proc/report_shield_status(var/status)
	if(status == CORE_SHIELD_LOW)
		visible_message(SPAN_DANGER("\The [src]'s internal tendril shield fails, leaving the nucleus vulnerable!"), 3)
		reported_low_damage = TRUE
	if(status == CORE_SHIELD_HIGH)
		visible_message(SPAN_DANGER("\The [src]'s internal tendril shield seems to have fully reformed."), 3)
		reported_low_damage = FALSE

/obj/effect/neoblob/core/verb/manage_neoblob_cluster()
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
/obj/effect/neoblob/core/update_icon()
	switch(get_health_percent())
		if(66 to INFINITY)
			icon_state = "blob_core"
		if(33 to 66)
			icon_state = "blob_node"
		if(-INFINITY to 33)
			icon_state = "blob_factory"

/obj/effect/neoblob/core/process()
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
/obj/effect/neoblob/core/secondary
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

/obj/effect/neoblob/core/secondary/process()
	if(!parent_core || QDELETED(parent_core))
		add_damage(maxhealth / 4) // four processes to die if main core is deddo
		return
	..()

/obj/effect/neoblob/core/secondary/process_core_health()
	return

/obj/effect/neoblob/core/secondary/update_icon()
	icon_state = (health / maxhealth >= 0.5) ? "blob_node" : "blob_factory"

/obj/effect/neoblob/shield
	name = "shielding mass"
	desc = "A pulsating mass of interwoven tendrils. These seem particularly robust, but not quite as active."
	icon_state = "blob_shield"
	maxhealth = 120
	damage_min = 15
	damage_max = 25
	attack_cooldown = 45
	regen_rate = 4
	opacity = TRUE
	expandType = /obj/effect/neoblob/ravaging
	neoblob_role = NEOBLOB_ROLE_SHIELD
	light_color = NEOBLOB_COLOR_SHIELD

/obj/effect/neoblob/shield/Initialize()
	. = ..()
	update_nearby_tiles()

/obj/effect/neoblob/shield/Destroy()
	density = FALSE
	update_nearby_tiles()
	return ..()

/obj/effect/neoblob/shield/update_icon()
	if(health > maxhealth / 3)
		icon_state = "blob_shield"
	else
		icon_state = "blob_shield_damaged"

/obj/effect/neoblob/shield/CanPass(var/atom/movable/mover, var/turf/target, var/height = 0, var/air_group = 0)
	if(mover?.movement_type & PHASING)
		return TRUE
	return !density

/obj/effect/neoblob/ravaging
	name = "ravaging mass"
	desc = "A mass of interwoven tendrils. They thrash around haphazardly at anything in reach."
	maxhealth = 20
	damage_min = 20
	damage_max = 25
	attack_cooldown = 30
	light_color = NEOBLOB_COLOR_RAV
	neoblob_role = NEOBLOB_ROLE_RAVAGING
