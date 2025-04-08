









---
local PalletFillerBuyPalletEvent_mt = Class(PalletFillerBuyPalletEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PalletFillerBuyPalletEvent.emptyNew()
    local self = Event.new(PalletFillerBuyPalletEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function PalletFillerBuyPalletEvent.new(object)
    local self = PalletFillerBuyPalletEvent.emptyNew()
    self.object = object

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PalletFillerBuyPalletEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PalletFillerBuyPalletEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function PalletFillerBuyPalletEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)

        if self.object ~= nil and self.object:getIsSynchronized() then
            if g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_PALLET, 1) then
                self.object:buyPalletFillerPallets(true)
            else
                local vehicleBuyData = BuyVehicleData.new()
                vehicleBuyData:setStoreItem(self.object.spec_palletFiller.pallet.storeItem)
                connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_TOO_MANY_PALLETS, vehicleBuyData))
            end
        end
    else
        if self.object ~= nil and self.object:getIsSynchronized() then
            self.object:buyPalletFillerPallets(true)
        end
    end
end
