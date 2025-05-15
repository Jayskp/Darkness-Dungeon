import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;

import 'joystick_controller.dart';
import 'map_loader.dart';
import 'player.dart';
import 'minimap.dart';
import 'enemy.dart';
import 'health_display.dart';

class DungeonGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector {
  late Player player;
  // Initialize joystickController without 'late' since we'll handle it differently
  JoystickController? joystickController;
  late CameraComponent mainCamera;
  late MapLoader mapLoader;
  late Minimap minimap;
  final String mapPath = 'map_ex/jb-32.tmx';
  final List<Enemy> enemies = [];

  // Random for enemy spawning
  final _random = math.Random();

  // Track initialization state
  bool _joystickInitialized = false;

  @override
  Future<void> onLoad() async {
    developer.log('DungeonGame onLoad started');

    // Ensure assets directory is set up correctly
    await images.loadAll([
      // Player sprites
      'Player/idle/1.png',
      'Player/idle/2.png',
      'Player/idle/3.png',
      'Player/idle/4.png',
      'Player/run/1.png',
      'Player/run/2.png',
      'Player/run/3.png',
      'Player/run/4.png',
      'Player/run/5.png',
      'Player/run/6.png',
      'Player/run/7.png',
      'Player/run/8.png',
      'Player/run/9.png',
      'Player/run/10.png',
      'Player/run/11.png',
      'Player/run/12.png',
      'Player/run/13.png',
      'Player/respawn/1.png',
      'Player/respawn/2.png',
      'Player/respawn/3.png',
      'Player/respawn/4.png',
      // Map assets
      'wall.png', 
      // Map tileset
      'map_ex/jb-32-Tileset.png',
    ]);

    developer.log('All images loaded successfully');

    // Create a world for all game components
    final world = World();
    add(world);

    // Load the map
    mapLoader = MapLoader();
    await world.add(mapLoader);
    await mapLoader.loadMap(mapPath);

    // Create the player
    player = Player();
    await world.add(player);

    // Spawn some enemies
    await _spawnEnemies(world);

    // Set up the main camera that follows the player
    final gameSize = mapLoader.mapSize;

    mainCamera = CameraComponent(world: world);
    mainCamera.viewfinder.anchor = Anchor.center;
    mainCamera.viewfinder.zoom = 1.5;
    mainCamera.follow(player);

    // Add camera to the game
    await add(mainCamera);

    // Add minimap overlay
    minimap = Minimap(
      player: player,
      mapSize: gameSize,
      position: Vector2(size.x - 210, 10),
      size: Vector2(200, 150),
    );
    await add(minimap);

    // Add health display
    final healthDisplay = HealthDisplay(
      player: player,
      position: Vector2(10, 10),
    );
    await add(healthDisplay);

    try {
      developer.log('Initializing joystick controller');
      // Initialize joystick controller after player is added to the game
      joystickController = JoystickController(
        player: player,
        margin: const EdgeInsets.only(bottom: 100, left: 50),
      );
      _joystickInitialized = true;
      developer.log('Joystick controller initialized successfully');
    } catch (e) {
      developer.log('Error initializing joystick controller: $e', error: e);
      _joystickInitialized = false;
    }

    developer.log('DungeonGame onLoad completed');
  }

  // A helper method to safely get the joystick overlay
  Widget? getJoystickOverlay() {
    if (!_joystickInitialized || joystickController == null) {
      developer.log('Returning empty container for joystick - not initialized');
      return Container(); // Return empty container if not initialized
    }
    developer.log('Returning joystick overlay widget');
    return joystickController!.buildJoystickOverlay();
  }

  Future<void> _spawnEnemies(World world) async {
    // Create several patrol patterns around the map
    final mapSize = mapLoader.mapSize;
    final patrolPoints = [
      // First patrol area (top-left area)
      [
        Vector2(mapSize.x * 0.2, mapSize.y * 0.2),
        Vector2(mapSize.x * 0.3, mapSize.y * 0.2),
        Vector2(mapSize.x * 0.3, mapSize.y * 0.3),
        Vector2(mapSize.x * 0.2, mapSize.y * 0.3),
      ],
      // Second patrol area (bottom-right area)
      [
        Vector2(mapSize.x * 0.7, mapSize.y * 0.7),
        Vector2(mapSize.x * 0.8, mapSize.y * 0.7),
        Vector2(mapSize.x * 0.8, mapSize.y * 0.8),
        Vector2(mapSize.x * 0.7, mapSize.y * 0.8),
      ],
      // Third patrol area (center area)
      [
        Vector2(mapSize.x * 0.4, mapSize.y * 0.4),
        Vector2(mapSize.x * 0.6, mapSize.y * 0.4),
        Vector2(mapSize.x * 0.6, mapSize.y * 0.6),
        Vector2(mapSize.x * 0.4, mapSize.y * 0.6),
      ],
    ];

    // Spawn 3 enemies, one for each patrol area
    for (int i = 0; i < patrolPoints.length; i++) {
      final patrolArea = patrolPoints[i];
      // Start at a random position in the patrol area
      final randomIndex = _random.nextInt(patrolArea.length);
      final startPosition = patrolArea[randomIndex];

      final enemy = Enemy(
        position: startPosition,
        patrolPoints: patrolArea,
        speed: 50.0 + _random.nextInt(30).toDouble(), // Convert to double
      );

      enemies.add(enemy);
      await world.add(enemy);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update minimap with player position
    if (minimap.isLoaded && player.isLoaded) {
      minimap.updatePlayerPosition(player.position);
    }
  }
}
