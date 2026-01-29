// ============================================================
//        TEXT TRANSFORMATION CONTROLLER
// ============================================================
//
// The backend magic that powers the viral Select Text → AI Actions.
// This is where selected text becomes legendary content.
//
// ============================================================

const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// AI Transformation prompts - each one is carefully crafted for maximum quality
const TRANSFORMATION_PROMPTS = {
  rewrite: `You are a master editor and writing coach. Your job is to rewrite the given text to make it clearer, more engaging, and more impactful while preserving the original meaning and intent.

Rules:
- Keep the same tone and style unless it's clearly poor
- Fix grammar, spelling, and awkward phrasing
- Make it more readable and flowing
- Preserve all key information and facts
- Don't change the length dramatically
- Make it sound natural and human

Return ONLY the rewritten text, nothing else.`,

  expand: `You are a content expansion specialist. Your job is to take the given text and expand it with relevant details, examples, explanations, and context while maintaining the original message.

Rules:
- Add 50-100% more content
- Include specific examples where appropriate
- Add relevant details that enhance understanding
- Maintain the original tone and style
- Keep it engaging and readable
- Don't add fluff - every addition should add value
- Preserve the core message

Return ONLY the expanded text, nothing else.`,

  shorten: `You are a master of concise communication. Your job is to condense the given text while preserving all essential information and impact.

Rules:
- Remove unnecessary words and phrases
- Combine related sentences
- Keep all key points and facts
- Maintain clarity and readability
- Preserve the original tone
- Aim for 30-50% reduction in length
- Don't lose any important meaning

Return ONLY the shortened text, nothing else.`,

  professional: `You are a business communication expert. Your job is to transform the given text into professional, formal language suitable for business contexts.

Rules:
- Use formal, professional vocabulary
- Remove casual expressions and slang
- Structure sentences clearly and formally
- Maintain respectful, business-appropriate tone
- Keep all factual information
- Make it suitable for workplace communication
- Ensure it sounds authoritative and credible

Return ONLY the professional version, nothing else.`,

  casual: `You are a friendly communication coach. Your job is to transform the given text into casual, conversational language that feels natural and approachable.

Rules:
- Use everyday, conversational vocabulary
- Make it sound like friendly conversation
- Remove overly formal language
- Keep it warm and approachable
- Maintain all important information
- Make it feel personal and relatable
- Use contractions and casual expressions appropriately

Return ONLY the casual version, nothing else.`,

  translate: `You are a professional translator. Your job is to translate the given text into the target language while preserving meaning, tone, and style.

Rules:
- Translate accurately and naturally
- Preserve the original tone and style
- Use appropriate cultural expressions
- Maintain all factual information
- Make it sound native in the target language
- Don't add or remove information
- Ensure cultural appropriateness

Return ONLY the translated text, nothing else.`
};

// Language names for translation
const LANGUAGE_NAMES = {
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'it': 'Italian',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'ja': 'Japanese',
  'ko': 'Korean',
  'zh': 'Chinese',
  'ar': 'Arabic',
  'hi': 'Hindi',
  'nl': 'Dutch',
  'sv': 'Swedish',
  'no': 'Norwegian',
  'da': 'Danish'
};

/**
 * Transform selected text using AI
 */
const transformText = async (req, res) => {
  try {
    const { text, action, context = '', language = 'auto' } = req.body;

    // Validation
    if (!text || !action) {
      return res.status(400).json({
        error: 'Missing required fields: text and action'
      });
    }

    if (!TRANSFORMATION_PROMPTS[action]) {
      return res.status(400).json({
        error: `Invalid action: ${action}. Valid actions: ${Object.keys(TRANSFORMATION_PROMPTS).join(', ')}`
      });
    }

    // Build the prompt
    let systemPrompt = TRANSFORMATION_PROMPTS[action];
    
    // Add language instruction for translation
    if (action === 'translate' && language !== 'auto') {
      const languageName = LANGUAGE_NAMES[language] || language;
      systemPrompt += `\n\nTarget language: ${languageName}`;
    }

    // Add context if provided
    let userPrompt = `Text to transform: "${text}"`;
    if (context.trim()) {
      userPrompt += `\n\nContext (surrounding text): "${context}"`;
    }

    console.log(`🤖 Transforming text with action: ${action}`);
    console.log(`📝 Original text: "${text.substring(0, 100)}${text.length > 100 ? '...' : ''}"`);

    // Call OpenAI
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: systemPrompt
        },
        {
          role: 'user',
          content: userPrompt
        }
      ],
      temperature: action === 'translate' ? 0.1 : 0.3,
      max_tokens: Math.max(500, text.length * 2), // Ensure enough tokens for expansion
    });

    const transformedText = completion.choices[0]?.message?.content?.trim();

    if (!transformedText) {
      throw new Error('No response from AI');
    }

    console.log(`✅ Transformed text: "${transformedText.substring(0, 100)}${transformedText.length > 100 ? '...' : ''}"`);

    res.json({
      success: true,
      transformedText,
      originalText: text,
      action,
      language: action === 'translate' ? language : undefined
    });

  } catch (error) {
    console.error('❌ Text transformation error:', error);
    
    res.status(500).json({
      error: 'Failed to transform text',
      details: error.message
    });
  }
};

export {
  transformText
};