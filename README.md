# SahajMudra — learn Indian Sign Language with Meta's Muse models

Built for the **Meta Global AI Developer Hackathon** (theme: *Build for Your World*, indie developer track).

SahajMudra is a Flutter app that teaches **Indian Sign Language (ISL)** and, unlike a static flashcard app, gives the learner real feedback on the sign they are making, in real time, using the phone camera and microphone.

## Why this exists

India has millions of deaf and hard-of-hearing people and very few ISL teachers. A learner practising alone gets no feedback: nobody tells them whether their hand shape is right. Hearing family members, classmates and shopkeepers rarely know any ISL at all, so the "silent divide" stays.

## What's in the app

| Area | What it does |
|---|---|
| **Learn** | Lessons for A–Z, numbers 0–9 and greetings, each with a reference image and a written description |
| **AI Tutor / Practice** | Point the camera at your hand, capture, and **Muse Spark** looks at the image and returns whether the sign is correct, a score, what is off, and a tip |
| **Setu (bridge)** | Three modes: **Sign → Text**, **Voice → Sign**, **Text → Sign** |
| **Progress** | Best score per letter/number, streak, sessions; updates live after each attempt |

## Meta models used

| Model | Where | What for |
|---|---|---|
| `muse-spark-1.3` (vision) | `lib/services/meta_service.dart` → `analyzeImage` | Scores a captured hand sign against the target and explains what to fix (structured JSON output: `correct`, `score`, `issues`, `tip`) |
| `muse-spark-1.3` (vision) | `lib/services/meta_service.dart` → `identifySign` | Setu **Sign → Text**: identifies which sign (from a candidate list, or `NONE`) is being shown, with a confidence |
| `muse-voice-transcribe-1.0` | `lib/services/meta_service.dart` → `transcribe` | Setu **Voice → Sign**: you speak a word or number, it is transcribed, then shown as a sequence of signs |

All calls go to the Meta Model API (`https://api.meta.ai/v1`). If a Meta call fails or no key is configured, the practice screen falls back to the original rule-based scorer so the app never dead-ends.

## How it works

```
Camera frame ──► Muse Spark (vision, JSON schema) ──► score + issues + tip ──► Progress
Microphone  ──► WAV 16 kHz mono ──► Muse Voice Transcribe ──► text ──► sign sequence
Camera frame ──► Muse Spark (candidate list + NONE) ──► detected sign + confidence
```

The scoring prompt is deliberately strict: a blurry, missing or wrong hand is marked incorrect, scores are capped below the "mastered" threshold (80) when the sign is wrong, and the model is told to describe only what it can see.

## Known limitations

- **Static hand shapes only.** Feedback is based on a single captured frame. Signs that involve movement (most greetings) cannot be judged yet.
- **Letter descriptions need work.** The written descriptions for some letters are one-handed (closer to ASL) while the reference images are two-handed ISL, and a few descriptions are near-duplicates (2/V, 9/F, 0/O, 6/W). Numbers are the most reliable part right now.
- **Greeting reference images are missing.**
- **No custom-trained model.** Everything comes from Meta's hosted models; there is no on-device landmark model in this build.
- **API key is compiled into the app** via `--dart-define`. A production version must call Meta through a small backend that holds the key.

## Run it

Requirements: Flutter (stable), an Android phone or emulator with a camera, and a Meta Model API key.

```bash
git clone https://github.com/ThatNocturnalCoder/sahajmudra-meta.git
cd sahajmudra-meta
flutter pub get
flutter run --dart-define=MODEL_API_KEY=YOUR_KEY_HERE
```

Without a key the app still runs, using the offline fallback scorer; the Setu Sign → Text and Voice → Sign modes need the key.

## Tech

Flutter / Dart, `camera`, `record`, `http`, `shared_preferences`, Meta Model API (Muse Spark 1.3, Muse Voice Transcribe 1.0).

## Author

Mansha · [@ThatNocturnalCoder](https://github.com/ThatNocturnalCoder)
