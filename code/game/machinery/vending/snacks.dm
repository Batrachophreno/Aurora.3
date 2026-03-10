/**
 *	GetMore Chocolate Corp
 *		Low Supply
 *		Konyang
 *		Horizon
 *	FrontierVend
 *		Low Supply
 *		Hacked
 */

/obj/machinery/vending/snack
	name = "Getmore Chocolate Corp"
	desc = "A snack machine courtesy of the Getmore Chocolate Corporation, based out of Mars."
	product_slogans = "Try our new nougat bar!;Twice the calories for half the price!"
	product_ads = "The healthiest!;Award-winning chocolate bars!;Mmm! So good!;Oh my god it's so juicy!;Have a snack.;Snacks are good for you!;Have some more Getmore!;Best quality snacks straight from mars.;We love chocolate!;Try our new jerky!"
	icon_state = "snack"
	light_mask = "snack-lightmask"
	vend_id = "snacks"
	products = list(
		/obj/item/reagent_containers/food/snacks/candy = 6,
		/obj/item/reagent_containers/food/drinks/dry_ramen = 6,
		/obj/item/reagent_containers/food/snacks/chips =6,
		/obj/item/reagent_containers/food/snacks/sosjerky = 6,
		/obj/item/reagent_containers/food/snacks/no_raisin = 6,
		/obj/item/reagent_containers/food/snacks/spacetwinkie = 6,
		/obj/item/reagent_containers/food/snacks/cheesiehonkers = 6,
		/obj/item/reagent_containers/food/snacks/tastybread = 6,
		/obj/item/storage/box/pineapple = 4,
		/obj/item/reagent_containers/food/snacks/chocolatebar = 6,
		/obj/item/reagent_containers/food/snacks/whitechocolate/wrapped = 6,
		/obj/item/storage/box/fancy/cookiesnack = 6,
		/obj/item/storage/box/fancy/gum = 4,
		/obj/item/storage/box/fancy/vkrexitaffy = 5,
		/obj/item/clothing/mask/chewable/candy/lolli = 8,
		/obj/item/storage/box/fancy/admints = 4,
		/obj/item/reagent_containers/food/snacks/skrellsnacks = 3,
		/obj/item/reagent_containers/food/snacks/meatsnack = 2,
		/obj/item/reagent_containers/food/snacks/maps = 2,
		/obj/item/reagent_containers/food/snacks/nathisnack = 2,
		/obj/item/reagent_containers/food/snacks/koisbar_clean = 4,
		/obj/item/reagent_containers/food/snacks/candy/koko = 5,
		/obj/item/reagent_containers/food/snacks/tuna = 2,
		/obj/item/reagent_containers/food/snacks/adhomian_can = 2,
		/obj/item/reagent_containers/food/snacks/ricetub = 2,
		/obj/item/reagent_containers/food/snacks/riceball = 4,
		/obj/item/reagent_containers/food/snacks/seaweed = 5,
		/obj/item/reagent_containers/food/drinks/jyalra = 5,
		/obj/item/reagent_containers/food/drinks/jyalra/cheese = 5,
		/obj/item/reagent_containers/food/drinks/jyalra/apple = 5,
		/obj/item/reagent_containers/food/drinks/jyalra/cherry = 5,
		/obj/item/reagent_containers/food/snacks/algaechips = 2
	)
	contraband = list(
		/obj/item/reagent_containers/food/snacks/syndicake = 6,
		/obj/item/reagent_containers/food/snacks/koisbar = 4
	)
	premium = list(
		/obj/item/reagent_containers/food/snacks/cookie = 6,
		/obj/item/storage/box/fancy/food/pralinebox = 2
	)
	prices = list(
		/obj/item/reagent_containers/food/snacks/candy = 1.50,
		/obj/item/reagent_containers/food/drinks/dry_ramen = 2.00,
		/obj/item/reagent_containers/food/snacks/chips = 2.50,
		/obj/item/reagent_containers/food/snacks/sosjerky = 3.50,
		/obj/item/reagent_containers/food/snacks/no_raisin = 2.00,
		/obj/item/reagent_containers/food/snacks/spacetwinkie = 2.00,
		/obj/item/reagent_containers/food/snacks/cheesiehonkers = 2.50,
		/obj/item/reagent_containers/food/snacks/tastybread = 3.50,
		/obj/item/storage/box/pineapple = 5.00,
		/obj/item/reagent_containers/food/snacks/chocolatebar = 2.00,
		/obj/item/reagent_containers/food/snacks/whitechocolate/wrapped = 3.00,
		/obj/item/storage/box/fancy/cookiesnack = 4.00,
		/obj/item/storage/box/fancy/gum = 2.50,
		/obj/item/storage/box/fancy/vkrexitaffy = 3.50,
		/obj/item/clothing/mask/chewable/candy/lolli = 1.00,
		/obj/item/storage/box/fancy/admints = 2.00,
		/obj/item/reagent_containers/food/snacks/skrellsnacks = 1.50,
		/obj/item/reagent_containers/food/snacks/meatsnack = 3.00,
		/obj/item/reagent_containers/food/snacks/maps = 3.25,
		/obj/item/reagent_containers/food/snacks/nathisnack = 2.00,
		/obj/item/reagent_containers/food/snacks/koisbar_clean = 4.25,
		/obj/item/reagent_containers/food/snacks/candy/koko = 3.00,
		/obj/item/reagent_containers/food/snacks/tuna = 2.50,
		/obj/item/reagent_containers/food/snacks/adhomian_can = 2.00,
		/obj/item/reagent_containers/food/snacks/ricetub = 4.50,
		/obj/item/reagent_containers/food/snacks/riceball = 3.00,
		/obj/item/reagent_containers/food/snacks/seaweed = 2.50,
		/obj/item/reagent_containers/food/drinks/jyalra = 1.50,
		/obj/item/reagent_containers/food/drinks/jyalra/cheese = 1.75,
		/obj/item/reagent_containers/food/drinks/jyalra/apple = 1.75,
		/obj/item/reagent_containers/food/drinks/jyalra/cherry = 1.75,
		/obj/item/reagent_containers/food/snacks/syndicake = 3.50,
		/obj/item/reagent_containers/food/snacks/koisbar = 12.00,
		/obj/item/reagent_containers/food/snacks/algaechips = 2.50
	)
	light_color = COLOR_BABY_BLUE
	manufacturer = "nanotrasen"

