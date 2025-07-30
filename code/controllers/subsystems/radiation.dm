SUBSYSTEM_DEF(radiation)
	name = "Radiation"
	wait = 0.5 SECONDS
	flags = SS_BACKGROUND | SS_NO_INIT

	/// A list of radiation sources (/datum/radiation_pulse_information) that have yet to process.
	/// Do not interact with this directly, use `radiation_pulse` instead.
	var/list/datum/radiation_pulse_information/processing = list()

	var/list/sources = list()			// all radiation source datums
	var/list/sources_assoc = list()		// Sources indexed by turf for de-duplication.
	var/list/resistance_cache = list()	// Cache of turf's radiation resistance.

	var/list/current_sources   = list()
	var/list/current_res_cache = list()
	var/list/listeners         = list()

/datum/controller/subsystem/radiation/fire(resumed = FALSE)
	if (!resumed)
		current_sources = sources.Copy()
		current_res_cache = resistance_cache.Copy()
		listeners = GLOB.living_mob_list.Copy()

	while(length(current_sources))
		var/datum/radiation_source/S = current_sources[length(current_sources)]
		LIST_DEC(current_sources)

		if(QDELETED(S))
			sources -= S
		else if(S.decay)
			S.update_rad_power(S.rad_power - RADIATION_DECAY_RATE)
		if (MC_TICK_CHECK)
			return

	while(length(current_res_cache))
		var/turf/T = current_res_cache[length(current_res_cache)]
		LIST_DEC(current_res_cache)

		if(QDELETED(T))
			resistance_cache -= T
		else if((length(T.contents) + 1) != resistance_cache[T])
			resistance_cache -= T // If its stale REMOVE it! It will get added if its needed.
		if (MC_TICK_CHECK)
			return

	if(!length(sources))
		listeners.Cut()

	while(length(listeners))
		var/atom/A = listeners[length(listeners)]
		LIST_DEC(listeners)

		if(!QDELETED(A))
			var/atom/location = A.loc
			var/rads = 0
			if(istype(location))
				rads = location.get_rads()
			if(rads)
				A.rad_act(rads)
		if (MC_TICK_CHECK)
			return

// Ray trace from all active radiation sources to T and return the strongest effect.
/datum/controller/subsystem/radiation/proc/get_rads_at_turf(turf/T)
	. = 0
	if(!istype(T))
		return

	for(var/value in sources)
		var/datum/radiation_source/source = value
		if(source.rad_power < .)
			continue // Already being affected by a stronger source
		if(source.source_turf.z != T.z)
			continue // Radiation is not multi-z
		if(source.respect_maint)
			var/area/A = T.loc
			if(A.area_flags & AREA_FLAG_RAD_SHIELDED)
				continue // In shielded area

		var/dist = get_dist(source.source_turf, T)
		if(dist > source.range)
			continue // Too far to possibly affect
		if(source.flat)
			. = max(., source.rad_power)
			continue // No need to ray trace for flat  field

		// Okay, now ray trace to find resistence!
		var/turf/origin = source.source_turf
		var/working = source.rad_power
		while(origin != T)
			origin = get_step_towards(origin, T) //Raytracing
			if(!resistance_cache[origin]) //Only get the resistance if we don't already know it.
				origin.calc_rad_resistance()
			if(origin.cached_rad_resistance)
				working = round((working / (origin.cached_rad_resistance * RADIATION_RESISTANCE_MULTIPLIER)), 0.1)
			if((working <= .) || (working <= RADIATION_THRESHOLD_CUTOFF))
				break // Already affected by a stronger source (or its zero...)
		. = max((working / (dist ** 2)), .) //Butchered version of the inverse square law. Works for this purpose
		if(. <= RADIATION_THRESHOLD_CUTOFF)
			. = 0

// Add a radiation source instance to the repository.  It will override any existing source on the same turf.
/datum/controller/subsystem/radiation/proc/add_source(datum/radiation_source/S)
	if(!isturf(S.source_turf))
		return
	var/datum/radiation_source/existing = sources_assoc[S.source_turf]
	if(existing)
		qdel(existing)
	sources += S
	sources_assoc[S.source_turf] = S

// Creates a temporary radiation source that will decay
/datum/controller/subsystem/radiation/proc/radiate(source, power) //Sends out a radiation pulse, taking walls into account
	if(!(source && power)) //Sanity checking
		return
	var/datum/radiation_source/S = new()
	S.source_turf = get_turf(source)
	S.update_rad_power(power)
	add_source(S)

// Sets the radiation in a range to a constant value.
/datum/controller/subsystem/radiation/proc/flat_radiate(source, power, range, respect_maint = FALSE)
	if(!(source && power && range))
		return
	var/datum/radiation_source/S = new()
	S.flat = TRUE
	S.range = range
	S.respect_maint = respect_maint
	S.source_turf = get_turf(source)
	S.update_rad_power(power)
	add_source(S)

// Irradiates a full Z-level. Hacky way of doing it, but not too expensive.
/datum/controller/subsystem/radiation/proc/z_radiate(atom/source, power, respect_maint = FALSE)
	if(!(power && source))
		return
	var/turf/epicentre = locate(round(world.maxx / 2), round(world.maxy / 2), source.z)
	flat_radiate(epicentre, power, world.maxx, respect_maint)

SUBSYSTEM_DEF(radiation)
	name = "Radiation"
	flags = SS_BACKGROUND | SS_NO_INIT

	wait = 0.5 SECONDS

	/// A list of radiation sources (/datum/radiation_pulse_information) that have yet to process.
	/// Do not interact with this directly, use `radiation_pulse` instead.
	var/list/datum/radiation_pulse_information/processing = list()

