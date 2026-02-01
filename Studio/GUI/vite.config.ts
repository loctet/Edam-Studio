import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";

export default defineConfig({
  server: {
    host: 'localhost', // Only show localhost
    port: 3000, // Force specific port
    watch: {
      usePolling: true,
      interval: 100,
    },
    fs: {
      allow: [path.resolve(__dirname, "..")],
    },
  },
  plugins: [
    react(),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      "@edams-models/edam": path.resolve(__dirname, "../edams-models/edam"),
      "@config": path.resolve(__dirname, "../config.json"),
    },
  }
})