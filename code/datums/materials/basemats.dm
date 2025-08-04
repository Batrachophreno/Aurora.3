///Has no special properties.
/datum/material/iron
	name = "iron"
	desc = "Common iron ore often found in sedimentary and igneous layers of the crust."
	color = "#B6BEC2"
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	sheet_type = /obj/item/stack/sheet/iron
	ore_type = /obj/item/stack/ore/iron
	value_per_unit = 5 / SHEET_MATERIAL_AMOUNT
	mat_rust_resistance = RUST_RESISTANCE_BASIC
	mineral_rarity = MATERIAL_RARITY_COMMON
	points_per_unit = 1 / SHEET_MATERIAL_AMOUNT
	minimum_value_override = 0
	tradable = TRUE
	tradable_base_quantity = MATERIAL_QUANTITY_COMMON

///Breaks extremely easily but is transparent.
/datum/material/glass
	name = "glass"
	desc = "Glass forged by melting sand."
	color = "#6292AF"
	alpha = 150
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	integrity_modifier = 0.1
	sheet_type = /obj/item/stack/sheet/glass
	ore_type = /obj/item/stack/ore/glass/basalt
	shard_type = /obj/item/shard
	debris_type = /obj/effect/decal/cleanable/glass
	value_per_unit = 5 / SHEET_MATERIAL_AMOUNT
	minimum_value_override = 0
	tradable = TRUE
	tradable_base_quantity = MATERIAL_QUANTITY_COMMON
	armor_modifiers = list(MELEE = 0.2, BULLET = 0.2, ENERGY = 1, BIO = 0.2, FIRE = 1, ACID = 0.2)
	mineral_rarity = MATERIAL_RARITY_COMMON
	points_per_unit = 1 / SHEET_MATERIAL_AMOUNT
	texture_layer_icon_state = "shine"

/*
Color matrices are like regular colors but unlike with normal colors, you can go over 255 on a channel.
Unless you know what you're doing, only use the first three numbers. They're in RGB order.
*/

///Has no special properties. Could be good against vampires in the future perhaps.
/datum/material/silver
	name = "silver"
	desc = "Silver"
	color = "#B5BCBB"
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	sheet_type = /obj/item/stack/sheet/mineral/silver
	ore_type = /obj/item/stack/ore/silver
	value_per_unit = 50 / SHEET_MATERIAL_AMOUNT
	tradable = TRUE
	tradable_base_quantity = MATERIAL_QUANTITY_UNCOMMON
	mineral_rarity = MATERIAL_RARITY_SEMIPRECIOUS
	points_per_unit = 16 / SHEET_MATERIAL_AMOUNT
	texture_layer_icon_state = "shine"
	fish_weight_modifier = 1.35

///Slight force increase
/datum/material/gold
	name = "gold"
	desc = "Gold"
	color = "#E6BB45"
	strength_modifier = 1.2
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	sheet_type = /obj/item/stack/sheet/mineral/gold
	ore_type = /obj/item/stack/ore/gold
	value_per_unit = 125 / SHEET_MATERIAL_AMOUNT
	tradable = TRUE
	tradable_base_quantity = MATERIAL_QUANTITY_RARE
	armor_modifiers = list(MELEE = 1.1, BULLET = 1.1, LASER = 1.15, ENERGY = 1.15, BOMB = 1, BIO = 1, FIRE = 0.7, ACID = 1.1)
	mineral_rarity = MATERIAL_RARITY_PRECIOUS
	points_per_unit = 18 / SHEET_MATERIAL_AMOUNT
	texture_layer_icon_state = "shine"

