local default_style = data.raw["gui-style"].default

default_style[ALLIANCE_BUTTON_FRAME_STYLE] = {
	type = "horizontal_flow_style",
	parent = "horizontal_flow",
    top_padding = 5,
    left_padding = 5,
}

default_style[ALLIANCE_BUTTON_STYLE] = {
    type = "button_style",
    parent = "button",
    maximal_width = 50,
    maximal_height = 48,
    font = "default-small-semibold"
}

default_style[ALLIANCE_PANEL_STYLE] = {
    type = "table_style",
    parent = "table",
    cell_padding = 4,
 }