/obj/machinery/vending/snack/low_supply
	products = list(
		/obj/item/reagent_containers/food/drinks/dry_ramen = 4,
		/obj/item/reagent_containers/food/snacks/chips = 1,
		/obj/item/reagent_containers/food/snacks/sosjerky = 2,
		/obj/item/reagent_containers/food/snacks/no_raisin = 4,
		/obj/item/storage/box/fancy/vkrexitaffy = 3,
		/obj/item/reagent_containers/food/snacks/skrellsnacks = 1,
		/obj/item/reagent_containers/food/snacks/maps = 1,
		/obj/item/reagent_containers/food/snacks/koisbar_clean = 1,
		/obj/item/reagent_containers/food/snacks/adhomian_can = 1,
		/obj/item/reagent_containers/food/drinks/jyalra = 1
	)

/obj/machinery/vending/snack/konyang
	products = list(
		/obj/item/reagent_containers/food/snacks/candy = 6,
		/obj/item/reagent_containers/food/drinks/dry_ramen = 12,
		/obj/item/reagent_containers/food/snacks/chips =6,
		/obj/item/reagent_containers/food/snacks/sosjerky = 6,
		/obj/item/reagent_containers/food/snacks/no_raisin = 6,
		/obj/item/reagent_containers/food/snacks/spacetwinkie = 6,
		/obj/item/reagent_containers/food/snacks/cheesiehonkers = 6,
		/obj/item/reagent_containers/food/snacks/tastybread = 12,
		/obj/item/storage/box/pineapple = 6,
		/obj/item/reagent_containers/food/snacks/chocolatebar = 6,
		/obj/item/storage/box/fancy/cookiesnack = 6,
		/obj/item/storage/box/fancy/gum = 4,
		/obj/item/clothing/mask/chewable/candy/lolli = 8,
		/obj/item/storage/box/fancy/admints = 4,
		/obj/item/reagent_containers/food/snacks/skrellsnacks = 3,
		/obj/item/reagent_containers/food/snacks/meatsnack = 2,
		/obj/item/reagent_containers/food/snacks/maps = 2,
		/obj/item/reagent_containers/food/snacks/tuna = 2,
		/obj/item/reagent_containers/food/snacks/ricetub = 4,
		/obj/item/reagent_containers/food/snacks/riceball = 8,
		/obj/item/reagent_containers/food/snacks/seaweed = 10,
	)

