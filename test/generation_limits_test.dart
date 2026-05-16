import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('caps single request counts separately from batch target counts', () {
    expect(normalizeImageGenerationRequestCount(0), 1);
    expect(normalizeImageGenerationRequestCount(100), 4);
    expect(normalizeImageGenerationTargetCount(0), 1);
    expect(normalizeImageGenerationTargetCount(100), 100);
    expect(normalizeImageGenerationTargetCount(5000), 1000);
    expect(normalizeBatchGenerationTargetCount(0), 1);
    expect(normalizeBatchGenerationTargetCount(100), 100);
    expect(normalizeBatchGenerationTargetCount(5000), 1000);
  });

  test('splits large generation targets into safe request-sized batches', () {
    expect(
      splitImageGenerationBatches(targetCount: 100, requestCount: 4),
      List<int>.filled(25, 4),
    );
    expect(splitImageGenerationBatches(targetCount: 10, requestCount: 4), [
      4,
      4,
      2,
    ]);
    expect(splitImageGenerationBatches(targetCount: 5, requestCount: 99), [
      4,
      1,
    ]);
  });
}
