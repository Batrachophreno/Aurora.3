/** Materials made from other materials.
 */
/datum/material/alloy
	name = "alloy"
	desc = "A material composed of two or more other materials."
	init_flags = NONE
	/// The materials this alloy is made from weighted by their ratios.
	var/list/composition = null

/datum/material/alloy/return_composition(amount = 1, flags)
	if(flags & MATCONTAINER_ACCEPT_ALLOYS)
		return ..()

	. = list()

	var/list/cached_comp = composition
	for(var/comp_mat in cached_comp)
		var/datum/material/component_material = GET_MATERIAL_REF(comp_mat)
		var/list/component_composition = component_material.return_composition(cached_comp[comp_mat], flags)
		for(var/comp_comp_mat in component_composition)
			.[comp_comp_mat] += component_composition[comp_comp_mat] * amount

/** Plasteel
 *
 * An alloy of iron and phoron.
 * Applies a significant slowdown effect to any and all items that contain it.
 */
/datum/material/alloy/plasteel
	name = "plasteel"
	desc = "The heavy duty result of infusing iron with phoron."
	color = "#706374"
	init_flags = MATERIAL_INIT_MAPLOAD
	value_per_unit = 0.135
	strength_modifier = 1.25
	integrity_modifier = 1.5 // Heavy duty.
	armor_modifiers = list(MELEE = 1.4, BULLET = 1.4, LASER = 1.1, ENERGY = 1.1, BOMB = 1.5, BIO = 1, FIRE = 1.1, ACID = 1)
	sheet_type = /obj/item/stack/sheet/plasteel
	categories = list(
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	composition = list(/datum/material/iron=1, /datum/material/phoron=1)
	mat_rust_resistance = RUST_RESISTANCE_REINFORCED
	added_slowdown = 0.05

/** Phorotanium
 *
 * An alloy of titanium and phoron.
 */
/datum/material/alloy/phorotanium
	name = "phorotanium"
	desc = "The extremely heat resistant result of infusing titanium with phoron."
	color = "#3a313a"
	init_flags = MATERIAL_INIT_MAPLOAD
	value_per_unit = 0.225
	strength_modifier = 0.9 // It's a lightweight alloy.
	integrity_modifier = 1.3
	armor_modifiers = list(MELEE = 1.1, BULLET = 1.1, LASER = 1.4, ENERGY = 1.4, BOMB = 1.1, BIO = 1.2, FIRE = 1.5, ACID = 1)
	sheet_type = /obj/item/stack/sheet/mineral/phorotanium
	categories = list(
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	composition = list(/datum/material/titanium=1, /datum/material/phoron=1)

/** Phorosilicate
 *
 * An alloy of phoron and silicate.
 */
/datum/material/alloy/phorosilicate
	name = "phorosilicate"
	desc = "phoron-infused silicate. It is much more durable and heat resistant than either of its component materials."
	color = "#ff80f4"
	alpha = 150
	starlight_color = COLOR_STRONG_MAGENTA
	init_flags = MATERIAL_INIT_MAPLOAD
	integrity_modifier = 0.5
	armor_modifiers = list(MELEE = 0.8, BULLET = 0.8, LASER = 1.2, ENERGY = 1.2, BOMB = 0.3, BIO = 1.2, FIRE = 2, ACID = 2)
	sheet_type = /obj/item/stack/sheet/phorosilicate
	shard_type = /obj/item/shard/phorosilicate
	debris_type = /obj/effect/decal/cleanable/glass/phorosilicate
	value_per_unit = 0.075
	categories = list(
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	composition = list(/datum/material/glass=1, /datum/material/phoron=0.5)

/** Titaniumglass
 *
 * An alloy of glass and titanium.
 */
/datum/material/alloy/titaniumglass
	name = "titanium glass"
	desc = "A specialized silicate-titanium alloy that is commonly used in shuttle windows."
	color = "#cfbee0"
	alpha = 150
	starlight_color = COLOR_COMMAND_BLUE
	init_flags = MATERIAL_INIT_MAPLOAD
	armor_modifiers = list(MELEE = 1.2, BULLET = 1.2, LASER = 0.8, ENERGY = 0.8, BOMB = 0.5, BIO = 1.2, FIRE = 0.8, ACID = 2)
	sheet_type = /obj/item/stack/sheet/titaniumglass
	shard_type = /obj/item/shard/titanium
	debris_type = /obj/effect/decal/cleanable/glass/titanium
	value_per_unit = 0.04
	categories = list(
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	composition = list(/datum/material/glass=1, /datum/material/titanium=0.5)

/** Plastitanium Glass
 *
 * An alloy of plastitanium and glass.
 */
/datum/material/alloy/plastitaniumglass
	name = "plastitanium glass"
	desc = "A specialized silicate-plastitanium alloy."
	color = "#5d3369"
	starlight_color = COLOR_CENTCOM_BLUE
	alpha = 150
	init_flags = MATERIAL_INIT_MAPLOAD
	integrity_modifier = 1.1
	armor_modifiers = list(MELEE = 1.2, BULLET = 1.2, LASER = 1.2, ENERGY = 1.2, BOMB = 0.5, BIO = 1.2, FIRE = 2, ACID = 2)
	sheet_type = /obj/item/stack/sheet/plastitaniumglass
	shard_type = /obj/item/shard/plastitanium
	debris_type = /obj/effect/decal/cleanable/glass/plastitanium
	value_per_unit = 0.125
	categories = list(
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	composition = list(/datum/material/glass=1, /datum/material/alloy/plastitanium=0.5)
