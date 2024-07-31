local controller = ui.create("Tonemap controller")

local customBloom = controller:switch("Bloom scale")
local bloomGroup = customBloom:create("Bloom settings")
local boomSlider = bloomGroup:slider("Bloom scale", 0, 1000, 200, 0.01)

local customExposure = controller:switch("Exposure scale")
local exposureGroup = customExposure:create("Exposure settings")
local exposureMinScale = exposureGroup:slider("Exposure min scale", 0, 100, 10, 0.01)
local exposureMaxScale = exposureGroup:slider("Exposure max scale", 0, 100, 50, 0.01)
	
local function tonemap_control(tonemap)
	--bloom
	tonemap.m_bUseCustomBloomScale = customBloom:get()
	tonemap.m_flCustomBloomScale = boomSlider:get() * 0.01
	
	--exposure
	tonemap.m_bUseCustomAutoExposureMin = customExposure:get()
	tonemap.m_bUseCustomAutoExposureMax = customExposure:get()
	tonemap.m_flCustomAutoExposureMin = exposureMinScale:get() * 0.01
	tonemap.m_flCustomAutoExposureMax = exposureMaxScale:get() * 0.01
end

events.pre_render:set(function()
	entity.get_entities(69, true, tonemap_control)
end)