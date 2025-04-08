





















---
local ChatDisplay_mt = Class(ChatDisplay, HUDDisplay)


---Create a new ChatDisplay.
-- @return table ChatDisplay instance
function ChatDisplay.new()
    local self = ChatDisplay:superClass().new(ChatDisplay_mt)

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.chat_middle", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgTop = g_overlayManager:createOverlay("gui.chat_top", 0, 0, 0, 0)
    self.bgTop:setColor(r, g, b, a)
    self.bgBottom = g_overlayManager:createOverlay("gui.chat_bottom", 0, 0, 0, 0)
    self.bgBottom:setColor(r, g, b, a)

    self.messages = {} -- reference to chat message history owned by mission object
    self.maxNumMessages = 50
    self.scrollOffset = 0
    self.closeTime = 0
    self.duration = 10 * 1000

    return self
end








---Store scaled positioning, size and offset values.
function ChatDisplay:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 300)
    self:setPosition(g_hudAnchorLeft + offsetX, g_hudAnchorBottom + offsetY)

    local bgWidth, bgBottomHeight = self:scalePixelValuesToScreenVector(300, 6)
    local bgTopHeight = self:scalePixelToScreenHeight(6)
    self.bgBottom:setDimension(bgWidth, bgBottomHeight)
    self.bgTop:setDimension(bgWidth, bgTopHeight)
    self.bgScale:setDimension(bgWidth, 0)

    self.messageOffsetY = self:scalePixelToScreenHeight(5)

    self.textOffsetX, self.textOffsetY = self:scalePixelValuesToScreenVector(6, -28)
    self.textSize = self:scalePixelToScreenHeight(12)
    self.maxTextWidth = bgWidth - 2*self.textOffsetX

    self.maxHeight = self:scalePixelToScreenHeight(300)

    self.titleOffsetX, self.titleOffsetY = self:scalePixelValuesToScreenVector(6, -13)
    self.titleHeight = self:scalePixelToScreenHeight(20)
    self.titleTextSize = self:scalePixelToScreenHeight(13)
end



































































































---Scroll chat messages by a given amount.
-- @param integer delta messages (positive or negative) to scroll
function ChatDisplay:scrollChatMessages(delta)
    self.scrollOffset = math.clamp(self.scrollOffset + delta, 0, math.max(0, #self.messages-1))
end
