part of 'particle_morpher.dart';

// Lightweight 3- & 4-D simplex-noise, public-domain core adapted for Dart.
// Zero runtime allocations in hot loops.

class SimplexNoise{
  static const _grad3=<List<int>>[
    [ 1, 1,0],[-1, 1,0],[ 1,-1,0],[-1,-1,0],
    [ 1, 0,1],[-1, 0,1],[ 1, 0,-1],[-1, 0,-1],
    [ 0, 1,1],[ 0,-1,1],[ 0, 1,-1],[ 0,-1,-1],
  ];
  static const _grad4=<List<int>>[
    [0,1,1,1],[0,1,1,-1],[0,1,-1,1],[0,1,-1,-1],
    [0,-1,1,1],[0,-1,1,-1],[0,-1,-1,1],[0,-1,-1,-1],
    [1,0,1,1],[1,0,1,-1],[1,0,-1,1],[1,0,-1,-1],
    [-1,0,1,1],[-1,0,1,-1],[-1,0,-1,1],[-1,0,-1,-1],
    [1,1,0,1],[1,1,0,-1],[1,-1,0,1],[1,-1,0,-1],
    [-1,1,0,1],[-1,1,0,-1],[-1,-1,0,1],[-1,-1,0,-1],
    [1,1,1,0],[1,1,-1,0],[1,-1,1,0],[1,-1,-1,0],
    [-1,1,1,0],[-1,1,-1,0],[-1,-1,1,0],[-1,-1,-1,0],
  ];
  late final List<int> _perm=List.filled(512,0),
                       _p12=List.filled(512,0);

  SimplexNoise([math.Random? rng]){
    rng??=math.Random();
    final base=List<int>.generate(256,(i)=>i)..shuffle(rng);
    for(int i=0;i<512;i++){
      _perm[i]=base[i&255];
      _p12[i]=_perm[i]%12;
    }
  }

  double noise3D(double x,double y,double z){
    const F3=1/3,G3=1/6;
    final s=(x+y+z)*F3;
    final i=(x+s).floor(), j=(y+s).floor(), k=(z+s).floor();
    final t=(i+j+k)*G3;
    final X0=i-t, Y0=j-t, Z0=k-t;
    var x0=x-X0, y0=y-Y0, z0=z-Z0;

    late int i1,j1,k1,i2,j2,k2;
    if(x0>=y0){
      if(y0>=z0){ i1=1;j1=0;k1=0; i2=1;j2=1;k2=0; }
      else if(x0>=z0){ i1=1;j1=0;k1=0; i2=1;j2=0;k2=1; }
      else{ i1=0;j1=0;k1=1; i2=1;j2=0;k2=1; }
    }else{
      if(y0<z0){ i1=0;j1=0;k1=1; i2=0;j2=1;k2=1; }
      else if(x0<z0){ i1=0;j1=1;k1=0; i2=0;j2=1;k2=1; }
      else{ i1=0;j1=1;k1=0; i2=1;j2=1;k2=0; }
    }

    final x1=x0-i1+G3, y1=y0-j1+G3, z1=z0-k1+G3;
    final x2=x0-i2+2*G3, y2=y0-j2+2*G3, z2=z0-k2+2*G3;
    final x3=x0-1+3*G3, y3=y0-1+3*G3, z3=z0-1+3*G3;

    final ii=i&255, jj=j&255, kk=k&255;
    final gi0=_p12[ii+_perm[jj+_perm[kk]]];
    final gi1=_p12[ii+i1+_perm[jj+j1+_perm[kk+k1]]];
    final gi2=_p12[ii+i2+_perm[jj+j2+_perm[kk+k2]]];
    final gi3=_p12[ii+1+_perm[jj+1+_perm[kk+1]]];

    double n0=0,n1=0,n2=0,n3=0;

    double t0=0.6-x0*x0-y0*y0-z0*z0;
    if(t0>0){ t0*=t0; n0=t0*t0*_dot3(_grad3[gi0],x0,y0,z0);}
    double t1=0.6-x1*x1-y1*y1-z1*z1;
    if(t1>0){ t1*=t1; n1=t1*t1*_dot3(_grad3[gi1],x1,y1,z1);}
    double t2=0.6-x2*x2-y2*y2-z2*z2;
    if(t2>0){ t2*=t2; n2=t2*t2*_dot3(_grad3[gi2],x2,y2,z2);}
    double t3=0.6-x3*x3-y3*y3-z3*z3;
    if(t3>0){ t3*=t3; n3=t3*t3*_dot3(_grad3[gi3],x3,y3,z3);}

    return 32*(n0+n1+n2+n3);
  }

