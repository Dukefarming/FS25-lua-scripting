








---
local BgaSellStation_mt = Class(BgaSellStation, UnloadingStation)










































---
function BgaSellStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#appearsOnStats", "Appears on stats page", false)

    UnloadingStation.registerXMLPaths(schema, basePath)
end
