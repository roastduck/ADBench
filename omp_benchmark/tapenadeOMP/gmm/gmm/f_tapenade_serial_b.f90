!        Generated by TAPENADE     (INRIA, Ecuador team)
!  Tapenade 3.16 (develop) - 14 Jul 2023 15:27
!
MODULE WISHART_MODULE_DIFF
  USE ISO_C_BINDING
  TYPE, BIND(C) :: WISHART
      REAL(C_DOUBLE) :: gamma
      INTEGER(C_INT) :: m
  END TYPE WISHART

CONTAINS
!  Differentiation of arr_max in reverse (adjoint) mode (with options OpenMP):
!   gradient     of useful results: x arr_max
!   with respect to varying inputs: x
  SUBROUTINE ARR_MAX_B(n, x, xb, arr_maxb)
    IMPLICIT NONE
    INTEGER :: n, i
    REAL(kind=8), DIMENSION(n) :: x
    REAL(kind=8), DIMENSION(n) :: xb
    REAL(kind=8) :: arr_max
    REAL(kind=8) :: arr_maxb
    INTEGER*4 :: branch
    arr_max = x(1)
    DO i=2,n
      IF (arr_max .LT. x(i)) THEN
        arr_max = x(i)
        CALL PUSHCONTROL1B(1)
      ELSE
        CALL PUSHCONTROL1B(0)
      END IF
    END DO
    DO i=n,2,-1
      CALL POPCONTROL1B(branch)
      IF (branch .NE. 0) THEN
        xb(i) = xb(i) + arr_maxb
        arr_maxb = 0.0_8
      END IF
    END DO
    xb(1) = xb(1) + arr_maxb
  END SUBROUTINE ARR_MAX_B

  FUNCTION ARR_MAX(n, x)
    IMPLICIT NONE
    INTEGER :: n, i
    REAL(kind=8), DIMENSION(n) :: x
    REAL(kind=8) :: arr_max
    arr_max = x(1)
    DO i=2,n
      IF (arr_max .LT. x(i)) arr_max = x(i)
    END DO
  END FUNCTION ARR_MAX

!  Differentiation of sqnorm in reverse (adjoint) mode (with options OpenMP):
!   gradient     of useful results: x sqnorm
!   with respect to varying inputs: x
  SUBROUTINE SQNORM_B(n, x, xb, sqnormb)
    IMPLICIT NONE
    INTEGER :: n, i
    REAL(kind=8), DIMENSION(n) :: x
    REAL(kind=8), DIMENSION(n) :: xb
    REAL(kind=8) :: sqnorm
    REAL(kind=8) :: sqnormb
    DO i=n,2,-1
      xb(i) = xb(i) + 2*x(i)*sqnormb
    END DO
    xb(1) = xb(1) + 2*x(1)*sqnormb
  END SUBROUTINE SQNORM_B

  FUNCTION SQNORM(n, x)
    IMPLICIT NONE
    INTEGER :: n, i
    REAL(kind=8), DIMENSION(n) :: x
    REAL(kind=8) :: sqnorm
    sqnorm = x(1)*x(1)
    DO i=2,n
      sqnorm = sqnorm + x(i)*x(i)
    END DO
  END FUNCTION SQNORM

!  Differentiation of subtract in reverse (adjoint) mode (with options OpenMP):
!   gradient     of useful results: out y
!   with respect to varying inputs: out y
  SUBROUTINE SUBTRACT_B(d, x, y, yb, out, outb)
    IMPLICIT NONE
    INTEGER :: d, id
    REAL(kind=8), DIMENSION(d) :: x, y, out
    REAL(kind=8), DIMENSION(d) :: yb, outb
    DO id=d,1,-1
      yb(id) = yb(id) - outb(id)
      outb(id) = 0.0_8
    END DO
  END SUBROUTINE SUBTRACT_B

  SUBROUTINE SUBTRACT(d, x, y, out)
    IMPLICIT NONE
    INTEGER :: d, id
    REAL(kind=8), DIMENSION(d) :: x, y, out
    DO id=1,d
      out(id) = x(id) - y(id)
    END DO
  END SUBROUTINE SUBTRACT

