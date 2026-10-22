#include "utils.h"
#include <cblas.h>
#include <stdlib.h>

double* my_solver(int N, double *A, double* B) {
	double size = N * N * sizeof(double);
    double *C = (double*)malloc(size);

    double *B_copy = (double*)malloc(size);
	double *B_copy2 = (double*)malloc(size);

    cblas_dcopy(N * N, B, 1, B_copy, 1);
    cblas_dcopy(N * N, B, 1, B_copy2, 1);

    double *temp = (double*)malloc(size);

    // At * B
    cblas_dtrmm(CblasRowMajor, CblasLeft, CblasUpper, CblasTrans, CblasNonUnit, N, N, 1.0, A, N, B, N);

    // B * A
    cblas_dtrmm(CblasRowMajor, CblasRight, CblasUpper, CblasNoTrans, CblasNonUnit, N, N, 1.0, A, N, B_copy, N);

    // (At * B) + (B * A)
    for (int i = 0; i < N * N; i++) {
        temp[i] = B_copy[i] + B[i];
    }

    // temp * Bt
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasTrans, N, N, N, 1.0, temp, N, B_copy2, N, 0.0, C, N);

	free(B_copy);
	free(B_copy2);
	free(temp);

    return C;
}
