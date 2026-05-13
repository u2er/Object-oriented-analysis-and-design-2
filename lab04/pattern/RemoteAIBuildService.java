package com.tq.aiarchitect;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.concurrent.CompletableFuture;

public class RemoteAIBuildService implements IBuildService {
    private static final HttpClient HTTP_CLIENT = HttpClient.newHttpClient();
    private static final Gson GSON = new Gson();
    private static final String API_URL = "http://127.0.0.1:8112/generate_build";

    @Override
    public CompletableFuture<BlueprintResponse> getBlueprint(String prompt) {
        JsonObject jsonRequest = new JsonObject();
        jsonRequest.addProperty("prompt", prompt);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(API_URL))
                .header("Content-Type", "application/json")
                .version(HttpClient.Version.HTTP_1_1)
                .POST(HttpRequest.BodyPublishers.ofString(jsonRequest.toString()))
                .build();

        return HTTP_CLIENT.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                .thenApply(response -> {
                    if (response.statusCode() == 200) {
                        return GSON.fromJson(response.body(), BlueprintResponse.class);
                    } else {
                        throw new RuntimeException("Server error: " + response.statusCode());
                    }
                });
    }
}