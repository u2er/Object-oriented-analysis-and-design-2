package com.tq.aiarchitect;

import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.event.RegisterCommandsEvent;
import net.minecraftforge.fml.common.Mod;

@Mod("aibuilder")
public class AIArchitectMod {
    
    public AIArchitectMod() {
        DatabaseManager.init();
        MinecraftForge.EVENT_BUS.addListener(this::onRegisterCommands);
    }

    private void onRegisterCommands(RegisterCommandsEvent event) {
        AICommand.register(event.getDispatcher());
    }
}