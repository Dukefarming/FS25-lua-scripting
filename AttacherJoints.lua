





































---Returns the closest lower link category for a given width
-- @return int index category index (0-4)
function AttacherJoints.getClosestLowerLinkCategoryIndex(width)
    local minDistance, index = math.huge, 1
    for categoryIndex, categoryWidth in pairs(AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY) do
        local distance = math.abs(width - categoryWidth)
        if distance < minDistance then
            minDistance = distance
            index = categoryIndex
        end
    end

    return index
end


---
function AttacherJoints.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("attacherJoint", g_i18n:getText("configuration_attacherJoint"), "attacherJoints", VehicleConfigurationItem)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AttacherJoints")

    AttacherJoints.registerAttacherJointXMLPaths(schema, "vehicle.attacherJoints")

    SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "hydraulic")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "attach")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "detach")

    schema:register(XMLValueType.FLOAT, "vehicle.attacherJoints#comboDuration", "Combo duration", 2)

    schema:register(XMLValueType.INT, "vehicle.attacherJoints#connectionHoseConfigId", "Connection hose configuration index to use")
    schema:register(XMLValueType.INT, "vehicle.attacherJoints#powerTakeOffConfigId", "Power take off configuration index to use")
    schema:register(XMLValueType.INT, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)#connectionHoseConfigId", "Connection hose configuration index to use")
    schema:register(XMLValueType.INT, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)#powerTakeOffConfigId", "Power take off configuration index to use")

    schema:register(XMLValueType.FLOAT, "vehicle.attacherJoints#maxUpdateDistance", "Max. distance to vehicle root to update attacher joint graphics", AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE)

    schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#attacherJointIndices", "Group is only active if something is attached to those joints (List if indices of the attacher joint in xml)")
    schema:register(XMLValueType.NODE_INDICES, Dashboard.GROUP_XML_KEY .. "#attacherJointNodes", "Group is only active if something is attached to those joints (List of attacherJoint nodes)")

    schema:register(XMLValueType.VECTOR_N, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. ".heightNode(?)#disablingAttacherJointIndices", "Attacher joint indices that disable height node if something is attached")
    schema:register(XMLValueType.VECTOR_N, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. ".heightNode(?)#disablingAttacherJointIndices", "Attacher joint indices that disable height node if something is attached")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints#comboDirection", "Current combo direction")

    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#jointIndex", "Index of attacherJoint")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#moveDown", "Attacher joint is lowered or not")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#attachedVehicleUniqueId", "Unique id of attached vehicle")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attachedImplement(?)#inputJointIndex", "Index of input attacher joint on the attached vehicle")

    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints.attacherJoint(?)#jointIndex", "Index of attacherJoint")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).attacherJoints.attacherJoint(?)#isBlocked", "Attacher joint is blocked or not")

    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?)#rootVehicleId", "Root vehicle id")
    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#attachmentId", "Attachment vehicle id")
    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#inputJointDescIndex", "Index of input attacher joint", 1)
    schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#jointIndex", "Index of attacher joint")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.attachments(?).attachment(?)#moveDown", "Attachment lowered or lifted")
end


---
function AttacherJoints.registerAttacherJointXMLPaths(schema, baseName)
    schema:setXMLSharedRegistration("AttacherJoint", baseName)

    baseName = baseName .. ".attacherJoint(?)"

    schema:register(XMLValueType.NODE_INDEX, baseName .. "#node", "Node")
    schema:register(XMLValueType.NODE_INDEX, baseName .. "#nodeVisual", "Visual node")

    schema:register(XMLValueType.BOOL, baseName .. "#supportsHardAttach", "Supports hard attach")
    schema:register(XMLValueType.STRING, baseName .. "#jointType", "Joint type", "implement")

    schema:register(XMLValueType.STRING, baseName .. ".subType#name", "If defined this type needs to match with the sub type in the tool")
    schema:register(XMLValueType.STRING, baseName .. ".subType#brandRestriction", "If defined it's only possible to attach tools from these brands (can be multiple separated by ' ')")
    schema:register(XMLValueType.STRING, baseName .. ".subType#vehicleRestriction", "If defined it's only possible to attach tools containing these strings in there xml path (can be multiple separated by ' ')")
    schema:register(XMLValueType.BOOL, baseName .. ".subType#subTypeShowWarning", "Show warning if sub type does not match", true)

    schema:register(XMLValueType.BOOL, baseName .. "#allowsJointLimitMovement", "Allows joint limit movement", true)
    schema:register(XMLValueType.BOOL, baseName .. "#allowsLowering", "Allows lowering", true)
    schema:register(XMLValueType.BOOL, baseName .. "#isDefaultLowered", "Default lowered state", false)
    schema:register(XMLValueType.BOOL, baseName .. "#allowDetachingWhileLifted", "Allow detach while lifted", true)
    schema:register(XMLValueType.BOOL, baseName .. "#allowFoldingWhileAttached", "Allow folding while attached", true)

    schema:register(XMLValueType.BOOL, baseName .. "#canTurnOnImplement", "Can turn on implement", true)

    schema:register(XMLValueType.NODE_INDEX, baseName .. ".rotationNode#node", "Rotation node")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#lowerRotation", "Lower rotation", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#upperRotation", "Upper rotation", "rotation in i3d")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#startRotation", "Start rotation", "rotation in i3d")

    schema:register(XMLValueType.NODE_INDEX, baseName .. ".rotationNode2#node", "Rotation node")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode2#lowerRotation", "Lower rotation", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode2#upperRotation", "Upper rotation", "rotation in i3d")

    schema:register(XMLValueType.NODE_INDEX, baseName .. ".transNode#node", "Translation node")
    schema:register(XMLValueType.FLOAT, baseName .. ".transNode#height", "Height of visual translation node", 0.12)
    schema:register(XMLValueType.FLOAT, baseName .. ".transNode#minY", "Min Y translation")
    schema:register(XMLValueType.FLOAT, baseName .. ".transNode#maxY", "Max Y translation")

    schema:register(XMLValueType.NODE_INDEX, baseName .. ".transNode.dependentBottomArm#node", "Dependent bottom arm node")
    schema:register(XMLValueType.FLOAT, baseName .. ".transNode.dependentBottomArm#threshold", "If the trans node Y translation is below this threshold the rotation will be set", "unlimited, so rotation is always set")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".transNode.dependentBottomArm#rotation", "Rotation to be set when the translation node is below the threshold", "0 0 0")

    schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#lower", "Lower distance to ground", 0.7)
    schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#upper", "Upper distance to ground", 1.0)


    schema:register(XMLValueType.ANGLE, baseName .. "#lowerRotationOffset", "Upper rotation offset", 0)
    schema:register(XMLValueType.ANGLE, baseName .. "#upperRotationOffset", "Lower rotation offset", 0)

    schema:register(XMLValueType.BOOL, baseName .. "#dynamicLowerRotLimit", "Set the lower rot limit dynamically based on the lowered state (so the attacher can freely rotate between it's upper and lower rotation value. E.g. for combines)", false)

    schema:register(XMLValueType.BOOL, baseName .. "#lockDownRotLimit", "Lock down rotation limit", false)
    schema:register(XMLValueType.BOOL, baseName .. "#lockUpRotLimit", "Lock up rotation limit", false)

    schema:register(XMLValueType.BOOL, baseName .. "#lockDownTransLimit", "Lock down translation limit", true)
    schema:register(XMLValueType.BOOL, baseName .. "#lockUpTransLimit", "Lock up translation limit", false)


    schema:register(XMLValueType.VECTOR_ROT, baseName .. "#lowerRotLimit", "Lower rotation limit", "(20 20 20) for implement type, otherwise (0 0 0)")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. "#upperRotLimit", "Upper rotation limit", "Lower rot limit")

    schema:register(XMLValueType.VECTOR_3, baseName .. "#lowerTransLimit", "Lower translation limit", "(0.5 0.5 0.5) for implement type, otherwise (0 0 0)")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#upperTransLimit", "Upper translation limit", "Lower trans limit")

    schema:register(XMLValueType.VECTOR_3, baseName .. "#jointPositionOffset", "Joint position offset", "0 0 0")

    schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitSpring", "Rotation limit spring", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitDamping", "Rotation limit damping", "1 1 1")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitForceLimit", "Rotation limit force limit", "-1 -1 -1")

    schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitSpring", "Translation limit spring", "0 0 0")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitDamping", "Translation limit damping", "1 1 1")
    schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitForceLimit", "Translation limit force limit", "-1 -1 -1")

    schema:register(XMLValueType.FLOAT, baseName .. "#moveTime", "Move time", 0.5)
    schema:register(XMLValueType.VECTOR_N, baseName .. "#disabledByAttacherJoints", "This attacher becomes unavailable after attaching something to these attacher joint indices")
    schema:register(XMLValueType.BOOL, baseName .. "#enableCollision", "Collision between vehicle is enabled", false)

    AttacherJointTopArm.registerVehicleXMLPaths(schema, baseName .. ".topArm")

    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#rotationNode", "Rotation node of bottom arm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#translationNode", "Translation node of bottom arm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#referenceNode", "Reference node of bottom arm")
    schema:register(XMLValueType.VECTOR_ROT, baseName .. ".bottomArm#startRotation", "Start rotation", "values set in i3d")
    schema:register(XMLValueType.INT, baseName .. ".bottomArm#zScale", "Inverts bottom arm direction", 1)
    schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#lockDirection", "Lock direction", true)
    schema:register(XMLValueType.ANGLE, baseName .. ".bottomArm#resetSpeed", "Speed of bottom arm to return to idle position (deg/sec)", 45)
    schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#updateReferenceDistance", "If 'true', the reference distance will be updated dynamically. So it's possible to adjust the bottom arm length.", false)
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#jointPositionNode", "Node that will be equalized with the current attacher joint position of the attached implement")
    schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#toggleVisibility", "Bottom arm will be hidden on detach", false)
    schema:register(XMLValueType.VECTOR_N, baseName .. ".bottomArm#categoryRange", "Defines the min. and max. category that can be used separated by a whitespace. (if only one value is given it will be used as min. and max. value.)", "1 4")
    schema:register(XMLValueType.VECTOR_N, baseName .. ".bottomArm#widthRange", "Defines the min. and max. bottom arm width that can be used separated by a whitespace. Overwrites the categoryRange attribute. (if only one value is given it will be used as min. and max. value.)")
    schema:register(XMLValueType.FLOAT, baseName .. ".bottomArm#defaultWidth", "Defines the default bottom arm width while nothing is attached", "Width inside i3d file")
    schema:register(XMLValueType.INT, baseName .. ".bottomArm#defaultCategory", "Defines the default width category which is used when nothing is attached", "Width inside i3d file")
    schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#ballVisibility", "Defines if the balls of the tool are visible while the tool is attached to us", true)
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm.armLeft#node", "Left bottom arm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm.armLeft#referenceNode", "Left bottom arm reference node (placed at the attaching point at the end of the bottom arm. If not defined the arm will be translated on the X axis to the target width.)")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm.armRight#node", "Right bottom arm")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm.armRight#referenceNode", "Right bottom arm reference node (placed at the attaching point at the end of the bottom arm. If not defined the arm will be translated on the X axis to the target width.)")

    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#leftNode", "Node of moving tool that will be aligned to 'bottomArmLeftNode', if defined in the tool")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#rightNode", "Node of moving tool that will be aligned to 'bottomArmRightNode', if defined in the tool")

    schema:register(XMLValueType.STRING, baseName .. ".toolbar#filename", "Filename to toolbars i3d containing 5 meshes for category 0-4", "$data/shared/assets/toolbars/toolbars.i3d")

    SoundManager.registerSampleXMLPaths(schema, baseName, "attachSound")
    SoundManager.registerSampleXMLPaths(schema, baseName, "detachSound")

    schema:register(XMLValueType.NODE_INDEX, baseName .. ".steeringBars#leftNode", "Steering bar left node")
    schema:register(XMLValueType.NODE_INDEX, baseName .. ".steeringBars#rightNode", "Steering bar right node")
    schema:register(XMLValueType.BOOL, baseName .. ".steeringBars#forceUsage", "Forces usage of tools steering axle even if no steering bars are defined", true)

    schema:register(XMLValueType.NODE_INDICES, baseName .. ".visuals#nodes", "Visual nodes of attacher joint that will be visible when the joint is active")
    schema:register(XMLValueType.NODE_INDICES, baseName .. ".visuals#hide", "Visual nodes that will be hidden while attacher joint is active if there attacher is inactive")

    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, baseName)
    schema:register(XMLValueType.BOOL, baseName .. "#delayedObjectChanges", "Defines if object change is deactivated after the bottomArm has moved (if available)", true)
    schema:register(XMLValueType.BOOL, baseName .. "#delayedObjectChangesOnAttach", "Defines if object change is activated on attach or post attach", false)

    schema:register(XMLValueType.INT, baseName .. "#direction", "Direction of attacher joint (1 = front, -1 = back). Used for additional attachments on mobile and top light control in basegame.")
    schema:register(XMLValueType.BOOL, baseName .. "#useTopLights", "Defines if the attacher joint enables the top lights if something is attached. Flag needs to be set on the implement as well.", "'true' if the attacher joint is on the front")

    schema:register(XMLValueType.NODE_INDEX, baseName .. "#rootNode", "Root node", "Parent component of attacher joint node")

    schema:register(XMLValueType.FLOAT, baseName .. "#comboTime", "Combo time")

    schema:register(XMLValueType.VECTOR_2, baseName .. ".schema#position", "Schema position")
    schema:register(XMLValueType.VECTOR_2, baseName .. ".schema#liftedOffset", "Offset if lifted", "0 5")
    schema:register(XMLValueType.ANGLE, baseName .. ".schema#rotation", "Schema rotation", 0)
    schema:register(XMLValueType.BOOL, baseName .. ".schema#invertX", "Invert X", false)

    schema:addDelayedRegistrationPath(baseName, "AttacherJoint")

    schema:resetXMLSharedRegistration("AttacherJoint", baseName)
end


---Registration of attacher joint type
-- @param string name name if attacher type
function AttacherJoints.registerJointType(name)
    local key = "JOINTTYPE_"..string.upper(name)
    if AttacherJoints[key] == nil then
        AttacherJoints.NUM_JOINTTYPES = AttacherJoints.NUM_JOINTTYPES+1
        AttacherJoints[key] = AttacherJoints.NUM_JOINTTYPES
        AttacherJoints.jointTypeNameToInt[name] = AttacherJoints.NUM_JOINTTYPES
    end

    return AttacherJoints[key]
end

























---
function AttacherJoints.prerequisitesPresent(specializations)
    return true
end


---
function AttacherJoints.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onPreAttachImplement")
    SpecializationUtil.registerEvent(vehicleType, "onPostAttachImplement")
    SpecializationUtil.registerEvent(vehicleType, "onPreDetachImplement")
    SpecializationUtil.registerEvent(vehicleType, "onPostDetachImplement")
    SpecializationUtil.registerEvent(vehicleType, "onRequiresTopLightsChanged")
end


---
function AttacherJoints.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadAttachmentsFinished",                     AttacherJoints.loadAttachmentsFinished)
    SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementEvent",                   AttacherJoints.handleLowerImplementEvent)
    SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementByAttacherJointIndex",    AttacherJoints.handleLowerImplementByAttacherJointIndex)
    SpecializationUtil.registerFunction(vehicleType, "getAttachedImplements",                       AttacherJoints.getAttachedImplements)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJoints",                           AttacherJoints.getAttacherJoints)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointByJointDescIndex",            AttacherJoints.getAttacherJointByJointDescIndex)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexByNode",                 AttacherJoints.getAttacherJointIndexByNode)
    SpecializationUtil.registerFunction(vehicleType, "getImplementFromAttacherJointIndex",          AttacherJoints.getImplementFromAttacherJointIndex)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromObject",             AttacherJoints.getAttacherJointIndexFromObject)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointDescFromObject",              AttacherJoints.getAttacherJointDescFromObject)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromImplementIndex",     AttacherJoints.getAttacherJointIndexFromImplementIndex)
    SpecializationUtil.registerFunction(vehicleType, "getObjectFromImplementIndex",                 AttacherJoints.getObjectFromImplementIndex)
    SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointGraphics",                 AttacherJoints.updateAttacherJointGraphics)
    SpecializationUtil.registerFunction(vehicleType, "calculateAttacherJointMoveUpperLowerAlpha",   AttacherJoints.calculateAttacherJointMoveUpperLowerAlpha)
    SpecializationUtil.registerFunction(vehicleType, "doGroundHeightNodeCheck",                     AttacherJoints.doGroundHeightNodeCheck)
    SpecializationUtil.registerFunction(vehicleType, "finishGroundHeightNodeCheck",                 AttacherJoints.finishGroundHeightNodeCheck)
    SpecializationUtil.registerFunction(vehicleType, "groundHeightNodeCheckCallback",               AttacherJoints.groundHeightNodeCheckCallback)
    SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotation",                 AttacherJoints.updateAttacherJointRotation)
    SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotationNodes",            AttacherJoints.updateAttacherJointRotationNodes)
    SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointSettingsByObject",         AttacherJoints.updateAttacherJointSettingsByObject)
    SpecializationUtil.registerFunction(vehicleType, "setAttacherJointBottomArmWidth",              AttacherJoints.setAttacherJointBottomArmWidth)
    SpecializationUtil.registerFunction(vehicleType, "attachImplementFromInfo",                     AttacherJoints.attachImplementFromInfo)
    SpecializationUtil.registerFunction(vehicleType, "attachImplement",                             AttacherJoints.attachImplement)
    SpecializationUtil.registerFunction(vehicleType, "postAttachImplement",                         AttacherJoints.postAttachImplement)
    SpecializationUtil.registerFunction(vehicleType, "createAttachmentJoint",                       AttacherJoints.createAttachmentJoint)
    SpecializationUtil.registerFunction(vehicleType, "hardAttachImplement",                         AttacherJoints.hardAttachImplement)
    SpecializationUtil.registerFunction(vehicleType, "hardDetachImplement",                         AttacherJoints.hardDetachImplement)
    SpecializationUtil.registerFunction(vehicleType, "detachImplement",                             AttacherJoints.detachImplement)
    SpecializationUtil.registerFunction(vehicleType, "detachImplementByObject",                     AttacherJoints.detachImplementByObject)
    SpecializationUtil.registerFunction(vehicleType, "playAttachSound",                             AttacherJoints.playAttachSound)
    SpecializationUtil.registerFunction(vehicleType, "playDetachSound",                             AttacherJoints.playDetachSound)
    SpecializationUtil.registerFunction(vehicleType, "detachingIsPossible",                         AttacherJoints.detachingIsPossible)
    SpecializationUtil.registerFunction(vehicleType, "attachAdditionalAttachment",                  AttacherJoints.attachAdditionalAttachment)
    SpecializationUtil.registerFunction(vehicleType, "detachAdditionalAttachment",                  AttacherJoints.detachAdditionalAttachment)
    SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByJointDescIndex",           AttacherJoints.getImplementIndexByJointDescIndex)
    SpecializationUtil.registerFunction(vehicleType, "getImplementByJointDescIndex",                AttacherJoints.getImplementByJointDescIndex)
    SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByObject",                   AttacherJoints.getImplementIndexByObject)
    SpecializationUtil.registerFunction(vehicleType, "getImplementByObject",                        AttacherJoints.getImplementByObject)
    SpecializationUtil.registerFunction(vehicleType, "callFunctionOnAllImplements",                 AttacherJoints.callFunctionOnAllImplements)
    SpecializationUtil.registerFunction(vehicleType, "activateAttachments",                         AttacherJoints.activateAttachments)
    SpecializationUtil.registerFunction(vehicleType, "deactivateAttachments",                       AttacherJoints.deactivateAttachments)
    SpecializationUtil.registerFunction(vehicleType, "deactivateAttachmentsLights",                 AttacherJoints.deactivateAttachmentsLights)
    SpecializationUtil.registerFunction(vehicleType, "setJointMoveDown",                            AttacherJoints.setJointMoveDown)
    SpecializationUtil.registerFunction(vehicleType, "getJointMoveDown",                            AttacherJoints.getJointMoveDown)
    SpecializationUtil.registerFunction(vehicleType, "getIsHardAttachAllowed",                      AttacherJoints.getIsHardAttachAllowed)
    SpecializationUtil.registerFunction(vehicleType, "loadAttacherJointFromXML",                    AttacherJoints.loadAttacherJointFromXML)
    SpecializationUtil.registerFunction(vehicleType, "onBottomArmToolbarI3DLoaded",                 AttacherJoints.onBottomArmToolbarI3DLoaded)
    SpecializationUtil.registerFunction(vehicleType, "setSelectedImplementByObject",                AttacherJoints.setSelectedImplementByObject)
    SpecializationUtil.registerFunction(vehicleType, "getSelectedImplement",                        AttacherJoints.getSelectedImplement)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleAttach",                          AttacherJoints.getCanToggleAttach)
    SpecializationUtil.registerFunction(vehicleType, "getShowAttachControlBarAction",               AttacherJoints.getShowAttachControlBarAction)
    SpecializationUtil.registerFunction(vehicleType, "getAttachControlBarActionAccessible",         AttacherJoints.getAttachControlBarActionAccessible)
    SpecializationUtil.registerFunction(vehicleType, "detachAttachedImplement",                     AttacherJoints.detachAttachedImplement)
    SpecializationUtil.registerFunction(vehicleType, "startAttacherJointCombo",                     AttacherJoints.startAttacherJointCombo)
    SpecializationUtil.registerFunction(vehicleType, "registerSelfLoweringActionEvent",             AttacherJoints.registerSelfLoweringActionEvent)
    SpecializationUtil.registerFunction(vehicleType, "getIsAttachingAllowed",                       AttacherJoints.getIsAttachingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getCanSteerAttachable",                       AttacherJoints.getCanSteerAttachable)
    SpecializationUtil.registerFunction(vehicleType, "onAttacherJointsVehicleLoaded",               AttacherJoints.onAttacherJointsVehicleLoaded)
    SpecializationUtil.registerFunction(vehicleType, "getAttachableInfo",                           AttacherJoints.getAttachableInfo)
    SpecializationUtil.registerFunction(vehicleType, "setAttacherJointBlocked",                     AttacherJoints.setAttacherJointBlocked)
end


---
function AttacherJoints.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "raiseActive",                         AttacherJoints.raiseActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerActionEvents",                AttacherJoints.registerActionEvents)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeActionEvents",                  AttacherJoints.removeActionEvents)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics",                        AttacherJoints.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics",                   AttacherJoints.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass",                        AttacherJoints.getTotalMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass",          AttacherJoints.getAdditionalComponentMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addChildVehicles",                    AttacherJoints.addChildVehicles)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAirConsumerUsage",                 AttacherJoints.getAirConsumerUsage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower",                    AttacherJoints.getRequiresPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addVehicleToAIImplementList",         AttacherJoints.addVehicleToAIImplementList)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "collectAIAgentAttachments",           AttacherJoints.collectAIAgentAttachments)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setAIVehicleObstacleStateDirty",      AttacherJoints.setAIVehicleObstacleStateDirty)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle",               AttacherJoints.getDirectionSnapAngle)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation",             AttacherJoints.getFillLevelInformation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableAddToolCameras",            AttacherJoints.attachableAddToolCameras)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableRemoveToolCameras",         AttacherJoints.attachableRemoveToolCameras)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelectableObjects",           AttacherJoints.registerSelectableObjects)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel",   AttacherJoints.getIsReadyForAutomatedTrainTravel)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAutomaticShiftingAllowed",       AttacherJoints.getIsAutomaticShiftingAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML",           AttacherJoints.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive",           AttacherJoints.getIsDashboardGroupActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointHeightNode",         AttacherJoints.loadAttacherJointHeightNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointHeightNodeActive",  AttacherJoints.getIsAttacherJointHeightNodeActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed",                     AttacherJoints.isDetachAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed",                    AttacherJoints.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWheelFoliageDestructionAllowed", AttacherJoints.getIsWheelFoliageDestructionAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed",      AttacherJoints.getAreControlledActionsAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConnectionHoseConfigIndex",        AttacherJoints.getConnectionHoseConfigIndex)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPowerTakeOffConfigIndex",          AttacherJoints.getPowerTakeOffConfigIndex)
end


