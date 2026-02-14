local httpService = game:GetService('HttpService')
local ThemeManager = {} do
	ThemeManager.Folder = 'SodiumLibSettings'
	-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['SodiumDefault']	= { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"00baff","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['SodiumMidnight']	= { 2, httpService:JSONDecode('{"FontColor":"ebebeb","MainColor":"121216","AccentColor":"00baff","BackgroundColor":"0e0e12","OutlineColor":"2a2a34"}') },
		['SodiumIce']		= { 3, httpService:JSONDecode('{"FontColor":"ebf5ff","MainColor":"10181c","AccentColor":"00d2ff","BackgroundColor":"0c1216","OutlineColor":"263842"}') },
		['SodiumRose']		= { 4, httpService:JSONDecode('{"FontColor":"fff0f5","MainColor":"1c1216","AccentColor":"ff5a8c","BackgroundColor":"160e12","OutlineColor":"3c2830"}') },
	}

	function ThemeManager:ApplyTheme(theme)
		local data = self.BuiltInThemes[theme]

		if not data then return end

		-- custom themes are just regular dictionaries instead of an array with { index, dictionary }

		local scheme = data[2]
		for idx, col in next, scheme do
			self.Library[idx] = Color3.fromHex(col)
			
			if Options[idx] then
				Options[idx]:SetValueRGB(Color3.fromHex(col))
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		-- This allows us to force apply themes without loading the themes tab :)
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		if content and self.BuiltInThemes[content] then
			theme = content
		end

		Options.ThemeManager_ThemeList:SetValue(theme)
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = self.Library.MainColor });
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });

		groupbox:AddToggle('RGBAccent', {
			Text = 'RGB Accent (Animated)',
			Default = false,
			Tooltip = 'Animates the AccentColor using a rainbow loop',
			Callback = function(Value)
				self.Library:ToggleRGB(Value, 3)
			end
		})

		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = self.Library.FontColor });

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })
		groupbox:AddButton('Reset theme', function()
			local theme = Options.ThemeManager_ThemeList and Options.ThemeManager_ThemeList.Value
			if type(theme) ~= 'string' then
				theme = 'SodiumMidnight'
			end
			pcall(function()
				if Toggles and Toggles.RGBAccent and Toggles.RGBAccent.Type == 'Toggle' then
					Toggles.RGBAccent:SetValue(false)
				end
			end)
			self:ApplyTheme(theme)
			self.Library:Notify(string.format('Reset theme to %q', theme), 3)
		end)

		groupbox:AddButton('Set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value))
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.MainColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.OutlineColor:OnChanged(UpdateTheme)
		Options.FontColor:OnChanged(UpdateTheme)
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
		-- Keep AccentColor picker in sync with RGB accent changes
		if self.Library then
			self.Library.OnAccentColorChanged = function(color)
				if Options and Options.AccentColor and Options.AccentColor.Type == 'ColorPicker' then
					Options.AccentColor.Value = color
					pcall(function()
						Options.AccentColor:SetHSVFromRGB(color)
					end)
					pcall(function()
						Options.AccentColor:Display()
					end)
					self:ThemeUpdate()
				end
			end
		end
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		-- build the entire tree if a path is like some-hub/phantom-forces
		-- makefolder builds the entire tree on Synapse X but not other exploits

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')
		table.insert(paths, self.Folder .. '/settings')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