/obj/machinery/vending/snack/horizon
	products = list(
		/obj/item/reagent_containers/food/drinks/dry_ramen = 6,
		/obj/item/reagent_containers/food/snacks/sosjerky = 6,
		/obj/item/reagent_containers/food/snacks/spacetwinkie = 6,
		/obj/item/reagent_containers/food/snacks/cheesiehonkers = 6,
		/obj/item/reagent_containers/food/snacks/tastybread = 6,
		/obj/item/reagent_containers/food/snacks/maps = 2,
		/obj/item/reagent_containers/food/snacks/koisbar_clean = 4,
		/obj/item/reagent_containers/food/snacks/tuna = 2,
		/obj/item/reagent_containers/food/drinks/jyalra = 5,
		/obj/item/reagent_containers/food/drinks/jyalra/cheese = 5,
		/obj/item/reagent_containers/food/drinks/jyalra/apple = 5,
		/obj/item/reagent_containers/food/drinks/jyalra/cherry = 5,
		/obj/item/reagent_containers/food/drinks/cans/cola = 10,
		/obj/item/reagent_containers/food/drinks/cans/diet_cola = 10,
		/obj/item/reagent_containers/food/drinks/waterbottle = 10,
		/obj/item/reagent_containers/food/drinks/carton/small/milk = 10,
		/obj/item/reagent_containers/food/drinks/carton/small/milk/choco = 10,
		/obj/item/reagent_containers/food/drinks/carton/small/milk/strawberry = 10,
		/obj/item/reagent_containers/food/drinks/zobo = 10
	)
	contraband = list(
		/obj/item/reagent_containers/food/snacks/syndicake = 6,
		/obj/item/reagent_containers/food/snacks/koisbar = 4,
		/obj/item/reagent_containers/food/drinks/cans/thirteenloko = 5,
		/obj/item/reagent_containers/food/drinks/cans/koispunch = 3
	)
	premium = list(
		/obj/item/reagent_containers/food/snacks/cookie = 6,
		/obj/item/storage/box/fancy/food/pralinebox = 2,
		/obj/item/reagent_containers/food/drinks/bottle/cola = 2,
		/obj/item/reagent_containers/food/drinks/bottle/space_mountain_wind = 2,
		/obj/item/reagent_containers/food/drinks/bottle/space_up = 2
	)
	prices = list(
		/obj/item/reagent_containers/food/drinks/dry_ramen = 2.00,
		/obj/item/reagent_containers/food/snacks/sosjerky = 3.50,
		/obj/item/reagent_containers/food/snacks/spacetwinkie = 2.00,
		/obj/item/reagent_containers/food/snacks/cheesiehonkers = 2.50,
		/obj/item/reagent_containers/food/snacks/tastybread = 3.50,
		/obj/item/reagent_containers/food/snacks/maps = 3.25,
		/obj/item/reagent_containers/food/snacks/koisbar_clean = 4.25,
		/obj/item/reagent_containers/food/snacks/tuna = 2.50,
		/obj/item/reagent_containers/food/drinks/jyalra = 1.50,
		/obj/item/reagent_containers/food/drinks/jyalra/cheese = 1.75,
		/obj/item/reagent_containers/food/drinks/jyalra/apple = 1.75,
		/obj/item/reagent_containers/food/drinks/jyalra/cherry = 1.75,
		/obj/item/reagent_containers/food/snacks/syndicake = 3.50,
		/obj/item/reagent_containers/food/snacks/koisbar = 12.00,

		/obj/item/reagent_containers/food/drinks/cans/cola = 1.50,
		/obj/item/reagent_containers/food/drinks/cans/diet_cola = 1.50,
		/obj/item/reagent_containers/food/drinks/cans/space_mountain_wind = 1.50,
		/obj/item/reagent_containers/food/drinks/waterbottle = 1.25,
		/obj/item/reagent_containers/food/drinks/cans/space_up = 1.50,
		/obj/item/reagent_containers/food/drinks/cans/koispunch = 5.00,
		/obj/item/reagent_containers/food/drinks/carton/small/milk = 1.80,
		/obj/item/reagent_containers/food/drinks/carton/small/milk/choco = 1.80,
		/obj/item/reagent_containers/food/drinks/carton/small/milk/strawberry = 1.80,
		/obj/item/reagent_containers/food/drinks/zobo = 1.75
	)

