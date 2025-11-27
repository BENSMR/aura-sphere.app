# CRM Insights Function - Quick Reference

## 🎯 What This Function Does

The `generateCrmInsights` Cloud Function:
1. Takes a list of CRM contacts
2. Sends them to OpenAI for analysis
3. Gets back AI-generated insights with:
   - Contact segmentation
   - Top prospects ranked by conversion likelihood
   - Recommended follow-up actions
   - Email/SMS templates
4. Auto-creates tasks from suggested actions
5. Caches results to prevent API rate limiting

---

## 🔄 Call Flow

```
Flutter App (crm_ai_insights_screen.dart)
    ↓
CrmInsightsProvider.generate(userId)
    ↓
OpenAICrmService.generateCrmInsights(userId, contactIds)
    ↓
FunctionsService.callFunction('generateCrmInsights', {...})
    ↓
Cloud Function (functions/src/crm/insights.ts)
    ├─→ Validate authentication
    ├─→ Load contacts from Firestore OR use passed contacts
    ├─→ Send to OpenAI API
    ├─→ Parse JSON response
    ├─→ Save insights to Firestore
    ├─→ Create follow-up tasks (optional, non-blocking)
    ├─→ Cache results for 3 hours
    └─→ Return response
    ↓
CrmInsightsProvider updates UI
    ↓
CrmAiInsightsScreen displays results
```

---

## 📝 Function Signature

```typescript
export const generateCrmInsights = functions.https.onCall(
  async (data, context) => {
    // data contains:
    // {
    //   userId: string,           // Required: user ID
    //   contactIds?: string[],    // Optional: specific contacts from Firestore
    //   contacts?: Contact[]      // Optional: contacts passed directly from client
    // }
    
    // Returns:
    // {
    //   success: boolean,
    //   source: 'cache' | 'openai',
    //   cached: boolean,
    //   cooldown?: boolean,
    //   nextAllowedAt?: string,
    //   insights: {
    //     summary: string,
    //     segments: [{name, reason}],
    //     topContacts: [{id, name, score, reason}],
    //     actions: [{title, suggestion, channel, dueDays}],
    //     emailTemplate: {subject, body},
    //     smsTemplate: {body},
    //     confidence: 'high|medium|low',
    //     explain: string
    //   },
    //   insightId: string,
    //   createdTasks: number
    // }
  }
);
```

---

## 🔐 Security Features

✅ **Authentication Check**
```typescript
if (!context.auth) throw new HttpsError('unauthenticated', '...');
```

✅ **User Isolation**
```typescript
if (callerUid !== userId) {
  // Only admins can request insights for other users
}
```

✅ **Firestore Rules Compliance**
```typescript
// All documents include userId field
await insightRef.set({
  userId,  // ← Required by security rules
  raw: parsed,
  // ...
});
```

---

## ⚙️ Configuration Required

### Firebase Functions Config
```bash
# Set OpenAI API key
firebase functions:config:set openai.key="sk-xxx..."

# Verify
firebase functions:config:get
```

### Firestore Collections Created
- `users/{uid}/crm_insights` - Stores insights
- `users/{uid}/crm_insights_meta/lastRun` - Cache metadata
- `users/{uid}/tasks` - Auto-created follow-up tasks

### Firestore Rules Required
```
match /users/{userId} {
  match /crm_insights/{insightId} {
    allow read, write: if request.auth.uid == userId;
  }
  match /tasks/{taskId} {
    allow read, write: if request.auth.uid == userId;
  }
}
```

---

## 🧪 Testing

### 1. Local Emulator
```bash
firebase emulators:start --only functions
# Calls will hit local function
```

### 2. From Flutter
```dart
final provider = context.read<CrmInsightsProvider>();
await provider.generate('user123');
print(provider.insights); // See results
print(provider.error);     // See errors
```

### 3. From Firebase Console
```bash
firebase functions:log --follow
# Watch for logs as requests come in
```

