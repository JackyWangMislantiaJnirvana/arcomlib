-- constants
STOPPER_DELAY = 1
REDSTONE_DELAY = 0.5

-- devices' address
local devs_addr = {
    redbus = "left",
    tempSens = "right",
    massSens = "back",
    modem = "bottom",

    redbusDevs = {
        droppers = colors.pink,
        stopper = colors.orange,
        caster = colors.white,
        igniter = colors.yellow
    }
}

local function setRedbusOutput(color, status)
    if status == true then
        redstone.setBundledOutput(
            devs_addr.redbus,
            colors.combine(redstone.getBundledOutput(devs_addr.redbus), color)
        )
    elseif status == false then
        redstone.setBundledOutput(
            devs_addr.redbus,
            colors.subtract(redstone.getBundledOutput(devs_addr.redbus), color)
        )
    else
        error("setRedbus: bad argument : status")
    end
end

local smeltery = {}

-- dropper interface
function smeltery.drop()
    setRedbusOutput(devs_addr.redbusDevs.droppers, true)
    sleep(REDSTONE_DELAY)
    setRedbusOutput(devs_addr.redbusDevs.droppers, false)
end

-- e-stop interface
function smeltery.setEStopper(status)
    setRedbusOutput(devs_addr.redbusDevs.stopper, status)
    repeat
        sleep(STOPPER_DELAY)
    until(smeltery.tempSens.getval())
    setRedbusOutput(devs_addr.redbusDevs.stopper, false)
end

-- caster status
smeltery.caster = {
    status = false
}

function smeltery.caster.start()
    smeltery.caster.status = true
    setRedbusOutput(devs_addr.redbusDevs.caster, true)
end

function smeltery.caster.stop()
    smeltery.caster.status = false
    setRedbusOutput(devs_addr.redbusDevs.caster, false)
end

function smeltery.ignite()
    setRedbusOutput(devs_addr.redbusDevs.igniter, true)
    sleep(1)
    setRedbusOutput(devs_addr.redbusDevs.igniter, false)
end

function smeltery.caster.getStatus()
    return smeltery.caster.status
end

-- Temperature sensor interface
smeltery.tempSens = peripheral.wrap(devs_addr.tempSens)

function smeltery.getTemp()
    return smeltery.tempSens.getval()
end

return smeltery