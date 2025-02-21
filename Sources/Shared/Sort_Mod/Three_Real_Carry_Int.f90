!==============================================================================!
  pure recursive subroutine Three_Real_Carry_Int(Sort, a1, a2, a3, b)
!------------------------------------------------------------------------------!
!   Quick sort three real arrays (think of three coordinates) and carry one    !
!   integer arral along                                                        !
!                                                                              !
!   Adapted from: https://gist.github.com/1AdAstra1  (good work Olga)          !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  class(Sort_Type), intent(in)    :: Sort
  real,             intent(inout) :: a1(:), a2(:), a3(:)
  integer,          intent(inout) :: b(:)
!-----------------------------------[Locals]-----------------------------------!
  real    :: x1, x2, x3
  integer :: i, j, n
!==============================================================================!

  n = size(a1, 1)
  x1 = a1( (1+n) / 2 )
  x2 = a2( (1+n) / 2 )
  x3 = a3( (1+n) / 2 )
  i = 1
  j = n

  do
    do while ( Math % Smaller_Real(a1(i),x1)  .or.   &
               Math % Approx_Real (a1(i),x1)  .and.  &
               Math % Smaller_Real(a2(i),x2)  .or.   &
               Math % Approx_Real (a1(i),x1)  .and.  &
               Math % Approx_Real (a2(i),x2)  .and.  &
               Math % Smaller_Real(a3(i),x3)  )
      i = i + 1
    end do
    do while ( Math % Smaller_Real(x1,a1(j))  .or.   &
               Math % Approx_Real (x1,a1(j))  .and.  &
               Math % Smaller_Real(x2,a2(j))  .or.   &
               Math % Approx_Real (x1,a1(j))  .and.  &
               Math % Approx_Real (x2,a2(j))  .and.  &
               Math % Smaller_Real(x3,a3(j))  )
      j = j - 1
    end do
    if(i >= j) exit

    ! Swap values in a and b
    call Swap_Real(a1(i), a1(j))
    call Swap_Real(a2(i), a2(j))
    call Swap_Real(a3(i), a3(j))
    call Swap_Int (b (i), b (j))

    i = i + 1
    j = j - 1
  end do

  if(1 < i - 1) call Sort % Three_Real_Carry_Int(a1(1:i-1),  &
                                                 a2(1:i-1),  &
                                                 a3(1:i-1),  &
                                                 b (1:i-1))
  if(j + 1 < n) call Sort % Three_Real_Carry_Int(a1(j+1:n),  &
                                                 a2(j+1:n),  &
                                                 a3(j+1:n),  &
                                                 b (j+1:n))

  end subroutine
