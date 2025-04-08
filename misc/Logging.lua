





























---Prints a xml warning to console and logfile, prepends 'Warning (<xmlFilename>):'
-- @param table|integer|string xmlFile xml file object or xml handle
-- @param string warningMessage the warning message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in warning message
function Logging.xmlWarning(xmlFile, warningMessage, ...)
    local filename = getFilename(xmlFile)
    printWarning(string.format("  Warning (%s): "..warningMessage, filename, ...))
end


---Prints a xml error to console and logfile, prepends 'Error (<xmlFilename>):'
-- @param table|integer|string xmlFile xml file object or xml handle
-- @param string errorMessage the error message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in error message
function Logging.xmlError(xmlFile, errorMessage, ...)
    local filename = getFilename(xmlFile)
    printError(string.format("  Error (%s): "..errorMessage, filename, ...))
end


---Prints a xml info to console and logfile, prepends 'Info (<xmlFilename>):'
-- @param table|integer|string xmlFile xml file object or xml handle
-- @param string infoMessage the warning message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in warning message
function Logging.xmlInfo(xmlFile, infoMessage, ...)
    local filename = getFilename(xmlFile)
    print(string.format("  Info (%s): "..infoMessage, filename, ...))
end


---Prints an i3d node warning to console and logfile, prepends 'Warning (<nodeNamePath> (<nodeIndexPath>)):'
-- @param entityId node i3d node entityId to include in the output
-- @param string warningMessage the warning message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in warning message
function Logging.i3dWarning(node, warningMessage, ...)
    local nodeStr = I3DUtil.getNodeNameAndIndexPath(node)
    printWarning(string.format("  Warning (%s): "..warningMessage, nodeStr, ...))
end


---Prints an i3d node error to console and logfile, prepends 'Error (<nodeNamePath> (<nodeIndexPath>)):'
-- @param entityId node i3d node entityId to include in the output
-- @param string errorMessage the error message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in error message
function Logging.i3dError(node, errorMessage, ...)
    local nodeStr = I3DUtil.getNodeNameAndIndexPath(node)
    printError(string.format("  Error (%s): "..errorMessage, nodeStr, ...))
end


---Prints an i3d node info to console and logfile, prepends 'Info (<nodeNamePath> (<nodeIndexPath>)):'
-- @param entityId node i3d node entityId to include in the output
-- @param string infoMessage the warning message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in warning message
function Logging.i3dInfo(node, infoMessage, ...)
    local nodeStr = I3DUtil.getNodeNameAndIndexPath(node)
    print(string.format("  Info (%s): "..infoMessage, nodeStr, ...))
end





































---Prints a warning to console and logfile, prepends 'Warning:'
-- @param string warningMessage the warning message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in warning message
function Logging.warning(warningMessage, ...)
    printWarning(string.format("  Warning: "..warningMessage, ...))
end


---Prints an error to console and logfile, prepends 'Error:'
-- @param string errorMessage the warning message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in warning message
function Logging.error(errorMessage, ...)
    printError(string.format("  Error: "..errorMessage, ...))
end


---Prints an info to console and logfile, prepends 'Info:'
-- @param string infoMessage the warning message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in warning message
function Logging.info(infoMessage, ...)
    print(string.format("  Info: "..infoMessage, ...))
end



---Prints an fatal error to console and logfile and stops the game. To be used for unrecoverable errors only
-- @param string fatalMessage the error message. Can contain string-format placeholders
-- @param any ... variable number of parameters. Depends on placeholders in fatal message
function Logging.fatal(fatalMessage, ...)
    local message = string.format("  Fatal Error: "..fatalMessage, ...)
    printCallstack()
    requestExit()
    error(message) -- break script execution
end
