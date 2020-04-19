require("defines")

data:extend({
    {
        type = "double-setting",
        name = PARAM_OFFLINE_DAMAGE_REDUCTION_NAME,
        setting_type = "runtime-global",
        default_value = PARAM_OFFLINE_DAMAGE_REDUCTION,
        minimum_value = 0.0,
        maximum_value  = 1.0,
        order = "a"
    },
    {
        type = "int-setting",
        name = PARAM_REACH_BONUS_NAME,
        setting_type = "runtime-global",
        default_value = PARAM_REACH_BONUS,
        minimum_value = 0,
        order = "b"
    },
    {
        type = "int-setting",
        name = PARAM_INVENTORY_BONUS_NAME,
        setting_type = "runtime-global",
        default_value = PARAM_INVENTORY_BONUS,
        minimum_value = 0,
        order = "c"
    },
    {
        type = "double-setting",
        name = PARAM_MINING_BONUS_NAME,
        setting_type = "runtime-global",
        default_value = PARAM_MINING_BONUS,
        minimum_value = 0,
        order = "d"
    }
})