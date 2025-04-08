









---
local PointOfInterest_mt = Class(PointOfInterest)


---
function PointOfInterest.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX,  basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.STRING,  basePath .. "#text", "POI text")
    schema:register(XMLValueType.STRING,  basePath .. "#textFormat", "POI text additional format string")
    schema:register(XMLValueType.STRING,  basePath .. "#textParams", "POI text format parameters")
    schema:register(XMLValueType.BOOL,  basePath .. "#showOwner", "Show only for owners")
    schema:register(XMLValueType.BOOL,  basePath .. "#showEveryone", "Show everyone")
end
