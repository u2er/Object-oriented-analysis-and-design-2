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
    //private static final Logger LOGGER = LogUtils.getLogger();
    private static final HttpClient HTTP_CLIENT = HttpClient.newHttpClient();
    private static final Gson GSON = new Gson();

    public static void register(CommandDispatcher<CommandSourceStack> dispatcher) {
        // Команда: /aibuild <prompt>
        dispatcher.register(Commands.literal("aibuild")
            .then(Commands.argument("prompt", StringArgumentType.greedyString())
                .executes(context -> {
                    CommandSourceStack source = context.getSource();
                    String prompt = StringArgumentType.getString(context, "prompt");

                    source.sendSuccess(() -> Component.literal("§e[AI] AI is working: " + prompt), false);

                    BlockPos center = BlockPos.containing(source.getPosition());
                    Level level = source.getLevel();
                    String playerName = source.getPlayer() != null ? source.getPlayer().getName().getString() : "Server";

                    requestBuilding(prompt, center, level, playerName, source);
                    return 1;
                })));

        // Команда: /aihistory [лимит]
        dispatcher.register(Commands.literal("aihistory")
            .executes(context -> showHistory(context.getSource(), 5)) // По умолчанию 5 записей
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

    private static void requestBuilding(String prompt, BlockPos center, Level level,
                                         String playerName, CommandSourceStack source) {
        JsonObject jsonRequest = new JsonObject();
        jsonRequest.addProperty("prompt", prompt);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://127.0.0.1:8112/generate_build"))
                .header("Content-Type", "application/json")
                .version(HttpClient.Version.HTTP_1_1)
                .POST(HttpRequest.BodyPublishers.ofString(jsonRequest.toString()))
                .build();

        HTTP_CLIENT.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                .thenAccept(response -> {
                    if (response.statusCode() == 200) {
                        BlueprintResponse blueprint = GSON.fromJson(response.body(), BlueprintResponse.class);

                        if (blueprint.description != null && !blueprint.description.isEmpty()) {
                            //LOGGER.info("[AI Architect] Description for '{}': {}", prompt, blueprint.description);
                            source.getServer().execute(() -> source.sendSuccess(() -> Component.literal("§b[AI] " + blueprint.description), false));
                        }

                        DatabaseManager.logBuild(playerName, prompt, center.getX(), center.getY(), center.getZ());
                        source.getServer().execute(() -> buildInWorld(blueprint, center, level, source));
                    } else {
                        source.getServer().execute(() ->
                            source.sendFailure(Component.literal("§c[AI] Server error: " + response.statusCode()))
                        );
                    }
                })
                .exceptionally(ex -> {
                    source.getServer().execute(() ->
                        source.sendFailure(Component.literal("§c[AI] Connection error: " + ex.getMessage()))
                    );
                    return null;
                });
    }

    private static void buildInWorld(BlueprintResponse blueprint, BlockPos center,
                                      Level level, CommandSourceStack source) {
        if (blueprint == null || blueprint.blocks == null) {
            source.sendFailure(Component.literal("§c[AI] Empty or invalid blueprint received."));
            return;
        }

        int blocksPlaced = 0;
        int blocksSkipped = 0;

        for (BlueprintResponse.BlockInfo bInfo : blueprint.blocks) {
            if (bInfo.material == null || bInfo.material.isBlank()) {
                blocksSkipped++;
                continue;
            }

            BlockPos targetPos = center.offset(bInfo.x, bInfo.y, bInfo.z);

            try {
                ResourceLocation blockId = ResourceLocation.parse(bInfo.material);
                Optional<Block> maybeBlock = BuiltInRegistries.BLOCK.getOptional(blockId);

                if (maybeBlock.isEmpty()) {
                    blocksSkipped++;
                    continue; 
                }

                Block blockToPlace = maybeBlock.get();
                level.setBlock(targetPos, blockToPlace.defaultBlockState(), 3);
                blocksPlaced++;

            } catch (Exception e) {
                blocksSkipped++;
            }
        }

        final int placed = blocksPlaced;
        final int skipped = blocksSkipped;
        source.sendSuccess(() -> Component.literal(
            "§a[AI] Done! Placed: " + placed + " blocks. Skipped: " + skipped + " (unknown IDs)."
        ), false);
    }
}