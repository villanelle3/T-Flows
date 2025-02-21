!==============================================================================!
  real function Schmidt_Numb(Flow, c)
!------------------------------------------------------------------------------!
!   Computes laminar Schmidt number for cell "c"                               !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  class(Field_Type), target :: Flow
  integer                   :: c
!==============================================================================!

  Schmidt_Numb =  Flow % viscosity(c)  &
               / (Flow % diffusivity * Flow % density(c))

  end function
