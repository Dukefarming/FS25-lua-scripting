








---
local DigitalDisplay_mt = Class(DigitalDisplay)
























---
function DigitalDisplay.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#baseNode", "Base node", false)
    schema:register(XMLValueType.INT, basePath .. "#precision", "Precision", 0)
    schema:register(XMLValueType.BOOL, basePath .. "#showZero", "Show zeros or hide them", true)
end
