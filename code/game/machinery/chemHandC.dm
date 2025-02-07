
//Base, not intended to ever appear

/obj/machinery/chemtemper
	icon = 'icons/obj/chemHandC.dmi'

	density = 1
	anchored = 1
	machine_flags = SCREWTOGGLE | CROWDESTROY | WRENCHMOVE | FIXED2WORK | EJECTNOTDEL
	pass_flags = PASSTABLE
	use_power = MACHINE_POWER_USE_IDLE
	idle_power_usage = 25
	active_power_usage = 5000

	var/max_temperature = 0
	var/thermal_energy_transfer = 0
	var/part_kind = 0
	var/onstage = null
	var/image/OLholder
	var/image/ULholder
	var/obj/item/weapon/reagent_containers/held_container
	var/working = FALSE
	var/had_item = FALSE

/obj/machinery/chemtemper/RefreshParts()
	var/T = 0
	overlays = null
	part_kind = initial(part_kind)
	if(part_kind == "laser")
		for(var/obj/item/weapon/stock_parts/micro_laser/L in component_parts)
			T += L.rating
			part_kind = L.rating //Sets what tier of laser we have
		thermal_energy_transfer = initial(thermal_energy_transfer) * T
		overlays += image(icon = icon, icon_state = "t[part_kind]_laser")
		OLholder = image(icon = icon, icon_state = "t[part_kind]_beam")
		OLholder.plane = OBJ_PLANE
		OLholder.layer = ABOVE_OBJ_LAYER

	if(part_kind == "scanner")
		for(var/obj/item/weapon/stock_parts/scanning_module/S in component_parts)
			T += S.rating
			part_kind = S.rating //Sets what tier of scanner we have
		thermal_energy_transfer = initial(thermal_energy_transfer) * T
		overlays += image(icon = icon, icon_state = "t[part_kind]_scanner")
		OLholder = image(icon = icon, icon_state = "t[part_kind]_waveFront")
		OLholder.plane = OBJ_PLANE
		OLholder.layer = ABOVE_OBJ_LAYER
		ULholder = image(icon = icon, icon_state = "t[part_kind]_waveBack")
		ULholder.plane = OBJ_PLANE
		ULholder.layer = BELOW_OBJ_LAYER

	T = 0
	for(var/obj/item/weapon/stock_parts/capacitor/C in component_parts)
		T += C.rating-1
	idle_power_usage = initial(idle_power_usage) - (T * 10) //T1: 25w, T2: 15w, T3: 5w
	active_power_usage = initial(active_power_usage) - (T * 2000) //T1: 5000w, T2: 2500w, T3: 1250w

/obj/machinery/chemtemper/power_change()
	if( powered() )
		stat &= ~NOPOWER
		icon_state = "[initial(icon_state)]"
	else
		spawn(rand(0, 15))
			stat |= NOPOWER
			icon_state = "[initial(icon_state)]_off"

/obj/machinery/chemtemper/process()
	if(stat & (BROKEN|NOPOWER|FORCEDISABLE))
		return
	if(held_container && working)
		held_container.reagents.heating(thermal_energy_transfer, max_temperature)

/obj/machinery/chemtemper/attack_hand(mob/user)
	if(!user.incapacitated() && Adjacent(user) && user.dexterity_check())
		if(held_container)
			overlays -= onstage
			to_chat(user, "<span class='notice'>You remove \the [held_container] from \the [src].</span>")
			user.put_in_hands(held_container)
			held_container = null
			had_item = TRUE
		toggle(user)
		had_item = FALSE

/obj/machinery/chemtemper/attackby(obj/item/weapon/W, mob/user)
	if(istype(W, /obj/item/weapon/reagent_containers) && anchored)
		if(!held_container)
			if(user.drop_item(W, src))
				held_container = W
				to_chat(user, "<span class='notice'>You put \the [held_container] onto \the [src].</span>")
				var/image/I = image("icon"=W, "layer"=FLOAT_LAYER)
				onstage = I
				overlays += I
				return 1
		else
			to_chat(user, "<span class='notice'>\The [src] already has \a [held_container] on it.</span>")
			return 1
	else
		return ..()

