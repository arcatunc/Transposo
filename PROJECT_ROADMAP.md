# Project Blueprint: Transposo

## 1. Branding & Identity
*   **Application Name (Global/EN):** Transposo: Sheet Music Transposer
*   **Subtitle / Slogan (EN):** The ultimate transposing tool for musicians.
*   **Application Name (TR):** Transposo: Enstrüman Nota Dönüştürücü
*   **Subtitle / Slogan (TR):** Nota kağıtlarını saniyeler içinde enstrümanına uyarla.

---

## 2. Technology Stack & Architecture
*   **Framework:** Flutter (Dart) — Multiplatform capabilities with highly maintainable widget structures for AI agent workflows.
*   **AI Integration:** `google_generative_ai` — Direct serverless interaction with Gemini 1.5 Flash using free-tier API quotas.
*   **Visual Sheet Music Rendering:** `webview_flutter` — Local HTML asset loading leveraging the **ABCJS** library to dynamically draw clean musical staves.
*   **Local Storage / Persistence:** `shared_preferences` or `hive` — Offline storage for execution state, historical notes, and setting preferences.
*   **Media Capture:** `image_picker` — Clean image capturing from camera or local gallery selections.

---

## 3. Core UI/UX Requirements
*   **Modern Aesthetic:** Follow Material 3 guidelines using fluid layouts, ample padding, and modern rounded card-based components.
*   **Theme Support:** Native **Dark Mode** and **Light Mode** configurations following system settings or toggleable controls. High contrast ratios for low-light stage/performance conditions.
*   **Localization (i18n):** Full support for English and Turkish out-of-the-box via Flutter `flutter_localizations` or lightweight JSON keys. All labels, buttons, errors, and instrument designations must translate seamlessly.

---

## 4. Incremental Development Phases

### Phase 1: Core Transposition Engine & Base UI Scaffold
*   **Objective:** Establish the foundational mathematical model in Dart and bind it to basic interface elements.
*   **Actionable Tasks:**
    1. Port pythonic `find_note_index` and `transposer` transposition arithmetic into a pure Dart utility class. Ensure string modifiers like `+` and `-` for octaves are handled correctly.
    2. Build a single-page form with two Dropdowns (Source & Target Instruments), an input text field, and an interactive trigger button.
*   **Test Scenarios:**
    1.  *Basic Transposition:* Input `C:1 D:1 E:1`. Set Source to "Piano (C)" and Target to "Trumpet (Bb)". Verify output evaluates precisely to `D:1 E:1 F#:1`.
    2.  *Octave Integrity:* Input `A+:1 G-:2`. Trigger identical source/target keys and verify modifiers `+` and `-` emerge unmodified.
    3.  *Malformed Input Resilience:* Provide bad sequences (e.g., `XYZ:9`). Confirm that string parsing safely skips illegal elements without runtime crash exceptions.

### Phase 2: Measure Partitioning & ABCJS Sheet Music Rendering
*   **Objective:** Organize raw rhythmic sequences into proper musical time signatures and visually render notation pages.
*   **Actionable Tasks:**
    1. Write a partitioning method that collects cumulative item duration sums, inserting bar lines (`|`) exactly at 4.0 beat intervals (4/4 time signature context). Linebreaks (`\n`) must append every 4 measures.
    2. Embed an `abcjs_template.html` document within native local assets. Connect `webview_flutter` to execute JavaScript bindings transferring parsed ABC notation text dynamically into the viewport.
*   **Test Scenarios:**
    1.  *Bar Line Insertion:* Provide `C:2 D:2 E:1 F:1 G:2`. Confirm structural string outputs parse matching format signatures (`C2 D2 | E F G2`).
    2.  *Fractional Beats:* Evaluate short values like `0.5` or `0.25` and ensure translation translates natively to ABC metrics (`/2` and `/4` string representations).
    3.  *Visual Staff Verification:* Fire the execution pipeline and verify via UI observation that standard blank stave grids populate neatly without crashing the Webview canvas.

### Phase 3: Gemini Vision API Integration (Serverless)
*   **Objective:** Introduce multimodal image input pipelines directly resolving serverless data processing tasks without hosted backends.
*   **Actionable Tasks:**
    1. Integrate the `image_picker` workflow to fetch camera payloads or disk imagery.
    2. Wire up the `google_generative_ai` service. Send binary image arrays paired with the structured system prompt to a serverless gemini-2.5-flash endpoint, passing the generated raw strings straight into the text preview field.
*   **Test Scenarios:**
    1.  *Media Capture Routine:* Verify tapping the capture trigger asks for device hardware access permissions and shows chosen image indicators correctly.
    2.  *Mock AI Sequence Injection:* Create an isolated unit mock that injects static output `C:1 D:1 E:1` into the processing pipeline, checking that UI fields receive information as expected.
    3.  *Network Deficit Recovery:* Disable network links (Airplane Mode) and confirm the application alerts the user cleanly with a snackbar or fallback notification rather than hard-crashing.

### Phase 4: State Persistence, History Tracking & Polish
*   **Objective:** Store system workflows, compile analytical history logs, and polish global application interfaces.
*   **Actionable Tasks:**
    1. Implement local database persistence to capture active values across lifecycle app closures.
    2. Construct a historical drawer or modal layout showing historical conversions (Dates, Source Keys, Target Keys, Notes).
    3. Implement interactive hot-reload event loops: updating notes inside input text fields should trigger real-time updates inside the Webview staff window.
*   **Test Scenarios:**
    1.  *Lifecycle State Survival:* Populate values, adjust instruments, and terminate the running application thread. Boot the application back up and verify configuration states initialize exactly where left.
    2.  *Log Record Reversals:* Perform several structural conversions, select a prior historical row record from the list view, and verify it updates fields accurately.
    3.  *Live Edit Syncing:* Manually edit a single symbol via keyboard entry inside the input view field and confirm the active Webview interface renders the updated layout immediately.

---

## 5. Crucial Implementation Details (Hidden Gotchas)
*   **API Security Without Backends:** Pass the environment parameter `--dart-define="GEMINI_API_KEY=your_key"` during compilation steps instead of exposing hardcoded configuration strings.
*   **Zoom Adaptability & Webview Scaling:** Inject adaptive CSS viewports inside your `abcjs` HTML wrapper (`user-scalable=yes`) so performing musicians can easily pinch-to-zoom on detailed sheets using compact mobile monitors.
*   **Audio Verification Fallback (Future Polish):** Retain structured note tracking fields so future enhancements can add lightweight MIDI playback support natively via digital soundfonts.

## Development Rules
*   **GitHub Commit Message** After developing each phase or hotfix, write a detailed github commit title and body. But do not ever commit the changes. User will make the committing.