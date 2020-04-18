local default_style = data.raw["gui-style"].default

default_style[TOP_FLOW_STYLE] = {
	type = "horizontal_flow_style",
	parent = "horizontal_flow",
    top_padding = 0,
    left_padding = 0,
}

default_style[LEFT_FLOW_STYLE] = {
	type = "vertical_flow_style",
	parent = "vertical_flow",
    top_padding = 5,
    left_padding = 13,
}

default_style[CONTAINER_FLOW_STYLE] = {
	type = "horizontal_flow_style",
	parent = "horizontal_flow",
    top_padding = 0,
    bottom_padding = 0,
    left_padding = 0,
    right_padding = 0,
}

default_style[BUTTON_STYLE] = {
    type = "button_style",
    parent = "button",
    maximal_width = 50,
    maximal_height = 48,
    font = "default-small-semibold"
}

default_style[ALLY_TABLE_STYLE] = {
    type = "table_style",
    parent = "table",
    cell_padding = 4,
 }