/datum/controller/subsystem/radiation/fire(resumed)
	while (processing.len)
		var/datum/radiation_pulse_information/pulse_information = processing[1]

		var/datum/weakref/source_ref = pulse_information.source_ref
		var/atom/source = source_ref.resolve()
		if (isnull(source))
			processing.Cut(1, 2)
			continue

		pulse(source, pulse_information)

		if (MC_TICK_CHECK)
			return

		processing.Cut(1, 2)

/datum/controller/subsystem/radiation/stat_entry(msg)
	msg = "[msg] | Pulses: [processing.len]"
	return ..()

/datum/controller/subsystem/radiation/proc/pulse(atom/source, datum/radiation_pulse_information/pulse_information)
	var/list/cached_rad_insulations = list()
	var/list/cached_turfs_to_process = pulse_information.turfs_to_process
	var/turfs_iterated = 0
	for (var/turf/turf_to_irradiate as anything in cached_turfs_to_process)
		turfs_iterated += 1
		for (var/atom/movable/target in turf_to_irradiate)
			if (!can_irradiate_basic(target))
				continue

			var/current_insulation = 1

			for (var/turf/turf_in_between in get_line(source, target) - get_turf(source))
				var/insulation = cached_rad_insulations[turf_in_between]
				if (isnull(insulation))
					insulation = turf_in_between.rad_insulation
					for (var/atom/on_turf as anything in turf_in_between.contents)
						insulation *= on_turf.rad_insulation
					cached_rad_insulations[turf_in_between] = insulation

				current_insulation *= insulation

				if (current_insulation <= pulse_information.threshold)
					break

			SEND_SIGNAL(target, COMSIG_IN_RANGE_OF_IRRADIATION, pulse_information, current_insulation)

			// Check a second time, because of TRAIT_BYPASS_EARLY_IRRADIATED_CHECK
			if (HAS_TRAIT(target, TRAIT_IRRADIATED))
				continue

			if (current_insulation <= pulse_information.threshold)
				continue

			/// Perceived chance of target getting irradiated.
			var/perceived_chance
			/// Intensity variable which will describe the radiation pulse.
			/// It is used by perceived intensity, which diminishes over range. The chance of the target getting irradiated is determined by perceived_intensity.
			/// Intensity is calculated so that the chance of getting irradiated at half of the max range is the same as the chance parameter.
			var/intensity
			/// Diminishes over range. Used by perceived chance, which is the actual chance to get irradiated.
			var/perceived_intensity

			if(pulse_information.chance < 100) // Prevents log(0) runtime if chance is 100%
				intensity = -log(1 - pulse_information.chance / 100) * (1 + pulse_information.max_range / 2) ** 2
				perceived_intensity = intensity * INVERSE((1 + get_dist_euclidean(source, target)) ** 2) // Diminishes over range.
				perceived_intensity *= (current_insulation - pulse_information.threshold) * INVERSE(1 - pulse_information.threshold) // Perceived intensity decreases as objects that absorb radiation block its trajectory.
				perceived_chance = 100 * (1 - NUM_E ** -perceived_intensity)
			else
				perceived_chance = 100

			var/irradiation_result = SEND_SIGNAL(target, COMSIG_IN_THRESHOLD_OF_IRRADIATION, pulse_information)
			if (irradiation_result & CANCEL_IRRADIATION)
				continue

			if (pulse_information.minimum_exposure_time && !(irradiation_result & SKIP_MINIMUM_EXPOSURE_TIME_CHECK))
				target.AddComponent(/datum/component/radiation_countdown, pulse_information.minimum_exposure_time)
				continue

			if (!prob(perceived_chance))
				continue

			if (irradiate_after_basic_checks(target))
				target.investigate_log("was irradiated by [source].", INVESTIGATE_RADIATION)

		if(MC_TICK_CHECK)
			break

	cached_turfs_to_process.Cut(1, turfs_iterated + 1)

/// Will attempt to irradiate the given target, limited through IC means, such as radiation protected clothing.
/datum/controller/subsystem/radiation/proc/irradiate(atom/target)
	if (!can_irradiate_basic(target))
		return FALSE

	irradiate_after_basic_checks(target)
	return TRUE

/datum/controller/subsystem/radiation/proc/irradiate_after_basic_checks(atom/target)
	PRIVATE_PROC(TRUE)

	if (ishuman(target) && wearing_rad_protected_clothing(target))
		return FALSE

	target.AddComponent(/datum/component/irradiated)
	return TRUE

/// Returns whether or not the target can be irradiated by any means.
/// Does not check for clothing.
/datum/controller/subsystem/radiation/proc/can_irradiate_basic(atom/target)
	if (!CAN_IRRADIATE(target))
		return FALSE

	if (HAS_TRAIT(target, TRAIT_IRRADIATED) && !HAS_TRAIT(target, TRAIT_BYPASS_EARLY_IRRADIATED_CHECK))
		return FALSE

	if (HAS_TRAIT(target, TRAIT_RADIMMUNE))
		return FALSE

	return TRUE

/// Returns whether or not the human is covered head to toe in rad-protected clothing.
/datum/controller/subsystem/radiation/proc/wearing_rad_protected_clothing(mob/living/carbon/human/human)
	for (var/obj/item/bodypart/limb as anything in human.bodyparts)
		var/protected = FALSE

		for (var/obj/item/clothing as anything in human.get_clothing_on_part(limb))
			if (HAS_TRAIT(clothing, TRAIT_RADIATION_PROTECTED_CLOTHING))
				protected = TRUE
				break

		if (!protected)
			return FALSE

	return TRUE