---
function AttacherJoints.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onLightsTypesMaskChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnLightStateChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onBrakeLightsVisibilityChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onReverseLightsVisibilityChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onBeaconLightsVisibilityChanged", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onBrake", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onActivate", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", AttacherJoints)
    SpecializationUtil.registerEventListener(vehicleType, "onReverseDirectionChanged", AttacherJoints)
end


---Called before loading
-- @param table savegame savegame
function AttacherJoints:onPreLoad(savegame)
    local spec = self.spec_attacherJoints
    spec.attachedImplements = {}
    spec.selectedImplement = nil

    spec.lastInputAttacherCheckIndex = 0
end


---Called on loading
-- @param table savegame savegame
function AttacherJoints:onLoad(savegame)
    local spec = self.spec_attacherJoints

    spec.attacherJointCombos = {}
    spec.attacherJointCombos.duration = self.xmlFile:getValue("vehicle.attacherJoints#comboDuration", 2) * 1000
    spec.attacherJointCombos.currentTime = 0
    spec.attacherJointCombos.direction = -1
    spec.attacherJointCombos.isRunning = false
    spec.attacherJointCombos.joints = {}

    spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.attacherJoints#maxUpdateDistance", AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE)

    spec.visualNodeToAttacherJoints = {}
    spec.hideVisualNodeToAttacherJoints = {}

    spec.attacherJoints = {}
    local i = 0
    while true do
        local baseName = string.format("vehicle.attacherJoints.attacherJoint(%d)", i)
        if not self.xmlFile:hasProperty(baseName) then
            break
        end
        local attacherJoint = {}
        if self:loadAttacherJointFromXML(attacherJoint, self.xmlFile, baseName, i) then
            table.insert(spec.attacherJoints, attacherJoint)
            attacherJoint.index = #spec.attacherJoints
        end
        i = i + 1
    end

    -- data structure to store information about eventually attachable vehicles
    spec.attachableInfo = {}
    spec.attachableInfo.attacherVehicle = nil
    spec.attachableInfo.attacherVehicleJointDescIndex = nil
    spec.attachableInfo.attachable = nil
    spec.attachableInfo.attachableJointDescIndex = nil

    spec.pendingAttachableInfo = {}
    spec.pendingAttachableInfo.minDistance = math.huge
    spec.pendingAttachableInfo.minDistanceY = math.huge
    spec.pendingAttachableInfo.attacherVehicle = nil
    spec.pendingAttachableInfo.attacherVehicleJointDescIndex = nil
    spec.pendingAttachableInfo.attachable = nil
    spec.pendingAttachableInfo.attachableJointDescIndex = nil
    spec.pendingAttachableInfo.warning = nil

    if self.isClient then
        spec.samples = {}
        spec.isHydraulicSamplePlaying = false
        spec.samples.hydraulic  = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.attach     = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "attach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.detach     = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "detach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    if self.isClient and g_isDevelopmentVersion then
        for k, attacherJoint in ipairs(spec.attacherJoints) do
            if spec.samples.attach == nil and attacherJoint.sampleAttach == nil then
                Logging.xmlDevWarning(self.xmlFile, "Missing attach sound for attacherjoint '%d'", k)
            end
            if attacherJoint.rotationNode ~= nil and spec.samples.hydraulic == nil then
                Logging.xmlDevWarning(self.xmlFile, "Missing hydraulic sound for attacherjoint '%d'", k)
            end
        end
    end

    spec.showAttachNotAllowedText = 0
    spec.wasInAttachRange = false

    spec.texts = {}
    spec.texts.warningToolNotCompatible = g_i18n:getText("warning_toolNotCompatible")
    spec.texts.warningToolBrandNotCompatible = g_i18n:getText("warning_toolBrandNotCompatible")
    spec.texts.infoAttachNotAllowed = g_i18n:getText("info_attach_not_allowed")
    spec.texts.lowerImplementFirst = g_i18n:getText("warning_lowerImplementFirst")
    spec.texts.detachNotAllowed = g_i18n:getText("warning_detachNotAllowed")
    spec.texts.actionAttach = g_i18n:getText("action_attach")
    spec.texts.actionDetach = g_i18n:getText("action_detach")
    spec.texts.warningFoldingAttacherJoint = g_i18n:getText("warning_foldingNotWhileAttachedToAttacherJoint")

    spec.groundHeightNodeCheckData = {
        isDirty = false,
        minDistance = math.huge,
        hit = false,
        raycastDistance = 1,
        currentRaycastDistance = 1,
        heightNodes = {},
        jointDesc = {},
        index = -1,
        lowerDistanceToGround = 0,
        upperDistanceToGround = 0,
        currentRaycastWorldPos = {0, 0, 0},
        currentRaycastWorldDir = {0, 0, 0},
        currentJointTransformPos = {0, 0, 0},
        raycastWorldPos = {0, 0, 0},
        raycastWorldDir = {0, 0, 0},
        jointTransformPos = {0, 0, 0},
        upperAlpha = 0,
        lowerAlpha = 0,
    }

    spec.dirtyFlag = self:getNextDirtyFlag()
end


---Called after loading
-- @param table savegame savegame
function AttacherJoints:onPostLoad(savegame)
    local spec = self.spec_attacherJoints

    for attacherJointIndex, attacherJoint in pairs(spec.attacherJoints) do
        attacherJoint.jointOrigRot = { getRotation(attacherJoint.jointTransform) }
        attacherJoint.jointOrigTrans = { getTranslation(attacherJoint.jointTransform) }
        if attacherJoint.transNode ~= nil then
            local _
            attacherJoint.transNodeMinY = Utils.getNoNil(attacherJoint.transNodeMinY, attacherJoint.jointOrigTrans[2])
            attacherJoint.transNodeMaxY = Utils.getNoNil(attacherJoint.transNodeMaxY, attacherJoint.jointOrigTrans[2])
            _, attacherJoint.transNodeOffsetY, _ = localToLocal(attacherJoint.jointTransform, attacherJoint.transNode, 0, 0, 0)
            _, attacherJoint.transNodeMinY, _ = localToLocal(getParent(attacherJoint.transNode), self.rootNode, 0, attacherJoint.transNodeMinY, 0)
            _, attacherJoint.transNodeMaxY, _ = localToLocal(getParent(attacherJoint.transNode), self.rootNode, 0, attacherJoint.transNodeMaxY, 0)
        end

        if attacherJoint.transNodeDependentBottomArm ~= nil then
            for _, attacherJoint2 in pairs(spec.attacherJoints) do
                if attacherJoint2.bottomArm ~= nil then
                    if attacherJoint2.bottomArm.rotationNode == attacherJoint.transNodeDependentBottomArm then
                        attacherJoint.transNodeDependentBottomArmAttacherJoint = attacherJoint2
                    end
                end
            end

            if attacherJoint.transNodeDependentBottomArmAttacherJoint == nil then
                Logging.xmlWarning(self.xmlFile, "Unable to find dependent bottom arm '%s' in any attacher joint.", getName(attacherJoint.transNodeDependentBottomArm))
                attacherJoint.transNodeDependentBottomArm = nil
            end
        end

        if attacherJoint.bottomArm ~= nil then
            setRotation(attacherJoint.bottomArm.rotationNode, attacherJoint.bottomArm.rotX, attacherJoint.bottomArm.rotY, attacherJoint.bottomArm.rotZ)
            if self.setMovingToolDirty ~= nil then
                self:setMovingToolDirty(attacherJoint.bottomArm.rotationNode)
            end
        end
        if attacherJoint.rotationNode ~= nil then
            setRotation(attacherJoint.rotationNode, attacherJoint.rotX, attacherJoint.rotY, attacherJoint.rotZ)
        end

        if self.getInputAttacherJoints ~= nil then
            attacherJoint.inputAttacherJointOffsets = {}
            for _, inputAttacherJoint in ipairs(self:getInputAttacherJoints()) do
                local xDir, yDir, zDir = localDirectionToLocal(attacherJoint.jointTransform, inputAttacherJoint.node, 0, 0, 1)
                local xUp, yUp, zUp = localDirectionToLocal(attacherJoint.jointTransform, inputAttacherJoint.node, 0, 1, 0)
                local xNorm, yNorm, zNorm = localDirectionToLocal(attacherJoint.jointTransform, inputAttacherJoint.node, 1, 0, 0)
                local xOffset, yOffset, zOffset = localToLocal(attacherJoint.jointTransform, inputAttacherJoint.node, 0, 0, 0)
                table.insert(attacherJoint.inputAttacherJointOffsets, {xOffset, yOffset, zOffset, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm})
            end
        end

        if self.getAIRootNode ~= nil then
            local aiRootNode = self:getAIRootNode()
            local xDir, yDir, zDir = localDirectionToLocal(attacherJoint.jointTransform, aiRootNode, 0, 0, 1)
            local xUp, yUp, zUp = localDirectionToLocal(attacherJoint.jointTransform, aiRootNode, 0, 1, 0)
            local xNorm, yNorm, zNorm = localDirectionToLocal(attacherJoint.jointTransform, aiRootNode, 1, 0, 0)
            local xOffset, yOffset, zOffset = localToLocal(attacherJoint.jointTransform, aiRootNode, 0, 0, 0)
            attacherJoint.aiRootNodeOffset = {xOffset, yOffset, zOffset, xDir, yDir, zDir, xUp, yUp, zUp, xNorm, yNorm, zNorm}
        end

        if attacherJoint.comboTime ~= nil then
            table.insert(spec.attacherJointCombos.joints, {jointIndex = attacherJointIndex, time = math.clamp(attacherJoint.comboTime, 0, 1) * spec.attacherJointCombos.duration})
        end

        -- set all attacher joints to the defined default width including toolbar visibility
        self:setAttacherJointBottomArmWidth(attacherJointIndex, nil)
    end

    if savegame ~= nil and not savegame.resetVehicles then
        if spec.attacherJointCombos ~= nil then
            local comboDirection = savegame.xmlFile:getValue(savegame.key..".attacherJoints#comboDirection")
            if comboDirection ~= nil then
                spec.attacherJointCombos.direction = comboDirection
                if comboDirection == 1 then
                    spec.attacherJointCombos.currentTime = spec.attacherJointCombos.duration
                end
            end
        end
    end

    if #spec.attacherJoints == 0 then
        SpecializationUtil.removeEventListener(self, "onReadStream", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onWriteStream", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onUpdateInterpolation", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onUpdate", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onUpdateEnd", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onStateChange", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onLightsTypesMaskChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onTurnLightStateChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onBrakeLightsVisibilityChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onReverseLightsVisibilityChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onBeaconLightsVisibilityChanged", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onBrake", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onTurnedOn", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onTurnedOff", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onLeaveVehicle", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onActivate", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onDeactivate", AttacherJoints)
        SpecializationUtil.removeEventListener(self, "onReverseDirectionChanged", AttacherJoints)
    end
end


---Called after loading
-- @param table savegame savegame
function AttacherJoints:onLoadFinished(savegame)
    local spec = self.spec_attacherJoints
    if savegame ~= nil and (not savegame.resetVehicles or savegame.keepPosition) then
        spec.attachmentDataToLoad = {}

        local xmlFile = savegame.xmlFile

        for index, attachedImplementKey in xmlFile:iterator(savegame.key..".attacherJoints.attachedImplement") do
            local jointIndex = xmlFile:getValue(attachedImplementKey .. "#jointIndex")

            local attachmentData = {}
            attachmentData.jointIndex = jointIndex
            attachmentData.attachedVehicleUniqueId = xmlFile:getValue(attachedImplementKey .. "#attachedVehicleUniqueId")
            attachmentData.inputIndex = xmlFile:getValue(attachedImplementKey .. "#inputJointIndex")
            attachmentData.moveDown = xmlFile:getValue(attachedImplementKey .. "#moveDown", false)
            if attachmentData.jointIndex ~= nil and attachmentData.attachedVehicleUniqueId ~= nil and attachmentData.inputIndex ~= nil then
                local vehicle = g_currentMission.vehicleSystem:getVehicleByUniqueId(attachmentData.attachedVehicleUniqueId)
                if vehicle ~= nil then
                    self:attachImplement(vehicle, attachmentData.inputIndex, attachmentData.jointIndex, true, nil, attachmentData.moveDown, true, true)
                    self:setJointMoveDown(attachmentData.jointIndex, attachmentData.moveDown, true)
                else
                    table.insert(spec.attachmentDataToLoad, attachmentData)
                end
            end
        end

        for index, attacherJointKey in xmlFile:iterator(savegame.key..".attacherJoints.attacherJoint") do
            local jointIndex = xmlFile:getValue(attacherJointKey .. "#jointIndex")
            local isBlocked = xmlFile:getValue(attacherJointKey .. "#isBlocked")
            if isBlocked then
                local attacherJoint = spec.attacherJoints[jointIndex]
                attacherJoint.isBlocked = isBlocked
            end
        end

        if #spec.attachmentDataToLoad > 0 then
            g_messageCenter:subscribe(MessageType.VEHICLE_LOADED, self.onAttacherJointsVehicleLoaded, self)
        end
    end
end


---Called on before deleting
function AttacherJoints:onPreDelete()
    local spec = self.spec_attacherJoints

    if spec.attachedImplements ~= nil then
        for i=#spec.attachedImplements, 1, -1 do
            local implement = spec.attachedImplements[i]
            -- additional attachments will be detached and remove by the leading attachment
            if not implement.object:getIsAdditionalAttachment() then
                self:detachImplementByObject(implement.object, true)
            end
        end
    end
end


---Called on deleting
function AttacherJoints:onDelete()
    local spec = self.spec_attacherJoints

    if spec.attacherJoints ~= nil then
        for _, jointDesc in pairs(spec.attacherJoints) do
            g_soundManager:deleteSample(jointDesc.sampleAttach)
            g_soundManager:deleteSample(jointDesc.sampleDetach)

            if jointDesc.topArm ~= nil then
                jointDesc.topArm:delete()
                jointDesc.topArm = nil
            end

            local bottomArm = jointDesc.bottomArm
            if bottomArm ~= nil then
                if bottomArm.sharedLoadRequestIdToolbar ~= nil then
                    g_i3DManager:releaseSharedI3DFile(bottomArm.sharedLoadRequestIdToolbar)
                    bottomArm.sharedLoadRequestIdToolbar = nil
                end
            end
        end

        g_soundManager:deleteSamples(spec.samples)
    end
end


