class ISLData {
  // Drive folder links per letter — from the official ISL dictionary
  static const Map<String, String> letterVideoFolders = {
    'A': 'https://drive.google.com/drive/folders/1nkI7lddegUWDvmGsmn68QkB5ikp5_3kt',
    'B': 'https://drive.google.com/drive/folders/1S-G5qoWth0aI9fLzKs8Myv2LyMrq8jUh',
    'C': 'https://drive.google.com/drive/folders/1iZvUpDh5gtzoRmQKWAVfCOe8iWEjzS2S',
    'D': 'https://drive.google.com/drive/folders/1aQywSGpfHXOdM1pfs2rfqU3Y_ScLXRjh',
    'E': 'https://drive.google.com/drive/folders/13pJC91P8ligEXJh7ZcVbdOdBv8OM7ugw',
    'F': 'https://drive.google.com/drive/folders/1uwjIG-hYqxYTURtWMEpmCc9NzV13uz-S',
    'G': 'https://drive.google.com/drive/folders/1_jxELuDPMQb67NM6woqcdcn5QWd2mVeC',
    'H': 'https://drive.google.com/drive/folders/1BL9C7zyFAcRQg-DsM-CiIjsoFMbSvTCt',
    'I': 'https://drive.google.com/drive/folders/1K6eUYZLdCRh21Ecxx9wcsAJ3HP7jd4CI',
    'J': 'https://drive.google.com/drive/folders/198cCQXlwdAwmxabGVvXMZKQ-lnDclO37',
    'K': 'https://drive.google.com/drive/folders/1rXKlSTKyWJNqDL6-lupJuufMUZW7Zunc',
    'L': 'https://drive.google.com/drive/folders/1MbKLv9fBdLUPE4-PrSbSGBCnudtuKRTg',
    'M': 'https://drive.google.com/drive/folders/1qDHOYx4Eijrgo3cZHucMIlPRKgcK__8Z',
    'N': 'https://drive.google.com/drive/folders/1UUeBYdHraz86n9wgJG2HR4-gfMuO6o8e',
    'O': 'https://drive.google.com/drive/folders/1FZVV2snPZAR9_Zcy-XEo15cKgcVbMiUM',
    'P': 'https://drive.google.com/drive/folders/1hR6GnLjEj8_I5UPDJg3ZE0oQDzCnzXFy',
    'Q': 'https://drive.google.com/drive/folders/1Q6BYTJRyUElN6XCKrU9RXW2YzHGICPUA',
    'R': 'https://drive.google.com/drive/folders/1Zkr_CW-PmeGFjmJRmjA-lYubIVnFyb7o',
    'S': 'https://drive.google.com/drive/folders/1EQaicx76vWxgQwSosFQcAbrzgePEwPYN',
    'T': 'https://drive.google.com/drive/folders/1QcM74V2Q4OGRzDhZrP_ULHd5W4XgzmPw',
    'U': 'https://drive.google.com/drive/folders/1g9DxvHVMcoID1PhbvR8kJ5Mhq921hDcM',
    'V': 'https://drive.google.com/drive/folders/1hdhswMEW2FbBhi4GPgYsTBrhThpuSoNK',
    'W': 'https://drive.google.com/drive/folders/1JMWkAryDQ074isVeD0_umJfFHOhb3f6t',
    'X': 'https://drive.google.com/drive/folders/1t4mOWrTel2OXS76RX7b9X2Gf-6MqmrFp',
    'Y': 'https://drive.google.com/drive/folders/1wiWGUBD_R_KobXRAE3Erpp7XUZrUuYNb',
    'Z': 'https://drive.google.com/drive/folders/1cTyPjYRqrBTG2cEHQNXd4oRGkp9HtY4M',
  };
  static const Map<String, String> numberDescriptions = {
  '0': 'All fingers and thumb curved to form an O shape, like the letter O sign.',
  '1': 'Only index finger extended upward. All other fingers curled into fist. Thumb tucked.',
  '2': 'Index and middle fingers extended up in a V shape. Other fingers curled. Like the letter V.',
  '3': 'Thumb, index, and middle fingers extended. Ring and pinky curled down.',
  '4': 'Four fingers (index, middle, ring, pinky) extended upward spread. Thumb tucked across palm.',
  '5': 'All five fingers spread wide open. Palm faces outward.',
  '6': 'Pinky and thumb touch at tips. Other three fingers extended upward.',
  '7': 'Ring finger and thumb touch at tips. Other fingers extended upward.',
  '8': 'Middle finger and thumb touch at tips. Index, ring, pinky extended upward.',
  '9': 'Index finger and thumb touch at tips forming a circle. Other fingers extended up. Like letter F.',
};

static const Map<String, String> greetingDescriptions = {
  'Hello': 'Open hand, fingers together, palm facing outward. Move hand sideways in a small wave from the wrist.',
  'Thank You': 'Flat hand with fingers together. Touch fingertips to chin, then move hand forward toward the person.',
  'Namaste': 'Both palms pressed together in front of chest, fingers pointing upward. Slight bow of the head.',
  'Sorry': 'Make a fist with dominant hand. Place it on your chest and move it in a circular motion.',
  'Yes': 'Make a fist. Nod the fist up and down at the wrist, like a head nodding yes.',
  'No': 'Extend index and middle fingers together. Tap them against the thumb twice quickly.',
};

