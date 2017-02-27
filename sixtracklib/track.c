#ifndef _GPUCODE

#include <math.h>
#include <stdio.h>
#define M_PI 3.14159265358979323846

#endif


#define CLIGHT 299792458

#include "particle.h"

#include "track.h"

__CUDA_HOST_DEVICE__
int Drift_track(CLGLOBAL Particle* p, CLGLOBAL Drift *el){
  double xp, yp;
  double length=el->length;
  xp = p->px * p->rpp;
  yp = p->py * p->rpp;
  p->x += xp * length;
  p->y += yp * length;
  p->sigma += length * (1 - p->rvv*( 1 + (xp*xp+yp*yp)/2 ) );
  p->s+=length;
//  _DP("Drift_track: length=%g\n",length);
  return 1;
};


__CUDA_HOST_DEVICE__
int DriftExact_track(CLGLOBAL Particle* p, double length){
  double lpzi, lbzi, px, py, opd;
  opd=1+p->delta;
  px=p->px; py=p->py;
  lpzi= length/sqrt(opd*opd-px*px-py*py);
  lbzi=(p->beta0*p->beta0*p->psigma+1)*lpzi;
  p->x += px*lpzi ;
  p->y += py*lpzi ;
  p->sigma += length - lbzi;
  p->s += length ;
  return 1;
}

//int Multipole_track(CLGLOBAL Particle* p, long int order,
//                     double l, double hxl, double hyl, CLGLOBAL double *bal){
__CUDA_HOST_DEVICE__
int Multipole_track(CLGLOBAL Particle* p, CLGLOBAL Multipole *el){
  double x,y,chi,dpx,dpy,zre,zim,b1l,a1l,hxx,hyy;
  long int order=el->order;
  double hxl=el->hxl;
  double hyl=el->hyl;
  double l=el->l;
  CLGLOBAL double *bal = el->bal;
  dpx=bal[order*2];
  dpy=bal[order*2+1];
  x=p->x; y=p->y; chi=p->chi;
//  _DP("Multipole_track: dpx,y=%g %G\n",dpx,dpy);
  for (int ii=order-1;ii>=0;ii--){
    zre=(dpx*x-dpy*y);
    zim=(dpx*y+dpy*x);
//    _DP("Multipole_track: y,x=%g %G\n",x,y);
    dpx=bal[ii*2]+zre;
    dpy=bal[ii*2+1]+zim;
//    _DP("Multipole_track: dpx,y=%g %G\n",dpx,dpy);
  }
  dpx=-chi*dpx ;
  dpy=chi*dpy ;
//  _DP("Multipole_track: dpx,y=%g %G\n",dpx,dpy);
  if (l>0){
     b1l=chi*bal[0]; a1l=chi*bal[1];
     hxx=hxl/l*x; hyy=hyl/l*y;
     dpx+=hxl + hxl*p->delta - b1l*hxx;
     dpy-=hyl + hyl*p->delta - a1l*hyy;
     p->sigma-=chi*(hxx-hyy)*l*p->rvv;
  }
  p->px+=dpx ;  p->py+=dpy ;
  return 1 ;
}

__CUDA_HOST_DEVICE__
int Cavity_track(CLGLOBAL Particle* p, double volt, double freq, double lag ){
  double phase, pt, opd;
  phase=lag-2*M_PI/CLIGHT*freq*p->sigma/p->beta0;
  //printf("ggg00 %e %e\n",p->psigma,p->psigma+p->chi*volt/(p->p0c));
  p->psigma+=p->chi*volt*sin(phase)/(p->p0c*p->beta0);
  pt=p->psigma * p->beta0;
  opd=sqrt( pt*pt+ 2*p->psigma + 1 );
  p->delta=opd - 1;
  p->beta=opd/(1/p->beta0+pt);
  //p->gamma=1/sqrt(1-p->beta*p->beta);
  p->gamma=(pt*p->beta0+1)*p->gamma0;
  p->rpp=1/opd;
  p->rvv=p->beta0/p->beta;
  //printf("ggg2 %e %e %e\n",pt,opd,p->delta);
  return 1;
}

