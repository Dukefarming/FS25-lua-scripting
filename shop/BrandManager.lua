










---This class handles all registered brands
local BrandManager_mt = Class(BrandManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function BrandManager.new(customMt)
    local self = AbstractManager.new(customMt or BrandManager_mt)

    addConsoleCommand("gsBrandUsageList", "Prints a list of all used brands", "consoleCommandBrandUsageList", self)

    return self
end


---Initialize data structures
function BrandManager:initDataStructures()
    self.numOfBrands = 0
    self.nameToIndex = {}
    self.nameToBrand = {}
    self.indexToBrand = {}

    Brand = self.nameToIndex
end


---Load data on map load
-- @return boolean true if loading was successful else false
function BrandManager:loadMapData(missionInfo)
    BrandManager:superClass().loadMapData(self)

    local xmlFile = XMLFile.load("brandsXML", "dataS/brands.xml")

    for _, brandKey in xmlFile:iterator("brands.brand") do
        local name = xmlFile:getString(brandKey .. "#name")
        local title = xmlFile:getString(brandKey .. "#title")
        local image = xmlFile:getString(brandKey .. "#image")
        local imageShopOverview = xmlFile:getString(brandKey .. "#imageShopOverview")
        local imageOffset = xmlFile:getFloat(brandKey .. "#imageOffset")

        if title ~= nil and string.startsWith(title, "$l10n_") then
            title = g_i18n:getText(title:sub(7))
        end

        self:addBrand(name, title, image, "", false, imageShopOverview, imageOffset)
    end

    xmlFile:delete()

    return true
end


---Adds a new band
-- @param string name the mapping name .e.g "HORSCH" for accessing a brand using the Brand.HORSCH enumeration
-- @param string title the displayed name of the brand in ui
-- @param string imageFilename the brand icon
-- @param string baseDir the image filename base directory
-- @param boolean isMod is a mod brand
-- @param string? imageShopOverview the brand icon for shop overview
-- @param float? imageOffset percentage [0..1] of the transparent pixels on the side of the icon used for aligning it in UI
-- @return table? brand
function BrandManager:addBrand(name, title, imageFilename, baseDir, isMod, imageShopOverview, imageOffset)
    if name == nil or name == "" then
        Logging.warning("Could not register brand. Name is missing or empty!")
        return false
    end
    if title == nil or title == "" then
        Logging.warning("Could not register brand '%s'. Title is missing or empty!", name)
        return false
    end
    if imageFilename == nil or imageFilename == "" then
        Logging.warning("Could not register brand '%s'. Image is missing or empty!", name)
        return false
--#debug else
--#debug    local fullFilename = Utils.getFilename(imageFilename, baseDir)
--#debug    if not textureFileExists(fullFilename) then
--#debug        Logging.devWarning("Defined image file for brand '%s' not found! (%s)", name, fullFilename)
--#debug    end
    end
    if baseDir == nil then
        Logging.warning("Could not register brand '%s'. Base directory not defined!", name)
        return false
    end
    if imageShopOverview == nil then
        -- use default image if no specific shop overview icon is available
        imageShopOverview = imageFilename
--#debug else
--#debug    local fullFilename = Utils.getFilename(imageShopOverview, baseDir)
--#debug    if not textureFileExists(fullFilename) then
--#debug        Logging.devWarning("Defined shop overview image file for brand '%s' not found! (%s)", name, fullFilename)
--#debug    end
    end

    name = name:upper()

    if ClassUtil.getIsValidIndexName(name) then
        if self.nameToIndex[name] == nil then
            self.numOfBrands = self.numOfBrands + 1
            self.nameToIndex[name] = self.numOfBrands

            local brand = {}
            brand.index = self.numOfBrands
            brand.name = name
            brand.image = Utils.getFilename(imageFilename, baseDir)
            brand.imageShopOverview = Utils.getFilename(imageShopOverview, baseDir)
            brand.title = title
            brand.isMod = isMod
            brand.imageOffset = imageOffset or 0

            self.nameToBrand[name] = brand
            self.indexToBrand[self.numOfBrands] = brand

            return brand
        end

        return nil -- brand already present
    else
        Logging.warning("Invalid brand name '" .. tostring(name) .. "'! Only capital letters allowed!")
        return nil
    end
end


---Gets brand by index
-- @param integer brandIndex brand index
-- @return table brand the brand object
function BrandManager:getBrandByIndex(brandIndex)
    if brandIndex ~= nil then
        return self.indexToBrand[brandIndex]
    end
    return nil
end


---Gets brand icon by index
-- @param integer brandIndex brand index
-- @return string path path to brand icon
function BrandManager:getBrandIconByIndex(brandIndex)
    if brandIndex ~= nil and self.indexToBrand[brandIndex] ~= nil then
        return self.indexToBrand[brandIndex].image
    end
    return nil
end


---Gets brand by name
-- @param string brandName brand name
-- @return table brand the brand object
function BrandManager:getBrandByName(brandName)
    if brandName ~= nil then
        return self.nameToBrand[brandName:upper()]
    end
    return nil
end


---Gets brand index by name
-- @param string brandName brand name
-- @return integer brandIndex the brand index
function BrandManager:getBrandIndexByName(brandName)
    if brandName ~= nil then
        if ClassUtil.getIsValidIndexName(brandName) then
            local brandIndex = self.nameToIndex[brandName:upper()]
            if brandIndex == nil then
                local bestMatch = Utils.getClosestMatchingString(brandName, table.toList(self.nameToBrand), 3)
                local suggestions = bestMatch and string.format(" Did you mean '%s'?", bestMatch) or ""
                Logging.warning("'%s' is an unknown brand!%s Using 'LIZARD' instead!", brandName, suggestions)
                return Brand.LIZARD
            end

            return brandIndex
        else
            Logging.warning("Invalid brand name '" .. brandName .. "'! Only capital letters and underscores allowed. Using Lizard instead.")
            return Brand.LIZARD
        end
    end

    return nil
end
