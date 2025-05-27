# TempleApp — 3-Shape Particle Morpher (Mobile-Optimised v1.0.0)

A self-contained Flutter package that renders a 500 – 1,000-point particle system able to morph between Sphere → Cube → Pyramid with Bezier-swarm motion, 3D/4D simplex-noise displacement, and a dim blue-white star-field backdrop.

Targets 24 FPS on mid-range phones while preserving all visual flair of the 15K-point desktop demo.

## Features

- **3D Particle System**: 900 interactive particles that can morph between three geometric shapes
- **Shape Morphing**: Smooth transitions between sphere, cube, and pyramid formations
- **Advanced Visual Effects**:
  - Bezier curve interpolation during morphing
  - 3D/4D simplex noise displacement for organic movement
  - Swirling particle motion during transitions
  - Dynamic color gradients based on particle position
- **Starfield Background**: 100 twinkling stars for atmospheric depth
- **Mobile Optimized**: Targets 24 FPS on mid-range devices
- **Interactive Controls**: Touch to pause auto-rotation, tap button to trigger morphs

## Project Structure

```
temple_particles/
├── lib/
│   ├── particle_morpher.dart    ← Main widget for TempleApp
│   └── simplex_noise.dart       ← Noise generation algorithms
├── assets/
│   └── shaders/
│       ├── particles.vert       ← Particle vertex shader
│       ├── particles.frag       ← Particle fragment shader
│       ├── stars.vert          ← Star vertex shader
│       └── stars.frag          ← Star fragment shader
├── pubspec.yaml
└── README.md
```

## Quick Start

1. **Add to your Flutter project**:
   ```yaml
   # In your app's pubspec.yaml
   dependencies:
     temple_particles:
       path: path/to/temple_particles
   ```

2. **Import and use**:
   ```dart
   import 'package:temple_particles/particle_morpher.dart';
   
   // Add anywhere in your widget tree
   const ParticleMorpher()
   ```

3. **Run the project**:
   ```bash
   cd temple_particles
   flutter pub get
   flutter run
   ```

## Dependencies

- **flutter_gl**: WebGL wrapper for 3D rendering
- **three_dart**: Three.js-style 3D API for Dart
- **vector_math**: 3D vector mathematics
- **provider**: State management for UI updates

## Performance

- **Particle Count**: 900 particles (optimized for mobile)
- **Target FPS**: 24 FPS on mid-range devices
- **Memory Efficient**: Zero runtime allocations in animation loops
- **GPU Accelerated**: Uses hardware-accelerated WebGL rendering

## Controls

- **Drag**: Orbit around the particle system
- **Pinch**: Zoom in/out
- **Touch**: Tap "Change Shape" button to trigger morphing
- **Auto-rotate**: Pauses when touching, resumes when released

## Technical Details

### Shape Generation
- **Sphere**: Fibonacci spiral distribution for even spacing
- **Cube**: Random distribution across six faces
- **Pyramid**: Weighted distribution between base and triangular faces

### Animation System
- **Morphing**: Quadratic Bezier interpolation with intermediate swarm points
- **Idle Animation**: Gentle breathing and noise-based displacement
- **Effects**: Swirl rotation around quasi-random axes during transitions

### Shader Features
- **Particle Rendering**: Circular points with smooth alpha falloff
- **Dynamic Sizing**: Size changes during morphing for emphasis
- **Color Enhancement**: Brightness boosts during active transitions
- **Star Rendering**: Twinkling effect with distance-based sizing

## Integration Notes

This package is designed to be dropped directly into TempleApp or any Flutter application. The `ParticleMorpher` widget is self-contained and manages its own state through Provider.

The system automatically handles:
- WebGL context initialization
- Shader compilation and loading
- Asset management
- Performance optimization
- Error handling and graceful fallbacks

## Tested Platforms

- **iOS**: iPhone 11 and newer
- **Android**: Pixel 4 and equivalent
- **Flutter**: 3.22+ / Dart 3.3+

---

© 2025 TempleApp | MIT License