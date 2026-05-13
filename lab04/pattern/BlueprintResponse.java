package com.tq.aiarchitect;

import java.util.List;

public class BlueprintResponse {
    public String description; 
    public List<BlockInfo> blocks;

    public static class BlockInfo {
        public int x;
        public int y;
        public int z;
        public String material;
    }
}