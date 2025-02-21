!==============================================================================!
  subroutine User_Mod_End_Of_Time_Step(Flow, Turb, Vof, Swarm,  &
                                       n, n_stat_t, n_stat_p, time)
!------------------------------------------------------------------------------!
!   This function is called at the end of time step.                           !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Field_Type),    target :: Flow
  type(Turb_Type),     target :: Turb
  type(Vof_Type),      target :: Vof
  type(Swarm_Type),    target :: Swarm
  integer, intent(in)         :: n         ! time step
  integer, intent(in)         :: n_stat_t  ! start time step for Turb. stat.
  integer, intent(in)         :: n_stat_p  ! start time step for Swarm. stat.
  real,    intent(in)         :: time      ! physical time
!-----------------------------------[Locals]-----------------------------------!
  type(Grid_Type), pointer :: Grid
  type(Var_Type),  pointer :: t
  integer                  :: c1, c2, s
  real                     :: nu, area
!==============================================================================!

  ! Take aliases
  Grid => Flow % pnt_grid

  call Flow % Alias_Energy(t)

  !------------------------------------!
  !   Compute average Nusselt number   !
  !------------------------------------!
  if(Grid % name(1:6) .eq. 'FLUID') then

    ! Initialize variables for computing average Nusselt number
    nu   = 0.0
    area = 0.0

    do s = 1, Grid % n_faces
      c1 = Grid % faces_c(1,s)
      c2 = Grid % faces_c(2,s)

      if(c2 < 0 .and. Grid % Comm % cell_proc(c1) .eq. this_proc) then

        if( Var_Mod_Bnd_Cond_Type(t,c2) .eq. WALL ) then
          area = area + Grid % s(s)
          nu   = nu + Grid % s(s)                 &
                    * abs(t % n(c2) - t % n(c1))  &
                    / Grid % d(s)
        end if  ! if wall
      end if    ! c2 < 0
    end do      ! through s

    !-----------------------------------------------!
    !   Integrate (summ) heated area, and heat up   !
    !-----------------------------------------------!
    call Comm_Mod_Global_Sum_Real(area)
    call Comm_Mod_Global_Sum_Real(nu)

    !-------------------------------------------------!
    !   Compute averaged Nussel number and print it   !
    !-------------------------------------------------!
    nu = nu / area

    if(this_proc < 2) then
      print '(a)',        ' #==========================================='
      print '(a)',        ' # Output from user function, Nusslet number!'
      print '(a)',        ' #-------------------------------------------'
      print '(a,es12.4)', ' # Toral  area    : ', area
      print '(a,es12.4)', ' # Nusselt number : ', nu
    end if

  end if  ! domain is middle

  end subroutine
