// TempleApp – 3-Shape Particle Morpher
//
// Integration:
//   ❶ Add `temple_particles` directory to your repo.
//   ❷ In TempleApp's root pubspec.yaml, add:
//
//          path: modules/temple_particles
//
//   ❸ `import 'package:temple_particles/particle_morpher.dart'`
//   ❹ Embed `const ParticleMorpher()` anywhere in your widget tree.
//
// Tested on Flutter 3.22 / Dart 3.3 (iOS 17, Pixel 7).

library temple_particles;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math.dart' as vm;

part 'simplex_noise.dart';

/// ───────────────────────────── Configuration

class _Cfg {
  static const int particleCount = 900;          // 500 – 1000 mobile sweet-spot
  static const int starCount     = 100;
  static const double shapeSize  = 100.0;       // Larger size for Canvas rendering

  static const morphDur   = Duration(milliseconds: 3500);
  static const targetFps  = 24;

  // Idle
  static const idleRot    = 0.08;

  // Visual
  static const morphSize  = 0.175;
  static const morphBright= 0.25;
  static const partSizeLo = 0.3;
  static const partSizeHi = 0.5;
}

/// ───────────────────────────── State models (Provider)

class _MorphState extends ChangeNotifier {
  double t = 0;         // 0-1 progress
  bool   busy = false;
  int    shape = 0;     // 0 sphere | 1 cube | 2 pyramid
  void _set(double v){ t=v; notifyListeners(); }
  void begin(int next){ busy=true; shape=next; notifyListeners(); }
  void end(){ busy=false; t=0; notifyListeners(); }
}

class _LoadState extends ChangeNotifier{
  double p=0; String s="Booting…";
  void upd(double v,String msg){ p=v; s=msg; notifyListeners(); }
}

/// ───────────────────────────── Public widget

class ParticleMorpher extends StatelessWidget {
  /// `true`  → HUD hidden  
  /// `false` → HUD shown   (default)
  const ParticleMorpher({
    super.key,
    this.hideHud = true,
  });

  final bool hideHud;

  @override
  Widget build(BuildContext ctx) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => _MorphState()),
      ChangeNotifierProvider(create: (_) => _LoadState()),
    ],
    child: _PMorpher(hideHud: hideHud),
  );
}

/// ───────────────────────────── Internal stateful

class _PMorpher extends StatefulWidget {
  const _PMorpher({required this.hideHud});

  final bool hideHud;

  @override
  _PMorpherState createState() => _PMorpherState();
}

class _PMorpherState extends State<_PMorpher> with TickerProviderStateMixin{
  late List<vm.Vector3> _particles, _targets;
  late List<double> _sizes, _effects;
  late List<Color> _colors;
  late List<vm.Vector3> _stars;
  late List<double> _starSizes;
  late List<Color> _starColors;

  late List<List<vm.Vector3>> _shapes;
  
  final _n3 = SimplexNoise(math.Random(42));

  late final AnimationController _mCtl;
  late final Animation<double>    _mAnim;

  Timer? _ticker;
  Timer? _morphTimer;
  DateTime _tLast = DateTime.now();
  double _elapsed = 0;
  bool _ready=false;
  
  double _rotationY = 0;

  /// ───────────────────────── Life-cycle

  @override void initState(){
    super.initState();
    _mCtl = AnimationController(vsync:this,duration:_Cfg.morphDur);
    _mAnim = CurvedAnimation(parent:_mCtl,curve:Curves.easeInOutCubic)
      ..addListener(()=>context.read<_MorphState>()._set(_mAnim.value))
      ..addStatusListener((s){ if(s==AnimationStatus.completed) _finishMorph(); });
    WidgetsBinding.instance.addPostFrameCallback((_)=>_boot());
  }