__CUDA_HOST_DEVICE__
int Align_track(CLGLOBAL Particle* p, double cz, double sz,
                                      double dx, double dy){
  double xn,yn;
  xn= cz*p->x-sz*p->y - dx;
  yn= sz*p->x+cz*p->y - dy;
  p->x=xn;
  p->y=yn;
  xn= cz*p->px+sz*p->py;
  yn=-sz*p->px+cz*p->py;
  p->px=xn;
  p->py=yn;
  return 1;
};

/******************************************/



__CUDA_HOST_DEVICE__
LinMap_data LinMap_init( double alpha_x_s0, double beta_x_s0, double alpha_x_s1, double beta_x_s1,
                         double alpha_y_s0, double beta_y_s0, double alpha_y_s1, double beta_y_s1,
                         double dQ_x, double dQ_y ) {
  LinMap_data res;
  double s,c;
  
  //sincos(dQ_x, &s, &c);
  s = sin(dQ_x); c = cos(dQ_x);
  res.matrix[0] = sqrt(beta_x_s1/beta_x_s0)*(c+alpha_x_s0*s);
  res.matrix[1] = sqrt(beta_x_s1*beta_x_s0)*s;
  res.matrix[2] = ((alpha_x_s0-alpha_x_s1)*c - (1.+alpha_x_s0*alpha_x_s1)*s)/sqrt(beta_x_s1*beta_x_s0);
  res.matrix[3] = sqrt(beta_x_s0/beta_x_s1)*(c-alpha_x_s1*s);
  
  //sincos(dQ_y, &s, &c);
  s = sin(dQ_y); c = cos(dQ_y);
  res.matrix[4] = sqrt(beta_y_s1/beta_y_s0)*(c+alpha_y_s0*s);
  res.matrix[5] = sqrt(beta_y_s1*beta_y_s0)*s;
  res.matrix[6] = ((alpha_y_s0-alpha_y_s1)*c - (1.+alpha_y_s0*alpha_y_s1)*s)/sqrt(beta_y_s1*beta_y_s0);
  res.matrix[7] = sqrt(beta_y_s0/beta_y_s1)*(c-alpha_y_s1*s);
  return res;
}


__CUDA_HOST_DEVICE__
int LinMap_track(CLGLOBAL Particle* p, CLGLOBAL LinMap_data *el){
  double M00 = el->matrix[0];
  double M01 = el->matrix[1];
  double M10 = el->matrix[2];
  double M11 = el->matrix[3];
  double M22 = el->matrix[4];
  double M23 = el->matrix[5];
  double M32 = el->matrix[6];
  double M33 = el->matrix[7];
  double x0  = p->x;
  double px0 = p->px;
  double y0  = p->y;
  double py0 = p->py;
  
  p->x  = M00*x0 + M01*px0;
  p->px = M10*x0 + M11*px0;
  p->y  = M22*y0 + M23*py0;
  p->py = M32*y0 + M33*py0;
  return 1;
}

__CUDA_HOST_DEVICE__
int BB4D_track(CLGLOBAL Particle* p, CLGLOBAL BB4D_data *el){
  
  double Ex, Ey;
  
  switch(el->trasv_field_type){
    case 1:
      get_transv_field_gauss_round( (CLGLOBAL transv_field_gauss_round_data*) (el->field_map_data), p->x, p->y, &Ex, &Ey);
      break;
    case 2:
      get_transv_field_gauss_ellip( (CLGLOBAL transv_field_gauss_ellip_data*) (el->field_map_data), p->x, p->y, &Ex, &Ey);
      break;
    default:
      Ex = 1/0.;
      Ey = 1/0.;
  }    
  
  double fact_kick = p->chi * el->N_s * el->q_s * p->q0 * (1. + p->beta * el->beta_s)/(p->p0c*QELEM*(p->beta + el->beta_s));
  
  p->px += fact_kick*Ex;
  p->py += fact_kick*Ey;
  return 1;
}