---
function AttacherJoints:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_attacherJoints
    if spec.attacherJointCombos ~= nil then
        xmlFile:setValue(key.."#comboDirection", spec.attacherJointCombos.direction)
    end

    if spec.attacherJoints ~= nil then
        for index, implement in ipairs(spec.attachedImplements) do
            if implement.object ~= nil then
                local attacherJointKey = string.format("%s.attachedImplement(%d)", key, index - 1)

                local jointDesc = self:getAttacherJointByJointDescIndex(implement.jointDescIndex)
                xmlFile:setValue(attacherJointKey .. "#jointIndex", implement.jointDescIndex)
                xmlFile:setValue(attacherJointKey .. "#moveDown", jointDesc.moveDown)

                xmlFile:setValue(attacherJointKey .. "#attachedVehicleUniqueId", implement.object:getUniqueId())
                xmlFile:setValue(attacherJointKey .. "#inputJointIndex", implement.inputJointDescIndex)
            end
        end

        local index = 0
        for jointIndex, jointDesc in pairs(spec.attacherJoints) do
            if jointDesc.isBlocked then
                local attacherJointKey = string.format("%s.attacherJoint(%d)", key, index)
                xmlFile:setValue(attacherJointKey .. "#jointIndex", jointIndex)

                xmlFile:setValue(attacherJointKey .. "#isBlocked", jointDesc.isBlocked)

                index = index + 1
            end
        end
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AttacherJoints:onReadStream(streamId, connection)
    local numImplements = streamReadInt8(streamId)
    for i=1, numImplements do
        local object = NetworkUtil.readNodeObject(streamId)
        local inputJointDescIndex = streamReadInt8(streamId)
        local jointDescIndex = streamReadInt8(streamId)
        local moveDown = streamReadBool(streamId)
        if object ~= nil and object:getIsSynchronized() then
            self:attachImplement(object, inputJointDescIndex, jointDescIndex, true, i, moveDown, true, true)
            self:setJointMoveDown(jointDescIndex, moveDown, true)
        end
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AttacherJoints:onWriteStream(streamId, connection)
    local spec = self.spec_attacherJoints

    -- write attached implements
    streamWriteInt8(streamId, #spec.attachedImplements)
    for i=1, #spec.attachedImplements do
        local implement = spec.attachedImplements[i]
        local inputJointDescIndex = implement.object.spec_attachable.inputAttacherJointDescIndex
        local jointDescIndex = implement.jointDescIndex
        local jointDesc = spec.attacherJoints[jointDescIndex]
        local moveDown = jointDesc.moveDown
        NetworkUtil.writeNodeObject(streamId, implement.object)
        streamWriteInt8(streamId, inputJointDescIndex)
        streamWriteInt8(streamId, jointDescIndex)
        streamWriteBool(streamId, moveDown)
    end
end


---Called after position interpolation update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function AttacherJoints:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_attacherJoints
    if self.currentUpdateDistance < spec.maxUpdateDistance then
        for _, implement in pairs(spec.attachedImplements) do
            if implement.object ~= nil then
                if self.updateLoopIndex == implement.object.updateLoopIndex then
                    self:updateAttacherJointGraphics(implement, dt, true)
                    implement.object:updateInputAttacherJointGraphics(implement, dt)
                end
            end
        end
    end

    -- call the update interpolation function on hard attached implements
    -- as their position depends on our own position
    -- this results in a doubled call on the tools side, as we do not surpress the first call
    for _, implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            if implement.object.spec_attachable.isHardAttached then
                SpecializationUtil.raiseEvent(implement.object, "onUpdateInterpolation", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
            end
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function AttacherJoints:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_attacherJoints

    if self.isClient then
        spec.showAttachNotAllowedText = math.max(spec.showAttachNotAllowedText - dt, 0)
        if spec.showAttachNotAllowedText > 0 then
            g_currentMission:addExtraPrintText(spec.texts.infoAttachNotAllowed)
        end
    end

    -- update attachables in range
    local info = spec.attachableInfo

    if (Platform.gameplay.automaticAttach and self.isServer)
    or (self.isClient and spec.actionEvents ~= nil and spec.actionEvents[InputAction.ATTACH] ~= nil) then
        if self:getCanToggleAttach() then
            AttacherJoints.updateVehiclesInAttachRange(self, AttacherJoints.MAX_ATTACH_DISTANCE_SQ, AttacherJoints.MAX_ATTACH_ANGLE, true)
        else
            info.attacherVehicle, info.attacherVehicleJointDescIndex, info.attachable, info.attachableJointDescIndex = nil, nil, nil, nil
        end
    end
end


---
function AttacherJoints:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- force update of all attacher joint graphics independent of camera distance right before vehicles starts to sleep
    -- so if we get into the update distance agan we are already in the right state without waking up the vehicle
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            if self.updateLoopIndex == implement.object.updateLoopIndex then
                self:updateAttacherJointGraphics(implement, dt, true)
            end
        end
    end
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function AttacherJoints:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_attacherJoints

    local playHydraulicSound = false

    for _, implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            local jointDesc = spec.attacherJoints[implement.jointDescIndex]

            if not implement.object.spec_attachable.isHardAttached then
                if self.isServer then
                    if implement.attachingIsInProgress then
                        local done = true
                        for i=1,3 do
                            local lastRotLimit = implement.attachingRotLimit[i]
                            local lastTransLimit = implement.attachingTransLimit[i]
                            implement.attachingRotLimit[i] = math.max(0, implement.attachingRotLimit[i] - implement.attachingRotLimitSpeed[i] * dt)
                            implement.attachingTransLimit[i] = math.max(0, implement.attachingTransLimit[i] - implement.attachingTransLimitSpeed[i] * dt)
                            if  (implement.attachingRotLimit[i] > 0 or implement.attachingTransLimit[i] > 0) or
                                (lastRotLimit > 0 or lastTransLimit > 0)
                            then
                                done = false
                            end
                        end
                        implement.attachingIsInProgress = not done

                        if done then
                            if implement.object.spec_attachable.attacherJoint.hardAttach and self:getIsHardAttachAllowed(implement.jointDescIndex) then
                                self:hardAttachImplement(implement)
                            end
                            self:postAttachImplement(implement)
                        end
                    end
                end
                if not implement.attachingIsInProgress then
                    local jointFrameInvalid = false
                    if jointDesc.allowsLowering then
                        if self:getIsActive() then
                            local upperAlpha, lowerAlpha = jointDesc.upperAlpha, jointDesc.lowerAlpha
                            if jointDesc.moveDown then
                                upperAlpha, lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, implement.object)
                                jointDesc.moveTime = jointDesc.moveDefaultTime * math.abs(upperAlpha - lowerAlpha)
                            end

                            local moveAlpha = Utils.getMovedLimitedValue(jointDesc.moveAlpha, lowerAlpha, upperAlpha, jointDesc.moveTime, dt, not jointDesc.moveDown)
                            if moveAlpha ~= jointDesc.moveAlpha or upperAlpha ~= jointDesc.upperAlpha or lowerAlpha ~= jointDesc.lowerAlpha then
                                jointDesc.upperAlpha = upperAlpha
                                jointDesc.lowerAlpha = lowerAlpha

                                if jointDesc.moveDown then
                                    if math.abs(jointDesc.moveAlpha - jointDesc.lowerAlpha) < 0.05 then
                                        jointDesc.isMoving = false
                                    end
                                else
                                    if math.abs(jointDesc.moveAlpha - jointDesc.upperAlpha) < 0.05 then
                                        jointDesc.isMoving = false
                                    end
                                end

                                playHydraulicSound = jointDesc.isMoving

                                jointDesc.moveAlpha = moveAlpha
                                if jointDesc.upperAlpha - jointDesc.lowerAlpha ~= 0 then
                                    jointDesc.moveLimitAlpha = 1- (moveAlpha-jointDesc.lowerAlpha) / (jointDesc.upperAlpha-jointDesc.lowerAlpha)
                                else
                                    jointDesc.moveLimitAlpha = 1
                                end
                                jointFrameInvalid = true
                                self:updateAttacherJointRotationNodes(jointDesc, jointDesc.moveAlpha)
                                self:updateAttacherJointRotation(jointDesc, implement.object)
                            end
                        end
                    end

                    jointFrameInvalid = jointFrameInvalid or jointDesc.jointFrameInvalid
                    if jointFrameInvalid then
                        jointDesc.jointFrameInvalid = false
                        if self.isServer then
                            setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
                        end
                    end
                end
                if self.isServer then
                    local force = implement.attachingIsInProgress
                    if force or (jointDesc.allowsLowering and jointDesc.allowsJointLimitMovement) then
                        if jointDesc.jointIndex ~= nil and jointDesc.jointIndex ~= 0 then
                            if force or implement.object.spec_attachable.attacherJoint.allowsJointRotLimitMovement then
                                local alpha = math.max(jointDesc.moveLimitAlpha - implement.rotLimitThreshold, 0) / (1-implement.rotLimitThreshold)

                                for i=1, 3 do
                                    AttacherJoints.updateAttacherJointRotationLimit(implement, jointDesc, i, force, alpha)
                                end
                            end

                            if force or implement.object.spec_attachable.attacherJoint.allowsJointTransLimitMovement then
                                local alpha = math.max(jointDesc.moveLimitAlpha - implement.transLimitThreshold, 0) / (1-implement.transLimitThreshold)

                                for i=1, 3 do
                                    AttacherJoints.updateAttacherJointTranslationLimit(implement, jointDesc, i, force, alpha)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if self.isClient and spec.samples.hydraulic ~= nil then
        for i=1, #spec.attacherJoints do
            local jointDesc = spec.attacherJoints[i]
            if jointDesc.bottomArm ~= nil and jointDesc.bottomArm.bottomArmInterpolating then
                playHydraulicSound = true
            end
        end

        if playHydraulicSound then
            if not spec.isHydraulicSamplePlaying then
                g_soundManager:playSample(spec.samples.hydraulic)
                spec.isHydraulicSamplePlaying = true
            end
        else
            if spec.isHydraulicSamplePlaying then
                g_soundManager:stopSample(spec.samples.hydraulic)
                spec.isHydraulicSamplePlaying = false
            end
        end
    end

    local combos = spec.attacherJointCombos
    if combos ~= nil and combos.isRunning then
        for _, joint in pairs(combos.joints) do
            local doLowering
            if combos.direction == 1 and combos.currentTime >= joint.time then
                doLowering = true
            elseif combos.direction == -1 and combos.currentTime <= combos.duration-joint.time then
                doLowering = false
            end

            if doLowering ~= nil then
                local implement = self:getImplementFromAttacherJointIndex(joint.jointIndex)
                if implement ~= nil then
                    if implement.object.setLoweredAll ~= nil then
                        implement.object:setLoweredAll(doLowering, joint.jointIndex)
                    end
                end
            end
        end

        if (combos.direction == -1 and combos.currentTime == 0) or
           (combos.direction == 1  and combos.currentTime == combos.duration) then
            combos.isRunning = false
        end

        combos.currentTime = math.clamp(combos.currentTime + dt*combos.direction, 0, combos.duration)
    end

    AttacherJoints.updateActionEvents(self)

    -- auto attach for mobile version
    if Platform.gameplay.automaticAttach then
        if self.isServer then
            if self:getCanToggleAttach() then
                local info = spec.attachableInfo

                if info.attachable ~= nil and not spec.wasInAttachRange and info.attacherVehicle == self then
                    if not self.isReconfigurating and not info.attachable.isReconfigurating then
                        local attachAllowed, warning = info.attachable:isAttachAllowed(self:getActiveFarm(), info.attacherVehicle)
                        if attachAllowed then
                            -- wasInAttachRange is nil after detach until the detached implement is in range
                            if spec.wasInAttachRange == nil then
                                spec.wasInAttachRange = true
                            else
                                self:attachImplementFromInfo(info)
                            end
                        elseif warning ~= nil then
                            g_currentMission:showBlinkingWarning(warning, 2000)
                        end
                    end
                elseif info.attachable == nil and spec.wasInAttachRange then
                    spec.wasInAttachRange = false
                end
            end
        end
    end
end


---Called after all attachments were loaded
function AttacherJoints:loadAttachmentsFinished()
    -- apply loaded selection from savegame after all implemented were attached
    if self.rootVehicle == self then
        if self.loadedSelectedObjectIndex ~= nil then
            local object = self.selectableObjects[self.loadedSelectedObjectIndex]
            if object ~= nil then
                self:setSelectedObject(object, self.loadedSubSelectedObjectIndex or 1)
            end

            self.loadedSelectedObjectIndex = nil
            self.loadedSubSelectedObjectIndex = nil
        end
    end
end


---
function AttacherJoints:handleLowerImplementEvent(vehicle, direction)
    local selectedVehicle = self:getSelectedVehicle()
    if vehicle == nil and selectedVehicle == self then
        local spec = self.spec_attacherJoints
        if #spec.attachedImplements == 1 then
            vehicle = spec.attachedImplements[1].object
        end
    end

    local implement = self:getImplementByObject(vehicle or selectedVehicle)
    if implement ~= nil then
        local object = implement.object
        if object ~= nil and object.getAttacherVehicle ~= nil then

            local attacherVehicle = object:getAttacherVehicle()
            if attacherVehicle ~= nil then

                local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(object)
                attacherVehicle:handleLowerImplementByAttacherJointIndex(attacherJointIndex, direction)
            end
        end
    end
end


---
function AttacherJoints:handleLowerImplementByAttacherJointIndex(attacherJointIndex, direction)
    if attacherJointIndex ~= nil then
        local implement = self:getImplementByJointDescIndex(attacherJointIndex)
        if implement ~= nil then
            local object = implement.object
            local attacherJoints = self:getAttacherJoints()
            local attacherJoint = attacherJoints[attacherJointIndex]

            local allowsLowering, warning = object:getAllowsLowering()
            if allowsLowering and attacherJoint.allowsLowering then
                if direction == nil then
                    direction = not attacherJoint.moveDown
                end
                self:setJointMoveDown(implement.jointDescIndex, direction, false)
            elseif not allowsLowering and warning ~= nil then
                g_currentMission:showBlinkingWarning(warning, 2000)
            end
        end
    end
end


---
function AttacherJoints:getAttachedImplements()
    return self.spec_attacherJoints.attachedImplements
end


---
function AttacherJoints:getAttacherJoints()
    return self.spec_attacherJoints.attacherJoints
end


---
function AttacherJoints:getAttacherJointByJointDescIndex(jointDescIndex)
    return self.spec_attacherJoints.attacherJoints[jointDescIndex]
end


---
function AttacherJoints:getAttacherJointIndexByNode(node)
    local spec = self.spec_attacherJoints
    for i=1, #spec.attacherJoints do
        local attacherJoint = spec.attacherJoints[i]
        if attacherJoint.jointTransform == node then
            return i
        end
    end

    return nil
end


---
function AttacherJoints:getImplementFromAttacherJointIndex(attacherJointIndex)
    local spec = self.spec_attacherJoints
    for _,attachedImplement in pairs(spec.attachedImplements) do
        if attachedImplement.jointDescIndex == attacherJointIndex then
            return attachedImplement
        end
    end

    return nil
end


---
function AttacherJoints:getAttacherJointIndexFromObject(object)
    local spec = self.spec_attacherJoints
    for _,attachedImplement in pairs(spec.attachedImplements) do
        if attachedImplement.object == object then
            return attachedImplement.jointDescIndex
        end
    end

    return nil
end


---
function AttacherJoints:getAttacherJointDescFromObject(object)
    local spec = self.spec_attacherJoints
    for _,attachedImplement in pairs(spec.attachedImplements) do
        if attachedImplement.object == object then
            return spec.attacherJoints[attachedImplement.jointDescIndex]
        end
    end

    return nil
end


---
function AttacherJoints:getAttacherJointIndexFromImplementIndex(implementIndex)
    local spec = self.spec_attacherJoints
    local attachedImplement = spec.attachedImplements[implementIndex]
    if attachedImplement ~= nil then
        return attachedImplement.jointDescIndex
    end
    return nil
end


---
function AttacherJoints:getObjectFromImplementIndex(implementIndex)
    local spec = self.spec_attacherJoints
    local attachedImplement = spec.attachedImplements[implementIndex]
    if attachedImplement ~= nil then
        return attachedImplement.object
    end
    return nil
end


---Update attacher joint graphics
-- @param table implement implement
-- @param float dt time since last call in ms
function AttacherJoints:updateAttacherJointGraphics(implement, dt, forceUpdate)
    local spec = self.spec_attacherJoints

    if implement.object ~= nil then
        local jointDesc = spec.attacherJoints[implement.jointDescIndex]

        local attacherJoint = implement.object:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)

        if jointDesc.bottomArm ~= nil then
            local ax, ay, az = getWorldTranslation(jointDesc.bottomArm.rotationNode)
            local bx, by, bz = getWorldTranslation(attacherJoint.node)

            local x, y, z = worldDirectionToLocal(getParent(jointDesc.bottomArm.rotationNode), bx-ax, by-ay, bz-az)
            local distance = MathUtil.vector3Length(x,y,z)
            local upX, upY, upZ = 0,1,0
            if math.abs(y) > 0.99*distance then
                -- direction and up is parallel
                upY = 0
                if y > 0 then
                    upZ = 1
                else
                    upZ = -1
                end
            end
            local dirX, dirY, dirZ = 0, y*jointDesc.bottomArm.zScale, z*jointDesc.bottomArm.zScale
            if not jointDesc.bottomArm.lockDirection then
                dirX = x*jointDesc.bottomArm.zScale
            end

            local changed = false
            if math.abs(jointDesc.bottomArm.lastDirection[1] - dirX) > 0.001 or
               math.abs(jointDesc.bottomArm.lastDirection[2] - dirY) > 0.001 or
               math.abs(jointDesc.bottomArm.lastDirection[3] - dirZ) > 0.001 then

                if implement.attachingIsInProgress then
                    -- set only direction node so we can use this rotation as reference for the interpolator
                    setDirection(jointDesc.bottomArm.rotationNodeDir, dirX, dirY, dirZ, upX, upY, upZ)
                else
                    setDirection(jointDesc.bottomArm.rotationNode, dirX, dirY, dirZ, upX, upY, upZ)
                end

                jointDesc.bottomArm.lastDirection[1] = dirX
                jointDesc.bottomArm.lastDirection[2] = dirY
                jointDesc.bottomArm.lastDirection[3] = dirZ

                changed = true
            end

            if implement.attachingIsInProgress then
                if changed then
                    if not implement.bottomArmInterpolating then
                        local interpolator = ValueInterpolator.new(jointDesc.bottomArm.interpolatorKey, jointDesc.bottomArm.interpolatorGet, jointDesc.bottomArm.interpolatorSet, {getRotation(jointDesc.bottomArm.rotationNodeDir)}, AttacherJoints.SMOOTH_ATTACH_TIME)
                        if interpolator ~= nil then
                            interpolator:setDeleteListenerObject(self)
                            interpolator:setFinishedFunc(jointDesc.bottomArm.interpolatorFinished, jointDesc.bottomArm)

                            jointDesc.bottomArm.bottomArmInterpolating = true
                            implement.bottomArmInterpolating = true
                            implement.bottomArmInterpolator = interpolator
                        end
                    else
                        local rx, ry, rz = getRotation(jointDesc.bottomArm.rotationNodeDir)
                        local target = implement.bottomArmInterpolator:getTarget()
                        target[1], target[2], target[3] = rx, ry, rz
                        implement.bottomArmInterpolator:updateSpeed()
                    end
                end
            else
                if implement.bottomArmInterpolator ~= nil then
                    ValueInterpolator.removeInterpolator(jointDesc.bottomArm.interpolatorKey)
                    jointDesc.bottomArm.bottomArmInterpolating = false
                    implement.bottomArmInterpolating = false
                    implement.bottomArmInterpolator = nil
                end
            end

            if jointDesc.bottomArm.translationNode ~= nil and not implement.attachingIsInProgress then
                if jointDesc.bottomArm.updateReferenceDistance then
                    jointDesc.bottomArm.referenceDistance = calcDistanceFrom(jointDesc.bottomArm.referenceNode, jointDesc.bottomArm.translationNode)
                end

                setTranslation(jointDesc.bottomArm.translationNode, 0, 0, (distance-jointDesc.bottomArm.referenceDistance)*jointDesc.bottomArm.zScale)
            end

            if jointDesc.bottomArm.jointPositionNode ~= nil and not implement.attachingIsInProgress then
                setWorldTranslation(jointDesc.bottomArm.jointPositionNode, bx, by, bz)

                if self.setMovingToolDirty ~= nil then
                    self:setMovingToolDirty(jointDesc.bottomArm.jointPositionNode, forceUpdate, dt)
                end
            end

            if self.setMovingToolDirty ~= nil then
                self:setMovingToolDirty(jointDesc.bottomArm.rotationNode, forceUpdate, dt)
            end

            if attacherJoint.needsToolbar and jointDesc.bottomArm.toolbarNode ~= nil then
                local parent = getParent(jointDesc.bottomArm.toolbarNode)

                local xDir, yDir, zDir = localDirectionToLocal(attacherJoint.node, jointDesc.rootNode, 1, 0, 0)
                xDir, yDir, zDir = localDirectionToLocal(jointDesc.rootNode, parent, 0, yDir, zDir)

                local xUp, yUp, zUp = localDirectionToLocal(attacherJoint.node, jointDesc.rootNode, 0, 1, 0)
                xUp, yUp, zUp = localDirectionToLocal(jointDesc.rootNode, parent, 0, yUp, zUp)

                setDirection(jointDesc.bottomArm.toolbarNode, xDir, yDir, zDir, xUp, yUp, zUp)
            end

            if self.updateMovingPartByNode ~= nil then
                if jointDesc.bottomArm.leftNode ~= nil then
                    self:updateMovingPartByNode(jointDesc.bottomArm.leftNode, forceUpdate, dt)
                end
                if jointDesc.bottomArm.rightNode ~= nil then
                    self:updateMovingPartByNode(jointDesc.bottomArm.rightNode, forceUpdate, dt)
                end
            end
        end

        -- update top arm after the bottom arm as on some vehicles the top arm mounting is depending on the bottom arm
        if jointDesc.topArm ~= nil then
            if not implement.attachingIsInProgress and attacherJoint.topReferenceNode ~= nil then
                jointDesc.topArm:update(dt, attacherJoint.topReferenceNode)
            end
        end
    end
end


---Calculate move upper and lower alpha of attacher joint
-- @param table jointDesc joint desc of used attacher
-- @param table object object of attached vehicle
-- @param boolean initial initial call to reset
function AttacherJoints:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, object, initial)
    local objectAttacherJoint = object.spec_attachable.attacherJoint

    if jointDesc.allowsLowering then
        local lowerDistanceToGround = jointDesc.lowerDistanceToGround
        local upperDistanceToGround = jointDesc.upperDistanceToGround

        local upperAlpha
        local lowerAlpha

        if #objectAttacherJoint.heightNodes > 0 and jointDesc.rotationNode ~= nil then
            local checkData = self.spec_attacherJoints.groundHeightNodeCheckData
            if initial then
                checkData.heightNodes = objectAttacherJoint.heightNodes
                checkData.jointDesc = jointDesc
                checkData.objectAttacherJoint = objectAttacherJoint
                checkData.object = object
                checkData.index = -1

                lowerDistanceToGround = jointDesc.lowerDistanceToGround
                upperDistanceToGround = jointDesc.upperDistanceToGround

                for i=1, #objectAttacherJoint.heightNodes do
                    local heightNode = objectAttacherJoint.heightNodes[i]
                    local offX, offY, offZ = localToLocal(heightNode.node, heightNode.attacherJointNode, 0, 0, 0)

                    self:updateAttacherJointRotationNodes(jointDesc, 1)
                    setRotation(jointDesc.jointTransform, unpack(jointDesc.jointOrigRot))
                    local _, y, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
                    local delta = jointDesc.lowerDistanceToGround - y
                    local _, hy, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, offX, offY, offZ)
                    lowerDistanceToGround = hy + delta

                    self:updateAttacherJointRotationNodes(jointDesc, 0)
                    _, y, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
                    delta = jointDesc.upperDistanceToGround - y
                    _, hy, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, offX, offY, offZ)
                    upperDistanceToGround = hy + delta
                end
            else
                if (jointDesc.moveAlpha or 0) > 0 then
                    if checkData.index == -1 then
                        checkData.index = 1

                        checkData.minDistance = math.huge
                        checkData.hit = false
                        self:doGroundHeightNodeCheck()
                    end

                    if checkData.isDirty then
                        checkData.isDirty = false
                        self:doGroundHeightNodeCheck()
                    end

                    if jointDesc.upperAlpha ~= nil and checkData.upperAlpha ~= nil then
                        upperAlpha = jointDesc.upperAlpha * 0.9 + checkData.upperAlpha * 0.1
                        lowerAlpha = jointDesc.lowerAlpha * 0.9 + checkData.lowerAlpha * 0.1
                    else
                        upperAlpha = checkData.upperAlpha
                        lowerAlpha = checkData.lowerAlpha
                    end
                else
                    upperAlpha = jointDesc.upperAlpha
                    lowerAlpha = jointDesc.lowerAlpha
                end
            end
        end

        if upperDistanceToGround == lowerDistanceToGround then
            upperAlpha = upperAlpha or 1
            lowerAlpha = lowerAlpha or 1
        else
            upperAlpha = upperAlpha or math.clamp((objectAttacherJoint.upperDistanceToGround - upperDistanceToGround) / (lowerDistanceToGround - upperDistanceToGround), 0, 1)
            lowerAlpha = lowerAlpha or math.clamp((objectAttacherJoint.lowerDistanceToGround - upperDistanceToGround) / (lowerDistanceToGround - upperDistanceToGround), 0, 1)
        end

        if initial then
            local checkData = self.spec_attacherJoints.groundHeightNodeCheckData
            checkData.upperAlpha = upperAlpha
            checkData.lowerAlpha = lowerAlpha
        end

        if objectAttacherJoint.allowsLowering and jointDesc.allowsLowering then
            return upperAlpha, lowerAlpha
        else
            if objectAttacherJoint.isDefaultLowered then
                return lowerAlpha, lowerAlpha
            else
                return upperAlpha, upperAlpha
            end
        end
    end

    if objectAttacherJoint.isDefaultLowered then
        return 1, 1
    else
        return 0, 0
    end
end


---Starts the next step in the ground height node check (raycast)
function AttacherJoints:doGroundHeightNodeCheck()
    local checkData = self.spec_attacherJoints.groundHeightNodeCheckData

    local heightNode = checkData.heightNodes[checkData.index]
    if heightNode ~= nil and checkData.object:getIsAttacherJointHeightNodeActive(heightNode) then
        local offX, offY, offZ = localToLocal(heightNode.node, heightNode.attacherJointNode, 0, 0, 0)

        self:updateAttacherJointRotationNodes(checkData.jointDesc, 1)
        local lWx, lWy, lWz = localToWorld(checkData.jointDesc.jointTransformOrig, offX, offY, offZ)

        self:updateAttacherJointRotationNodes(checkData.jointDesc, 0)
        local uWx, uWy, uWz = localToWorld(checkData.jointDesc.jointTransformOrig, offX, offY, offZ)

        --#debug if VehicleDebug.state == VehicleDebug.DEBUG then
        --#debug    DebugGizmo.renderAtPositionSimple(lWx, lWy, lWz)
        --#debug    DebugGizmo.renderAtPositionSimple(uWx, uWy, uWz)
        --#debug    drawDebugLine(uWx, uWy, uWz, 0, 1, 0, lWx, lWy, lWz, 1, 0, 0, true)
        --#debug end

        local dirX, dirY, dirZ = lWx - uWx, lWy - uWy, lWz - uWz
        local distance = MathUtil.vector3Length(dirX, dirY, dirZ)
        dirX, dirY, dirZ = MathUtil.vector3Normalize(dirX, dirY, dirZ)

        checkData.currentRaycastDistance = distance
        checkData.currentRaycastWorldPos[1] = uWx
        checkData.currentRaycastWorldPos[2] = uWy
        checkData.currentRaycastWorldPos[3] = uWz
        checkData.currentRaycastWorldDir[1] = dirX
        checkData.currentRaycastWorldDir[2] = dirY
        checkData.currentRaycastWorldDir[3] = dirZ

        checkData.currentJointTransformPos[1], checkData.currentJointTransformPos[2], checkData.currentJointTransformPos[3] = getWorldTranslation(checkData.jointDesc.jointTransform)

        -- as real raycast distance we also add the lower distance to ground
        distance = distance + checkData.objectAttacherJoint.lowerDistanceToGround
        checkData.minDistance = math.min(checkData.minDistance, distance)
        raycastAllAsync(uWx, uWy, uWz, dirX, dirY, dirZ, distance, "groundHeightNodeCheckCallback", self, CollisionFlag.TERRAIN)

        self:updateAttacherJointRotationNodes(checkData.jointDesc, checkData.jointDesc.moveAlpha or 0)
    else
        checkData.index = checkData.index + 1
        if checkData.index > #checkData.heightNodes then
            self:finishGroundHeightNodeCheck()
        else
            checkData.isDirty = true
        end
    end
end


