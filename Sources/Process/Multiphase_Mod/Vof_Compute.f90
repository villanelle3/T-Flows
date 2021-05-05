!==============================================================================!
  subroutine Multiphase_Mod_Vof_Compute(mult, Sol, dt, n)
!------------------------------------------------------------------------------!
!   Solves Volume Fraction equation using UPWIND ADVECTION and CICSAM          !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Multiphase_Type), target :: mult
  type(Solver_Type),     target :: Sol
  real                          :: dt
  integer                       :: n    ! current temporal iteration
!-----------------------------------[Locals]-----------------------------------!
  type(Field_Type),  pointer :: flow
  type(Grid_Type),   pointer :: grid
  type(Var_Type),    pointer :: vof
  type(Face_Type),   pointer :: v_flux
  type(Matrix_Type), pointer :: A
  real, contiguous,  pointer :: b(:)
  real, contiguous,  pointer :: beta_f(:)
  real, contiguous,  pointer :: beta_c(:)
  real, contiguous,  pointer :: c_d(:)
  real                       :: courant_max
  integer                    :: i_sub, n_sub, wrong_vf, n_wrong_vf0, n_wrong_vf1
  integer                    :: s, c, c1, c2, fu, corr
!==============================================================================!

  call Cpu_Timer_Mod_Start('Compute_Multiphase (without solvers)')

  ! Take aliases
  flow   => mult % pnt_flow
  grid   => flow % pnt_grid
  v_flux => flow % v_flux
  vof    => mult % vof
  beta_f => mult % beta_f
  beta_c => mult % beta_c
  c_d    => mult % c_d
  A      => Sol % A
  b      => Sol % b % val

  if(vof % adv_scheme .eq. CICSAM .or. &
     vof % adv_scheme .eq. STACS) then

    if(vof % adv_scheme .eq. CICSAM) then
      ! Compute courant Number close to the interface:
      call Vof_Max_Courant_Number(mult, dt, 1, courant_max)

      n_sub = min(max(ceiling(courant_max / mult % courant_max_param), 1),  &
                  mult % n_sub_param)

      ! Warning if Courant Number is exceeded
      if(n_sub > 1) then
        if(this_proc < 2) then
          call File_Mod_Append_File_For_Writing('alert-dt-vof.dat', fu)
          write(fu,*) 'Courant Number was exceded at iteration: ', n
          write(fu,*) 'Co_max = ', courant_max
          write(fu,*) 'Try reducing time step'
          close(fu)
        end if
      end if
    else
      n_sub = 1
    endif
  else
    ! Old volume fraction:
    vof % o(:) = vof % n(:)
  end if

  if(vof % adv_scheme .eq. UPWIND) then
    !-------------------------!
    !   Matrix Coefficients   !
    !-------------------------!

    call Multiphase_Mod_Vof_Coefficients(mult, A, b, dt)

    ! Solve System
    call Multiphase_Mod_Vof_Solve_System(mult, Sol, b)

    call Grid_Mod_Exchange_Cells_Real(grid, vof % n)

    !-----------------------------!
    !   Correct Volume Fraction   !
    !-----------------------------!

    do c = 1, grid % n_cells
      vof % n(c) = max(min(vof % n(c),1.0),0.0)
    end do

  else if(vof % adv_scheme .eq. CICSAM .or. &
           vof % adv_scheme .eq. STACS) then

    do i_sub = 1, n_sub

      ! Courant number full domain:
      call Vof_Max_Courant_Number(mult, dt / real(n_sub), 0, courant_max)

      !---------------------------!
      !   Predict beta at faces   !
      !---------------------------!

      ! Impose zero gradient at boundaries
      ! call Multiphase_Mod_Vof_Boundary_Extrapolation(grid, mult, vof % n)
      do s = 1, grid % n_faces
        c1 = grid % faces_c(1,s)
        c2 = grid % faces_c(2,s)
        if(c2 < 0) then
          if(Grid_Mod_Bnd_Cond_Type(grid,c2) .ne. INFLOW) then
            vof % n(c2) = vof % n(c1)
          end if
        end if
      end do

      ! Old volume fraction:
      vof % o(:) = vof % n(:)

      ! Compute gradient:
      call Field_Mod_Grad_Variable(flow, vof)

      call Multiphase_Mod_Vof_Predict_Beta(mult)

      do corr = 1, mult % corr_num_max
        !-------------------------!
        !   Matrix coefficients   !
        !-------------------------!

        call Multiphase_Mod_Vof_Coefficients(mult, A, b, dt / real(n_sub))

        ! Solve System
        call Multiphase_Mod_Vof_Solve_System(mult, Sol, b)

        do s = 1, grid % n_faces
          c1 = grid % faces_c(1,s)
          c2 = grid % faces_c(2,s)
          if(c2 < 0) then
            if(Grid_Mod_Bnd_Cond_Type(grid,c2) .ne. INFLOW) then
              vof % n(c2) = vof % n(c1)
            end if
          end if
        end do

        n_wrong_vf0 = 0
        n_wrong_vf1 = 0
        wrong_vf = 0

        ! Determine if 0 <= vof <= 1.0
        do c = 1, grid % n_cells
          if(vof % n(c) < -vof % tol) then
            n_wrong_vf0 = n_wrong_vf0 + 1
          end if

          if(vof % n(c) - 1.0 > vof % tol) then
            n_wrong_vf1 = n_wrong_vf1 + 1
          end if
        end do

        call Grid_Mod_Exchange_Cells_Real(grid, vof % n)

        !---------------------------!
        !   Correct beta at faces   !
        !---------------------------!

        if(n_wrong_vf0 > 0 .or. n_wrong_vf1 > 0) then
          wrong_vf = 1
        end if

        call Comm_Mod_Global_Sum_Int(wrong_vf)

        if(wrong_vf == 0) then
          goto 1
        else
          call Multiphase_Mod_Vof_Correct_Beta(mult)
        end if

      end do
