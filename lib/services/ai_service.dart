import 'dart:math' as math;

class AIService {
  static bool _isCalling = false;

  static Future<AIFeedback> analyzeSign({
  required String letter,
  required String islDescription,
  List<Map<String, double>>? landmarks,
}) async {
  if (_isCalling) {
    return const AIFeedback(
        text: 'Still analyzing...', score: 0, isCorrect: false);
  }
  _isCalling = true;
  await Future.delayed(const Duration(milliseconds: 500));

  int score = 0;
  String feedback = '';

  if (landmarks != null && landmarks.length >= 21) {
    final result = _scoreLandmarks(letter, landmarks);
    score = result['score'] as int;
    feedback = result['feedback'] as String;
  } else {
    // No landmarks available yet — return 0 with coaching tip
    // This prevents false auto-advances
    score = 0;
    final hint = islDescription.split('.').first;
    feedback = 'Show your hand clearly. $hint.';
  }

  _isCalling = false;
  return AIFeedback(
    text: feedback,
    score: score,
    isCorrect: score >= 70,
  );
}

  static String _coachingFeedback(
      String letter, int score, String description) {
    final hint = description.split('.').first;
    if (score >= 80) return '✓ Great ${letter} sign! $hint.';
    if (score >= 70) return 'Good attempt! Remember: $hint.';
    return 'Keep going. Focus on: $hint.';
  }

  static bool _isFingerExtended(
      List<Map<String, double>> lm, int tipIdx, int pipIdx) {
    return (lm[tipIdx]['y'] ?? 0) < (lm[pipIdx]['y'] ?? 0);
  }

  static bool _isThumbExtended(List<Map<String, double>> lm) {
    final thumbTip = lm[4];
    final indexBase = lm[5];
    final dist = ((thumbTip['x'] ?? 0) - (indexBase['x'] ?? 0)).abs();
    return dist > 0.08;
  }

