package com.tq.aiarchitect;

import java.util.concurrent.CompletableFuture;

public interface IBuildService {
    CompletableFuture<BlueprintResponse> getBlueprint(String prompt);
}