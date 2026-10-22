#include "utils.h"

double* my_solver(int N, double *A, double* B) {
	register int size = N * N * sizeof(double);
	double *C = malloc(size);
	double *At = malloc(size);
	double *Bt = malloc(size);

	// Transpusa lui A si B
	for (register int i = 0; i < N; ++i) {
		for (register int j = 0; j <= i; ++j) {
			At[i * N + j] = A[j * N + i];
		}
		for (register int j = 0; j < N; ++j) {
			Bt[i * N + j] = B[j * N + i];
		}
	}

	double *temp1 = malloc(size);

	// At * B
	for (register int i = 0; i < N; ++i) {
		register double *orig_at = &At[i * N + 0];
		for (register int j = 0; j < N; ++j) {
			register double *at_ptr = orig_at;
			register double *b_ptr = &B[j];
			register double sum = 0;
			for (register int k = 0; k <= i; ++k) {
				sum += *at_ptr * *b_ptr;
				at_ptr++;
				b_ptr += N;
			}
			temp1[i * N + j] = sum;
		}
	}

	double *temp2 = malloc(size);

	// B * A
	for (register int i = 0; i < N; ++i) {
		register double *orig_b = &B[i * N + 0];
		for (register int j = 0; j < N; ++j) {
			register double *b_ptr = orig_b;
			register double *a_ptr = &A[j];
			register double sum = 0;
			for (register int k = 0; k <= j; ++k) {
				sum += *b_ptr * *a_ptr;
				b_ptr++;
				a_ptr += N;
			}
			temp2[i * N + j] = sum;
		}
	}

	double *temp3 = malloc(size);

	// temp1 + temp2
	for (register int i = 0; i < N; ++i) {
		for (register int j = 0; j < N; ++j) {
			temp3[i * N + j] = temp1[i * N + j] + temp2[i * N + j];
		}
	}

	// temp3 * Bt
	for (register int i = 0; i < N; ++i) {
		register double *orig_temp3 = &temp3[i * N + 0];
		for (register int j = 0; j < N; ++j) {
			register double *temp3_ptr = orig_temp3;
			register double *bt_ptr = &Bt[j];
			register double sum = 0;
			for (register int k = 0; k < N; ++k) {
				sum += *temp3_ptr * *bt_ptr;
				temp3_ptr++;
				bt_ptr += N;
			}
			C[i * N + j] = sum;
		}
	}

	free(At);
	free(Bt);
	free(temp1);
	free(temp2);
	free(temp3);

	return C;
}
