----
---- ShareCraftQueue
----
---- Chris Dean

local ShareCraftQueue = LibStub("AceAddon-3.0"):NewAddon("ShareCraftQueue")
local SHARE_SUBJECT = "Share Craft Queue"

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
    ShareCraftQueue:Print( "/scq rmall name -- remove all tracked items" )
    ShareCraftQueue:Print( "/scq queue count name -- add count items to the queue" )
    ShareCraftQueue:Print( "/scq reset -- empty the queue" )
    ShareCraftQueue:Print( "/scq scan -- add tracked items to the queue" )
    ShareCraftQueue:Print( "/scq show -- show the crafting queue" )
    ShareCraftQueue:Print( "/scq add-glyphs count -- track all the glyphs" )
    ShareCraftQueue:Print( "/scq read -- read the mail message" )

end

function ShareCraftQueue:ItemSummary( link )
    local n = self.db.profile.items[link]
    return( string.format( "%s => %s", link, n ) )
end

function ShareCraftQueue:LinkToShortItem( link )
    local _, lk = GetItemInfo( link )
    local num = string.match( lk, "item:(%d+)")
    return( string.format( "item:%s", num ) );
end

function ShareCraftQueue:ItemNameToLink( name )
    for i, link in pairs(self:ValidItems()) do
        if( name == GetItemInfo( link ) ) then
            return( link )
        end
    end
end

function ShareCraftQueue:QueueSummary( link, useId )
    local n = self.db.profile.queue[link]
    if( useId ) then
        return( string.format( "%s => %s", self:LinkToShortItem( link ), n ) )
    else
        return( string.format( "%s => %s", link, n ) )
    end
end

function ShareCraftQueue:Send( recipient )
    if( not recipient ) then
       ShareCraftQueue:Print( "Need recipient" )
    else
        body = date( "Share Craft Queue for %a %d %b %Y %X\n\n" )
        for i, link in pairs(self:ValidQueued()) do
            body = body .. self:QueueSummary( link, true ) .. "\n"
        end
        SendMail( recipient, SHARE_SUBJECT, body )
        ShareCraftQueue:Print( string.format( "sent to %s", recipient ) )
    end
end

function ShareCraftQueue:Show()
    local seen = false
    for i, link in pairs(self:ValidQueued()) do
        self:Print( self:QueueSummary( link, false ) )
        seen = true
    end
    if not seen then 
        self:Print( "queue empty" )
    end
end

function ShareCraftQueue:List()
    local seen = false
    for i, link in pairs(self:ValidItems()) do
        self:Print( self:ItemSummary( link ) )
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
        local name, link = GetItemInfo( item_name )
        self.db.profile.items[link] = tonumber( num )
        self:Print( string.format( "add %s for %s", link, num ) )
    end
end

function ShareCraftQueue:Remove( item_name )
    local _, link = GetItemInfo( item_name )
    if( not self.db.profile.items[link] ) then
        ShareCraftQueue:Print( string.format( "never seen %s", link ) )
    else
        self.db.profile.items[link] = nil
        ShareCraftQueue:Print( string.format( "removed %s", link ) )
    end
end

function ShareCraftQueue:Queue( arg )
    local num, item_name = string.match( arg, "%s*(%d+)%s+(.+)" )
    if( (not num) or (not item_name) ) then
        self:Print( "usage: queue count item" )
    else 
        local _, link = GetItemInfo( item_name )
        self.db.profile.queue[link] = tonumber( num )
        self:Print( string.format( "queue %s for %s", num, link ) )
    end
end

function ShareCraftQueue:Scan()
    local working = {}

    for link, n in pairs(self.db.profile.items) do
        if( n ) then
            if( GetItemCount(link, true) <= 0 ) then
                working[link] = n
            end
        end
    end

    local i = 1
    local name = 1
    while name ~= nil do
        local nm, _, count = GetAuctionItemInfo( "owner", i )
        name = nm
        if( name and count ) then
            local link = self:ItemNameToLink( name )
            if( link and working[link] ) then
                working[link] = nil
            end
        end
        i = i + 1
    end

    self.db.profile.queue = working

    self:Print( "scan complete" )
end

function ShareCraftQueue:Reset()
    self.db.profile.queue = {}
    self:Print( "queue reset" )
end

function ShareCraftQueue:RemoveAll()
    self.db.profile.items = {}
    self:Print( "all tracked items removed" )