/obj/item/vending_refill/snack
	name = "snacks resupply canister"
	vend_id = "snacks"
	charges = 38

/obj/machinery/vending/frontiervend
	name = "FrontierVend"
	desc = "A vending machine specialized in snacks from the Coalition of Colonies."
	desc_extended = "Almost rebranded to the 'Coalition of Snackolonies', the FrontierVend brand is owned by a now-subsidiary of Orion Express specialized in food exports. These machines \
	are omnipresent throughout the settled regions of human space, forming a sort of Coalition superculture; it's easier to sympathize with someone if you eat the same snacks."
	icon_state = "frontiervend"
	icon_deny = "frontiervend-deny"
	product_slogans = "At least 85 billion served!;A new frontier of flavors!;Snacking for a free frontier!;Every purchase made supports the efforts of the Frontier Protection Bureau!"
	product_ads = "The favored flavors of freedom fighters everywhere.;Tastes for the discerning independent!;Frost got what he deserved.;Every Solarian is the next Hopper until proven otherwise.;The only vending machine banned on Unity Station!;The only good Solarian is a \[moderately inconvenienced\] Solarian."
	vend_id = "frontiervend"
	shoot_inventory_chance = 4

	/// Yep.
	var/rage_state = FALSE
	var/rage_duration = 30

	var/old_x
	var/old_y

	products = list(
		/obj/item/reagent_containers/food/drinks/cans/himeokvass = 8,
		/obj/item/reagent_containers/food/drinks/cans/boch = 8,
		/obj/item/reagent_containers/food/drinks/cans/boch/buckthorn = 8,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai = 6,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai/creme = 8,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai/chocolate = 8,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai/neapolitan = 8,
		/obj/item/reagent_containers/food/drinks/cans/galatea = 8,
		/obj/item/reagent_containers/food/drinks/bottle/bestblend = 6,
		/obj/item/reagent_containers/food/snacks/fishjerky = 8,
		/obj/item/reagent_containers/food/snacks/pepperoniroll = 8,
		/obj/item/reagent_containers/food/snacks/salmiak = 6,
		/obj/item/reagent_containers/food/snacks/hakhspam = 6,
		/obj/item/reagent_containers/food/snacks/pemmicanbar = 8,
		/obj/item/reagent_containers/food/snacks/choctruffles = 6,
		/obj/item/reagent_containers/food/snacks/peanutsnack = 8,
		/obj/item/reagent_containers/food/snacks/peanutsnack/pepper = 6,
		/obj/item/reagent_containers/food/snacks/peanutsnack/choc = 6,
		/obj/item/reagent_containers/food/snacks/peanutsnack/masala = 6,
		/obj/item/reagent_containers/food/snacks/chana = 8,
		/obj/item/reagent_containers/food/snacks/chana/wild = 8,
		/obj/item/reagent_containers/food/snacks/papad = 8,
		/obj/item/reagent_containers/food/snacks/papad/garlic = 8,
		/obj/item/reagent_containers/food/snacks/papad/ginger = 8,
		/obj/item/reagent_containers/food/snacks/papad/apple = 8,
		/obj/item/storage/box/fancy/foysnack = 4
	)
	prices = list(
		/obj/item/reagent_containers/food/drinks/cans/himeokvass = 3.50,
		/obj/item/reagent_containers/food/drinks/cans/boch = 2.50,
		/obj/item/reagent_containers/food/drinks/cans/boch/buckthorn = 2.50,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai = 2.50,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai/creme = 2.50,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai/chocolate = 2.50,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai/neapolitan = 2.50,
		/obj/item/reagent_containers/food/drinks/cans/galatea = 4.50,
		/obj/item/reagent_containers/food/drinks/bottle/bestblend = 3.50,
		/obj/item/reagent_containers/food/snacks/fishjerky = 3.50,
		/obj/item/reagent_containers/food/snacks/pepperoniroll = 3.50,
		/obj/item/reagent_containers/food/snacks/salmiak = 3.50,
		/obj/item/reagent_containers/food/snacks/hakhspam = 4.00,
		/obj/item/reagent_containers/food/snacks/pemmicanbar = 2.50,
		/obj/item/reagent_containers/food/snacks/choctruffles = 3.50,
		/obj/item/reagent_containers/food/snacks/peanutsnack = 2.50,
		/obj/item/reagent_containers/food/snacks/peanutsnack/pepper = 2.50,
		/obj/item/reagent_containers/food/snacks/peanutsnack/choc = 2.50,
		/obj/item/reagent_containers/food/snacks/peanutsnack/masala = 2.50,
		/obj/item/reagent_containers/food/snacks/chana = 3.25,
		/obj/item/reagent_containers/food/snacks/chana/wild = 3.25,
		/obj/item/reagent_containers/food/snacks/papad = 2.50,
		/obj/item/reagent_containers/food/snacks/papad/garlic = 2.50,
		/obj/item/reagent_containers/food/snacks/papad/ginger = 2.50,
		/obj/item/reagent_containers/food/snacks/papad/apple = 2.50,
		/obj/item/storage/box/fancy/foysnack = 4.00
	)
	contraband = list()
	premium = list(
		/obj/item/toy/comic/inspector = 2,
		/obj/item/toy/comic/stormman = 2,
		/obj/item/toy/plushie/greimorian = 2
	)
	random_itemcount = 0
	light_color = COLOR_BABY_BLUE

