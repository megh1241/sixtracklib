#ifndef SIXTRACKLIB_PYHEADTAIL_PARTICLES_H__
#define SIXTRACKLIB_PYHEADTAIL_PARTICLES_H__

#if !defined( SIXTRL_NO_SYSTEM_INCLUDES )
    #include <stdbool.h>
    #include <stdint.h>
    #include <stdio.h>
    #include <stdlib.h>
#endif /* !defined( SIXTRL_NO_SYSTEM_INCLUDES ) */

#if !defined( SIXTRL_NO_INCLUDES )
    #include "sixtracklib/_impl/definitions.h"
    #include "sixtracklib/common/impl/particles_type.h"
#endif /* !defined( SIXTRL_NO_INCLUDES ) */

#if !defined( _GPUCODE ) && defined( __cplusplus )
extern "C" {
#endif /* !defined(  _GPUCODE ) && defined( __cplusplus ) */


struct ParticleData;

typedef struct ParticleData{
    int npart;
    double *x;
    double *xp;
    double *y;
    double *yp;
    double *z;
    double *dp;
    double *q0;
    double *mass0;
    double *p0c;
    double *beta0;
    double *gamma0;
} ParticleData;

#if !defined( _GPUCODE ) && defined( __cplusplus )
}
#endif /* !defined(  _GPUCODE ) && defined( __cplusplus ) */

#endif /* SIXTRACKLIB_COMMON_PARTICLES_H__ */

/* end: sixtracklib/common/particles.h */

