// Access check is of the type "req_one_access".
// These have been carefully selected to avoid allowing anyone with generic departmental access to see channels they should not.
var/global/list/default_internal_channels = list(
	num2text(PUB_FREQ) = list(),
	num2text(ENT_FREQ) = list(),
	num2text(EXP_FREQ) = list(),
	num2text(AI_FREQ)  = list(ACCESS_EQUIPMENT),
	num2text(ERT_FREQ) = list(ACCESS_CENT_SPECOPS),
	num2text(COMM_FREQ)= list(ACCESS_HEADS),
	num2text(ENG_FREQ) = list(ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS),
	num2text(MED_FREQ) = list(ACCESS_MEDICAL_EQUIP),
	num2text(MED_I_FREQ)=list(ACCESS_MEDICAL_EQUIP),
	num2text(SEC_FREQ) = list(ACCESS_SECURITY),
	num2text(SEC_I_FREQ)=list(ACCESS_SECURITY),
	num2text(PEN_FREQ) = list(ACCESS_ARMORY),
	num2text(SCI_FREQ) = list(ACCESS_TOX,ACCESS_ROBOTICS,ACCESS_XENOBIOLOGY,ACCESS_XENOBOTANY),
	num2text(SUP_FREQ) = list(ACCESS_CARGO),
	num2text(SRV_FREQ) = list(ACCESS_JANITOR, ACCESS_HYDROPONICS)
)

var/global/list/default_medbay_channels = list(
	num2text(PUB_FREQ) = list(),
	num2text(MED_FREQ) = list(ACCESS_MEDICAL_EQUIP),
	num2text(MED_I_FREQ) = list(ACCESS_MEDICAL_EQUIP)
)

var/global/list/default_expedition_channels = list(
	num2text(PUB_FREQ) = list(),
	num2text(EXP_FREQ) = list(),
	num2text(HAIL_FREQ) = list()
)

var/global/list/default_interrogation_channels = list(
	num2text(INT_FREQ) = list()
)

//
// Radios
//

