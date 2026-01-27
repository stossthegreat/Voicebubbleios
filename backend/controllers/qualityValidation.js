// ============================================================
//        QUALITY VALIDATION FOR EXTRACTIONS
// ============================================================

/**
 * Validate outcomes quality
 * @param {Array} outcomes 
 * @returns {object} { score, issues }
 */
export function validateOutcomesQuality(outcomes) {
  const issues = [];
  let score = 100;

  // Check minimum outcomes
  if (outcomes.length === 0) {
    issues.push({ code: "NO_OUTCOMES", message: "No outcomes extracted" });
    score -= 50;
  }

  // Check each outcome
  for (const outcome of outcomes) {
    // Check text length
    if (outcome.text.length < 5) {
      issues.push({ code: "TOO_SHORT", message: `Outcome too short: "${outcome.text}"` });
      score -= 10;
    }
    
    if (outcome.text.length > 200) {
      issues.push({ code: "TOO_LONG", message: "Outcome should be concise" });
      score -= 5;
    }

    // Check for vague language
    const vaguePatterns = [
      /^(do|think about|consider|maybe|possibly)/i,
      /(something|stuff|things|etc)/i,
    ];
    
    for (const pattern of vaguePatterns) {
      if (pattern.test(outcome.text)) {
        issues.push({ code: "VAGUE", message: "Outcome contains vague language" });
        score -= 5;
        break;
      }
    }
  }

  // Check for diversity of types (good sign)
  const types = new Set(outcomes.map(o => o.type));
  if (types.size === 1 && outcomes.length > 3) {
    issues.push({ code: "NO_DIVERSITY", message: "All outcomes same type" });
    score -= 10;
  }

  return {
    score: Math.max(0, score),
    issues,
  };
}

/**
 * Validate unstuck quality
 * @param {string} insight 
 * @param {string} action 
 * @param {string} originalInput 
 * @returns {object} { score, issues }
 */
export function validateUnstuckQuality(insight, action, originalInput) {
  const issues = [];
  let score = 100;

  // Insight checks
  if (insight.length < 20) {
    issues.push({ code: "INSIGHT_TOO_SHORT", message: "Insight needs more depth" });
    score -= 20;
  }

  if (insight.length > 300) {
    issues.push({ code: "INSIGHT_TOO_LONG", message: "Insight should be concise" });
    score -= 10;
  }

  // Check for therapy speak
  const therapyPatterns = [
    /it sounds like/i,
    /you might be feeling/i,
    /it seems that/i,
    /perhaps you/i,
  ];

  for (const pattern of therapyPatterns) {
    if (pattern.test(insight)) {
      issues.push({ code: "THERAPY_SPEAK", message: "Insight too soft/generic" });
      score -= 15;
      break;
    }
  }

  // Action checks
  if (action.length < 15) {
    issues.push({ code: "ACTION_TOO_SHORT", message: "Action needs more detail" });
    score -= 20;
  }

  if (action.length > 200) {
    issues.push({ code: "ACTION_TOO_LONG", message: "Action should be tiny and simple" });
    score -= 15;
  }

  // Check if action is too big
  const tooBigPatterns = [
    /(create a detailed|make a complete|develop a full|build a comprehensive)/i,
    /(entire|whole|complete|full plan)/i,
  ];

  for (const pattern of tooBigPatterns) {
    if (pattern.test(action)) {
      issues.push({ code: "ACTION_TOO_BIG", message: "Action not small enough" });
      score -= 20;
      break;
    }
  }

  // Check if action is vague
  const vagueActions = [
    /^(think about|consider|try to|maybe)/i,
    /(somehow|something|stuff)/i,
  ];

  for (const pattern of vagueActions) {
    if (pattern.test(action)) {
      issues.push({ code: "ACTION_VAGUE", message: "Action too vague" });
      score -= 15;
      break;
    }
  }

  return {
    score: Math.max(0, score),
    issues,
  };
}

export default {
  validateOutcomesQuality,
  validateUnstuckQuality,
};
