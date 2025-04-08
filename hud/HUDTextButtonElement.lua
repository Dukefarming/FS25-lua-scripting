








---A simple text button that can be used in the HUD. Use left-alt to release the mouse.
local HUDTextButtonElement_mt = Class(HUDTextButtonElement)













































---Set the text to display.
-- @param string text Display text.
-- @param float textSize Text size in reference resolution pixels.
-- @param integer textAlignment Text alignment as one of RenderText.[ALIGN_LEFT | ALIGN_CENTER | ALIGN_RIGHT].
-- @param table textColor Text display color as an array {r, g, b, a}.
-- @param boolean textBool If true, will render the text in bold.
function HUDTextButtonElement:setText(text, textSize, textAlignment, textColor, textBold)
    self.textDisplay:setText(text, textSize, textAlignment, textColor, textBold)
end
