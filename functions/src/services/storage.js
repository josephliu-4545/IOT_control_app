async function uploadJpegToStorageAndGetUrl({ admin, deviceId, imageBuffer }) {
  const bucket = admin.storage().bucket();

  const ts = Date.now();
  const imagePath = `environment/${deviceId}/${ts}.jpg`;
  const file = bucket.file(imagePath);

  await file.save(imageBuffer, {
    contentType: 'image/jpeg',
    resumable: false,
    metadata: {
      cacheControl: 'public, max-age=31536000',
    },
  });

  // Signed URL is easiest for devices + clients; you can switch to token-based download URLs later.
  const [imageUrl] = await file.getSignedUrl({
    action: 'read',
    expires: '2035-01-01',
  });

  return { imagePath, imageUrl };
}

module.exports = { uploadJpegToStorageAndGetUrl };