  Future<void> _boot()async{
    final ld=context.read<_LoadState>();
    try{
      ld.upd(.1,"Building shapes");
      _shapes=[
        _sphere(_Cfg.particleCount,_Cfg.shapeSize),
        _cube  (_Cfg.particleCount,_Cfg.shapeSize),
        _pyramid(_Cfg.particleCount,_Cfg.shapeSize),
      ];

      ld.upd(.3,"Allocating particles");
      _particles = List.generate(_Cfg.particleCount, (i) => _shapes[0][i].clone());
      _targets = List.generate(_Cfg.particleCount, (i) => _shapes[0][i].clone());
      _sizes = List.generate(_Cfg.particleCount, (i) => 
        _Cfg.partSizeLo + math.Random().nextDouble()*(_Cfg.partSizeHi-_Cfg.partSizeLo));
      _effects = List.filled(_Cfg.particleCount, 0.0);
      _colors = List.generate(_Cfg.particleCount, (i) => Colors.blue);
      
      ld.upd(.6,"Creating stars");
      _initStars();
      
      ld.upd(.8,"Coloring particles");
      _recolor();

      ld.upd(.9,"Starting animation");
      _ready=true;
      _ticker=Timer.periodic(
        Duration(milliseconds:(1000/_Cfg.targetFps).round()),
        (_)=>_animate(),
      );
      
      // Start automatic morphing after 3 seconds, then every 5 seconds
      Timer(const Duration(seconds: 3), () {
        _autoMorph();
        _morphTimer=Timer.periodic(
          const Duration(seconds: 5),
          (_)=>_autoMorph(),
        );
      });
      
      ld.upd(1,"Ready!");
      setState(()=>{});
    }catch(e,st){
      debugPrint("Boot error: $e\n$st");
      ld.upd(0,"Error: $e");
    }
  }

  /// ───────── Shape generators

  List<vm.Vector3> _sphere(int n,double r){
    final out = <vm.Vector3>[];
    final gap=math.pi*(math.sqrt(5)-1);
    final radius = r * 1.4; // Consistent scale with other shapes
    for(int i=0;i<n;i++){
      final y=1-(i/(n-1))*2;
      final rad=math.sqrt(1-y*y);
      final theta=gap*i;
      out.add(vm.Vector3(
        math.cos(theta)*rad*radius,
        y*radius,
        math.sin(theta)*rad*radius,
      ));
    }
    return out;
  }
  
  List<vm.Vector3> _cube(int n,double s){
    final out = <vm.Vector3>[];
    final h=s*1.4; // Consistent scale with other shapes
    final rng=math.Random(42);
    for(int i=0;i<n;i++){
      final f=rng.nextInt(6); 
      final u=rng.nextDouble()*h*2-h; 
      final v=rng.nextDouble()*h*2-h;
      switch(f){
        case 0: out.add(vm.Vector3( h,u,v)); break;
        case 1: out.add(vm.Vector3(-h,u,v)); break;
        case 2: out.add(vm.Vector3(u, h,v)); break;
        case 3: out.add(vm.Vector3(u,-h,v)); break;
        case 4: out.add(vm.Vector3(u,v, h)); break;
        case 5: out.add(vm.Vector3(u,v,-h)); break;
      }
    }
    return out;
  }
  
  List<vm.Vector3> _pyramid(int n,double s){
    final out = <vm.Vector3>[];
    final h=s*1.4; // Consistent scale with other shapes (height)
    final hb=s*1.4; // Consistent scale with other shapes (base)
    final rng=math.Random(137);
    final apex=vm.Vector3(0,h/2,0);
    final base=[
      vm.Vector3(-hb,-h/2,-hb),
      vm.Vector3( hb,-h/2,-hb),
      vm.Vector3( hb,-h/2, hb),
      vm.Vector3(-hb,-h/2, hb),
    ];
    final baseArea=s*s;
    final sideArea=.5*s*math.sqrt(h*h+hb*hb);
    final baseW=baseArea/(baseArea+4*sideArea);

    for(int i=0;i<n;i++){
      if(rng.nextDouble()<baseW){
        final u=rng.nextDouble(),v=rng.nextDouble();
        final p1=base[0]+(base[1]-base[0])*u;
        final p2=base[3]+(base[2]-base[3])*u;
        final p =p1+(p2-p1)*v;
        out.add(p);
      }else{
        final face=rng.nextInt(4);
        final v1=base[face], v2=base[(face+1)%4];
        double u=rng.nextDouble(), v=rng.nextDouble();
        if(u+v>1){u=1-u; v=1-v;}
        final p=v1+(v2-v1)*u+(apex-v1)*v;
        out.add(p);
      }
    }
    return out;
  }

  /// ───────── Star system

