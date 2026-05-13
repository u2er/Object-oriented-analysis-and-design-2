package com.tq.aiarchitect;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class DatabaseManager {
    private static final String DB_URL = "jdbc:sqlite:ai_builds.db"; 

    public static void init() {
        try (Connection conn = DriverManager.getConnection(DB_URL);
             Statement stmt = conn.createStatement()) {
            String sql = "CREATE TABLE IF NOT EXISTS build_history (" +
                         "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                         "player_name TEXT, " +
                         "prompt TEXT, " +
                         "center_x INT, center_y INT, center_z INT, " +
                         "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)";
            stmt.execute(sql);
            System.out.println("AI Architect Database initialized!");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void logBuild(String playerName, String prompt, int x, int y, int z) {
        String sql = "INSERT INTO build_history(player_name, prompt, center_x, center_y, center_z) VALUES(?,?,?,?,?)";
        try (Connection conn = DriverManager.getConnection(DB_URL);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, playerName);
            pstmt.setString(2, prompt);
            pstmt.setInt(3, x);
            pstmt.setInt(4, y);
            pstmt.setInt(5, z);
            pstmt.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static List<String> getRecentHistory(int limit) {
        List<String> history = new ArrayList<>();
        String sql = "SELECT player_name, prompt, timestamp FROM build_history ORDER BY id DESC LIMIT ?";
        try (Connection conn = DriverManager.getConnection(DB_URL);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, limit);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                String player = rs.getString("player_name");
                String prompt = rs.getString("prompt");
                String time = rs.getString("timestamp");
                history.add("§8[" + time + "] §e" + player + "§7: §a" + prompt);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return history;
    }
}