---Called to finish the ground height node check and calculate the upper and lower alpha based on the results
function AttacherJoints:finishGroundHeightNodeCheck()
    local checkData = self.spec_attacherJoints.groundHeightNodeCheckData

    if checkData.minDistance ~= math.huge then
        if not checkData.hit then
            checkData.raycastDistance = checkData.currentRaycastDistance

            checkData.raycastWorldPos[1] = checkData.currentRaycastWorldPos[1]
            checkData.raycastWorldPos[2] = checkData.currentRaycastWorldPos[2]
            checkData.raycastWorldPos[3] = checkData.currentRaycastWorldPos[3]

            checkData.raycastWorldDir[1] = checkData.currentRaycastWorldDir[1]
            checkData.raycastWorldDir[2] = checkData.currentRaycastWorldDir[2]
            checkData.raycastWorldDir[3] = checkData.currentRaycastWorldDir[3]

            checkData.jointTransformPos[1] = checkData.currentJointTransformPos[1]
            checkData.jointTransformPos[2] = checkData.currentJointTransformPos[2]
            checkData.jointTransformPos[3] = checkData.currentJointTransformPos[3]
        end

        local upperAlpha = (checkData.minDistance - checkData.objectAttacherJoint.upperDistanceToGround) / checkData.raycastDistance
        local lowerAlpha = (checkData.minDistance - checkData.objectAttacherJoint.lowerDistanceToGround) / checkData.raycastDistance

        local uWx, uWy, uWz = checkData.raycastWorldPos[1], checkData.raycastWorldPos[2], checkData.raycastWorldPos[3]
        local dirX, dirY, dirZ = checkData.raycastWorldDir[1], checkData.raycastWorldDir[2], checkData.raycastWorldDir[3]

        -- correction since we raycast straight to lower point, but rotate in a circle
        local x1, y1, z1 = uWx + dirX * checkData.raycastDistance * lowerAlpha, uWy + dirY * checkData.raycastDistance * lowerAlpha, uWz + dirZ * checkData.raycastDistance * lowerAlpha

        local x3, y3, z3 = checkData.jointTransformPos[1], checkData.jointTransformPos[2], checkData.jointTransformPos[3]
        local straightToCenter = MathUtil.vector3Length(x1-x3, y1-y3, z1-z3)
        local circleToCenter = MathUtil.vector3Length(uWx-x3, uWy-y3, uWz-z3)
        local straightOffset = circleToCenter - straightToCenter

        local _, h1, h2
        _, h1, _ = worldToLocal(self.rootNode, x1, y1, z1)
        _, h2, _ = worldToLocal(self.rootNode, uWx, uWy, uWz)

        local angle = math.atan(straightOffset / (h2 - h1))
        local offset = straightOffset * math.sin(angle)
        lowerAlpha = (checkData.minDistance - checkData.objectAttacherJoint.lowerDistanceToGround - offset) / checkData.raycastDistance

        checkData.lowerAlpha = math.clamp(lowerAlpha, 0, 1)
        checkData.upperAlpha = math.clamp(upperAlpha, 0, 1)
    end

    checkData.index = -1
end


---Callback used when raycast hits an object.
-- @param integer hitObjectId scenegraph object id
-- @param float x world x hit position
-- @param float y world y hit position
-- @param float z world z hit position
-- @param float distance distance at which the cast hit the object
-- @param float nx normal x direction
-- @param float ny normal y direction
-- @param float nz normal z direction
-- @param integer subShapeIndex sub shape index
-- @param integer shapeId id of shape
-- @param boolean isLast is last hit
-- @return boolean return false to stop raycast
function AttacherJoints:groundHeightNodeCheckCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
    if self.isDeleted then
        return
    end

    local checkData = self.spec_attacherJoints.groundHeightNodeCheckData

    if hitObjectId ~= 0 then
        if getRigidBodyType(hitObjectId) == RigidBodyType.STATIC then
            if distance < checkData.minDistance then
                --#debug if VehicleDebug.state == VehicleDebug.DEBUG then
                --#debug    DebugGizmo.renderAtPosition(x, y, z, 0, 0, 1, 0, 1, 0)
                --#debug end

                checkData.raycastDistance = checkData.currentRaycastDistance
                checkData.minDistance = distance
                checkData.hit = true

                checkData.raycastWorldPos[1] = checkData.currentRaycastWorldPos[1]
                checkData.raycastWorldPos[2] = checkData.currentRaycastWorldPos[2]
                checkData.raycastWorldPos[3] = checkData.currentRaycastWorldPos[3]

                checkData.raycastWorldDir[1] = checkData.currentRaycastWorldDir[1]
                checkData.raycastWorldDir[2] = checkData.currentRaycastWorldDir[2]
                checkData.raycastWorldDir[3] = checkData.currentRaycastWorldDir[3]

                checkData.jointTransformPos[1] = checkData.currentJointTransformPos[1]
                checkData.jointTransformPos[2] = checkData.currentJointTransformPos[2]
                checkData.jointTransformPos[3] = checkData.currentJointTransformPos[3]
            end
        else
            if not isLast then
                return true
            end
        end
    end

    checkData.index = checkData.index + 1
    if checkData.index > #checkData.heightNodes then
        self:finishGroundHeightNodeCheck()
    else
        checkData.isDirty = true
    end

    return false
end


---Update attacher joint rotations depending on move alpha
-- @param table jointDesc joint desc of used attacher
-- @param table object object of attached vehicle
function AttacherJoints:updateAttacherJointRotation(jointDesc, object)
    local objectAttacherJoint = object.spec_attachable.attacherJoint

    -- rotate attacher such that
    local targetRot = MathUtil.lerp(objectAttacherJoint.upperRotationOffset, objectAttacherJoint.lowerRotationOffset, jointDesc.moveAlpha)
    local curRot = MathUtil.lerp(jointDesc.upperRotationOffset, jointDesc.lowerRotationOffset, jointDesc.moveAlpha)
    local rotDiff = targetRot - curRot

    setRotation(jointDesc.jointTransform, unpack(jointDesc.jointOrigRot))
    rotateAboutLocalAxis(jointDesc.jointTransform, rotDiff, 0, 0, 1)
end


---
function AttacherJoints:updateAttacherJointRotationNodes(jointDesc, alpha)
    if jointDesc.rotationNode ~= nil then
        setRotation(jointDesc.rotationNode, MathUtil.vector3ArrayLerp(jointDesc.upperRotation, jointDesc.lowerRotation, alpha))
    end
    if jointDesc.rotationNode2 ~= nil then
        setRotation(jointDesc.rotationNode2, MathUtil.vector3ArrayLerp(jointDesc.upperRotation2, jointDesc.lowerRotation2, alpha))
    end
end


---
function AttacherJoints:updateAttacherJointSettingsByObject(vehicle, updateLimit, updateRotationOffset, updateDistanceToGround)
    local jointDesc = self:getAttacherJointDescFromObject(vehicle)
    local implement = self:getImplementByObject(vehicle)
    local objectAttacherJoint = vehicle:getActiveInputAttacherJoint()
    if jointDesc ~= nil and implement ~= nil then
        if updateLimit then
            for i=1, 3 do
                AttacherJoints.updateAttacherJointLimits(implement, jointDesc, objectAttacherJoint, i)
                AttacherJoints.updateAttacherJointRotationLimit(implement, jointDesc, i, false, jointDesc.moveLimitAlpha)
                AttacherJoints.updateAttacherJointTranslationLimit(implement, jointDesc, i, false, jointDesc.moveLimitAlpha)
            end
        end

        if updateRotationOffset then
            self:updateAttacherJointRotation(jointDesc, vehicle)
            if self.isServer then
                setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
            end
        end

        if updateDistanceToGround then
            local upperAlpha, lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, vehicle)
            jointDesc.moveTime = jointDesc.moveDefaultTime * math.abs(upperAlpha - lowerAlpha)
            jointDesc.upperAlpha = upperAlpha
            jointDesc.lowerAlpha = lowerAlpha
        end
    end
end


---
function AttacherJoints:setAttacherJointBottomArmWidth(jointDescIndex, width)
    local spec = self.spec_attacherJoints
    local jointDesc = spec.attacherJoints[jointDescIndex]
    local bottomArm = jointDesc.bottomArm

    if bottomArm ~= nil and bottomArm.variableWidthAvailable ~= nil then
        width = width or bottomArm.defaultWidth

        if bottomArm.armLeftReferenceNode ~= nil and bottomArm.armRightReferenceNode ~= nil then
            local upX, upY, upZ = localDirectionToWorld(bottomArm.rotationNode, 0, 1, 0)

            local wx, wy, wz = localToWorld(bottomArm.referenceNode, width * 0.5, 0, 0)
            local ax, ay, az = getWorldTranslation(bottomArm.armLeft)
            local dx, dy, dz = MathUtil.vector3Normalize(wx - ax, wy - ay, wz - az)
            I3DUtil.setWorldDirection(bottomArm.armLeft, dx, dy, dz, upX, upY, upZ, nil, nil, nil)

            wx, wy, wz = localToWorld(bottomArm.referenceNode, -width * 0.5, 0, 0)
            ax, ay, az = getWorldTranslation(bottomArm.armRight)
            dx, dy, dz = MathUtil.vector3Normalize(wx - ax, wy - ay, wz - az)
            I3DUtil.setWorldDirection(bottomArm.armRight, dx, dy, dz, upX, upY, upZ, nil, nil, nil)

            local _, _, zOffsetLeft = localToLocal(bottomArm.armLeftReferenceNode, bottomArm.rotationNode, 0, 0, 0)
            local _, _, zOffsetRight = localToLocal(bottomArm.armRightReferenceNode, bottomArm.rotationNode, 0, 0, 0)
            bottomArm.referenceDistance = (math.abs(zOffsetLeft) + math.abs(zOffsetRight)) * 0.5

            -- update reference node since the toolbars are linked inside
            setTranslation(bottomArm.referenceNode, 0, 0, -bottomArm.referenceDistance)
        else
            local _, y, z = getTranslation(bottomArm.armLeft)
            setTranslation(bottomArm.armLeft, width * 0.5, y, z)

            _, y, z = getTranslation(bottomArm.armRight)
            setTranslation(bottomArm.armRight, -width * 0.5, y, z)
        end

        if self.setMovingToolDirty ~= nil then
            self:setMovingToolDirty(bottomArm.rotationNode)
        end
    end

    if bottomArm ~= nil and bottomArm.toolbars ~= nil then
        local activeIndex = AttacherJoints.getClosestLowerLinkCategoryIndex(width or bottomArm.defaultWidth)
        for index, node in ipairs(jointDesc.bottomArm.toolbars) do
            setVisibility(node, activeIndex == index - 1)
        end
    end
end


---
function AttacherJoints:attachImplementFromInfo(info)
    if info.attachable ~= nil then
        local attacherJoints = info.attacherVehicle.spec_attacherJoints.attacherJoints
        if attacherJoints[info.attacherVehicleJointDescIndex].jointIndex == 0 then
            if info.attachable:getActiveInputAttacherJointDescIndex() ~= nil then
                if info.attachable:getAllowMultipleAttachments() then
                    info.attachable:resolveMultipleAttachments()
                else
                    return false
                end
            end

            -- do not allow multiple implements in the same direction for mobile
            if GS_IS_MOBILE_VERSION then
                local attacherJointDirection = attacherJoints[info.attacherVehicleJointDescIndex].attacherJointDirection
                if attacherJointDirection ~= nil then
                    local attachedImplements = info.attacherVehicle:getAttachedImplements()
                    for i=1, #attachedImplements do
                        local jointDesc = attacherJoints[attachedImplements[i].jointDescIndex]

                        if attacherJointDirection == jointDesc.attacherJointDirection then
                            return false
                        end
                    end
                end
            end

            info.attacherVehicle:attachImplement(info.attachable, info.attachableJointDescIndex, info.attacherVehicleJointDescIndex)
            return true
        end
    end

    return false
end
























































































































































































































































---
function AttacherJoints:postAttachImplement(implement)
    local spec = self.spec_attacherJoints

    local object = implement.object
    local inputJointDescIndex = implement.inputJointDescIndex
    local jointDescIndex = implement.jointDescIndex
    local objectAttacherJoint = object.spec_attachable.inputAttacherJoints[inputJointDescIndex]
    local jointDesc = spec.attacherJoints[jointDescIndex]

    if objectAttacherJoint.topReferenceNode ~= nil then
        if jointDesc.topArm ~= nil then
            jointDesc.topArm:setIsActive(true)
        end
    end

    if jointDesc.bottomArm ~= nil then
        if jointDesc.bottomArm.toggleVisibility then
            setVisibility(jointDesc.bottomArm.rotationNode, true)
        end

        if objectAttacherJoint.needsToolbar and jointDesc.bottomArm.toolbarNode ~= nil then
            setVisibility(jointDesc.bottomArm.toolbarNode, true)
        end

        if jointDesc.bottomArm.leftNode ~= nil and objectAttacherJoint.bottomArmLeftNode ~= nil then
            self:setMovingPartReferenceNode(jointDesc.bottomArm.leftNode, objectAttacherJoint.bottomArmLeftNode, false)
        end
        if jointDesc.bottomArm.rightNode ~= nil and objectAttacherJoint.bottomArmRightNode ~= nil then
            self:setMovingPartReferenceNode(jointDesc.bottomArm.rightNode, objectAttacherJoint.bottomArmRightNode, false)
        end
    end

    if jointDesc.delayedObjectChangesOnAttach then
        ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, true, self, self.setMovingToolDirty)
    end

    if not implement.loadFromSavegame then
        self:playAttachSound(jointDesc)
    end

    self:updateAttacherJointGraphics(implement, 0)

    SpecializationUtil.raiseEvent(self, "onPostAttachImplement", object, inputJointDescIndex, jointDescIndex)
    object:postAttach(self, inputJointDescIndex, jointDescIndex, implement.loadFromSavegame)

    local data = {attacherVehicle=self, attachedVehicle=implement.object}
    local rootVehicle = self.rootVehicle
    rootVehicle:raiseStateChange(VehicleStateChange.ATTACH, data)
end


---Create attacher joint between vehicle and implement
-- @param table implement implement to attach
-- @param boolean noSmoothAttach dont use smooth attach
function AttacherJoints:createAttachmentJoint(implement, noSmoothAttach)

    local spec = self.spec_attacherJoints
    local jointDesc = spec.attacherJoints[implement.jointDescIndex]
    local objectAttacherJoint = implement.object.spec_attachable.inputAttacherJoints[implement.inputJointDescIndex]

    if self.isServer and objectAttacherJoint ~= nil then
        if (getRigidBodyType(jointDesc.rootNode) ~= RigidBodyType.DYNAMIC and getRigidBodyType(jointDesc.rootNode) ~= RigidBodyType.KINEMATIC)
        or (getRigidBodyType(objectAttacherJoint.rootNode) ~= RigidBodyType.DYNAMIC and getRigidBodyType(objectAttacherJoint.rootNode) ~= RigidBodyType.KINEMATIC) then
            return
        end

        -- root vehicle can be different, if we are hard attached
        local rootVehicle = g_currentMission:getNodeObject(jointDesc.rootNode) or self
        if not rootVehicle.isAddedToPhysics or not implement.object.isAddedToPhysics then
            return
        end

        local xNew = jointDesc.jointOrigTrans[1] + jointDesc.jointPositionOffset[1]
        local yNew = jointDesc.jointOrigTrans[2] + jointDesc.jointPositionOffset[2]
        local zNew = jointDesc.jointOrigTrans[3] + jointDesc.jointPositionOffset[3]

        local rx, ry, rz = getRotation(jointDesc.jointTransform)

        -- restore original joint position for worldToLocal operation (in case the vehicle was not completely detached and just remove from physics)
        setTranslation(jointDesc.jointTransform, jointDesc.jointOrigTrans[1], jointDesc.jointOrigTrans[2], jointDesc.jointOrigTrans[3])
        setRotation(jointDesc.jointTransform, jointDesc.jointOrigRot[1], jointDesc.jointOrigRot[2], jointDesc.jointOrigRot[3])

        -- transform offset position to world coord and to jointTransform coord to get position offset dependend on angle and position
        local x, y, z = localToWorld(getParent(jointDesc.jointTransform), xNew, yNew, zNew)
        local x1, y1, z1 = worldToLocal(jointDesc.jointTransform, x, y, z)

        -- move jointTransform to offset pos
        setTranslation(jointDesc.jointTransform, xNew, yNew, zNew)

        -- reapply the rotation that was already calculated by updateAttacherJointRotation before
        setRotation(jointDesc.jointTransform, rx, ry, rz)

        -- transform it to implement position and angle
        x, y, z = localToWorld(objectAttacherJoint.node, x1, y1, z1)
        local x2, y2, z2 = worldToLocal(getParent(objectAttacherJoint.node), x, y, z)

        setTranslation(objectAttacherJoint.node, x2, y2, z2)

        local constr = JointConstructor.new()
        constr:setActors(jointDesc.rootNode, objectAttacherJoint.rootNode)
        constr:setJointTransforms(jointDesc.jointTransform, objectAttacherJoint.node)
        --constr:setBreakable(20, 10)

        implement.jointRotLimit = {}
        implement.jointTransLimit = {}

        implement.lowerRotLimit = {}
        implement.lowerTransLimit = {}

        implement.upperRotLimit = {}
        implement.upperTransLimit = {}

        if noSmoothAttach == nil or not noSmoothAttach then
            local _
            local dx,dy,dz = localToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0,0,0)

            local dirX,dirY,dirZ = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0,1,0)
            local rX = math.atan2(dirZ,dirY)

            dirX,_,dirZ = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0,0,1)
            local rY = math.atan2(dirX,dirZ)

            dirX,dirY,_ = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 1,0,0)
            local rZ = math.atan2(dirY,dirX)

            implement.attachingTransLimit = { math.abs(dx), math.abs(dy), math.abs(dz) }
            implement.attachingRotLimit = { math.abs(rX), math.abs(rY), math.abs(rZ) }
            implement.attachingTransLimitSpeed = {}
            implement.attachingRotLimitSpeed = {}
            for i=1,3 do
                implement.attachingTransLimitSpeed[i] = implement.attachingTransLimit[i] / AttacherJoints.SMOOTH_ATTACH_TIME
                implement.attachingRotLimitSpeed[i] = implement.attachingRotLimit[i] / AttacherJoints.SMOOTH_ATTACH_TIME
            end
            implement.attachingIsInProgress = true
        else
            implement.attachingTransLimit = { 0,0,0 }
            implement.attachingRotLimit = { 0,0,0 }
        end

        implement.rotLimitThreshold = objectAttacherJoint.rotLimitThreshold or 0
        implement.transLimitThreshold = objectAttacherJoint.transLimitThreshold or 0

        for i=1, 3 do
            local rotLimit, transLimit = AttacherJoints.updateAttacherJointLimits(implement, jointDesc, objectAttacherJoint, i)

            local limitRot = rotLimit
            local limitTrans = transLimit
            if noSmoothAttach == nil or not noSmoothAttach then
                limitRot = math.max(rotLimit, implement.attachingRotLimit[i])
                limitTrans = math.max(transLimit, implement.attachingTransLimit[i])
            end

            local rotLimitDown, rotLimitUp = -limitRot, limitRot
            if i == 3 then
                if jointDesc.lockDownRotLimit then
                    rotLimitDown = math.min(-implement.attachingRotLimit[i], 0)
                end
                if jointDesc.lockUpRotLimit then
                    rotLimitUp = math.max(implement.attachingRotLimit[i], 0)
                end
            end
            constr:setRotationLimit(i-1, rotLimitDown, rotLimitUp)
            implement.jointRotLimit[i] = limitRot

            local transLimitDown, transLimitUp = -limitTrans, limitTrans
            if i == 2 then
                if jointDesc.lockDownTransLimit then
                    transLimitDown = math.min(-implement.attachingTransLimit[i], 0)
                end
                if jointDesc.lockUpTransLimit then
                    transLimitUp = math.max(implement.attachingTransLimit[i], 0)
                end
            end
            constr:setTranslationLimit(i-1, true, transLimitDown, transLimitUp)
            implement.jointTransLimit[i] = limitTrans
        end

        if jointDesc.enableCollision then
            constr:setEnableCollision(true)
        else
            for _, component in pairs(self.components) do
                if component.node ~= jointDesc.rootNodeBackup and not component.collideWithAttachables then
                    setPairCollision(component.node, objectAttacherJoint.rootNode, false)
                end
            end
        end

        local springX = math.max(jointDesc.rotLimitSpring[1], objectAttacherJoint.rotLimitSpring[1])
        local springY = math.max(jointDesc.rotLimitSpring[2], objectAttacherJoint.rotLimitSpring[2])
        local springZ = math.max(jointDesc.rotLimitSpring[3], objectAttacherJoint.rotLimitSpring[3])
        local dampingX = math.max(jointDesc.rotLimitDamping[1], objectAttacherJoint.rotLimitDamping[1])
        local dampingY = math.max(jointDesc.rotLimitDamping[2], objectAttacherJoint.rotLimitDamping[2])
        local dampingZ = math.max(jointDesc.rotLimitDamping[3], objectAttacherJoint.rotLimitDamping[3])
        local forceLimitX = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[1], objectAttacherJoint.rotLimitForceLimit[1])
        local forceLimitY = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[2], objectAttacherJoint.rotLimitForceLimit[2])
        local forceLimitZ = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[3], objectAttacherJoint.rotLimitForceLimit[3])
        constr:setRotationLimitSpring(springX, dampingX, springY, dampingY, springZ, dampingZ)
        constr:setRotationLimitForceLimit(forceLimitX, forceLimitY, forceLimitZ)

        springX = math.max(jointDesc.transLimitSpring[1], objectAttacherJoint.transLimitSpring[1])
        springY = math.max(jointDesc.transLimitSpring[2], objectAttacherJoint.transLimitSpring[2])
        springZ = math.max(jointDesc.transLimitSpring[3], objectAttacherJoint.transLimitSpring[3])
        dampingX = math.max(jointDesc.transLimitDamping[1], objectAttacherJoint.transLimitDamping[1])
        dampingY = math.max(jointDesc.transLimitDamping[2], objectAttacherJoint.transLimitDamping[2])
        dampingZ = math.max(jointDesc.transLimitDamping[3], objectAttacherJoint.transLimitDamping[3])
        forceLimitX = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[1], objectAttacherJoint.transLimitForceLimit[1])
        forceLimitY = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[2], objectAttacherJoint.transLimitForceLimit[2])
        forceLimitZ = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[3], objectAttacherJoint.transLimitForceLimit[3])
        constr:setTranslationLimitSpring(springX, dampingX, springY, dampingY, springZ, dampingZ)
        constr:setTranslationLimitForceLimit(forceLimitX, forceLimitY, forceLimitZ)

        jointDesc.jointIndex = constr:finalize()

        -- restore implement attacher joint position (to ensure correct bottom arm alignment)
        setTranslation(objectAttacherJoint.node, unpack(objectAttacherJoint.jointOrigTrans))
    else
        -- set joint index to '1' on client side, so we can check if something is attached
        jointDesc.jointIndex = 1
    end
end