/obj/item/radio
	name = "shortwave radio"
	icon = 'icons/obj/radio.dmi'
	icon_state = "walkietalkie"
	item_state = "radio"
	obj_flags = OBJ_FLAG_CONDUCTABLE
	slot_flags = SLOT_BELT
	throw_speed = 2
	throw_range = 9
	w_class = WEIGHT_CLASS_SMALL
	matter = list(MATERIAL_ALUMINIUM = 75, MATERIAL_GLASS = 25)
	suffix = "\[3\]"
	var/radio_desc = ""
	var/const/FREQ_LISTENING = TRUE
	/// Automatically set on initialize, only update if bypass_default_internal is set to TRUE
	var/list/internal_channels
	/// played sound on usage
	var/clicksound = SFX_BUTTON
	/// volume of clicksound
	var/clickvol = 10

	var/obj/item/cell/cell = /obj/item/cell/device
	var/last_radio_sound = -INFINITY

	/// If FALSE, broadcasting and listening don't matter and this radio does nothing
	VAR_PRIVATE/on = TRUE

	/// Current frequency the radio is set to
	VAR_PRIVATE/frequency = PUB_FREQ
	/// frequency the radio defaults to on reset / startup
	var/default_frequency = PUB_FREQ

	/// Whether the radio transmits dialogue it hears nearby onto its radio channel
	VAR_PRIVATE/broadcasting = FALSE
	/// Whether the radio is currently receiving radio messages from its frequencies
	VAR_PRIVATE/listening = TRUE

	//the below vars are used to track listening and broadcasting should they be forced off for whatever reason but "supposed" to be active
	//eg player sets the radio to listening, but an emp or whatever turns it off, its still supposed to be activated but was forced off,
	//when it wears off it sets listening to should_be_listening

	/// used for tracking what broadcasting should be in the absence of things forcing it off, eg its set to broadcast but gets emp'd temporarily
	var/should_be_broadcasting = FALSE
	/// used for tracking what listening should be in the absence of things forcing it off, eg its set to listen but gets emp'd temporarily
	var/should_be_listening = TRUE

	/// Both the range around the radio in which mobs can hear what it receives and the range the radio can hear
	var/canhear_range = 3

	var/last_transmission
	/// tune to frequency to unlock traitor supplies
	var/traitor_frequency = 0
	/// used in autosay, held by the radio for re-use
	var/mob/living/announcer/announcer = null
	var/datum/wires/radio/wires = null
	/// Whether wires are accessible. Toggleable by screwdrivering.
	var/unscrewed = FALSE
	/// If true, the radio has access to the full spectrum.
	var/freerange = FALSE

	/// associative list of the encrypted radio channels this radio is currently set to listen/broadcast to, of the form: list(channel name = TRUE or FALSE)
	var/list/channels
	/// Current encryption key in first slot
	var/obj/item/encryptionkey/keyslot_1 = null
	/// Current encryption key in second slot
	var/obj/item/encryptionkey/keyslot_2 = null
	/// Obj path of an encryption key to spawn into this radio on Initialize().
	var/ks1type = /obj/item/encryptionkey
	/// Obj path of an encryption key to spawn into this radio on Initialize().
	var/ks2type = null

	var/translate_binary = FALSE
	var/translate_hivenet = FALSE

	/// This variable effectively shortcircuits the encryption key behavior. If TRUE, the radio will ignore keyslot behavior and will attempt to read the UI user's ID and access rights to provision channels dynamically.
	/// This is the behavior of the Horizon's shortwave radios. These are mapped across all depts on the Horizon and will remain as-is. In the future, should we choose, we can make the change to have shortwaves work on keyslots like headsets.
	var/provision_channels_based_on_id_access = TRUE

	/// Flags for which "special" (antag) radio networks should be accessible
	var/special_channels = NONE
	/// lazy associative list of the encrypted radio channels this radio can listen/broadcast to, of the form: list(channel name = channel frequency)
	var/list/datum/radio_frequency/secure_radio_connections = list()
	var/datum/radio_frequency/radio_connection

	var/subspace_transmission = FALSE
	/// Holder to see if it's a syndicate encrypted radio
	var/syndie = FALSE
	/// if TRUE, can say/hear on the Special Channel!!! (TBD)
	var/independent = FALSE

	/// Frequency lock to stop the user from untuning specialist radios.
	var/freqlock = RADIO_FREQENCY_UNLOCKED
	/// If true, broadcasts will be large and BOLD.
	var/use_command = FALSE
	/// If true, use_command can be toggled at will.
	var/command = FALSE

/obj/item/radio/feedback_hints(mob/user, distance, is_adjacent)
	. += ..()
	if(radio_desc)
		. += radio_desc

/obj/item/radio/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "The radio key .i will allow you to speak into a nearby intercom, .r will speak into a radio in your right hand, and .l will speak into your left. The microphone does not need to be enabled for this to work."

/obj/item/radio/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	if(new_frequency)
		frequency = new_frequency
		radio_connection = SSradio.add_object(src, new_frequency, RADIO_CHAT)

/// By default copies default_internal_channels. Override on child for radios that need snowflake.
/obj/item/radio/proc/set_internal_channels()
	return default_internal_channels.Copy()

/obj/item/radio/Initialize()
	. = ..()

	wires = new(src)

	if(provision_channels_based_on_id_access)
		internal_channels = set_internal_channels()
	else
		internal_channels.Cut()
		if(ks1type)
			keyslot_1 = new ks1type(src)
		if(ks2type)
			keyslot_2 = new ks2type(src)
		recalculateChannels(TRUE)

	if(frequency < RADIO_LOW_FREQ || frequency > RADIO_HIGH_FREQ)
		frequency = sanitize_frequency(frequency)

	for (var/ch_name in channels)
		secure_radio_connections[ch_name] = SSradio.add_object(src, radiochannels[ch_name],  RADIO_CHAT)

	set_listening(listening)
	set_broadcasting(broadcasting)
	set_frequency(default_frequency)
	set_on(on)

/obj/item/radio/Destroy()
	SSradio.remove_object_all(src)
	QDEL_NULL(keyslot_1)
	QDEL_NULL(keyslot_2)
	QDEL_NULL(announcer)
	QDEL_NULL(wires)
	return ..()

/obj/item/radio/proc/is_on()
	return on

/obj/item/radio/proc/get_frequency()
	return frequency

