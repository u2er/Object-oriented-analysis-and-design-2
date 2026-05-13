package com.tq.aiarchitect;

import java.util.ArrayList;
import java.util.concurrent.CompletableFuture;

public class StubBuildService implements IBuildService {
    @Override
    public CompletableFuture<BlueprintResponse> getBlueprint(String prompt) {
        return CompletableFuture.supplyAsync(() -> {
            BlueprintResponse stub = new BlueprintResponse();
            stub.description = "ОШИБКА: Сервер недоступен. Создан временный куб из грязи.";
            stub.blocks = new ArrayList<>();

            // Генерация куба 3x3x3 (от -1 до 1 по осям вокруг центра)
            for (int x = -1; x <= 1; x++) {
                for (int y = 0; y <= 2; y++) {
                    for (int z = -1; z <= 1; z++) {
                        BlueprintResponse.BlockInfo block = new BlueprintResponse.BlockInfo();
                        block.x = x;
                        block.y = y;
                        block.z = z;
                        block.material = "minecraft:dirt";
                        stub.blocks.add(block);
                    }
                }
            }
            return stub;
        });
    }
}