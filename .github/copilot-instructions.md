# AI Agent Instructions for Engineering-Thesis-Voting-App

## Project Overview
This is a Flutter voting application with a client-server architecture designed for conducting secure electronic voting sessions. The app supports both web and mobile platforms using Flutter's cross-platform capabilities.

## Architecture and Components

### Data Layer
- Models are located in `lib/models/` and use Hive for persistence
- Each model has a corresponding `.g.dart` file with generated code
- Models follow a pattern of implementing Hive TypeAdapters (see `enums.dart` and other model files)

### Repository Layer (`lib/repositories/`)
- Repositories handle data persistence using Hive boxes
- Lazy initialization pattern: boxes are opened on first use
- Example: See `meeting_repository.dart` for the standard repository pattern

### Network Layer (`lib/network/`)
- `api_network.dart`: Handles HTTP communication with Admin Host server
- `ws_client.dart`: Manages WebSocket connections
- Base URL format: `http://<host>:8080`
- Standard timeout: 8 seconds for API calls

### UI Screens (`lib/screens/`)
Key screens:
- `landing_page.dart`: Entry point
- `admin_page.dart`: Admin controls
- `voting_page.dart`: Voting interface
- `results_page.dart`: Display voting results

## Development Workflow

### Setup
1. Ensure Flutter is installed and configured
2. Run `flutter pub get` to install dependencies
3. Run `flutter pub run build_runner build` to generate `.g.dart` files

### Key Patterns
- Hive adapters are registered with sequential IDs (see `main.dart`)
- Repository methods are all asynchronous
- Network calls include proper error handling and timeouts

### Testing
- Widget tests are in `test/widget_test.dart`
- Run tests with `flutter test`

## Common Tasks

### Adding a New Model
1. Create model class in `lib/models/`
2. Add `@HiveType` annotation with next available ID
3. Run code generation: `flutter pub run build_runner build`
4. Register adapter in `main.dart`'s `_initHive()`

### Adding a New Screen
1. Create screen in `lib/screens/`
2. Add route in `main.dart`
3. Update navigation logic if needed

### Network Integration
- Use `ApiNetwork` class for HTTP endpoints
- Follow existing error handling patterns
- Remember to close client when done: `apiNetwork.close()`

## Cross-Component Communication
- Models → Repositories → Screens flow for data
- WebSocket client handles real-time updates
- State management through standard Flutter patterns