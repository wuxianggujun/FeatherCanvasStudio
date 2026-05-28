const int minImageGenerationCount = 1;
const int maxImageGenerationRequestCount = 4;
const int maxImageGenerationTargetCount = 1000;
const int maxTemplateImageReferenceCount = 8;
const int defaultBatchGenerationTargetCount = 100;
const int maxBatchGenerationTargetCount = maxImageGenerationTargetCount;
const int defaultBatchGenerationRequestCount = maxImageGenerationRequestCount;

int normalizeImageGenerationCount(int value) {
  return value < minImageGenerationCount ? minImageGenerationCount : value;
}

int normalizeImageGenerationRequestCount(int value) {
  return normalizeImageGenerationCount(
    value,
  ).clamp(minImageGenerationCount, maxImageGenerationRequestCount).toInt();
}

int normalizeImageGenerationTargetCount(int value) {
  return normalizeImageGenerationCount(
    value,
  ).clamp(minImageGenerationCount, maxImageGenerationTargetCount).toInt();
}

int normalizeBatchGenerationTargetCount(int value) {
  return normalizeImageGenerationTargetCount(value);
}

List<int> splitImageGenerationBatches({
  required int targetCount,
  required int requestCount,
}) {
  var remaining = normalizeBatchGenerationTargetCount(targetCount);
  final normalizedRequestCount = normalizeImageGenerationRequestCount(
    requestCount,
  );
  final batches = <int>[];
  while (remaining > 0) {
    final batchCount = remaining < normalizedRequestCount
        ? remaining
        : normalizedRequestCount;
    batches.add(batchCount);
    remaining -= batchCount;
  }
  return batches;
}
