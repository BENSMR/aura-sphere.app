import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface BrandingProfile {
  logoUrl?: string;
  signatureUrl?: string;
  primaryColor?: string;
  accentColor?: string;
  textColor?: string;
  footerNote?: string;
  watermarkText?: string;
  showSignature?: boolean;
  companyDetails?: {
    name: string;
    email?: string;
    phone?: string;
    website?: string;
    address?: string;
  };
  createdAt?: any;
  updatedAt?: any;
}

/**
 * Save or update a branding profile for a user
 * Validates all inputs and stores in Firestore
 */
export const saveBrandingProfile = functions
  .region('us-central1')
  .https.onCall(
    async (
      data: BrandingProfile,
      context: functions.https.CallableContext
    ): Promise<{ success: boolean; message: string }> => {
      try {
        // Verify authentication
        if (!context.auth?.uid) {
          throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
          );
        }

        const userId = context.auth.uid;

        // Validate required fields
        if (!data.companyDetails?.name) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Company name is required'
          );
        }

        // Validate color format
        if (data.primaryColor && !isValidColor(data.primaryColor)) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid primary color format. Use #RRGGBB'
          );
        }

        if (data.accentColor && !isValidColor(data.accentColor)) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid accent color format. Use #RRGGBB'
          );
        }

        if (data.textColor && !isValidColor(data.textColor)) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid text color format. Use #RRGGBB'
          );
        }

        // Validate URLs if provided
        if (data.logoUrl && !isValidUrl(data.logoUrl)) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid logo URL'
          );
        }

        if (data.signatureUrl && !isValidUrl(data.signatureUrl)) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid signature URL'
          );
        }

        // Validate email if provided
        if (
          data.companyDetails?.email &&
          !isValidEmail(data.companyDetails.email)
        ) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Invalid email address'
          );
        }

        // Prepare branding object
        const branding: BrandingProfile = {
          ...data,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Add createdAt if this is a new profile
        const existingDoc = await db
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('businessBranding')
          .get();

        if (!existingDoc.exists) {
          branding.createdAt = admin.firestore.FieldValue.serverTimestamp();
        }

        // Save to Firestore
        await db
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('businessBranding')
          .set(branding, { merge: true });

        // Log the update
        console.log(`Branding profile updated for user: ${userId}`);

        return {
          success: true,
          message: 'Branding profile saved successfully',
        };
      } catch (error) {
        console.error('Error saving branding profile:', error);
        throw new functions.https.HttpsError(
          'internal',
          `Failed to save branding profile: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      }
    }
  );

/**
 * Get a user's branding profile
 */
export const getBrandingProfile = functions
  .region('us-central1')
  .https.onCall(
    async (
      data: any,
      context: functions.https.CallableContext
    ): Promise<BrandingProfile | null> => {
      try {
        if (!context.auth?.uid) {
          throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
          );
        }

        const userId = context.auth.uid;

        const doc = await db
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('businessBranding')
          .get();

        if (!doc.exists) {
          return null;
        }

        return doc.data() as BrandingProfile;
      } catch (error) {
        console.error('Error fetching branding profile:', error);
        throw new functions.https.HttpsError(
          'internal',
          `Failed to fetch branding profile: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      }
    }
  );

/**
 * Delete a user's branding profile (revert to defaults)
 */
