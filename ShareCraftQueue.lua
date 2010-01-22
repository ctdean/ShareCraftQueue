----
---- ShareCraftQueue
----
---- Chris Dean

local ShareCraftQueue = LibStub("AceAddon-3.0"):NewAddon("ShareCraftQueue")

function ShareCraftQueue:OnInitialize()
    local defaults = {
        profile = {
            items = {},
            queue = {},
        }
    }
    local acedb = LibStub:GetLibrary("AceDB-3.0")
    self.db = acedb:New("ShareCraftQueueDB", defaults)
end

function ShareCraftQueue:Print( str )
   print( "|cff15ff00Share Craft Queue|r: " .. str )
end

function ShareCraftQueue:SortedValid( data )
    res = {}
    for item, flag in pairs(data) do
       if( flag ) then
           table.insert( res, item )
       end
    end

    table.sort( res )
    return( res )
end

function ShareCraftQueue:ValidItems()
    return( self:SortedValid( self.db.profile.items ) )
end

function ShareCraftQueue:ValidQueued()
    return( self:SortedValid( self.db.profile.queue ) )
end

function ShareCraftQueue:Help()
    ShareCraftQueue:Print( "Send a crafting queue via email" )
    ShareCraftQueue:Print( "/scq send recipient -- send the mail" )
    ShareCraftQueue:Print( "/scq list -- list all the items that are being tracked" )
    ShareCraftQueue:Print( "/scq add count name -- track this item" )
    ShareCraftQueue:Print( "/scq rm name -- don't track this item" )
    ShareCraftQueue:Print( "/scq queue count name -- add count items to the queue" )
    ShareCraftQueue:Print( "/scq reset -- empty the queue" )
    ShareCraftQueue:Print( "/scq scan -- add tracked items to the queue" )
    ShareCraftQueue:Print( "/scq show -- show the crafting queue" )
    ShareCraftQueue:Print( "/scq add-glyphs count -- track all the glyphs" )

end

function ShareCraftQueue:ItemSummary( name )
    local n = self.db.profile.items[name]
    return( string.format( "%s => %s", name, n ) )
end

function ShareCraftQueue:QueueSummary( name )
    local n = self.db.profile.queue[name]
    return( string.format( "%s => %s", name, n ) )
end

function ShareCraftQueue:Send( recipient )
    if( not recipient ) then
       ShareCraftQueue:Print( "Need recipient" )
    else
        body = date( "Share Craft Queue for %a %d %b %Y %X\n\n" )
        for i, item in pairs(self:ValidQueued()) do
            body = body .. self:QueueSummary( item ) .. "\n"
        end
        SendMail( recipient, "Share Craft Queue", body )
        ShareCraftQueue:Print( string.format( "sent to %s", recipient ) )
    end
end

function ShareCraftQueue:Show()
    local seen = false
    for i, item in pairs(self:ValidQueued()) do
        self:Print( self:QueueSummary( item ) )
        seen = true
    end
    if not seen then 
        self:Print( "queue empty" )
    end
end

function ShareCraftQueue:List()
    local seen = false
    for i, item in pairs(self:ValidItems()) do
        self:Print( self:ItemSummary( item ) )
        seen = true
    end
    if not seen then 
        self:Print( "no tracking list" )
    end
end

function ShareCraftQueue:Add( arg )
    local num, item_name = string.match( arg, "%s*(%d+)%s+(.+)" )
    if( (not num) or (not item_name) ) then
        self:Print( "usage: add count item" )
    else 
        local name = GetItemInfo( item_name )
        self.db.profile.items[name] = tonumber( num )
        self:Print( string.format( "add %s for %s", num, name ) )
    end
end

function ShareCraftQueue:Remove( item_name )
    local name = GetItemInfo( item_name )
    if( not self.db.profile.items[name] ) then
        ShareCraftQueue:Print( string.format( "never seen %s", name ) )
    else
        self.db.profile.items[name] = nil
        ShareCraftQueue:Print( string.format( "removed %s", name ) )
    end
end

function ShareCraftQueue:Queue( arg )
    local num, item_name = string.match( arg, "%s*(%d+)%s+(.+)" )
    if( (not num) or (not item_name) ) then
        self:Print( "usage: queue count item" )
    else 
        local name = GetItemInfo( item_name )
        self.db.profile.queue[name] = tonumber( num )
        self:Print( string.format( "queue %s for %s", num, name ) )
    end
end

function ShareCraftQueue:Scan()
    local working = {}

    for name, n in pairs(self.db.profile.items) do
        if( n ) then
            if( GetItemCount(name, true) <= 0 ) then
                working[name] = n
            end
        end
    end

    local i = 1
    local name = 1
    while name ~= nil do
        name = GetAuctionItemInfo( "owner", i )
        if( name and working[name] ) then
            working[name] = nil
        end
        i = i + 1
    end

    self.db.profile.queue[name] = working

    self:Print( "scan complete" )
end

function ShareCraftQueue:Reset()
    self.db.profile.queue = {}
    self:Print( "queue reset" )
end


SLASH_SHARECRAFTQUEUE1 = "/scq"
SLASH_SHARECRAFTQUEUE2 = "/sharecraftqueue"
SlashCmdList["SHARECRAFTQUEUE"] = function( msg )
    local cmd, arg = string.split(" ", msg or "", 2 )
    cmd = string.lower(cmd or "")

    if( cmd == "send" ) then
       ShareCraftQueue:Send( arg )
    elseif( cmd == "list" ) then
        ShareCraftQueue:List()
    elseif( cmd == "show" ) then
        ShareCraftQueue:Show()
    elseif( cmd == "add" ) then
        ShareCraftQueue:Add( arg )
    elseif( cmd == "rm" ) then
        ShareCraftQueue:Remove( arg )
    elseif( cmd == "queue" ) then
        ShareCraftQueue:Queue( arg )
    elseif( cmd == "scan" ) then
        ShareCraftQueue:Scan()
    elseif( cmd == "reset" ) then
        ShareCraftQueue:Reset()
    elseif( cmd == "add-glyphs" ) then
        ShareCraftQueue:AddGlyphs( arg )
    else
        ShareCraftQueue:Help()
    end
end
