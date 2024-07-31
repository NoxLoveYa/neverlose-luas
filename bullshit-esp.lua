--getting images
local images = {
	["amogus"] = network.get("https://cdn.discordapp.com/attachments/1049903225265999932/1050077001177911336/7513466.png"),
	["muscledoggo"] = network.get("https://i.kym-cdn.com/photos/images/newsfeed/001/582/322/94d.png"),
	["penis"] = network.get("https://media.tenor.com/y1bfWPx8xj0AAAAC/happy-penis-cartoon-penis.gif"),
	["penis2"] = network.get("https://media.discordapp.net/attachments/754743016400486444/861658313183199232/image0.gif"),
	["drooling cat"] = network.get("https://media.tenor.com/3eGE_XIvCO4AAAAd/mimimimimi-cat-sleeping.gif"),
	["femboy war"] = network.get("https://media.tenor.com/BGkyyR_lEU0AAAAd/war.gif"),
	["hvh meme"] = network.get("https://media.tenor.com/0EIMWM2Fns0AAAAd/fartware-anti-aim.gif"),
	["happy cat"] = network.get("https://media.tenor.com/D3Owbj5xGUYAAAAC/cat-cats.gif"),
	["hvh meme2"] = network.get("https://cdn.discordapp.com/attachments/1049903225265999932/1050086059599466526/spreadmiss.gif"),
	["anime girl"] = network.get("https://imgs.search.brave.com/F8hVdX8Z-T0Y8pPijcAHlPqSVW5y6ZP92duqsVLMy2s/rs:fit:649:961:1/g:ce/aHR0cHM6Ly9wbmdp/bWcuY29tL3VwbG9h/ZHMvYW5pbWVfZ2ly/bC9hbmltZV9naXJs/X1BORzEzLnBuZw"),
}

--function to gt all the keys to the images
local function get_idx()
	local array = {}
		
	for idx, _ in pairs(images) do
		table.insert(array, idx)
	end
	return array
end

--ui
local ref = ui.create("image preview")
local combo = ref:combo("images", get_idx())
	
local image = render.load_image(images[combo:get()])
	
local texture = ref:texture(image)
local scale_slider = ref:slider("widt adjustemens", 0, 30, 0)
	
--ui update shit
combo:set_callback(function()
	local choosen = combo:get()
	image = render.load_image(images[choosen])
	texture:set(image)
end, true)


--rendering
local ennemies = {}

events.createmove:set(function()
	ennemies = entity.get_players(true, true)
end)

events.render:set(function()
	if not entity.get_local_player() or 
		not entity.get_local_player():is_alive() then return end
	
	for idx, enemy in pairs(ennemies) do
		if not enemy:is_alive() then goto skip end
		
		local bbox = enemy:get_bbox()
		local left = bbox.pos1
		local right = bbox.pos2
		if not left or not right then goto skip end
		render.texture(image, left - vector(scale_slider:get(), 0), (right - left) + vector(scale_slider:get() * 2, 0))
		::skip::
	end
end)