/obj/item/radio/proc/get_broadcasting()
	return broadcasting

/obj/item/radio/proc/get_listening()
	return listening

/**
 * setter for the listener var, adds or removes this radio from the global radio list if we are also on
 *
 * * new_listening - the new value we want to set listening to
 * * actual_setting - whether or not the radio is supposed to be listening, sets should_be_listening to the new listening value if true, otherwise just changes listening
 */
/obj/item/radio/proc/set_listening(new_listening, actual_setting = TRUE)

	listening = new_listening
	if(actual_setting)
		should_be_listening = listening

	if(listening && on)
		for(var/channel_name in channels)
			if(channels[channel_name])
				secure_radio_connections[channel_name] = SSradio.add_object(src, radiochannels[channel_name], RADIO_CHAT)
		radio_connection = SSradio.add_object(src, frequency, RADIO_CHAT)
	else if(!listening)
		SSradio.remove_object_all(src)
		radio_connection = null

/**
 * setter for broadcasting that makes us not hearing sensitive if not broadcasting and hearing sensitive if broadcasting
 * hearing sensitive in this case only matters for the purposes of listening for words said in nearby tiles, talking into us directly bypasses hearing
 *
 * * new_broadcasting- the new value we want to set broadcasting to
 * * actual_setting - whether or not the radio is supposed to be broadcasting, sets should_be_broadcasting to the new value if true, otherwise just changes broadcasting
 */
/obj/item/radio/proc/set_broadcasting(new_broadcasting, actual_setting = TRUE)

	broadcasting = new_broadcasting
	if(actual_setting)
		should_be_broadcasting = broadcasting

	if(broadcasting && on) //we dont need hearing sensitivity if we arent broadcasting, because talk_into doesnt care about hearing
		become_hearing_sensitive(INNATE_TRAIT)
	else if(!broadcasting)
		lose_hearing_sensitivity(INNATE_TRAIT)

///setter for the on var that sets both broadcasting and listening to off or whatever they were supposed to be
/obj/item/radio/proc/set_on(new_on)

	on = new_on

	if(on)
		set_broadcasting(should_be_broadcasting)//set them to whatever theyre supposed to be
		set_listening(should_be_listening)
	else
		set_broadcasting(FALSE, actual_setting = FALSE)//fake set them to off
		set_listening(FALSE, actual_setting = FALSE)

/obj/item/radio/attack_self(mob/user as mob)
	if(unscrewed && !provision_channels_based_on_id_access)
		if(keyslot_1 || keyslot_2)
			for(var/ch_name in channels)
				SSradio.remove_object(src, radiochannels[ch_name])
				secure_radio_connections[ch_name] = null

			if(keyslot_1)
				var/turf/T = get_turf(user)
				if(T)
					keyslot_1.forceMove(T)
					keyslot_1 = null

			if(keyslot_2)
				var/turf/T = get_turf(user)
				if(T)
					keyslot_2.forceMove(T)
					keyslot_2 = null

			recalculateChannels(TRUE)
			to_chat(user, SPAN_NOTICE("You pop out the encryption keys in the radio!"))
		else
			to_chat(user, SPAN_WARNING("This radio doesn't have any encryption keys!"))
	else
		interact(user)

/obj/item/radio/interact(mob/user)
	if(!user)
		return 0

	if(unscrewed)
		wires.interact(user)

	return ui_interact(user)

/obj/item/radio/ui_interact(mob/user, datum/tgui/ui, datum/ui_state/state)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Radio", name)
		if(state)
			ui.set_state(state)
		ui.open()

/obj/item/radio/ui_data(mob/user)
	var/list/data = list()

	data["mic_status"] = broadcasting
	data["speaker"] = listening
	data["frequency"] = format_frequency(frequency)
	data["default_freq"] = format_frequency(default_frequency)
	data["rawfreq"] = num2text(frequency)


	data["frequency"] = frequency
	data["broadcasting"] = broadcasting
	data["listening"] = listening
	data["minFrequency"] = PUBLIC_LOW_FREQ
	data["maxFrequency"] = PUBLIC_HIGH_FREQ
	data["freqlock"] = freqlock != RADIO_FREQENCY_UNLOCKED
	data["channels"] = list()
	for(var/channel in channels)
		data["channels"][channel] = channels[channel] & FREQ_LISTENING
	data["command"] = command
	data["useCommand"] = use_command
	data["subspace"] = subspace_transmission
	data["mic_cut"] = (wires.is_cut(WIRE_TRANSMIT) || wires.is_cut(WIRE_SIGNAL))
	data["spk_cut"] = (wires.is_cut(WIRE_RECEIVE) || wires.is_cut(WIRE_SIGNAL))

	return data

