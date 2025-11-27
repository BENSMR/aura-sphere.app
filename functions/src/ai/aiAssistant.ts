import { CallableContext } from 'firebase-functions/v1/https';
import { getOpenaiClient } from '../utils/openai';

export const aiAssistant = async (data: any, context: CallableContext) => {
  if (!context.auth) {
    throw new Error('Unauthorized');
  }

  const { prompt } = data;

  if (!prompt) {
    throw new Error('Prompt is required');
  }

  try {
    const openai = getOpenaiClient();
    const response = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: 'You are an AI assistant helping with business management tasks for AuraSphere Pro.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
    });

    return {
      response: response.choices[0].message.content,
    };
  } catch (error) {
    console.error('AI Assistant error:', error);
    throw new Error('Failed to get AI response');
  }
};