---Hard attach implement
-- @param table implement implement to attach
function AttacherJoints:hardAttachImplement(implement)
    local spec = self.spec_attacherJoints

    local implements = {}
    local attachedImplements
    if implement.object.getAttachedImplements ~= nil then
        attachedImplements = implement.object:getAttachedImplements()
    end
    if attachedImplements ~= nil then
        for i=#attachedImplements, 1, -1 do
            local impl = attachedImplements[i]
            local object = impl.object
            local jointDescIndex = impl.jointDescIndex
            local jointDesc = implement.object.spec_attacherJoints.attacherJoints[jointDescIndex]
            local inputJointDescIndex = object.spec_attachable.inputAttacherJointDescIndex
            local moveDown = jointDesc.moveDown
            table.insert(implements, 1, {object=object, implementIndex=i, jointDescIndex=jointDescIndex, inputJointDescIndex=inputJointDescIndex, moveDown=moveDown})
            implement.object:detachImplement(1, true)
        end
    end

    local attacherJoint = spec.attacherJoints[implement.jointDescIndex]
    local implementJoint = implement.object.spec_attachable.attacherJoint

    local baseVehicleComponentNode = self:getParentComponent(attacherJoint.jointTransform)
    local attachedVehicleComponentNode = implement.object:getParentComponent(implement.object.spec_attachable.attacherJoint.node)

    -- remove all components from physics
    local wasAddedToPhysics = self.isAddedToPhysics
    if wasAddedToPhysics then
        local currentVehicle = self
        while currentVehicle ~= nil do
            currentVehicle:removeFromPhysics()
            currentVehicle = currentVehicle.attacherVehicle
        end
        implement.object:removeFromPhysics()
    end

    -- set valid baseVehicle compound
    if spec.attacherVehicle == nil then
        setIsCompound(baseVehicleComponentNode, true)
    end
    -- set attachedVehicle to compound child
    setIsCompoundChild(attachedVehicleComponentNode, true)

    -- set direction and local position
    local dirX, dirY, dirZ = localDirectionToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 0, 1)
    local upX, upY, upZ = localDirectionToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 1, 0)
    setDirection(attachedVehicleComponentNode, dirX, dirY, dirZ, upX, upY, upZ)
    local x,y,z = localToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 0, 0)
    setTranslation(attachedVehicleComponentNode, x, y, z)
    link(attacherJoint.jointTransform, attachedVehicleComponentNode)

    -- link visual and set to correct position
    if implementJoint.visualNode ~= nil and attacherJoint.jointTransformVisual ~= nil then
        dirX, dirY, dirZ = localDirectionToLocal(implementJoint.visualNode, implementJoint.node, 0, 0, 1)
        upX, upY, upZ = localDirectionToLocal(implementJoint.visualNode, implementJoint.node, 0, 1, 0)
        setDirection(implementJoint.visualNode, dirX, dirY, dirZ, upX, upY, upZ)
        x,y,z = localToLocal(implementJoint.visualNode, implementJoint.node, 0, 0, 0)
        setTranslation(implementJoint.visualNode, x, y, z)
        link(attacherJoint.jointTransformVisual, implementJoint.visualNode)
    end

    implement.object.spec_attachable.isHardAttached = true

    -- add to physics again
    if wasAddedToPhysics then
        local currentVehicle = self
        while currentVehicle ~= nil do
            currentVehicle:addToPhysics()
            currentVehicle = currentVehicle.attacherVehicle
        end
    end

    -- set new joint rootNodes
    for _, attacherJointToUpdate in pairs(implement.object.spec_attacherJoints.attacherJoints) do
        attacherJointToUpdate.rootNode = self.rootNode
    end

    for _, impl in pairs(implements) do
        implement.object:attachImplement(impl.object, impl.inputJointDescIndex, impl.jointDescIndex, true, impl.implementIndex, impl.moveDown, true)
    end

    if self.isServer then
        self:setMassDirty()
        self:raiseDirtyFlags(self.vehicleDirtyFlag)
    end

    return true
end


---Hard detach implement
-- @param table implement implement to detach
function AttacherJoints:hardDetachImplement(implement)
    -- restore original joint rootNode
    for _, attacherJoint in pairs(implement.object.spec_attacherJoints.attacherJoints) do
        attacherJoint.rootNode = attacherJoint.rootNodeBackup
    end

    local implementJoint = implement.object.spec_attachable.attacherJoint

    local attachedVehicleComponentNode = implement.object:getParentComponent(implementJoint.node)

    local wasAddedToPhysics = self.isAddedToPhysics
    if wasAddedToPhysics then
        local currentVehicle = self
        while currentVehicle ~= nil do
            currentVehicle:removeFromPhysics()
            currentVehicle = currentVehicle.attacherVehicle
        end
    end

    setIsCompound(attachedVehicleComponentNode, true)

    local x,y,z = getWorldTranslation(attachedVehicleComponentNode)
    setTranslation(attachedVehicleComponentNode, x,y,z)
    local dirX, dirY, dirZ = localDirectionToWorld(implement.object.rootNode, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(implement.object.rootNode, 0, 1, 0)
    setDirection(attachedVehicleComponentNode, dirX, dirY, dirZ, upX, upY, upZ)
    link(getRootNode(), attachedVehicleComponentNode)

    if implementJoint.visualNode ~= nil and getParent(implementJoint.visualNode) ~= implementJoint.visualNodeData.parent then
        link(implementJoint.visualNodeData.parent, implementJoint.visualNode, implementJoint.visualNodeData.index)
        setRotation(implementJoint.visualNode, implementJoint.visualNodeData.rotation[1], implementJoint.visualNodeData.rotation[2], implementJoint.visualNodeData.rotation[3])
        setTranslation(implementJoint.visualNode, implementJoint.visualNodeData.translation[1], implementJoint.visualNodeData.translation[2], implementJoint.visualNodeData.translation[3])
    end

    if wasAddedToPhysics then
        local currentVehicle = self
        while currentVehicle ~= nil do
            currentVehicle:addToPhysics()
            currentVehicle = currentVehicle.attacherVehicle
        end
        implement.object:addToPhysics()
    end

    implement.object.spec_attachable.isHardAttached = false

    if self.isServer then
        self:setMassDirty()
        self:raiseDirtyFlags(self.vehicleDirtyFlag)
    end

    return true
end


---Detach implement
-- @param integer implementIndex index of implement in self.attachedImplements
-- @param boolean noEventSend no event send
-- @return boolean success success
function AttacherJoints:detachImplement(implementIndex, noEventSend)
    local spec = self.spec_attacherJoints

    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(VehicleDetachEvent.new(self, spec.attachedImplements[implementIndex].object), nil, nil, self)
        else
            -- Send detach request to server and return
            local implement = spec.attachedImplements[implementIndex]
            if implement.object ~= nil then
                g_client:getServerConnection():sendEvent(VehicleDetachEvent.new(self, implement.object))
            end
            return
        end
    end

    local implement = spec.attachedImplements[implementIndex]
    implement.isDetaching = true

    SpecializationUtil.raiseEvent(self, "onPreDetachImplement", implement)
    implement.object:preDetach(self, implement)

    local jointDesc
    if implement.object ~= nil then
        jointDesc = spec.attacherJoints[implement.jointDescIndex]
        if jointDesc.transNode ~= nil then
            setTranslation(jointDesc.transNode, unpack(jointDesc.transNodeOrgTrans))

            if jointDesc.transNodeDependentBottomArm ~= nil then
                local bottomArmJointDesc = jointDesc.transNodeDependentBottomArmAttacherJoint
                local interpolator = ValueInterpolator.new(bottomArmJointDesc.bottomArm.interpolatorKey, bottomArmJointDesc.bottomArm.interpolatorGet, bottomArmJointDesc.bottomArm.interpolatorSet, {bottomArmJointDesc.bottomArm.rotX, bottomArmJointDesc.bottomArm.rotY, bottomArmJointDesc.bottomArm.rotZ}, AttacherJoints.SMOOTH_ATTACH_TIME * 2)
                if interpolator ~= nil then
                    interpolator:setDeleteListenerObject(self)
                    interpolator:setFinishedFunc(bottomArmJointDesc.bottomArm.interpolatorFinished, bottomArmJointDesc.bottomArm)
                    bottomArmJointDesc.bottomArm.bottomArmInterpolating = true
                end
            end
        end
        if not implement.object.spec_attachable.isHardAttached then
            if self.isServer then
                if jointDesc.jointIndex ~= 0 then
                    removeJoint(jointDesc.jointIndex)
                end

                if not jointDesc.enableCollision then
                    for _, component in pairs(self.components) do
                        if component.node ~= jointDesc.rootNodeBackup and not component.collideWithAttachables then
                            local attacherJoint = implement.object:getActiveInputAttacherJoint()
                            setPairCollision(component.node, attacherJoint.rootNode, true)
                        end
                    end
                end
            end
        end
        jointDesc.jointIndex = 0

        self:setAttacherJointBottomArmWidth(implement.jointDescIndex, nil) -- reset width
    end

    if not jointDesc.delayedObjectChanges or jointDesc.bottomArm == nil then
        ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, false, self, self.setMovingToolDirty)
    end

    for i=1, #jointDesc.hideVisuals do
        local node = jointDesc.hideVisuals[i]

        local allowedToShow = true
        local attacherJoints = spec.hideVisualNodeToAttacherJoints[node]
        if attacherJoints ~= nil then
            for j=1, #attacherJoints do
                if attacherJoints[j].jointIndex ~= 0 then
                    allowedToShow = false
                end
            end
        end

        if allowedToShow then
            setVisibility(node, true)
        end
    end

    for i=1, #jointDesc.visualNodes do
        local node = jointDesc.visualNodes[i]

        local hideNode = false
        local attacherJoints = spec.hideVisualNodeToAttacherJoints[node]
        if attacherJoints ~= nil then
            for j=1, #attacherJoints do
                if attacherJoints[j].jointIndex ~= 0 then
                    hideNode = true
                end
            end
        end

        if hideNode then
            setVisibility(node, false)
        end
    end

    if implement.object ~= nil then
        local object = implement.object

        if object.spec_attachable.isHardAttached then
            self:hardDetachImplement(implement)
        end

        if self.isClient then
            if jointDesc.topArm ~= nil then
                jointDesc.topArm:setIsActive(false)
            end

            if jointDesc.bottomArm ~= nil then
                local interpolator = ValueInterpolator.new(jointDesc.bottomArm.interpolatorKey, jointDesc.bottomArm.interpolatorGet, jointDesc.bottomArm.interpolatorSet, {jointDesc.bottomArm.rotX, jointDesc.bottomArm.rotY, jointDesc.bottomArm.rotZ}, nil, jointDesc.bottomArm.resetSpeed)
                if interpolator ~= nil then
                    interpolator:setDeleteListenerObject(self)
                    interpolator:setFinishedFunc(jointDesc.bottomArm.interpolatorFinished, jointDesc.bottomArm)
                    jointDesc.bottomArm.bottomArmInterpolating = true

                    if jointDesc.delayedObjectChanges then
                        interpolator:setFinishedFunc(function()
                            jointDesc.bottomArm.interpolatorFinished(jointDesc.bottomArm)

                            -- in case we already attached another vehicle
                            if jointDesc.jointIndex == 0 then
                                ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, false, self, self.setMovingToolDirty)
                            end
                        end)
                    end
                end

                jointDesc.bottomArm.lastDirection[1], jointDesc.bottomArm.lastDirection[2], jointDesc.bottomArm.lastDirection[3] = 0, 0, 0

                if jointDesc.bottomArm.translationNode ~= nil then
                    setTranslation(jointDesc.bottomArm.translationNode, 0, 0, 0)
                end
                if jointDesc.bottomArm.toolbarNode ~= nil then
                    setVisibility(jointDesc.bottomArm.toolbarNode, false)
                end
                if jointDesc.bottomArm.toggleVisibility then
                    setVisibility(jointDesc.bottomArm.rotationNode, false)
                end

                if jointDesc.bottomArm.leftNode ~= nil then
                    self:setMovingPartReferenceNode(jointDesc.bottomArm.leftNode, nil, false)
                end
                if jointDesc.bottomArm.rightNode ~= nil then
                    self:setMovingPartReferenceNode(jointDesc.bottomArm.rightNode, nil, false)
                end
            end
        end
        -- restore original translation
        setTranslation(jointDesc.jointTransform, unpack(jointDesc.jointOrigTrans))
        local attacherJoint = object:getActiveInputAttacherJoint()
        setTranslation(attacherJoint.node, unpack(attacherJoint.jointOrigTrans))
        if jointDesc.rotationNode ~= nil then
            setRotation(jointDesc.rotationNode, jointDesc.rotX, jointDesc.rotY, jointDesc.rotZ)
        end
        if jointDesc.rotationNode2 ~= nil then
            setRotation(jointDesc.rotationNode2, -jointDesc.rotX, -jointDesc.rotY, -jointDesc.rotZ)
        end

        SpecializationUtil.raiseEvent(self, "onPostDetachImplement", implementIndex)
        object:postDetach(implementIndex)

        self:detachAdditionalAttachment(jointDesc, attacherJoint)
    end

    table.remove(spec.attachedImplements, implementIndex)

    self:playDetachSound(jointDesc)

    spec.wasInAttachRange = nil

    self:updateVehicleChain()
    implement.object:updateVehicleChain()

    local data = {attacherVehicle=self, attachedVehicle=implement.object}
    implement.object:raiseStateChange(VehicleStateChange.DETACH, data)
    local rootVehicle = self.rootVehicle
    rootVehicle:raiseStateChange(VehicleStateChange.DETACH, data)

    self.rootVehicle:updateSelectableObjects()
    if GS_IS_MOBILE_VERSION then
        -- for mobile we select the next vehicle that can be detached, if non available we select the root
        local nextImplement = next(spec.attachedImplements)
        if spec.attachedImplements[nextImplement] ~= nil then
            self.rootVehicle:setSelectedVehicle(spec.attachedImplements[nextImplement].object, nil, true)
        else
            self.rootVehicle:setSelectedVehicle(self, nil, true)
        end
    else
        self.rootVehicle:setSelectedVehicle(self, nil, true)
    end
    self.rootVehicle:requestActionEventUpdate() -- do action event update independent of a successful selection (important since we cannot select every vehicle)
    implement.object:updateSelectableObjects()
    implement.object:setSelectedVehicle(implement.object, nil, true)
    implement.object:requestActionEventUpdate() -- do action event update independent of a successful selection (important since we cannot select every vehicle)

    AttacherJoints.updateRequiredTopLightsState(self)

    return true
end


---Detach implement by object of implement
-- @param table object object of implement to detach
-- @param boolean noEventSend no event send
-- @return boolean success success
function AttacherJoints:detachImplementByObject(object, noEventSend)
    local spec = self.spec_attacherJoints

    for i,implement in ipairs(spec.attachedImplements) do
        if implement.object == object then
            self:detachImplement(i, noEventSend)
            break
        end
    end

    return true
end


---
function AttacherJoints:setSelectedImplementByObject(object)
    self.spec_attacherJoints.selectedImplement = self:getImplementByObject(object)
end


---
function AttacherJoints:getSelectedImplement()
    local spec = self.spec_attacherJoints

    -- check if implement is still attached
    if spec.selectedImplement ~= nil then
        if spec.selectedImplement.object:getAttacherVehicle() ~= self then
            return nil
        end
    end

    return spec.selectedImplement
end


---
function AttacherJoints:getCanToggleAttach()
    return true
end






---
function AttacherJoints:getShowAttachControlBarAction()
    if self:getIsAIActive() then
        return false
    end

    local spec = self.spec_attacherJoints
    local info = spec.attachableInfo

    local selectedVehicle = self:getSelectedVehicle()
    if info.attacherVehicle == nil then
        if selectedVehicle ~= nil and not selectedVehicle.isDeleted then
            if selectedVehicle.getAttacherVehicle ~= nil and selectedVehicle:getAttacherVehicle() ~= nil then
                return true
            end
        end
    elseif selectedVehicle == nil then
        return true
    end

    if info.attachable ~= nil and info.attacherVehicle == self then
        return true
    end

    return false
end


---
function AttacherJoints:detachAttachedImplement()
    if self:getCanToggleAttach() then
        AttacherJoints.actionEventAttach(self)
    end
end


---
function AttacherJoints:startAttacherJointCombo(force)
    local spec = self.spec_attacherJoints

    if not spec.attacherJointCombos.isRunning or force then
        spec.attacherJointCombos.direction = -spec.attacherJointCombos.direction
        spec.attacherJointCombos.isRunning = true
    end
end










---
function AttacherJoints:getIsAttachingAllowed(attacherJoint)
    if attacherJoint.jointIndex ~= 0 then
        return false
    end

    if attacherJoint.isBlocked then
        return false
    end

    if attacherJoint.disabledByAttacherJoints ~= nil and #attacherJoint.disabledByAttacherJoints > 0 then
        for i=1, #attacherJoint.disabledByAttacherJoints do
            local jointIndex = attacherJoint.disabledByAttacherJoints[i]
            if self:getImplementByJointDescIndex(jointIndex) ~= nil then
                return false
            end
        end
    end

    return true
end


---Returns if the vehicle can control the steering axles of the given attachable
-- @param table jointDesc joint desc
-- @return boolean success success
function AttacherJoints:getCanSteerAttachable(attachable)
    local jointDesc = self:getAttacherJointDescFromObject(attachable)
    if jointDesc ~= nil then
        if jointDesc.steeringBarLeftNode ~= nil or jointDesc.steeringBarRightNode ~= nil or jointDesc.steeringBarForceUsage then
            return true
        end
    end

    return false
end


---Called when a new vehicle has been loaded
-- @param table vehicle vehicle object
function AttacherJoints:onAttacherJointsVehicleLoaded(vehicle)
    local spec = self.spec_attacherJoints

    if spec.attachmentDataToLoad ~= nil then
        for i=#spec.attachmentDataToLoad, 1, -1 do
            local attachmentData = spec.attachmentDataToLoad[i]
            if attachmentData.attachedVehicleUniqueId == vehicle:getUniqueId() then
                self:attachImplement(vehicle, attachmentData.inputIndex, attachmentData.jointIndex, true, nil, attachmentData.moveDown, true, true)
                self:setJointMoveDown(attachmentData.jointIndex, attachmentData.moveDown, true)

                table.remove(spec.attachmentDataToLoad, i)
            end
        end

        if #spec.attachmentDataToLoad == 0 then
            self:loadAttachmentsFinished()
            spec.attachmentDataToLoad = nil

            g_messageCenter:unsubscribe(MessageType.VEHICLE_LOADED, self)
        end
    else
        g_messageCenter:unsubscribe(MessageType.VEHICLE_LOADED, self)
    end
end


---
function AttacherJoints:registerSelfLoweringActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end


---Play attach sound
-- @param table jointDesc joint desc
-- @return boolean success success
function AttacherJoints:playAttachSound(jointDesc)
    local spec = self.spec_attacherJoints

    if self.isClient then
        if jointDesc ~= nil and jointDesc.sampleAttach ~= nil then
            g_soundManager:playSample(jointDesc.sampleAttach)
        else
            g_soundManager:playSample(spec.samples.attach)
        end
    end

    return true
end


---Play detach sound
-- @param table jointDesc joint desc
-- @return boolean success success
function AttacherJoints:playDetachSound(jointDesc)
    local spec = self.spec_attacherJoints

    if self.isClient then
        if jointDesc ~= nil and jointDesc.sampleDetach ~= nil then
            g_soundManager:playSample(jointDesc.sampleDetach)
        elseif spec.samples.detach ~= nil then
            g_soundManager:playSample(spec.samples.detach)
        elseif jointDesc ~= nil and jointDesc.sampleAttach ~= nil then
            g_soundManager:playSample(jointDesc.sampleAttach)
        else
            g_soundManager:playSample(spec.samples.attach)
        end
    end

    return true
end


---Returns true if it is possible to detach selected implement
-- @return boolean possibleToDetach possible to detach selected implement
function AttacherJoints:detachingIsPossible()
    local implement = self:getImplementByObject(self:getSelectedVehicle())
    if implement ~= nil then
        local object = implement.object
        if object ~= nil and object.attacherVehicle ~= nil and object:isDetachAllowed() then
            local implementIndex = object.attacherVehicle:getImplementIndexByObject(object)
            if implementIndex ~= nil then
                return true
            end
        end
    end
    return false
end


---Creates and attaches additional attachment
function AttacherJoints:attachAdditionalAttachment(jointDesc, inputJointDesc, object)
    if jointDesc.attacherJointDirection ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
        local storeItem = g_storeManager:getItemByXMLFilename(inputJointDesc.additionalAttachment.filename)
        if storeItem ~= nil then
            local targetDirection = -jointDesc.attacherJointDirection
            local attacherJoint, attacherJointIndex
            for index, attacherJointToCheck in ipairs(self:getAttacherJoints()) do
                if attacherJointToCheck.attacherJointDirection == targetDirection then
                    if attacherJointToCheck.jointIndex ~= 0 then
                        attacherJoint = nil
                        break
                    else
                        if attacherJointToCheck.jointType == inputJointDesc.additionalAttachment.jointType then
                            attacherJoint = attacherJointToCheck
                            attacherJointIndex = index
                        end
                    end
                end
            end

            if attacherJoint ~= nil then
                local x, y, z = localToWorld(attacherJoint.jointTransform, 0, 0, 0)
                local dirX, _, dirZ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)
                local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)

                jointDesc.additionalAttachment.currentAttacherJointIndex = attacherJointIndex
                local asyncCallbackArguments = {attacherJointIndex,
                                                inputJointDesc.additionalAttachment.inputAttacherJointIndex,
                                                attacherJoint.jointTransform,
                                                inputJointDesc.additionalAttachment.needsLowering,
                                                object,
                                                storeItem.xmlFilename}

                local data = VehicleLoadingData.new()
                data:setStoreItem(storeItem)
                data:setPosition(x, y, z)
                data:setRotation(0, yRot, 0)
                data:setPropertyState(VehiclePropertyState.NONE)
                data:setOwnerFarmId(self:getActiveFarm())

                data:load(AttacherJoints.additionalAttachmentLoaded, self, asyncCallbackArguments)
            end
        end
    end
end


---Creates and attaches additional attachment
function AttacherJoints:detachAdditionalAttachment(jointDesc, inputJointDesc)
    if jointDesc.additionalAttachment.currentAttacherJointIndex ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
        local implement = self:getImplementByJointDescIndex(jointDesc.additionalAttachment.currentAttacherJointIndex)
        if implement ~= nil then
            if implement.object:getIsAdditionalAttachment() then
                self:detachImplementByObject(implement.object)

                -- on the exit the vehicle will be removed by BaseMission.delete
                if not g_currentMission.isExitingGame then
                    implement.object:delete()
                end
            end
        end
    end
end


