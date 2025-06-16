import 'package:flutter/material.dart';
import '../../services/ocr_queue_service.dart';

/// OCR 큐 상태를 표시하는 위젯
class OcrStatusWidget extends StatelessWidget {
  final OcrQueueService ocrQueueService;
  final TextStyle? textStyle;

  const OcrStatusWidget({
    super.key,
    required this.ocrQueueService,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // OCR 큐 상태
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'OCR: ${ocrQueueService.queueLength}/${ocrQueueService.totalProcessed}',
            style: textStyle ?? TextStyle(
              color: ocrQueueService.isProcessing ? Colors.red : Colors.purple,
              fontSize: 12,
            ),
          ),
        ),
        // 최대 큐 길이
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Max: ${ocrQueueService.maxQueueLength}',
            style: textStyle ?? const TextStyle(color: Colors.orange, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

/// OCR 결과를 표시하는 위젯
class OcrResultWidget extends StatelessWidget {
  final List<String> ocrResults;
  final String? title;

  const OcrResultWidget({
    super.key,
    required this.ocrResults,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.text_fields, color: Colors.purple, size: 16),
              const SizedBox(width: 8),
              Text(
                title ?? 'OCR Results (${ocrResults.length})',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        
        // OCR 결과 리스트
        Expanded(
          child: ocrResults.isEmpty
              ? const Center(
                  child: Text(
                    'No OCR results yet',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: ocrResults.length,
                  itemBuilder: (context, index) {
                    return Container(
                      constraints: const BoxConstraints(maxWidth: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purple.withOpacity(0.5)),
                      ),
                      child: Text(
                        ocrResults[index],
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
} 