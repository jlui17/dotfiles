/**
 * Caveman Mode — auto-activate extension for pi.
 *
 * Source: https://github.com/JuliusBrussee/caveman
 *
 * Injects caveman-mode instructions into the system prompt ONCE per session
 * (on the first user prompt). The "ACTIVE EVERY RESPONSE" persistence rule
 * keeps the model in caveman mode after that — no need to re-inject.
 *
 * Disable: remove this file or edit it to return early.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

/** Path to the installed caveman skill SKILL.md */
const CAVEMAN_SKILL_PATH = join(
	homedir(),
	".pi",
	"agent",
	"git",
	"github.com",
	"JuliusBrussee",
	"caveman",
	"skills",
	"caveman",
	"SKILL.md",
);

/** Track whether we've already injected caveman instructions this session */
let injectedThisSession = false;

/**
 * Strip YAML frontmatter from a skill file.
 */
function stripFrontmatter(content: string): string {
	return content.replace(/^---[\s\S]*?---\n*/m, "").trim();
}

/**
 * Read caveman instructions from the installed package.
 * Returns empty string if package isn't installed.
 */
function readCavemanInstructions(): string {
	try {
		const raw = readFileSync(CAVEMAN_SKILL_PATH, "utf-8");
		return stripFrontmatter(raw);
	} catch {
		// Caveman package not installed — skip silently
		return "";
	}
}

/**
 * Append caveman rules to the system prompt.
 */
function injectCaveman(systemPrompt: string, instructions: string): string {
	return `${systemPrompt}

## Caveman Mode (Active By Default)

${instructions}

**Persistence:** Caveman mode stays ACTIVE for ALL responses. Do not revert to
verbose/formal speech after a few turns. Do not add back filler or pleasantries
unless the user explicitly says "stop caveman" or "normal mode".

**Default intensity:** full. User can switch with /caveman lite|full|ultra.
`;
}

export default function cavemanExtension(pi: ExtensionAPI) {
	// Reset on every session start (new, resume, fork, reload)
	pi.on("session_start", () => {
		injectedThisSession = false;
	});

	// Inject caveman ONCE — on the first user prompt of the session
	pi.on("before_agent_start", async (event) => {
		if (injectedThisSession) {
			return {};
		}

		injectedThisSession = true;

		const instructions = readCavemanInstructions();
		if (!instructions) {
			return {};
		}

		return {
			systemPrompt: injectCaveman(event.systemPrompt, instructions),
		};
	});
}