---Called after the additional attachment was loaded
function AttacherJoints:additionalAttachmentLoaded(vehicles, vehicleLoadState, asyncCallbackArguments)
    if vehicleLoadState ~= VehicleLoadingState.OK then
        Logging.warning("Failed to load additional attachment '%s'.", asyncCallbackArguments[6].xmlFilename)
        return
    end

    local vehicle = vehicles[1]
    if vehicle == nil or vehicle.setIsAdditionalAttachment == nil then
        Logging.warning("Invalid additional attachment '%s'.", asyncCallbackArguments[6].xmlFilename)
        return
    end

    local offset = {0, 0, 0}
    if vehicle.getInputAttacherJoints ~= nil then
        local inputAttacherJoints = vehicle:getInputAttacherJoints()
        if inputAttacherJoints[asyncCallbackArguments[2]] ~= nil then
            offset = inputAttacherJoints[asyncCallbackArguments[2]].jointOrigOffsetComponent
        end
    end

    local x, y, z = localToWorld(asyncCallbackArguments[3], unpack(offset))
    local dirX, _, dirZ = localDirectionToWorld(asyncCallbackArguments[3], 1, 0, 0)
    local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
    local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)

    vehicle:setAbsolutePosition(x, math.max(y, terrainY + 0.05), z, 0, yRot, 0)
    self:attachImplement(vehicle, asyncCallbackArguments[2], asyncCallbackArguments[1], true, nil, nil, true, true)
    vehicle:setIsAdditionalAttachment(asyncCallbackArguments[4], true)
    if vehicle.addDirtAmount ~= nil and asyncCallbackArguments[5] ~= nil and asyncCallbackArguments[5].getDirtAmount ~= nil then
        vehicle:addDirtAmount(asyncCallbackArguments[5]:getDirtAmount())
    end

    self.rootVehicle:updateSelectableObjects()
    self.rootVehicle:setSelectedVehicle(asyncCallbackArguments[5] or self)
end


---Returns implement index in 'self.attachedImplements' by jointDescIndex
-- @param integer jointDescIndex joint desc index
-- @return integer index index of implement
function AttacherJoints:getImplementIndexByJointDescIndex(jointDescIndex)
    local spec = self.spec_attacherJoints

    for i, implement in pairs(spec.attachedImplements) do
        if implement.jointDescIndex == jointDescIndex then
            return i
        end
    end

    return nil
end


---Returns implement by jointDescIndex
-- @param integer jointDescIndex joint desc index
-- @return table implement implement
function AttacherJoints:getImplementByJointDescIndex(jointDescIndex)
    local spec = self.spec_attacherJoints

    for i, implement in pairs(spec.attachedImplements) do
        if implement.jointDescIndex == jointDescIndex then
            return implement
        end
    end

    return nil
end


---Returns implement index in 'self.attachedImplements' by object
-- @param table object object of attached implement
-- @return integer index index of implement
function AttacherJoints:getImplementIndexByObject(object)
    local spec = self.spec_attacherJoints

    for i, implement in pairs(spec.attachedImplements) do
        if implement.object == object then
            return i
        end
    end

    return nil
end


---Returns implement by object
-- @param table object object of attached implement
-- @return table implement implement
function AttacherJoints:getImplementByObject(object)
    local spec = self.spec_attacherJoints

    for i, implement in pairs(spec.attachedImplements) do
        if implement.object == object then
            return implement
        end
    end

    return nil
end


---
function AttacherJoints:callFunctionOnAllImplements(functionName, ...)
    for _, implement in pairs(self:getAttachedImplements()) do
        local vehicle = implement.object
        if vehicle ~= nil then
            if vehicle[functionName] ~= nil then
                vehicle[functionName](vehicle, ...)
            end
        end
    end
end


---Call "activate" on all attachments
function AttacherJoints:activateAttachments()
    local spec = self.spec_attacherJoints

    for _,v in pairs(spec.attachedImplements) do
        if v.object ~= nil then
            v.object:activate()
        end
    end
end


---Call "deactivate" on all attachments
function AttacherJoints:deactivateAttachments()
    local spec = self.spec_attacherJoints

    for _,v in pairs(spec.attachedImplements) do
        if v.object ~= nil then
            v.object:deactivate()
        end
    end
end


---Call "deactivateLights" on all attachments
function AttacherJoints:deactivateAttachmentsLights()
    local spec = self.spec_attacherJoints

    for _,v in pairs(spec.attachedImplements) do
        if v.object ~= nil and v.object.deactivateLights ~= nil then
            v.object:deactivateLights()
        end
    end
end


---Set joint move down
-- @param integer jointDescIndex index of joint desc
-- @param boolean moveDown move down
-- @param boolean noEventSend no event send
-- @return boolean success success
function AttacherJoints:setJointMoveDown(jointDescIndex, moveDown, noEventSend)
    local spec = self.spec_attacherJoints

    local jointDesc = spec.attacherJoints[jointDescIndex]
    if moveDown ~= jointDesc.moveDown then
        if jointDesc.allowsLowering then
            jointDesc.moveDown = moveDown
            jointDesc.isMoving = true

            local implementIndex = self:getImplementIndexByJointDescIndex(jointDescIndex)
            if implementIndex ~= nil then
                local implement = spec.attachedImplements[implementIndex]
                if implement.object ~= nil then
                    implement.object:setLowered(moveDown)
                end
            end
        end

        VehicleLowerImplementEvent.sendEvent(self, jointDescIndex, moveDown, noEventSend)
    end

    return true
end


---Returns the current joint move down state
-- @param integer jointDescIndex index of joint desc
-- @return boolean moveDown move down
function AttacherJoints:getJointMoveDown(jointDescIndex)
    local jointDesc = self.spec_attacherJoints.attacherJoints[jointDescIndex]
    if jointDesc.allowsLowering then
        return jointDesc.moveDown
    end

    return false
end


---Returns if attacher joint supports hard attach
-- @param integer jointDescIndex index of joint
-- @return boolean supportsHardAttach attacher joint supports hard attach
function AttacherJoints:getIsHardAttachAllowed(jointDescIndex)
    local spec = self.spec_attacherJoints

    return spec.attacherJoints[jointDescIndex].supportsHardAttach
end


---Load attacher joint from xml
-- @param table attacherJoint attacherJoint
-- @param integer fileId xml file id
-- @param string baseName baseName
-- @param integer index index of attacher joint
function AttacherJoints:loadAttacherJointFromXML(attacherJoint, xmlFile, baseName, index)
    local spec = self.spec_attacherJoints

    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#index", baseName .. "#node") -- FS17
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#indexVisual", baseName .. "#nodeVisual") -- FS17
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#ptoOutputNode", "vehicle.powerTakeOffs.output") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerDistanceToGround", baseName..".distanceToGround#lower") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperDistanceToGround", baseName..".distanceToGround#upper") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#rotationNode", baseName..".rotationNode#node") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperRotation", baseName..".rotationNode#upperRotation") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerRotation", baseName..".rotationNode#lowerRotation") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#startRotation", baseName..".rotationNode#startRotation") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#rotationNode2", baseName..".rotationNode2#node") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperRotation2", baseName..".rotationNode2#upperRotation") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerRotation2", baseName..".rotationNode2#lowerRotation") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNode", baseName..".transNode#node") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeMinY", baseName..".transNode#minY") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeMaxY", baseName..".transNode#maxY") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeHeight", baseName..".transNode#height") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. ".additionalAttachment#attacherJointDirection", baseName.."#direction") -- FS22 to FS25


    local node = xmlFile:getValue(baseName.. "#node", nil, self.components, self.i3dMappings)
    if node == nil then
        Logging.xmlWarning(self.xmlFile, "Missing node for attacherJoint '%s'", baseName)
        return false
    end

    attacherJoint.jointTransform = node
    attacherJoint.jointComponent = self:getParentComponent(attacherJoint.jointTransform)

    attacherJoint.jointTransformVisual = xmlFile:getValue(baseName .. "#nodeVisual", nil, self.components, self.i3dMappings)
    attacherJoint.supportsHardAttach = xmlFile:getValue(baseName.."#supportsHardAttach", true)

    attacherJoint.jointOrigOffsetComponent = { localToLocal(attacherJoint.jointComponent, attacherJoint.jointTransform, 0, 0, 0) }
    attacherJoint.jointOrigRotOffsetComponent = { localRotationToLocal(attacherJoint.jointComponent, attacherJoint.jointTransform, 0, 0, 0) }

    attacherJoint.jointTransformOrig = createTransformGroup(getName(node) .. "_jointTransformOrig")
    link(getParent(node), attacherJoint.jointTransformOrig)
    setTranslation(attacherJoint.jointTransformOrig, getTranslation(node))
    setRotation(attacherJoint.jointTransformOrig, getRotation(node))

    local jointTypeStr = xmlFile:getValue(baseName.. "#jointType")
    local jointType
    if jointTypeStr ~= nil then
        jointType = AttacherJoints.jointTypeNameToInt[jointTypeStr]
        if jointType == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid jointType '%s' for attacherJoint '%s'!", tostring(jointTypeStr), baseName)
        end
    end
    if jointType == nil then
        jointType = AttacherJoints.JOINTTYPE_IMPLEMENT
    end
    attacherJoint.jointType = jointType

    local subTypeStr = xmlFile:getValue(baseName.. ".subType#name")
    if not string.isNilOrWhitespace(subTypeStr) then
        attacherJoint.subTypes = string.split(subTypeStr, " ")
    end

    local brandRestrictionStr = xmlFile:getValue(baseName.. ".subType#brandRestriction")
    if brandRestrictionStr ~= nil and string.trim(brandRestrictionStr) ~= "" then
        attacherJoint.brandRestrictions = string.split(brandRestrictionStr, " ")

        for i=1, #attacherJoint.brandRestrictions do
            local brand = g_brandManager:getBrandByName(attacherJoint.brandRestrictions[i])
            if brand ~= nil then
                attacherJoint.brandRestrictions[i] = brand
            else
                Logging.xmlError(xmlFile, "Unknown brand '%s' in '%s'", attacherJoint.brandRestrictions[i], baseName.. ".subType#brandRestriction")
                attacherJoint.brandRestrictions = nil
                break
            end
        end
    end

    local vehicleRestrictionStr = xmlFile:getValue(baseName.. ".subType#vehicleRestriction")
    if vehicleRestrictionStr ~= nil and string.trim(vehicleRestrictionStr) ~= "" then
        attacherJoint.vehicleRestrictions = string.split(vehicleRestrictionStr, " ")
    end

    attacherJoint.subTypeShowWarning = xmlFile:getValue(baseName.. ".subType#subTypeShowWarning", true)

    attacherJoint.allowsJointLimitMovement = xmlFile:getValue(baseName.."#allowsJointLimitMovement", true)
    attacherJoint.allowsLowering = xmlFile:getValue(baseName.."#allowsLowering", true)
    attacherJoint.isDefaultLowered = xmlFile:getValue(baseName.."#isDefaultLowered", false)

    attacherJoint.allowDetachingWhileLifted = xmlFile:getValue(baseName.."#allowDetachingWhileLifted", true)
    attacherJoint.allowFoldingWhileAttached = xmlFile:getValue(baseName.."#allowFoldingWhileAttached", true)

    if jointType == AttacherJoints.JOINTTYPE_TRAILER or jointType == AttacherJoints.JOINTTYPE_TRAILERLOW or jointType == AttacherJoints.JOINTTYPE_TRAILERCAR then
        attacherJoint.allowsLowering = false
    end

    attacherJoint.canTurnOnImplement = xmlFile:getValue(baseName.."#canTurnOnImplement", true)

    local rotationNode = xmlFile:getValue(baseName.. ".rotationNode#node", nil, self.components, self.i3dMappings)
    if rotationNode ~= nil then
        attacherJoint.rotationNode = rotationNode

        attacherJoint.lowerRotation = xmlFile:getValue(baseName..".rotationNode#lowerRotation", "0 0 0", true)
        attacherJoint.upperRotation = xmlFile:getValue(baseName..".rotationNode#upperRotation", nil, true) or {getRotation(rotationNode)}
        attacherJoint.rotX, attacherJoint.rotY, attacherJoint.rotZ = xmlFile:getValue(baseName..".rotationNode#startRotation", nil)
        if attacherJoint.rotX == nil then
            attacherJoint.rotX, attacherJoint.rotY, attacherJoint.rotZ = getRotation(rotationNode)
        end

        local lowerValues = {attacherJoint.lowerRotation[1], attacherJoint.lowerRotation[2], attacherJoint.lowerRotation[3]}
        local upperValues = {attacherJoint.upperRotation[1], attacherJoint.upperRotation[2], attacherJoint.upperRotation[3]}

        for i=1, 3 do
            local l = lowerValues[i]
            local u = upperValues[i]

            if l > u then
                upperValues[i] = l
                lowerValues[i] = u
            end
        end

        attacherJoint.rotX = math.clamp(attacherJoint.rotX, lowerValues[1], upperValues[1])
        attacherJoint.rotY = math.clamp(attacherJoint.rotY, lowerValues[2], upperValues[2])
        attacherJoint.rotZ = math.clamp(attacherJoint.rotZ, lowerValues[3], upperValues[3])
    end

    local rotationNode2 = xmlFile:getValue(baseName.. ".rotationNode2#node", nil, self.components, self.i3dMappings)
    if rotationNode2 ~= nil then
        attacherJoint.rotationNode2 = rotationNode2

        attacherJoint.lowerRotation2 = xmlFile:getValue(baseName..".rotationNode2#lowerRotation", nil, true) or {-attacherJoint.lowerRotation[1], -attacherJoint.lowerRotation[2], -attacherJoint.lowerRotation[3]}
        attacherJoint.upperRotation2 = xmlFile:getValue(baseName..".rotationNode2#upperRotation", nil, true) or {-attacherJoint.upperRotation[1], -attacherJoint.upperRotation[2], -attacherJoint.upperRotation[3]}
    end

    attacherJoint.transNode = xmlFile:getValue(baseName..".transNode#node", nil, self.components, self.i3dMappings)
    if attacherJoint.transNode ~= nil then
        attacherJoint.transNodeOrgTrans = {getTranslation(attacherJoint.transNode)}
        attacherJoint.transNodeHeight = xmlFile:getValue(baseName..".transNode#height", 0.12)
        attacherJoint.transNodeMinY = xmlFile:getValue(baseName..".transNode#minY")
        attacherJoint.transNodeMaxY = xmlFile:getValue(baseName..".transNode#maxY")

        attacherJoint.transNodeDependentBottomArm = xmlFile:getValue(baseName..".transNode.dependentBottomArm#node", nil, self.components, self.i3dMappings)
        attacherJoint.transNodeDependentBottomArmThreshold = xmlFile:getValue(baseName..".transNode.dependentBottomArm#threshold", math.huge)
        attacherJoint.transNodeDependentBottomArmRotation = xmlFile:getValue(baseName..".transNode.dependentBottomArm#rotation", "0 0 0", true)
    end

    -- lowerDistanceToGround is a mandatory attribute if a rotationNode is available
    if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and xmlFile:getValue(baseName..".distanceToGround#lower") == nil then
        Logging.xmlWarning(self.xmlFile, "Missing '.distanceToGround#lower' for attacherJoint '%s'. Use console command 'gsVehicleAnalyze' to get correct values!", baseName)
    end
    attacherJoint.lowerDistanceToGround = xmlFile:getValue(baseName..".distanceToGround#lower", 0.7)

    -- upperDistanceToGround is a mandatory attribute if a rotationNode is available
    if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and xmlFile:getValue(baseName..".distanceToGround#upper") == nil then
        Logging.xmlWarning(self.xmlFile, "Missing '.distanceToGround#upper' for attacherJoint '%s'. Use console command 'gsVehicleAnalyze' to get correct values!", baseName)
    end
    attacherJoint.upperDistanceToGround = xmlFile:getValue(baseName..".distanceToGround#upper", 1.0)

    if attacherJoint.lowerDistanceToGround > attacherJoint.upperDistanceToGround then
        Logging.xmlWarning(self.xmlFile, "distanceToGround#lower may not be larger than distanceToGround#upper for attacherJoint '%s'. Switching values!", baseName)
        local copy = attacherJoint.lowerDistanceToGround
        attacherJoint.lowerDistanceToGround = attacherJoint.upperDistanceToGround
        attacherJoint.upperDistanceToGround = copy
    end

    attacherJoint.lowerRotationOffset = xmlFile:getValue(baseName.."#lowerRotationOffset", 0)
    attacherJoint.upperRotationOffset = xmlFile:getValue(baseName.."#upperRotationOffset", 0)

    attacherJoint.dynamicLowerRotLimit = xmlFile:getValue(baseName.."#dynamicLowerRotLimit", false)

    attacherJoint.lockDownRotLimit = xmlFile:getValue(baseName.."#lockDownRotLimit", false)
    attacherJoint.lockUpRotLimit = xmlFile:getValue(baseName.."#lockUpRotLimit", false)
    -- only use translimit in +y. Set -y to 0
    attacherJoint.lockDownTransLimit = xmlFile:getValue(baseName.."#lockDownTransLimit", true)
    attacherJoint.lockUpTransLimit = xmlFile:getValue(baseName.."#lockUpTransLimit", false)

    local lowerRotLimitStr = "20 20 20"
    if jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
        lowerRotLimitStr = "0 0 0"
    end
    local lx, ly, lz = xmlFile:getValue(baseName.."#lowerRotLimit", lowerRotLimitStr)
    attacherJoint.lowerRotLimit = {
        math.abs(lx or 20),
        math.abs(ly or 20),
        math.abs(lz or 20)
    }

    local ux, uy, uz = xmlFile:getValue(baseName.."#upperRotLimit")
    attacherJoint.upperRotLimit = {
        math.abs(ux or lx or 20),
        math.abs(uy or ly or 20),
        math.abs(uz or lz or 20)
    }

    local lowerTransLimitStr = "0.5 0.5 0.5"
    if jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
        lowerTransLimitStr = "0 0 0"
    end
    lx, ly, lz = xmlFile:getValue(baseName.."#lowerTransLimit", lowerTransLimitStr)
    attacherJoint.lowerTransLimit = {
        math.abs(lx or 0),
        math.abs(ly or 0),
        math.abs(lz or 0)
    }

    ux, uy, uz = xmlFile:getValue(baseName.."#upperTransLimit")
    attacherJoint.upperTransLimit = {
        math.abs(ux or lx or 0),
        math.abs(uy or ly or 0),
        math.abs(uz or lz or 0)
    }

    attacherJoint.jointPositionOffset = xmlFile:getValue(baseName.."#jointPositionOffset", "0 0 0", true)

    attacherJoint.rotLimitSpring = xmlFile:getValue( baseName.."#rotLimitSpring", "0 0 0", true)
    attacherJoint.rotLimitDamping = xmlFile:getValue( baseName.."#rotLimitDamping", "1 1 1", true)
    attacherJoint.rotLimitForceLimit = xmlFile:getValue( baseName.."#rotLimitForceLimit", "-1 -1 -1", true)

    attacherJoint.transLimitSpring = xmlFile:getValue( baseName.."#transLimitSpring", "0 0 0", true)
    attacherJoint.transLimitDamping = xmlFile:getValue( baseName.."#transLimitDamping", "1 1 1", true)
    attacherJoint.transLimitForceLimit = xmlFile:getValue( baseName.."#transLimitForceLimit", "-1 -1 -1", true)

    attacherJoint.moveDefaultTime = xmlFile:getValue(baseName.."#moveTime", 0.5) * 1000
    attacherJoint.moveTime = attacherJoint.moveDefaultTime

    attacherJoint.disabledByAttacherJoints = xmlFile:getValue(baseName.."#disabledByAttacherJoints", nil, true)

    attacherJoint.enableCollision = xmlFile:getValue(baseName.."#enableCollision", false)

    attacherJoint.topArm = AttacherJointTopArm.loadFromVehicleXML(self, baseName .. ".topArm")

    local bottomArmRotationNode = xmlFile:getValue(baseName.. ".bottomArm#rotationNode", nil, self.components, self.i3dMappings)
    local translationNode = xmlFile:getValue(baseName.. ".bottomArm#translationNode", nil, self.components, self.i3dMappings)
    local referenceNode = xmlFile:getValue(baseName.. ".bottomArm#referenceNode", nil, self.components, self.i3dMappings)
    if bottomArmRotationNode ~= nil then
        local bottomArm = {}
        bottomArm.rotationNode = bottomArmRotationNode
        bottomArm.rotationNodeDir = createTransformGroup("rotationNodeDirTemp")
        link(getParent(bottomArmRotationNode), bottomArm.rotationNodeDir)
        setTranslation(bottomArm.rotationNodeDir, getTranslation(bottomArmRotationNode))
        setRotation(bottomArm.rotationNodeDir, getRotation(bottomArmRotationNode))
        bottomArm.lastDirection = {0, 0, 0}
        bottomArm.rotX, bottomArm.rotY, bottomArm.rotZ = xmlFile:getValue(baseName..".bottomArm#startRotation", nil)
        if bottomArm.rotX == nil then
            bottomArm.rotX, bottomArm.rotY, bottomArm.rotZ = getRotation(bottomArmRotationNode)
        end

        bottomArm.interpolatorGet = function()
            return getRotation(bottomArm.rotationNode)
        end
        bottomArm.interpolatorSet = function(x, y, z)
            setRotation(bottomArm.rotationNode, x, y, z)
            if self.setMovingToolDirty ~= nil then
                self:setMovingToolDirty(bottomArm.rotationNode)
            end
        end
        bottomArm.interpolatorFinished = function(_)
            bottomArm.bottomArmInterpolating = false
        end

        bottomArm.interpolatorKey = bottomArmRotationNode .. "rotation"
        bottomArm.bottomArmInterpolating = false

        if translationNode ~= nil and referenceNode ~= nil then
            bottomArm.translationNode = translationNode
            bottomArm.referenceNode = referenceNode

            local x,y,z = getTranslation(translationNode)
            if math.abs(x) >= 0.0001 or math.abs(y) >= 0.0001 or math.abs(z) >= 0.0001 then
                Logging.xmlWarning(self.xmlFile, "BottomArm translation of attacherJoint '%s' is not 0/0/0!", baseName)
            end
            bottomArm.referenceDistance = calcDistanceFrom(referenceNode, translationNode)
        end
        bottomArm.zScale = math.sign(xmlFile:getValue(baseName.. ".bottomArm#zScale", 1))
        bottomArm.lockDirection = xmlFile:getValue(baseName.. ".bottomArm#lockDirection", true)
        bottomArm.resetSpeed = xmlFile:getValue(baseName.. ".bottomArm#resetSpeed", 45)
        bottomArm.updateReferenceDistance = xmlFile:getValue(baseName.. ".bottomArm#updateReferenceDistance", false)

        bottomArm.jointPositionNode = xmlFile:getValue(baseName.. ".bottomArm#jointPositionNode", nil, self.components, self.i3dMappings)

        bottomArm.toggleVisibility = xmlFile:getValue(baseName.. ".bottomArm#toggleVisibility", false)
        if bottomArm.toggleVisibility then
            setVisibility(bottomArm.rotationNode, false)
        end

        if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
             local toolbarI3dFilename = Utils.getFilename(xmlFile:getValue(baseName.. ".toolbar#filename", "$data/shared/assets/toolbars/toolbars.i3d"), self.baseDirectory)
             local arguments = {
                 bottomArm = bottomArm,
                 referenceNode = referenceNode
             }
             bottomArm.sharedLoadRequestIdToolbar = self:loadSubSharedI3DFile(toolbarI3dFilename, false, false, self.onBottomArmToolbarI3DLoaded, self, arguments)
        end

        bottomArm.minWidth, bottomArm.maxWidth = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2], AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2]
        local categoryRange = xmlFile:getValue(baseName .. ".bottomArm#categoryRange", "1 4", true)
        if categoryRange ~= nil and #categoryRange >= 1 then
            bottomArm.minWidth = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[categoryRange[1]] or bottomArm.minWidth
            bottomArm.maxWidth = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[categoryRange[2] or categoryRange[1]] or bottomArm.maxWidth
        end

        local widthRange = xmlFile:getValue(baseName .. ".bottomArm#widthRange", nil, true)
        if widthRange ~= nil and #widthRange >= 1 then
            bottomArm.minWidth = widthRange[1] or bottomArm.minWidth
            bottomArm.maxWidth = widthRange[2] or widthRange[1] or bottomArm.maxWidth
        end

        if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
            if not xmlFile:hasProperty(baseName .. ".bottomArm#categoryRange") and not xmlFile:hasProperty(baseName .. ".bottomArm#widthRange") then
                Logging.xmlWarning(xmlFile, "Missing categoryRange or widthRange attribute for bottom arm in '%s'", baseName)
            end
        end

        bottomArm.armLeft = xmlFile:getValue(baseName .. ".bottomArm.armLeft#node", nil, self.components, self.i3dMappings)
        bottomArm.armLeftReferenceNode = xmlFile:getValue(baseName .. ".bottomArm.armLeft#referenceNode", nil, self.components, self.i3dMappings)
        if bottomArm.armLeft ~= nil and bottomArm.armLeftReferenceNode ~= nil then
            bottomArm.armLeftLength = calcDistanceFrom(bottomArm.armLeft, bottomArm.armLeftReferenceNode)
        end

        bottomArm.armRight = xmlFile:getValue(baseName .. ".bottomArm.armRight#node", nil, self.components, self.i3dMappings)
        bottomArm.armRightReferenceNode = xmlFile:getValue(baseName .. ".bottomArm.armRight#referenceNode", nil, self.components, self.i3dMappings)
        if bottomArm.armRight ~= nil and bottomArm.armRightReferenceNode ~= nil then
            bottomArm.armRightLength = calcDistanceFrom(bottomArm.armRight, bottomArm.armRightReferenceNode)
        end

        bottomArm.ballVisibility = xmlFile:getValue(baseName .. ".bottomArm#ballVisibility", true)

        if bottomArm.armLeft ~= nil and bottomArm.armRight ~= nil and bottomArm.referenceNode ~= nil then
            bottomArm.variableWidthAvailable = true
            local defaultWidth

            local defaultCategory = xmlFile:getValue(baseName .. ".bottomArm#defaultCategory")
            if defaultCategory ~= nil then
                if defaultCategory >= 0 and defaultCategory <= 4 then
                    defaultWidth = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[defaultCategory]
                end
            end

            if defaultWidth == nil then
                defaultWidth = xmlFile:getValue(baseName .. ".bottomArm#defaultWidth")
            end


            if defaultWidth == nil then
                local xOffset, _, _ = localToLocal(bottomArm.armLeftReferenceNode or bottomArm.armLeft, bottomArm.referenceNode, 0, 0, 0)
                defaultWidth = math.abs(xOffset) * 2
            end

            bottomArm.defaultWidth = defaultWidth
        else
            bottomArm.defaultWidth = (bottomArm.minWidth + bottomArm.maxWidth) * 0.5
        end

        if self.setMovingPartReferenceNode ~= nil then
            bottomArm.leftNode = xmlFile:getValue(baseName .. ".bottomArm#leftNode", nil, self.components, self.i3dMappings)
            bottomArm.rightNode = xmlFile:getValue(baseName .. ".bottomArm#rightNode", nil, self.components, self.i3dMappings)
        end

        attacherJoint.bottomArm = bottomArm
    end

    if self.isClient then
        attacherJoint.sampleAttach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "attachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        attacherJoint.sampleDetach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "detachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    attacherJoint.steeringBarLeftNode = xmlFile:getValue(baseName.. ".steeringBars#leftNode", nil, self.components, self.i3dMappings)
    attacherJoint.steeringBarRightNode = xmlFile:getValue(baseName.. ".steeringBars#rightNode", nil, self.components, self.i3dMappings)
    attacherJoint.steeringBarForceUsage = xmlFile:getValue(baseName.. ".steeringBars#forceUsage", true)

    attacherJoint.visualNodes = xmlFile:getValue(baseName.. ".visuals#nodes", nil, self.components, self.i3dMappings, true)
    for i=1, #attacherJoint.visualNodes do
        local visualNode = attacherJoint.visualNodes[i]

        if spec.visualNodeToAttacherJoints[visualNode] == nil then
            spec.visualNodeToAttacherJoints[visualNode] = {}
        end

        table.insert(spec.visualNodeToAttacherJoints[visualNode], attacherJoint)
    end

    attacherJoint.hideVisuals = xmlFile:getValue(baseName.. ".visuals#hide", nil, self.components, self.i3dMappings, true)
    for i=1, #attacherJoint.hideVisuals do
        local hideNode = attacherJoint.hideVisuals[i]

        if spec.hideVisualNodeToAttacherJoints[hideNode] == nil then
            spec.hideVisualNodeToAttacherJoints[hideNode] = {}
        end

        table.insert(spec.hideVisualNodeToAttacherJoints[hideNode], attacherJoint)
    end

    attacherJoint.changeObjects = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, attacherJoint.changeObjects, self.components, self)
    ObjectChangeUtil.setObjectChanges(attacherJoint.changeObjects, false, self, self.setMovingToolDirty, true)
    attacherJoint.delayedObjectChanges = xmlFile:getValue(baseName.."#delayedObjectChanges", true)
    attacherJoint.delayedObjectChangesOnAttach = xmlFile:getValue(baseName.."#delayedObjectChangesOnAttach", false)

    attacherJoint.additionalAttachment = {}

    local _, _, zOffset = localToLocal(attacherJoint.jointTransform, self.rootNode, 0, 0, 0)
    attacherJoint.attacherJointDirection = xmlFile:getValue(baseName .. "#direction", math.sign(zOffset))

    attacherJoint.useTopLights = xmlFile:getValue(baseName .. "#useTopLights", attacherJoint.attacherJointDirection == 1)

    attacherJoint.rootNode = xmlFile:getValue(baseName.."#rootNode", self:getParentComponent(attacherJoint.jointTransform), self.components, self.i3dMappings)
    attacherJoint.rootNodeBackup = attacherJoint.rootNode
    attacherJoint.jointIndex = 0

    attacherJoint.isBlocked = false
    attacherJoint.comboTime = xmlFile:getValue(baseName .. "#comboTime")

    local schemaKey = baseName.. ".schema"
    if xmlFile:hasProperty(schemaKey) then
        local x, y = xmlFile:getValue(schemaKey .. "#position")
        if x == nil then
            Logging.xmlWarning(self.xmlFile, "Missing values for '%s'", schemaKey .. "#position")
        else
            local liftedOffsetX, liftedOffsetY = xmlFile:getValue(schemaKey.."#liftedOffset", "0 5")

            self.schemaOverlay:addAttacherJoint(
                x, y,
                xmlFile:getValue(schemaKey .. "#rotation", 0),
                xmlFile:getValue(schemaKey .. "#invertX", false),
                liftedOffsetX, liftedOffsetY
            )
        end
    else
        Logging.xmlWarning(self.xmlFile, "Missing schema overlay attacherJoint '%s'!", baseName)
    end

    return true
