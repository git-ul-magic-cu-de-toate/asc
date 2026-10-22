/*
 * Tema 2 ASC
 * 2023 Spring
 */
#include "utils.h"
#include <cblas.h>
#include "string.h"

#define SCALAR_UNIT 1.0

/* 
 * Add your BLAS implementation here
 */
double* my_solver(int N, double *A, double *B) {
	printf("BLAS SOLVER\n");

	double *C = malloc(n * n * sizeof(**A));
	if (!C)
		printf("[ERROR] Can't allocate liniar matrix!\n");

	// copies B to C for calculating A * B * A^t
	memcpy(C, B, N * N * sizeof(*C));

	// calculates A * B in C
	cblas_dtrmm(CblasRowMajor, CblasLeft, CblasUpper, CblasNoTrans,
				CblasNonUnit, N, N, SCALAR_UNIT, A, N, C, N);

	// calculates C * A^t in C
	cblas_dtrmm(CblasRowMajor, CblasRight, CblasUpper, CblasTrans,
				CblasNonUnit, N, N, SCALAR_UNIT, A, N, C, N);

	// calculates B^T x B^T + C
	cblas_dgemm(CblasRowMajor, CblasTrans, CblasTrans, N, N, N,
				SCALAR_UNIT, B, N, B, N, SCALAR_UNIT, C, N);

	return C;
}
