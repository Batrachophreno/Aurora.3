/datum/neoblob_type
	var/name = "infestation"
	var/color = COLOR_WHITE
	var/complementary_color = COLOR_WHITE
	var/icon = 'icons/mob/neoblob/astroclast.dmi'
	var/faction = "infestation"
	var/attack_weapon = "writhing mass"

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

	var/brute_resist = 4.3
	var/fire_resist = 0.8
	var/laser_resist = 2

/datum/neoblob_type/proc/get_name(var/obj/effect/neoblob/growth)
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

/datum/neoblob_type/proc/get_desc(var/obj/effect/neoblob/growth)
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

/datum/neoblob_type/proc/attack_msg(var/obj/effect/neoblob/growth, var/atom/target)
	target.visible_message(SPAN_WARNING("\The [growth] lashes out at \the [target]!"), SPAN_DANGER("\The [growth] lashes out at you!"))
	playsound(get_turf(growth), 'sound/effects/attackblob.ogg', 50, TRUE)

/datum/neoblob_type/proc/on_attack_living(var/obj/effect/neoblob/growth, var/mob/living/victim)
	var/infestation_damage = pick(DAMAGE_BRUTE, DAMAGE_BURN)
	attack_msg(growth, victim)
	victim.apply_damage(rand(growth.damage_min, growth.damage_max), infestation_damage, used_weapon = attack_weapon)