!  Differentiation of log_sum_exp in reverse (adjoint) mode (with options OpenMP):
!   gradient     of useful results: x log_sum_exp
!   with respect to varying inputs: x
  SUBROUTINE LOG_SUM_EXP_B(n, x, xb, log_sum_expb)
    IMPLICIT NONE
    INTEGER :: n, i
    REAL(kind=8), DIMENSION(n) :: x
    REAL(kind=8), DIMENSION(n) :: xb
    REAL(kind=8) :: log_sum_exp, mx, semx
    REAL(kind=8) :: log_sum_expb, mxb, semxb
    INTRINSIC EXP
    INTRINSIC LOG
    REAL(kind=8) :: tempb
    mx = ARR_MAX(n, x)
    semx = 0.0
    DO i=1,n
      semx = semx + EXP(x(i) - mx)
    END DO
    semxb = log_sum_expb/semx
    mxb = log_sum_expb
    DO i=n,1,-1
      tempb = EXP(x(i)-mx)*semxb
      xb(i) = xb(i) + tempb
      mxb = mxb - tempb
    END DO
    CALL ARR_MAX_B(n, x, xb, mxb)
  END SUBROUTINE LOG_SUM_EXP_B

  FUNCTION LOG_SUM_EXP(n, x)
    IMPLICIT NONE
    INTEGER :: n, i
    REAL(kind=8), DIMENSION(n) :: x
    REAL(kind=8) :: log_sum_exp, mx, semx
    INTRINSIC EXP
    INTRINSIC LOG
    mx = ARR_MAX(n, x)
    semx = 0.0
    DO i=1,n
      semx = semx + EXP(x(i) - mx)
    END DO
    log_sum_exp = LOG(semx) + mx
  END FUNCTION LOG_SUM_EXP

  FUNCTION LOG_GAMMA_DISTRIB(a, p)
    IMPLICIT NONE
    INTEGER :: p, j
    REAL(kind=8) :: a, out
    INTRINSIC LOG
    REAL(kind=8) :: arg1
    REAL(kind=8) :: result1
    REAL(kind=8) :: log_gamma_distrib
    out = 0.25*p*(p-1)*LOG(3.1415926)
    DO j=1,p
      arg1 = a + 0.5*(1-j)
      result1 = LGAMMA(arg1)
      out = out + result1
    END DO
    log_gamma_distrib = out
  END FUNCTION LOG_GAMMA_DISTRIB