  void _initStars(){
    _stars = [];
    _starSizes = [];
    _starColors = [];
          final rng=math.Random();
    for(int i=0;i<_Cfg.starCount;i++){
      final th=rng.nextDouble()*math.pi*2;
      final ph=math.acos(2*rng.nextDouble()-1);
      final r=300+rng.nextDouble()*200;
      _stars.add(vm.Vector3(
        r*math.sin(ph)*math.cos(th),
        r*math.sin(ph)*math.sin(th),
        r*math.cos(ph),
      ));

      final b=.3+rng.nextDouble()*.3;
      _starColors.add(Color.fromRGBO(
        (b*0.8*255).round(),
        (b*0.9*255).round(),
        (b*255).round(),
        0.7
      ));
      _starSizes.add(rng.nextDouble()*.8+.4);
    }
  }

  /// ───────── Animation

  void _animate(){
    if(!_ready||!mounted) return;
    final now=DateTime.now();
    final dt=now.difference(_tLast).inMicroseconds/1e6;
    _tLast=now; 
    _elapsed+=dt;
    
    _rotationY += dt * _Cfg.idleRot;

    final m=context.read<_MorphState>();
    m.busy ? _stepMorph(dt) : _stepIdle(dt);
    
    setState(() {});
  }

  void _stepMorph(double dt){
    final t=context.read<_MorphState>().t;
    final eff=math.sin(t*math.pi);
    
    // Apply breathing animation during morph to avoid discontinuity
    final scale=1+math.sin(_elapsed*.5)*.015;

    for(int i=0;i<_particles.length;i++){
      // Linear interpolation with breathing scale applied consistently
      final basePos = _particles[i] * (1-t) + _targets[i] * t;
      _particles[i] = basePos * scale;
      _effects[i] = eff;
    }
  }

  void _stepIdle(double dt){
    final scale=1+math.sin(_elapsed*.5)*.015;
    final currentShape = context.read<_MorphState>().shape;
    for(int i=0;i<_particles.length;i++){
      final base = _shapes[currentShape][i];
      _particles[i] = base * scale;
      _effects[i] = 0;
    }
  }

  /// ───────── UI helpers

  void _autoMorph(){
    if(_mCtl.isAnimating) return;
    final m=context.read<_MorphState>();
    final next=(m.shape+1)%_shapes.length;
    _targets = _shapes[next].map((v) => v.clone()).toList();
    m.begin(next);
    _mCtl.forward();
  }
  
  void _finishMorph(){
    final m=context.read<_MorphState>();
    
    // Apply current breathing scale to maintain continuity
    final scale=1+math.sin(_elapsed*.5)*.015;
    _particles = _targets.map((v) => v * scale).toList();
    
    for(int i=0;i<_effects.length;i++) {
      _effects[i] = 0;
    }
    _recolor();
    m.end();
    _mCtl.reset();
  }
  
  void _recolor(){
    const maxR=_Cfg.shapeSize*1.1;
    for(int i=0;i<_particles.length;i++){
      final p = _particles[i];
      final d=p.length;
      final t=(d/maxR).clamp(0,1).toDouble();
      final n=(_n3.noise3D(p.x*.01,p.y*.01,p.z*.01)+1)*.5;

      final h=200/360;
      final s=0.6+(n*0.1);
      final l=0.55+0.45*t;
      _colors[i] = _hslToColor(h,s,l);
    }
  }
  
  Color _hslToColor(double h,double s,double l){
    double q=l<.5? l*(1+s): l+s-l*s;
    double p=2*l-q;
    double r=_hue(p,q,h+1/3);
    double g=_hue(p,q,h);
    double b=_hue(p,q,h-1/3);
    return Color.fromRGBO((r*255).round(),(g*255).round(),(b*255).round(),1);
  }
  
  double _hue(double p,double q,double t){
    if(t<0) t+=1; if(t>1) t-=1;
    if(t<1/6) return p+(q-p)*6*t;
    if(t<1/2) return q;
    if(t<2/3) return p+(q-p)*(2/3-t)*6;
    return p;
  }

  @override void dispose(){
    _ticker?.cancel();
    _morphTimer?.cancel();
    _mCtl.dispose();
    super.dispose();
  }

  /// ───────── Canvas Painter