---

## 📊 Example Response

```json
{
  "success": true,
  "source": "openai",
  "cached": false,
  "insights": {
    "summary": "Your contact base shows strong engagement with 15% high-quality leads",
    "segments": [
      {
        "name": "High-Value Prospects",
        "reason": "Companies >50 employees, recent interaction, high engagement score"
      },
      {
        "name": "Nurture Track",
        "reason": "Interested but not yet ready to commit"
      },
      {
        "name": "Re-engagement Needed",
        "reason": "Previously engaged, no contact in 60+ days"
      }
    ],
    "topContacts": [
      {
        "id": "contact_123",
        "name": "John Smith (Acme Corp)",
        "score": 92,
        "reason": "Recent interaction, company size match, decision maker role"
      }
    ],
    "actions": [
      {
        "title": "Schedule Discovery Call",
        "suggestion": "John showed strong interest in your case study. Schedule 30-min call to discuss implementation timeline.",
        "channel": "email",
        "dueDays": 2
      }
    ],
    "emailTemplate": {
      "subject": "John, let's discuss your Q1 goals",
      "body": "Hi John,\n\nI noticed you reviewed our case studies...\n\nLooking forward to connecting!\n\nBest"
    },
    "smsTemplate": {
      "body": "Hi John! Following up on our conversation about your Q1 goals. When's a good time to chat? -Team"
    },
    "confidence": "high",
    "explain": "High confidence based on 3+ recent interactions, company profile match, and explicit engagement signals"
  },
  "insightId": "insight_abc123",
  "createdTasks": 5
}
```

---

## 🐛 Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| `ApiError: 401` | OpenAI API key invalid | `firebase functions:config:set openai.key="..."` |
| `Error: No contacts found` | No contacts in collection | Create contacts first via CRM screen |
| `Firestore permission denied` | Missing userId field | Already fixed in current implementation |
| `JSON parsing failed` | OpenAI returned non-JSON | Check prompt in function, increase max_tokens |
| `Timeout` | OpenAI slow response | Increase timeout from 60s to 120s if needed |

---

## 📈 Performance

- **Typical Duration:** 3-8 seconds (OpenAI API call)
- **Cached Response:** <100ms
- **Payload Size:** ~5-20KB
- **Rate Limit:** 60 requests/minute per user
- **Cache Duration:** 3 hours
- **Cost:** ~$0.001-0.005 per call

---

## 🔗 Related Code Files

| File | Purpose |
|------|---------|
| `functions/src/crm/insights.ts` | Main function implementation |
| `functions/src/utils/openai.ts` | OpenAI client initialization |
| `functions/src/utils/logger.ts` | Logging utility |
| `lib/providers/crm_insights_provider.dart` | Flutter state management |
| `lib/services/ai/openai_crm_service.dart` | Flutter service layer |
| `lib/screens/crm/crm_ai_insights_screen.dart` | UI that calls this function |
| `firestore.rules` | Security rules |

---

## ✅ Deployment Checklist

- [ ] OpenAI API key configured in Firebase
- [ ] Cloud Functions built successfully
- [ ] Firestore security rules deployed
- [ ] Tested with sample contacts
- [ ] Error logging verified
- [ ] Task creation working
- [ ] Caching working (second call returns cached)
- [ ] Flutter app updated

---

## 🚀 Deploy Command

```bash
# Build functions
cd functions && npm run build && cd ..

# Deploy only CRM insights function
firebase deploy --only functions:generateCrmInsights

# Or deploy all functions
firebase deploy --only functions

# Monitor
firebase functions:log --follow
```

---

## 📞 Need Help?

1. Check Firebase Cloud Functions logs
2. See `/docs/crm_insights_fix_guide.md` for detailed debugging
3. Verify OpenAI API key is set: `firebase functions:config:get`
4. Check Firestore has contacts: Firebase Console > Firestore > users/{uid}/contacts

