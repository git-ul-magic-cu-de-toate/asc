#include <stdio.h>
#include <stdlib.h>
/*
 * Add your unoptimized implementation here
 */
double* my_solver(int N, double *A, double* B) {
	printf("NEOPT SOLVER\n");

	// calculates A * B
	double *AB = (double *)calloc(N * N, sizeof(double));
	for (int i = 0; i < N; i++)
		for (int j = 0; j < N; j++)
			for (int k = i; k < N; k++)
				AB[i * N + j] += A[i * N + k] * B[k * N + j];

	// calculates AB * A_t
	double *ABA_t = (double *)calloc(N * N, sizeof(double));
	for (int i = 0; i < N; i++)
		for (int j = 0; j < N; j++)
			for (int k = 0; k < N; k++)
				ABA_t[i * N + j] += AB[i * N + k] * A[j * N + k];

	// calculates B_t
	double *B_t = (double *)calloc(N * N, sizeof(double));
	for (int i = 0; i < N; i++)
		for (int j = 0; j < N; j++)
			B_t[j * N + i] = B[i * N + j];

	// calculates B_t x B_t
	double *result = (double *)calloc(N * N, sizeof(double));
	for (int i = 0; i < N; i++)
		for (int j = 0; j < N; j++)
			for (int k = 0; k < N; k++)
				result[i * N + j] += B_t[i * N + k] * B_t[k * N + j];

	// calculates A x B x A_t + B_t x B_t and stores it into result
	for (int i = 0; i < N; i++)
		for (int j = 0; j < N; j++)
			result[i * N + j] += ABA_t[i * N + j];

	free(AB);
	free(ABA_t);
	free(B_t);

	return result;
}
