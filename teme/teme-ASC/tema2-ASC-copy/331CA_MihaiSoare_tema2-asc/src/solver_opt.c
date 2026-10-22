/*
 * Tema 2 ASC
 * 2023 Spring
 */
#include "utils.h"

/*
 * Add your optimized implementation here
 */
double* my_solver(int N, double *A, double* B) {
	printf("OPT SOLVER\n");

	register int i = 0, j = 0, k = 0;

	// calculates A * B
	double *AB = (double *)calloc(N * N, sizeof(double));
	for (i = 0; i < N; i++) {
		register double *AB_ptr = AB + i * N;

		for (j = 0; j < N; j++, AB_ptr++) {
			register double sum = 0.0;

			register double *A_ptr = A + i * N + i;
			for (k = i; k < N; k++, A_ptr++) {
				sum += (*A_ptr) * B[k * N + j];
				// sum += *B_ptr * *A_ptr;
			}
			*AB_ptr = sum;
		}
	}


	// calculates AB * A_t
	double *ABA_t = (double *)calloc(N * N, sizeof(double));
	for (i = 0; i < N; i++) {
		register double *ABAt_ptr = ABA_t + i * N;
		for (j = 0; j < N; j++, ABAt_ptr++ ) {
			register double sum = 0.0;

			register double *AB_ptr = AB + i * N;
			register double *A_ptr = A + j * N;
			for (k = 0; k < N; k++, AB_ptr++, A_ptr++) {
				sum += (*AB_ptr) * (*A_ptr);
			}
			*ABAt_ptr = sum;
		}
	}

	// calculates B_t
	double *B_t = (double *)calloc(N * N, sizeof(double));
	for (i = 0; i < N; i++)
		for (j = 0; j < N; j++)
			B_t[j * N + i] = B[i * N + j];

	// calculates B_t x B_t
	double *result = (double *)calloc(N * N, sizeof(double));
	for (i = 0; i < N; i++) {
		register double *result_ptr = result + i * N;
		for (j = 0; j < N; j++, result_ptr++) {
			register double sum = 0.0;

			register double *Bt_ptr = B_t + i * N;
			for (k = 0; k < N; k++, Bt_ptr++) {
				sum += (*Bt_ptr) * B_t[k * N + j];
			}
			*result_ptr = sum;
		}
	}

	// calculates A x B x A_t + B_t x B_t and stores it into result
	register int N2_limit = N * N;
	register double *result_ptr = result;
	register double *ABAt_ptr = ABA_t;
	for (i = 0; i < N2_limit; i++, ABAt_ptr++, result_ptr++)
			*result_ptr += *ABAt_ptr;

	free(AB);
	free(ABA_t);
	free(B_t);

	return result;
}

