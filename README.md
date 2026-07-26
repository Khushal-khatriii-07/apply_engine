# JobPilot Mail Sender

JobPilot Mail Sender is a production-quality, cross-platform desktop application designed to automate personalized job application email campaigns from Excel database files. It replaces manual email processes with sequential, high-speed concurrent email delivery using Gmail SMTP, personalized email bodies, and automated resume PDF attachments.

## Tech Stack
* **Frontend**: Flutter 3.41+ (Dart 3.11+), Material 3, GetX (State & Routing), GetStorage (Local Persistence), File Picker, Google Fonts.
* **Backend**: Python 3.12 (compatible with 3.9+), pandas (Excel processing), openpyxl (xlsx generator), email-validator, aiosmtplib (async SMTP), asyncio.
* **Interprocess Protocol**: Flutter initiates the Python engine via `Process.start()` and coordinates campaigns asynchronously through standard input/output JSON streams.

---

## Folder Structure
```text
jobpilot_mail_sender/
├── lib/
│   ├── controllers/
│   │   └── mail_controller.dart       # State management, ETR rates, filtration logic
│   ├── models/
│   │   └── lead_model.dart            # Lead model matching Excel schema
│   ├── screens/
│   │   └── dashboard_screen.dart      # Material 3 Sidebar and Main workspace layout
│   ├── services/
│   │   └── python_service.dart        # Process manager piping stdin/stdout JSON
│   ├── utils/
│   │   └── app_theme.dart             # Material 3 slate schemes and colors
│   └── main.dart                      # Database boot and injection hook
├── python/
│   ├── venv/                          # Python isolated virtual environment
│   ├── config.py                      # SMTP variables and limits
│   ├── logger.py                      # JSON log emitter
│   ├── mailer.py                      # Asynchronous multi-worker mail engine
│   ├── reader.py                      # Excel database parser using pandas
│   ├── validator.py                   # Deduplication and email structure checker
│   ├── main.py                        # Backend runner translating JSON commands
│   └── requirements.txt               # Backend dependencies
├── pubspec.yaml                       # Frontend dependency configurations
└── README.md                          # Documentation
```

---

## Setup and Run Instructions

### Prerequisites
* Flutter SDK (3.41.5+ stable channel recommended).
* Python 3 (3.9+).
* An Excel sheet containing matching recruitment details.
* A Gmail account with a 16-character **App Password** configured (required for Gmail SMTP).

### 1. Build the Python Environment
Setup the isolated virtual environment and install all packages:
```bash
cd python
python3 -m venv venv
# On macOS/Linux:
./venv/bin/pip install -U pip
./venv/bin/pip install -r requirements.txt
# On Windows:
venv\Scripts\pip install -U pip
venv\Scripts\pip install -r requirements.txt
```

Verify that the Python environment imports everything correctly:
```bash
# From the project root directory:
PYTHONPATH=. python/venv/bin/python3 python/main.py --test
# Expecting Output:
# VERIFYING PYTHON ENVIRONMENT...
# STATUS: OK
```

### 2. Run the Flutter Desktop App
Fetch frontend dependencies and launch the desktop environment:
```bash
flutter pub get
flutter run -d macos    # For macOS
# or
flutter run -d windows  # For Windows
```

---

## Key Features
1. **Beautiful Material 3 Design**: Supports automatic dark/light mode toggles, rounded containers, visual pill indicators, and custom spacing.
2. **Personalized Templates**: Embeds dynamic placeholders in your Subject or Email Body. Use `{Recruiter}`, `{Company}`, `{Role}`, or `{Email}` to personalize emails.
3. **Throttled Concurrency**: Allows selecting worker threads (1, 2, 3, or 5) and configuring delays (0.5s to 10s) between successive sends.
4. **Resilient Campaigns**: Supports campaign-level play/pause/stop triggers. If paused or stopped, progress is not lost, and workers shut down gracefully.
5. **Interactive Controls**: Table supports fuzzy search, status filters, sorting columns, retrying failed emails, and manual duplication pruning.
6. **Detailed Reports**: Export a summary report `.xlsx` containing outcomes, failure logs, and dispatch times.
