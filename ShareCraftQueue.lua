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

    self.db.profile.queue = working

    self:Print( "scan complete" )
end

function ShareCraftQueue:Reset()
    self.db.profile.queue = {}
    self:Print( "queue reset" )
end

function ShareCraftQueue:AddGlyphs( arg )
    local num = string.match( arg, "%s*(%d+)" )
    if( not num ) then
        self:Print( "usage: add-glyphs count" )
    else 
        for _, name in ipairs( self:AllGlyphs() ) do
            self.db.profile.items[name] = num
        end
        self:Print( "glyphs added" )
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

function ShareCraftQueue:AllGlyphs()
    local glyphs = {
        "Glyph of Corruption", 
        "Glyph of Aimed Shot", 
        "Glyph of Molten Armor", 
        "Glyph of Power Word: Shield", 
        "Glyph of Disengage", 
        "Glyph of Focus", 
        "Glyph of Chain Lightning", 
        "Glyph of Water Elemental", 
        "Glyph of Shred", 
        "Glyph of Challenging Roar", 
        "Glyph of Holy Shock", 
        "Glyph of Psychic Scream", 
        "Glyph of Lightning Bolt", 
        "Glyph of Remove Curse", 
        "Glyph of Blurred Speed", 
        "Glyph of Astral Recall", 
        "Glyph of Blast Wave", 
        "Glyph of Pick Pocket", 
        "Glyph of Disease", 
        "Glyph of Blink", 
        "Glyph of Rending", 
        "Glyph of Flash of Light", 
        "Glyph of Metamorphosis", 
        "Glyph of Ice Barrier", 
        "Glyph of Healing Stream Totem", 
        "Glyph of Ambush", 
        "Glyph of Death Strike", 
        "Glyph of Sinister Strike", 
        "Glyph of Death Grip", 
        "Glyph of Seal of Wisdom", 
        "Glyph of Volley", 
        "Glyph of Regrowth", 
        "Glyph of Swiftmend", 
        "Glyph of Frost Trap", 
        "Glyph of Killing Spree", 
        "Glyph of Shadowfiend", 
        "Glyph of Explosive Trap", 
        "Glyph of Shackle Undead", 
        "Glyph of Arcane Missiles", 
        "Glyph of Bloodthirst", 
        "Glyph of Seal of Vengeance", 
        "Glyph of Mortal Strike", 
        "Glyph of Explosive Shot", 
        "Glyph of Pain Suppression", 
        "Glyph of Shadowflame", 
        "Glyph of Curse of Exhaustion", 
        "Glyph of Flash Heal", 
        "Glyph of Maul", 
        "Glyph of Healing Wave", 
        "Glyph of Fortitude", 
        "Glyph of Mass Dispel", 
        "Glyph of Judgement", 
        "Glyph of Icy Touch", 
        "Glyph of Hemorrhage", 
        "Glyph of Curse of Agony", 
        "Glyph of Pick Lock", 
        "Glyph of Hamstring", 
        "Glyph of Hammer of Justice", 
        "Glyph of Howling Blast", 
        "Glyph of Salvation", 
        "Glyph of Anti-Magic Shell", 
        "Glyph of Flame Shock", 
        "Glyph of Hymn of Hope", 
        "Glyph of Eternal Water", 
        "Glyph of Aquatic Form", 
        "Glyph of Lava Lash", 
        "Glyph of Nourish", 
        "Glyph of Taunt", 
        "Glyph of Lay on Hands", 
        "Glyph of Gouge", 
        "Glyph of Revenge", 
        "Glyph of the Ghoul", 
        "Glyph of Blood Strike", 
        "Glyph of Healthstone", 
        "Glyph of Hurricane", 
        "Glyph of Quick Decay", 
        "Glyph of Rake", 
        "Glyph of Lightning Shield", 
        "Glyph of Unbreakable Armor", 
        "Glyph of Divine Storm", 
        "Glyph of Chaos Bolt", 
        "Glyph of Snake Trap", 
        "Glyph of Unstable Affliction", 
        "Glyph of Aspect of the Viper", 
        "Glyph of Souls", 
        "Glyph of Felguard", 
        "Glyph of Spell Reflection", 
        "Glyph of Levitate", 
        "Glyph of Blocking", 
        "Glyph of Sap", 
        "Glyph of Chains of Ice", 
        "Glyph of Horn of Winter", 
        "Glyph of Fire Nova", 
        "Glyph of Stoneclaw Totem", 
        "Glyph of Lesser Healing Wave", 
        "Glyph of Shadow Dance", 
        "Glyph of Howl of Terror", 
        "Glyph of Bladestorm", 
        "Glyph of Avenger's Shield", 
        "Glyph of Cleaving", 
        "Glyph of Heroic Strike", 
        "Glyph of Evocation", 
        "Glyph of Hunger for Blood", 
        "Glyph of Moonfire", 
        "Glyph of Drain Soul", 
        "Glyph of Blood Tap", 
        "Glyph of Whirlwind", 
        "Glyph of Chimera Shot", 
        "Glyph of Distract", 
        "Glyph of Monsoon", 
        "Glyph of Growl", 
        "Glyph of Freezing Trap", 
        "Glyph of Demonic Circle", 
        "Glyph of Mana Gem", 
        "Glyph of Feint", 
        "Glyph of Scorch", 
        "Glyph of Blessing of Might", 
        "Glyph of Vigilance", 
        "Glyph of Fireball", 
        "Glyph of Adrenaline Rush", 
        "Glyph of Frost Strike", 
        "Glyph of Beacon of Light", 
        "Glyph of Frenzied Regeneration", 
        "Glyph of Dark Command", 
        "Glyph of Frost Ward", 
        "Glyph of Ice Armor", 
        "Glyph of the Wise", 
        "Glyph of Battle", 
        "Glyph of Hex", 
        "Glyph of Plague Strike", 
        "Glyph of Fire Ward", 
        "Glyph of Succubus", 
        "Glyph of Blessing of Kings", 
        "Glyph of Guardian Spirit", 
        "Glyph of Revive Pet", 
        "Glyph of Mutilate", 
        "Glyph of Dispersion", 
        "Glyph of Fear Ward", 
        "Glyph of Mage Armor", 
        "Glyph of Serpent Sting", 
        "Glyph of Deep Freeze", 
        "Glyph of Frost Armor", 
        "Glyph of Flametongue Weapon", 
        "Glyph of Possessed Strength", 
        "Glyph of Thunder", 
        "Glyph of Fire Elemental Totem", 
        "Glyph of Riptide", 
        "Glyph of Resonating Power", 
        "Glyph of Health Funnel", 
        "Glyph of Wrath", 
        "Glyph of Righteous Defense", 
        "Glyph of Shield of Righteousness", 
        "Glyph of Ghost Wolf", 
        "Glyph of Enduring Victory", 
        "Glyph of Mend Pet", 
        "Glyph of Haunt", 
        "Glyph of Starfire", 
        "Glyph of Survival Instincts", 
        "Glyph of Tricks of the Trade", 
        "Glyph of Death's Embrace", 
        "Glyph of Unending Breath", 
        "Glyph of Raise Dead", 
        "Glyph of Arcane Explosion", 
        "Glyph of Chain Heal", 
        "Glyph of Hunter's Mark", 
        "Glyph of Holy Wrath", 
        "Glyph of Fire Blast", 
        "Glyph of Smite", 
        "Glyph of Barkskin", 
        "Glyph of Wild Growth", 
        "Glyph of the Wild", 
        "Glyph of Charge", 
        "Glyph of Elemental Mastery", 
        "Glyph of Sunder Armor", 
        "Glyph of Arcane Barrage", 
        "Glyph of Vanish", 
        "Glyph of the Hawk", 
        "Glyph of Life Tap", 
        "Glyph of Preparation", 
        "Glyph of the Beast", 
        "Glyph of Wyvern Sting", 
        "Glyph of Earthliving Weapon", 
        "Glyph of Claw", 
        "Glyph of Feign Death", 
        "Glyph of Scourge Imprisonment", 
        "Glyph of Icy Veins", 
        "Glyph of Bone Shield", 
        "Glyph of Water Mastery", 
        "Glyph of Water Breathing", 
        "Glyph of Voidwalker", 
        "Glyph of Vigor", 
        "Glyph of Immolate", 
        "Glyph of Victory Rush", 
        "Glyph of the Pack", 
        "Glyph of Hammer of Wrath", 
        "Glyph of Mending", 
        "Glyph of Unholy Blight", 
        "Glyph of Unburdened Rebirth", 
        "Glyph of Sweeping Strikes", 
        "Glyph of Penance", 
        "Glyph of Ghostly Strike", 
        "Glyph of Death and Decay", 
        "Glyph of Typhoon", 
        "Glyph of Kilrogg", 
        "Glyph of Turn Evil", 
        "Glyph of Last Stand", 
        "Glyph of Trueshot Aura", 
        "Glyph of Arcane Power", 
        "Glyph of Totem of Wrath", 
        "Glyph of Rip", 
        "Glyph of Intervene", 
        "Glyph of Dash", 
        "Glyph of Thorns", 
        "Glyph of Seal of Righteousness", 
        "Glyph of Fear", 
        "Glyph of Invisibility", 
        "Glyph of Fading", 
        "Glyph of Stormstrike", 
        "Glyph of Strangulate", 
        "Glyph of Starfall", 
        "Glyph of Immolation Trap", 
        "Glyph of Mocking Blow", 
        "Glyph of Sprint", 
        "Glyph of Spiritual Attunement", 
        "Glyph of Soulstone", 
        "Glyph of Spirit of Redemption", 
        "Glyph of Soul Link", 
        "Glyph of Blessing of Wisdom", 
        "Glyph of Backstab", 
        "Glyph of Slow Fall", 
        "Glyph of Slice and Dice", 
        "Glyph of Siphon Life", 
        "Glyph of Imp", 
        "Glyph of Avenging Wrath", 
        "Glyph of Berserk", 
        "Glyph of Lava", 
        "Glyph of Shadow Protection", 
        "Glyph of Dancing Rune Weapon", 
        "Glyph of Shocking", 
        "Glyph of Shield Wall", 
        "Glyph of Lifebloom", 
        "Glyph of Arcane Shot", 
        "Glyph of Evasion", 
        "Glyph of Enraged Regeneration", 
        "Glyph of Shadow Word: Pain", 
        "Glyph of Expose Armor", 
        "Glyph of Death Coil", 
        "Glyph of Shadow Word: Death", 
        "Glyph of Heart Strike", 
        "Glyph of Inner Fire", 
        "Glyph of Exorcism", 
        "Glyph of Shadow Bolt", 
        "Glyph of Icebound Fortitude", 
        "Glyph of Shadow", 
        "Glyph of Crusader Strike", 
        "Glyph of Earth Shield", 
        "Glyph of Frost Nova", 
        "Glyph of Cloak of Shadows", 
        "Glyph of Bloodrage", 
        "Glyph of Steady Shot", 
        "Glyph of Seal of Light", 
        "Glyph of Bestial Wrath", 
        "Glyph of Divine Plea", 
        "Glyph of Scourge Strike", 
        "Glyph of Windfury Weapon", 
        "Glyph of Rune Tap", 
        "Glyph of Healing Touch", 
        "Glyph of Scatter Shot", 
        "Glyph of Water Shield", 
        "Glyph of Savage Roar", 
        "Glyph of the Penguin", 
        "Glyph of Frost Shock", 
        "Glyph of Holy Light", 
        "Glyph of Dark Death", 
        "Glyph of Devastate", 
        "Glyph of Searing Pain", 
        "Glyph of Safe Fall", 
        "Glyph of Rupture", 
        "Glyph of Ice Lance", 
        "Glyph of Rebirth", 
        "Glyph of Rune Strike", 
        "Glyph of Multi-Shot", 
        "Glyph of Garrote", 
        "Glyph of Ice Block", 
        "Glyph of Execution", 
        "Glyph of Rapid Rejuvenation", 
        "Glyph of Renewed Life", 
        "Glyph of Renew", 
        "Glyph of Rejuvenation", 
        "Glyph of Raptor Strike", 
        "Glyph of Deterrence", 
        "Glyph of Arcane Blast", 
        "Glyph of Incinerate", 
        "Glyph of Hungering Cold", 
        "Glyph of Lightwell", 
        "Glyph of Command", 
        "Glyph of Dispel Magic", 
        "Glyph of Mind Flay", 
        "Glyph of Rapid Fire", 
        "Glyph of Feral Spirit", 
        "Glyph of Enslave Demon", 
        "Glyph of Cleansing", 
        "Glyph of Rapid Charge", 
        "Glyph of Barbaric Insults", 
        "Glyph of Prayer of Healing", 
        "Glyph of Deadly Throw", 
        "Glyph of Polymorph", 
        "Glyph of Kill Shot", 
        "Glyph of Sense Undead", 
        "Glyph of Pestilence", 
        "Glyph of Circle of Healing", 
        "Glyph of Mirror Image", 
        "Glyph of Frostbolt", 
        "Glyph of Scare Beast", 
        "Glyph of Seal of Command", 
        "Glyph of Fade", 
        "Glyph of Insect Swarm", 
        "Glyph of Frostfire", 
        "Glyph of Obliterate", 
        "Glyph of Living Bomb", 
        "Glyph of Thunder Clap", 
        "Glyph of Mind Sear", 
        "Glyph of Felhunter", 
        "Glyph of Blade Flurry", 
        "Glyph of Overpower", 
        "Glyph of Mind Control", 
        "Glyph of Vampiric Blood", 
        "Glyph of Mangle", 
        "Glyph of Divinity", 
        "Glyph of Hammer of the Righteous", 
        "Glyph of Mana Tide Totem", 
        "Glyph of Corpse Explosion", 
        "Glyph of Shockwave", 
        "Glyph of Conflagrate", 
        "Glyph of Crippling Poison", 
        "Glyph of Thunderstorm", 
        "Glyph of Innervate", 
        "Glyph of Shadowburn", 
        "Glyph of Entangling Roots", 
        "Glyph of Consecration", 
        "Glyph of Water Walking", 
        "Glyph of Holy Nova", 
        "Glyph of Fan of Knives", 
        "Glyph of Arcane Intellect", 
        "Glyph of Eviscerate"
    }

    return( glyphs )
end