/obj/item/radio/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user

	if(clicksound && iscarbon(user))
		playsound(loc, clicksound, clickvol)

	switch(action)
		if("frequency")
			if(freqlock != RADIO_FREQENCY_UNLOCKED)
				return
			var/tune = 0
			var/adjust = text2num(params["adjust"])
			if(adjust)
				tune = frequency + adjust * 10
			else if(tune)
				tune *= 10
			if(tune)
				set_frequency(sanitize_frequency(tune))
			. = TRUE

		if("tune_to_channel")
			if(freqlock != RADIO_FREQENCY_UNLOCKED)
				return
			var/channel = params["channel"]
			if(!(channel in channels))
				return
			// bypasses frequency range, force tunes to a specific encrypted channel
			set_frequency(default_frequency)
			. = TRUE

		if("listen")
			set_listening(!listening)
			. = TRUE
		if("broadcast")
			set_broadcasting(!broadcasting)
			. = TRUE
		if("channel")
			var/channel = params["channel"]
			if(!(channel in channels))
				return
			if(channels[channel] & FREQ_LISTENING)
				channels[channel] &= ~FREQ_LISTENING
			else
				channels[channel] |= FREQ_LISTENING
			. = TRUE

/obj/item/radio/Topic(href, href_list)
	if(..())
		return TRUE

	usr.set_machine(src)
	if (href_list["track"])
		var/mob/target = locate(href_list["track"])
		var/mob/living/silicon/ai/A = locate(href_list["track2"])
		if(A && target)
			A.ai_actual_track(target)
		. = TRUE

	else if (href_list["freq"])
		var/new_frequency = (frequency + text2num(href_list["freq"]))
		if ((new_frequency < PUBLIC_LOW_FREQ || new_frequency > PUBLIC_HIGH_FREQ))
			new_frequency = sanitize_frequency(new_frequency)
		set_frequency(new_frequency)
		if(hidden_uplink)
			if(hidden_uplink.check_trigger(usr, frequency, traitor_frequency))
				usr << browse(null, "window=radio")
		. = TRUE
	else if (href_list["talk"])
		set_broadcasting(!broadcasting)
		. = TRUE
	else if (href_list["listen"])
		var/chan_name = href_list["ch_name"]
		if (!chan_name)
			set_listening(!listening)
		else
			if (channels[chan_name] & FREQ_LISTENING)
				channels[chan_name] &= ~FREQ_LISTENING
			else
				channels[chan_name] |= FREQ_LISTENING
		. = TRUE
	else if(href_list["spec_freq"])
		var freq = href_list["spec_freq"]
		if(has_channel_access(usr, freq))
			set_frequency(text2num(freq))
		. = TRUE
	else if(href_list["reset_freq"])
		if(default_frequency)
			set_frequency(default_frequency)
			. = TRUE

	if(href_list["nowindow"]) // here for pAIs, maybe others will want it, idk
		return TRUE

	if(.)
		SSnanoui.update_uis(src)
		update_icon()

/obj/item/radio/proc/setupRadioDescription(var/additional_radio_desc)
	var/radio_text = ""
	var/found_first_department = FALSE
	for(var/i = 1 to channels.len)
		var/channel = channels[i]
		var/key = get_radio_key_from_channel(channel)
		if(!length(key) && !found_first_department && channel != CHANNEL_COMMON && channel != CHANNEL_ENTERTAINMENT)
			// if we don't have a key and it's the 'shortcut' channel, put the department key instead
			key = get_radio_key_from_channel("department")
			found_first_department = TRUE

		radio_text += "[key] - [channel]"
		if(i != channels.len)
			radio_text += ", "

	radio_desc = radio_text
	if(additional_radio_desc)
		radio_desc += additional_radio_desc

