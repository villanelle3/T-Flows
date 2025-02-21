!==============================================================================!
  subroutine Compute_Momentum_Explicit(Process, Flow, ui, Nat)
!------------------------------------------------------------------------------!
!   Explicit computation of momentum equations, used in PISO algorithm,        !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  class(Process_Type)         :: Process
  type(Field_Type),    target :: Flow
  type(Var_Type)              :: ui        ! velocity component
  type(Native_Type),   target :: Nat
!-----------------------------------[Locals]-----------------------------------!
  type(Grid_Type),   pointer :: Grid
  type(Matrix_Type), pointer :: M
  real, contiguous,  pointer :: b(:)
  integer                    :: s, c, c1, c2
  real, contiguous,  pointer :: sum_neigh(:)
!==============================================================================!

  call Profiler % Start('Compute_Momentum_Explicit')

  call Work % Connect_Real_Cell(sum_neigh)

  ! Take aliases
  Grid => Flow % pnt_grid
  M    => Nat % M
  b    => Nat % b % val

  ! PISO corrections are executed here
  if (Flow % p_m_coupling == PISO .and. Flow % inside_piso_loop) then

    ! Sum of neighbours
    sum_neigh(:) = 0.0
    do s = 1, Grid % n_faces
      c1 = Grid % faces_c(1,s)
      c2 = Grid % faces_c(2,s)
      if(Grid % Comm % cell_proc(c1) .eq. this_proc) then
        if(c2 > 0) then
          sum_neigh(c1) = sum_neigh(c1) - M % val(M % pos(1,s)) * ui % n(c2)
          sum_neigh(c2) = sum_neigh(c2) - M % val(M % pos(2,s)) * ui % n(c1)
        end if
      end if
    end do

    ! Solve velocity explicitely (no under relaxation!!)
    do c = 1, Grid % n_cells - Grid % Comm % n_buff_cells
      ui % n(c) = (sum_neigh(c) + b(c)) / M % val(M % dia(c))
    end do

    call Flow % Grad_Variable(ui)

  end if

  call Work % Disconnect_Real_Cell(sum_neigh)

  call Profiler % Stop('Compute_Momentum_Explicit')

  end subroutine
