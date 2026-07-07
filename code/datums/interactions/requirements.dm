ABSTRACT_TYPE(/datum/interaction_requirement)

/datum/interaction_requirement
	/// Stable machine-readable id for diagnostics.
	var/id
	/// Short player-facing requirement text.
	var/name
	/// Structured status returned when the requirement is not met.
	var/failure_status = INTERACTION_RESULT_BLOCKED
	/// Optional human-readable failure reason.
	var/failure_message

/datum/interaction_requirement/New(id, name, failure_status, failure_message)
	if(!isnull(id))
		src.id = id
	if(!isnull(name))
		src.name = name
	if(!isnull(failure_status))
		src.failure_status = failure_status
	if(!isnull(failure_message))
		src.failure_message = failure_message

/datum/interaction_requirement/proc/is_met(datum/interaction_context/context)
	return TRUE

/datum/interaction_requirement/proc/render_hint(datum/interaction_context/context)
	return name

/datum/interaction_requirement/proc/get_failure(datum/interaction_context/context)
	return new /datum/interaction_result(failure_status, failure_message)

/datum/interaction_requirement/adjacent
	id = "adjacent"
	name = "stand next to it"
	failure_status = INTERACTION_RESULT_BLOCKED
	failure_message = "You are too far away."

/datum/interaction_requirement/adjacent/is_met(datum/interaction_context/context)
	return context?.is_adjacent

/datum/interaction_requirement/active_item_empty
	id = "active_item_empty"
	name = "an empty active hand"
	failure_status = INTERACTION_RESULT_MISSING_ACTIVE_ITEM
	failure_message = "Your active hand must be empty."

/datum/interaction_requirement/active_item_empty/is_met(datum/interaction_context/context)
	return !context?.active_item

/datum/interaction_requirement/active_tool
	id = "active_tool"
	failure_status = INTERACTION_RESULT_MISSING_ACTIVE_ITEM
	var/required_tool

/datum/interaction_requirement/active_tool/New(required_tool, tool_name)
	src.required_tool = required_tool
	..("active_tool_[required_tool]", tool_name || required_tool, INTERACTION_RESULT_MISSING_ACTIVE_ITEM, "You need [tool_name || required_tool].")

/datum/interaction_requirement/active_tool/is_met(datum/interaction_context/context)
	return context?.active_item?.tool_behaviour == required_tool

/datum/interaction_requirement/active_type
	id = "active_type"
	failure_status = INTERACTION_RESULT_MISSING_ACTIVE_ITEM
	var/typepath

/datum/interaction_requirement/active_type/New(typepath, item_name)
	src.typepath = typepath
	..("active_type_[typepath]", item_name || "[typepath]", INTERACTION_RESULT_MISSING_ACTIVE_ITEM, "You need [item_name || "[typepath]"].")

/datum/interaction_requirement/active_type/is_met(datum/interaction_context/context)
	return istype(context?.active_item, typepath)

/datum/interaction_requirement/active_stack_amount
	id = "active_stack_amount"
	failure_status = INTERACTION_RESULT_MISSING_ACTIVE_ITEM
	var/amount = 1

/datum/interaction_requirement/active_stack_amount/New(amount, stack_name)
	src.amount = amount
	..("active_stack_amount_[amount]", "[amount] [stack_name || "stack items"]", INTERACTION_RESULT_MISSING_ACTIVE_ITEM, "You need [amount] [stack_name || "stack items"].")

/datum/interaction_requirement/active_stack_amount/is_met(datum/interaction_context/context)
	if(!istype(context?.active_item, /obj/item/stack))
		return FALSE
	var/obj/item/stack/stack = context.active_item
	return stack.get_amount() >= amount

/datum/interaction_requirement/active_circuitboard
	id = "active_circuitboard"
	name = "a circuit board"
	failure_status = INTERACTION_RESULT_MISSING_ACTIVE_ITEM
	var/required_board_type

/datum/interaction_requirement/active_circuitboard/New(required_board_type, board_name)
	src.required_board_type = required_board_type
	..("active_circuitboard_[required_board_type]", board_name || "a circuit board", INTERACTION_RESULT_MISSING_ACTIVE_ITEM, "You need [board_name || "a circuit board"].")

/datum/interaction_requirement/active_circuitboard/is_met(datum/interaction_context/context)
	if(!istype(context?.active_item, /obj/item/circuitboard))
		return FALSE
	var/obj/item/circuitboard/board = context.active_item
	return !required_board_type || board.board_type == required_board_type

/datum/interaction_requirement/target_var_equals
	id = "target_var_equals"
	failure_status = INTERACTION_RESULT_WRONG_TARGET_STATE
	var/var_name
	var/expected_value

/datum/interaction_requirement/target_var_equals/New(var_name, expected_value, state_name)
	src.var_name = var_name
	src.expected_value = expected_value
	..("target_var_equals_[var_name]", state_name || "[var_name] is [expected_value]", INTERACTION_RESULT_WRONG_TARGET_STATE, "The target is in the wrong state.")

/datum/interaction_requirement/target_var_equals/is_met(datum/interaction_context/context)
	if(!context?.target || !(var_name in context.target.vars))
		return FALSE
	return context.target.vars[var_name] == expected_value