  @override Widget build(BuildContext ctx) => Stack(
    children:[
      if(_ready)
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                stars: _stars,
                particleColors: _colors,
                starColors: _starColors,
                particleSizes: _sizes,
                starSizes: _starSizes,
                effects: _effects,
                rotationY: _rotationY,
                morphState: context.watch<_MorphState>(),
              ),
              size: Size.infinite,
            ),
          ),
        ),
      Consumer<_LoadState>(builder:(_,l,__){
        if(l.p>=1&&_ready) return const SizedBox.shrink();
        return Container(
          color:Colors.black,
          child:Center(
            child:Column(
              mainAxisSize:MainAxisSize.min,
              children:[
                const Text('Initializing Particles…',style:TextStyle(fontSize:22,color:Colors.white)),
                const SizedBox(height:24),
                SizedBox(
                  width:280,
                  child:Column(children:[
                    LinearProgressIndicator(
                      value:l.p,
                      backgroundColor:Colors.white12,
                      valueColor:AlwaysStoppedAnimation(
                        Color.lerp(const Color(0xff00a2ff),const Color(0xff00ffea),l.p)!),
                      minHeight:6,
                    ),
                    const SizedBox(height:14),
                    Text(l.s,style:const TextStyle(color:Colors.white70)),
                  ]),
                ),
              ],
            ),
          ),
        );
      }),
      if (_ready)
        Visibility(
          visible: !widget.hideHud,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _Hud(),
            ),
          ),
        ),
    ],
  );
}

/// ───────────────────────────── Custom Painter

class _ParticlePainter extends CustomPainter {
  final List<vm.Vector3> particles;
  final List<vm.Vector3> stars;
  final List<Color> particleColors;
  final List<Color> starColors;
  final List<double> particleSizes;
  final List<double> starSizes;
  final List<double> effects;
  final double rotationY;
  final _MorphState morphState;

  const _ParticlePainter({
    required this.particles,
    required this.stars,
    required this.particleColors,
    required this.starColors,
    required this.particleSizes,
    required this.starSizes,
    required this.effects,
    required this.rotationY,
    required this.morphState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) / 400;

    // Draw stars first
    for (int i = 0; i < stars.length; i++) {
      final star = _project3D(stars[i], center, scale, rotationY);
      if (star != null) {
        final paint = Paint()
          ..color = starColors[i]
          ..style = PaintingStyle.fill;
        canvas.drawCircle(star, starSizes[i] * scale, paint);
      }
    }

    // Draw particles
    for (int i = 0; i < particles.length; i++) {
      final particle = _project3D(particles[i], center, scale, rotationY);
      if (particle != null) {
        final effect = effects[i];
        final size = particleSizes[i] * scale * (1 + effect * _Cfg.morphSize);
        final color = particleColors[i];
        
        final paint = Paint()
          ..color = Color.fromRGBO(
            ((color.r * 255.0).round() * (1 + effect * _Cfg.morphBright)).clamp(0, 255).round(),
            ((color.g * 255.0).round() * (1 + effect * _Cfg.morphBright)).clamp(0, 255).round(),
            ((color.b * 255.0).round() * (1 + effect * _Cfg.morphBright)).clamp(0, 255).round(),
            color.a,
          )
          ..style = PaintingStyle.fill;
        canvas.drawCircle(particle, size, paint);
      }
    }
  }

  Offset? _project3D(vm.Vector3 point, Offset center, double scale, double rotY) {
    // Simple 3D to 2D projection with rotation
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    
    final rotatedX = point.x * cosY - point.z * sinY;
    final rotatedZ = point.x * sinY + point.z * cosY + 300; // Add depth offset
    
    if (rotatedZ <= 0) return null; // Behind camera
    
    final perspective = 200 / rotatedZ;
    final x = center.dx + rotatedX * scale * perspective;
    final y = center.dy - point.y * scale * perspective;
    
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true; // Always repaint for animation
  }
}

/// Info HUD widget (unchanged logic, just moved for clarity)
class _Hud extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x59191e32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Consumer<_MorphState>(builder: (_, m, __) {
        const names = ['Sphere', 'Cube', 'Pyramid'];
        return Text(
          m.busy ? 'Morphing…'
                 : 'Shape: ${names[m.shape]}  (auto-morphing)',
          style: TextStyle(fontSize: 14, color: Colors.white, shadows: [
            Shadow(color: m.busy ? const Color(0xccff9632) : const Color(0xcc0080ff),
                   blurRadius: m.busy ? 8 : 5),
          ]),
        );
      }),
    );
  }
} 