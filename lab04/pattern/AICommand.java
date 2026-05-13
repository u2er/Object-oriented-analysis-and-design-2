package com.tq.aiarchitect;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.mojang.brigadier.CommandDispatcher;
import com.mojang.brigadier.arguments.IntegerArgumentType;
import com.mojang.brigadier.arguments.StringArgumentType;
import com.mojang.logging.LogUtils;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.Commands;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation; 
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import org.slf4j.Logger;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Optional;

public class AICommand {
    private static final Logger LOGGER = LogUtils.getLogger();
    private static final IBuildService REMOTE_SERVICE = new RemoteAIBuildService();
    private static final IBuildService STUB_SERVICE = new StubBuildService();

    public static void register(CommandDispatcher<CommandSourceStack> dispatcher) {
        // Команда: /aibuild <prompt>
        dispatcher.register(Commands.literal("aibuild")
            .then(Commands.argument("prompt", StringArgumentType.greedyString())
                .executes(context -> {
                    executeBuild(context.getSource(), StringArgumentType.getString(context, "prompt"));
                    return 1;
                })));

        // Команда: /aihistory [лимит]
        dispatcher.register(Commands.literal("aihistory")
            .executes(context -> showHistory(context.getSource(), 5))
            .then(Commands.argument("limit", IntegerArgumentType.integer(1, 50))
                .executes(context -> {
                    int limit = IntegerArgumentType.getInteger(context, "limit");
                    return showHistory(context.getSource(), limit);
                })));
    }

    private static int showHistory(CommandSourceStack source, int limit) {
        List<String> history = DatabaseManager.getRecentHistory(limit);
        if (history.isEmpty()) {
            source.sendSuccess(() -> Component.literal("§c[AI] History is empty."), false);
        } else {
            source.sendSuccess(() -> Component.literal("§6--- AI Build History (Last " + history.size() + ") ---"), false);
            for (String entry : history) {
                source.sendSuccess(() -> Component.literal(entry), false);
            }
        }
        return 1;
    }

    private static void executeBuild(CommandSourceStack source, String prompt) {
        source.sendSuccess(() -> Component.literal("§e[AI] Requesting building..."), false);
        
        BlockPos center = BlockPos.containing(source.getPosition());
        Level level = source.getLevel();
        String playerName = source.getPlayer() != null ? source.getPlayer().getName().getString() : "Server";

        // Пытаемся вызвать реальный сервис
        REMOTE_SERVICE.getBlueprint(prompt)
            .exceptionally(ex -> {
                // Если ошибка (сервер недоступен) -> вызываем ФИКТИВНЫЙ МЕТОД
                LOGGER.warn("AI Server unavailable, using stub service: {}", ex.getMessage());
                return STUB_SERVICE.getBlueprint(prompt).join();
            })
            .thenAccept(blueprint -> {
                // Логирование описания
                if (blueprint.description != null) {
                    LOGGER.info("[AI] Build Info: {}", blueprint.description);
                }

                DatabaseManager.logBuild(playerName, prompt, center.getX(), center.getY(), center.getZ());
                
                source.getServer().execute(() -> buildInWorld(blueprint, center, level, source));
            });
    }

    private static void buildInWorld(BlueprintResponse blueprint, BlockPos center, Level level, CommandSourceStack source) {
        int placed = 0;
        int skipped = 0;
        for (BlueprintResponse.BlockInfo bInfo : blueprint.blocks) {
            try {
                ResourceLocation blockId = ResourceLocation.parse(bInfo.material);
                Optional<Block> maybeBlock = BuiltInRegistries.BLOCK.getOptional(blockId);
                if (maybeBlock.isPresent()) {
                    level.setBlock(center.offset(bInfo.x, bInfo.y, bInfo.z), maybeBlock.get().defaultBlockState(), 3);
                    placed++;
                }
            } catch (Exception ignored) {skipped++;}
        }
        
        int finalPlaced = placed;
        int finalSkipped = skipped;
        source.sendSuccess(() -> Component.literal("§a[AI] Done! Placed: " + finalPlaced + " blocks. Skipped:" + finalSkipped + " (unknown IDs)."), false);
    }
}