/obj/item/radio/proc/list_channels(var/mob/user)
	return list_internal_channels(user)

/obj/item/radio/proc/list_secure_channels(var/mob/user)
	var/dat[0]

	for(var/ch_name in channels)
		var/chan_stat = channels[ch_name]
		var/listening = !!(chan_stat & FREQ_LISTENING) != 0

		dat.Add(list(list("chan" = ch_name, "display_name" = ch_name, "secure_channel" = 1, "sec_channel_listen" = !listening, "chan_span" = frequency_span_class(radiochannels[ch_name]))))

	return dat

/obj/item/radio/proc/list_internal_channels(var/mob/user)
	var/dat[0]
	for(var/internal_chan in internal_channels)
		if(has_channel_access(user, internal_chan))
			dat.Add(list(list("chan" = internal_chan, "display_name" = get_frequency_name(text2num(internal_chan)), "chan_span" = frequency_span_class(text2num(internal_chan)))))

	return dat

/obj/item/radio/proc/has_channel_access(var/mob/user, var/freq)
	if(!user)
		return 0

	if(!(freq in internal_channels))
		return 0

	return user.has_internal_radio_channel_access(internal_channels[freq])

/mob/proc/has_internal_radio_channel_access(var/list/req_one_accesses)
	var/obj/item/card/id/I = GetIdCard()
	return has_access(list(), req_one_accesses, I ? I.GetAccess() : list())

/mob/abstract/ghost/observer/has_internal_radio_channel_access(var/list/req_one_accesses)
	return can_admin_interact()

/obj/item/radio/proc/autosay(var/message, var/from, var/channel) //BS12 EDIT
	var/datum/radio_frequency/connection = null
	if(channel && channels && channels.len > 0)
		if(channel == "department")
			for(var/freq in channels)
				if(freq == "Common" || freq == "Entertainment" || freq == "Expeditionary")
					continue
				channel = freq
				break
			if(channel == "department") // didn't find one, use first one
				channel = channels[1]
		connection = secure_radio_connections[channel]
	else
		connection = radio_connection
		channel = null

	if (!istype(connection))
		return

	if(!istype(announcer))
		announcer = new()

	announcer.PrepareBroadcast(from)
	var/datum/weakref/speaker_weakref = WEAKREF(announcer)
	var/datum/signal/subspace/vocal/signal = new(src, connection.frequency, speaker_weakref, announcer.default_language, message, "states")
	signal.send_to_receivers()
	announcer.ResetAfterBroadcast()

// Interprets the message mode when talking into a radio, possibly returning a connection datum
/obj/item/radio/proc/handle_message_mode(mob/living/M as mob, message, message_mode)
	// If a channel isn't specified, send to common.
	if(!message_mode || message_mode == "headset")
		return radio_connection

	// Otherwise, if a channel is specified, look for it.
	if(channels && channels.len > 0)
		if(message_mode == "department") // Department radio shortcut
			for(var/freq in channels)
				if(freq == "Common" || freq == "Entertainment" || freq == "Expeditionary")
					continue
				message_mode = freq
				break
			if(message_mode == "department") // didn't find one, use first one
				message_mode = channels[1]
		if (channels[message_mode]) // only broadcast if the channel is set on
			return secure_radio_connections[message_mode]

	// If we were to send to a channel we don't have, drop it.
	return null

