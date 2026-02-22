// Provider-agnostic AI stub.
// Later you can plug OpenAI / Gemini / Vertex / etc.

async function analyzeEnvironment({ imageUrl, imageBuffer }) {
  void imageUrl;
  void imageBuffer;

  // Placeholder heuristic output.
  return {
    lighting: 'unknown',
    hazards: [],
    summary: 'AI service not configured yet. This is a stub result.',
    risk_level: 'unknown',
  };
}

module.exports = { analyzeEnvironment };
