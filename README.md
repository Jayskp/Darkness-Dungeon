# Dungeon Adventure Game

A 2D dungeon game built with Flutter and Flame featuring TMX map loading, joystick controls, and a minimap.

## Features

- TMX map loading from assets/map_ex
- Main camera that follows the player
- Minimap in the top-right corner showing the full map
- Joystick controls for player movement
- Player animations for different states (idle, run, attack, death)

## How to Run

1. Ensure you have Flutter installed
2. Clone this repository
3. Run the following commands:

```bash
flutter pub get
flutter run
```

## Controls

- Joystick: Move the player
- Keyboard: Use arrows or WASD to move
- Space: Attack

## Development Notes

This game demonstrates:
- Loading TMX maps using flame_tiled
- Setting up a camera system with a main camera and minimap
- Implementing joystick controls and keyboard input
- Creating animations for the player character
- Proper Flame game architecture with components

## Project Structure

- `lib/main.dart` - Main entry point
- `lib/game/dungeon_game.dart` - Main game class
- `lib/game/player.dart` - Player character
- `lib/game/map_loader.dart` - TMX map loading
- `lib/game/joystick_controller.dart` - Joystick controls
- `lib/game/minimap.dart` - Minimap implementation
