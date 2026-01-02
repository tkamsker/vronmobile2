import 'package:flutter/material.dart';
import 'package:vronmobile2/core/config/env_config.dart';

/// Canvas configuration settings loaded from .env
/// Controls canvas behavior, rotation increments, connection thresholds
class CanvasConfiguration {
  final double canvasWidth;
  final double canvasHeight;
  final double zoomLevel;
  final Offset panOffset;
  final int rotationIncrement; // degrees per tap
  final int doorConnectionThreshold; // pixels
  final int gridSize; // pixels (0 = disabled)

  const CanvasConfiguration({
    required this.canvasWidth,
    required this.canvasHeight,
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    required this.rotationIncrement,
    required this.doorConnectionThreshold,
    required this.gridSize,
  });

  /// Create configuration from .env values with canvas dimensions
  factory CanvasConfiguration.fromEnv({
    required double canvasWidth,
    required double canvasHeight,
  }) {
    return CanvasConfiguration(
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      zoomLevel: 1.0,
      panOffset: Offset.zero,
      rotationIncrement: EnvConfig.roomRotationDegrees,
      doorConnectionThreshold: EnvConfig.doorConnectionThreshold,
      gridSize: EnvConfig.canvasGridSize,
    );
  }

  /// Create default configuration with standard canvas size
  factory CanvasConfiguration.defaultConfig() {
    return CanvasConfiguration(
      canvasWidth: 800,
      canvasHeight: 600,
      zoomLevel: 1.0,
      panOffset: Offset.zero,
      rotationIncrement: EnvConfig.roomRotationDegrees,
      doorConnectionThreshold: EnvConfig.doorConnectionThreshold,
      gridSize: EnvConfig.canvasGridSize,
    );
  }

  /// Copy with new values
  CanvasConfiguration copyWith({
    double? canvasWidth,
    double? canvasHeight,
    double? zoomLevel,
    Offset? panOffset,
    int? rotationIncrement,
    int? doorConnectionThreshold,
    int? gridSize,
  }) {
    return CanvasConfiguration(
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      rotationIncrement: rotationIncrement ?? this.rotationIncrement,
      doorConnectionThreshold:
          doorConnectionThreshold ?? this.doorConnectionThreshold,
      gridSize: gridSize ?? this.gridSize,
    );
  }
}
