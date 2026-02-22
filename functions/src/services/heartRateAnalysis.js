async function analyzeHeartRateTelemetry({ admin, deviceId, bpm }) {
  const db = admin.firestore();

  // Get last analysis to detect spikes.
  const prevSnap = await db
    .collection('heart_rate_analysis')
    .where('deviceId', '==', deviceId)
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();

  const prevBpm = prevSnap.empty ? null : Number(prevSnap.docs[0].data()?.bpm);

  let status = 'normal';
  let reason = 'Within normal range.';

  if (bpm > 120) {
    status = 'high';
    reason = 'BPM above 120.';
  } else if (bpm < 40) {
    status = 'low';
    reason = 'BPM below 40.';
  }

  if (Number.isFinite(prevBpm)) {
    const delta = Math.abs(bpm - prevBpm);
    if (delta >= 30) {
      status = 'spike';
      reason = `Spike detected (Δ${delta} from previous BPM).`;
    }
  }

  return { status, reason, prevBpm };
}

module.exports = { analyzeHeartRateTelemetry };
