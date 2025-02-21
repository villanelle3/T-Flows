!==============================================================================!
  logical function Gen_Mod_Are_Nodes_Twins(n1, n2)
!------------------------------------------------------------------------------!
!   Checks if the nodes are twins, i.e. are they shared on periodicity         !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  integer :: n1, n2
!-----------------------------------[Locals]-----------------------------------!
  integer :: n, check
!==============================================================================!

  check = 0

  do n=1,twin_n(n1,0)
    if(twin_n(n1,n) .eq. n2) check = check + 1
  end do

  do n=1,twin_n(n2,0)
    if(twin_n(n2,n) .eq. n1) check = check + 1
  end do

  if(check .eq. 2) then
    Gen_Mod_Are_Nodes_Twins = .true.
    return
  else if(check .eq. 0) then
    Gen_Mod_Are_Nodes_Twins = .false.
    return
  else
    print *, '# ERROR in Are_Nodes_Twins!  Major trouble !  Stopping !'
    stop
  end if

  end function
