// ============================================================
//        MESSAGE BUILDER — UPGRADED
// ============================================================
//
// Constructs OpenAI messages by combining:
// 1. Global Engine (master brain)
// 2. Mode Amplifier (social/email/creative/extraction)
// 3. Preset Behaviour (specific instructions)
// 4. Language Requirement (if specified)
// 5. Few-shot Examples (pattern learning)
//
// ============================================================

import { GLOBAL_ENGINE, MODE_AMPLIFIERS } from "./global.js";
import { PRESET_DEFINITIONS } from "./presets.js";

// ============================================================
// PRESET TO MODE MAPPING
// ============================================================

const PRESET_TO_MODE = {
  // Social Media
  "x_thread": "social",
  "x_post": "social",
  "facebook_post": "social",
  "instagram_caption": "social",
  "instagram_hook": "social",
  "linkedin_post": "social",
  
  // Email
  "email_professional": "email",
  "email_casual": "email",
  
  // Creative
  "story_novel": "creative",
  "poem": "creative",
  "script_dialogue": "creative",
  
  // Extraction
  "outcomes": "extraction",
  "unstuck": "extraction",
  "to_do": "extraction",
  "meeting_notes": "extraction",
  
  // Others use default (no amplifier)
  "magic": null,
  "quick_reply": null,
  "shorten": null,
  "expand": null,
  "formal_business": null,
  "casual_friendly": null,
};

// ============================================================
// GET PRESET CONFIG
// ============================================================

/**
 * Get configuration for a specific preset
 * @param {string} presetId 
 * @returns {object} Preset config or magic as fallback
 */
export function getPresetConfig(presetId) {
  const config = PRESET_DEFINITIONS[presetId];
  if (!config) {
    console.warn(`Unknown preset: ${presetId}, falling back to magic`);
    return PRESET_DEFINITIONS["magic"];
  }
  return config;
}

// ============================================================
// BUILD SYSTEM CONTENT
// ============================================================

/**
 * Build the complete system message
 * @param {string} presetId 
 * @param {string} language 
 * @returns {string}
 */
function buildSystemContent(presetId, language = "auto") {
  const preset = getPresetConfig(presetId);
  const mode = PRESET_TO_MODE[presetId];
  
  // Start with global engine
  const parts = [GLOBAL_ENGINE];
  
  // Add mode amplifier if applicable
  if (mode && MODE_AMPLIFIERS[mode]) {
    parts.push(MODE_AMPLIFIERS[mode]);
  }
  
  // Add language requirement
  if (language && language !== "auto") {
    parts.push(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌍 LANGUAGE REQUIREMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OUTPUT LANGUAGE: ${language}

You MUST respond in ${language}.
This overrides language detection.
JSON keys remain in English if outputting JSON.
`);
  }
  
  // Add preset-specific behaviour
  parts.push(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 ACTIVE PRESET: ${presetId.toUpperCase()} (${preset.label})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${preset.behaviour ? preset.behaviour.trim() : "Apply standard transformation rules."}
`);

  return parts.join("\n\n");
}

// ============================================================
// BUILD MESSAGES
// ============================================================

/**
 * Build complete OpenAI chat messages
 * @param {object} options
 * @param {string} options.presetId - The preset to use
 * @param {string} options.userText - User's input text
 * @param {string} [options.language] - Target language ('auto' or ISO code)
 * @returns {Array} Messages array for OpenAI
 */
export function buildMessages({ presetId, userText, language = "auto" }) {
  const preset = getPresetConfig(presetId);
  const systemContent = buildSystemContent(presetId, language);

  const messages = [
    {
      role: "system",
      content: systemContent
    }
  ];

  // Add few-shot examples if available
  if (Array.isArray(preset.examples) && preset.examples.length > 0) {
    for (const example of preset.examples) {
      if (!example || !example.input || !example.output) continue;
      
      messages.push({ 
        role: "user", 
        content: example.input 
      });
      messages.push({ 
        role: "assistant", 
        content: typeof example.output === "string" 
          ? example.output 
          : JSON.stringify(example.output)
      });
    }
  }

  // Add actual user input
  messages.push({
    role: "user",
    content: userText
  });

  return messages;
}

// ============================================================
// GET PRESET PARAMETERS
// ============================================================

/**
 * Get OpenAI parameters for a preset
 * @param {string} presetId 
 * @returns {object} { temperature, max_tokens }
 */
export function getPresetParameters(presetId) {
  const preset = getPresetConfig(presetId);
  return {
    temperature: preset.temperature ?? 0.7,
    max_tokens: preset.max_tokens ?? 600
  };
}

// ============================================================
// GET PRESET INFO (for debugging/logging)
// ============================================================

/**
 * Get preset metadata
 * @param {string} presetId 
 * @returns {object}
 */
export function getPresetInfo(presetId) {
  const preset = getPresetConfig(presetId);
  const mode = PRESET_TO_MODE[presetId];
  
  return {
    id: presetId,
    label: preset.label,
    mode: mode || "default",
    temperature: preset.temperature,
    max_tokens: preset.max_tokens,
    exampleCount: preset.examples?.length || 0,
  };
}

// ============================================================
// VALIDATE PRESET EXISTS
// ============================================================

/**
 * Check if a preset ID is valid
 * @param {string} presetId 
 * @returns {boolean}
 */
export function isValidPreset(presetId) {
  return presetId in PRESET_DEFINITIONS;
}

// ============================================================
// GET ALL PRESET IDS
// ============================================================

/**
 * Get list of all available preset IDs
 * @returns {string[]}
 */
export function getAllPresetIds() {
  return Object.keys(PRESET_DEFINITIONS);
}

// ============================================================
// EXPORTS
// ============================================================

export default {
  getPresetConfig,
  buildMessages,
  getPresetParameters,
  getPresetInfo,
  isValidPreset,
  getAllPresetIds,
};