!==============================================================================!
  subroutine Calculate_Geometry(grid)
!------------------------------------------------------------------------------!
!   Calculates geometrical quantities of the grid.                             !
!------------------------------------------------------------------------------!
!----------------------------------[Modules]-----------------------------------!
  use Grid_Mod
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  type(Grid_Type) :: grid
!-----------------------------------[Locals]-----------------------------------!
  integer              :: c, c1, c2, n, s, ss, cc2, c_max, nnn, hh, mm, b
  integer              :: c11, c12, c21, c22, s1, s2, bou_cen, cnt_bnd, cnt_per
  integer              :: color_per, n_per, number_faces, option
  integer              :: rot_dir, n1, n2, i_nod, j_nod
  logical              :: per_x, per_y, per_z
  real                 :: xt(MAX_FACES_N_NODES),  &
                          yt(MAX_FACES_N_NODES),  &
                          zt(MAX_FACES_N_NODES)
  real                 :: xs2, ys2, zs2, x_a, y_a, z_a, x_b, y_b, z_b
  real                 :: x_cell_1, y_cell_1, z_cell_1, dv_1
  real                 :: x_cell_2, y_cell_2, z_cell_2, dv_2
  real                 :: x_c, y_c, z_c, det, angle_face, tol
  real                 :: ab_i, ab_j, ab_k, ac_i, ac_j, ac_k, p_i, p_j, p_k
  real                 :: per_min, per_max, t, sur_tot, angle, max_dis
  real,    allocatable :: xspr(:), yspr(:), zspr(:)
  real,    allocatable :: b_coor(:), phi_face(:)
  integer, allocatable :: b_face(:), face_copy(:)
  character(SL)        :: answer, dir
  real                 :: big, small, factor, prod