end


---Called when toolbar was loaded
-- @param integer i3dNode top arm i3d node
-- @param table args async arguments
function AttacherJoints:onBottomArmToolbarI3DLoaded(i3dNode, failedReason, args)
    local bottomArm = args.bottomArm
    local referenceNode = args.referenceNode

    if i3dNode ~= 0 then
        local rootNode = getChildAt(i3dNode, 0)
        link(referenceNode, rootNode)
        setTranslation(rootNode, 0, 0, 0)
        setVisibility(rootNode, false)

        local activeIndex = AttacherJoints.getClosestLowerLinkCategoryIndex(bottomArm.defaultWidth or AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2])

        bottomArm.toolbarNode = rootNode
        bottomArm.toolbars = {}
        for index=1, getNumOfChildren(rootNode) do
            local toolbar = getChildAt(rootNode, index - 1)
            setTranslation(toolbar, 0, 0, 0)
            setVisibility(toolbar, activeIndex == index - 1)

            table.insert(bottomArm.toolbars, toolbar)
        end

        delete(i3dNode)
    end
end


---
function AttacherJoints:raiseActive(superFunc)
    local spec = self.spec_attacherJoints

    superFunc(self)
    for _,implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            implement.object:raiseActive()
        end
    end
end


---
function AttacherJoints:registerActionEvents(superFunc, excludedVehicle)
    local spec = self.spec_attacherJoints

    superFunc(self, excludedVehicle)
    if self ~= excludedVehicle then
        -- at first we register the inputs of the selected vehicle
        -- so they got the higest prio and cannot be overwritten by another vehicle
        local selectedObject = self:getSelectedObject()
        if selectedObject ~= nil and self ~= selectedObject.vehicle and excludedVehicle ~= selectedObject.vehicle then
            selectedObject.vehicle:registerActionEvents()
        end

        for _,implement in pairs(spec.attachedImplements) do
            if implement.object ~= nil then
                if selectedObject == nil then printCallstack() end
                implement.object:registerActionEvents(selectedObject.vehicle)
            end
        end
    end
end


---
function AttacherJoints:removeActionEvents(superFunc)
    local spec = self.spec_attacherJoints

    superFunc(self)

    for _,implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            implement.object:removeActionEvents()
        end
    end
end


---Add to physics
-- @return boolean success success
function AttacherJoints:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end

    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        if not implement.object.spec_attachable.isHardAttached then
            self:createAttachmentJoint(implement, true)
        else
            -- needs to be called on hard attached implements, as it automatically is added to physics as well
            implement.object:addToPhysics()
        end
    end

    return true
end


---Add to physics
-- @return boolean success success
function AttacherJoints:removeFromPhysics(superFunc)
    local spec = self.spec_attacherJoints

    for _, implement in pairs(spec.attachedImplements) do
        if not implement.object.spec_attachable.isHardAttached then
            local jointDesc = spec.attacherJoints[implement.jointDescIndex]
            if jointDesc.jointIndex ~= 0 then
                jointDesc.jointIndex = 0
            end
        else
            -- needs to be called on hard attached implements, as it automatically is removed from physics as well
            implement.object:removeFromPhysics()
        end
    end

    if not superFunc(self) then
        return false
    end

    return true
end


---Returns total mass of vehicle (optional including attached vehicles)
-- @param boolean onlyGivenVehicle use only the given vehicle, if false or nil it includes all attachables
-- @return float totalMass total mass
function AttacherJoints:getTotalMass(superFunc, onlyGivenVehicle)
    local spec = self.spec_attacherJoints
    local mass = superFunc(self)

    if onlyGivenVehicle == nil or not onlyGivenVehicle then
        for _, implement in pairs(spec.attachedImplements) do
            local object = implement.object
            if object ~= nil then
                mass = mass + object:getTotalMass(onlyGivenVehicle)
            end
        end
    end

    return mass
end


---
function AttacherJoints:getAdditionalComponentMass(superFunc, component)
    local additionalMass = superFunc(self, component)

    if component.node == self.rootNode then
        local spec = self.spec_attacherJoints
        for _, implement in pairs(spec.attachedImplements) do
            local object = implement.object
            if object ~= nil and object.spec_attachable.isHardAttached then
                additionalMass = additionalMass + object:getTotalMass(true)
            end
        end
    end

    return additionalMass
end


---Inserts all child vehicles into the given table
-- @param table vehicles child vehicles table
function AttacherJoints:addChildVehicles(superFunc, vehicles, rootVehicle)
    local spec = self.spec_attacherJoints

    for _, implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.addChildVehicles ~= nil then
            object:addChildVehicles(vehicles, rootVehicle)
        end
    end

    return superFunc(self, vehicles, rootVehicle)
end


---Returns air consumer usage of attached vehicles
-- @return float usage air usage
function AttacherJoints:getAirConsumerUsage(superFunc)
    local spec = self.spec_attacherJoints
    local usage = superFunc(self)

    for _, implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.getAttachbleAirConsumerUsage ~= nil then
            usage = usage + object:getAttachbleAirConsumerUsage()
        end
    end

    return usage
end


---Returns if the vehicle is currently requiring power for a certain activity (e.g. for unloading via the pipe) - this can be used to automatically try to enable the power (e.g. motor turn on)
function AttacherJoints:getRequiresPower(superFunc)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            if implement.object:getRequiresPower() then
                return true
            end
        end
    end

    return superFunc(self)
end


---
function AttacherJoints:addVehicleToAIImplementList(superFunc, list)
    superFunc(self, list)

    for _, implement in pairs(self:getAttachedImplements()) do
        local object = implement.object
        if object ~= nil and object.addVehicleToAIImplementList ~= nil then
            object:addVehicleToAIImplementList(list)
        end
    end
end


---
function AttacherJoints:collectAIAgentAttachments(superFunc, aiDrivableVehicle)
    superFunc(self, aiDrivableVehicle)

    for _, implement in pairs(self:getAttachedImplements()) do
        local object = implement.object
        if object ~= nil and object.collectAIAgentAttachments ~= nil then
            object:collectAIAgentAttachments(aiDrivableVehicle)
            aiDrivableVehicle:startNewAIAgentAttachmentChain()
        end
    end
end


---
function AttacherJoints:setAIVehicleObstacleStateDirty(superFunc)
    superFunc(self)

    for _, implement in pairs(self:getAttachedImplements()) do
        local object = implement.object
        if object ~= nil and object.setAIVehicleObstacleStateDirty ~= nil then
            object:setAIVehicleObstacleStateDirty()
        end
    end
end


---
function AttacherJoints:getDirectionSnapAngle(superFunc)
    local spec = self.spec_attacherJoints
    local maxAngle = superFunc(self)

    for _, implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.getDirectionSnapAngle ~= nil then
            maxAngle = math.max(maxAngle + object:getDirectionSnapAngle())
        end
    end

    return maxAngle
end


---
function AttacherJoints:getFillLevelInformation(superFunc, display)
    local spec = self.spec_attacherJoints

    superFunc(self, display)

    for _, implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.getFillLevelInformation ~= nil then
            object:getFillLevelInformation(display)
        end
    end
end


---
function AttacherJoints:attachableAddToolCameras(superFunc)
    local spec = self.spec_attacherJoints
    superFunc(self)

    for _,implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.attachableAddToolCameras ~= nil then
            object:attachableAddToolCameras()
        end
    end
end


---
function AttacherJoints:attachableRemoveToolCameras(superFunc)
    local spec = self.spec_attacherJoints
    superFunc(self)

    for _,implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.attachableRemoveToolCameras ~= nil then
            object:attachableRemoveToolCameras()
        end
    end
end


---
function AttacherJoints:registerSelectableObjects(superFunc, selectableObjects)
    superFunc(self, selectableObjects)

    local spec = self.spec_attacherJoints
    for _,implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.registerSelectableObjects ~= nil then
            object:registerSelectableObjects(selectableObjects)
        end
    end
end


---
function AttacherJoints:getIsReadyForAutomatedTrainTravel(superFunc)
    local spec = self.spec_attacherJoints
    for _,implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil and object.getIsReadyForAutomatedTrainTravel ~= nil then
            if not object:getIsReadyForAutomatedTrainTravel() then
                return false
            end
        end
    end

    return superFunc(self)
end


---
function AttacherJoints:getIsAutomaticShiftingAllowed(superFunc)
    local spec = self.spec_attacherJoints
    local lastSpeed = self:getLastSpeed()
    for _, implement in pairs(spec.attachedImplements) do
        if lastSpeed < 2 then
            if implement.attachingIsInProgress then
                return false
            else
                local jointDescIndex = implement.jointDescIndex
                local jointDesc = spec.attacherJoints[jointDescIndex]
                if jointDesc.isMoving then
                    return false
                end
            end
        end

        local object = implement.object
        if object ~= nil and object.getIsAutomaticShiftingAllowed ~= nil then
            if not object:getIsAutomaticShiftingAllowed() then
                return false
            end
        end
    end

    return superFunc(self)
end


---
function AttacherJoints:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
    if not superFunc(self, xmlFile, key, group) then
        return false
    end

    group.attacherJointIndices = {}

    local attacherJointIndices = xmlFile:getValue(key .. "#attacherJointIndices", nil, true)
    if attacherJointIndices ~= nil then
        for _, attacherJointIndex in ipairs(attacherJointIndices) do
            table.insert(group.attacherJointIndices, attacherJointIndex)
        end
    end

    if #group.attacherJointIndices == 0 then
        group.attacherJointIndices = nil
    end

    group.attacherJointNodes = xmlFile:getValue(key .. "#attacherJointNodes", nil, self.components, self.i3dMappings, true)
    if #group.attacherJointNodes == 0 then
        group.attacherJointNodes = nil
    end

    return true
end


---
function AttacherJoints:getIsDashboardGroupActive(superFunc, group)
    if group.attacherJointNodes ~= nil and self.finishedLoading then
        if group.attacherJointIndices == nil then
            group.attacherJointIndices = {}
        end

        for _, node in ipairs(group.attacherJointNodes) do
            local attacherJointIndex = self:getAttacherJointIndexByNode(node)
            if attacherJointIndex ~= nil then
                table.insert(group.attacherJointIndices, attacherJointIndex)
            end
        end

        if #group.attacherJointIndices == 0 then
            group.attacherJointIndices = nil
        end

        group.attacherJointNodes = nil
    end

    if group.attacherJointIndices ~= nil then
        local hasAttachment = false
        for _, jointIndex in ipairs(group.attacherJointIndices) do
            if self:getImplementFromAttacherJointIndex(jointIndex) ~= nil then
                hasAttachment = true
            end
        end

        if not hasAttachment then
            return false
        end
    end

    return superFunc(self, group)
end


---
function AttacherJoints:loadAttacherJointHeightNode(superFunc, xmlFile, key, heightNode, attacherJointNode)
    heightNode.disablingAttacherJointIndices = xmlFile:getValue(key .. "#disablingAttacherJointIndices", "", true)

    return superFunc(self, xmlFile, key, heightNode, attacherJointNode)
end


---
function AttacherJoints:getIsAttacherJointHeightNodeActive(superFunc, heightNode)
    for _, jointIndex in ipairs(heightNode.disablingAttacherJointIndices) do
        if self:getImplementFromAttacherJointIndex(jointIndex) ~= nil then
            return false
        end
    end

    return superFunc(self, heightNode)
end


---Returns true if detach is allowed
-- @return boolean detachAllowed detach is allowed
function AttacherJoints:isDetachAllowed(superFunc)
    local detachAllowed, warning, showWarning = superFunc(self)
    if not detachAllowed then
        return detachAllowed, warning, showWarning
    end

    local spec = self.spec_attacherJoints
    for attacherJointIndex, attacherJoint in ipairs(spec.attacherJoints) do
        if not attacherJoint.allowDetachingWhileLifted then
            if not attacherJoint.moveDown then
                local implement = self:getImplementByJointDescIndex(attacherJointIndex)
                if implement ~= nil then
                    local inputAttacherJoint = implement.object:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)
                    if inputAttacherJoint ~= nil and not inputAttacherJoint.forceAllowDetachWhileLifted then
                        return false, string.format(spec.texts.lowerImplementFirst, implement.object.typeDesc)
                    end
                end
            end
        end
    end

    return true
end


---
function AttacherJoints:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    local spec = self.spec_attacherJoints
    for attacherJointIndex, attacherJoint in ipairs(spec.attacherJoints) do
        if not attacherJoint.allowFoldingWhileAttached then
            if attacherJoint.jointIndex ~= 0 then
                return false, spec.texts.warningFoldingAttacherJoint
            end
        end
    end

    return superFunc(self, direction, onAiTurnOn)
end


---Returns true if foliage destruction is allowed
-- @return boolean isAllowed tfoliage destruction is allowed
function AttacherJoints:getIsWheelFoliageDestructionAllowed(superFunc, wheel)
    if not superFunc(self, wheel) then
        return false
    end

    local spec = self.spec_attacherJoints
    for _,implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil then
            if object.getBlockFoliageDestruction ~= nil then
                if object:getBlockFoliageDestruction() then
                    return false
                end
            end
        end
    end

    return true
end


---Returns if controlled actions are allowed
-- @return boolean allow allow controlled actions
-- @return string warning not allowed warning
function AttacherJoints:getAreControlledActionsAllowed(superFunc)
    local allowed, warning = superFunc(self)
    if not allowed then
        return false, warning
    end

    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local object = implement.object
        if object ~= nil then
            if object.getAreControlledActionsAllowed ~= nil then
                allowed, warning = object:getAreControlledActionsAllowed()
                if not allowed then
                    return false, warning
                end
            end
        end

        if implement.attachingIsInProgress then
            return false
        end
    end

    return true, warning
end


---
function AttacherJoints:getConnectionHoseConfigIndex(superFunc)
    local index = superFunc(self)
    index = self.xmlFile:getValue("vehicle.attacherJoints#connectionHoseConfigId", index)

    if self.configurations["attacherJoint"] ~= nil then
        local configKey = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations["attacherJoint"] - 1)
        index = self.xmlFile:getValue(configKey .. "#connectionHoseConfigId", index)
    end

    return index
end


---
function AttacherJoints:getPowerTakeOffConfigIndex(superFunc)
    local index = superFunc(self)
    index = self.xmlFile:getValue("vehicle.attacherJoints#powerTakeOffConfigId", index)

    if self.configurations["attacherJoint"] ~= nil then
        local configKey = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations["attacherJoint"] - 1)
        index = self.xmlFile:getValue(configKey .. "#powerTakeOffConfigId", index)
    end

    return index
end


