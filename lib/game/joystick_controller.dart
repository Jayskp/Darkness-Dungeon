import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flame/components.dart';
import 'player.dart';
import 'dart:math' as math;

class JoystickController {
  final Player player;
  final EdgeInsets margin;
  final bool isDraggable;
  bool _isInitialized = false;

  // The raw joystick values
  Vector2 _stickPosition = Vector2.zero();

  JoystickController({
    required this.player,
    this.margin = const EdgeInsets.only(bottom: 100, left: 100),
    this.isDraggable = false,
  }) {
    _isInitialized = true;
  }

  Widget buildJoystickOverlay() {
    if (!_isInitialized) {
      return Container(); // Return empty container if not initialized
    }

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: margin,
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.purple.shade800,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _updateJoystickPosition(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updateJoystickPosition(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _stickPosition = Vector2.zero();
    player.moveWithJoystick(_stickPosition);
  }

  void _updateJoystickPosition(Offset position) {
    // Calculate the center of the joystick
    final centerX = 60.0; // Half of container width
    final centerY = 60.0; // Half of container height

    // Calculate distance from center
    final dx = position.dx - centerX;
    final dy = position.dy - centerY;

    // Calculate the distance from the center
    final distance = math.sqrt(dx * dx + dy * dy);

    // Limit the distance to the radius of the joystick
    final maxDistance = 30.0; // Half of inner container width

    if (distance > 0) {
      // Normalize the position
      double normalizedDx = dx / distance;
      double normalizedDy = dy / distance;

      // Calculate the actual distance to use (capped at maxDistance)
      final usedDistance = math.min(distance, maxDistance);

      // Calculate the final position values
      final normalizedX = normalizedDx * (usedDistance / maxDistance);
      final normalizedY = normalizedDy * (usedDistance / maxDistance);

      // Update stick position
      _stickPosition = Vector2(normalizedX, normalizedY);

      // Update player movement
      player.moveWithJoystick(_stickPosition);
    }
  }
}

// Note: We don't need the sin/cos functions anymore as the joystick package
// gives us normalized values directly