/datum/material/diamond
	name = "diamond"
	desc = "Highly pressurized carbon"
	color = "#C9D8F2"
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	sheet_type = /obj/item/stack/sheet/mineral/diamond
	ore_type = /obj/item/stack/ore/diamond
	alpha = 132
	starlight_color = COLOR_BLUE_LIGHT
	value_per_unit = 500 / SHEET_MATERIAL_AMOUNT
	strength_modifier = 1.1
	integrity_modifier = 1.25
	tradable = TRUE
	tradable_base_quantity = MATERIAL_QUANTITY_EXOTIC
	armor_modifiers = list(MELEE = 1.3, BULLET = 1.3, LASER = 0.6, ENERGY = 1, BOMB = 1.2, BIO = 1, FIRE = 1, ACID = 1)
	mineral_rarity = MATERIAL_RARITY_RARE
	points_per_unit = 50 / SHEET_MATERIAL_AMOUNT

/datum/material/uranium
	name = "uranium"
	desc = "Uranium"
	color = "#2C992C"
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	sheet_type = /obj/item/stack/sheet/mineral/uranium
	ore_type = /obj/item/stack/ore/uranium
	value_per_unit = 100 / SHEET_MATERIAL_AMOUNT
	tradable = TRUE
	tradable_base_quantity = MATERIAL_QUANTITY_RARE
	armor_modifiers = list(MELEE = 1.5, BULLET = 1.4, LASER = 0.5, ENERGY = 0.5, FIRE = 1, ACID = 1)
	mineral_rarity = MATERIAL_RARITY_SEMIPRECIOUS
	points_per_unit = 30 / SHEET_MATERIAL_AMOUNT

/datum/material/phoron
	name = "phoron"
	desc = "The rarest stuff in the Spur."
	color = "#BA3692"
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	sheet_type = /obj/item/stack/sheet/mineral/phoron
	ore_type = /obj/item/stack/ore/phoron
	value_per_unit = 200 / SHEET_MATERIAL_AMOUNT
	armor_modifiers = list(MELEE = 1.4, BULLET = 0.7, ENERGY = 1.2, BIO = 1.2, ACID = 0.5)
	mineral_rarity = MATERIAL_RARITY_PRECIOUS
	points_per_unit = 15 / SHEET_MATERIAL_AMOUNT

///Mediocre force increase
/datum/material/titanium
	name = "titanium"
	desc = "Titanium"
	color = "#EFEFEF"
	strength_modifier = 1.3
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	sheet_type = /obj/item/stack/sheet/mineral/titanium
	ore_type = /obj/item/stack/ore/titanium
	value_per_unit = 125 / SHEET_MATERIAL_AMOUNT
	tradable = TRUE
	tradable_base_quantity = MATERIAL_QUANTITY_UNCOMMON
	armor_modifiers = list(MELEE = 1.35, BULLET = 1.3, LASER = 1.3, ENERGY = 1.25, BOMB = 1.25, BIO = 1, FIRE = 0.7, ACID = 1)
	mat_rust_resistance = RUST_RESISTANCE_TITANIUM
	mineral_rarity = MATERIAL_RARITY_SEMIPRECIOUS
	texture_layer_icon_state = "shine"

///Force decrease
/datum/material/plastic
	name = "plastic"
	desc = "Plastic"
	color = "#BFB9AC"
	strength_modifier = 0.85
	sheet_type = /obj/item/stack/sheet/plastic
    /// No plastic or coal ore, so we use slag.
	ore_type = /obj/item/stack/ore/slag
	categories = list(
		MAT_CATEGORY_SILO = TRUE,
		MAT_CATEGORY_RIGID=TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
	)
	value_per_unit = 25 / SHEET_MATERIAL_AMOUNT
	armor_modifiers = list(MELEE = 1.5, BULLET = 1.1, LASER = 0.3, ENERGY = 0.5, BOMB = 1, BIO = 1, FIRE = 1.1, ACID = 1)
	mineral_rarity = MATERIAL_RARITY_UNDISCOVERED //Nobody's found oil on lavaland yet.
	points_per_unit = 4 / SHEET_MATERIAL_AMOUNT

