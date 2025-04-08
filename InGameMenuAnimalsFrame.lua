









---In-game menu animals statistics frame.
-- 
-- Displays information for all owned animal pens and horses.
-- 
local InGameMenuAnimalsFrame_mt = Class(InGameMenuAnimalsFrame, TabbedMenuFrameElement)






















































---
function InGameMenuAnimalsFrame:delete()
    for k, clone in pairs(self.subCategoryDotBox.elements) do
        clone:delete()
        self.subCategoryDotBox.elements[k] = nil
    end

    self.subCategoryDotTemplate:delete()

    InGameMenuAnimalsFrame:superClass().delete(self)
end
