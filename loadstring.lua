-- loadstring(game:httpGet("https://github.com/Tokkenik/ClockLib/edit/main/loadstring.lua", true))()

local Window = {};
Window.__index = Window;

-- variables
local workspace = game:GetService("Workspace");
local tweenService = game:GetService("TweenService");
local inputService = game:GetService("UserInputService");
local contentProvider = game:GetService("ContentProvider");
local coreGui = game:GetService("CoreGui");

-- functions
local function udim2ToVector2(value)
	local camera = workspace.CurrentCamera;
	local x = camera.ViewportSize.X * value.X.Scale + value.X.Offset;
	local y = camera.ViewportSize.Y * value.Y.Scale + value.Y.Offset;
	return Vector2.new(x,y);
end

local function vector2ToUDim2(value)
	return UDim2.fromOffset(value.X, value.Y);
end

local function changeAnchor(obj, anchorPoint)
	local oldOffset = obj.AbsoluteSize * obj.AnchorPoint;
	local newOffset = obj.AbsoluteSize * anchorPoint;
	obj.AnchorPoint = anchorPoint;
	obj.Position += vector2ToUDim2(newOffset - oldOffset);
end

local function round(num, increment)
	local result = math.floor(num / increment + (math.sign(num) * 0.5)) * increment;
	if result < 0 then result += increment; end
	return tonumber(string.format('%.02f', result));
end

local function getLength(t)
	local length = 0;
	for _ in next, t do length += 1; end
	return length;
end

-- assets
contentProvider:PreloadAsync({
	"rbxassetid://7347408509", -- menu button
	"rbxassetid://10002373478", -- close button
	"rbxassetid://3517304301", -- mini button
	"rbxassetid://9754130783", -- toggle checkmark
	"rbxassetid://9805044713", -- dropdown arrow
	"rbxassetid://10628883286" -- button image
});

-- library
function Window.new(title: string?, size: Vector2?)
	return setmetatable({
		title = title or "Window",
		size = size or Vector2.new(350, 250),
		minimized = false,
		hasInit = false,
		selectedTab = nil,
		instances = {},
		connections = {},
		tabs = {},
		flags = {},
		items = {},
		themeItems = {},
		theme = {
			backgroundColor       = Color3.fromRGB(54, 57, 63),
			titleColor            = Color3.fromRGB(255, 255, 255),
			lineColor             = Color3.fromRGB(160, 160, 160),
			topColor              = Color3.fromRGB(47, 49, 54),
			topButtonColor        = Color3.fromRGB(200, 200, 200),
			menuColor             = Color3.fromRGB(47, 49, 54),
			menuButtonColor       = Color3.fromRGB(230, 230, 230),
			tabButtonColor        = Color3.fromRGB(57, 59, 64),
			tabButtonOutline      = Color3.fromRGB(70, 72, 76),
			sectionTextColor      = Color3.fromRGB(200, 200, 200),
			sectionItemColor      = Color3.fromRGB(50, 53, 59),
			sectionItemTextColor  = Color3.fromRGB(200, 200, 200),
			toggleColor           = Color3.fromRGB(47, 49, 54),
			toggleActiveColor     = Color3.fromRGB(200, 200, 200),
			toggleBorderColor     = Color3.fromRGB(200, 200, 200),
			sliderColor           = Color3.fromRGB(47, 49, 54),
			sliderBarColor        = Color3.fromRGB(200, 200, 200),
			sliderBorderColor     = Color3.fromRGB(200, 200, 200),
			sliderValueColor      = Color3.fromRGB(200, 200, 200),
			dropdownArrowColor    = Color3.fromRGB(200, 200, 200),
			dropdownValueColor    = Color3.fromRGB(200, 200, 200),
			dropdownItemColor     = Color3.fromRGB(54, 56, 62),
			dropdownItemTextColor = Color3.fromRGB(200, 200, 200),
			buttonImageColor      = Color3.fromRGB(255, 255, 255),
			textFont              = Enum.Font.TitilliumWeb
		}
	}, Window);
end

function Window:Create(class: string, properties: table)
	assert(class ~= nil, "Missing argument #1 (string expected)");
	assert(properties ~= nil, "Missing argument #2 (table expected)");
	local instance = Instance.new(class);
	for property, value in next, properties do
		instance[property] = value;
	end
	table.insert(self.instances, instance);
	return instance;
end

function Window:Connect(signal: RBXScriptSignal, callback)
	assert(signal ~= nil, "Missing argument #1 (RBXScriptSignal expected)");
	assert(callback ~= nil, "Missing argument #2 (function expected)");
	local connection = signal:Connect(callback);
	table.insert(self.connections, connection);
	return connection;