  // Plain English description of each ISL alphabet sign
  // Used as context for Claude when evaluating user's hand landmarks
  static const Map<String, String> letterDescriptions = {
    'A': 'Both hands are held up with palms facing forward, each in a fist with the four fingers curled down and only the thumbs extended inward. The tips of the two thumbs touch together in the middle.',
    'B': 'Use both hands held up with fingertips pointing up, with all fingers curled and each thumb tip touching its index fingertip to form a small circle. The two circles touch together in the middle at the thumb tips and index tips.',
    'C': 'Use one hand held upright with the palm facing sideways. Curl the four fingers together and curve them over the top while the thumb sticks out below, leaving an open C shape with the fingertips and thumb not touching.',
    'D': 'Use both hands with only the index fingers extended while the middle, ring, and pinky fingers are curled into a fist. The upper hand comes in from the side with the thumb extended and index bent down, and the lower hand points straight up with the thumb tucked against the fist, so the tips of the two index fingers touch to form a rounded shape.',
    'E': 'Use both hands with only the index finger extended straight and the other fingers curled into a fist with the thumb tucked in. Hold the left hand horizontal pointing right and the right hand vertical pointing up, so the tips of the two index fingers touch to form a right-angle corner.',
    'F': 'Use both hands with only the index and middle fingers extended straight together, the other fingers curled down and the thumbs folded in. Hold one hand sideways with fingers pointing horizontally and the other hand upright with fingers pointing up, crossing the upright fingers in front of the sideways fingertips to touch at a right angle.',
    'G': 'Use both hands closed into tight fists with all fingers curled and thumbs tucked in and not extended. Hold one fist horizontally and bring the second fist up from below so the top knuckles of the lower fist touch the underside of the upper fist.',
    'H': 'Use both hands with all fingers extended straight and together and thumbs tucked against the side of the palm. Hold the hands upright with palms facing each other so the fingertips meet at the top to form a pointed peak.',
    'I': 'One hand is held upright with only the index finger extended straight up, while the middle, ring, and pinky fingers are curled into a fist with the thumb pressed against them. The palm faces sideways, the hands do not touch or cross, and no movement is shown.',
    'J': 'Both hands are used with only the index finger extended and the other fingers curled into a fist with the thumb tucked in. The left hand comes from the left with its index pointing inward and the right hand comes from below with its index pointing up, so the two fingertips meet and touch at the top.',
    'K': 'Two hands are used: the lower hand points its index finger straight up with the middle, ring, and little fingers curled shut and the thumb held against the side, while the upper hand comes in from the side facing down with its index finger extended sideways and bent down at the tip in a hook and its other fingers curled shut with the thumb tucked in. The hooked tip of the upper index touches the side of the lower upright index.',
    'L': 'Use one hand with the palm facing forward, with no touching or crossing. Extend the index finger straight up and the thumb straight out to the side to form an L-shape, while the middle, ring, and little fingers are curled down into the palm.',
    'M': 'It uses two hands: one hand is held upright with the palm facing sideways, all four fingers extended straight up together and the thumb held slightly out to the side. The other hand comes in sideways with its fingers extended together and pointing straight so its fingertips touch the middle of the upright palm, while its thumb is bent up.',
    'N': 'Two hands are used: one hand is held upright with three fingers extended straight up together, palm facing sideways, while the other hand is held horizontal with the index and middle fingers extended together pointing sideways. The horizontal hand has its ring and little fingers curled with the thumb curled over them, and the tips of its two extended fingers touch the edge of the upright hand near the base of the fingers to form a T-shape.',
    'O': 'One hand is held upright with the palm facing to the side. Curl all four fingers down to meet the thumb so the fingertips and thumb tip touch to form a small round O.',
    'P': 'Use both hands. The upper hand reaches in from the left with the thumb and index finger curled together to form a circle while the other three fingers stay extended upward, and the lower hand points straight up from below with only the index finger extended and the other fingers curled with the thumb tucked in, so that index fingertip touches the spot where the upper thumb and index meet.',
    'Q': 'This sign uses two hands, both held upright with palms facing inward and fingertips meeting in the middle. The lower hand has only the index finger extended straight up with the other fingers curled and thumb tucked, while the upper hand has the thumb and bent index finger touching tip-to-tip to make a small circle with the other two fingers extended straight up, and the lower index tip touches that circle junction.',
    'R': 'Two hands are used: one hand is held upright with fingers pointing straight up, all four fingers extended together and the thumb held slightly out to the side. The other hand is a fist coming in from the side with only the index finger extended straight, the other fingers curled and the thumb tucked in, with the tip of the index finger touching the side edge of the upright palm.',
    'S': 'Both hands are used with the index, middle, and ring fingers curled into a fist and only the little finger stuck straight out — the upper hand holds its thumb open to the side while the lower hand folds its thumb over the curled fingers. The upper hand comes from the left palm-down and the lower hand points up palm-in, with the lower little-fingertip touching and lightly pinched between the upper little-fingertip and thumb-tip in the center.',
    'T': 'Use both hands with only the index finger extended and the other fingers curled into a fist with the thumb tucked alongside. Hold one hand sideways with the index pointing across and the other hand upright with the index pointing up, touching the fingertips together at a right angle to form a T shape.',
    'U': 'One hand is held upright with the palm facing forward, the thumb and little finger extended straight up and the middle three fingers curled down into the palm. There is no second hand, touching, or crossing.',
    'V': 'Using one hand with the palm facing forward and fingers pointing up, extend the index and middle fingers straight up and spread apart in a V while the ring and little fingers are curled down with the thumb pressed over them.',
    'W': 'Both hands are held upright with fingertips pointing up. Curl all fingers and overlap them together at the top, with each thumb pressed upward against the other hand\'s fingers.',
    'X': 'Use both hands in a fist with only the index finger extended pointing up and inward and the thumb tucked over the curled fingers. Cross the middle of the two index fingers to form an X with the backs of the hands facing outward.',
    'Y': 'Two hands are used: the hand on the left is held sideways with the thumb pointing up, the index finger extended straight out and the other fingers curled, while the hand on the right is held upright with the palm facing forward, the thumb pointing up, one finger extended up and out and the other fingers curled into the palm. The tip of the left index finger touches the side of the right thumb.',
    'Z': 'Use two hands: hold one hand sideways with the index finger extended pointing across and the thumb sticking forward with the other fingers curled in, and hold the other hand upright with all four fingers extended straight up together and the thumb slightly out with the palm facing sideways. The hands don\'t touch or cross, with the index fingertip held just short of the upright palm.',
  };

  static List<String> get alphabet => letterDescriptions.keys.toList();
  static List<String> get numbers => numberDescriptions.keys.toList();
static List<String> get greetings => greetingDescriptions.keys.toList();

  // User progress key for SharedPreferences
  static const String progressKey = 'sahaj_progress';
  static const String streakKey = 'sahaj_streak';
  static const String lastActiveKey = 'sahaj_last_active';
  static String getDescription(String item) {
  return letterDescriptions[item] ??
      numberDescriptions[item] ??
      greetingDescriptions[item] ??
      '';
}
}