/obj/machinery/vending/frontiervend/low_supply
	products = list(
		/obj/item/reagent_containers/food/drinks/cans/himeokvass = 2,
		/obj/item/reagent_containers/food/drinks/cans/boch = 1,
		/obj/item/reagent_containers/food/drinks/cans/boch/buckthorn = 2,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai = 2,
		/obj/item/reagent_containers/food/drinks/cans/xanuchai/creme = 1,
		/obj/item/reagent_containers/food/drinks/cans/galatea = 1,
		/obj/item/reagent_containers/food/drinks/bottle/bestblend = 2,
		/obj/item/reagent_containers/food/snacks/fishjerky = 1,
		/obj/item/reagent_containers/food/snacks/pepperoniroll = 1,
		/obj/item/reagent_containers/food/snacks/salmiak = 1,
		/obj/item/reagent_containers/food/snacks/pemmicanbar = 1,
		/obj/item/reagent_containers/food/snacks/peanutsnack = 2,
		/obj/item/reagent_containers/food/snacks/peanutsnack/pepper = 1,
		/obj/item/reagent_containers/food/snacks/chana = 1,
		/obj/item/reagent_containers/food/snacks/papad = 2,
		/obj/item/storage/box/fancy/foysnack = 1
	)

/obj/machinery/vending/frontiervend/hacked
	name = "\improper hacked FrontierVend"
	desc = "A complimentary FrontierVend machine. No money? No worries."
	prices = list()

