Lane A (data/backend) is live on branch `mike`. Pull it.

WHAT'S THERE
- backend,dataAPI/  Python API. Real Basiq open banking working + a mock
                    fallback so nothing breaks offline.
- lib/data/         Dart client for the Flutter app. Already typed.

TO RUN THE BACKEND (each of you, or just point at mine)
  cd "backend,dataAPI"
  python3 -m venv .venv
  .venv/bin/pip install -r requirements.txt
  .venv/bin/uvicorn main:app --port 8000
  Check it: open http://localhost:8000/docs

TO USE IT FROM FLUTTER
  flutter pub get          (I added the `http` package)
  import 'package:moneymoneymoney/data/api_client.dart';
  final api = ApiClient();
  final data = await api.home();   // plan + tower + missions + progression

  Don't write fetch/http calls anywhere else. Everything goes through ApiClient.

THE CONTRACT
  backend,dataAPI/docs/API.md — every endpoint and field.
  Don't rename a field without telling me, three people are coding against it.

IF YOU'RE ON A PHONE not an emulator, I'll run the backend and you use:
  ApiClient(baseUrl: 'http://<my-laptop-IP>:8000')
  Android emulator already works with no baseUrl.

WHAT I STILL OWE YOU
  Nothing blocking. Build against it now — the mock returns realistic data
  whether or not the bank connection is up.