  double noise4D(double x,double y,double z,double w){
    const F4=(math.sqrt(5)-1)/4, G4=(5-math.sqrt(5))/20;
    final s=(x+y+z+w)*F4;
    final i=(x+s).floor(), j=(y+s).floor(), k=(z+s).floor(), l=(w+s).floor();
    final t=(i+j+k+l)*G4;
    final X0=i-t, Y0=j-t, Z0=k-t, W0=l-t;
    var x0=x-X0, y0=y-Y0, z0=z-Z0, w0=w-W0;

    int rankx=0,ranky=0,rankz=0,rankw=0;
    if(x0>y0) rankx++; else ranky++;
    if(x0>z0) rankx++; else rankz++;
    if(x0>w0) rankx++; else rankw++;
    if(y0>z0) ranky++; else rankz++;
    if(y0>w0) ranky++; else rankw++;
    if(z0>w0) rankz++; else rankw++;

    final i1=rankx>=3?1:0, j1=ranky>=3?1:0, k1=rankz>=3?1:0, l1=rankw>=3?1:0;
    final i2=rankx>=2?1:0, j2=ranky>=2?1:0, k2=rankz>=2?1:0, l2=rankw>=2?1:0;
    final i3=rankx>=1?1:0, j3=ranky>=1?1:0, k3=rankz>=1?1:0, l3=rankw>=1?1:0;

    final x1=x0-i1+G4, y1=y0-j1+G4, z1=z0-k1+G4, w1=w0-l1+G4;
    final x2=x0-i2+2*G4, y2=y0-j2+2*G4, z2=z0-k2+2*G4, w2=w0-l2+2*G4;
    final x3=x0-i3+3*G4, y3=y0-j3+3*G4, z3=z0-k3+3*G4, w3=w0-l3+3*G4;
    final x4=x0-1+4*G4, y4=y0-1+4*G4, z4=z0-1+4*G4, w4=w0-1+4*G4;

    final ii=i&255, jj=j&255, kk=k&255, ll=l&255;
    int gi0=_perm[ii+_perm[jj+_perm[kk+_perm[ll]]]]%32;
    int gi1=_perm[ii+i1+_perm[jj+j1+_perm[kk+k1+_perm[ll+l1]]]]%32;
    int gi2=_perm[ii+i2+_perm[jj+j2+_perm[kk+k2+_perm[ll+l2]]]]%32;
    int gi3=_perm[ii+i3+_perm[jj+j3+_perm[kk+k3+_perm[ll+l3]]]]%32;
    int gi4=_perm[ii+1+_perm[jj+1+_perm[kk+1+_perm[ll+1]]]]%32;

    double n0=0,n1=0,n2=0,n3=0,n4=0;
    double t0=0.6-x0*x0-y0*y0-z0*z0-w0*w0;
    if(t0>0){ t0*=t0; n0=t0*t0*_dot4(_grad4[gi0],x0,y0,z0,w0);}
    double t1=0.6-x1*x1-y1*y1-z1*z1-w1*w1;
    if(t1>0){ t1*=t1; n1=t1*t1*_dot4(_grad4[gi1],x1,y1,z1,w1);}
    double t2=0.6-x2*x2-y2*y2-z2*z2-w2*w2;
    if(t2>0){ t2*=t2; n2=t2*t2*_dot4(_grad4[gi2],x2,y2,z2,w2);}
    double t3=0.6-x3*x3-y3*y3-z3*z3-w3*w3;
    if(t3>0){ t3*=t3; n3=t3*t3*_dot4(_grad4[gi3],x3,y3,z3,w3);}
    double t4=0.6-x4*x4-y4*y4-z4*z4-w4*w4;
    if(t4>0){ t4*=t4; n4=t4*t4*_dot4(_grad4[gi4],x4,y4,z4,w4);}

    return 27*(n0+n1+n2+n3+n4);
  }

  double _dot3(List<int> g,double x,double y,double z)=>g[0]*x+g[1]*y+g[2]*z;
  double _dot4(List<int> g,double x,double y,double z,double w)=>g[0]*x+g[1]*y+g[2]*z+g[3]*w;
}