!==============================================================================!
  subroutine User_Mod_Beginning_Of_Correct_Velocity(flow, mult, sol,  &
                                                    curr_dt, ini)
!------------------------------------------------------------------------------!
!   This function is called at the beginning of Correct_Velocity function.     !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Field_Type),      target :: flow
  type(Multiphase_Type), target :: mult
  type(Solver_Type),     target :: sol
  integer, intent(in)           :: curr_dt
  integer, intent(in)           :: ini
!==============================================================================!

  end subroutine