export const deleteBrandingProfile = functions
  .region('us-central1')
  .https.onCall(
    async (
      data: any,
      context: functions.https.CallableContext
    ): Promise<{ success: boolean; message: string }> => {
      try {
        if (!context.auth?.uid) {
          throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
          );
        }

        const userId = context.auth.uid;

        await db
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('businessBranding')
          .delete();

        console.log(`Branding profile deleted for user: ${userId}`);

        return {
          success: true,
          message: 'Branding profile deleted. Using default branding.',
        };
      } catch (error) {
        console.error('Error deleting branding profile:', error);
        throw new functions.https.HttpsError(
          'internal',
          `Failed to delete branding profile: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      }
    }
  );

/**
 * Get default branding profile (used when user has no custom branding)
 */
export const getDefaultBrandingProfile = functions
  .region('us-central1')
  .https.onCall(
    async (
      data: any,
      context: functions.https.CallableContext
    ): Promise<BrandingProfile> => {
      return {
        primaryColor: '#1976D2',
        accentColor: '#FFC107',
        textColor: '#000000',
        showSignature: false,
        companyDetails: {
          name: 'Your Company',
        },
      };
    }
  );

/**
 * Validate hex color format
 */
function isValidColor(color: string): boolean {
  // Match hex color format #RRGGBB or #RRGGBBAA
  return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(color);
}

/**
 * Validate URL format (both gs:// and https://)
 */
function isValidUrl(url: string): boolean {
  try {
    if (url.startsWith('gs://')) {
      // Google Cloud Storage URL
      return true;
    }
    // Standard HTTP(S) URL
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

/**
 * Validate email address
 */
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Create a branding profile from template
 * Users can select from predefined styles
 */
export const createBrandingFromTemplate = functions
  .region('us-central1')
  .https.onCall(
    async (
      data: { template: string; companyName: string },
      context: functions.https.CallableContext
    ): Promise<{ success: boolean; branding: BrandingProfile }> => {
      try {
        if (!context.auth?.uid) {
          throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
          );
        }

        const { template, companyName } = data;

        if (!template || !companyName) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Template and company name are required'
          );
        }

        let branding: BrandingProfile;

        // Define templates
        switch (template.toLowerCase()) {
          case 'professional':
            branding = {
              primaryColor: '#1976D2',
              accentColor: '#1565C0',
              textColor: '#212121',
              showSignature: true,
              companyDetails: { name: companyName },
            };
            break;

          case 'modern':
            branding = {
              primaryColor: '#0A84FF',
              accentColor: '#00FFC8',
              textColor: '#0D0D12',
              showSignature: false,
              companyDetails: { name: companyName },
            };
            break;

          case 'minimal':
            branding = {
              primaryColor: '#000000',
              accentColor: '#666666',
              textColor: '#333333',
              showSignature: false,
              companyDetails: { name: companyName },
            };
            break;

          case 'vibrant':
            branding = {
              primaryColor: '#FF6B35',
              accentColor: '#F7931E',
              textColor: '#2C2C2C',
              showSignature: true,
              companyDetails: { name: companyName },
            };
            break;

          case 'elegant':
            branding = {
              primaryColor: '#6A4C93',
              accentColor: '#C5A3FF',
              textColor: '#1B1B1B',
              showSignature: true,
              companyDetails: { name: companyName },
            };
            break;

          default:
            throw new functions.https.HttpsError(
              'invalid-argument',
              `Unknown template: ${template}`
            );
        }

        return {
          success: true,
          branding,
        };
      } catch (error) {
        console.error('Error creating branding from template:', error);
        throw new functions.https.HttpsError(
          'internal',
          `Failed to create branding template: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      }
    }
  );

/**
 * List available branding templates
 */
export const listBrandingTemplates = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    return [
      {
        id: 'professional',
        name: 'Professional',
        description: 'Classic blue and white professional design',
        primaryColor: '#1976D2',
        accentColor: '#1565C0',
      },
      {
        id: 'modern',
        name: 'Modern',
        description: 'Contemporary tech-forward colors',
        primaryColor: '#0A84FF',
        accentColor: '#00FFC8',
      },
      {
        id: 'minimal',
        name: 'Minimal',
        description: 'Clean and simple monochrome',
        primaryColor: '#000000',
        accentColor: '#666666',
      },
      {
        id: 'vibrant',
        name: 'Vibrant',
        description: 'Bold and energetic colors',
        primaryColor: '#FF6B35',
        accentColor: '#F7931E',
      },
      {
        id: 'elegant',
        name: 'Elegant',
        description: 'Sophisticated purple tones',
        primaryColor: '#6A4C93',
        accentColor: '#C5A3FF',
      },
    ];
  });