///Force decrease and mushy sound effect. (Not yet implemented)
/datum/material/biomass
	name = "biomass"
	desc = "Organic matter."
	color = "#735b4d"
	strength_modifier = 0.8
	value_per_unit = 50 / SHEET_MATERIAL_AMOUNT

/datum/material/wood
	name = "wood"
	desc = "Flexible, durable, but flammable. Hard to come across in space."
	color = "#855932"
	strength_modifier = 0.5
	sheet_type = /obj/item/stack/sheet/mineral/wood
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	value_per_unit = 20 / SHEET_MATERIAL_AMOUNT
	armor_modifiers = list(MELEE = 1.1, BULLET = 1.1, LASER = 0.4, ENERGY = 0.4, BOMB = 1, BIO = 0.2, ACID = 0.3)
	texture_layer_icon_state = "woodgrain"

/datum/material/wood/on_main_applied(atom/source, mat_amount, multiplier)
	. = ..()
	if(source.material_flags & MATERIAL_AFFECT_STATISTICS && isobj(source))
		var/obj/wooden = source
		wooden.resistance_flags |= FLAMMABLE

/datum/material/wood/on_main_removed(atom/source, mat_amount, multiplier)
	. = ..()
	if(source.material_flags & MATERIAL_AFFECT_STATISTICS && isobj(source))
		var/obj/wooden = source
		wooden.resistance_flags &= ~FLAMMABLE

// It's basically adamantine, but it isn't!
/datum/material/metalhydrogen
	name = "Metal Hydrogen"
	desc = "Solid metallic hydrogen. Some say it should be impossible"
	color = "#62708A"
	alpha = 150
	starlight_color = COLOR_MODERATE_BLUE
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	sheet_type = /obj/item/stack/sheet/mineral/metal_hydrogen
	value_per_unit = 700 / SHEET_MATERIAL_AMOUNT
	strength_modifier = 1.2
	armor_modifiers = list(MELEE = 1.35, BULLET = 1.3, LASER = 1.3, ENERGY = 1.25, BOMB = 0.7, BIO = 1, FIRE = 1.3, ACID = 1)

//I don't like sand. It's coarse, and rough, and irritating, and it gets everywhere.
/datum/material/sand
	name = "sand"
	desc = "You know, it's amazing just how structurally sound sand can be."
	color = "#EDC9AF"
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	sheet_type = /obj/item/stack/sheet/sandblock
	value_per_unit = 2 / SHEET_MATERIAL_AMOUNT
	strength_modifier = 0.5
	integrity_modifier = 0.1
	armor_modifiers = list(MELEE = 0.25, BULLET = 0.25, LASER = 1.25, ENERGY = 0.25, BOMB = 0.25, BIO = 0.25, FIRE = 1.5, ACID = 1.5)
	turf_sound_override = FOOTSTEP_SAND
	texture_layer_icon_state = "sand"

/datum/material/sandstone
	name = "sandstone"
	desc = "Bialtaakid 'ant taerif ma hdha."
	color = "#ECD5A8"
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	sheet_type = /obj/item/stack/sheet/mineral/sandstone
	value_per_unit = 5 / SHEET_MATERIAL_AMOUNT
	armor_modifiers = list(MELEE = 0.5, BULLET = 0.5, LASER = 1.25, ENERGY = 0.5, BOMB = 0.5, BIO = 0.25, FIRE = 1.5, ACID = 1.5)
	turf_sound_override = FOOTSTEP_WOOD
	texture_layer_icon_state = "brick"

/datum/material/snow
	name = "snow"
	desc = "There's no business like snow business."
	color = COLOR_WHITE
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	sheet_type = /obj/item/stack/sheet/mineral/snow
	strength_modifier = 0.4
	integrity_modifier = 0.4
	value_per_unit = 5 / SHEET_MATERIAL_AMOUNT
	armor_modifiers = list(MELEE = 0.25, BULLET = 0.25, LASER = 0.25, ENERGY = 0.25, BOMB = 0.25, BIO = 0.25, FIRE = 0.25, ACID = 1.5)
	turf_sound_override = FOOTSTEP_SAND
	texture_layer_icon_state = "sand"

