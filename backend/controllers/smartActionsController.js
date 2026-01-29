// ============================================================
// SMART ACTIONS CONTROLLER - INTELLIGENT VERSION
// Extracts actionable items from voice input with HIGH ACCURACY
// ============================================================

import { OpenAI } from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const LANGUAGE_NAMES = {
  "en": "English", "es": "Spanish", "fr": "French", "de": "German",
  "it": "Italian", "pt": "Portuguese", "ru": "Russian", "ja": "Japanese",
  "ko": "Korean", "zh": "Chinese", "ar": "Arabic", "hi": "Hindi",
  "fa": "Farsi (Persian)", "tr": "Turkish", "vi": "Vietnamese",
  "nl": "Dutch", "pl": "Polish", "uk": "Ukrainian", "he": "Hebrew"
};

function getLanguageName(code) {
  return LANGUAGE_NAMES[code] || "English";
}

const SMART_ACTIONS_PROMPT = `You are an EXPERT ACTION CLASSIFIER. Your job is to ACCURATELY identify what the user wants to do.

🎯 BE EXTREMELY SMART ABOUT CLASSIFICATION:

📧 EMAIL - Strong indicators (if ANY of these → EMAIL):
- Email signature phrases: "yours sincerely", "best regards", "kind regards", "thanks", "cheers", "sincerely"
- Greeting: "Dear [name]", "Hi [name]", "Hello [name]"
- Email-specific: "email to", "send to", "write to", "forward to"
- Professional tone with proper structure
- Mentions "subject line" or email format
- Multiple paragraphs of formal/professional text
⚠️ CRITICAL: If text has "yours sincerely", "best regards", "dear [name]" → ALWAYS EMAIL, NEVER calendar!

📅 CALENDAR - ONLY if ALL of these:
- Explicit time/date mentioned ("tomorrow at 3pm", "Monday at 10am", "next Tuesday")
- Meeting/appointment/event context ("meeting with", "call with", "appointment")
- NOT just "I need to do X" (that's a task)
⚠️ CRITICAL: If NO specific time mentioned → NOT a calendar event!

✅ TODO/TASK:
- Action verbs: "need to", "have to", "must", "remember to", "don't forget to"
- No specific time = task (if time → maybe calendar)
- "Buy groceries", "call mom", "finish report"

📝 NOTE:
- Information to save/remember
- Lists, ideas, thoughts
- No action required, just storing info

💬 MESSAGE:
- "Tell the team", "post in Slack", "message on Discord"
- Casual communication, not formal email

🧠 INTELLIGENCE RULES:
1. Context is KING - look at the WHOLE message
2. Email signatures = EMAIL (not calendar!)
3. Greetings like "Dear X" = EMAIL
4. No datetime = NOT calendar (it's task or note)
5. Professional multi-paragraph = likely EMAIL
6. One sentence action = likely TASK
7. "Remind me to X" = TASK (not calendar unless specific time given)

OUTPUT REQUIREMENTS:
- Return ONLY actions you're CONFIDENT about
- If no date/time → DON'T make calendar event
- If has email structure → EMAIL (not task)
- VALIDATE: Calendar MUST have datetime, Email MUST have recipient/body

OUTPUT JSON (no markdown):
{
  "actions": [
    {
      "type": "calendar|email|todo|note|message",
      "title": "Brief title",
      "description": "Details (optional)",
      "datetime": "YYYY-MM-DDTHH:MM:SS+00:00 (ONLY if specific time mentioned)",
      "location": "Place (optional)",
      "attendees": ["person1"] (optional),
      "recipient": "email@example.com (REQUIRED for email)",
      "subject": "Subject line (for email)",
      "body": "Full body text (for email/message)",
      "priority": "high|normal|low (optional)",
      "platform": "Gmail|Calendar|Tasks|etc",
      "formattedText": "Ready-to-use formatted text"
    }
  ]
}

EXAMPLE - Email with signature:
Input: "Dear John, I hope this email finds you well. I wanted to discuss the project timeline. Could we schedule a call next week? Best regards"
→ Type: EMAIL (has greeting + signature "Best regards")
→ NOT calendar (no specific time like "Tuesday at 3pm")

EXAMPLE - Calendar with time:
Input: "Meeting with Sarah tomorrow at 3pm to discuss budget"
→ Type: CALENDAR (specific time given)
→ datetime: [actual tomorrow date]T15:00:00

EXAMPLE - Task without time:
Input: "I need to call mom sometime this week"
→ Type: TODO (no specific time)
→ NOT calendar

BE SMART. BE ACCURATE. DON'T GUESS.`;

export async function extractSmartActions(req, res) {
  try {
    const { text, language = "auto" } = req.body;

    if (!text) {
      return res.status(400).json({ error: "Text is required" });
    }

    const languageName = getLanguageName(language);
    const languageInstruction = language && language !== "auto"
      ? `\n\n🌍 OUTPUT LANGUAGE: ${languageName}\nAll formatted text must be in ${languageName}.`
      : "";

    const messages = [
      {
        role: "system",
        content: SMART_ACTIONS_PROMPT + languageInstruction
      },
      {
        role: "user",
        content: text
      }
    ];

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: messages,
      temperature: 0.1, // Very low for consistency
      max_tokens: 2000,
    });

    const responseText = completion.choices[0].message.content.trim();
    
    // Parse JSON response
    let parsed;
    try {
      // Remove markdown code blocks if present
      const cleaned = responseText
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      parsed = JSON.parse(cleaned);
    } catch (parseError) {
      console.error("Failed to parse AI response:", responseText);
      throw new Error("AI returned invalid JSON");
    }

    // Validate and clean response
    if (!parsed.actions || !Array.isArray(parsed.actions)) {
      throw new Error("Invalid response structure");
    }

    // STRICT VALIDATION - Filter out invalid actions
    const validActions = parsed.actions.filter(action => {
      // Must have type, title, formattedText
      if (!action.type || !action.title || !action.formattedText) {
        console.warn(`⚠️ Skipping action without required fields:`, action);
        return false;
      }

      // CALENDAR must have datetime
      if (action.type === 'calendar' && !action.datetime) {
        console.warn(`⚠️ Skipping calendar action without datetime:`, action.title);
        return false;
      }

      // EMAIL must have body or recipient
      if (action.type === 'email' && !action.body && !action.recipient) {
        console.warn(`⚠️ Skipping email action without body/recipient:`, action.title);
        return false;
      }

      return true;
    });

    // Log what we extracted
    console.log(`✅ Extracted ${validActions.length} valid actions from: "${text.substring(0, 50)}..."`);
    validActions.forEach(action => {
      console.log(`  - ${action.type.toUpperCase()}: ${action.title}`);
    });

    res.json({
      actions: validActions,
      original_text: text
    });

  } catch (error) {
    console.error("Smart actions extraction error:", error);
    res.status(500).json({ 
      error: "Failed to extract smart actions",
      details: error.message 
    });
  }
}