/obj/item/radio/talk_into(mob/living/M, message, channel, var/say_verb = "says", var/datum/language/speaking = null, var/ignore_restrained)
	if(!on)
		return FALSE
	if(!M || !message)
		return FALSE
	if(wires.is_cut(WIRE_TRANSMIT)) // The device has to have all its wires and shit intact
		return FALSE

	if (iscarbon(M))
		var/mob/living/carbon/C = M
		if ((CE_UNDEXTROUS in C.chem_effects) || C.stunned >= 10)
			to_chat(M, SPAN_WARNING("You can't move your arms enough to activate the radio..."))
			return
		if(iszombie(M))
			to_chat(M, SPAN_WARNING("Try as you might, you cannot will your decaying body into operating \the [src]."))
			return FALSE

	if(istype(M))
		if(M.restrained() && !ignore_restrained)
			to_chat(M, SPAN_WARNING("You can't speak into \the [src.name] while restrained."))
			return FALSE
		M.trigger_aiming(TARGET_CAN_RADIO)

	if(!radio_connection)
		set_frequency(frequency)

	if(loc == M)
		playsound(loc, 'sound/effects/walkietalkie.ogg', 5, 0, -1, required_asfx_toggles = ASFX_RADIO)

	/*
		Roughly speaking, radios attempt to make a subspace transmission (which
		is received, processed, and rebroadcast by the telecomms satellite) and
		if that fails, they send a mundane radio transmission.
		Headsets cannot send/receive mundane transmissions, only subspace.
		Syndicate radios can hear transmissions on all well-known frequencies.
		CentCom radios can hear the CentCom frequency no matter what.
	*/

	// Get the frequency
	var/datum/radio_frequency/connection = handle_message_mode(M, message, channel)
	if (!istype(connection))
		return FALSE

	// Determine the identify information attached to the signal
	var/datum/weakref/speaker_weakref = WEAKREF(M)
	var/datum/signal/subspace/vocal/signal = new(src, connection.frequency, speaker_weakref, speaking, message, say_verb)

	// All radios attempt to use the subspace system
	. = signal.send_to_receivers()

	// If it's subspace only, that's all we can do
	if(subspace_transmission)
		return

	// Non-subspace radios will check in a couple of seconds, and if the signal was never received, we send a mundane broadcast
	addtimer(CALLBACK(src, PROC_REF(backup_transmission), signal), 2 SECONDS)

/obj/item/radio/proc/backup_transmission(datum/signal/subspace/vocal/signal)
	var/turf/T = get_turf(src)
	if (signal.data["done"] && (T.z in signal.levels))
		return

	// If we're here, the signal was never processed. Proceed with mundane broadcast:
	signal.data["compression"] = 0
	signal.transmission_method = TRANSMISSION_RADIO
	signal.levels = GetConnectedZlevels(T.z)
	signal.broadcast()

/obj/item/radio/hear_talk(mob/M as mob, msg, var/verb = "says", var/datum/language/speaking = null)
	if (!broadcasting || get_dist(src, M) > canhear_range)
		return

	return talk_into(M, msg, null, verb, speaking, ignore_restrained = TRUE)

/obj/item/radio/proc/can_receive(input_frequency, list/levels)
	// check if the radio can receive on the given frequency
	if (!listening)
		return

	if (levels != RADIO_NO_Z_LEVEL_RESTRICTION)
		var/turf/position = get_turf(src)
		if (!position || !(position.z in levels))
			return FALSE

	if (within_jamming_range(src))
		return FALSE

	if ((input_frequency in ANTAG_FREQS) && !syndie) //Checks to see if it's allowed on that frequency, based on the encryption keys
		return FALSE

	for (var/ch_name in channels)
		var/datum/radio_frequency/RF = secure_radio_connections[ch_name]
		if (RF.frequency == input_frequency)
			return channels[ch_name]

	if (input_frequency == frequency)
		return TRUE

	return FALSE

/obj/item/radio/proc/send_hear(freq, level)
	if(!can_receive(freq, level))
		return

	return get_hearers_in_view(canhear_range, src)

/obj/item/radio/attackby(obj/item/attacking_item, mob/user)
	..()
	/// Beacons only use screwdriver attackby to anchor/unanchor them to turfs.
	if(istype(src, /obj/item/radio/beacon))
		return
	// Handle opening/closing maint panel
	if(attacking_item.tool_behaviour == TOOL_SCREWDRIVER)
		to_chat(user, SPAN_NOTICE("You [unscrewed ? "screw shut" : "unscrew"] the service panel of \the [src]"))
		unscrewed = !unscrewed
		return
	// Handle encryption key insertion
	if(unscrewed && istype(attacking_item, /obj/item/encryptionkey))
		if(keyslot_1 && keyslot_2)
			to_chat(user, SPAN_WARNING("The headset can't hold another key!"))
			return
		if(!keyslot_1)
			user.drop_from_inventory(attacking_item, src)
			keyslot_1 = attacking_item
		else
			user.drop_from_inventory(attacking_item, src)
			keyslot_2 = attacking_item
		recalculateChannels(TRUE)

