/obj/item/
	name = "item"
	desc = "Oh my god it's an item."

	var/size = 1 //Size in.. uh...
	var/weight = 1 //Weight in kg

	var/is_container = FALSE //Setting this to true will open the below inventories on use.
	var/container_max_size = 0 //I this item has a container, how much should it be able to hold in each slot?
	var/container_max_weight = 0 //I this item has a container, how much should it be able to hold in each slot?

	var/list/obj/inventory/inventories = list() //The inventory holders this object has

	icon_state = "inventory"
	var/icon_state_held_left = "held_left"
	var/icon_state_held_right = "held_right"
	var/icon_state_worn = "worn"

	var/worn_layer = 0

	var/item_slot = SLOT_NONE

	mouse_over_pointer = MOUSE_ACTIVE_POINTER

	var/no_held_draw = FALSE

	var/slot_icons = FALSE //Set to true if the clothing is based on where it's slot is.

	var/ignore_other_slots = FALSE


	var/block_mul = list(
		ATTACK_TYPE_MELEE = 0,
		ATTACK_TYPE_RANGED = 0,
		ATTACK_TYPE_MAGIC = 0
	)

	var/parry_mul = list(
		ATTACK_TYPE_MELEE = 0,
		ATTACK_TYPE_RANGED = 0,
		ATTACK_TYPE_MAGIC = 0
	)

	var/soul_bound = FALSE

/obj/item/clicked_by_object(var/mob/caller as mob,var/atom/object,location,control,params) //The src was clicked on by the object

	if(!is_container)
		return ..()

	if(is_inventory(object) && is_advanced(caller))

		var/mob/living/advanced/A = caller

		for(var/obj/inventory/I in A.inventory)
			if(I in inventories)
				continue
			if(!I.is_container)
				continue
			I.alpha = 0
			I.mouse_opacity = 0

		for(var/i=1,i<=length(inventories),i++)
			var/obj/inventory/I = inventories[i]
			I.screen_loc = "CENTER+[i]-[(length(inventories)+1)/2],BOTTOM+1.25"
			if(!I.alpha)
				animate(I,alpha=255,time=4)
				I.mouse_opacity = 2
			else
				animate(I,alpha=0,time=4)
				I.mouse_opacity = 0
		return TRUE

	if(is_item(object) && length(inventories))
		var/added = FALSE

		if(object.type != src.type)
			for(var/obj/inventory/I in inventories)
				if(I.add_object(object,FALSE))
					added = TRUE
					break

		if(added)
			caller.to_chat(span("notice","You stuff \the [object] in your [src]."))
		else
			caller.to_chat(span("warning","You don't have enough inventory space to hold this!"))

	return 	..()

/obj/item/New(var/desired_loc)

	//force_move(desired_loc) //TODO: FIGURE THIS OUT

	var/dynamic_id = 1

	for(var/i=1, i <= length(inventories), i++)
		var/obj/inventory/new_inv = inventories[i]
		inventories[i] = new new_inv(src)

		if(is_dynamic_inventory(inventories[i]))
			inventories[i].id = "dynamic_[dynamic_id]"
			dynamic_id += 1

		if(container_max_size)
			inventories[i].max_size = container_max_size
		if(container_max_weight)
			inventories[i].max_weight = container_max_weight

	. = ..()

obj/item/proc/update_owner(desired_owner)
	for(var/v in inventories)
		var/obj/inventory/I = v
		I.update_owner(desired_owner)

/obj/item/proc/get_owner()
	if(is_inventory(src.loc))
		var/obj/inventory/I = src.loc
		return I.owner

	return null

/obj/item/update_icon()
	..()
	if(is_inventory(src.loc))
		var/obj/inventory/I = src.loc
		I.update_icon()

/obj/item/proc/can_be_worn()
	return FALSE

/obj/item/get_examine_text(var/mob/examiner)

	if(!is_advanced(examiner))
		return ..()

	. = ..()

	var/mob/living/advanced/A = examiner

	if(damage_type && all_damage_types[damage_type])

		var/damagetype/DT = all_damage_types[damage_type]

		var/list/base_damage_list = list()
		var/list/attribute_damage_list = list()
		var/list/skill_damage_list = list()

		for(var/k in DT.base_attack_damage)
			var/v = DT.base_attack_damage[k]
			if(v)
				base_damage_list += "[v] [k]"

		for(var/k in DT.attribute_stats)
			var/v = DT.attribute_stats[k]
			var/experience/E = A.attributes[k]
			var/grade
			switch(v)
				if(CLASS_S)
					grade = "S"
				if(CLASS_A)
					grade = "A"
				if(CLASS_B)
					grade = "B"
				if(CLASS_C)
					grade = "C"
				if(CLASS_D)
					grade = "D"
				if(CLASS_E)
					grade = "E"

			if(grade)
				attribute_damage_list += "[capitalize(k)]: [grade] ([floor(E.get_current_level()*v)] [DT.attribute_damage[k]])"

		for(var/k in DT.skill_stats)
			var/v = DT.skill_stats[k]
			var/experience/E = A.skills[k]
			var/grade
			switch(v)
				if(CLASS_S)
					grade = "S"
				if(CLASS_A)
					grade = "A"
				if(CLASS_B)
					grade = "B"
				if(CLASS_C)
					grade = "C"
				if(CLASS_D)
					grade = "D"
				if(CLASS_E)
					grade = "E"

			if(grade)
				skill_damage_list += "[capitalize(k)]: [grade] ([floor(E.get_current_level()*v)] [DT.skill_damage[k]])"

		var/returning_text = ..()
		if(length(base_damage_list))
			returning_text += div("notice bold","Base Damage:") + div("notice","[english_list(base_damage_list, and_text = ", ")]")

		if(length(attribute_damage_list))
			returning_text += div("notice bold","Attribute Damage:") + div("notice","[english_list(attribute_damage_list, and_text = ", ")]")

		if(length(skill_damage_list))
			returning_text += div("notice bold","Skill Damage:") + div("notice","[english_list(skill_damage_list, and_text = ", ")]")

		return . + returning_text

	return .

obj/item/proc/do_automatic(caller,object,location,params)
	return TRUE

/obj/item/proc/on_pickup(var/obj/inventory/I) //When the item is picked up.

	if(is_container)
		for(var/obj/inventory/I2 in inventories)
			I2.update_owner(I.owner)

	return

/obj/item/proc/on_drop(var/obj/inventory/I)
	return