# LinenFlow

iOS app for hotel linen room attendants — count received inventory, calculate bundle distribution across floors, track delivery progress, and save daily logs.

## Requirements

- Xcode 16+ (project targets iOS 17+)
- iPhone or iOS Simulator

## Getting Started

1. Open `LinenFlow.xcodeproj` in Xcode.
2. Select the **HimmerFlow** scheme.
3. Build and run on a simulator or device.

```bash
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

## Project Structure

| Path | Description |
|------|-------------|
| `LinenFlow/` | Main iOS app source |
| `LinenFlowTests/` | Unit tests |
| `LinenFlow Widget/` | Home Screen widget extension |
| `LinenFlowWidgets/` | Widget assets and configuration |
| `android/` | Android companion app |
| `Docs/` | Build log and criteria checklist |

## Tests

Run tests from Xcode (**Product → Test**) or via command line:

```bash
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```

## License

Private — all rights reserved.
