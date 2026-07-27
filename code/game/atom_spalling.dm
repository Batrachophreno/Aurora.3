/**
 * Returns TRUE if this atom can emit spalling after something forcefully pierces through it.
 */
/atom/proc/can_generate_spalling(atom/source)
	return FALSE

/**
 * Returns the projectile type emitted when this atom spalls.
 */
/atom/proc/get_spalling_projectile_type(atom/source)
	return /obj/projectile/bullet/pellet/fragment/spall

/**
 * Emits a cone of shrapnel from this atom. Called by ship projectiles or any other source
 * that decides the atom was pierced/hit hard enough to spall.
 *
 * Params:
 * * shrapnel_dir: mandatory. Dir bitflag that we try to throw spalling out from.
 * * source: The projectile that caused the spalling; mostly for flavor text.
 * * emits_from: The turf we spawn our new spalling fragment projectiles from. Generally can be derived if one is not passed.
 * * message: Sends the default spalling message; set to FALSE if you want to handle messaging elsewhere.
 */
/atom/proc/emit_spalling(shrapnel_dir = null, atom/source = null, turf/emits_from = null, message = TRUE)
	set waitfor = FALSE

	if(!shrapnel_dir)
		return FALSE
	if(!emits_from && source)
		emits_from = get_turf(source)
	if(!emits_from)
		var/turf/source_turf = get_turf(src)
		if(source_turf)
			emits_from = get_step(source_turf, shrapnel_dir)
			if(!emits_from)
				emits_from = source_turf
	if(!emits_from)
		return FALSE

	var/spalling_projectile_type = get_spalling_projectile_type(source)
	if(!spalling_projectile_type)
		return FALSE

	var/atom/launch_source = emits_from
	if(source && get_turf(source) == emits_from)
		launch_source = source
	else if(!source && get_turf(src) == emits_from)
		launch_source = src

	if(message)
		if(source)
			launch_source.visible_message(SPAN_DANGER("Huge chunks of shrapnel spray out from \the [src] as \the [source] punches through!"))
		else
			launch_source.visible_message(SPAN_DANGER("Huge chunks of shrapnel spray out from \the [src]!"))

	var/list/target_turfs = list()
	target_turfs += get_step(emits_from, shrapnel_dir)
	target_turfs += get_step(emits_from, turn(shrapnel_dir, -45))
	target_turfs += get_step(emits_from, turn(shrapnel_dir, 45))
	target_turfs += get_step(get_step(emits_from, turn(shrapnel_dir, -45)), shrapnel_dir)
	target_turfs += get_step(get_step(emits_from, turn(shrapnel_dir, 45)), shrapnel_dir)

	var/atom/movable/movable_source
	if(ismovable(source))
		movable_source = source

	for(var/turf/T in target_turfs)
		var/obj/projectile/bullet/pellet/fragment/spall/P = new spalling_projectile_type(emits_from)
		P.preparePixelProjectile(T, launch_source)
		P.firer = movable_source
		P.fired_from = src
		P.fire()
	return TRUE

/turf/simulated/wall/can_generate_spalling(atom/source)
	return TRUE

/obj/structure/can_generate_spalling(atom/source)
	if(!should_use_health)
		return FALSE
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	return T.check_density(FALSE, TRUE)

/obj/structure/window/get_spalling_projectile_type(atom/source)
	return /obj/projectile/bullet/pellet/fragment/spall/glass

/obj/structure/grille/get_spalling_projectile_type(atom/source)
	return /obj/projectile/bullet/pellet/fragment/spall/metalrod

/obj/structure/window_frame/get_spalling_projectile_type(atom/source)
	return /obj/projectile/bullet/pellet/fragment/spall/metalrod

/obj/structure/machinery/door/can_generate_spalling(atom/source)
	return TRUE

/obj/structure/machinery/door/airlock/get_spalling_projectile_type(atom/source)
	if(window_material && window_material == GET_SINGLETON(MATERIAL_GLASS))
		return /obj/projectile/bullet/pellet/fragment/spall/glass
	return ..()
