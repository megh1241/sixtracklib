#if !defined( SIXTRL_NO_INCLUDES )
    #include "sixtracklib/cuda/impl/track_particles_kernel.cuh"
#endif /* !defined( SIXTRL_NO_INCLUDES ) */

#if !defined( SIXTRL_NO_SYSTEM_INCLUDES )
    #include <stdio.h>
    #include <cuda.h>
#endif /* !defined( SIXTRL_NO_SYSTEM_INCLUDES ) */

#if !defined( SIXTRL_NO_INCLUDES )
    #include "sixtracklib/_impl/definitions.h"
    #include "sixtracklib/common/blocks.h"
    #include "sixtracklib/common/particles.h"
    #include "sixtracklib/common/pyheadtail_particles.h"
    #include "sixtracklib/common/beam_elements.h"
    #include "sixtracklib/common/impl/faddeeva.h"
    #include "sixtracklib/common/impl/beam_beam_element_6d.h"
    #include "sixtracklib/common/track.h"
#endif /* !defined( SIXTRL_NO_INCLUDES ) */

__global__ void Copy_buffer_pyheadtail_sixtracklib(
    unsigned char* __restrict__ particles_data_buffer,
    double*  __restrict__ x,
    double*  __restrict__ xp,
    double*  __restrict__ y,
    double*  __restrict__ yp,
    double*  __restrict__ q0,
    double*  __restrict__ mass0,
    double*  __restrict__ beta0,
    double*  __restrict__ gamma0,
    double*  __restrict__ z,
    double*  __restrict__ dp,
    double*  __restrict__ p0c,
    int64_t*       __restrict__ ptr_success_flag
){
	
	NS(Blocks) particles_buffer;
	NS(Blocks_preset)( &particles_buffer );
	NS(Blocks_unserialize_without_remapping)( &particles_buffer, particles_data_buffer );

	NS(BlockInfo)* ptr_info  = NS(Blocks_get_block_infos_begin)( &particles_buffer );
	NS(Particles)* particles = NS(Blocks_get_particles)( ptr_info );
	size_t num_of_particles  = NS(Particles_get_num_particles)( particles );

	memcpy( NS(Particles_get_x)( particles ),
             x,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_px)( particles ),
             xp,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_y)( particles ),
             y,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_py)( particles ),
             yp,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_q0)( particles ),
             q0,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_mass0)( particles ),
             mass0,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_beta0)( particles ),
             beta0,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_gamma0)( particles ),
             gamma0,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_sigma)( particles ),
             z,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_delta)( particles ),
             dp,
             num_of_particles * sizeof( double )
             );
	memcpy( NS(Particles_get_p0c)( particles ),
             p0c,
             num_of_particles * sizeof( double )
             );
}


__global__ void Copy_buffer_sixtracklib_pyheadtail(
    unsigned char* __restrict__ particles_data_buffer,
    double*  __restrict__ x,
    double*  __restrict__ xp,
    double*  __restrict__ y,
    double*  __restrict__ yp,
    double*  __restrict__ q0,
    double*  __restrict__ mass0,
    double*  __restrict__ beta0,
    double*  __restrict__ gamma0,
    double*  __restrict__ z,
    double*  __restrict__ dp,
    double*  __restrict__ p0c,
    int64_t*       __restrict__ ptr_success_flag
){
	NS(Blocks) particles_buffer;
	NS(Blocks_preset)( &particles_buffer );
	NS(Blocks_unserialize_without_remapping)( &particles_buffer, particles_data_buffer );

	NS(BlockInfo)* ptr_info  = NS(Blocks_get_block_infos_begin)( &particles_buffer );
	NS(Particles)* particles = NS(Blocks_get_particles)( ptr_info );
	size_t num_of_particles  = NS(Particles_get_num_particles)( particles );

	memcpy(x, NS(Particles_get_const_x)( particles ),
             num_of_particles * sizeof( double )
             );
	memcpy(xp, NS(Particles_get_const_px)( particles ),
             num_of_particles * sizeof( double )
             );
	memcpy(y, NS(Particles_get_const_y)( particles ),
             num_of_particles * sizeof( double )
             );
	memcpy(yp, NS(Particles_get_const_py)( particles ),
             num_of_particles * sizeof( double )
             );
	memcpy(q0, NS(Particles_get_const_q0)( particles ),
             num_of_particles * sizeof( double )
             );
	memcpy(mass0, NS(Particles_get_const_mass0)( particles ),
             num_of_particles * sizeof( double )
             );
	memcpy(beta0, NS(Particles_get_const_beta0)( particles ),
             num_of_particles * sizeof( double )
             );
	memcpy(gamma0, NS(Particles_get_const_gamma0)( particles ),
             num_of_particles * sizeof( double )
             );
	memcpy(z, NS(Particles_get_const_sigma)( particles ),
             num_of_particles * sizeof( double )
             );
}



