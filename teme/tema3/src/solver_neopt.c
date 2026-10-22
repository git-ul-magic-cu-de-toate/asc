#include "utils.h"

double* my_solver(int N, double *A, double* B) {
	double *C = (double*)calloc(N * N, sizeof(double));

	double *At = (double*)calloc(N * N, sizeof(double));
	double *Bt = (double*)calloc(N * N, sizeof(double));

	// Transpusa lui A
	for (int i = 0; i < N; i++) {
		for (int j = 0; j <= i; j++) {
			At[i * N + j] = A[j * N + i];
		}
	}

	// Transpusa lui B
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			Bt[i * N + j] = B[j * N + i];
		}
	}

	double *temp1 = (double*)calloc(N * N, sizeof(double));
	double *temp2 = (double*)calloc(N * N, sizeof(double));
	double *temp3 = (double*)calloc(N * N, sizeof(double));

	// At * B
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			for (int k = 0; k <= i; k++) {
				temp1[i * N + j] += At[i * N + k] * B[k * N + j];
			}
		}
	}

	// B * A
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			for (int k = 0; k <= j; k++) {
				temp2[i * N + j] += B[i * N + k] * A[k * N + j];
			}
		}
	}

	// temp1 + temp2
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			temp3[i * N + j] = temp1[i * N + j] + temp2[i * N + j];
		}
	}

	// temp3 * Bt
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			for (int k = 0; k < N; k++) {
				C[i * N + j] += temp3[i * N + k] * Bt[k * N + j];
			}
		}
	}

	free(At);
	free(Bt);
	free(temp1);
	free(temp2);
	free(temp3);

	return C;
}
