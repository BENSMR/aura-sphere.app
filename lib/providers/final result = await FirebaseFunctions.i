final result = await FirebaseFunctions.instance
  .httpsCallable('visionOcr')
  .call({'imageUrl': uploadedImageUrl});