/obj/machinery/chemtemper/attack_ghost()
	return

/obj/machinery/chemtemper/AltClick(mob/user)
	if(Adjacent(user))
		toggle(user)
		return
	return ..()

/obj/machinery/chemtemper/verb/toggle()
	set src in view(1)
	set name = "Toggle active"
	set category = "Object"

/obj/machinery/chemtemper/toggle(mob/user)
	if(!user.incapacitated() && Adjacent(user) && !(stat & (FORCEDISABLE|NOPOWER)) && user.dexterity_check())
		if(!held_container && working) //For when you take the beaker off but left the heater/cooler on
			working = !working
			if(OLholder)
				overlays -= OLholder
			if(ULholder)
				underlays -= ULholder
			processing_objects.Remove(src)
			to_chat(user, "<span class='notice'>You turn off \the [src].</span>")
			return
		else if(held_container)
			working = !working
			if(working)
				if(OLholder)
					overlays += OLholder
				if(ULholder)
					underlays += ULholder
				processing_objects.Add(src)
				to_chat(user, "<span class='notice'>You turn on \the [src].</span>")
			else
				if(OLholder)
					overlays -= OLholder
				if(ULholder)
					underlays -= ULholder
				processing_objects.Remove(src)
				to_chat(user, "<span class='notice'>You turn off \the [src].</span>")
			return
		else
			if(!had_item)
				to_chat(user, "<span class='notice'>\The [src] doesn't have a container to work on right now.</span>")

//Heater//

/obj/machinery/chemtemper/heater
	name = "directed laser heater"
	desc = "A platform with an integrated laser that uses high-energy photons to heat a subject through atomic vibrations. In a practical sense, it has no upper limit to how much thermal energy can be induced this way, as it is capable of reaching temperatures which could rapidly destroy any laboratory-approved container."
	icon_state = "heater"
	icon_state_open = "heater_open"

	max_temperature = TEMPERATURE_LASER
	thermal_energy_transfer = 3000
	part_kind = "laser"

/obj/machinery/chemtemper/heater/New()
	. = ..()

	component_parts = newlist(
		/obj/item/weapon/circuitboard/chemheater,
		/obj/item/weapon/stock_parts/micro_laser,
		/obj/item/weapon/stock_parts/capacitor
	)
	RefreshParts()

//Cooler//

/obj/machinery/chemtemper/cooler
	name = "cryonic wave projector"
	desc = "Ever want to see a microwave work in reverse? Well this machine is basically that. This machine could technically keep removing energy forever until it reaches absolute zero. Breaking physics and physicists since 2314 to current year and counting."
	icon_state = "cooler"
	icon_state_open = "cooler_open"

	max_temperature = 0 //You can make stuff REALLY cold
	thermal_energy_transfer = -3000
	part_kind = "scanner"

/obj/machinery/chemtemper/cooler/New()
	. = ..()

	component_parts = newlist(
		/obj/item/weapon/circuitboard/chemcooler,
		/obj/item/weapon/stock_parts/scanning_module,
		/obj/item/weapon/stock_parts/capacitor
	)
	RefreshParts()

/*
//Unused desired temp setting. Maybe useful in the future? Not likely since who doesn't want their ice to be absolute zero?
/obj/machinery/chemtemper/cooler/verb/settemp(mob/user as mob)
	set src in view(1)
	set name = "Set temperature"
	set category = "Object"

	var/set_temp = input("Input desired temperature (20 to -273 Celsius).", "Set Temperature") as num
	if(set_temp>20 || set_temp<-273.15)
		to_chat(user, "<span class='notice'>Invalid temperature.</span>")
		return
	max_temperature = set_temp+273.15
*/