end

function Window:Unload()
	for _, connection in next, self.connections do
		pcall(connection.Disconnect, connection);
	end
	for _, instance in next, self.instances do
		pcall(instance.Destroy, instance);
	end
end

function Window:UpdateTheme(theme: table?)
	theme = theme or self.theme;
	for _, info in next, self.themeItems do
		local obj, prop, name = unpack(info);
		obj[prop] = theme[name];
	end
end

function Window:AddTab(title: string?)
	local tab = {
		title = title or "Tab",
		window = self,
		sections = {},
		hasInit = false
	};

	function tab:AddSection(title: string?)
		local section = {
			title = title or "Section",
			items = {},
			tab = self,
			window = self.window,
			hasInit = false
		};
		
		function section:AddButton(options: table?) -- rbxassetid://9728031212
			local button = {
				name = options and (options.name or options.Name) or "Button",
				callback = options and (options.callback or options.Callback) or nil,
				section = self,
				window = self.window,
				hasInit = false
			}
			
			function button:Init()
				assert(not self.hasInit, "Item has already initialized");
				
				self.main = self.window:Create("Frame", {
					Size = UDim2.new(1,0,0,30),
					BorderSizePixel = 0,
					BackgroundColor3 = self.window.theme.sectionItemColor,
					Parent = self.section.itemHolder
				});
				table.insert(self.window.themeItems, {self.main, "BackgroundColor3", "sectionItemColor"});

				self.window:Create("UICorner", {
					CornerRadius = UDim.new(0,5),
					Parent = self.main
				});
				
				self.title = self.window:Create("TextLabel", {
					Text = self.name,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = self.window.theme.sectionItemTextColor,
					Position = UDim2.new(0,5,0,5),
					Size = UDim2.new(0.5,-10,1,-10),
					BackgroundTransparency = 1,
					Font = self.window.theme.textFont,
					Parent = self.main
				});
				table.insert(self.window.themeItems, {self.title, "Font", "textFont"});
				table.insert(self.window.themeItems, {self.title, "TextColor3", "sectionItemTextColor"});
				
				self.buttonBox = self.window:Create("ImageLabel", {
					Image = "rbxassetid://10628883286",
					ImageColor3 = self.window.theme.buttonImageColor,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1,0.5),
					Position = UDim2.new(1,-5,0.5,0),
					BorderSizePixel = 0,
					Size = UDim2.new(0,self.main.AbsoluteSize.Y-10,1,-10),
					Parent = self.main,
				});
				table.insert(self.window.themeItems, {self.buttonBox, "ImageColor3", "buttonImageColor"});

				self.window:Create("UICorner", {
					CornerRadius = UDim.new(0,5),
					Parent = self.buttonBox
				});
				
				self.window:Connect(self.main.InputBegan, function(input, processed) 
					if input.UserInputType.Name == "MouseButton1" and not processed and self.callback then
						pcall(self.callback);
					end
				end);
				
				self.hasInit = true;
			end
			
			table.insert(self.items, button);
			return button;
		end

		function section:AddDropdown(options: table?)
			local dropdown = {
				name = options and (options.name or options.Name) or "Dropdown",
				default = options and (options.default or options.Default) or "",
				content = options and (options.content or options.Content) or {},
				flag = options and (options.flag or options.Flag) or nil,
				callback = options and (options.callback or options.Callback) or nil,
				contentObjects = {},
				section = self,
				window = self.window,
				open = false,
				hasInit = false
			};
			
			dropdown.value = dropdown.default;

			function dropdown:Set(value: string)
				assert(value, "Missing argument #1 (string expected)");
				
				self.value = value;
				if self.callback then
					pcall(self.callback, self.value);
				end
				if self.flag then
					rawset(self.window.flags, self.flag, self.value);
				end
				if self.hasInit then
					for name, item in next, self.contentObjects do
						item.mask.Visible = name == self.value;
					end
					self.dropdownValue.Text = self.value;
				end
			end

			function dropdown:Get()
				return self.value;
			end

			function dropdown:Add(name: string?)
				assert(self.hasInit, "Dropdown has not initialized");
				local item = {
					name = name or "Item"
				};

				item.main = self.window:Create("Frame", {
					BorderSizePixel = 0,
					BackgroundColor3 = self.window.theme.dropdownItemColor,
					Size = UDim2.new(1,0,0,30),
					Parent = self.contentHolder
				});
				table.insert(self.window.themeItems, {item.main, "BackgroundColor3", "dropdownItemColor"});

				self.window:Create("UICorner", { Parent = item.main });

				item.mask = self.window:Create("Frame", {
					Size = UDim2.new(1,0,1,0),
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.new(1,1,1),
					BackgroundTransparency = 0.9,
					Visible = false,
					Parent = item.main
				});

				self.window:Create("UICorner", { Parent = item.mask });

				item.title = self.window:Create("TextLabel", {
					Text = item.name,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = self.window.theme.dropdownItemTextColor,
					Position = UDim2.new(0,5,0,5),
					Size = UDim2.new(1,-10,1,-10),
					BackgroundTransparency = 1,
					Font = self.window.theme.textFont,
					Parent = item.main
				});
				table.insert(self.window.themeItems, {item.title, "Font", "textFont"});
				table.insert(self.window.themeItems, {item.title, "TextColor3", "dropdownItemTextColor"});

				self.window:Connect(item.main.InputBegan, function(input, processed)
					if input.UserInputType.Name == "MouseButton1" and not processed then
						self:Set(item.name);
					end
				end);

				self.contentObjects[name] = item;
			end

			function dropdown:Remove(name: string)
				assert(name, "Missing argument #1 (string expected)");
				assert(self.hasInit, "Item has not initialized");

				local obj = self.contentObjects[name];
				if obj then
					obj.main:Destroy();
				end
				self.contentObjects[name] = nil;
			end

			function dropdown:Init()
				assert(not self.hasInit, "Item has already initialized");

				self.main = self.window:Create("Frame", {
					Size = UDim2.new(1,0,0,30),
					BorderSizePixel = 0,
					BackgroundColor3 = self.window.theme.sectionItemColor,
					Parent = self.section.itemHolder
				});
				table.insert(self.window.themeItems, {self.main, "BackgroundColor3", "sectionItemColor"});

				self.window:Create("UICorner", {
					CornerRadius = UDim.new(0,5),
					Parent = self.main
				});

				self.mainHolder = self.window:Create("Frame", {
					Size = UDim2.new(1,0,0,self.main.AbsoluteSize.Y),
					BackgroundTransparency = 1,
					Parent = self.main
				});

				self.title = self.window:Create("TextLabel", {
					Text = self.name,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = self.window.theme.sectionItemTextColor,
					Position = UDim2.new(0,5,0,5),
					Size = UDim2.new(0.5,-10,1,-10),
					BackgroundTransparency = 1,
					Font = self.window.theme.textFont,
					Parent = self.mainHolder
				});
				table.insert(self.window.themeItems, {self.title, "Font", "textFont"});
				table.insert(self.window.themeItems, {self.title, "TextColor3", "sectionItemTextColor"});

				self.arrow = self.window:Create("ImageLabel", {
					Image = "rbxassetid://9805044713",
					AnchorPoint = Vector2.new(1,0.5),
					Position = UDim2.new(1,-5,0.5,0),
					Size = UDim2.new(0,self.mainHolder.AbsoluteSize.Y-10,1,-10),
					BackgroundTransparency = 1,
					ImageColor3 = self.window.theme.dropdownArrowColor,
					Rotation = 180,
					Parent = self.mainHolder,
				});
				table.insert(self.window.themeItems, {self.arrow, "ImageColor3", "dropdownArrowColor"});
				
				self.dropdownValue = self.window:Create("TextLabel", {
					Text = self.value,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextColor3 = self.window.theme.dropdownValueColor,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1,0.5),
					Position = UDim2.new(1,-self.arrow.AbsoluteSize.X-5,0.5,0),
					Size = UDim2.new(0,100,1,-10),
					Font = self.window.theme.textFont,
					Parent = self.mainHolder
				});
				table.insert(self.window.themeItems, {self.dropdownValue, "Font", "textFont"});
				table.insert(self.window.themeItems, {self.dropdownValue, "TextColor3", "dropdownValueColor"});
				
				self.contentHolder = self.window:Create("ScrollingFrame", {
					Position = UDim2.new(0,0,0,self.mainHolder.AbsoluteSize.Y),
					Size = UDim2.new(1,0,1,-self.mainHolder.AbsoluteSize.Y),
					BackgroundTransparency = 1,
					ScrollBarThickness = 0,
					Parent = self.main
				});

				self.contentLayout = self.window:Create("UIListLayout", {
					Padding = UDim.new(0,5),
					Parent = self.contentHolder
				});

				self.contentPadding = self.window:Create("UIPadding", {
					PaddingTop = UDim.new(0,5),
					PaddingBottom = UDim.new(0,5),
					PaddingLeft = UDim.new(0,5),
					PaddingRight = UDim.new(0,5),
					Parent = self.contentHolder
				})

				self.window:Connect(self.mainHolder.InputBegan, function(input, processed)
					if input.UserInputType.Name == "MouseButton1" and not processed then
						local itemCount = math.min(getLength(self.contentObjects), 3);
						tweenService:Create(self.arrow, TweenInfo.new(0.2), {
							Rotation = self.open and 180 or 0
						}):Play();
						tweenService:Create(self.main, TweenInfo.new(0.2), {
							Size = UDim2.new(1,0,0, self.open and self.mainHolder.AbsoluteSize.Y or 
								(self.mainHolder.AbsoluteSize.Y +
									self.contentPadding.PaddingTop.Offset +
									itemCount*30 +
									(itemCount-1) * self.contentLayout.Padding.Offset +
									self.contentPadding.PaddingBottom.Offset)
							)
						}):Play();
						self.open = not self.open;
					end
				end);

				self.hasInit = true;
				for _, content in next, self.content do
					self:Add(content);
				end
				self:Set(self.value);
			end

			if dropdown.flag then
				self.window.items[dropdown.flag] = dropdown;
			end

			table.insert(self.items, dropdown);
			return dropdown;
		end

		function section:AddSlider(options: table?)
			local slider = {
				name = options and (options.name or options.Name) or "Slider",
				default = options and (options.default or options.Default) or 5,
				min = options and (options.min or options.Min) or 0,
				max = options and (options.max or options.Max) or 10,
				flag = options and (options.flag or options.Flag) or nil,
				increment = options and (options.increment or options.Increment) or 1,
				suffix = options and (options.suffix or options.Suffix) or "",
				callback = options and (options.callback or options.Callback) or nil,
				section = self,
				window = self.window,
				hasInit = false
			};
			
			slider.value = slider.default;

			function slider:Set(value: number)
				assert(value, "Missing argument #1 (number expected)");

				self.value = math.clamp(round(value, self.increment), self.min, self.max);
				if self.callback then
					pcall(self.callback, self.value);
				end
				if self.flag then
					rawset(self.window.flags, self.flag, self.value);
				end
				if self.hasInit then
					local percent = math.clamp((self.value - self.min) / (self.max - self.min), 0, 1);
					self.sliderValue.Text = self.value .. self.suffix;
					tweenService:Create(self.sliderBar, TweenInfo.new(0.1), {
						Size = UDim2.new(percent, 0, 1, 1)
					}):Play();
				end
			end

			function slider:Get()
				return self.value;
			end

			function slider:Update()
				local mouse = inputService:GetMouseLocation();
				local offset = mouse.X - self.sliderInput.AbsolutePosition.X;
				local percent = math.clamp(offset / self.sliderInput.AbsoluteSize.X, 0, 1);
				local value = math.clamp(percent * (self.max - self.min) + self.min, self.min, self.max);
				self:Set(value);
			end

			function slider:Init()
				assert(not self.hasInit, "Item has already initialized");

				self.main = self.window:Create("Frame", {
					Size = UDim2.new(1,0,0,30),
					BorderSizePixel = 0,
					BackgroundColor3 = self.window.theme.sectionItemColor,
					Parent = self.section.itemHolder
				});
				table.insert(self.window.themeItems, {self.main, "BackgroundColor3", "sectionItemColor"});

				self.window:Create("UICorner", {
					CornerRadius = UDim.new(0,5),
					Parent = self.main
				});

				self.title = self.window:Create("TextLabel", {
					Text = self.name,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = self.window.theme.sectionItemTextColor,
					Position = UDim2.new(0,5,0,5),
					Size = UDim2.new(0.5,-10,1,-10),
					BackgroundTransparency = 1,
					Font = self.window.theme.textFont,
					Parent = self.main
				});
				table.insert(self.window.themeItems, {self.title, "Font", "textFont"});
				table.insert(self.window.themeItems, {self.title, "TextColor3", "sectionItemTextColor"});

				self.slider = self.window:Create("Frame", {
					AnchorPoint = Vector2.new(1,0.5),
					Position = UDim2.new(1,-10,0.5,0),
					Size = UDim2.new(0.5,-10,0,5),
					BackgroundColor3 = self.window.theme.sliderColor,
					BorderSizePixel = 0,
					Parent = self.main
				});
				table.insert(self.window.themeItems, {self.slider, "BackgroundColor3", "sliderColor"});

				self.window:Create("UICorner", {
					CornerRadius = UDim.new(0,3),
					Parent = self.slider
				});

				self.sliderBorder = self.window:Create("UIStroke", {
					Color = self.window.theme.sliderBorderColor,
					Parent = self.slider
				});
				table.insert(self.window.themeItems, {self.sliderBorder, "Color", "sliderBorderColor"});

				self.sliderBar = self.window:Create("Frame", {
					BackgroundColor3 = self.window.theme.sliderBarColor,
					BorderSizePixel = 0,
					Size = UDim2.new(0,0,1,1),
					Parent = self.slider
				});
				table.insert(self.window.themeItems, {self.sliderBar, "BackgroundColor3", "sliderBarColor"});

				self.window:Create("UICorner", {
					CornerRadius = UDim.new(0,3),
					Parent = self.sliderBar
				});

				self.sliderInput = self.window:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0,0,0.5,0),
					Size = UDim2.new(1,0,0,self.main.AbsoluteSize.Y-10),
					BackgroundTransparency = 1,
					Parent = self.slider
				});

				self.sliderValue = self.window:Create("TextLabel", {
					Text = self.value .. self.suffix,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextColor3 = self.window.theme.sliderValueColor,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1,0.5),
					Position = UDim2.new(0,-10,0.5,0),
					Size = UDim2.new(1,0,1,10),
					Font = self.window.theme.textFont,
					Parent = self.slider
				});
				table.insert(self.window.themeItems, {self.sliderValue, "Font", "textFont"});
				table.insert(self.window.themeItems, {self.sliderValue, "TextColor3", "sliderValueColor"});

				self.window:Connect(self.sliderInput.InputBegan, function(input, processed) 
					if input.UserInputType.Name == "MouseButton1" and not processed then
						self.dragging = true;
						self:Update();
					end
				end);

				self.window:Connect(inputService.InputEnded, function(input, processed) 
					if input.UserInputType.Name == "MouseButton1" and not processed then
						self.dragging = false;
					end
				end);

				self.window:Connect(inputService.InputChanged, function(input)
					if input.UserInputType.Name == "MouseMovement" and self.dragging then
						self:Update();
					end
				end);

				self.hasInit = true;
				self:Set(self.value);
			end

			if slider.flag then
				self.window.items[slider.flag] = slider;
			end

			table.insert(self.items, slider);
			return slider;
		end

		function section:AddToggle(options: table?)
			local toggle = {
				name = options and (options.name or options.Name) or "Toggle",
				default = options and (options.default or options.Default) or false,
				flag = options and (options.flag or options.Flag) or nil,
				callback = options and (options.callback or options.Callback) or nil,
				section = self,
				window = self.window,
				hasInit = false
			};
			
			toggle.value = toggle.default;

			function toggle:Set(value: boolean)
				assert(value ~= nil, "Missing argument #1 (boolean expected)");

				self.value = value;
				if self.callback then
					pcall(self.callback, self.value);
				end
				if self.flag then
					rawset(self.window.flags, self.flag, self.value);
				end
				if self.hasInit then
					tweenService:Create(self.tickBox, TweenInfo.new(0.1), {
						ImageTransparency = self.value and 0 or 1,
						BackgroundColor3 = self.value and
							self.window.theme.toggleActiveColor or
							self.window.theme.toggleColor;
					}):Play();
				end
			end

			function toggle:Get()
				return self.value;
			end

			function toggle:Init()
				assert(not self.hasInit, "Item has already initialized");

				self.main = self.window:Create("Frame", {
					Size = UDim2.new(1,0,0,30),
					BorderSizePixel = 0,
					BackgroundColor3 = self.window.theme.sectionItemColor,
					Parent = self.section.itemHolder
				});
				table.insert(self.window.themeItems, {self.main, "BackgroundColor3", "sectionItemColor"});

				self.window:Create("UICorner", {
					CornerRadius = UDim.new(0,5),
					Parent = self.main
				});

				self.title = self.window:Create("TextLabel", {
					Text = self.name,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = self.window.theme.sectionItemTextColor,
					Position = UDim2.new(0,5,0,5),
					Size = UDim2.new(0.5,-10,1,-10),
					BackgroundTransparency = 1,
					Font = self.window.theme.textFont,
					Parent = self.main
				});
				table.insert(self.window.themeItems, {self.title, "Font", "textFont"});
				table.insert(self.window.themeItems, {self.title, "TextColor3", "sectionItemTextColor"});

				self.tickBox = self.window:Create("ImageLabel", {
					Image = "rbxassetid://9754130783",
					ImageColor3 = self.window.theme.toggleColor,
					BackgroundColor3 = self.window.theme.toggleColor,
					AnchorPoint = Vector2.new(1,0.5),
					Position = UDim2.new(1,-5,0.5,0),
					BorderSizePixel = 0,
					Size = UDim2.new(0,self.main.AbsoluteSize.Y-10,1,-10),
					Parent = self.main,
				});
				table.insert(self.window.themeItems, {self.tickBox, "BackgroundColor3", "toggleColor"});
				table.insert(self.window.themeItems, {self.tickBox, "ImageColor3", "toggleColor"});

				self.window:Create("UICorner", {
					CornerRadius = UDim.new(0,5),
					Parent = self.tickBox
				});

				self.tickBoxBorder = self.window:Create("UIStroke", {
					Color = self.window.theme.toggleBorderColor,
					Parent = self.tickBox
				});
				table.insert(self.window.themeItems, {self.tickBoxBorder, "Color", "toggleBorderColor"});

				self.window:Connect(self.main.InputBegan, function(input, processed)
					if input.UserInputType.Name == "MouseButton1" and not processed then
						self:Set(not self.value);
					end
				end);

				self.hasInit = true;
				self:Set(self.value);
			end

			if toggle.flag then
				self.window.items[toggle.flag] = toggle;
			end

			table.insert(self.items, toggle);
			return toggle;
		end

		function section:Init()
			assert(not self.hasInit, "Item has already initialized");

			self.main = self.window:Create("Frame", {
				Size = UDim2.new(1,0,0,20),
				BackgroundTransparency = 1,
				Parent = self.tab.sectionHolder
			});

			self.title = self.window:Create("TextLabel", {
				Text = self.title,
				TextScaled = true,
				TextColor3 = self.window.theme.sectionTextColor,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Font = self.window.theme.textFont,
				Size = UDim2.new(1,0,0,20),
				Parent = self.main,
			});
			table.insert(self.window.themeItems, {self.title, "Font", "textFont"});
			table.insert(self.window.themeItems, {self.title, "TextColor3", "sectionTextColor"});

			self.itemHolder = self.window:Create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0,0,0,self.title.AbsoluteSize.Y),
				Parent = self.main,
			});

			self.listLayout = self.window:Create("UIListLayout", {
				Padding = UDim.new(0,5),
				Parent = self.itemHolder
			});

			self.window:Connect(self.itemHolder.Changed, function()
				self.itemHolder.Size = UDim2.new(1,0,0,self.listLayout.AbsoluteContentSize.Y);
				self.main.Size = UDim2.new(1,0,0,
					self.title.AbsoluteSize.Y +
						self.itemHolder.AbsoluteSize.Y
				);
			end);

			for _, item in next, self.items do
				item:Init();
			end

			self.hasInit = true;
		end

		table.insert(self.sections, section);
		return section;
	end

	function tab:Select()
		self.window.selectedTab = self;
		if self.hasInit then
			self.sectionHolder.Visible = true;
			tweenService:Create(self.main, TweenInfo.new(0.2), {
				TextTransparency = 0,
				BackgroundTransparency = 0
			}):Play();
		end
		for _, tab in next, self.window.tabs do
			if tab ~= self then
				tab:Deselect();
			end
		end
	end

	function tab:Deselect()
		if self.hasInit then
			self.sectionHolder.Visible = false;
			tweenService:Create(self.main, TweenInfo.new(0.2), {
				TextTransparency = 0.5,
				BackgroundTransparency = 0.7
			}):Play();
		end
	end

	function tab:Init()
		assert(not self.hasInit, "Item has already initialized");

		self.main = self.window:Create("TextButton", {
			TextScaled = true,
			AutoButtonColor = false,
			Font = self.window.theme.textFont,
			Text = self.title,
			Size = UDim2.new(1,0,0,20),
			TextColor3 = self.window.theme.menuButtonColor,
			BackgroundTransparency = 0.7,
			BackgroundColor3 = self.window.theme.tabButtonColor,
			TextTransparency = self.window.selectedTab == self and 0 or 0.5,
			Parent = self.window.tabHolder
		});
		table.insert(self.window.themeItems, {self.main, "BackgroundColor3", "tabButtonColor"});
		table.insert(self.window.themeItems, {self.main, "Font", "textFont" });
		table.insert(self.window.themeItems, {self.main, "TextColor3", "menuButtonColor" });

		self.window:Create("UICorner", {
			CornerRadius = UDim.new(0,4),
			Parent = self.main
		});

		self.tabOutline = self.window:Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = self.window.theme.tabButtonOutline,
			Parent = self.main
		});
		table.insert(self.window.themeItems, {self.tabOutline, "Color", "tabButtonOutline"});

		self.sectionHolder = self.window:Create("ScrollingFrame", {
			ScrollBarThickness = 0,
			Position = UDim2.new(0,0,0,self.window.top.AbsoluteSize.Y),
			Size = UDim2.new(1,0,1,-self.window.top.AbsoluteSize.Y),
			BackgroundTransparency = 1,
			Visible = self.window.selectedTab == self,
			Parent = self.window.main
		});

		self.listLayout = self.window:Create("UIListLayout", {
			Padding = UDim.new(0,10),
			Parent = self.sectionHolder 
		});

		self.uiPadding = self.window:Create("UIPadding", {
			PaddingLeft = UDim.new(0,10),
			PaddingRight = UDim.new(0,10),
			PaddingBottom = UDim.new(0,10),
			Parent = self.sectionHolder 
		});

		self.window:Connect(self.sectionHolder.Changed, function()
			self.sectionHolder.CanvasSize = UDim2.new(1,0,0,
				self.uiPadding.PaddingTop.Offset +
					self.uiPadding.PaddingBottom.Offset +
					self.listLayout.AbsoluteContentSize.Y
			);
		end);

		self.window:Connect(self.main.MouseButton1Down, function()
			self:Select();
		end);

		for _, section in next, self.sections do
			section:Init();
		end

		self.hasInit = true;
	end

	self.selectedTab = tab;
	table.insert(self.tabs, tab);
	return tab;
