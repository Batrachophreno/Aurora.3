#define COGBAR_ANIMATION_TIME (0.5 SECONDS)

/datum/cogbar
	/// The progress cog visual element.
	var/image/cog
	/// The target where this progress cog is applied and where it is shown.
	var/atom/cog_loc
	/// The mob who the progress cog appears over.
	var/mob/user
	/// Icon path of the cog.
	var/cogicon
	/// The icon state.
	var/cogiconstate
	/// Where to draw the progress cog above the user.
	var/offset_y

/datum/cogbar/New(mob/user, cogicon = 'icons/effects/fire.dmi', cogiconstate = "wavey_fire")
	to_chat(world,"running cogbar/New([user], [cogicon], [cogiconstate])")
	if(QDELETED(user) || !istype(user))
		stack_trace("/datum/cogbar created with [isnull(user) ? "null" : "invalid"] user")
		qdel(src)
		return
	src.user = user
	src.cogicon = cogicon
	src.cogiconstate = cogiconstate
	user.cogbar = src

	var/list/icon_offsets = user.get_oversized_icon_offsets()
	var/offset_x = icon_offsets["x"]
	offset_y = icon_offsets["y"]
	if(isnull(cogicon))
		stack_trace("/datum/cogbar was created with a null icon.")
		qdel(src)
		return
	if(isnull(cogiconstate))
		stack_trace("/datum/cogbar was created with a null icon state.")
		qdel(src)
		return

	cog = new(cogicon, user, cogiconstate, HUD_ABOVE_ITEM_LAYER, pixel_x = offset_x)
	// SET_PLANE_EXPLICIT(bar, ABOVE_HUD_PLANE, user)
	cog.plane = HUD_PLANE
	// cog.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA

	if(user)
		to_chat(world,"we have cog_loc [user]")
		cog.pixel_y = 0
		cog.alpha = 255
		animate(
			cog,
			pixel_y = world.icon_size + offset_y,
			alpha = 255,
			time = COGBAR_ANIMATION_TIME,
			easing = SINE_EASING
		)

	RegisterSignal(user, COMSIG_QDELETING, PROC_REF(on_user_delete))

	to_chat(world,"got to the end of New()")
	to_chat(world,"user [user] cogbar is [user.cogbar]")

/datum/cogbar/Destroy()
	to_chat(world,"running Destroy()")
	if(user && user.cogbar)
		user.cogbar = null
		user = null
	cog_loc = null
	cog = null

	return ..()

/// Called right before the user's Destroy()
/datum/cogbar/proc/on_user_delete(datum/source)
	to_chat(world,"running on_user_delete([source])")
	SIGNAL_HANDLER
	user.cogbar = null
	user = null
	qdel(src)

/// Called when all progbars are exhausted, be they successful or a failure. Wraps up things to delete the datum and cog.
/datum/cogbar/proc/end_progress()
	to_chat(world,"running end_progress()")
	animate(cog, alpha = 0, time = COGBAR_ANIMATION_TIME)

	QDEL_IN(src, COGBAR_ANIMATION_TIME)

#undef COGBAR_ANIMATION_TIME

