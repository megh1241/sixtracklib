#include "sixtracklib/cuda/cuda_env.h"

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <cuda_runtime_api.h>
#include <cuda.h>

#include "sixtracklib/_impl/definitions.h"
#include "sixtracklib/common/blocks.h"
#include "sixtracklib/cuda/impl/track_particles_kernel.cuh"
#include "sixtracklib/common/pyheadtail_particles.h"

extern __host__ bool NS(Track_particles_on_cuda_gpu_part)(
    int const num_of_blocks,
    int const num_threads_per_block,
    SIXTRL_UINT64_T const num_of_turns,
    NS(Blocks)* SIXTRL_RESTRICT particles_buffer,
    NS(Blocks)* SIXTRL_RESTRICT beam_elements,
    NS(Blocks)* SIXTRL_RESTRICT elem_by_elem_buffer,
    ParticleData *p
    );

bool __host__ NS(Track_particles_on_cuda_gpu_part)(
    int const num_of_blocks,
    int const num_threads_per_block,
    SIXTRL_UINT64_T const num_of_turns,
    NS(Blocks)* SIXTRL_RESTRICT particles_buffer,
    NS(Blocks)* SIXTRL_RESTRICT beam_elements,
    NS(Blocks)* SIXTRL_RESTRICT elem_by_elem_buffer,
    ParticleData *p
    )
{
    double *x = p->x;
    double *xp = p->xp;
    double *y = p->y;
    double *yp = p->yp;
    double *q0 = p->q0;
    double *mass0 = p->mass0;
    double *beta0 = p->beta0;
    double *gamma0 = p->gamma0;
    double *z = p->z;
    double *dp = p->dp;
    double *p0c = p->p0c;
    bool success = false;

    if( ( NS(Blocks_are_serialized)( particles_buffer ) ) &&
        ( NS(Blocks_are_serialized)( beam_elements ) ) )
    {
        cudaError_t err;

        SIXTRL_STATIC_VAR uint64_t const U64_ZERO =
            static_cast< uint64_t >( 0 );

        uint64_t dummy_elem_by_elem_header[ 4 ] =
        {
            U64_ZERO, U64_ZERO, U64_ZERO ,U64_ZERO
        };

        /* ----------------------------------------------------------------- */

        unsigned char* cuda_particles_data_buffer = NULL;
        unsigned char* host_particles_data_buffer = NULL;

        NS(block_size_t) const particles_buffer_size =
            NS(Blocks_get_total_num_bytes)( particles_buffer );

        if( particles_buffer_size > 0u )
        {
            err = cudaMalloc( ( void** )&cuda_particles_data_buffer,
                              particles_buffer_size );

            success  = ( err == cudaSuccess );
            success &= ( cuda_particles_data_buffer != NULL );

            host_particles_data_buffer = NS(Blocks_get_data_begin)(
                particles_buffer );

            err = cudaMemcpy(
                cuda_particles_data_buffer, host_particles_data_buffer,
                particles_buffer_size, cudaMemcpyHostToDevice );

            success &= ( err == cudaSuccess );
        }

        /* ----------------------------------------------------------------- */

        unsigned char* cuda_beam_elements_data_buffer = NULL;
        unsigned char* host_beam_elements_data_buffer = NULL;

        NS(block_size_t) const beam_elements_buffer_size =
            NS(Blocks_get_total_num_bytes)( beam_elements );

        if( success )
        {
            if( beam_elements_buffer_size > 0u )
            {
                err = cudaMalloc( ( void** )&cuda_beam_elements_data_buffer,
                                    beam_elements_buffer_size );

                success  = ( err == cudaSuccess );
                success &= ( cuda_beam_elements_data_buffer != NULL );

                host_beam_elements_data_buffer = NS(Blocks_get_data_begin)(
                    beam_elements );

                err = cudaMemcpy( cuda_beam_elements_data_buffer,
                    host_beam_elements_data_buffer, beam_elements_buffer_size,
                    cudaMemcpyHostToDevice );

                success &= ( err == cudaSuccess );
            }
            else
            {
                success = false;
            }
        }

        /* ----------------------------------------------------------------- */

        bool use_elem_by_elem_buffer = false;
        unsigned char* cuda_elem_by_elem_data_buffer = NULL;
        unsigned char* host_elem_by_elem_data_buffer = NULL;

        NS(block_size_t) elem_by_elem_buffer_size =
            ( NS(Blocks_are_serialized)( elem_by_elem_buffer ) )
                ? NS(Blocks_get_total_num_bytes)( elem_by_elem_buffer ) : 0u;

        if( success )
        {
            if( elem_by_elem_buffer_size > 0u )
            {
                use_elem_by_elem_buffer = true;
                host_elem_by_elem_data_buffer = NS(Blocks_get_data_begin)(
                    elem_by_elem_buffer );

                err = cudaMalloc( ( void** )&cuda_elem_by_elem_data_buffer,
                                  elem_by_elem_buffer_size );
            }
            else
            {
                host_elem_by_elem_data_buffer =
                    ( unsigned char* )&dummy_elem_by_elem_header[ 0 ];

                elem_by_elem_buffer_size = 4u * sizeof( uint64_t );

                err = cudaMalloc( ( void** )&cuda_elem_by_elem_data_buffer,
                                  4u * sizeof( uint64_t ) );
            }

            success  = ( err == cudaSuccess );
            success &= ( cuda_elem_by_elem_data_buffer != NULL );
            success &= ( host_elem_by_elem_data_buffer != NULL );
            success &= ( elem_by_elem_buffer_size > 0u );

            use_elem_by_elem_buffer &= success;
        }

        if( success )
        {
            err = cudaMemcpy(
                cuda_elem_by_elem_data_buffer,
                host_elem_by_elem_data_buffer,
                elem_by_elem_buffer_size, cudaMemcpyHostToDevice );

            success = ( err == cudaSuccess );
        }

        int64_t* cuda_success_flag = NULL;
        int64_t  host_success_flag = static_cast< int64_t >( 0 );

        if( success )
        {
            err = cudaMalloc( ( void** )&cuda_success_flag,
                                sizeof( int64_t ) );

            success = ( err == cudaSuccess );
        }

        if( success )
        {
            err = cudaMemcpy( cuda_success_flag, &host_success_flag,
                              sizeof( int64_t ), cudaMemcpyHostToDevice );

            success = ( err == cudaSuccess );
        }

        if( success )
        {
            Track_remap_serialized_blocks_buffer<<<
                num_of_blocks, num_threads_per_block >>>(
                    cuda_particles_data_buffer, cuda_beam_elements_data_buffer,
                    cuda_elem_by_elem_data_buffer, cuda_success_flag );

            err = cudaDeviceSynchronize();
            success  = ( err == cudaSuccess );

            if( success )
            {
                err = cudaMemcpy( &host_success_flag, cuda_success_flag,
                                  sizeof( int64_t ), cudaMemcpyDeviceToHost );
                success  = ( err == cudaSuccess );
                success &= ( host_success_flag == static_cast<int64_t>( 0 ) );
            }
        }

	if ( success )
	{
            Copy_buffer_pyheadtail_sixtracklib<<<
                num_of_blocks, num_threads_per_block >>>(
                    cuda_particles_data_buffer, 
                    x, xp, y, yp, q0, mass0, beta0, gamma0, z, dp, p0c, 
		    cuda_success_flag );

            err = cudaDeviceSynchronize();
            success  = ( err == cudaSuccess );

	}

        if( success )
        {
            Track_particles_kernel_cuda<<< num_of_blocks, num_threads_per_block >>>(
                num_of_turns, cuda_particles_data_buffer,
                cuda_beam_elements_data_buffer, cuda_elem_by_elem_data_buffer,
                cuda_success_flag );

            err = cudaDeviceSynchronize();
            success = ( err == cudaSuccess );
	    if ( success )
	    {
		    Copy_buffer_sixtracklib_pyheadtail<<<
		    num_of_blocks, num_threads_per_block >>>(
                    cuda_particles_data_buffer,
                    x, xp, y, yp, q0, mass0, beta0, gamma0, z, dp, p0c,
		     cuda_success_flag );
            	    err = cudaDeviceSynchronize();
            	    success = ( err == cudaSuccess );
	    }
        }

        err = cudaFree( cuda_success_flag );
        success &= ( err == cudaSuccess );

        err = cudaFree( cuda_elem_by_elem_data_buffer  );
        success &= ( err == cudaSuccess );

        err = cudaFree( cuda_beam_elements_data_buffer );
        success &= ( err == cudaSuccess );

        err = cudaFree( cuda_particles_data_buffer  );
        success &= ( err == cudaSuccess );

    }

    return success;
}

