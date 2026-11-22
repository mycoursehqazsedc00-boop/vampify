--[[
    Vampify - CombatHub Adapter
    Routes VampifyDamageFrame and VampifyIncomingFrame events through CombatHub
    without modifying capture/damage.lua or capture/incoming.lua.
    Strict Lua 5.0.
]]

if not CombatHub or type(CombatHub.OnPostLogin) ~= "function" then
    return
end

CombatHub:OnPostLogin(function()
    -- 1. Damage frame (always active)
    local df = getglobal("VampifyDamageFrame")
    if df then
        local origDmg = df:GetScript("OnEvent")
        if type(origDmg) == "function" then
            df:UnregisterAllEvents()
            CombatHub:Subscribe("Vampify_Damage", "Vampify (Damage)", {
                "SPELL_DAMAGE_EVENT_SELF",
                "AUTO_ATTACK_SELF",
                "SPELL_GO_SELF",
            }, function(ev, a1, a2, a3, a4, a5, a6, a7, a8, a9)
                CombatHub:InvokeFrameOnEvent(df, origDmg, ev, a1, a2, a3, a4, a5, a6, a7, a8, a9)
            end, nil)
        end
    end

    -- 2. Incoming frame (dynamically toggled by /vf watch and /vf perhit)
    local inf = getglobal("VampifyIncomingFrame")
    local inc = getglobal("VampifyIncoming")
    if inf and inc then
        local origInc = inf:GetScript("OnEvent")
        if type(origInc) == "function" then
            local incomingEvents = {
                "SPELL_DAMAGE_EVENT_OTHER",
                "AUTO_ATTACK_OTHER",
                "SPELL_HEAL_BY_SELF",
                "SPELL_HEAL_BY_OTHER",
            }
            local incomingEventSet = {
                SPELL_DAMAGE_EVENT_OTHER = true,
                AUTO_ATTACK_OTHER        = true,
                SPELL_HEAL_BY_SELF       = true,
                SPELL_HEAL_BY_OTHER      = true,
            }

            local function dispatchInc(ev, a1, a2, a3, a4, a5, a6, a7, a8, a9)
                CombatHub:InvokeFrameOnEvent(inf, origInc, ev, a1, a2, a3, a4, a5, a6, a7, a8, a9)
            end

            local function syncIncomingSub(active)
                if active then
                    if not CombatHub:IsSubscribed("Vampify_Incoming") then
                        CombatHub:Subscribe("Vampify_Incoming", "Vampify (Incoming)", incomingEvents, dispatchInc, "self")
                    end
                else
                    if CombatHub:IsSubscribed("Vampify_Incoming") then
                        CombatHub:Unsubscribe("Vampify_Incoming")
                    end
                end
            end

            -- Check if incoming was already activated during load (e.g. saved /vf perhit)
            local wasActive = (inc.isOn and inc.isOn())
                or (inf.IsEventRegistered and inf:IsEventRegistered("SPELL_DAMAGE_EVENT_OTHER"))
                and true or false

            -- Detach any already-registered incoming combat events
            local i
            for i = 1, table.getn(incomingEvents) do
                inf:UnregisterEvent(incomingEvents[i])
            end

            if wasActive then
                syncIncomingSub(true)
            end

            -- Hook frame RegisterEvent/UnregisterEvent for incoming combat events
            local origReg = inf.RegisterEvent
            local origUnreg = inf.UnregisterEvent
            inf.RegisterEvent = function(self, ev)
                if incomingEventSet[ev] then
                    syncIncomingSub(true)
                    return
                end
                return origReg(self, ev)
            end
            inf.UnregisterEvent = function(self, ev)
                if incomingEventSet[ev] then
                    syncIncomingSub(false)
                    return
                end
                return origUnreg(self, ev)
            end
        end
    end
end)
