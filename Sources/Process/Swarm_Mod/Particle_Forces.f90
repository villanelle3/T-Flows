!==============================================================================!
  subroutine Swarm_Mod_Particle_Forces(swarm, k)
!------------------------------------------------------------------------------!
!                 Computes the forces exerted on the particle                  !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Swarm_Type), target :: swarm
  integer                  :: k     ! particle number
!-----------------------------------[Locals]-----------------------------------!
  type(Field_Type),    pointer :: flow
  type(Particle_Type), pointer :: part
  real                         :: fb      ! buoyant force
  real                         :: fd      ! drag force
  real                         :: ft      ! total force acting on the particle
  real                         :: cd      ! drag coefficient
  integer                      :: n_part  ! particle(s) number
!==============================================================================!

  ! Take aliases
  flow => swarm % pnt_flow
  part => swarm % particle(k)

  ! Particle surface area (Spherical particle)
  part % area =  PI * (part % d **2)

  ! Particle volume
   part % vol = ONE_SIXTH * PI * (part % d **3)

  !----------------------------------------------------!
  !  Compute the buoyancy force (acting in +ve y-dir)  !
  !----------------------------------------------------!

  ! if the particle is lighter than the fluid (i.e. fb is +ve)...
  ! ...then both buoyancy and drag forces will act on the particle...
  ! ...in the same direction (upwards), and in this case the particle...
  ! ...will be moving upwards as well. Otherwise fb will be -ve and it...
  ! ...will be deducted from the total force.

  part % fb = (density - part % density) * EARTH_G * part % vol

  ! Compute drag coefficient
  if (part % re .ge. 1000.0) then
    cd = 0.43
  else
    cd = 24.0 / part % re * (part % f)
  end if

  !-----------------------------------------------------------------!
  !  Compute the drag force (acting in particle counter direction)  !
  !-----------------------------------------------------------------!
  part % fd = .5 * cd * density * part % area  * part % rel_vvn * part % rel_vv

  !---------------------------!
  !  Compute the total force  !
  !---------------------------!
  part%ft = part%fb + part%fd

  ! The forces below are meant to be EXERTED on the particle
  !  Print *, 'particle drag force    = ', part % fd
  !  Print *, 'particle buoyant force = ', part % fb
  !  Print *, 'particle total force   = ', part % ft
  !  print *,  ""

  if (part % fb .ge. 0.0) then
    if (part % fb .ge. part % fd) then
       Print *, 'Particle is moving upwards!'
    end if
  end if

end subroutine
