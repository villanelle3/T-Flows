!==============================================================================!
  subroutine Multiphase_Mod_Vof_Allocate(mult, flow)
!------------------------------------------------------------------------------!
!   Allocates memory for variables in Multphase_Mod.                           !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Multiphase_Type), target :: mult
  type(Field_Type),      target :: flow
!-----------------------------------[Locals]-----------------------------------!
  type(Grid_Type), pointer :: grid
  integer                  :: nb, nc, nf
!==============================================================================!

  ! Store pointers
  mult % pnt_flow => flow
  mult % pnt_grid => flow % pnt_grid

  ! Take aliases
  grid => flow % pnt_grid
  nb   =  grid % n_bnd_cells
  nc   =  grid % n_cells
  nf   =  grid % n_faces

  call Var_Mod_Allocate_Solution(mult % vof,    grid, 'VOF', '')
  call Var_Mod_Allocate_New_Only(mult % smooth, grid, 'SMO')

  ! Surface curvature
  allocate(mult % curv(-nb:nc));  mult % curv(-nb:nc) = 0.0

  ! Surface normals
  allocate(mult % nx(-nb:nc));  mult % nx(-nb:nc) = 0.0
  allocate(mult % ny(-nb:nc));  mult % ny(-nb:nc) = 0.0
  allocate(mult % nz(-nb:nc));  mult % nz(-nb:nc) = 0.0

  ! Surface tension force
  allocate(mult % surf_fx(-nb:nc));  mult % surf_fx(-nb:nc) = 0.0
  allocate(mult % surf_fy(-nb:nc));  mult % surf_fy(-nb:nc) = 0.0
  allocate(mult % surf_fz(-nb:nc));  mult % surf_fz(-nb:nc) = 0.0

  if(flow % mass_transfer) then
    allocate(mult % qci  (-nb:nc));        mult % qci         (-nb:nc) = 0.0
    allocate(mult % cell_at_elem(-nb:nc)); mult % cell_at_elem(-nb:nc) = 0
    allocate(mult % m_dot(-nb:nc));        mult % m_dot       (-nb:nc) = 0.0
    call Var_Mod_Allocate_New_Only(mult % var, grid, 'PHV')
  end if

  if(mult % track_front) then
    call Front_Mod_Allocate(mult % front, flow)
!f_vs_s    call Surf_Mod_Allocate(mult % surf, flow)
  end if

  ! Physical properties for all (two) phases
  allocate(mult % phase_dens(2))
  allocate(mult % phase_visc(2))
  allocate(mult % phase_capa(2))
  allocate(mult % phase_cond(2))

  end subroutine