__global__ void Track_remap_serialized_blocks_buffer(
    unsigned char* __restrict__ particles_data_buffer,
    unsigned char* __restrict__ beam_elements_data_buffer,
    unsigned char* __restrict__ elem_by_elem_data_buffer,
    int64_t*       __restrict__ ptr_success_flag )
{
    int const global_id = blockIdx.x * blockDim.x + threadIdx.x;
    int const total_num_threads = blockDim.x * gridDim.x;

    int const gid_to_remap_particles     = 0;

    int const gid_to_remap_beam_elements = ( total_num_threads > 1 )
        ? 1 : gid_to_remap_particles;

    int const gid_to_remap_elem_by_elem  = ( total_num_threads > 2 )
        ? 2 : gid_to_remap_beam_elements;

    int64_t success_flag = 0;

    if( global_id <= gid_to_remap_elem_by_elem )
    {
        if( global_id == gid_to_remap_particles )
        {
            NS(Blocks) particles_buffer;
            NS(Blocks_preset)( &particles_buffer );

            if( 0 != NS(Blocks_unserialize)( &particles_buffer,
                        particles_data_buffer ) )
            {
                success_flag |= -1;
            }
        }

        if( ( success_flag == 0 ) &&
            ( global_id == gid_to_remap_beam_elements ) )
        {
            NS(Blocks) beam_elements;
            NS(Blocks_preset)( &beam_elements );

            if( 0 != NS(Blocks_unserialize)( &beam_elements,
                        beam_elements_data_buffer ) )
            {
                success_flag = -2;
            }
        }

        if( ( success_flag == 0 ) &&
            ( global_id == gid_to_remap_elem_by_elem ) )
        {
            uint64_t const* header = reinterpret_cast< uint64_t const* >(
                elem_by_elem_data_buffer );

            if( ( header != 0 ) && ( header[ 0 ] != 0u ) )
            {
                NS(Blocks) elem_by_elem_buffer;
                NS(Blocks_preset)( &elem_by_elem_buffer );

                if( 0 != NS(Blocks_unserialize)(
                        &elem_by_elem_buffer, elem_by_elem_data_buffer ) )
                {
                    success_flag = -4;
                }
            }
        }
    }

    if( ( success_flag != 0 ) && ( ptr_success_flag != NULL ) )
    {
        *ptr_success_flag |= success_flag;
    }

    return;
}