!  Differentiation of log_wishart_prior in reverse (adjoint) mode (with options OpenMP):
!   gradient     of useful results: log_wishart_prior
!   with respect to varying inputs: qdiags sum_qs icf
  SUBROUTINE LOG_WISHART_PRIOR_B(p, k, wishart_var, sum_qs, sum_qsb, &
&   qdiags, qdiagsb, icf, icfb, log_wishart_priorb)
    IMPLICIT NONE
    INTEGER :: p, k, ik
    TYPE(WISHART) :: wishart_var
    REAL(kind=8), DIMENSION(*), INTENT(IN) :: sum_qs, qdiags, icf
    REAL(kind=8), DIMENSION(*) :: sum_qsb, qdiagsb, icfb
    REAL(kind=8) :: log_wishart_prior, c, out, frobenius
    REAL(kind=8) :: log_wishart_priorb, outb, frobeniusb
    INTEGER :: n, icf_sz, id
    INTRINSIC LOG
    REAL :: arg1
    INTEGER :: result1
    REAL(kind=8) :: result10
    REAL(kind=8) :: result10b
    INTEGER :: arg10
    REAL(kind=8) :: result2
    REAL(kind=8) :: result2b
    icf_sz = p*(p+1)/2
    outb = log_wishart_priorb

    DO ik = 1, k * p
        qdiagsb(ik) = 0.0
    END DO
    DO ik = 1, k
        sum_qsb(ik) = 0.0
    END DO
    DO ik = 1, k * icf_sz
        icfb(ik) = 0.0
    END DO

    DO ik=k,1,-1
      frobeniusb = 0.5*wishart_var%gamma**2*outb
      sum_qsb(ik) = sum_qsb(ik) - wishart_var%m*outb
      result10b = frobeniusb
      result2b = frobeniusb
      arg10 = icf_sz - p
      CALL SQNORM_B(arg10, icf((ik-1)*icf_sz+p+1:ik*icf_sz), icfb((ik-1)&
&             *icf_sz+p+1:ik*icf_sz), result2b)
      CALL SQNORM_B(p, qdiags((ik-1)*p+1:ik*p), qdiagsb((ik-1)*p+1:ik*p)&
&             , result10b)
    END DO
  END SUBROUTINE LOG_WISHART_PRIOR_B

  FUNCTION LOG_WISHART_PRIOR(p, k, wishart_var, sum_qs, qdiags, icf)
    IMPLICIT NONE
    INTEGER :: p, k, ik
    TYPE(WISHART) :: wishart_var
    REAL(kind=8), DIMENSION(*), INTENT(IN) :: sum_qs, qdiags, icf
    REAL(kind=8) :: log_wishart_prior, c, out, frobenius
    INTEGER :: n, icf_sz, id
    INTRINSIC LOG
    REAL(kind=8) :: arg1
    REAL(kind=8) :: result1
    REAL(kind=8) :: result10
    INTEGER :: arg10
    REAL(kind=8) :: result2
    n = p + wishart_var%m + 1
    icf_sz = p*(p+1)/2
    arg1 = 0.5*n
    result1 = LOG_GAMMA_DISTRIB(arg1, p)
    c = n*p*(LOG(wishart_var%gamma)-0.5*LOG(2.0)) - result1
    out = 0
    DO ik=1,k
      result10 = SQNORM(p, qdiags((ik-1)*p+1:ik*p))
      arg10 = icf_sz - p
      result2 = SQNORM(arg10, icf((ik-1)*icf_sz+p+1:ik*icf_sz))
      frobenius = result10 + result2
      out = out + 0.5*wishart_var%gamma*wishart_var%gamma*frobenius - &
&       wishart_var%m*sum_qs(ik)
    END DO
    log_wishart_prior = out - k*c
  END FUNCTION LOG_WISHART_PRIOR

!  Differentiation of preprocess_qs in reverse (adjoint) mode (with options OpenMP):
!   gradient     of useful results: qdiags sum_qs icf
!   with respect to varying inputs: icf
  SUBROUTINE PREPROCESS_QS_B(d, k, icf, icfb, sum_qs, sum_qsb, qdiags, &
&   qdiagsb)
    IMPLICIT NONE
    INTEGER :: d, k, ik, id
    REAL(kind=8), DIMENSION(*), INTENT(IN) :: icf
    REAL(kind=8), DIMENSION(*) :: icfb
    REAL(kind=8), DIMENSION(*) :: sum_qs, qdiags
    REAL(kind=8), DIMENSION(*) :: sum_qsb, qdiagsb
    INTEGER :: icf_sz
    INTRINSIC EXP
    icf_sz = d*(d+1)/2
    DO ik=k,1,-1
      DO id=d,1,-1
        icfb((ik-1)*icf_sz+id) = icfb((ik-1)*icf_sz+id) + EXP(icf((ik-1)&
&         *icf_sz+id))*qdiagsb((ik-1)*d+id) + sum_qsb(ik)
        qdiagsb((ik-1)*d+id) = 0.0_8
      END DO
      sum_qsb(ik) = 0.0_8
    END DO
  END SUBROUTINE PREPROCESS_QS_B

  SUBROUTINE PREPROCESS_QS(d, k, icf, sum_qs, qdiags)
    IMPLICIT NONE
    INTEGER :: d, k, ik, id
    REAL(kind=8), DIMENSION(*), INTENT(IN) :: icf
    REAL(kind=8), DIMENSION(*), INTENT(OUT) :: sum_qs, qdiags
    INTEGER :: icf_sz
    INTRINSIC EXP
    icf_sz = d*(d+1)/2
    DO ik=1,k
      sum_qs(ik) = 0.
      DO id=1,d
        sum_qs(ik) = sum_qs(ik) + icf((ik-1)*icf_sz+id)
        qdiags((ik-1)*d+id) = EXP(icf((ik-1)*icf_sz+id))
      END DO
    END DO
  END SUBROUTINE PREPROCESS_QS