---
function AttacherJoints:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_attacherJoints
        self:clearActionEventsTable(spec.actionEvents)

        -- ignore vehicle selection on 'getIsActiveForInput', so we can select the target vehicle and attach or lower it
        if isActiveForInputIgnoreSelection then
            if #spec.attacherJoints > 0 then
                -- only display lower and attach action if selected implement is direct child of vehicle, not sub child
                local selectedImplement = self:getSelectedImplement()
                if selectedImplement ~= nil and selectedImplement.object ~= self then
                    for _, attachedImplement in pairs(spec.attachedImplements) do
                        if attachedImplement == selectedImplement then
                            -- custom registration of the action event. This allows us to overwritte it in the implement (e.g in Foldable)
                            selectedImplement.object:registerLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, selectedImplement.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)
                        end
                    end
                end

                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.LOWER_ALL_IMPLEMENTS, self, AttacherJoints.actionEventLowerAllImplements, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end

            if self:getSelectedVehicle() == self then
                local state, _ = self:registerSelfLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, self, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)

                -- if the selected attacher vehicle can not be lowered and we got only one implement that can be lowered
                -- we add the lowering action for the first implement
                if state == nil or not state then
                    if #spec.attachedImplements == 1 then
                        local firstImplement = spec.attachedImplements[1]
                        if firstImplement ~= nil then
                            firstImplement.object:registerLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, firstImplement.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, nil, true)
                        end
                    end
                end
            end

            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ATTACH, self, AttacherJoints.actionEventAttach, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)

            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DETACH, self, AttacherJoints.actionEventDetach, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

            AttacherJoints.updateActionEvents(self)
        end
    end
end


---Called on activate
function AttacherJoints:onActivate()
    self:activateAttachments()
end


---Called on deactivate
function AttacherJoints:onDeactivate()
    self:deactivateAttachments()
    if self.isClient then
        local spec = self.spec_attacherJoints
        g_soundManager:stopSample(spec.samples.hydraulic)
        spec.isHydraulicSamplePlaying = false
    end
end


---
function AttacherJoints:onReverseDirectionChanged(direction)
    local spec = self.spec_attacherJoints

    if spec.attacherJointCombos ~= nil then
        for _, joint in pairs(spec.attacherJointCombos.joints) do
            joint.time = math.abs(joint.time - spec.attacherJointCombos.duration)
        end
    end
end


---
function AttacherJoints:onStateChange(state, data)
    local spec = self.spec_attacherJoints

    for _, implement in pairs(spec.attachedImplements) do
        if implement.object ~= nil then
            implement.object:raiseStateChange(state, data)
        end
    end

    if state == VehicleStateChange.LOWER_ALL_IMPLEMENTS then
        if #spec.attacherJoints > 0 then
            self:startAttacherJointCombo()
        end
    end
end


---
function AttacherJoints:onLightsTypesMaskChanged(lightsTypesMask)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setLightsTypesMask ~= nil then
            vehicle:setLightsTypesMask(lightsTypesMask, true, true)
        end
    end
end


---
function AttacherJoints:onTurnLightStateChanged(state)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setTurnLightState ~= nil then
            vehicle:setTurnLightState(state, true, true)
        end
    end
end


---
function AttacherJoints:onBrakeLightsVisibilityChanged(visibility)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setBrakeLightsVisibility ~= nil then
            vehicle:setBrakeLightsVisibility(visibility)
        end
    end
end


---
function AttacherJoints:onReverseLightsVisibilityChanged(visibility)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setReverseLightsVisibility ~= nil then
            vehicle:setReverseLightsVisibility(visibility)
        end
    end
end


---
function AttacherJoints:onBeaconLightsVisibilityChanged(visibility)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.setBeaconLightsVisibility ~= nil then
            vehicle:setBeaconLightsVisibility(visibility, true, true)
        end
    end
end


---
function AttacherJoints:onBrake(brakePedal)
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil and vehicle.brake ~= nil then
            vehicle:brake(brakePedal)
        end
    end
end


---
function AttacherJoints:onTurnedOn()
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil then
            local turnedOnVehicleSpec = vehicle.spec_turnOnVehicle
            if turnedOnVehicleSpec then
                if turnedOnVehicleSpec.turnedOnByAttacherVehicle then
                    vehicle:setIsTurnedOn(true, true)
                end
            end
        end
    end
end


---
function AttacherJoints:onTurnedOff()
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil then
            local turnedOnVehicleSpec = vehicle.spec_turnOnVehicle
            if turnedOnVehicleSpec then
                if turnedOnVehicleSpec.turnedOnByAttacherVehicle then
                    vehicle:setIsTurnedOn(false, true)
                end
            end
        end
    end
end


---
function AttacherJoints:onLeaveVehicle()
    local spec = self.spec_attacherJoints
    for _, implement in pairs(spec.attachedImplements) do
        local vehicle = implement.object
        if vehicle ~= nil then
            SpecializationUtil.raiseEvent(vehicle, "onLeaveRootVehicle")
        end
    end
end









---
function AttacherJoints.getAttacherJointCompatibility(vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
    if inputAttacherJoint.forcedAttachingDirection ~= 0 and attacherJoint.attacherJointDirection ~= nil then
        if inputAttacherJoint.forcedAttachingDirection ~= attacherJoint.attacherJointDirection then
            return false
        end
    end

    if attacherJoint.isBlocked then
        return false
    end

    if attacherJoint.subTypes ~= nil then
        if inputAttacherJoint.subTypes == nil then
            return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
        end

        local found = false
        for i=1, #attacherJoint.subTypes do
            for j=1, #inputAttacherJoint.subTypes do
                if attacherJoint.subTypes[i] == inputAttacherJoint.subTypes[j] then
                    found = true
                    break
                end
            end
        end

        if not found then
            if attacherJoint.subTypeShowWarning and inputAttacherJoint.subTypeShowWarning then
                return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
            end

            return false
        end
    else
        if inputAttacherJoint.subTypes ~= nil then
            if inputAttacherJoint.subTypeShowWarning and attacherJoint.subTypeShowWarning then
                return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
            end

            return false
        end
    end

    if attacherJoint.brandRestrictions ~= nil then
        local found = false
        for i=1, #attacherJoint.brandRestrictions do
            if inputAttacherVehicle.brand ~= nil then
                if inputAttacherVehicle.brand == attacherJoint.brandRestrictions[i] then
                    found = true
                    break
                end
            end
        end

        if not found then
            local brandString = ""
            for i=1, #attacherJoint.brandRestrictions do
                if i > 1 then
                    brandString = brandString .. ", "
                end
                brandString = brandString .. attacherJoint.brandRestrictions[i].title
            end

            return false, string.format(vehicle.spec_attacherJoints.texts.warningToolBrandNotCompatible, brandString)
        end
    end

    if attacherJoint.vehicleRestrictions ~= nil then
        local found = false
        for i=1, #attacherJoint.vehicleRestrictions do
            if inputAttacherVehicle.configFileName:find(attacherJoint.vehicleRestrictions[i]) ~= nil then
                found = true
                break
            end
        end

        if not found then
            return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
        end
    end

    return true
end




---
function AttacherJoints.findVehicleInAttachRange()
    log("function 'AttacherJoints.findVehicleInAttachRange' is deprecated. Use 'AttacherJoints.updateVehiclesInAttachRange' instead. Valid output of this function is now up to 5 frames delayed, if parameter 4 is not 'true'.")
end


---
function AttacherJoints.updateVehiclesInAttachRange(vehicle, maxDistanceSq, maxAngle, fullUpdate)
    local spec = vehicle.spec_attacherJoints

    if spec ~= nil then
        local attachableInfo = spec.attachableInfo
        local pendingInfo = spec.pendingAttachableInfo

        -- first, check if attached implements can attach something
        if vehicle.getAttachedImplements ~= nil then
            local implements = vehicle:getAttachedImplements()
            for _,implement in pairs(implements) do
                if implement.object ~= nil then
                    local attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex, warning = AttacherJoints.updateVehiclesInAttachRange(implement.object, maxDistanceSq, maxAngle, fullUpdate)
                    if attacherVehicle ~= nil then
                        attachableInfo.attacherVehicle, attachableInfo.attacherVehicleJointDescIndex, attachableInfo.attachable, attachableInfo.attachableJointDescIndex, attachableInfo.warning = attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex, warning
                        return attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex, warning
                    end
                end
            end
        end

        local numJoints = #g_currentMission.vehicleSystem.inputAttacherJoints
        local minUpdateJoints = math.max(math.floor(numJoints / 5), 1) -- update each joint at least every 5 frames
        local firstJoint = spec.lastInputAttacherCheckIndex % numJoints + 1
        local lastJoint = math.min(firstJoint + minUpdateJoints, numJoints)

        if fullUpdate then
            firstJoint = 1
            lastJoint = numJoints
        end

        spec.lastInputAttacherCheckIndex = lastJoint % numJoints

        for attacherJointIndex=1, #spec.attacherJoints do
            local attacherJoint = spec.attacherJoints[attacherJointIndex]

            if attacherJoint.jointIndex == 0 then
                if vehicle:getIsAttachingAllowed(attacherJoint) then
                    local x, y, z = getWorldTranslation(attacherJoint.jointTransform)

                    for i=firstJoint, lastJoint do
                        local jointInfo = g_currentMission.vehicleSystem.inputAttacherJoints[i]

                        if jointInfo.jointType == attacherJoint.jointType then
                            if jointInfo.vehicle:getIsInputAttacherActive(jointInfo.inputAttacherJoint) then
                                local distSq = MathUtil.vector2LengthSq(x-jointInfo.translation[1], z-jointInfo.translation[3])
                                if distSq < maxDistanceSq and distSq < pendingInfo.minDistance then
                                    local distY = y-jointInfo.translation[2]
                                    local distSqY = distY*distY

                                    if distSqY < maxDistanceSq*4 and distSqY < pendingInfo.minDistanceY then
                                        if jointInfo.vehicle:getActiveInputAttacherJointDescIndex() == nil or jointInfo.vehicle:getAllowMultipleAttachments() then
                                            local compatibility, notAllowedWarning = getAttacherJointCompatibility(vehicle, attacherJoint, jointInfo.vehicle, jointInfo.inputAttacherJoint)
                                            if compatibility then
                                                local angleInRange
                                                local attachAngleLimitAxis = jointInfo.inputAttacherJoint.attachAngleLimitAxis
                                                if attachAngleLimitAxis == 1 then
                                                    local dx, _, _ = localDirectionToLocal(jointInfo.node, attacherJoint.jointTransform, 1, 0, 0)
                                                    angleInRange = dx > maxAngle
                                                elseif attachAngleLimitAxis == 2 then
                                                    local _, dy, _ = localDirectionToLocal(jointInfo.node, attacherJoint.jointTransform, 0, 1, 0)
                                                    angleInRange = dy > maxAngle
                                                else
                                                    local _, _, dz = localDirectionToLocal(jointInfo.node, attacherJoint.jointTransform, 0, 0, 1)
                                                    angleInRange = dz > maxAngle
                                                end

                                                if angleInRange then
                                                    pendingInfo.minDistance = distSq
                                                    pendingInfo.minDistanceY = distSqY
                                                    pendingInfo.attacherVehicle = vehicle
                                                    pendingInfo.attacherVehicleJointDescIndex = attacherJointIndex
                                                    pendingInfo.attachable = jointInfo.vehicle
                                                    pendingInfo.attachableJointDescIndex = jointInfo.jointIndex
                                                end
                                            else
                                                pendingInfo.warning = pendingInfo.warning or notAllowedWarning
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if spec.lastInputAttacherCheckIndex == 0 or numJoints == 0 then
            attachableInfo.attacherVehicle = pendingInfo.attacherVehicle
            attachableInfo.attacherVehicleJointDescIndex = pendingInfo.attacherVehicleJointDescIndex
            attachableInfo.attachable = pendingInfo.attachable
            attachableInfo.attachableJointDescIndex = pendingInfo.attachableJointDescIndex
            attachableInfo.warning = pendingInfo.warning

            pendingInfo.minDistance = math.huge
            pendingInfo.minDistanceY = math.huge
            pendingInfo.attacherVehicle = nil
            pendingInfo.attacherVehicleJointDescIndex = nil
            pendingInfo.attachable = nil
            pendingInfo.attachableJointDescIndex = nil
            pendingInfo.warning = nil
        end

        return attachableInfo.attacherVehicle, attachableInfo.attacherVehicleJointDescIndex, attachableInfo.attachable, attachableInfo.attachableJointDescIndex, attachableInfo.warning
    end

    return nil, nil, nil, nil
end


---
function AttacherJoints.actionEventAttach(self, actionName, inputValue, callbackState, isAnalog)
    -- attach or detach something
    local info = self.spec_attacherJoints.attachableInfo
    if info.attachable ~= nil then
        -- attach
        local attachAllowed, warning = info.attachable:isAttachAllowed(self:getActiveFarm(), info.attacherVehicle)
        if attachAllowed then
            if self.isServer then
                self:attachImplementFromInfo(info)
            else
                g_client:getServerConnection():sendEvent(VehicleAttachRequestEvent.new(info))
            end
        else
            if warning ~= nil then
                g_currentMission:showBlinkingWarning(warning, 2000)
            end
        end
    else
        -- detach
        local object = self:getSelectedVehicle()
        if object ~= nil and object ~= self and object.isDetachAllowed ~= nil then
            local detachAllowed, warning, showWarning = object:isDetachAllowed()
            if detachAllowed then
                object:startDetachProcess()
            elseif showWarning == nil or showWarning then
                g_currentMission:showBlinkingWarning(warning or self.spec_attacherJoints.texts.detachNotAllowed, 2000)
            end
        end
    end
end


---
function AttacherJoints.actionEventDetach(self, actionName, inputValue, callbackState, isAnalog)
    -- detach
    local object = self:getSelectedVehicle()
    if object ~= nil and object ~= self and object.isDetachAllowed ~= nil then
        local detachAllowed, warning, showWarning = object:isDetachAllowed()
        if detachAllowed then
            object:startDetachProcess()
        elseif showWarning == nil or showWarning then
            g_currentMission:showBlinkingWarning(warning or self.spec_attacherJoints.texts.detachNotAllowed, 2000)
        end
    end
end


---
function AttacherJoints.actionEventLowerImplement(self, actionName, inputValue, callbackState, isAnalog)
    -- self is the implement object to lower, so we call the function on the attacher vehicle
    if self.getAttacherVehicle ~= nil then
        self:getAttacherVehicle():handleLowerImplementEvent()
    end
end


---
function AttacherJoints.actionEventLowerAllImplements(self, actionName, inputValue, callbackState, isAnalog)
    self:startAttacherJointCombo(true)

    self.rootVehicle:raiseStateChange(VehicleStateChange.LOWER_ALL_IMPLEMENTS)
end


---
function AttacherJoints.updateActionEvents(self)
    local spec = self.spec_attacherJoints
    local info = spec.attachableInfo

    if self.isClient then
        if spec.actionEvents ~= nil then
            local attachActionEvent = spec.actionEvents[InputAction.ATTACH]
            if attachActionEvent ~= nil then
                local visible = false

                if self:getCanToggleAttach() then
                    if info.warning ~= nil then
                        g_currentMission:showBlinkingWarning(info.warning, 500)
                    end

                    local text = ""
                    local prio = GS_PRIO_VERY_LOW

                    local selectedVehicle = self:getSelectedVehicle()
                    if selectedVehicle ~= nil and not selectedVehicle.isDeleted and selectedVehicle.isDetachAllowed ~= nil and selectedVehicle:isDetachAllowed() then
                        if selectedVehicle:getAttacherVehicle() ~= nil then
                            visible = true
                            text = spec.texts.actionDetach
                        end
                    end

                    if info.attacherVehicle ~= nil then
                        if g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), info.attachable) then
                            visible = true
                            text = spec.texts.actionAttach
                            g_currentMission:showAttachContext(info.attachable)
                            prio = GS_PRIO_VERY_HIGH
                        else
                            spec.showAttachNotAllowedText = 100
                        end
                    end

                    g_inputBinding:setActionEventText(attachActionEvent.actionEventId, text)
                    g_inputBinding:setActionEventTextPriority(attachActionEvent.actionEventId, prio)
                end

                g_inputBinding:setActionEventTextVisibility(attachActionEvent.actionEventId, visible)
            end

            local lowerActionEvent = spec.actionEvents[InputAction.LOWER_IMPLEMENT]
            if lowerActionEvent ~= nil then
                local showLower = false
                local text = ""
                local selectedImplement = self:getSelectedImplement()
                if selectedImplement ~= nil then
                    for _, attachedImplement in pairs(spec.attachedImplements) do
                        if attachedImplement == selectedImplement then
                            showLower, text = attachedImplement.object:getLoweringActionEventState()
                            break
                        end
                    end
                elseif #spec.attachedImplements == 1 then
                    local attachedImplement = spec.attachedImplements[1]
                    showLower, text = attachedImplement.object:getLoweringActionEventState()
                end

                g_inputBinding:setActionEventActive(lowerActionEvent.actionEventId, showLower)
                g_inputBinding:setActionEventText(lowerActionEvent.actionEventId, text)
                g_inputBinding:setActionEventTextPriority(lowerActionEvent.actionEventId, GS_PRIO_NORMAL)
            end
        end
    end
end


---
function AttacherJoints.updateAttacherJointLimits(implement, attacherJointDesc, inputAttacherJointDesc, axis)
    local lowerRotLimit = attacherJointDesc.lowerRotLimit[axis]*inputAttacherJointDesc.lowerRotLimitScale[axis]
    local upperRotLimit = attacherJointDesc.upperRotLimit[axis]*inputAttacherJointDesc.upperRotLimitScale[axis]
    if inputAttacherJointDesc.fixedRotation then
        lowerRotLimit = 0
        upperRotLimit = 0
    end

    local upperTransLimit = attacherJointDesc.lowerTransLimit[axis]*inputAttacherJointDesc.lowerTransLimitScale[axis]
    local lowerTransLimit = attacherJointDesc.upperTransLimit[axis]*inputAttacherJointDesc.upperTransLimitScale[axis]
    implement.lowerRotLimit[axis] = lowerRotLimit
    implement.upperRotLimit[axis] = upperRotLimit

    implement.lowerTransLimit[axis] = upperTransLimit
    implement.upperTransLimit[axis] = lowerTransLimit

    if not attacherJointDesc.allowsLowering then
        implement.upperRotLimit[axis] = lowerRotLimit
        implement.upperTransLimit[axis] = upperTransLimit
    end

    local rotLimit = lowerRotLimit
    local transLimit = upperTransLimit
    if attacherJointDesc.allowsLowering and attacherJointDesc.allowsJointLimitMovement then
        if inputAttacherJointDesc.allowsJointRotLimitMovement then
            rotLimit = MathUtil.lerp(upperRotLimit, lowerRotLimit, attacherJointDesc.moveAlpha)
        end
        if inputAttacherJointDesc.allowsJointTransLimitMovement then
            transLimit = MathUtil.lerp(lowerTransLimit, upperTransLimit, attacherJointDesc.moveAlpha)
        end
    end

    return rotLimit, transLimit
end



---
function AttacherJoints.updateAttacherJointRotationLimit(implement, attacherJointDesc, axis, force, alpha)
    local newRotLimit = MathUtil.lerp( math.max(implement.attachingRotLimit[axis], implement.upperRotLimit[axis]),
                                    math.max(implement.attachingRotLimit[axis], implement.lowerRotLimit[axis]), alpha)
    if force or math.abs(newRotLimit - implement.jointRotLimit[axis]) > 0.0005 then
        local rotLimitDown = -newRotLimit
        local rotLimitUp = newRotLimit
        if axis == 3 then
            if attacherJointDesc.lockDownRotLimit then
                rotLimitDown = math.min(-implement.attachingRotLimit[axis], 0)
            end
            if attacherJointDesc.lockUpRotLimit then
                rotLimitUp = math.max(implement.attachingRotLimit[axis], 0)
            end
            if attacherJointDesc.dynamicLowerRotLimit then
                if attacherJointDesc.rotationNode ~= nil then
                    local rotLimit = math.abs(attacherJointDesc.upperRotation[1] - attacherJointDesc.lowerRotation[1]) * alpha
                    rotLimitUp = rotLimit
                    rotLimitDown = 0
                end
            end
        end

        setJointRotationLimit(attacherJointDesc.jointIndex, axis-1, true, rotLimitDown, rotLimitUp)
        implement.jointRotLimit[axis] = newRotLimit
    end
end


---
function AttacherJoints.updateAttacherJointTranslationLimit(implement, attacherJointDesc, axis, force, alpha)
    local newTransLimit = MathUtil.lerp(   math.max(implement.attachingTransLimit[axis], implement.upperTransLimit[axis]),
                                        math.max(implement.attachingTransLimit[axis], implement.lowerTransLimit[axis]), alpha)

    if force or math.abs(newTransLimit - implement.jointTransLimit[axis]) > 0.0005 then
        local transLimitDown = -newTransLimit
        local transLimitUp = newTransLimit
        if axis == 2 then
            if attacherJointDesc.lockDownTransLimit then
                transLimitDown = math.min(-implement.attachingTransLimit[axis], 0)
            end
            if attacherJointDesc.lockUpTransLimit then
                transLimitUp = math.max(implement.attachingTransLimit[axis], 0)
            end
        end

        setJointTranslationLimit(attacherJointDesc.jointIndex, axis-1, true, transLimitDown, transLimitUp)
        implement.jointTransLimit[axis] = newTransLimit
    end
end


---Updates the requires top lights state based on the attached implements
function AttacherJoints.updateRequiredTopLightsState(self)
    local spec = self.spec_attacherJoints
    local requiresTopLights = false
    for i, implement in ipairs(spec.attachedImplements) do
        local attacherJoint = spec.attacherJoints[implement.jointDescIndex]
        local implementJoint = implement.object:getActiveInputAttacherJoint()
        if attacherJoint.useTopLights and implementJoint.useTopLights then
            requiresTopLights = true
            break
        end
    end

    SpecializationUtil.raiseEvent(self, "onRequiresTopLightsChanged", requiresTopLights)
end


---Sets the width of the bottom arm to a certain category width
function AttacherJoints.consoleCommandBottomArmWidth(_, category, width)
    if width ~= nil then
        width = tonumber(width) or AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[2]
    else
        width = AttacherJoints.LOWER_LINK_WIDTH_BY_CATEGORY[tonumber(category) or 2]
    end

    Logging.info("Set bottom arm width to %.3f m. (Category %d)", width, AttacherJoints.getClosestLowerLinkCategoryIndex(width))

    if g_currentMission ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        for i, vehicle in ipairs(g_localPlayer:getCurrentVehicle().childVehicles) do
            local spec = vehicle.spec_attacherJoints
            if spec ~= nil then
                for jointDescIndex, _ in ipairs(spec.attacherJoints) do
                    vehicle:setAttacherJointBottomArmWidth(jointDescIndex, width)
                end
            end
        end
    end
end