/datum/material/bronze
	name = "bronze"
	desc = "Clock Cult? Never heard of it."
	color = "#876223"
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	sheet_type = /obj/item/stack/sheet/bronze
	value_per_unit = 50 / SHEET_MATERIAL_AMOUNT
	armor_modifiers = list(MELEE = 1, BULLET = 1, LASER = 1, ENERGY = 1, BOMB = 1, BIO = 1, FIRE = 1.5, ACID = 1.5)

/datum/material/paper
	name = "paper"
	desc = "Ten thousand folds of pure starchy power."
	color = "#E5DCD5"
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	sheet_type = /obj/item/stack/sheet/paperframes
	value_per_unit = 5 / SHEET_MATERIAL_AMOUNT
	strength_modifier = 0.3
	armor_modifiers = list(MELEE = 0.1, BULLET = 0.1, LASER = 0.1, ENERGY = 0.1, BOMB = 0.1, BIO = 0.1, ACID = 1.5)
	turf_sound_override = FOOTSTEP_SAND
	texture_layer_icon_state = "paper"

/datum/material/paper/on_main_applied(atom/source, mat_amount, multiplier)
	. = ..()
	if(!isobj(source) || !(source.material_flags & MATERIAL_AFFECT_STATISTICS))
		return
	var/obj/paper = source
	paper.resistance_flags |= FLAMMABLE
	paper.obj_flags |= UNIQUE_RENAME

/datum/material/paper/on_main_removed(atom/source, mat_amount, multiplier)
	. = ..()
	if(!isobj(source) || !(source.material_flags & MATERIAL_AFFECT_STATISTICS))
		return
	var/obj/paper = source
	paper.resistance_flags &= ~FLAMMABLE

/datum/material/cardboard
	name = "cardboard"
	desc = "They say cardboard is used by hobos to make incredible things."
	color = "#5F625C"
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	sheet_type = /obj/item/stack/sheet/cardboard
	value_per_unit = 6 / SHEET_MATERIAL_AMOUNT
	strength_modifier = 0.3
	armor_modifiers = list(MELEE = 0.25, BULLET = 0.25, LASER = 0.25, ENERGY = 0.25, BOMB = 0.25, BIO = 0.25, ACID = 1.5)

/datum/material/cardboard/on_main_applied(atom/source, mat_amount, multiplier)
	. = ..()
	if(isobj(source) && source.material_flags & MATERIAL_AFFECT_STATISTICS)
		var/obj/cardboard = source
		cardboard.resistance_flags |= FLAMMABLE
		cardboard.obj_flags |= UNIQUE_RENAME

/datum/material/cardboard/on_main_removed(atom/source, mat_amount, multiplier)
	if(isobj(source) && source.material_flags & MATERIAL_AFFECT_STATISTICS)
		var/obj/cardboard = source
		cardboard.resistance_flags &= ~FLAMMABLE
	return ..()


/datum/material/bamboo
	name = "bamboo"
	desc = "If it's good enough for pandas, it's good enough for you."
	color = "#87a852"
	categories = list(
		MAT_CATEGORY_RIGID = TRUE,
		MAT_CATEGORY_BASE_RECIPES = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL = TRUE,
		MAT_CATEGORY_ITEM_MATERIAL_COMPLEMENTARY = TRUE,
		)
	sheet_type = /obj/item/stack/sheet/mineral/bamboo
	strength_modifier = 0.5
	value_per_unit = 5 / SHEET_MATERIAL_AMOUNT
	armor_modifiers = list(MELEE = 0.5, BULLET = 0.5, LASER = 0.5, ENERGY = 0.5, BOMB = 0.5, BIO = 0.51, FIRE = 0.5, ACID = 1.5)
	turf_sound_override = FOOTSTEP_WOOD
	texture_layer_icon_state = "bamboo"
