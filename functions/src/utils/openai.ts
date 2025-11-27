import OpenAI from 'openai';
import * as functions from 'firebase-functions';

let cachedOpenai: OpenAI | null = null;

export function getOpenaiClient(): OpenAI {
  if (!cachedOpenai) {
    const apiKey = process.env.OPENAI_API_KEY || functions.config().openai?.key;
    
    if (!apiKey) {
      throw new Error(
        'OpenAI API key not configured. Set via: firebase functions:config:set openai.key="sk-..."'
      );
    }

    cachedOpenai = new OpenAI({ apiKey });
  }

  return cachedOpenai;
}

// Export as getter for backward compatibility
Object.defineProperty(exports, 'openai', {
  get() {
    return getOpenaiClient();
  }
});
