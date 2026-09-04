# Flutter frontend

```bash
cd frontend
flutter pub get
flutter run
```

Default backend: `http://127.0.0.1:8000`

Override it with:

```bash
flutter run --dart-define=BACKEND_URL=http://192.168.1.10:8000
```

Android emulator commonly uses:

```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8000
```

Features include dark/light theme, transaction/date search, persisted history, status filters, animated confidence, expandable source fields, prominent exceptions, copy/share, analytics charts, responsive layouts and designed empty/error states.