/datum/neoblob_type/proc/on_received_damage(var/obj/effect/neoblob/growth, damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	return damage

/datum/neoblob_type/proc/on_death(var/obj/effect/neoblob/growth, damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	return

/datum/neoblob_type/proc/on_expand(var/obj/effect/neoblob/growth, var/obj/effect/neoblob/new_growth, var/turf/target)
	return

/datum/neoblob_type/proc/on_core_process(var/obj/effect/neoblob/growth)
	return

/datum/neoblob_type/proc/get_pruned_product(var/obj/effect/neoblob/growth)
	return growth.product

/datum/neoblob_type/astroclast
	name = "astroclast"
	color = "#AAFF00"
	complementary_color = "#57787B"
	faction = "astroclast"
	attack_weapon = "astroclast tendril"

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

/datum/neoblob_type/astroclast/attack_msg(var/obj/effect/neoblob/growth, var/atom/target)
	target.visible_message(SPAN_WARNING("A tendril flies out from \the [growth] and smashes into \the [target]!"), SPAN_DANGER("A tendril flies out from \the [growth] and smashes into you!"))
	playsound(get_turf(growth), 'sound/effects/attackblob.ogg', 50, TRUE)

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
	var/secondary_core_growth_type

/obj/effect/neoblob
	neoblob_type = /datum/neoblob_type/astroclast
	secondary_core_growth_type = /obj/effect/neoblob/core/secondary

/atom/proc/is_neoblob()
	return FALSE

/obj/effect/neoblob/is_neoblob()
	return TRUE

/obj/effect/neoblob/Initialize(mapload, new_health, var/new_strain)
	. = ..()
	if(isnum(new_health))
		health = clamp(new_health, 1, maxhealth)
	ensure_strain(new_strain)
	update_icon()
	START_PROCESSING(SSprocessing, src)

/obj/effect/neoblob/Destroy()
	strain = null
	parent_core = null
	return ..()

/obj/effect/neoblob/proc/ensure_strain(var/new_strain)
	if(istype(new_strain, /datum/neoblob_type))
		strain = new_strain
	else if(ispath(new_strain, /datum/neoblob_type))
		strain = new new_strain()
	if(!strain && parent_core && !QDELETED(parent_core))
		strain = parent_core.strain
	if(!strain && ispath(neoblob_type, /datum/neoblob_type))
		strain = new neoblob_type()
	if(strain)
		brute_resist = strain.brute_resist
		fire_resist = strain.fire_resist
		laser_resist = strain.laser_resist
	return strain

/obj/effect/neoblob/proc/apply_strain_apperance()
	var/datum/neoblob_type/current_strain = ensure_strain()
	if(!current_strain)
		return
	icon = current_strain.icon
	name = current_strain.get_name(src)
	desc = current_strain.get_desc(src)
	color = current_strain.color
	light_color = current_strain.color
	if(light_range && light_power)
		set_light(light_range, light_power, current_strain.color)

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
	apply_strain_apperance()

/obj/effect/neoblob/process()
	if(!parent_core || QDELETED(parent_core))
		add_damage(maxhealth / 4) // four processes to die if main core is deddo
		return
	regen()
	if(world.time < (attack_time + attack_cooldown))
		return
	attempt_attack()

/obj/effect/neoblob/add_damage(damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	var/datum/neoblob_type/current_strain = ensure_strain()
	if(current_strain)
		damage = current_strain.on_received_damage(src, damage, damage_flags, damage_type, armor_penetration, weapon)
	. = ..(damage, damage_flags, damage_type, armor_penetration, weapon)
	update_icon()

/obj/effect/neoblob/on_death(damage, damage_flags, damage_type, armor_penetration, obj/weapon)
	var/datum/neoblob_type/current_strain = ensure_strain()
	if(current_strain)
		current_strain.on_death(src, damage, damage_flags, damage_type, armor_penetration, weapon)
	playsound(get_turf(src), 'sound/effects/splat.ogg', 50, TRUE)
	. = ..()

/obj/effect/neoblob/proc/regen()
	health = min(health + regen_rate, maxhealth)
	update_icon()

/obj/effect/neoblob/proc/has_nearby_core(var/turf/T)
	for(var/obj/effect/neoblob/growth in range(2, T))
		if(growth.is_core)
			return TRUE
	return FALSE

/obj/effect/neoblob/proc/expand(var/turf/T)
	if(istype(T, /turf/space) || (isopenturf(T)) || (istype(T, /turf/simulated/mineral) && T.density))
		return
	if(istype(T, /turf/simulated/wall))
		var/turf/simulated/wall/SW = T
		SW.add_damage(80)
		return
	var/obj/structure/girder/G = locate() in T
	if(G)
		G.add_damage(rand(40, 80))
		return
	var/obj/structure/window/W = locate() in T
	if(W)
		W.shatter()
		return
	var/obj/structure/grille/GR = locate() in T
	if(GR)
		qdel(GR)
		return
	var/obj/structure/tank_wall/TW = locate() in T
	if(TW)
		TW.add_damage(rand(5,20))
		return
	for(var/obj/structure/machinery/door/D in T) // There can be several - and some of them can be open, locate() is not suitable
		if(D.density)
			attack_door(D)
			if(D.health <= 0)
				if(!D.open(TRUE))
					D.visible_message(SPAN_WARNING("\The [src] bashes through \the [D], demolishing it!"))
					qdel(D)
			return
	var/obj/structure/foamedmetal/F = locate() in T
	if(F)
		F.visible_message(SPAN_WARNING("\The [src] lashes into \the [F], tearing it apart!"))
		qdel(F)
		return
	var/obj/structure/reagent_dispensers/RT = locate() in T
	if(RT)
		RT.visible_message(SPAN_WARNING("\The [src] pierces into \the [RT], blowing it apart!"))
		RT.ex_act(2)
		return
	var/obj/structure/inflatable/I = locate() in T
	if(I)
		I.visible_message(SPAN_WARNING("\The [src] rips into \the [F], tearing a hole into it!"))
		I.deflate(TRUE)
		return
	var/obj/vehicle/V = locate() in T
	if(V)
		V.ex_act(2)
		return
	var/obj/structure/machinery/camera/CA = locate() in T
	if(CA && !(CA.stat & BROKEN))
		CA.add_damage(30)
		return

	// Above things, we destroy completely and thus can use locate. Mobs are different.
	for(var/mob/living/L in T)
		if(L.stat == DEAD)
			continue
		attack_living(L)

	var/obj/effect/neoblob/inherited_core = parent_core
	if(is_core)
		inherited_core = src

	var/datum/neoblob_type/current_strain = ensure_strain()
	if(!has_nearby_core(T) && secondary_core_growth_type && prob(secondary_core_growth_chance))
		var/obj/effect/neoblob/S = new secondary_core_growth_type(T, null, current_strain)
		S.parent_core = inherited_core
		if(current_strain)
			current_strain.on_expand(src, S, T)
	else
		var/obj/effect/neoblob/B = new expandType(T, min(health, 30), current_strain)
		B.parent_core = inherited_core
		if(current_strain)
			current_strain.on_expand(src, B, T)

/obj/effect/neoblob/proc/pulse(var/forceLeft, var/list/dirs, var/bad_dir)
	sleep(4)
	var/pushDir = pick(dirs - bad_dir)
	var/turf/T = get_step(src, pushDir)
	var/obj/effect/neoblob/B = locate() in T
	if(!B)
		if(prob(health))
			var/retry = expand(T)
			if(retry)
				pulse(forceLeft - 1, dirs, pushDir)
	else if(forceLeft)
		B.pulse(forceLeft - 1, dirs - get_dir(B, src))

/obj/effect/neoblob/proc/attack_msg(atom/source)
	var/datum/neoblob_type/current_strain = ensure_strain()
	if(current_strain)
		current_strain.attack_msg(src, source)

/obj/effect/neoblob/proc/attack_door(var/obj/structure/machinery/door/D)
	if(!D)
		return
	attack_msg(D)
	D.add_damage(rand(damage_min, damage_max))

/obj/effect/neoblob/proc/attack_living(var/mob/living/L)
	if(!L)
		return
	var/datum/neoblob_type/current_strain = ensure_strain()
	if(current_strain)
		current_strain.on_attack_living(src, L)

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
			var/datum/neoblob_type/current_strain = ensure_strain()
			var/product_type = current_strain ? current_strain.get_pruned_product(src) : product
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
	var/pulse_power = 50 // How far the core can potentially grow in size
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

// Rough icon state changes that reflect the core's health
/obj/effect/neoblob/core/update_icon()
	switch(get_health_percent())
		if(66 to INFINITY)
			icon_state = "blob_core"
		if(33 to 66)
			icon_state = "blob_node"
		if(-INFINITY to 33)
			icon_state = "blob_factory"
	apply_strain_apperance()

/obj/effect/neoblob/core/process()
	set waitfor = 0
	if(!may_process)
		return
	may_process = FALSE
	process_core_health()
	regen()
	var/datum/neoblob_type/current_strain = ensure_strain()
	if(current_strain)
		current_strain.on_core_process(src)
	for(var/i = 1 to times_to_pulse)
		pulse(pulse_power, GLOB.cardinals.Copy())
	may_process = TRUE
	if(world.time < (attack_time + attack_cooldown))
		return
	attempt_attack()

// Blob has a very small probability of growing these when spreading. These will spread the blob further.
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
	apply_strain_apperance()

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
	apply_strain_apperance()

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
			force = 15
			color = COLOR_BRONZE
			origin_tech = list(TECH_MATERIAL = 2, TECH_BIO = 2)
		if(TENDRIL_FIRE)
			desc = "A tendril removed from an astroclast. It's hot to the touch."
			damtype = DAMAGE_BURN
			force = 22
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