end

function ShareCraftQueue:AddGlyphs( arg )
    local num = string.match( arg, "%s*(%d+)" )
    if( not num ) then
        self:Print( "usage: add-glyphs count" )
    else 
        for _, itemstr in ipairs( self:AllGlyphs() ) do
            _, link = GetItemInfo( itemstr )
            self.db.profile.items[link] = num
        end
        self:Print( "glyphs added" )
    end
end

function ShareCraftQueue:ReadMail()
    local ninbox, total = GetInboxNumItems()
    for i = 1, ninbox do
        local _, _, _, subject = GetInboxHeaderInfo( i )
        if( subject == SHARE_SUBJECT ) then
            local body = GetInboxText( i )
            for itemstr, count in string.gmatch( body, "(item:%d+) => (%d+)" ) do
                local _, link = GetItemInfo( itemstr )
                local cur = QuickAuctions.db.realm.craftQueue[link]
                QuickAuctions.db.realm.craftQueue[link] = (cur or 0) + tonumber( count )
            end
            self:Print( "added to QA" )
        end
    end
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
    elseif( cmd == "rmall" ) then
        ShareCraftQueue:RemoveAll()
    elseif( cmd == "queue" ) then
        ShareCraftQueue:Queue( arg )
    elseif( cmd == "scan" ) then
        ShareCraftQueue:Scan()
    elseif( cmd == "reset" ) then
        ShareCraftQueue:Reset()
    elseif( cmd == "add-glyphs" ) then
        ShareCraftQueue:AddGlyphs( arg )
    elseif( cmd == "read" ) then
        ShareCraftQueue:ReadMail()
    else
        ShareCraftQueue:Help()
    end
end

