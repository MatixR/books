!> @file dissipRoe1.f90
!!
!! Computation of 1st-order upwind dissipation.
!
! *****************************************************************************
!
!  (c) J. Blazek, CFD Consulting & Analysis, www.cfd-ca.de
!  Created February 25, 2014
!  Last modification: March 24, 2014
!
! *****************************************************************************
!
!  This program is free software; you can redistribute it and/or
!  modify it under the terms of the GNU General Public License
!  as published by the Free Software Foundation; either version 2
!  of the License, or (at your option) any later version.
!
!  This program is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!  GNU General Public License for more details.
!
!  You should have received a copy of the GNU General Public License
!  along with this program; if not, write to the Free Software
!  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
!
! *****************************************************************************

!> Computes upwind dissipation according to 1st-order Roe's flux-difference
!! splitting scheme.
!!
!! @param beta  coefficient for mixing new and old dissipation values
!!
subroutine DissipRoe1( beta )

  use ModDataTypes
  use ModGeometry
  use ModNumerics
  use ModPhysics
  implicit none

! parameters
  real(rtype), intent(in) :: beta

! local variables
  integer     :: i, j, im1, jm1
  real(rtype) :: beta5, ds, nx, ny, gam1, rrho, rl, ul, vl, pl, hl, &
                 rr, ur, vr, pr, hr, rav, dd, dd1, uav, vav, hav, q2a, &
                 c2a, cav, uv, du, h1, h2, h3, h4, h5, delta, eabs1, &
                 eabs2, eabs4
  real(rtype) :: fd(4)

! *****************************************************************************

  beta5 = 0.5D0*beta

! i-direction -----------------------------------------------------------------

  do j=2,j2

    do i=2,il
      im1 = i - 1
      ds  = Sqrt(si(1,i,j)*si(1,i,j)+si(2,i,j)*si(2,i,j))
      nx  = si(1,i,j)/ds
      ny  = si(2,i,j)/ds

! --- left and right state (at I-1/2)

      rrho = 1.D0/cv(1,im1,j)
      rl   = cv(1,im1,j)
      ul   = cv(2,im1,j)*rrho
      vl   = cv(3,im1,j)*rrho
      pl   = dv(1,im1,j)
      hl   = (pl+cv(4,im1,j))*rrho

      rrho = 1.D0/cv(1,i,j)
      rr   = cv(1,i,j)
      ur   = cv(2,i,j)*rrho
      vr   = cv(3,i,j)*rrho
      pr   = dv(1,i,j)
      hr   = (pr+cv(4,i,j))*rrho

! --- Roe's average

      rav   = Sqrt(rl*rr)
      gam1  = 0.5D0*(dv(4,im1,j)+dv(4,i,j)) - 1.D0
      dd    = rav/rl
      dd1   = 1.D0/(1.D0+dd)
      uav   = (ul+dd*ur)*dd1
      vav   = (vl+dd*vr)*dd1
      hav   = (hl+dd*hr)*dd1
      q2a   = 0.5D0*(uav*uav+vav*vav)
      c2a   = gam1*(hav-q2a)
      cav   = Sqrt(c2a)
      uv    = uav*nx + vav*ny
      du    = (ur-ul)*nx + (vr-vl)*ny

! --- eigenvalues

      h1    = Abs(uv - cav)
      h2    = Abs(uv)
      h4    = Abs(uv + cav)
      delta = epsentr*h4

      eabs1 = EntropyCorr1( h1,delta )
      eabs2 = EntropyCorr1( h2,delta )
      eabs4 = EntropyCorr1( h4,delta )

! --- upwind fluxes

      h1 = rav*cav*du
      h2 = eabs1*(pr-pl - h1)/(2.D0*c2a)
      h3 = eabs2*(rr-rl - (pr-pl)/c2a)
      h4 = eabs2*rav
      h5 = eabs4*(pr-pl + h1)/(2.D0*c2a)

      fd(1) = h2 + h3 + h5
      fd(2) = h2*(uav-cav*nx) + h3*uav + h4*(ur-ul-du*nx) + h5*(uav+cav*nx)
      fd(3) = h2*(vav-cav*ny) + h3*vav + h4*(vr-vl-du*ny) + h5*(vav+cav*ny)
      fd(4) = h2*(hav-cav*uv) + h3*q2a + h4*(uav*(ur-ul)+vav*(vr-vl)-uv*du) + &
              h5*(hav+cav*uv)

