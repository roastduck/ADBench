MODULE Wishart_Module
    TYPE :: Wishart
        REAL(kind=8) :: gamma
        INTEGER :: m
    END TYPE Wishart

    CONTAINS

    FUNCTION arr_max(n, x)
        INTEGER :: n, i
        REAL(kind=8), DIMENSION(n) :: x
        REAL(kind=8) :: arr_max
        arr_max = x(1)
        DO i = 2, n
            IF (arr_max < x(i)) THEN
                arr_max = x(i)
            END IF
        END DO
    END FUNCTION arr_max



    FUNCTION sqnorm(n, x)
        INTEGER :: n, i
        REAL(kind=8), DIMENSION(n) :: x
        REAL(kind=8) :: sqnorm
        sqnorm = x(1) * x(1)
        DO i = 2, n
            sqnorm = sqnorm + x(i) * x(i)
        END DO
    END FUNCTION sqnorm



    SUBROUTINE subtract(d, x, y, out)
        INTEGER :: d, id
        REAL(kind=8), DIMENSION(d) :: x, y, out
        DO id = 1, d
            out(id) = x(id) - y(id)
        END DO
    END SUBROUTINE subtract



    FUNCTION log_sum_exp(n, x)
        INTEGER :: n, i
        REAL(kind=8), DIMENSION(n) :: x
        REAL(kind=8) :: log_sum_exp, mx, semx
        mx = arr_max(n, x)
        semx = 0.0
        DO i = 1, n
            semx = semx + EXP(x(i) - mx)
        END DO
        log_sum_exp = LOG(semx) + mx
    END FUNCTION log_sum_exp



    FUNCTION log_gamma_distrib(a, p)
        INTEGER :: p, j
        REAL(kind=8) :: a, out
        out = 0.25 * p * (p - 1) * LOG(3.1415926)
        DO j = 1, p
            out = out + LGAMMA(a + 0.5 * (1 - j))
        END DO
        log_gamma_distrib = out
    END FUNCTION log_gamma_distrib



    FUNCTION log_wishart_prior(p, k, wishart_var, sum_qs, Qdiags, icf)
        INTEGER :: p, k, ik
        TYPE(Wishart) :: wishart_var
        REAL(kind=8), DIMENSION(*), INTENT(IN) :: sum_qs, Qdiags, icf
        REAL(kind=8) :: log_wishart_prior, C, out, frobenius
        INTEGER :: n, icf_sz, id
        n = p + wishart_var%m + 1
        icf_sz = p * (p + 1) / 2
        C = n * p * (LOG(wishart_var%gamma) - 0.5 * LOG(2.0)) - log_gamma_distrib(0.5 * n, p)
        out = 0
        DO ik = 1, k
            frobenius = sqnorm(p, Qdiags((ik-1)*p+1:ik*p)) + sqnorm(icf_sz - p, icf((ik-1)*icf_sz+p+1:(ik*icf_sz)))
            out = out + 0.5 * wishart_var%gamma * wishart_var%gamma * (frobenius) - wishart_var%m * sum_qs(ik)
        END DO
        log_wishart_prior = out - k * C
    END FUNCTION log_wishart_prior



    SUBROUTINE preprocess_qs(d, k, icf, sum_qs, Qdiags)
        INTEGER :: d, k, ik, id
        REAL(kind=8), DIMENSION(*), INTENT(IN) :: icf
        REAL(kind=8), DIMENSION(*), INTENT(OUT) :: sum_qs, Qdiags
        INTEGER :: icf_sz
        icf_sz = d * (d + 1) / 2
        DO ik = 1, k
            sum_qs(ik) = 0.
            DO id = 1, d
                sum_qs(ik) = sum_qs(ik) + icf((ik-1)*icf_sz+id)
                Qdiags((ik-1)*d+id) = EXP(icf((ik-1)*icf_sz+id))
            END DO
        END DO
    END SUBROUTINE preprocess_qs



    SUBROUTINE Qtimesx(d, Qdiag, ltri, x, out)
        INTEGER :: d, i, j
        REAL(kind=8), DIMENSION(*), INTENT(IN) :: Qdiag, ltri, x
        REAL(kind=8), DIMENSION(*), INTENT(OUT) :: out
        DO i = 1, d
            out(i) = Qdiag(i) * x(i)
        END DO
        Lparamsidx = 1
        DO i = 1, d
            DO j = i + 1, d
                out(j) = out(j) + ltri(Lparamsidx) * x(i)
                Lparamsidx = Lparamsidx + 1
            END DO
        END DO
    END SUBROUTINE Qtimesx



    SUBROUTINE gmm_objective(d, k, n, alphas, means, icf, x, wishart_var, err)
        INTEGER :: d, k, n, ix, ik
        TYPE(Wishart) :: wishart_var
        REAL(kind=8), DIMENSION(*), INTENT(IN) :: alphas, means, icf, x
        REAL(kind=8), INTENT(OUT) :: err
        REAL(kind=8), DIMENSION(:), ALLOCATABLE :: Qdiags, sum_qs, xcentered, Qxcentered, main_term
        INTEGER :: icf_sz, id
        REAL :: CONST
        CONST = -n * d * 0.5 * LOG(2 * 3.1415926)
        icf_sz = d * (d + 1) / 2
        ALLOCATE(Qdiags(d*k), sum_qs(k), xcentered(d), Qxcentered(d), main_term(k))
        CALL preprocess_qs(d, k, icf, sum_qs, Qdiags)
        slse = 0.
!$OMP PARALLEL DO SHARED(n, k, d, x, means, xcentered, Qdiags, icf, Qxcentered, main_term, alphas, sum_qs, icf_sz), PRIVATE(ix, ik) &
!$OMP&reduction(+:slse)
        DO ix = 1, n
            DO ik = 1, k
                CALL subtract(d, x((ix-1)*d+1:ix*d), means((ik-1)*d+1:ik*d), xcentered)
                CALL Qtimesx(d, Qdiags((ik-1)*d+1:ik*d), icf((ik-1)*icf_sz+d+1:(ik*icf_sz)), xcentered, Qxcentered)
                main_term(ik) = alphas(ik) + sum_qs(ik) - 0.5 * sqnorm(d, Qxcentered)
            END DO
            slse = slse + log_sum_exp(k, main_term)
        END DO
        lse_alphas = log_sum_exp(k, alphas)
        err = CONST + slse - n * lse_alphas + log_wishart_prior(d, k, wishart_var, sum_qs, Qdiags, icf)
        DEALLOCATE(Qdiags, sum_qs, xcentered, Qxcentered, main_term)
    END SUBROUTINE gmm_objective

END MODULE Wishart_Module
