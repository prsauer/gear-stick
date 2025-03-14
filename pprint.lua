
local function debug(tbl)
	for key, value in pairs(tbl) do
		print(key, value)
	end
end

local function pprint(tbl)
	-- Create the frame if it doesn't exist
	if not PPrintFrame then
		local frame = CreateFrame("Frame", "PPrintFrame", UIParent, "BackdropTemplate,ResizeLayoutFrame")
		frame:SetSize(800, 600)
		frame:SetPoint("CENTER")
		frame:SetFrameStrata("DIALOG")
		frame:SetResizable(true)
		
		-- Set resize bounds
		frame:SetResizeBounds(400, 300, 1200, 900)  -- min width, min height, max width, max height
		
		-- Set up the backdrop
		frame:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		frame:SetBackdropColor(0, 0, 0, 0.9)
		frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
		
		-- Add a title
		frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		frame.title:SetPoint("TOPLEFT", 8, -8)
		frame.title:SetText("Table Contents")
		
		-- Create the scroll frame
		local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", 8, -30)
		scrollFrame:SetPoint("BOTTOMRIGHT", -30, 8)
		
		-- Create the content frame
		local content = CreateFrame("Frame", nil, scrollFrame)
		content:SetSize(740, 50)
		scrollFrame:SetScrollChild(content)
		frame.content = content
		
		-- Add resize button
		local resizeButton = CreateFrame("Button", nil, frame)
		resizeButton:SetSize(32, 32)
		resizeButton:SetPoint("BOTTOMRIGHT")
		
		-- Create and set the resize button texture
		local resizeTexture = resizeButton:CreateTexture(nil, "OVERLAY")
		resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		resizeTexture:SetAllPoints()
		resizeButton:SetNormalTexture(resizeTexture)
		
		-- Add highlight texture
		local highlightTexture = resizeButton:CreateTexture(nil, "HIGHLIGHT")
		highlightTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		highlightTexture:SetAllPoints()
		resizeButton:SetHighlightTexture(highlightTexture)
		
		resizeButton:EnableMouse(true)
		
		resizeButton:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				frame:StartSizing("BOTTOMRIGHT")
			end
		end)
		
		resizeButton:SetScript("OnMouseUp", function(self, button)
			frame:StopMovingOrSizing()
			-- Update content frame width when resizing
			local width, height = frame:GetSize()
			frame.content:SetSize(width - 60, frame.content:GetHeight())
		end)
		
		-- Add close button
		local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
		
		-- Make the frame movable
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
		
		PPrintFrame = frame
	end
	
	-- Clear existing content
	for _, child in pairs({PPrintFrame.content:GetChildren()}) do
		child:Hide()
		child:SetParent(nil)
	end
	
	-- Function to recursively format table contents
	local function formatTable(t, indent)
		if type(t) ~= "table" then
			return {tostring(t)}
		end
		
		indent = indent or 0
		local result = {}
		local indentStr = string.rep("    ", indent)
		
		for k, v in pairs(t) do
			local key = tostring(k)
			if type(v) == "table" then
				table.insert(result, indentStr .. key .. " = {")
				local subTable = formatTable(v, indent + 1)
				for _, line in ipairs(subTable) do
					table.insert(result, line)
				end
				table.insert(result, indentStr .. "}")
			else
				table.insert(result, indentStr .. key .. " = " .. tostring(v))
			end
		end
		
		if #result == 0 then
			table.insert(result, indentStr .. "(empty table)")
		end
		
		return result
	end
	
	-- Format the table contents
	local lines = formatTable(tbl)
	
	-- Debug print
	print("Number of lines to display:", #lines)
	
	-- Create and position text lines
	local yOffset = 0
	for i, line in ipairs(lines) do
		local textLine = PPrintFrame.content:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		textLine:SetText(line)
		textLine:SetJustifyH("LEFT")
		textLine:SetPoint("TOPLEFT", PPrintFrame.content, "TOPLEFT", 0, -yOffset)
		textLine:SetWidth(700)
		
		-- Debug print
		print("Creating line:", line)
		
		yOffset = yOffset + 15 -- Increment offset for next line
	end
	
	-- Set content height to total height of all lines
	PPrintFrame.content:SetHeight(math.max(yOffset, 50))
	
	-- Show the frame
	PPrintFrame:Show()
end