__global__ void Track_particles_kernel_cuda(
    SIXTRL_UINT64_T const num_of_turns,
    unsigned char* __restrict__ particles_data_buffer,
    unsigned char* __restrict__ beam_elements_data_buffer,
    unsigned char* __restrict__ elem_by_elem_data_buffer,
    int64_t*       __restrict__ ptr_success_flag )
{
    int const global_id = blockIdx.x * blockDim.x + threadIdx.x;

    SIXTRL_STATIC_VAR uint64_t const U64_ZERO = static_cast< uint64_t >( 0 );

    NS(block_size_t) num_particle_blocks              = 0u;
    NS(block_size_t) num_beam_elements                = 0u;
    NS(block_size_t) num_elem_by_elem_blocks          = 0u;
    NS(block_size_t) num_elem_by_elem_blocks_per_turn = 0u;
    NS(block_size_t) num_required_elem_by_elem_blocks = 0u;
    NS(block_size_t) num_of_particles                 = 0u;

    NS(Blocks) particles_buffer;
    NS(Blocks) beam_elements;
    NS(Blocks) elem_by_elem_buffer;

    NS(Particles)* particles = NULL;

    int64_t success_flag = 0;
    bool use_elem_by_elem_buffer = false;

    NS(Blocks_preset)( &particles_buffer );

    if( 0 == NS(Blocks_unserialize_without_remapping)(
            &particles_buffer, particles_data_buffer ) )
    {
        num_particle_blocks =
            NS(Blocks_get_num_of_blocks)( &particles_buffer );

        if( num_particle_blocks == 1u )
        {
            NS(BlockInfo)* ptr_info =
                NS(Blocks_get_block_infos_begin)( &particles_buffer );

            particles = NS(Blocks_get_particles)( ptr_info );
            num_of_particles = NS(Particles_get_num_particles)( particles );
        }
    }

    if( ( particles == NULL ) || ( num_of_particles == 0u ) )
    {
        NS(Blocks_preset)( &particles_buffer );
        particles = NULL;
        success_flag |= -1;
    }

    NS(Blocks_preset)( &beam_elements );

    if( 0 == NS(Blocks_unserialize_without_remapping)(
        &beam_elements, beam_elements_data_buffer ) )
    {
        num_beam_elements = NS(Blocks_get_num_of_blocks)( &beam_elements );
    }

    if( num_beam_elements == 0u )
    {
        NS(Blocks_preset)( &beam_elements );
        success_flag |= -2;
    }

    if( elem_by_elem_data_buffer != NULL )
    {
        uint64_t const* elem_by_elem_header =
            reinterpret_cast< uint64_t const* >( elem_by_elem_data_buffer );

        num_elem_by_elem_blocks_per_turn =
            num_beam_elements * num_particle_blocks;

        num_required_elem_by_elem_blocks =
            num_of_turns * num_elem_by_elem_blocks_per_turn;

        NS(Blocks_preset)( &elem_by_elem_buffer );

        if( 0 == NS(Blocks_unserialize_without_remapping)(
            &elem_by_elem_buffer, elem_by_elem_data_buffer ) )
        {
            num_elem_by_elem_blocks =
                NS(Blocks_get_num_of_blocks)( &elem_by_elem_buffer );

            if( ( num_required_elem_by_elem_blocks > 0u ) &&
                ( num_elem_by_elem_blocks >=
                    num_required_elem_by_elem_blocks ) )
            {
                use_elem_by_elem_buffer = true;
            }
            else if( num_elem_by_elem_blocks == 0u )
            {
                NS(Blocks_preset)( &elem_by_elem_buffer );
                success_flag |= -4;
            }
        }
        else if( elem_by_elem_header[ 0 ] != U64_ZERO )
        {
            NS(Blocks_preset)( &elem_by_elem_buffer );
            success_flag |= -4;
        }
    }

    if( ( success_flag        == 0  ) && ( num_of_turns        != 0u ) &&
        ( num_beam_elements   != 0u ) && ( num_particle_blocks == 1u ) )
    {
        int ret = 0;
        int const stride = blockDim.x * gridDim.x;

        if( !use_elem_by_elem_buffer )
        {
            for( uint64_t ii = 0u ; ii < num_of_turns ; ++ii )
            {
                for( int jj = global_id; jj < num_of_particles ; jj += stride )
                {
                    ret |= NS(Track_beam_elements_particle)(
                        particles, jj, &beam_elements, NULL );
                }
            }

            if( ret != 0 ) success_flag |= -8;
        }
        else
        {
            NS(BlockInfo)* io_block_it =
                NS(Blocks_get_block_infos_begin)( &elem_by_elem_buffer );

            for( uint64_t ii = 0u ; ii < num_of_turns ; ++ii,
                io_block_it = io_block_it + num_beam_elements )
            {
                for( int jj = global_id; jj < num_of_particles ; jj += stride )
                {
                    ret |= NS(Track_beam_elements_particle)(
                        particles, jj, &beam_elements, io_block_it );
                }
            }

            if( ret != 0 ) success_flag |= -16;
        }
    }
    else
    {
        success_flag |= -32;
    }

    if( ( success_flag != 0 ) && ( ptr_success_flag != NULL ) )
    {
        *ptr_success_flag |= success_flag;
    }

    return;
}

/* end sixtracklib/cuda/track_particles_kernel.cu */
