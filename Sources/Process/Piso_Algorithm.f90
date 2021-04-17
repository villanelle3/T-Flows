!==============================================================================!
  subroutine Piso_Algorithm(flow, turb, mult, sol, ini)
!------------------------------------------------------------------------------!
!   PISO algorithm                                                             !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use Multiphase_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Field_Type),      target :: flow
  type(Turb_Type),       target :: turb
  type(Multiphase_Type), target :: mult
  type(Solver_Type),     target :: sol
  integer                       :: ini       ! current inner iteration
!-----------------------------------[Locals]-----------------------------------!
  type(Grid_Type), pointer :: grid
  type(Var_Type),  pointer :: u, v, w
  integer                  :: corr_steps
!==============================================================================!

  ! Take aliases
  grid => flow % pnt_grid
  call Field_Mod_Alias_Momentum(flow, u, v, w)

  if (flow % p_m_coupling == PISO) then

    flow % piso_status = .true.
    do corr_steps = 1, flow % n_piso_corrections
      flow % i_corr = corr_steps
      call Field_Mod_Grad_Pressure(flow, flow % p)

      ! All velocity components one after another
      call Compute_Momentum(flow, turb, mult, sol, ini)

      call Compute_Pressure(flow, mult, sol, ini)

      call Correct_Velocity(flow, turb, mult, sol, ini)
    end do

    flow % piso_status = .false.
    call Info_Mod_Iter_Fill_At(1, 1, u % name, u % eniter, u % res)
    call Info_Mod_Iter_Fill_At(1, 2, v % name, v % eniter, v % res)
    call Info_Mod_Iter_Fill_At(1, 3, w % name, w % eniter, w % res)
    flow % i_corr = 1

  end if

  end subroutine