! --- dissipation term

      ds            = ds*beta5
      diss(1,i  ,j) = diss(1,i  ,j) - fd(1)*ds
      diss(2,i  ,j) = diss(2,i  ,j) - fd(2)*ds
      diss(3,i  ,j) = diss(3,i  ,j) - fd(3)*ds
      diss(4,i  ,j) = diss(4,i  ,j) - fd(4)*ds

      diss(1,im1,j) = diss(1,im1,j) + fd(1)*ds
      diss(2,im1,j) = diss(2,im1,j) + fd(2)*ds
      diss(3,im1,j) = diss(3,im1,j) + fd(3)*ds
      diss(4,im1,j) = diss(4,im1,j) + fd(4)*ds
    enddo ! i

  enddo   ! j

! j-direction -----------------------------------------------------------------

  do i=2,i2

    do j=2,jl
      jm1 = j - 1
      ds  = Sqrt(sj(1,i,j)*sj(1,i,j)+sj(2,i,j)*sj(2,i,j))
      nx  = sj(1,i,j)/ds
      ny  = sj(2,i,j)/ds

! --- left and right state (at J-1/2)

      rrho = 1.D0/cv(1,i,jm1)
      rl   = cv(1,i,jm1)
      ul   = cv(2,i,jm1)*rrho
      vl   = cv(3,i,jm1)*rrho
      pl   = dv(1,i,jm1)
      hl   = (pl+cv(4,i,jm1))*rrho

      rrho = 1.D0/cv(1,i,j)
      rr   = cv(1,i,j)
      ur   = cv(2,i,j)*rrho
      vr   = cv(3,i,j)*rrho
      pr   = dv(1,i,j)
      hr   = (pr+cv(4,i,j))*rrho

! --- Roe's average

      rav   = Sqrt(rl*rr)
      gam1  = 0.5D0*(dv(4,i,jm1)+dv(4,i,j)) - 1.D0
      dd    = rav/rl
      dd1   = 1.D0/(1.D0+dd)
      uav   = (ul+dd*ur)*dd1
      vav   = (vl+dd*vr)*dd1
      hav   = (hl+dd*hr)*dd1
      q2a   = 0.5D0*(uav*uav+vav*vav)
      c2a   = gam1*(hav-q2a)
      cav   = Sqrt(c2a)
      uv    = uav*nx + vav*ny
      du    = (ur-ul)*nx + (vr-vl)*ny

! --- eigenvalues

      h1    = Abs(uv - cav)
      h2    = Abs(uv)
      h4    = Abs(uv + cav)
      delta = epsentr*h4

      eabs1 = EntropyCorr1( h1,delta )
      eabs2 = EntropyCorr1( h2,delta )
      eabs4 = EntropyCorr1( h4,delta )

! --- upwind fluxes

      h1 = rav*cav*du
      h2 = eabs1*(pr-pl - h1)/(2.D0*c2a)
      h3 = eabs2*(rr-rl - (pr-pl)/c2a)
      h4 = eabs2*rav
      h5 = eabs4*(pr-pl + h1)/(2.D0*c2a)

      fd(1) = h2 + h3 + h5
      fd(2) = h2*(uav-cav*nx) + h3*uav + h4*(ur-ul-du*nx) + h5*(uav+cav*nx)
      fd(3) = h2*(vav-cav*ny) + h3*vav + h4*(vr-vl-du*ny) + h5*(vav+cav*ny)
      fd(4) = h2*(hav-cav*uv) + h3*q2a + h4*(uav*(ur-ul)+vav*(vr-vl)-uv*du) + &
              h5*(hav+cav*uv)

! --- dissipation term

      ds            = ds*beta5
      diss(1,i,j  ) = diss(1,i,j  ) - fd(1)*ds
      diss(2,i,j  ) = diss(2,i,j  ) - fd(2)*ds
      diss(3,i,j  ) = diss(3,i,j  ) - fd(3)*ds
      diss(4,i,j  ) = diss(4,i,j  ) - fd(4)*ds

      diss(1,i,jm1) = diss(1,i,jm1) + fd(1)*ds
      diss(2,i,jm1) = diss(2,i,jm1) + fd(2)*ds
      diss(3,i,jm1) = diss(3,i,jm1) + fd(3)*ds
      diss(4,i,jm1) = diss(4,i,jm1) + fd(4)*ds
    enddo ! j

  enddo   ! i

! *****************************************************************************

contains

!> Evaluates entropy correction function
!!
!! @param z  value to be corrected
!! @param d  threshold value of the correction
!! @return   corrected value of z
!!
  real(rtype) function EntropyCorr1( z,d )
    implicit none
    real(rtype) :: z, d

    if (z > d) then
      EntropyCorr1 = z
    else
      EntropyCorr1 = 0.5D0*(z*z+d*d)/d
    endif
  end function EntropyCorr1

end subroutine DissipRoe1