function ShareCraftQueue:AllGlyphs()
    local glyphids = {
        "item:40896",
        "item:40897",
        "item:40899",
        "item:40900",
        "item:40901",
        "item:40902",
        "item:40903",
        "item:40906",
        "item:40908",
        "item:40909",
        "item:40912",
        "item:40913",
        "item:40914",
        "item:40915",
        "item:40916",
        "item:40919",
        "item:40920",
        "item:40921",
        "item:40922",
        "item:40923",
        "item:40924",
        "item:41092",
        "item:41094",
        "item:41095",
        "item:41096",
        "item:41097",
        "item:41098",
        "item:41099",
        "item:41100",
        "item:41101",
        "item:41102",
        "item:41103",
        "item:41104",
        "item:41105",
        "item:41106",
        "item:41107",
        "item:41108",
        "item:41109",
        "item:41110",
        "item:41517",
        "item:41518",
        "item:41524",
        "item:41526",
        "item:41527",
        "item:41529",
        "item:41530",
        "item:41531",
        "item:41532",
        "item:41533",
        "item:41534",
        "item:41535",
        "item:41536",
        "item:41537",
        "item:41538",
        "item:41539",
        "item:41540",
        "item:41541",
        "item:41542",
        "item:41547",
        "item:41552",
        "item:42396",
        "item:42397",
        "item:42398",
        "item:42399",
        "item:42400",
        "item:42401",
        "item:42402",
        "item:42403",
        "item:42404",
        "item:42405",
        "item:42406",
        "item:42407",
        "item:42408",
        "item:42409",
        "item:42410",
        "item:42411",
        "item:42412",
        "item:42414",
        "item:42415",
        "item:42416",
        "item:42417",
        "item:42453",
        "item:42454",
        "item:42455",
        "item:42456",
        "item:42457",
        "item:42458",
        "item:42459",
        "item:42460",
        "item:42461",
        "item:42462",
        "item:42463",
        "item:42464",
        "item:42465",
        "item:42466",
        "item:42467",
        "item:42468",
        "item:42469",
        "item:42470",
        "item:42471",
        "item:42472",
        "item:42473",
        "item:42734",
        "item:42735",
        "item:42736",
        "item:42737",
        "item:42738",
        "item:42739",
        "item:42740",
        "item:42741",
        "item:42742",
        "item:42743",
        "item:42744",
        "item:42745",
        "item:42746",
        "item:42747",
        "item:42748",
        "item:42749",
        "item:42750",
        "item:42751",
        "item:42752",
        "item:42753",
        "item:42754",
        "item:42897",
        "item:42898",
        "item:42899",
        "item:42900",
        "item:42901",
        "item:42902",
        "item:42903",
        "item:42904",
        "item:42905",
        "item:42906",
        "item:42907",
        "item:42908",
        "item:42909",
        "item:42910",
        "item:42911",
        "item:42912",
        "item:42913",
        "item:42914",
        "item:42915",
        "item:42916",
        "item:42917",
        "item:42954",
        "item:42955",
        "item:42956",
        "item:42957",
        "item:42958",
        "item:42959",
        "item:42960",
        "item:42961",
        "item:42962",
        "item:42963",
        "item:42964",
        "item:42965",
        "item:42966",
        "item:42967",
        "item:42968",
        "item:42969",
        "item:42970",
        "item:42971",
        "item:42972",
        "item:42973",
        "item:42974",
        "item:43316",
        "item:43331",
        "item:43332",
        "item:43334",
        "item:43335",
        "item:43338",
        "item:43339",
        "item:43340",
        "item:43342",
        "item:43343",
        "item:43344",
        "item:43350",
        "item:43351",
        "item:43354",
        "item:43355",
        "item:43356",
        "item:43357",
        "item:43359",
        "item:43360",
        "item:43361",
        "item:43364",
        "item:43365",
        "item:43366",
        "item:43367",
        "item:43368",
        "item:43369",
        "item:43370",
        "item:43371",
        "item:43372",
        "item:43373",
        "item:43374",
        "item:43376",
        "item:43377",
        "item:43378",
        "item:43379",
        "item:43380",
        "item:43381",
        "item:43385",
        "item:43386",
        "item:43388",
        "item:43389",
        "item:43390",
        "item:43391",
        "item:43392",
        "item:43393",
        "item:43394",
        "item:43395",
        "item:43396",
        "item:43397",
        "item:43398",
        "item:43399",
        "item:43400",
        "item:43412",
        "item:43413",
        "item:43414",
        "item:43415",
        "item:43416",
        "item:43417",
        "item:43418",
        "item:43419",
        "item:43420",
        "item:43421",
        "item:43422",
        "item:43423",
        "item:43424",
        "item:43425",
        "item:43426",
        "item:43427",
        "item:43428",
        "item:43429",
        "item:43430",
        "item:43431",
        "item:43432",
        "item:43533",
        "item:43534",
        "item:43535",
        "item:43536",
        "item:43537",
        "item:43538",
        "item:43539",
        "item:43541",
        "item:43542",
        "item:43543",
        "item:43544",
        "item:43545",
        "item:43546",
        "item:43547",
        "item:43548",
        "item:43549",
        "item:43550",
        "item:43551",
        "item:43552",
        "item:43553",
        "item:43554",
        "item:43671",
        "item:43672",
        "item:43673",
        "item:43674",
        "item:43725",
        "item:43825",
        "item:43826",
        "item:43827",
        "item:43867",
        "item:43868",
        "item:43869",
        "item:44684",
        "item:44920",
        "item:44922",
        "item:44923",
        "item:44928",
        "item:44955",
        "item:45601",
        "item:45602",
        "item:45603",
        "item:45604",
        "item:45622",
        "item:45623",
        "item:45625",
        "item:45731",
        "item:45732",
        "item:45733",
        "item:45734",
        "item:45735",
        "item:45736",
        "item:45737",
        "item:45738",
        "item:45739",
        "item:45740",
        "item:45741",
        "item:45742",
        "item:45743",
        "item:45744",
        "item:45745",
        "item:45746",
        "item:45747",
        "item:45753",
        "item:45755",
        "item:45756",
        "item:45757",
        "item:45758",
        "item:45760",
        "item:45761",
        "item:45762",
        "item:45764",
        "item:45766",
        "item:45767",
        "item:45768",
        "item:45769",
        "item:45770",
        "item:45771",
        "item:45772",
        "item:45775",
        "item:45776",
        "item:45777",
        "item:45778",
        "item:45779",
        "item:45780",
        "item:45781",
        "item:45782",
        "item:45783",
        "item:45785",
        "item:45789",
        "item:45790",
        "item:45792",
        "item:45793",
        "item:45794",
        "item:45795",
        "item:45797",
        "item:45799",
        "item:45800",
        "item:45803",
        "item:45804",
        "item:45805",
        "item:45806",
        "item:46372",
        "item:48720",
        "item:49084",
        "item:50045",
        "item:50077",
        "item:50125",
    }

    return( glyphids )
end