1     continue

      !------------------------!
      !   Correct boundaries   !
      !------------------------!
      do s = 1, grid % n_faces
        c1 = grid % faces_c(1,s)
        c2 = grid % faces_c(2,s)

        if(c2 < 0) then
          if(Grid_Mod_Bnd_Cond_Type(grid, c2) .ne. INFLOW) then
            if(vof % n(c2) < FEMTO) then
               vof % n(c2) = 0.0
            end if
            if(vof % n(c2) - 1.0 >= FEMTO) then
               vof % n(c2) = 1.0
            end if
          end if
        end if

      end do

      !--------------------------------------!
      !   Correct Interior Volume Fraction   !
      !--------------------------------------!
      do c = 1, grid % n_cells
        if(vof % n(c) < FEMTO) then
          vof % n(c) = 0.0
        end if
        if(vof % n(c) - 1.0 >= FEMTO) then
          vof % n(c) = 1.0
        end if
      end do

      call Grid_Mod_Exchange_Cells_Real(grid, vof % n)
    end do


  end if

  !------------------------------!
  !   Volume fraction at faces   !
  !------------------------------!

  if(vof % adv_scheme .eq. UPWIND) then

    ! At boundaries
    do s = 1, grid % n_faces
      c1 = grid % faces_c(1,s)
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(Grid_Mod_Bnd_Cond_Type(grid,c2) .ne. INFLOW) then
          vof % n(c2) = vof % n(c1)
        end if
      end if
    end do

  else if(vof % adv_scheme .eq. CICSAM .or. vof % adv_scheme .eq. STACS) then

    ! call Multiphase_Mod_Vof_Boundary_Extrapolation(grid, mult, vof % n)
    ! At boundaries
    do s = 1, grid % n_faces
      c1 = grid % faces_c(1,s)
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(Grid_Mod_Bnd_Cond_Type(grid,c2) .eq. OUTFLOW) then
          vof % n(c2) = vof % n(c1)
        else if(Grid_Mod_Bnd_Cond_Type(grid,c2) .eq. OPENBC) then
          vof % n(c2) = vof % n(c1)
        else if(Grid_Mod_Bnd_Cond_Type(grid,c2) .eq. INFLOW) then
        else
          vof % n(c2) = vof % n(c1)
        end if
      end if
    end do

  end if

  call Field_Mod_Grad_Variable(flow, vof)

  !----------------------------------------!
  !   Surface Tension Force Contribution   !
  !----------------------------------------!

  if(mult % surface_tension > TINY) then
    call Multiphase_Mod_Vof_Surface_Tension_Contribution_Csf(mult)
  end if

  !-----------------------!
  !   Update properties   !
  !-----------------------!
  call Multiphase_Mod_Vof_Physical_Properties(mult)

  call Cpu_Timer_Mod_Stop('Compute_Multiphase (without solvers)')

  end subroutine