!==============================================================================!
!                                                                              !
!                                n3                                            !
!                 +---------------!---------------+                            !
!                /|              /|              /|                            !
!               / |             / |             / |                            !
!              /  |          n2/  |            /  |                            !
!             +---------------!---------------+   |                            !
!             |   |           |   |           |   |                            !
!             |   |     o---- | s-------o     |   |                            !
!             |   +---- c1 ---|   !---- c2 ---|   +                            !
!             |  /            |  /n4          |  /                             !
!             | /             | /             | /                              !
!             |/              |/              |/                               !
!             +---------------!---------------+                                !
!                            n1                                                !
!                                                                              !
!   Notes:                                                                     !
!                                                                              !
!     ! face s is oriented from cell center c1 to cell center c2               !
!     ! c2 is greater then c1 inside the domain or smaller then 0              !
!       on the boundary                                                        !
!     ! nodes are denoted with n1 - n4                                         !
!                                                                              !
!            c3                                                                !
!             \  4-----3                                                       !
!              \/ \  . |                                                       !
!              /   \  +---c2                                                   !
!             /  .  \  |                                                       !
!            / .     \ |                                                       !
!           /.        \|                                                       !
!          1-----------2                                                       !
!                   |                                                          !
!                   c1                                                         !
!                                                                              !
!                                n3                                            !
!                 +---------------!-------+                                    !
!                /|            n2/|      /|                                    !
!               / |             !-------+ |                                    !
!              /  |            /|s|  c2 | |                                    !
!             +---------------+ | !-----| +                                    !
!             |   |           | |/n4    |/                                     !
!             |   |     c1    | !-------+                                      !
!             |   +-----------|n1 +                                            !
!             |  /            |  /                                             !
!             | /             | /                                              !
!             |/              |/                                               !
!             +---------------+                                                !
!                            n1                                                !
!                                                                              !
!------------------------------------------------------------------------------!
!   Generaly:                                                                  !
!                                                                              !
!   the equation of plane reads: A * x + B * y + C * z + D = 0                 !
!                                                                              !
!   and the equation of line:  x = x0 + t*rx                                   !
!                              y = y0 + t*ry                                   !
!                              z = z0 + t*rz                                   !
!- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -       !
!   In our case:                                                               !
!                                                                              !
!     line is a connection between the two cell centers:                       !
!                                                                              !
!     x = xc(c1) + t*(xc(c2)-xc(c1)) = xc(c1) + t*rx                           !
!     y = yc(c1) + t*(yc(c2)-yc(c1)) = yc(c1) + t*ry                           !
!     z = zc(c1) + t*(zc(c2)-zc(c1)) = zc(c1) + t*rz                           !
!                                                                              !
!                                                                              !
!     plane is a cell face:                                                    !
!                                                                              !
!     sx * x + sy * y + Sz * z = sx * xsp(s) + sy * ysp(s) + sz * zsp(s)       !
!                                                                              !
!     and the intersection is at:                                              !
!                                                                              !
!         sx*(xsp(s)-xc(c1)) + sy*(ysp(s)-yc(c1) + sz*(zsp(s)-zc(c1))          !
!     t = -----------------------------------------------------------          !
!                           rx*sx + ry*sy + rz*sz                              !
!                                                                              !
!==============================================================================!

  !-------------------------------!
  !   Scale geometry              !
  !-------------------------------!
  !   => depends on: xn, yn, zn   !
  !   <= gives:      xn, yn, zn   !
  !-------------------------------!
  print *, '#========================================='
  print *, '# Geometric extents:                 '
  print *, '#-----------------------------------------'
  print '(2(a,es10.3))', ' # X from: ', minval(grid % xn(:)),  &
                         '  to: ',      maxval(grid % xn(:))
  print '(2(a,es10.3))', ' # Y from: ', minval(grid % yn(:)),  &
                         '  to: ',      maxval(grid % yn(:))
  print '(2(a,es10.3))', ' # Z from: ', minval(grid % zn(:)),  &
                         '  to: ',      maxval(grid % zn(:))
  print *, '# Enter scaling factor for geometry: '
  print *, '# (or skip to keep as is): '
  print *, '#-----------------------------------------'
  call File_Mod_Read_Line(5)
  answer = line % tokens(1)
  call To_Upper_Case(answer)

  if( answer .ne. 'SKIP' ) then
    read(line % tokens(1), *) factor
    print '(a,es10.3)', ' # Scaling geometry by factor: ', factor
    grid % xn(:) = grid % xn(:) * factor
    grid % yn(:) = grid % yn(:) * factor
    grid % zn(:) = grid % zn(:) * factor
  end if


  ! Estimate big and small
  call Grid_Mod_Estimate_Big_And_Small(grid, big, small)

  !-----------------------------------------!
  !   Calculate the cell centers            !
  !-----------------------------------------!
  !   => depends on: xn, yn, zn             !
  !   <= gives:      xc, yc, zc @ c > 0     !
  !-----------------------------------------!
  call Grid_Mod_Calculate_Cell_Centers(grid)

  !-----------------------------------------------------!
  !   Calculate:                                        !
  !      components of cell faces, cell face centers.   !
  !-----------------------------------------------------!
  !   => depends on: xn, yn, zn                         !
  !   <= gives:      sx, sy, sz, xf, yf, zf             !
  !-----------------------------------------------------!
  do s = 1, grid % n_faces

    ! Copy face node coordinates to a local array for easier handling
    do n = 1, grid % faces_n_nodes(s)
      xt(n) = grid % xn(grid % faces_n(n,s))
      yt(n) = grid % yn(grid % faces_n(n,s))
      zt(n) = grid % zn(grid % faces_n(n,s))
    end do

    ! Cell face components
    grid % sx(s) = 0.0
    grid % sy(s) = 0.0
    grid % sz(s) = 0.0
    do n1 = 1, grid % faces_n_nodes(s)
      n2 = n1 + 1
      if(n2 > grid % faces_n_nodes(s)) n2 = 1
      grid % sx(s) = grid % sx(s) + (yt(n2) - yt(n1)) * (zt(n2) + zt(n1))
      grid % sy(s) = grid % sy(s) + (zt(n2) - zt(n1)) * (xt(n2) + xt(n1))
      grid % sz(s) = grid % sz(s) + (xt(n2) - xt(n1)) * (yt(n2) + yt(n1))
    end do
    grid % sx(s) = 0.5 * grid % sx(s)
    grid % sy(s) = 0.5 * grid % sy(s)
    grid % sz(s) = 0.5 * grid % sz(s)

    ! Barycenters
    n = grid % faces_n_nodes(s)
    grid % xf(s) = sum( xt(1:n) ) / real(n)
    grid % yf(s) = sum( yt(1:n) ) / real(n)
    grid % zf(s) = sum( zt(1:n) ) / real(n)

  end do ! through faces

  print *, '# Cell face components calculated !'

  !-------------------------------------------!
  !   Calculate boundary cell centers         !
  !-------------------------------------------!
  !   => depends on: xc, yc, zc, sx, sy, sz   !
  !   <= gives:      xc, yc, zc  for c<0      !
  !-------------------------------------------!
  print *, '#===================================='
  print *, '# Position the boundary cell centres:'
  print *, '#------------------------------------'
  print *, '# Type 1 for barycentric placement'
  print *, '# Type 2 for orthogonal placement'
  print *, '#------------------------------------'
  read(*,*) bou_cen

  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    sur_tot = sqrt(  grid % sx(s)*grid % sx(s)  &
                   + grid % sy(s)*grid % sy(s)  &
                   + grid % sz(s)*grid % sz(s) )

    if(c2 < 0) then
      t = (   grid % sx(s)*(grid % xf(s) - grid % xc(c1))        &
            + grid % sy(s)*(grid % yf(s) - grid % yc(c1))        &
            + grid % sz(s)*(grid % zf(s) - grid % zc(c1)) ) / sur_tot
      grid % xc(c2) = grid % xc(c1) + grid % sx(s)*t / sur_tot
      grid % yc(c2) = grid % yc(c1) + grid % sy(s)*t / sur_tot
      grid % zc(c2) = grid % zc(c1) + grid % sz(s)*t / sur_tot
      if(bou_cen .eq. 1) then
        grid % xc(c2) = grid % xf(s)
        grid % yc(c2) = grid % yf(s)
        grid % zc(c2) = grid % zf(s)
      end if
    end if
  end do ! through faces

  !---------------------------------------------------------------!
  !   Move the centers of co-planar molecules towards the walls   !
  !---------------------------------------------------------------!
  !   => depends on: xc, yc, zc                                   !
  !   <= gives:      xc, yc, zc                                   !
  !   +  uses:       dx, dy, dz                                   !
  !---------------------------------------------------------------!
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    if(c2 > 0) then
      grid % dx(c1) = max( grid % dx(c1), abs( grid % xc(c2) - grid % xc(c1) ) )
      grid % dy(c1) = max( grid % dy(c1), abs( grid % yc(c2) - grid % yc(c1) ) )
      grid % dz(c1) = max( grid % dz(c1), abs( grid % zc(c2) - grid % zc(c1) ) )
      grid % dx(c2) = max( grid % dx(c2), abs( grid % xc(c2) - grid % xc(c1) ) )
      grid % dy(c2) = max( grid % dy(c2), abs( grid % yc(c2) - grid % yc(c1) ) )
      grid % dz(c2) = max( grid % dz(c2), abs( grid % zc(c2) - grid % zc(c1) ) )
    end if
  end do ! through faces

  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    if(c2 < 0) then
      if( Math_Mod_Approx_Real(grid % dx(c1), 0.0, small) )  &
        grid % xc(c1) = 0.75 * grid % xc(c1) + 0.25 * grid % xc(c2)
      if( Math_Mod_Approx_Real(grid % dy(c1), 0.0, small) )  &
        grid % yc(c1) = 0.75 * grid % yc(c1) + 0.25 * grid % yc(c2)
      if( Math_Mod_Approx_Real(grid % dz(c1), 0.0, small) )  &
        grid % zc(c1) = 0.75 * grid % zc(c1) + 0.25 * grid % zc(c2)
    end if
  end do ! through faces

  ! Why are the following three lines needed?
  ! Because memory for dx, dy and dz was used in the previous step
  grid % dx(:) = 0.0
  grid % dy(:) = 0.0
  grid % dz(:) = 0.0

  !--------------------------------------------!
  !   Find the faces on the periodic boundary  !
  !--------------------------------------------!
  !   => depends on: xc, yc, zc, sx, sy, sz    !
  !   <= gives:      dx, dy, dz                !
  !--------------------------------------------!
  allocate(b_coor(grid % n_faces)); b_coor = 0.0
  allocate(b_face(grid % n_faces)); b_face = 0

  !--------------------------------------------------------!
  !                                                        !
  !   Phase I  ->  find the faces on periodic boundaries   !
  !                                                        !
  !--------------------------------------------------------!

  allocate(face_copy(grid % n_faces)); face_copy = 0

2 continue
  call Grid_Mod_Print_Bnd_Cond_List(grid)
  n_per = 0
  print *, '#=============================================================='
  print *, '# Enter the ordinal number(s) of periodic-boundary condition(s)'
  print *, '# from the boundary condition list (see above)                 '
  print *, '# Type skip if there is none !                                 '
  print *, '#--------------------------------------------------------------'
  call File_Mod_Read_Line(5)
  answer = line % tokens(1)
  call To_Upper_Case(answer)

  if( answer .eq. 'SKIP' ) then
    color_per = 0
    goto 1
  end if

  read(line % tokens(1), *) color_per
  if( color_per > grid % n_bnd_cond ) then
    print *, '# Critical error: boundary condition ', color_per,  &
               ' doesn''t exist!'
    print *, '# Exiting! '
    stop
  end if
  print *, '#=========================================='
  print *, '# Insert the periodic direction (x, y or z)'
  print *, '#------------------------------------------'
  read(*,*) dir
  call To_Upper_Case(dir)
  if(dir .ne. 'X' .and. dir .ne. 'Y' .and. dir .ne. 'Z') then
    print *, '# Critical error: direction is neither x, y nor z!'
    print *, '# Exiting! '
    stop
  end if

  print *, '#==============================================================='
  print *, '# For axisymmetric problems with periodic boundary conditions:  '
  print *, '# enter angle (in degrees) for rotation of the periodic boundary'
  print *, '# followed by rotation axis (1 -> x, 2 -> y, 3 -> z)            '
  print *, '#'
  print *, '# Type skip if you don''t deal with such a problem'
  print *, '#---------------------------------------------------------------'
  print *, '# (If the periodic direction is not parallel to the Caresian    '
  print *, '#  axis the coordinate system has to be rotated in 2D           '
  print *, '#---------------------------------------------------------------'
  call File_Mod_Read_Line(5)
  answer = line % tokens(1)
  call To_Upper_Case(answer)
  if( answer .eq. 'SKIP' ) then
    angle = 0.0
    rot_dir = 1
    option = 1
  else
    read(line % tokens(1),*) angle
    read(line % tokens(2),*) rot_dir
    option = 2
  end if

  !-------------------!
  !   With rotation   !
  !-------------------!
  if(option .eq. 2) then

    angle = angle * PI / 180.0

    if(dir .eq. 'X') then
      x_a = 0.0
      y_a = 0.0
      z_a = 0.0
      x_b = 0.0
      y_b = 1.0
      z_b = 0.0
      x_c = 0.0
      y_c = 0.0
      z_c = 1.0
    else if(dir .eq. 'Y') then
      x_a = 0.0
      y_a = 0.0
      z_a = 0.0
      x_b = 1.0
      y_b = 0.0
      z_b = 0.0
      x_c = 0.0
      y_c = 0.0
      z_c = 1.0
    else if(dir .eq. 'Z') then
      x_a = 0.0
      y_a = 0.0
      z_a = 0.0
      x_b = 1.0
      y_b = 0.0
      z_b = 0.0
      x_c = 0.0
      y_c = 1.0
      z_c = 0.0
    end if

    ab_i = x_b - x_a
    ab_j = y_b - y_a
    ab_k = z_b - z_a

    ac_i = x_c - x_a
    ac_j = y_c - y_a
    ac_k = z_c - z_a

    p_i =  ab_j*ac_k - ac_j*ab_k
    p_j = -ab_i*ac_k + ac_i*ab_k
    p_k =  ab_i*ac_j - ac_i*ab_j

    angle_face = angle_face * PI / 180.0

    allocate(phi_face(grid % n_faces)); phi_face=0.0
    allocate(xspr(grid % n_faces)); xspr=0.0
    allocate(yspr(grid % n_faces)); yspr=0.0
    allocate(zspr(grid % n_faces)); zspr=0.0

    do s = 1, grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(grid % bnd_cond % color(c2) .eq. color_per) then
          if( Math_Mod_Approx_Real(angle, 0.0, small) ) then
            xspr(s) = grid % xf(s)
            yspr(s) = grid % yf(s)
            zspr(s) = grid % zf(s)
          else
            if(rot_dir .eq. 3) then
              xspr(s) = grid % xf(s)*cos(angle) + grid % yf(s)*sin(angle)
              yspr(s) =-grid % xf(s)*sin(angle) + grid % yf(s)*cos(angle)
            else if(rot_dir .eq. 2) then
              xspr(s) = grid % xf(s)*cos(angle) + grid % zf(s)*sin(angle)
              zspr(s) =-grid % xf(s)*sin(angle) + grid % zf(s)*cos(angle)
            else if(rot_dir .eq. 1) then
              yspr(s) = grid % yf(s)*cos(angle) + grid % zf(s)*sin(angle)
              zspr(s) =-grid % yf(s)*sin(angle) + grid % zf(s)*cos(angle)
            end if
          end if
        end if
      end if
    end do
  end if  ! for option .eq. 2

  b_coor = 0.
  b_face = 0

  cnt_per = 0

  !-----------------!
  !   No rotation   !
  !-----------------!
  if(option .eq. 1) then
    do s = 1, grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(grid % bnd_cond % color(c2) .eq. color_per) then
          cnt_per = cnt_per + 1
          if(dir .eq. 'X') b_coor(cnt_per) = grid % xf(s)*big**2  &
                                           + grid % yf(s)*big     &
                                           + grid % zf(s)
          if(dir .eq. 'Y') b_coor(cnt_per) = grid % xf(s)         &
                                           + grid % yf(s)*big**2  &
                                           + grid % zf(s)*big
          if(dir .eq. 'Z') b_coor(cnt_per) = grid % xf(s)*big     &
                                           + grid % yf(s)         &
                                           + grid % zf(s)*big**2
          b_face(cnt_per) = s
        end if
      end if
    end do
    call Sort_Mod_Real_Carry_Int(b_coor(1:cnt_per),  &
                                 b_face(1:cnt_per))
  end if

  !-------------------!
  !   With rotation   !
  !-------------------!
  if(option .eq. 2) then
    c_max = 0
    do s = 1, grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(grid % bnd_cond % color(c2) .eq. color_per) then
          c_max = c_max + 1
        end if
      end if
    end do
    tol = small

3   continue

    nnn = 0
    hh = 0
    mm = 0
    cnt_per = 0

    per_max = -HUGE
    per_min =  HUGE

    do s = 1, grid % n_faces
      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(grid % bnd_cond % color(c2) .eq. color_per) then
          det = (  p_i*(grid % xf(s))  &
                 + p_j*(grid % yf(s))  &
                 + p_k*(grid % zf(s)))  &
              / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)
          per_min = min(per_min, det)
          per_max = max(per_max, det)
        end if
      end if
    end do
    per_max = 0.5*(per_max + per_min)

    do s = 1, grid % n_faces

      c2 = grid % faces_c(2,s)
      if(c2 < 0) then
        if(grid % bnd_cond % color(c2) .eq. color_per) then
          cnt_per = cnt_per + 1
          det = (  p_i*(grid % xf(s))   &
                 + p_j*(grid % yf(s))   &
                 + p_k*(grid % zf(s)))  &
              / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)

          if(dir .eq. 'X') then
            if((det) < (per_max)) then
              hh = hh + 1
              b_coor(hh) = real(hh)
              b_face(hh) = s
              do ss = 1, grid % n_faces
                cc2 = grid % faces_c(2,ss)
                if(cc2 < 0) then
                  if(grid % bnd_cond % color(cc2) .eq. color_per) then
                    det = (  p_i * (grid % xf(ss))   &
                           + p_j * (grid % yf(ss))   &
                           + p_k * (grid % zf(ss)))  &
                        / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)
                    if((det) > (per_max)) then
                      if((abs(grid % zf(ss)  - grid % zf(s))) < tol .and.   &
                         (abs(yspr(ss) - yspr(s))) < tol) then
                         mm = hh + c_max/2
                         b_coor(mm) = real(mm)
                         b_face(mm) = ss
                         nnn = nnn + 1
                      end if
                    end if
                  end if
                end if
              end do
            end if
          end if

          if(dir .eq. 'Y') then
            if((det) < (per_max)) then
              hh = hh + 1
              b_coor(hh) = real(hh)
              b_face(hh) = s
              do ss = 1, grid % n_faces
                cc2 = grid % faces_c(2,ss)
                if(cc2 < 0) then
                  if(grid % bnd_cond % color(cc2) .eq. color_per) then

                    det = (  p_i * (grid % xf(ss))  &
                           + p_j * (grid % yf(ss))  &
                           + p_k * (grid % zf(ss))) &
                        / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)

                    if((det) > (per_max)) then
                      if(abs((grid % zf(ss)  - grid % zf(s))) < tol .and.  &
                         abs((xspr(ss) - xspr(s))) < tol) then
                        mm = hh + c_max/2
                        b_coor(mm) = real(mm)
                        b_face(mm) = ss
                        nnn = nnn + 1
                      end if
                    end if

                  end if
                end if
              end do
            end if
          end if

          if(dir .eq. 'Z') then
            if((det) < (per_max)) then
              hh = hh + 1
              b_coor(hh) = real(hh)
              b_face(hh) = s
              do ss = 1, grid % n_faces
                cc2 = grid % faces_c(2,ss)
                if(cc2 < 0) then
                  if(grid % bnd_cond % color(cc2) .eq. color_per) then
                    det = (  p_i*(grid % xf(ss))   &
                           + p_j*(grid % yf(ss))   &
                           + p_k*(grid % zf(ss)))  &
                        / sqrt(p_i*p_i + p_j*p_j + p_k*p_k)
                    if((det) > (per_max)) then
                      print *, '# Warning!  Potentially a bug in ...'
                      print *, '# ... Compute_Geometry, line 580'
                      print *, '# Contact developers, and if you ... '
                      print *, '# ... are one of them, fix it!'
                      if(abs((grid % xf(ss) - grid % xf(s))) < tol .and.  &
                         abs((grid % yf(ss) - grid % yf(s))) < tol) then
                        mm = hh + c_max/2
                        b_coor(mm) = real(mm)
                        b_face(mm) = ss
                        nnn = nnn + 1
                      end if
                    end if
                  end if
                end if
              end do
            end if
          end if

        end if
      end if
    end do

    print *,'Iterating search for periodic cells: ',  &
    'Target: ', c_max/2, 'Result: ',nnn, 'Tolerance: ',tol

    if(nnn .eq. c_max/2) then
      continue
    else
      tol = tol*0.5
      goto 3  
    end if

    deallocate(phi_face)
    deallocate(xspr)
    deallocate(yspr)
    deallocate(zspr)

    call Sort_Mod_Real_Carry_Int(b_coor(1:cnt_per),  &
                                 b_face(1:cnt_per))
  end if  ! for option .eq. 2

  do s = 1, cnt_per/2
    s1 = b_face(s)
    s2 = b_face(s+cnt_per/2)
    c11 = grid % faces_c(1,s1)  ! cell 1 for face 1
    c21 = grid % faces_c(2,s1)  ! cell 2 for cell 1
    c12 = grid % faces_c(1,s2)  ! cell 1 for face 2
    c22 = grid % faces_c(2,s2)  ! cell 2 for face 2
    face_copy(s1) = s2          ! just to remember where it was coppied from
    grid % faces_c(2,s1) = c12
    grid % faces_c(1,s2) = 0    ! c21
    grid % faces_c(2,s2) = 0    ! c21
  end do

  n_per = cnt_per/2
  print *, '# Phase I: periodic cells: ', n_per

  ! Find periodic extents
  grid % per_x = 0.0
  grid % per_y = 0.0
  grid % per_z = 0.0
  do s = 1, n_per
    s1 = b_face(s)
    s2 = b_face(s + n_per)
    grid % per_x = max(grid % per_x, abs(grid % xf(s1) - grid % xf(s2)))
    grid % per_y = max(grid % per_y, abs(grid % yf(s1) - grid % yf(s2)))
    grid % per_z = max(grid % per_z, abs(grid % zf(s1) - grid % zf(s2)))
  end do
  print '(a38,f8.3)', ' # Periodicity in x direction         ', grid % per_x
  print '(a38,f8.3)', ' # Periodicity in y direction         ', grid % per_y
  print '(a38,f8.3)', ' # Periodicity in z direction         ', grid % per_z

  !-------------------------------------------------!
  !   Compress all boundary cells by removing all   !
  !   cells which were holding periodic condition   !
  !-------------------------------------------------!
  cnt_bnd = 0
  grid % new_c = 0
  do c = -1, -grid % n_bnd_cells, -1
    if(grid % bnd_cond % color(c) .ne. color_per) then
      cnt_bnd = cnt_bnd + 1
      grid % new_c(c) = -cnt_bnd
    end if
  end do

  ! Compress coordinates
  do c = -1, -grid % n_bnd_cells, -1
    if(grid % new_c(c) .ne. 0) then
      grid % xc(grid % new_c(c)) = grid % xc(c)
      grid % yc(grid % new_c(c)) = grid % yc(c)
      grid % zc(grid % new_c(c)) = grid % zc(c)
     grid % bnd_cond % color(grid % new_c(c)) = grid % bnd_cond % color(c)
    end if
  end do

  ! Compress indices
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(grid % new_c(c2) .ne. 0) then
      grid % faces_c(2,s) = grid % new_c(c2)
    end if
  end do

  grid % n_bnd_cells = cnt_bnd
  print *, '# Kept boundary cells: ', grid % n_bnd_cells

  !--------------------------------------------------------------------!
  !   Remove boundary condition with color_per and compress the rest   !
  !--------------------------------------------------------------------!
  if(color_per < grid % n_bnd_cond) then

    ! Set the color of boundary selected to be periodic to zero
    do c = -1, -grid % n_bnd_cells, -1
      if(grid % bnd_cond % color(c) .eq. color_per) then
        grid % bnd_cond % color(c) = 0
      end if
    end do

    ! Shift the rest of the boundary cells
    do b = 1, grid % n_bnd_cond - 1
      if(b .ge. color_per) then

        ! Correct the names
        grid % bnd_cond % name(b) = grid % bnd_cond % name (b+1)

        ! Correct all boundary colors too
        do c = -1, -grid % n_bnd_cells, -1
          if(grid % bnd_cond % color(c) .eq. (b+1)) then
            grid % bnd_cond % color(c) = b
          end if
        end do

      end if
    end do
  else
    grid % bnd_cond % name(grid % n_bnd_cond) = ''
  end if
  grid % n_bnd_cond = grid % n_bnd_cond - 1

  goto 2

