import { CallableContext } from 'firebase-functions/v1/https';
import * as vision from '@google-cloud/vision';

const client = new vision.ImageAnnotatorClient();

export const ocrProcessor = async (data: any, context: CallableContext) => {
  if (!context.auth) {
    throw new Error('Unauthorized');
  }

  const { imageUrl } = data;

  if (!imageUrl) {
    throw new Error('Image URL is required');
  }

  try {
    const [result] = await client.textDetection(imageUrl);
    const detections = result.textAnnotations;

    if (!detections || detections.length === 0) {
      throw new Error('No text detected in image');
    }

    const fullText = detections[0].description || '';

    // TODO: Use AI to extract structured expense data
    const expense = {
      amount: parseAmount(fullText),
      date: parseDate(fullText),
      merchant: parseMerchant(fullText),
      category: 'General',
      description: fullText.substring(0, 100),
    };

    return expense;
  } catch (error) {
    console.error('OCR processing error:', error);
    throw new Error('Failed to process receipt');
  }
};

function parseAmount(text: string): number {
  const amountMatch = text.match(/\$?\d+\.?\d{0,2}/);
  return amountMatch ? parseFloat(amountMatch[0].replace('$', '')) : 0;
}

function parseDate(text: string): string {
  // TODO: Implement robust date parsing
  return new Date().toISOString();
}

function parseMerchant(text: string): string {
  // TODO: Implement merchant name extraction
  return text.split('\n')[0] || 'Unknown';
}
