!==============================================================================!
  subroutine Control_Mod_Load_Initial_Solution_Name(val, verbose)
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  character(SL)     :: val
  logical, optional :: verbose
!==============================================================================!

  call Control_Mod_Read_Char_Item('LOAD_INITIAL_SOLUTION_NAME', 'skip',  &
                                   val, verbose)

  end subroutine