/obj/item/radio/proc/recalculateChannels(var/setDescription = FALSE)
	var/list/old_channel_settings = channels.Copy()
	channels = list()
	translate_binary = FALSE
	translate_hivenet = FALSE
	syndie = FALSE

	SSradio.remove_object_all(src)

	for(var/keyslot in list(keyslot_1, keyslot_2))
		if(!keyslot)
			continue
		var/obj/item/encryptionkey/K = keyslot

		for(var/ch_name in K.channels)
			if(ch_name in channels)
				continue
			LAZYSET(channels, ch_name, K.channels[ch_name])

		for(var/ch_name in K.additional_channels)
			if(ch_name in channels)
				continue
			LAZYSET(channels, ch_name, K.additional_channels[ch_name])

		if(K.translate_binary)
			translate_binary = TRUE

		if(K.translate_hivenet)
			translate_hivenet = TRUE

		if(K.syndie)
			syndie = TRUE

		if(K.independent)
			independent = TRUE

	for (var/ch_name in channels)
		if(ch_name in old_channel_settings)
			channels[ch_name] = old_channel_settings[ch_name]
		secure_radio_connections[ch_name] = SSradio.add_object(src, radiochannels[ch_name], RADIO_CHAT)

	if(setDescription)
		setupRadioDescription()

	return

/obj/item/radio/emp_act(severity)
	. = ..()

	set_broadcasting(FALSE)
	set_listening(FALSE)
	for (var/ch_name in channels)
		channels[ch_name] = 0

//
// Vesselbound Synthetic Radio
//

/obj/item/radio/borg
	var/mob/living/silicon/robot/myborg = null // Cyborg which owns this radio. Used for power checks
	var/shut_up = 1
	icon = 'icons/obj/robot_component.dmi' // Cyborgs radio icons should look like the component.
	icon_state = "radio"
	canhear_range = 0
	subspace_transmission = 1
	name = "integrated radio"
	var/radio_sound = null

/obj/item/radio/borg/Destroy()
	myborg = null
	. = ..()
	GC_TEMPORARY_HARDDEL

/obj/item/radio/borg/list_channels(var/mob/user)
	return list_secure_channels(user)

/obj/item/radio/borg/talk_into(mob/living/M, message, channel, verb, datum/language/speaking, var/ignore_restrained)
	. = ..()
	if (isrobot(src.loc))
		var/mob/living/silicon/robot/R = src.loc
		var/datum/robot_component/C = R.components["radio"]
		R.cell_use_power(C.active_usage)

/obj/item/radio/borg/Topic(href, href_list)
	if(..())
		return 1
	if (href_list["mode"])
		var/enable_subspace_transmission = text2num(href_list["mode"])
		if(enable_subspace_transmission != subspace_transmission)
			subspace_transmission = !subspace_transmission
			if(subspace_transmission)
				to_chat(usr, SPAN_NOTICE("Subspace Transmission is enabled"))
			else
				to_chat(usr, SPAN_NOTICE("Subspace Transmission is disabled"))

			if(subspace_transmission == 0)//Simple as fuck, clears the channel list to prevent talking/listening over them if subspace transmission is disabled
				channels = list()
			else
				recalculateChannels()
		. = 1
	if (href_list["shutup"]) // Toggle loudspeaker mode, AKA everyone around you hearing your radio.
		var/do_shut_up = text2num(href_list["shutup"])
		if(do_shut_up != shut_up)
			shut_up = !shut_up
			if(shut_up)
				canhear_range = 0
				to_chat(usr, SPAN_NOTICE("Loadspeaker disabled."))
			else
				canhear_range = 3
				to_chat(usr, SPAN_NOTICE("Loadspeaker enabled."))
		. = 1

	if(.)
		SSnanoui.update_uis(src)

/obj/item/radio/borg/interact(mob/user as mob)
	if(!on)
		return

	. = ..()

