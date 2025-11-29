import axios from "axios";
import FormData from "form-data";

const OPENAI_API_URL = "https://api.openai.com/v1";

/**
 * Safely returns your API key
 */
function getApiKey() {
  const key = process.env.OPENAI_API_KEY;
  if (!key) {
    console.warn("WARNING: OPENAI_API_KEY missing — OpenAI features will fail.");
  }
  return key;
}

/**
 * Shared axios client (no SDK)
 */
function getClient() {
  return axios.create({
    baseURL: OPENAI_API_URL,
    headers: {
      Authorization: `Bearer ${getApiKey()}`,
      "Content-Type": "application/json",
    },
    timeout: 60000,
  });
}

/**
 * HEALTH CHECK — axios-only, no SDK
 */
export async function checkOpenAIHealth() {
  try {
    const client = getClient();
    const res = await client.get("/models");

    return Array.isArray(res.data.data);
  } catch (err) {
    console.error("OpenAI health check failed:", err.message);
    return false;
  }
}

/**
 * WHISPER TRANSCRIPTION — axios-only
 */
export async function transcribeAudio(audioBuffer, filename = "audio.wav") {
  try {
    const apiKey = getApiKey();
    if (!apiKey) throw new Error("Missing OpenAI API key");

    const form = new FormData();
    form.append("file", audioBuffer, filename);
    form.append("model", "whisper-1"); // Correct Whisper model name

    const response = await axios.post(
      `${OPENAI_API_URL}/audio/transcriptions`,
      form,
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          ...form.getHeaders(),
        },
        timeout: 60000,
      }
    );

    return response.data.text;
  } catch (err) {
    console.error("Transcription error:", err.response?.data || err.message);
    throw new Error(
      `Transcription failed: ${
        err.response?.data?.error?.message || err.message
      }`
    );
  }
}

/**
 * REWRITE (STREAMING) — SSE-style axios stream
 */
export async function rewriteTextStreaming(messages, params, onChunk) {
  try {
    const apiKey = getApiKey();
    if (!apiKey) throw new Error("Missing OpenAI API key");

    const response = await axios.post(
      `${OPENAI_API_URL}/chat/completions`,
      {
        model: "gpt-4o-mini",
        messages,
        temperature: params.temperature || 0.7,
        max_tokens: params.max_tokens || 500,
        stream: true,
      },
      {
        headers: { Authorization: `Bearer ${apiKey}` },
        responseType: "stream",
      }
    );

    let full = "";

    return new Promise((resolve, reject) => {
      response.data.on("data", (raw) => {
        const lines = raw
          .toString()
          .split("\n")
          .filter((l) => l.trim() !== "");

        for (const line of lines) {
          if (line === "data: [DONE]") {
            return resolve(full);
          }

          const json = line.replace("data: ", "");

          try {
            const parsed = JSON.parse(json);
            const delta = parsed.choices?.[0]?.delta?.content;

            if (delta) {
              full += delta;
              onChunk && onChunk(delta);
            }
          } catch (e) {
            // silent skip incomplete chunks
          }
        }
      });

      response.data.on("end", () => resolve(full));
      response.data.on("error", (err) =>
        reject(new Error("Streaming error: " + err.message))
      );
    });
  } catch (err) {
    console.error("Rewrite streaming error:", err.message);
    throw new Error(`Rewrite failed: ${err.message}`);
  }
}

/**
 * REWRITE (NORMAL)
 */
export async function rewriteText(messages, params) {
  try {
    const client = getClient();

    const response = await client.post("/chat/completions", {
      model: "gpt-4o-mini",
      messages,
      temperature: params.temperature || 0.7,
      max_tokens: params.max_tokens || 500,
      stream: false,
    });

    return response.data.choices[0].message.content.trim();
  } catch (err) {
    console.error("Rewrite error:", err.message);
    throw new Error(
      `Rewrite failed: ${
        err.response?.data?.error?.message || err.message
      }`
    );
  }
}