1 continue
  !----------------------------------------------------!
  !                                                    !
  !   For some files, seems to be those generated in   !
  !   SnappyMesh, face orientation seems to be quite   !
  !   the opposite from what I expect in inner cells   !
  !                                                    !
  !----------------------------------------------------!
  n1 = 0
  n2 = 0
  do s = 1, grid % n_faces + grid % n_shadows
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    !-------------------------------------------------------------------------!
    !   Product of centres connection and surface normal should be positive   !
    !-------------------------------------------------------------------------!
    prod = grid % sx(s) * (grid % xc(c2)-grid % xc(c1) )  &
         + grid % sy(s) * (grid % yc(c2)-grid % yc(c1) )  &
         + grid % sz(s) * (grid % zc(c2)-grid % zc(c1) )

    !----------------------------------------------------------!
    !   If it is not, change the orientations of the surface   !
    !----------------------------------------------------------!
    if(prod < 0) then

      ! Increase the counters
      if(c2 > 0) n1 = n1 + 1
      if(c2 < 0) n2 = n2 + 1

      ! Reverse the order of face's nodes
      n = grid % faces_n_nodes(s)  ! number of nodes in this face
      call Sort_Mod_Reverse_Order_Int(grid % faces_n(1:n, s))

      ! Keep the first node first (important if it is concave)
      grid % faces_n(1:n,s) = cshift(grid % faces_n(1:n,s), -1)

      ! Change the orientation of calculated surface vector
      grid % sx(s) = -grid % sx(s)
      grid % sy(s) = -grid % sy(s)
      grid % sz(s) = -grid % sz(s)

    end if
  end do

  !-------------------------------------------------!
  !   Print some info on changed face orientation   !
  !-------------------------------------------------!
  if(n1 .gt. 0 .or. n2 .gt. 0) then
    print '(a)',      ' #======================================================'
    print '(a,i9,a)', ' # Changed orientation of', n1, ' inner faces,'
    print '(a,i9,a)', ' #                    and', n2, ' boundary faces.'
    print '(a)',      ' #------------------------------------------------------'
  else
    print '(a)', ' #========================================================='
    print '(a)', ' # Checked that all faces had good orientation (c1 -> c2). '
    print '(a)', ' #---------------------------------------------------------'
  end if

  !----------------------------------------------------!
  !                                                    !
  !   Phase II  ->  similar to the loop in Generator   !
  !                                                    !
  !----------------------------------------------------!

  !----------------!
  !   Initialize   !
  !----------------!
  n_per = 0
  grid % dx(:) = 0.0
  grid % dy(:) = 0.0
  grid % dz(:) = 0.0

  do s = 1, grid % n_faces

    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(c2 > 0) then

      !-------------------------!
      !   Find periodic faces   !
      !-------------------------!
      per_x = .false.
      if(grid % per_x .gt. NANO .and.  &
         abs(grid % xc(c2)-grid % xc(c1)) > 0.75 * grid % per_x) per_x = .true.
      per_y = .false.
      if(grid % per_y .gt. NANO .and.  &
         abs(grid % yc(c2)-grid % yc(c1)) > 0.75 * grid % per_y) per_y = .true.
      per_z = .false.
      if(grid % per_z .gt. NANO .and.  &
         abs(grid % zc(c2)-grid % zc(c1)) > 0.75 * grid % per_z) per_z = .true.

      if( per_x .or. per_y .or. per_z ) then

        n_per = n_per + 1

        ! Find the coordinates of the shadow face
        xs2 = grid % xf(face_copy(s))
        ys2 = grid % yf(face_copy(s))
        zs2 = grid % zf(face_copy(s))

        grid % dx(s) = grid % xf(s) - xs2  !-----------------------!
        grid % dy(s) = grid % yf(s) - ys2  ! later: xc2 = xc2 + dx !
        grid % dz(s) = grid % zf(s) - zs2  !-----------------------!

        grid % dx(face_copy(s)) = grid % dx(s)
        grid % dy(face_copy(s)) = grid % dy(s)
        grid % dz(face_copy(s)) = grid % dz(s)

        grid % faces_s(s) = face_copy(s)
        grid % faces_s(face_copy(s)) = s

        grid % per_x = max(grid % per_x, abs(grid % dx(s)))
        grid % per_y = max(grid % per_y, abs(grid % dy(s)))
        grid % per_z = max(grid % per_z, abs(grid % dz(s)))

      end if !  s*(c2-c1) < 0.0
    end if   !  c2 > 0
  end do     !  faces

  grid % n_shadows = n_per

  print '(a38,i9)',   ' # Phase II: number of shadow faces:  ', n_per
  print '(a38,f8.3)', ' # Periodicity in x direction         ', grid % per_x
  print '(a38,f8.3)', ' # Periodicity in y direction         ', grid % per_y
  print '(a38,f8.3)', ' # Periodicity in z direction         ', grid % per_z

  deallocate(face_copy)

  !-------------------------------------------------------!
  !                                                       !
  !   Phase III  ->  find the new numbers of cell faces   !
  !                                                       !
  !-------------------------------------------------------!
  number_faces = 0
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(c1 > 0) then
      number_faces = number_faces  + 1
      grid % new_f(s) = number_faces
    end if
  end do
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)
    if(.not. c1 > 0) then
      number_faces = number_faces  + 1
      grid % new_f(s) = number_faces
    end if
  end do
  print '(a38,i9)', ' # Old number of faces:               ',  grid % n_faces
  print '(a38,i9)', ' # New number of faces:               ',  number_faces

  !----------------------------------!
  !                                  !
  !   Phase IV  ->  sort the faces   !
  !                                  !
  !----------------------------------!
  call Grid_Mod_Sort_Faces_By_Index(grid, grid % new_f, grid % n_faces)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % xf, grid % new_f)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % yf, grid % new_f)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % zf, grid % new_f)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % sx, grid % new_f)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % sy, grid % new_f)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % sz, grid % new_f)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % dx, grid % new_f)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % dy, grid % new_f)
  call Sort_Mod_Real_By_Index(grid % n_faces, grid % dz, grid % new_f)

  grid % n_faces = grid % n_faces - n_per

  ! Final correction to shadow faces for grid % faces_s and grid faces_c
  do s = 1, grid % n_faces + grid % n_shadows
    if(grid % faces_s(s) > 0) then
      grid % faces_s(s) = grid % new_f(grid % faces_s(s))
      grid % faces_c(1, grid % faces_s(s)) = grid % faces_c(1, s)
      grid % faces_c(2, grid % faces_s(s)) = grid % faces_c(2, s)
    end if
  end do

  !-----------------------------------!
  !   Check the periodic boundaries   !
  !-----------------------------------!
  max_dis = 0.0
  do s = 1, grid % n_faces
    max_dis = max(max_dis, (  grid % dx(s)*grid % dx(s)  &
                            + grid % dy(s)*grid % dy(s)  &
                            + grid % dz(s)*grid % dz(s) ) )
  end do
  print '(a45,e12.5)', ' # Maximal distance of periodic boundary is: ',  &
                       sqrt(max_dis)

  !----------------------------------!
  !   Calculate the cell volumes     !
  !----------------------------------!
  !   => depends on: xc,yc,zc,       !
  !                  dx,dy,dz,       !
  !                  xsp, ysp, zsp   !
  !   <= gives:      vol             !
  !----------------------------------!
  do s = 1, grid % n_faces
    c1 = grid % faces_c(1,s)
    c2 = grid % faces_c(2,s)

    do i_nod = 1, grid % faces_n_nodes(s)  ! for all face types
      xt(i_nod) = grid % xn(grid % faces_n(i_nod,s))
      yt(i_nod) = grid % yn(grid % faces_n(i_nod,s))
      zt(i_nod) = grid % zn(grid % faces_n(i_nod,s))
    end do

    ! First cell
    x_cell_1 = grid % xc(c1)
    y_cell_1 = grid % yc(c1)
    z_cell_1 = grid % zc(c1)
    do i_nod = 1, grid % faces_n_nodes(s)  ! for all face types
      j_nod = i_nod + 1;  if(j_nod > grid % faces_n_nodes(s)) j_nod = 1

      dv_1 = Math_Mod_Tet_Volume(grid % xf(s), grid % yf(s), grid % zf(s),  &
                                 xt(i_nod),    yt(i_nod),    zt(i_nod),     &
                                 xt(j_nod),    yt(j_nod),    zt(j_nod),     &
                                 x_cell_1,     y_cell_1,     z_cell_1)
      grid % vol(c1) = grid % vol(c1) + abs(dv_1)
    end do  ! i_nod

    ! Second cell
    if(c2 > 0) then
      x_cell_2 = grid % xc(c2) + grid % dx(s)
      y_cell_2 = grid % yc(c2) + grid % dy(s)
      z_cell_2 = grid % zc(c2) + grid % dz(s)

      do i_nod = 1, grid % faces_n_nodes(s)  ! for all face types
        j_nod = i_nod + 1;  if(j_nod > grid % faces_n_nodes(s)) j_nod = 1

        dv_2 = Math_Mod_Tet_Volume(grid % xf(s), grid % yf(s), grid % zf(s),  &
                                   xt(i_nod),    yt(i_nod),    zt(i_nod),     &
                                   xt(j_nod),    yt(j_nod),    zt(j_nod),     &
                                   x_cell_2,     y_cell_2,     z_cell_2)
        grid % vol(c2) = grid % vol(c2) + abs(dv_2)
      end do  ! i_nod
    end if

  end do

  grid % min_vol =  HUGE
  grid % max_vol = -HUGE
  grid % tot_vol = 0.0
  do c = 1, grid % n_cells
    grid % tot_vol = grid % tot_vol + grid % vol(c)
    grid % min_vol = min(grid % min_vol, grid % vol(c))
    grid % max_vol = max(grid % max_vol, grid % vol(c))
  end do
  print '(a45,es12.5)', ' # Minimal cell volume is:                   ',  &
        grid % min_vol
  print '(a45,es12.5)', ' # Maximal cell volume is:                   ',  &
        grid % max_vol
  print '(a45,es12.5)', ' # Total domain volume is:                   ',  &
        grid % tot_vol
  print *, '# Cell volumes calculated !'

  if(grid % min_vol < 0.0) then
    print *, '# Negative volume occured!'
    print *, '# Execution will halt now!'
    stop
  end if

  deallocate(b_coor)
  deallocate(b_face)

  !------------------------------------------------------------!
  !   Calculate the interpolation factors for the cell faces   !
  !------------------------------------------------------------!
  call Grid_Mod_Calculate_Face_Interpolation(grid)

  print *, '# Interpolation factors calculated !'

  end subroutine
