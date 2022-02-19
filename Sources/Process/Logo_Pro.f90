!==============================================================================!
  subroutine Logo_Pro()
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use Const_Mod
  use Solver_Mod, only: PETSC_ACTIVE
!---------------------------------[Arguments]----------------------------------!
!==============================================================================!

  print *,'#===================================' // &
          '===================================='
  print *,'#                                                                   '
  print *,'#    ______________________ ____    ________  __      __  _________ '
  print *,'#    \__    ___/\_   _____/|    |   \_____  \/  \    /  \/   _____/ '
  print *,'#      |    |    |    __)  |    |    /   |   \   \/\/   /\_____  \  '
  print *,'#      |    |    |     \   |    |___/    |    \        / /        \ '
  print *,'#      |____|    \___  /   |_______ \_______  /\__/\  / /_______  / '
  print *,'#                    \/            \/       \/      \/          \/  '
  print *,'#                      ___                                          '
  print *,'#                     / _ \_______  _______ ___ ___                 '
  print *,'#                    / ___/ __/ _ \/ __/ -_|_-<(_-<                 '
  print *,'#                   /_/  /_/  \___/\__/\__/___/___/                 '
  print *,'#                                                                   '
  if(RP .eq. DP) then
  print *,'#                        Double precision mode'
  else
  print *,'#                        Single precision mode'
  end if
  if(PETSC_ACTIVE) then
  print *,'#                     Compiled with PETSc solvers'
  else
  print *,'#                    Only native solvers available'
  end if
  print *,'#-----------------------------------' // &
          '------------------------------------'

  end subroutine
