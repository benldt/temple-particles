import 'package:flutter/material.dart';
import 'package:temple_particles/particle_morpher.dart';

void main() {
  runApp(const TempleParticlesExampleApp());
}

class TempleParticlesExampleApp extends StatelessWidget {
  const TempleParticlesExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temple Particles Demo',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const ParticleDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ParticleDemo extends StatelessWidget {
  const ParticleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ParticleMorpher(),
    );
  }
} 