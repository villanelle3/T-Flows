!==============================================================================!
  subroutine Send_Int_Array(Comm, len_s, phi_s, dest)
!------------------------------------------------------------------------------!
!   Sends an integer array to processor dest.                                  !
!------------------------------------------------------------------------------!
  implicit none
!---------------------------------[Arguments]----------------------------------!
  class(Comm_Type) :: Comm
  integer          :: len_s         ! send length
  integer          :: phi_s(len_s)  ! send buffer
  integer          :: dest          ! destination processor
!-----------------------------------[Locals]-----------------------------------!
  integer :: stag, error
  integer :: status(MPI_STATUS_SIZE)
!==============================================================================!

  ! Form send tag
  stag = (n_proc) * this_proc + dest  ! tag for sending

  call Mpi_Send(phi_s(1),        & ! send buffer
                len_s,           & ! send length
                comm_type_int,   & ! datatype
                (dest-1),        & ! dest,
                stag,            & ! sendtag,
                MPI_COMM_WORLD,  &
                status,          &
                error)

  end subroutine