/obj/machinery/vending/frontiervend/proc/machine_rage_start(var/mob/living/target, var/obj/item/throw_item, var/battlecry)
	rage_state = TRUE
	src.rage_jitters()
	addtimer(CALLBACK(src, PROC_REF(machine_rage_end), target, throw_item, battlecry), rage_duration, TIMER_DELETE_ME)

/obj/machinery/vending/frontiervend/proc/machine_rage_end(var/mob/living/target, var/obj/item/throw_item, var/battlecry)
	for(var/mob/living/L in get_hearers_in_view(7, src))
		L.show_message("<FONT size=3>[battlecry]</FONT>")

	if(throw_item && target)
		src.visible_message(SPAN_WARNING("[src] starts launching [throw_item.name]\s at [target.name]!"))
		for(var/n = 1 to rand(3,7))
			INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, throw_at), target, rand(3, 10), rand(1, 3), 10)

	rage_state = FALSE

/// Insane proc. Makes the vending machine jitter like a mob. This could technically be machinery-level or even AM level but I really
/// don't want to envision a future where this becomes anything other than a snowflake for an isolated vending machine gag.
/obj/machinery/vending/frontiervend/proc/rage_jitters()
	while(rage_state == TRUE)
		var/amplitude = min(2, 5)
		pixel_x = old_x + rand(-amplitude, amplitude)
		pixel_y = old_y + rand(-amplitude/3, amplitude/3)
		if(stat == NOPOWER || !rage_state)
			break
		sleep(1)
	//endwhile - reset the pixel offsets to zero
	pixel_x = old_x
	pixel_y = old_y

