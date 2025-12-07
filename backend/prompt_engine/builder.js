// backend/prompt_engine/builder.js

import { GLOBAL_ENGINE } from "./global.js";
import { PRESET_DEFINITIONS } from "./presets.js";

/**
 * Get configuration for a specific preset
 */
export function getPresetConfig(presetId) {
  const config = PRESET_DEFINITIONS[presetId];
  if (!config) {
    // default to magic if unknown
    return PRESET_DEFINITIONS["magic"];
  }
  return config;
}

/**
 * Build the system message content combining:
 * - global engine
 * - active preset behaviour
 * - language instruction (if specified)
 */
function buildSystemContent(presetId, language = "auto") {
  const preset = getPresetConfig(presetId);
  
  const parts = [
    GLOBAL_ENGINE,
    "",
    `ACTIVE PRESET: "${presetId}" (${preset.label})`
  ];
  
  // Add language instruction if specified
  if (language && language !== "auto") {
    parts.push("", `LANGUAGE REQUIREMENT: You MUST respond in "${language}" language.`);
  }
  
  // Add preset-specific behaviour
  if (preset.behaviour) {
    parts.push("", "PRESET BEHAVIOUR:", preset.behaviour.trim());
  }
  
  return parts.filter(Boolean).join("\n\n");
}

/**
 * Build OpenAI chat messages with optional few-shot examples
 * @param {object} options
 * @param {string} options.presetId
 * @param {string} options.userText
 * @param {string} [options.language] - 'auto' or ISO code (e.g. 'en', 'fa', 'es')
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

  // Few-shot examples if available
  if (Array.isArray(preset.examples)) {
    for (const ex of preset.examples) {
      if (!ex || !ex.input || !ex.output) continue;
      messages.push({ role: "user", content: ex.input });
      messages.push({ role: "assistant", content: ex.output });
    }
  }

  // Actual user input
  messages.push({
    role: "user",
    content: userText
  });

  return messages;
}

/**
 * Get OpenAI parameters for a preset
 * @param {string} presetId
 */
export function getPresetParameters(presetId) {
  const preset = getPresetConfig(presetId);
  return {
    temperature: preset.temperature ?? 0.7,
    max_tokens: preset.max_tokens ?? 600
  };
}