end

function Window:Init()
	assert(not self.hasInit, "Item has already initialized");

	self.base = self:Create("ScreenGui", {
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = gethui and gethui() or coreGui
	});

	self.main = self:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = self.theme.backgroundColor,
		BorderSizePixel = 0,
		Parent = self.base
	});
	table.insert(self.themeItems, {self.main, "BackgroundColor3", "backgroundColor" });

	self:Create("UICorner", { Parent = self.main });

	self.top = self:Create("Frame", {
		BackgroundColor3 = self.theme.topColor,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 25),
		ZIndex = 2,
		Parent = self.main
	});
	table.insert(self.themeItems, {self.top, "BackgroundColor3", "topColor" });

	self:Create("UICorner", { Parent = self.top });

	self.leftBlock = self:Create("Frame", {
		AnchorPoint = Vector2.new(0,1),
		Position = UDim2.new(0,0,1,0),
		Size = UDim2.new(0,8,0,8),
		BorderSizePixel = 0,
		BackgroundColor3 = self.theme.topColor,
		Parent = self.top
	});
	table.insert(self.themeItems, {self.leftBlock, "BackgroundColor3", "topColor"});

	self.rightBlock = self:Create("Frame", {
		AnchorPoint = Vector2.new(1,1),
		Position = UDim2.new(1,0,1,0),
		Size = UDim2.new(0,8,0,8),
		BorderSizePixel = 0,
		BackgroundColor3 = self.theme.topColor,
		Parent = self.top
	});
	table.insert(self.themeItems, {self.rightBlock, "BackgroundColor3", "topColor"});

	self.line = self:Create("Frame", {
		BorderSizePixel = 0,
		BackgroundColor3 = self.theme.lineColor,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = self.top
	});
	table.insert(self.themeItems, {self.line, "BackgroundColor3", "lineColor"});

	self.menuButton = self:Create("ImageButton", {
		Image = "rbxassetid://7347408509",
		BackgroundTransparency = 1,
		ImageColor3 = self.theme.topButtonColor,
		Position = UDim2.new(0,1.5,0,1.5),
		Size = UDim2.new(0,self.top.AbsoluteSize.Y-3,1,-3),
		Parent = self.top
	});
	table.insert(self.themeItems, {self.menuButton, "ImageColor3", "topButtonColor" });

	self.titleLabel = self:Create("TextLabel", {
		Text = self.title,
		TextColor3 = self.theme.titleColor,
		TextTransparency = 0.2,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		Font = self.theme.textFont,
		Parent = self.top
	});
	table.insert(self.themeItems, {self.titleLabel, "Font", "textFont" });
	table.insert(self.themeItems, {self.titleLabel, "TextColor3", "titleColor" });

	self.closeButton = self:Create("ImageButton", {
		Image = "rbxassetid://10002373478",
		BackgroundTransparency = 1,
		ImageColor3 = self.theme.topButtonColor,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,0,0,0),
		Size = UDim2.new(0,self.top.AbsoluteSize.Y,1,0),
		Parent = self.top
	});
	table.insert(self.themeItems, {self.closeButton, "ImageColor3", "topButtonColor" });

	self.miniButton = self:Create("ImageButton", {
		Image = "rbxassetid://3517304301",
		BackgroundTransparency = 1,
		ImageColor3 = self.theme.topButtonColor,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1,-self.closeButton.AbsoluteSize.X,0,0),
		Size = UDim2.new(0,self.top.AbsoluteSize.Y,1,0),
		SliceScale = 5,
		Parent = self.top
	});
	table.insert(self.themeItems, {self.miniButton, "ImageColor3", "topButtonColor" });

	self.tabHolder = self:Create("Frame", {
		BorderSizePixel = 0,
		BackgroundColor3 = self.theme.menuColor,
		Size = UDim2.new(0,0,1,-self.top.AbsoluteSize.Y),
		Position = UDim2.new(0,0,0,self.top.AbsoluteSize.Y),
		ZIndex = 2,
		Visible = false,
		Parent = self.main
	});
	table.insert(self.themeItems, {self.tabHolder, "BackgroundColor3", "menuColor" });

	self:Create("UIListLayout", {
		Padding = UDim.new(0,5),
		Parent = self.tabHolder
	 });
	self:Create("UIPadding", {
		PaddingTop = UDim.new(0,5),
		PaddingBottom = UDim.new(0,5),
		PaddingLeft = UDim.new(0,5),
		PaddingRight = UDim.new(0,5),
		Parent = self.tabHolder
	});

	self:Connect(self.menuButton.MouseButton1Down, function()
		if self.menuOpen then
			local tween = tweenService:Create(self.tabHolder, TweenInfo.new(0.2), {
				Size = UDim2.new(0,0,1,-self.top.AbsoluteSize.Y),
			});
			tween:Play();
			tween.Completed:Connect(function()
				self.tabHolder.Visible = false;
			end);
		else
			self.tabHolder.Visible = true;
			tweenService:Create(self.tabHolder, TweenInfo.new(0.2), {
				Size = UDim2.new(0.3,0,1,-self.top.AbsoluteSize.Y),
			}):Play();
		end
		self.menuOpen = not self.menuOpen;
	end);

	self:Connect(self.closeButton.MouseButton1Down, function()
		local tween = tweenService:Create(self.main, TweenInfo.new(0.5), {
			Size = UDim2.new()
		});
		tween:Play();
		tween.Completed:Wait();
		self:Unload();
	end);

	self:Connect(self.miniButton.MouseButton1Down, function()
		if not self.minimizing then
			self.minimizing = true;
			changeAnchor(self.main, Vector2.new(0.5, 0));
			if self.minimized then
				tweenService:Create(self.main, TweenInfo.new(0.2), {
					Size = vector2ToUDim2(self.size)
				}):Play();
			else
				tweenService:Create(self.main, TweenInfo.new(0.2), {
					Size = UDim2.new(0, self.size.X, 0, self.top.AbsoluteSize.Y)
				}):Play();
			end
			self.minimized = not self.minimized;
			self.rightBlock.Visible = not self.minimized;
			self.leftBlock.Visible = not self.minimized;
			self.line.Visible = not self.minimized;
			task.wait(0.2);
			changeAnchor(self.main, Vector2.new(0.5, 0.5));
		end
		self.minimizing = false;
	end);

	self:Connect(self.top.InputBegan, function(input)
		if input.UserInputType.Name == "MouseButton1" then
			self.dragging = true;
			self.offset = udim2ToVector2(self.main.Position) - inputService:GetMouseLocation();
		end
	end);

	self:Connect(inputService.InputEnded, function(input)
		if input.UserInputType.Name == "MouseButton1" then
			self.dragging = false;
		end
	end);

	self:Connect(inputService.InputChanged, function(input)
		if input.UserInputType.Name == "MouseMovement" and self.dragging then
			self.main.Position = vector2ToUDim2(inputService:GetMouseLocation() + self.offset);
		end
	end);

	for _, tab in next, self.tabs do
		tab:Init();
	end

	tweenService:Create(self.main, TweenInfo.new(0.5), {
		Size = vector2ToUDim2(self.size)
	}):Play();

	self.hasInit = true;
end

return Window;