!  Differentiation of qtimesx in reverse (adjoint) mode (with options OpenMP):
!   gradient     of useful results: out x ltri qdiag
!   with respect to varying inputs: out x ltri qdiag
  SUBROUTINE QTIMESX_B(d, qdiag, qdiagb, ltri, ltrib, x, xb, out, outb)
    IMPLICIT NONE
    INTEGER :: d, i, j
    REAL(kind=8), DIMENSION(*), INTENT(IN) :: qdiag, ltri, x
    REAL(kind=8), DIMENSION(*) :: qdiagb, ltrib, xb
    REAL(kind=8), DIMENSION(*) :: out
    REAL(kind=8), DIMENSION(*) :: outb
    INTEGER :: lparamsidx
    INTEGER :: ad_from
    lparamsidx = 1
    DO i=1,d
      ad_from = i + 1
      DO j=ad_from,d
        CALL PUSHINTEGER4(lparamsidx)
        lparamsidx = lparamsidx + 1
      END DO
      CALL PUSHINTEGER4(ad_from)
    END DO
    DO i=d,1,-1
      CALL POPINTEGER4(ad_from)
      DO j=d,ad_from,-1
        CALL POPINTEGER4(lparamsidx)
        ltrib(lparamsidx) = ltrib(lparamsidx) + x(i)*outb(j)
        xb(i) = xb(i) + ltri(lparamsidx)*outb(j)
      END DO
    END DO
    DO i=d,1,-1
      qdiagb(i) = qdiagb(i) + x(i)*outb(i)
      xb(i) = xb(i) + qdiag(i)*outb(i)
      outb(i) = 0.0_8
    END DO
  END SUBROUTINE QTIMESX_B

  SUBROUTINE QTIMESX(d, qdiag, ltri, x, out)
    IMPLICIT NONE
    INTEGER :: d, i, j
    REAL(kind=8), DIMENSION(*), INTENT(IN) :: qdiag, ltri, x
    REAL(kind=8), DIMENSION(*), INTENT(OUT) :: out
    INTEGER :: lparamsidx
    DO i=1,d
      out(i) = qdiag(i)*x(i)
    END DO
    lparamsidx = 1
    DO i=1,d
      DO j=i+1,d
        out(j) = out(j) + ltri(lparamsidx)*x(i)
        lparamsidx = lparamsidx + 1
      END DO
    END DO
  END SUBROUTINE QTIMESX

!  Differentiation of gmm_objective in reverse (adjoint) mode (with options OpenMP):
!   gradient     of useful results: err
!   with respect to varying inputs: err means icf alphas
!   RW status of diff variables: err:in-zero means:out icf:out
!                alphas:out
  SUBROUTINE GMM_OBJECTIVE_B(d, k, n, alphas, alphasb, means, meansb, &
&   icf, icfb, x, wishart_var, err, errb) BIND(c)
    IMPLICIT NONE
    INTEGER :: d, k, n, ix, ik
    TYPE(WISHART) :: wishart_var
    REAL(kind=8), DIMENSION(*), INTENT(IN) :: alphas, means, icf, x
    REAL(kind=8), DIMENSION(*) :: alphasb, meansb, icfb
    REAL(kind=8) :: err
    REAL(kind=8) :: errb
    REAL(kind=8), DIMENSION(:), ALLOCATABLE :: qdiags, sum_qs, xcentered&
