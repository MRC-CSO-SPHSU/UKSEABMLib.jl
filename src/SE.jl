
if XAGENTS_GENERIC_PATH in LOAD_PATH && XAGENTS_MA_PATH in LOAD_PATH
    error("XAgents configuration error") 
elseif XAGENTS_MA_PATH in LOAD_PATH
    using SocioEconomics
    const SE = SocioEconomics
else 
    using SocioEconomicsX
    const SE = SocioEconomicsX
end 