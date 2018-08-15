#ifndef SIXTRACKLIB_CUDA_TRACK_PARTICLES_KERNEL_CUH__
#define SIXTRACKLIB_CUDA_TRACK_PARTICLES_KERNEL_CUH__

#if !defined( SIXTRL_NO_INCLUDES )
    #include "sixtracklib/_impl/definitions.h"
    #include "sixtracklib/common/blocks.h"
    #include "sixtracklib/common/pyheadtail_particles.h"
#endif /* !defined( SIXTRL_NO_INCLUDES ) */

__global__ void Track_remap_serialized_blocks_buffer(
    unsigned char* __restrict__ particles_data_buffer,
    unsigned char* __restrict__ beam_elements_data_buffer,
    unsigned char* __restrict__ elem_by_elem_data_buffer,
    int64_t*       __restrict__ success_flag );

__global__ void Track_particles_kernel_cuda(
    SIXTRL_UINT64_T const num_of_turns,
    unsigned char* __restrict__ particles_data_buffer,
    unsigned char* __restrict__ beam_elements_data_buffer,
    unsigned char* __restrict__ elem_by_elem_data_buffer,
    int64_t*       __restrict__ success_flag );

__global__ void Copy_buffer_pyheadtail_sixtracklib(
    unsigned char* __restrict__ particles_data_buffer,
    double* __restrict__ x,
    double* __restrict__ xp,
    double* __restrict__ y,
    double* __restrict__ yp,
    double*  __restrict__ q0,
    double*  __restrict__ mass0,
    double*  __restrict__ beta0,
    double*  __restrict__ gamma0,
    double*  __restrict__ z,
    double*  __restrict__ dp,
    double*  __restrict__ p0c,
    int64_t*       __restrict__ success_flag );

__global__ void Copy_buffer_sixtracklib_pyheadtail(
    unsigned char* __restrict__ particles_data_buffer,
    double* __restrict__ x,
    double* __restrict__ xp,
    double* __restrict__ y,
    double* __restrict__ yp,
    double*  __restrict__ q0,
    double*  __restrict__ mass0,
    double*  __restrict__ beta0,
    double*  __restrict__ gamma0,
    double*  __restrict__ z,
    double*  __restrict__ dp,
    double*  __restrict__ p0c,
    int64_t*       __restrict__ success_flag );

#endif /* SIXTRACKLIB_CUDA_TRACK_PARTICLES_KERNEL_CUH__ */

/* end sixtracklib/cuda/track_particles_kernel.cuh */