&   , qxcentered, main_term
    REAL(kind=8), DIMENSION(:), ALLOCATABLE :: qdiagsb, sum_qsb, &
&   xcenteredb, qxcenteredb, main_termb
    INTEGER :: icf_sz, id
    REAL :: const
    INTRINSIC LOG
    REAL :: slse
    REAL :: slseb
    REAL(kind=8) :: lse_alphas
    REAL(kind=8) :: lse_alphasb
    REAL(kind=8) :: result1
    REAL(kind=8) :: result1b
    INTEGER*4 :: branch
    icf_sz = d*(d+1)/2
    ALLOCATE(qdiagsb(d*k))
    qdiagsb = 0.0_8
    ALLOCATE(qdiags(d*k))
    ALLOCATE(sum_qsb(k))
    sum_qsb = 0.0_8
    ALLOCATE(sum_qs(k))
    ALLOCATE(xcenteredb(d))
    xcenteredb = 0.0_8
    ALLOCATE(xcentered(d))
    ALLOCATE(qxcenteredb(d))
    qxcenteredb = 0.0_8
    ALLOCATE(qxcentered(d))
    ALLOCATE(main_termb(k))
    main_termb = 0.0_8
    ALLOCATE(main_term(k))
    CALL PREPROCESS_QS(d, k, icf, sum_qs, qdiags)
    DO ix=1,n
      DO ik=1,k
        IF (ALLOCATED(xcentered)) THEN
          CALL PUSHREAL8ARRAY(xcentered, d)
          CALL PUSHCONTROL1B(1)
        ELSE
          CALL PUSHCONTROL1B(0)
        END IF
        CALL SUBTRACT(d, x((ix-1)*d+1:ix*d), means((ik-1)*d+1:ik*d), &
&               xcentered)
        IF (ALLOCATED(qxcentered)) THEN
          CALL PUSHREAL8ARRAY(qxcentered, d)
          CALL PUSHCONTROL1B(1)
        ELSE
          CALL PUSHCONTROL1B(0)
        END IF
        CALL QTIMESX(d, qdiags((ik-1)*d+1:ik*d), icf((ik-1)*icf_sz+d+1:&
&              ik*icf_sz), xcentered, qxcentered)
        result1 = SQNORM(d, qxcentered)
        CALL PUSHREAL8(main_term(ik))
        main_term(ik) = alphas(ik) + sum_qs(ik) - 0.5*result1
      END DO
    END DO
    slseb = errb
    lse_alphasb = (-n) * errb
    result1b = errb
    CALL LOG_WISHART_PRIOR_B(d, k, wishart_var, sum_qs, sum_qsb, qdiags&
&                      , qdiagsb, icf, icfb, result1b)

    DO ix = 1, k
        alphasb(ix) = 0.0
    END DO
    DO ix = 1, d * k
        meansb(ix) = 0.0
    END DO

    CALL LOG_SUM_EXP_B(k, alphas, alphasb, lse_alphasb);

    DO ix=n,1,-1
      result1b = slseb
      CALL LOG_SUM_EXP_B(k, main_term, main_termb, result1b)
      DO ik=k,1,-1
        CALL POPREAL8(main_term(ik))
        alphasb(ik) = alphasb(ik) + main_termb(ik)
        sum_qsb(ik) = sum_qsb(ik) + main_termb(ik)
        result1b = -(0.5*main_termb(ik))
        main_termb(ik) = 0.0_8
        CALL SQNORM_B(d, qxcentered, qxcenteredb, result1b)
        CALL POPCONTROL1B(branch)
        IF (branch .EQ. 1) CALL POPREAL8ARRAY(qxcentered, d)
        CALL QTIMESX_B(d, qdiags((ik-1)*d+1:ik*d), qdiagsb((ik-1)*d+1:ik&
&                *d), icf((ik-1)*icf_sz+d+1:ik*icf_sz), icfb((ik-1)*&
&                icf_sz+d+1:ik*icf_sz), xcentered, xcenteredb, &
&                qxcentered, qxcenteredb)
        CALL POPCONTROL1B(branch)
        IF (branch .EQ. 1) CALL POPREAL8ARRAY(xcentered, d)
        CALL SUBTRACT_B(d, x((ix-1)*d+1:ix*d), means((ik-1)*d+1:ik*d), &
&                 meansb((ik-1)*d+1:ik*d), xcentered, xcenteredb)
      END DO
    END DO
    CALL PREPROCESS_QS_B(d, k, icf, icfb, sum_qs, sum_qsb, qdiags, &
&                  qdiagsb)
    sum_qsb = 0.0_8
    qdiagsb = 0.0_8
    DEALLOCATE(main_term)
    DEALLOCATE(main_termb)
    DEALLOCATE(qxcentered)
    DEALLOCATE(qxcenteredb)
    DEALLOCATE(xcentered)
    DEALLOCATE(xcenteredb)
    DEALLOCATE(sum_qs)
    DEALLOCATE(sum_qsb)
    DEALLOCATE(qdiags)
    DEALLOCATE(qdiagsb)
    errb = 0.0_8
  END SUBROUTINE GMM_OBJECTIVE_B

  SUBROUTINE GMM_OBJECTIVE(d, k, n, alphas, means, icf, x, wishart_var, &
&   err) BIND(c)
    IMPLICIT NONE
    INTEGER :: d, k, n, ix, ik
    TYPE(WISHART) :: wishart_var
    REAL(kind=8), DIMENSION(*), INTENT(IN) :: alphas, means, icf, x
    REAL(kind=8), INTENT(OUT) :: err
    REAL(kind=8), DIMENSION(:), ALLOCATABLE :: qdiags, sum_qs, xcentered&
