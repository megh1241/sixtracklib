#ifndef SIXTRACKLIB_CUDA_CUDA_ENV_H__
#define SIXTRACKLIB_CUDA_CUDA_ENV_H__

#include "sixtracklib/_impl/definitions.h"
#include "sixtracklib/common/blocks.h"
#include "sixtracklib/common/pyheadtail_particles.h"

#if defined( __cplusplus )
extern "C" {
#endif /* defined( __cplusplus ) */

SIXTRL_HOST_FN bool NS(Track_particles_on_cuda_gpu_part)(
    int const num_of_blocks,
    int const num_threads_per_block,
    SIXTRL_UINT64_T const num_of_turns,
    NS(Blocks)* SIXTRL_RESTRICT particles_buffer,
    NS(Blocks)* SIXTRL_RESTRICT beam_elements,
    NS(Blocks)* SIXTRL_RESTRICT elem_by_elem_buffer,
    ParticleData* p
    /*double* x, 
    double* xp,
    double* y,
    double* yp,
    double *q0, double* mass0, double* beta0, double* gamma0,
    double *z, double* dp, double *p0c
*/
 );

SIXTRL_HOST_FN bool NS(Track_particles_on_cuda)(
    int const num_of_blocks,
    int const num_threads_per_block,
    SIXTRL_UINT64_T const num_of_turns,
    NS(Blocks)* SIXTRL_RESTRICT particles_buffer,
    NS(Blocks)* SIXTRL_RESTRICT beam_elements,
    NS(Blocks)* SIXTRL_RESTRICT elem_by_elem_buffer
   );
#if defined( __cplusplus )
}
#endif /* defined( __cplusplus ) */

#endif /* SIXTRACKLIB_CUDA_CUDA_ENV_H__ */

/* end: sixtracklib/sixtracklib/cuda/cuda_env.h */