extern __host__ bool NS(Track_particles_on_cuda)(
    int const num_of_blocks,
    int const num_threads_per_block,
    SIXTRL_UINT64_T const num_of_turns,
    NS(Blocks)* SIXTRL_RESTRICT particles_buffer,
    NS(Blocks)* SIXTRL_RESTRICT beam_elements,
    NS(Blocks)* SIXTRL_RESTRICT elem_by_elem_buffer );

bool __host__ NS(Track_particles_on_cuda)(
    int const num_of_blocks,
    int const num_threads_per_block,
    SIXTRL_UINT64_T const num_of_turns,
    NS(Blocks)* SIXTRL_RESTRICT particles_buffer,
    NS(Blocks)* SIXTRL_RESTRICT beam_elements,
    NS(Blocks)* SIXTRL_RESTRICT elem_by_elem_buffer )
{
    bool success = false;

    if( ( NS(Blocks_are_serialized)( particles_buffer ) ) &&
        ( NS(Blocks_are_serialized)( beam_elements ) ) )
    {
        cudaError_t err;

        SIXTRL_STATIC_VAR uint64_t const U64_ZERO =
            static_cast< uint64_t >( 0 );

        uint64_t dummy_elem_by_elem_header[ 4 ] =
        {
            U64_ZERO, U64_ZERO, U64_ZERO ,U64_ZERO
        };

        /* ----------------------------------------------------------------- */

        unsigned char* cuda_particles_data_buffer = NULL;
        unsigned char* host_particles_data_buffer = NULL;

        NS(block_size_t) const particles_buffer_size =
            NS(Blocks_get_total_num_bytes)( particles_buffer );

        if( particles_buffer_size > 0u )
        {
            err = cudaMalloc( ( void** )&cuda_particles_data_buffer,
                              particles_buffer_size );

            success  = ( err == cudaSuccess );
            success &= ( cuda_particles_data_buffer != NULL );

            host_particles_data_buffer = NS(Blocks_get_data_begin)(
                particles_buffer );

            err = cudaMemcpy(
                cuda_particles_data_buffer, host_particles_data_buffer,
                particles_buffer_size, cudaMemcpyHostToDevice );

            success &= ( err == cudaSuccess );
        }

        /* ----------------------------------------------------------------- */

        unsigned char* cuda_beam_elements_data_buffer = NULL;
        unsigned char* host_beam_elements_data_buffer = NULL;

        NS(block_size_t) const beam_elements_buffer_size =
            NS(Blocks_get_total_num_bytes)( beam_elements );

        if( success )
        {
            if( beam_elements_buffer_size > 0u )
            {
                err = cudaMalloc( ( void** )&cuda_beam_elements_data_buffer,
                                    beam_elements_buffer_size );

                success  = ( err == cudaSuccess );
                success &= ( cuda_beam_elements_data_buffer != NULL );

                host_beam_elements_data_buffer = NS(Blocks_get_data_begin)(
                    beam_elements );

                err = cudaMemcpy( cuda_beam_elements_data_buffer,
                    host_beam_elements_data_buffer, beam_elements_buffer_size,
                    cudaMemcpyHostToDevice );

                success &= ( err == cudaSuccess );
            }
            else
            {
                success = false;
            }
        }

        /* ----------------------------------------------------------------- */

        bool use_elem_by_elem_buffer = false;
        unsigned char* cuda_elem_by_elem_data_buffer = NULL;
        unsigned char* host_elem_by_elem_data_buffer = NULL;

        NS(block_size_t) elem_by_elem_buffer_size =
            ( NS(Blocks_are_serialized)( elem_by_elem_buffer ) )
                ? NS(Blocks_get_total_num_bytes)( elem_by_elem_buffer ) : 0u;

        if( success )
        {
            if( elem_by_elem_buffer_size > 0u )
            {
                use_elem_by_elem_buffer = true;
                host_elem_by_elem_data_buffer = NS(Blocks_get_data_begin)(
                    elem_by_elem_buffer );

                err = cudaMalloc( ( void** )&cuda_elem_by_elem_data_buffer,
                                  elem_by_elem_buffer_size );
            }
            else
            {
                host_elem_by_elem_data_buffer =
                    ( unsigned char* )&dummy_elem_by_elem_header[ 0 ];

                elem_by_elem_buffer_size = 4u * sizeof( uint64_t );

                err = cudaMalloc( ( void** )&cuda_elem_by_elem_data_buffer,
                                  4u * sizeof( uint64_t ) );
            }

            success  = ( err == cudaSuccess );
            success &= ( cuda_elem_by_elem_data_buffer != NULL );
            success &= ( host_elem_by_elem_data_buffer != NULL );
            success &= ( elem_by_elem_buffer_size > 0u );

            use_elem_by_elem_buffer &= success;
        }

        if( success )
        {
            err = cudaMemcpy(
                cuda_elem_by_elem_data_buffer,
                host_elem_by_elem_data_buffer,
                elem_by_elem_buffer_size, cudaMemcpyHostToDevice );

            success = ( err == cudaSuccess );
        }

        int64_t* cuda_success_flag = NULL;
        int64_t  host_success_flag = static_cast< int64_t >( 0 );

        if( success )
        {
            err = cudaMalloc( ( void** )&cuda_success_flag,
                                sizeof( int64_t ) );

            success = ( err == cudaSuccess );
        }

        if( success )
        {
            err = cudaMemcpy( cuda_success_flag, &host_success_flag,
                              sizeof( int64_t ), cudaMemcpyHostToDevice );

            success = ( err == cudaSuccess );
        }

        if( success )
        {
            Track_remap_serialized_blocks_buffer<<<
                num_of_blocks, num_threads_per_block >>>(
                    cuda_particles_data_buffer, cuda_beam_elements_data_buffer,
                    cuda_elem_by_elem_data_buffer, cuda_success_flag );

            err = cudaDeviceSynchronize();
            success  = ( err == cudaSuccess );

            if( success )
            {
                err = cudaMemcpy( &host_success_flag, cuda_success_flag,
                                  sizeof( int64_t ), cudaMemcpyDeviceToHost );

                success  = ( err == cudaSuccess );
                success &= ( host_success_flag == static_cast<int64_t>( 0 ) );
            }
        }

        if( success )
        {
            Track_particles_kernel_cuda<<< num_of_blocks, num_threads_per_block >>>(
                num_of_turns, cuda_particles_data_buffer,
                cuda_beam_elements_data_buffer, cuda_elem_by_elem_data_buffer,
                cuda_success_flag );

            err = cudaDeviceSynchronize();
            success = ( err == cudaSuccess );

            if( success )
            {
                err = cudaMemcpy( &host_success_flag, cuda_success_flag,
                                  sizeof( int64_t ), cudaMemcpyDeviceToHost );

                success  = ( err == cudaSuccess );
                success &= ( host_success_flag == U64_ZERO );
            }

            if( success )
            {
                err = cudaMemcpy( host_particles_data_buffer,
                                  cuda_particles_data_buffer,
                                  particles_buffer_size,
                                  cudaMemcpyDeviceToHost );

                success = ( err == cudaSuccess );
            }

            if( ( success ) && ( use_elem_by_elem_buffer ) )
            {
                err = cudaMemcpy( host_elem_by_elem_data_buffer,
                                  cuda_elem_by_elem_data_buffer,
                                  elem_by_elem_buffer_size,
                                  cudaMemcpyDeviceToHost );

                success = ( err == cudaSuccess );
            }
        }

        if( success )
        {
            success = ( 0 == NS(Blocks_unserialize)(
                particles_buffer, host_particles_data_buffer ) );
        }

        if( ( success ) && ( use_elem_by_elem_buffer ) )
        {
            success &= ( 0 == NS(Blocks_unserialize)(
                elem_by_elem_buffer, host_elem_by_elem_data_buffer ) );
        }

        err = cudaFree( cuda_success_flag );
        success &= ( err == cudaSuccess );

        err = cudaFree( cuda_elem_by_elem_data_buffer  );
        success &= ( err == cudaSuccess );

        err = cudaFree( cuda_beam_elements_data_buffer );
        success &= ( err == cudaSuccess );

        err = cudaFree( cuda_particles_data_buffer  );
        success &= ( err == cudaSuccess );
    }

    return success;
}

