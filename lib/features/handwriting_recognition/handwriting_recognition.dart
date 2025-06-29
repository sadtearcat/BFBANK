// 📄 [MAIN EXPORT] 손글씨 인식 기능 통합 모듈
// 역할: 손글씨 인식 관련 모든 핵심 클래스와 위젯을 외부에 노출
// 구성: 핵심 모델, 서비스, 유틸리티, UI 위젯, 개발자 도구
// 사용: 다른 모듈에서 'handwriting_recognition.dart' 하나만 import하면 모든 기능 사용 가능

// Core models
export 'models/drawing_stroke.dart';
export 'models/handwriting_prediction.dart';

// Core services
export 'services/handwriting_model_service.dart';

// Core utilities
export 'utils/handwriting_preprocessor.dart';

// UI widgets
export 'widgets/drawing_canvas.dart';
export 'widgets/handwriting_input_modal.dart';

// Developer tools
export 'widgets/handwriting_test_page.dart';
export 'widgets/benchmark_test_page.dart'; 