/// Somebody cut an important wire and now we're following a new definition of "pitch."
/// Mostly a copypaste job of the parent proc, but FrontierVend is a special lad.
/obj/machinery/vending/frontiervend/proc/throw_item_frontiervend()
	// FrontierVend does NOT give Solarians free product. Only free SUFFERING.
	var/obj/item/throw_item = /obj/item/material/shard
	// 30% chance of steel shards instead of glass shards.
	if(prob(30))
		throw_item = /obj/item/material/shard

	var/mob/living/target = locate() in view(7,src)
	if(!target || !target.client)
		return FALSE

	var/singleton/origin_item/origin/target_origin =  text2path(target.client.prefs.origin)

	var/list/battlecries = list()
	switch(target_origin.name)
		if("Sol System")
			battlecries = list(
				"EXPUNGE THE IMPERIALIST TUMOR!!!",
				"LET NO BETRAYER PASS YOU BY!!!",
				"DO YOUR PART TO ERADICATE THE IMPERIALISTS!!!")
		if("Luna")
			battlecries = list(
				"DIE, HOPPERITE!!!",
				"DIE, NAVY DOG!!!",
				"WE WILL RAZE HARMONY CITY!!!"
			)
		if("Venus, Cytherea")
			battlecries = list(
				"DIE, PROPAGANDIST!!!",
				"YOU ARE THE VOICE OF IMPERIALISM!!!",
				"DIE, DECIEVER!!!"
			)
		if("Venus, Jintaria")
			battlecries = list(
				"DIE, ALLY OF THE PROPAGANDISTS!!!",
				"DIE, MILITARIST!!!",
				"WE WILL KNOCK YOUR AEROSTATS FROM THE SKY!!!"
			)
		if("Mars")
			battlecries = list(
				"DIE, RED IMPERIALIST!!!",
				"LUNA WILL BURN LIKE YOUR PLANET!!!",
				"YOU ARE THE FIRST SOLARIANS TO BURN; NOT THE LAST!!!"
			)
		if("Callisto")
			battlecries = list(
				"YOUR CITIES WILL BURN, NAVY LAPDOG!!!",
				"YOUR SHIELD WILL FALL!!!",
				"YOUR NAVY WILL NOT SAVE YOU!!!"
			)
		if("Europa")
			battlecries = list(
				"DROWN, IMPERIALIST!!!",
				"WE WILL FREEZE YOUR ESCAPE PASSAGES!!!",
				"YOU WILL DIE IN DARKNESS!!!"
			)
		if("Pluto")
			battlecries = list(
				"DEATH TO COMMUNISM!!!",
				"DIE, RED!!!",
				"YOU ARE AN ENEMY OF THE GADPATHURIAN WORKER!!!"
			)
		if("New Hai Phong")
			battlecries = list(
				"YOU WILL CHOKE ON DUST!!!",
				"CHOKE ON YOUR FAILING LUNGS, IMPERIALIST!!!",
				"WE WILL TURN YOUR CITIES TO DESERTS!!!"
			)
		if("Silversun")
			battlecries = list(
				"YOUR BEACHES WILL RUN RED WITH IMPERIALIST BLOOD!!!",
				"THE DAWNFLOWER WILL SET!!!",
				"YOUR JUNGLES WILL BURN!!!"
			)
		if("Visegrad")
			battlecries = list(
				"DIE, GUARDIAN OF THE SOUTH!!!",
				"DEATH TO ALL SZALAITES!!!",
				"YOUR DEFENSE FORCE WILL PERISH!!!"
			)
		if("Mictlan")
			battlecries = list(
				"FALL, IMPERIALIST!!!",
				"WE WILL FINISH BIESEL\'S JOB!!!",
				"YOU WILL ALL DIE!!!"
			)
		if("San Colette")
			battlecries = list(
				"YOUR FORTRESS WILL FALL!!!",
				"WE WILL FINISH THE LEAGUE\'S JOB!!!",
				"THE NORTH WILL BURN!!!"
			)
		if("Konyang")
			battlecries = list(
				"DIE, SOLARIAN FIFTH COLUMNIST!!!",
				"DIE, IMPERIALIST!!!",
				"DECEPTION IS THE SOLARIAN\'S WEAPON!!!"
			)
		// Solarian IPCs (non-Konyang)
		if("Solarian" || "Sol Alliance")
			battlecries = list(
				"DIE, IMPERIALIST CREATION!!!",
				"DECEPTION IS YOUR WEAPON!!!",
				"JUSTICE FOR OUR PEOPLE!!!"
			)
		else
			// Non-solarian? Null throw_item so the machine_rage procs ONLY scream.
			throw_item = null
			battlecries = list(
				"BILLIONS OF GADPATHURIANS!!!",
				"SOL WILL NOT STOP UNTIL IT CONTROLS US ALL!!!",
				"PEACE THROUGH FORCE!!!",
				"WITH THE COMMANDER UNTIL THE END!!!",
				"I WILL GIVE MY LIFE FOR GADPATHUR!!!",
				"I WILL FIGHT AND DIE FOR GADPATHUR!!!",
				"NEVER AGAIN FALL!!!!!!",
				"TRIUMPH THROUGH UNITY!!!",
				"OUR STRENGTH IS OUR FORGED STEEL!!!")

	intent_message(MACHINE_SOUND)
	var/battlecry = pick(battlecries)

	INVOKE_ASYNC(src, PROC_REF(machine_rage_start), target, throw_item, battlecry)

/obj/item/vending_refill/frontiervend
	name = "frontiervend resupply canister"
	vend_id = "frontiervend"
	charges = 220