&   , qxcentered, main_term
    INTEGER :: icf_sz, id
    REAL :: const
    INTRINSIC LOG
    REAL(kind=8) :: slse
    REAL(kind=8) :: lse_alphas
    REAL(kind=8) :: result1
    const = -(n*d*0.5*LOG(2*3.1415926))
    icf_sz = d*(d+1)/2
    ALLOCATE(qdiags(d*k))
    ALLOCATE(sum_qs(k))
    ALLOCATE(xcentered(d))
    ALLOCATE(qxcentered(d))
    ALLOCATE(main_term(k))
    CALL PREPROCESS_QS(d, k, icf, sum_qs, qdiags)
    slse = 0.
    DO ix=1,n
      DO ik=1,k
        CALL SUBTRACT(d, x((ix-1)*d+1:ix*d), means((ik-1)*d+1:ik*d), &
&               xcentered)
        CALL QTIMESX(d, qdiags((ik-1)*d+1:ik*d), icf((ik-1)*icf_sz+d+1:&
&              ik*icf_sz), xcentered, qxcentered)
        result1 = SQNORM(d, qxcentered)
        main_term(ik) = alphas(ik) + sum_qs(ik) - 0.5*result1
      END DO
      result1 = LOG_SUM_EXP(k, main_term)
      slse = slse + result1
    END DO
    lse_alphas = LOG_SUM_EXP(k, alphas)
    result1 = LOG_WISHART_PRIOR(d, k, wishart_var, sum_qs, qdiags, icf)
    err = const + slse - n*lse_alphas + result1
    DEALLOCATE(qdiags)
    DEALLOCATE(sum_qs)
    DEALLOCATE(xcentered)
    DEALLOCATE(qxcentered)
    DEALLOCATE(main_term)
  END SUBROUTINE GMM_OBJECTIVE

END MODULE WISHART_MODULE_DIFF

