import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'dart:developer' as developer;
import 'dart:ui';
import 'dungeon_game.dart';
import 'enemy.dart';

enum PlayerState { idle, running, attacking, death }

enum PlayerDirection { left, right, up, down }

class Player extends SpriteAnimationComponent
    with HasGameRef<DungeonGame>, KeyboardHandler, CollisionCallbacks {
  Player({super.position})
    : super(size: Vector2(32, 48), anchor: Anchor.center);

  final double _speed = 150;
  late SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _attackAnimation;
  late final SpriteAnimation _deathAnimation;

  PlayerDirection direction = PlayerDirection.down;
  PlayerState state = PlayerState.idle;
  Vector2 movementVector = Vector2.zero();
  bool _facingLeft = false;

  // Health system
  int _maxHealth = 100;
  int _currentHealth = 100;
  bool _isInvulnerable = false;
  double _invulnerabilityTimer = 0;
  double _damageCooldown = 1.0; // 1 second invulnerability after taking damage

  // Getters for health
  int get maxHealth => _maxHealth;
  int get currentHealth => _currentHealth;
  double get healthPercentage => _currentHealth / _maxHealth;

  bool _isLoaded = false;

  @override
  Future<void> onLoad() async {
    if (_isLoaded) return;
    _isLoaded = true;

    // Pre-load all images
    await gameRef.images.loadAll([
      for (int i = 1; i <= 4; i++) 'images/Player/idle/$i.png',
      for (int i = 1; i <= 13; i++) 'images/Player/run/$i.png',
      for (int i = 1; i <= 4; i++) 'images/Player/respawn/$i.png',
    ]);

    await _loadAnimations();
    animation = _idleAnimation;

    // Start in the center of the map
    position = gameRef.mapLoader.mapSize / 2;

    // Add collision detection
    add(
      CircleHitbox(
        radius: size.x / 3,
        position: size / 2,
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update invulnerability timer
    if (_isInvulnerable) {
      _invulnerabilityTimer -= dt;
      if (_invulnerabilityTimer <= 0) {
        _isInvulnerable = false;
      }
    }

    // Die if health reaches 0
    if (_currentHealth <= 0 && state != PlayerState.death) {
      _die();
      return;
    }

    // Handle movement only if player is not dead
    if (state != PlayerState.death) {
      // Store the current position before moving
      final originalPosition = position.clone();

      // Update position based on movement vector
      if (movementVector != Vector2.zero()) {
        position += movementVector.normalized() * _speed * dt;

        // Determine direction for animation
        if (movementVector.x > 0) {
          direction = PlayerDirection.right;
          // Set to face right
          _facingLeft = false;
          transform.scale.x = 1;
        } else if (movementVector.x < 0) {
          direction = PlayerDirection.left;
          // Set to face left
          _facingLeft = true;
          transform.scale.x = -1;
        }

        if (movementVector.y > 0) {
          direction = PlayerDirection.down;
        } else if (movementVector.y < 0) {
          direction = PlayerDirection.up;
        }

        // Set running animation if not already running
        if (state != PlayerState.running) {
          state = PlayerState.running;
          animation = _runAnimation;
        }
      } else if (state != PlayerState.idle && state != PlayerState.attacking) {
        // Set idle animation if not moving and not already idle
        state = PlayerState.idle;
        animation = _idleAnimation;
      }

      // Check for collision with map obstacles
      if (gameRef.mapLoader.collidesWith(position, size)) {
        // If collision detected, revert to original position
        position = originalPosition;
      }

      // Keep player within map bounds
      final mapSize = gameRef.mapLoader.mapSize;
      position.clamp(
        Vector2(width / 2, height / 2),
        Vector2(mapSize.x - width / 2, mapSize.y - height / 2),
      );
    }
  }

  void moveWithJoystick(Vector2 direction) {
    // Only allow movement if not dead
    if (state != PlayerState.death) {
      movementVector = direction;
    }
  }

  void attack() {
    // Only allow attacking if not dead
    if (state != PlayerState.death && state != PlayerState.attacking) {
      state = PlayerState.attacking;
      animation = _attackAnimation;

      // Reset to idle after attack animation completes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state == PlayerState.attacking) {
          state = PlayerState.idle;
          animation = _idleAnimation;
        }
      });
    }
  }

  void takeDamage(int amount) {
    // Only take damage if not invulnerable and not dead
    if (!_isInvulnerable && state != PlayerState.death) {
      _currentHealth -= amount;
      _currentHealth = _currentHealth.clamp(0, _maxHealth);

      // Make player invulnerable for a short time
      _isInvulnerable = true;
      _invulnerabilityTimer = _damageCooldown;

      // Flash the player to indicate damage
      _flashOnDamage();
    }
  }

  void heal(int amount) {
    _currentHealth += amount;
    _currentHealth = _currentHealth.clamp(0, _maxHealth);
  }

  void _die() {
    state = PlayerState.death;
    animation = _deathAnimation;
    movementVector = Vector2.zero();

    // Respawn after a delay
    Future.delayed(const Duration(seconds: 3), () {
      // Reset health and position
      _currentHealth = _maxHealth;
      position = gameRef.mapLoader.mapSize / 2;
      state = PlayerState.idle;
      animation = _idleAnimation;
    });
  }

  void _flashOnDamage() {
    // Flash the player by toggling opacity
    opacity = 0.5;
    Future.delayed(const Duration(milliseconds: 100), () {
      opacity = 1.0;
      Future.delayed(const Duration(milliseconds: 100), () {
        opacity = 0.5;
        Future.delayed(const Duration(milliseconds: 100), () {
          opacity = 1.0;
        });
      });
    });
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Handle collision with enemies
    if (other is Enemy && !_isInvulnerable) {
      // Only take damage if enemy is in attack state
      if (other.state == EnemyState.attack) {
        takeDamage(10); // Take 10 damage from enemy attack
      }
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Reset movement vector
    movementVector = Vector2.zero();

    // Only handle keyboard input if player is not dead
    if (state != PlayerState.death) {
      // Move based on keyboard input
      if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
          keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
        movementVector.y = -1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
          keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
        movementVector.y = 1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
          keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
        movementVector.x = -1;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
          keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
        movementVector.x = 1;
      }

      // Attack with spacebar
      if (keysPressed.contains(LogicalKeyboardKey.space)) {
        attack();
      }
    }

    return true;
  }

  Future<void> _loadAnimations() async {
    try {
      developer.log('Loading Player idle animation');
      final idleSprites = <Sprite>[];
      for (int i = 1; i <= 4; i++) {
        final sprite = Sprite(
          gameRef.images.fromCache('images/Player/idle/$i.png'),
          srcSize: Vector2(32, 32),
        );
        idleSprites.add(sprite);
      }
      _idleAnimation = SpriteAnimation.spriteList(idleSprites, stepTime: 0.15);
      developer.log('Idle animation loaded successfully');

      developer.log('Loading Player run animation');
      final runSprites = <Sprite>[];
      for (int i = 1; i <= 12; i++) {
        final sprite = Sprite(
          gameRef.images.fromCache('images/Player/run/$i.png'),
          srcSize: Vector2(32, 32),
        );
        runSprites.add(sprite);
      }
      _runAnimation = SpriteAnimation.spriteList(runSprites, stepTime: 0.1);
      developer.log('Run animation loaded successfully');

      developer.log('Loading Player attack animation');
      final attackSprites = <Sprite>[];
      for (int i = 1; i <= 4; i++) {
        final sprite = Sprite(
          gameRef.images.fromCache('images/Player/run/$i.png'),
          srcSize: Vector2(32, 32),
        );
        attackSprites.add(sprite);
      }
      _attackAnimation = SpriteAnimation.spriteList(
        attackSprites,
        stepTime: 0.08,
      );
      developer.log('Attack animation loaded successfully');

      developer.log('Loading Player death animation');
      final deathSprites = <Sprite>[];
      for (int i = 1; i <= 4; i++) {
        final sprite = Sprite(
          gameRef.images.fromCache('images/Player/respawn/$i.png'),
          srcSize: Vector2(32, 32),
        );
        deathSprites.add(sprite);
      }
      _deathAnimation = SpriteAnimation.spriteList(deathSprites, stepTime: 0.2);
      developer.log('Death animation loaded successfully');
    } catch (e) {
      developer.log('Error loading player sprites: $e', error: e);
      _createFallbackAnimations();
    }
  }

  // Guaranteed working fallback animations for Flame 1.16.0
  void _createFallbackAnimations() {
    developer.log('Creating guaranteed fallback animations');

    // Create a basic colored sprite in memory
    // This doesn't rely on any external assets
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw a simple colored rectangle
    final paint = Paint()..color = Colors.red;
    canvas.drawRect(Rect.fromLTWH(0, 0, 32, 48), paint);

    // Convert to an image
    final picture = recorder.endRecording();
    final img = picture.toImageSync(32, 48);

    // Create a sprite from the generated image
    final fallbackSprite = Sprite(img);

    // Create animations with the fallback sprite
    final fallbackAnimation = SpriteAnimation.spriteList([
      fallbackSprite,
    ], stepTime: 1.0);

    // Assign to all animation properties
    _idleAnimation = fallbackAnimation;
    _runAnimation = fallbackAnimation;
    _attackAnimation = fallbackAnimation;
    _deathAnimation = fallbackAnimation;

    developer.log('Fallback animations created successfully');
  }
}