/obj/item/radio/borg/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/data[0]

	data["mic_status"] = broadcasting
	data["speaker"] = listening
	data["freq"] = format_frequency(frequency)
	data["default_freq"] = format_frequency(default_frequency)
	data["rawfreq"] = num2text(frequency)

	var/list/chanlist = list_channels(user)
	if(islist(chanlist) && chanlist.len)
		data["chan_list"] = chanlist
		data["chan_list_len"] = chanlist.len

	if(syndie)
		data["useSyndMode"] = 1

	data["has_loudspeaker"] = 1
	data["loudspeaker"] = !shut_up
	data["has_subspace"] = 1
	data["subspace"] = subspace_transmission

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "radio_basic.tmpl", "[name]", 400, 430)
		ui.set_initial_data(data)
		ui.open()

/obj/item/radio/proc/config(op)
	if(SSradio)
		for (var/ch_name in channels)
			SSradio.remove_object(src, radiochannels[ch_name])
	secure_radio_connections = list()
	channels = op
	if(SSradio)
		for (var/ch_name in op)
			secure_radio_connections[ch_name] = SSradio.add_object(src, radiochannels[ch_name],  RADIO_CHAT)
	return

//
// Radio Variants
//

/obj/item/radio/map_preset
	channels = list()

/obj/item/radio/map_preset/Initialize()
	if(!SSatlas.current_map.use_overmap)
		return ..()

	var/turf/T = get_turf(src)
	var/obj/effect/overmap/visitable/V = GLOB.map_sectors["[T.z]"]
	if(istype(V) && V.comms_support)
		var/freq_name = V.name
		if(V.freq_name)
			freq_name = V.freq_name
		frequency = assign_away_freq(freq_name)
		default_frequency = frequency
		channels += list(
			freq_name = TRUE,
			CHANNEL_HAILING = TRUE
		)
		if(V.comms_name)
			name = "[V.comms_name] shortwave radio"

	return ..()

/obj/item/radio/map_preset/set_internal_channels()
	return list(
		num2text(default_frequency) = list(),
		num2text(HAIL_FREQ) = list()
	)

/obj/item/radio/hailing
	default_frequency = HAIL_FREQ

/obj/item/radio/hailing/set_internal_channels()
	return list(
		num2text(HAIL_FREQ) = list()
	)

/obj/item/radio/hailing/Initialize()
	channels = list(
		CHANNEL_HAILING = TRUE
	)
	return ..()

// Radio (Off)
/obj/item/radio/off/Initialize()
	. = ..()
	set_listening(FALSE)

// Medical
/obj/item/radio/med
	icon_state = "walkietalkie-med"

// Medical (Off)
/obj/item/radio/med/off/Initialize()
	. = ..()
	set_listening(FALSE)

// Security
/obj/item/radio/sec
	icon_state = "walkietalkie-sec"

// Security (Off)
/obj/item/radio/sec/off/Initialize()
	. = ..()
	set_listening(FALSE)

// Engineering
/obj/item/radio/eng
	icon_state = "walkietalkie-eng"
	ks2type = /obj/item/encryptionkey/eng

// Engineering (Off)
/obj/item/radio/eng/off/Initialize()
	. = ..()
	set_listening(FALSE)

// Engineering
/obj/item/radio/heads/ce
	icon_state = "walkietalkie-eng"
	ks2type = /obj/item/encryptionkey/heads/ce

// Engineering (Off)
/obj/item/radio/eng/off/Initialize()
	. = ..()
	set_listening(FALSE)

// Science
/obj/item/radio/sci
	icon_state = "walkietalkie-sci"
	ks2type = /obj/item/encryptionkey/sci

// Science (Off)
/obj/item/radio/sci/off/Initialize()
	. = ..()
	set_listening(FALSE)

// Phone
/obj/item/radio/phone
	icon = 'icons/obj/radio.dmi'
	icon_state = "red_phone"
	name = "phone"
	var/radio_sound = null

/obj/item/radio/phone/Initialize()
	. = ..()
	set_broadcasting(FALSE)
	set_listening(TRUE)

// Medical Phone
/obj/item/radio/phone/medbay/Initialize()
	. = ..()
	set_frequency(MED_I_FREQ)
	internal_channels = default_medbay_channels.Copy()

// All-channel Radio
/obj/item/radio/all_channels/Initialize()
	channels = ALL_RADIO_CHANNELS.Copy()
	. = ..()
