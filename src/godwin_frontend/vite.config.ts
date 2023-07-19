import { defineConfig }  from "vite";
import EnvironmentPlugin from 'vite-plugin-environment'
import react             from "@vitejs/plugin-react";

const IS_DEV       = process.env.DFX_NETWORK !== "ic";
const REPLICA_PORT = process.env.DFX_REPLICA_PORT ?? "4943";

export default defineConfig({
  plugins: [  
    react(),
    // Maps all envars prefixed with 'CANISTER_' to process.env.*
    EnvironmentPlugin("all", { prefix: "CANISTER_" }),
    // Weirdly process not available to Webworker but import.meta.env will be.
    EnvironmentPlugin("all", { prefix: "CANISTER_", defineOn: 'import.meta.env' }),
    // Maps all envars prefixed with 'DFX_' to process.env.*
    EnvironmentPlugin("all", { prefix: "DFX_" }),
    // Weirdly process not available to Webworker but import.meta.env will be.
    EnvironmentPlugin("all", { prefix: "DFX_", defineOn: 'import.meta.env' }),
		// Maps all envars prefixed with 'VITE_' to process.env.*
		EnvironmentPlugin({ DFX_REPLICA_PORT: "4943" }),
		// Weirdly process not available to Webworker but import.meta.env will be.
		EnvironmentPlugin({ DFX_REPLICA_PORT: "4943" }, { defineOn: 'import.meta.env' }),
  ],
  build: {
    outDir: "dist/",
    emptyOutDir: true,
    // Remove warning "Module level directives cause errors when bundled, 'use client' was ignored."
    rollupOptions: {
      onwarn(warning, warn) {
        if (warning.code === 'MODULE_LEVEL_DIRECTIVE') {
          return
        }
        warn(warning)
      }}
  },
  worker: {
    format: 'es'
  },
  optimizeDeps: {
    esbuildOptions: {
			// Node.js global to browser globalThis.
			// (Makes it possible for WebWorker to use imports.) 
			define: {
				global: 'globalThis'
			},
    }
  },
	server: {
		proxy: {
			"/api": {
				target: IS_DEV ? `http://localhost:${REPLICA_PORT}` : `https://ic0.app`,
				changeOrigin: true,
				secure: !IS_DEV,
				//rewrite: (path) => path.replace(/^\/api/, "/api"),
			},
		},
	},
});