  static Map<String, dynamic> _scoreLandmarks(
      String letter, List<Map<String, double>> lm) {
    final indexUp = _isFingerExtended(lm, 8, 6);
    final middleUp = _isFingerExtended(lm, 12, 10);
    final ringUp = _isFingerExtended(lm, 16, 14);
    final pinkyUp = _isFingerExtended(lm, 20, 18);
    final thumbOut = _isThumbExtended(lm);
    final allCurled = !indexUp && !middleUp && !ringUp && !pinkyUp;
    final allUp = indexUp && middleUp && ringUp && pinkyUp;

    int score = 0;
    String feedback = '';

    switch (letter.toUpperCase()) {
      case 'A':
        if (allCurled && !thumbOut) { score = 90; feedback = '✓ Great A! Closed fist with thumb tucked.'; }
        else if (allCurled) { score = 70; feedback = 'Good fist! Rest thumb against your fingers.'; }
        else { score = 35; feedback = 'Curl all fingers into a fist for A.'; }
        break;
      case 'B':
        if (allUp && !thumbOut) { score = 92; feedback = '✓ Perfect B! Four fingers up, thumb tucked.'; }
        else if (allUp) { score = 72; feedback = 'Good! Tuck your thumb across the palm.'; }
        else { score = 30; feedback = 'Extend all four fingers straight up for B.'; }
        break;
      case 'C':
        if (!allCurled && !allUp) { score = 82; feedback = '✓ Nice C shape! Fingers curved like a cylinder.'; }
        else { score = 40; feedback = 'Curve fingers and thumb in a C shape.'; }
        break;
      case 'D':
        if (indexUp && !middleUp && !ringUp && !pinkyUp) { score = 88; feedback = '✓ Great D! Index up, others curled.'; }
        else if (indexUp) { score = 60; feedback = 'Good! Curl middle, ring and pinky down.'; }
        else { score = 30; feedback = 'Point only your index finger up for D.'; }
        break;
      case 'E':
        if (allCurled) { score = 82; feedback = '✓ Good E! All fingers bent at knuckles.'; }
        else { score = 35; feedback = 'Bend all fingers at the knuckles for E.'; }
        break;
      case 'F':
        if (!indexUp && middleUp && ringUp && pinkyUp) { score = 86; feedback = '✓ Nice F! Index to thumb, three fingers up.'; }
        else { score = 35; feedback = 'Touch index to thumb, raise other three fingers.'; }
        break;
      case 'G':
        if (indexUp && !middleUp && !ringUp && !pinkyUp) { score = 78; feedback = '✓ Good G! Index and thumb pointing sideways.'; }
        else { score = 38; feedback = 'Point index sideways with thumb extended.'; }
        break;
      case 'H':
        if (indexUp && middleUp && !ringUp && !pinkyUp) { score = 87; feedback = '✓ Great H! Index and middle together.'; }
        else { score = 35; feedback = 'Extend index and middle fingers together for H.'; }
        break;
      case 'I':
        if (!indexUp && !middleUp && !ringUp && pinkyUp) { score = 90; feedback = '✓ Perfect I! Only pinky extended.'; }
        else if (pinkyUp) { score = 60; feedback = 'Good pinky! Curl all other fingers down.'; }
        else { score = 30; feedback = 'Extend only your pinky for I.'; }
        break;
      case 'J':
        if (pinkyUp && !indexUp && !middleUp && !ringUp) { score = 80; feedback = '✓ Good J! Now trace a J in the air.'; }
        else { score = 35; feedback = 'Raise pinky and trace a J in the air.'; }
        break;
      case 'K':
        if (indexUp && middleUp && thumbOut) { score = 85; feedback = '✓ Nice K! Index, middle and thumb out.'; }
        else { score = 35; feedback = 'Raise index, middle and thumb for K.'; }
        break;
      case 'L':
        if (indexUp && thumbOut && !middleUp && !ringUp && !pinkyUp) { score = 92; feedback = '✓ Perfect L! Index up, thumb out at 90°.'; }
        else { score = 35; feedback = 'Point index up and thumb sideways for L.'; }
        break;
      case 'M':
        if (!indexUp && !middleUp && !ringUp) { score = 80; feedback = '✓ Good M! Three fingers over thumb.'; }
        else { score = 38; feedback = 'Fold index, middle and ring over thumb for M.'; }
        break;
      case 'N':
        if (!indexUp && !middleUp && ringUp) { score = 78; feedback = '✓ Nice N! Two fingers over thumb.'; }
        else { score = 35; feedback = 'Fold index and middle over thumb for N.'; }
        break;
      case 'O':
        final dx = (lm[4]['x']??0)-(lm[8]['x']??0);
        final dy = (lm[4]['y']??0)-(lm[8]['y']??0);
        final dist = math.sqrt(dx*dx+dy*dy);
        if (dist < 0.08) { score = 88; feedback = '✓ Great O! Perfect circle shape.'; }
        else if (dist < 0.15) { score = 65; feedback = 'Almost! Bring fingertips closer to thumb.'; }
        else { score = 35; feedback = 'Curve fingers to meet thumb in an O shape.'; }
        break;
      case 'P':
        if (indexUp && middleUp && !ringUp && !pinkyUp) { score = 78; feedback = '✓ Good P! Like K pointing downward.'; }
        else { score = 38; feedback = 'Point index and middle downward for P.'; }
        break;
      case 'Q':
        if (indexUp && thumbOut && !middleUp) { score = 78; feedback = '✓ Good Q! Index and thumb down.'; }
        else { score = 38; feedback = 'Point index and thumb downward for Q.'; }
        break;
      case 'R':
        if (indexUp && middleUp && !ringUp && !pinkyUp) { score = 82; feedback = '✓ Good R! Cross index and middle fingers.'; }
        else { score = 38; feedback = 'Cross your index and middle fingers for R.'; }
        break;
      case 'S':
        if (allCurled) { score = 85; feedback = '✓ Nice S! Fist with thumb over fingers.'; }
        else { score = 35; feedback = 'Make a fist, wrap thumb over fingers for S.'; }
        break;
      case 'T':
        if (allCurled) { score = 80; feedback = '✓ Good T! Thumb between index and middle.'; }
        else { score = 38; feedback = 'Fist with thumb between index and middle for T.'; }
        break;
      case 'U':
        if (indexUp && middleUp && !ringUp && !pinkyUp && !thumbOut) { score = 90; feedback = '✓ Perfect U! Index and middle up together.'; }
        else { score = 35; feedback = 'Extend index and middle straight up for U.'; }
        break;
      case 'V':
        if (indexUp && middleUp && !ringUp && !pinkyUp) { score = 90; feedback = '✓ Great V! Peace sign — spread apart.'; }
        else { score = 35; feedback = 'Make a V/peace sign for letter V.'; }
        break;
      case 'W':
        if (indexUp && middleUp && ringUp && !pinkyUp) { score = 88; feedback = '✓ Nice W! Three fingers spread.'; }
        else { score = 35; feedback = 'Extend index, middle and ring spread for W.'; }
        break;
      case 'X':
        if (!indexUp && allCurled) { score = 78; feedback = '✓ Good X! Index finger hooked.'; }
        else { score = 38; feedback = 'Curl index finger into a hook for X.'; }
        break;
      case 'Y':
        if (!indexUp && !middleUp && !ringUp && pinkyUp && thumbOut) { score = 90; feedback = '✓ Perfect Y! Thumb and pinky out.'; }
        else { score = 35; feedback = 'Extend only thumb and pinky for Y.'; }
        break;
      case 'Z':
        if (indexUp && !middleUp && !ringUp && !pinkyUp) { score = 78; feedback = '✓ Good Z! Trace a Z with your index finger.'; }
        else { score = 35; feedback = 'Point index finger and trace a Z in air.'; }
        break;
      default:
        score = 50;
        feedback = 'Keep practising!';
    }
    return {'score': score, 'feedback': feedback};
  }
}

class AIFeedback {
  final String text;
  final int score;
  final bool isCorrect;
  const AIFeedback({
    required this.text,
    required this.score,
    required this.isCorrect,
  });
}