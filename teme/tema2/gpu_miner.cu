#include <stdio.h>
#include <stdint.h>
#include "../include/utils.cuh"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

#define THREADS_PER_BLOCK 512
#define NUM_BLOCKS 256

__device__ const uint64_t thread_num = THREADS_PER_BLOCK * NUM_BLOCKS;
__device__ double ratio = MAX_NONCE / thread_num;

// Implement function to search for all nonces from 1 through MAX_NONCE (inclusive) using CUDA Threads
__global__ void findNonce(BYTE *d_block_content, BYTE *d_block_hash, uint64_t *d_nonce, BYTE *d_difficulty) {
	// Temporary storage for block content with nonce
	BYTE block_content_with_nonce[BLOCK_SIZE];

	// Copy block content to temporary storage
	for (size_t i = 0; i < BLOCK_SIZE / 4; ++i) {
    	((uint32_t*)block_content_with_nonce)[i] = ((uint32_t*)d_block_content)[i];
	}
	
	// Temporary variables
	char nonce_string[NONCE_SIZE];
	BYTE block_hash[SHA256_BLOCK_SIZE];

	// Calculate range of nonces for this thread
	const uint64_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    const uint64_t start = tid * ratio;
    const uint64_t end = min((tid + 1) * ratio, MAX_NONCE);

	// Iterate over the range of nonces
	for (uint64_t i = start; i <= end && *d_nonce == 0; i++) {
		// Convert nonce to string
		intToString(i, nonce_string);

		// Append nonce to block content
		size_t nonce_offset = d_strlen((const char *) d_block_content);
		d_strcpy((char*) block_content_with_nonce + nonce_offset, nonce_string);
		
		// Calculate hash of block content with nonce
		apply_sha256(block_content_with_nonce, d_strlen((const char *) block_content_with_nonce), block_hash, 1);

		// Check if hash meets difficulty criteria
		if (compare_hashes(block_hash, d_difficulty) <= 0) {
			*d_nonce = i; // Store nonce
			d_strcpy((char *) d_block_hash, (char *) block_hash); // Store hash
			break; // Exit loop
		}
	}
}

int main(int argc, char **argv) {
	BYTE hashed_tx1[SHA256_HASH_SIZE], hashed_tx2[SHA256_HASH_SIZE], hashed_tx3[SHA256_HASH_SIZE], hashed_tx4[SHA256_HASH_SIZE],
			tx12[SHA256_HASH_SIZE * 2], tx34[SHA256_HASH_SIZE * 2], hashed_tx12[SHA256_HASH_SIZE], hashed_tx34[SHA256_HASH_SIZE],
			tx1234[SHA256_HASH_SIZE * 2], top_hash[SHA256_HASH_SIZE], block_content[BLOCK_SIZE];
	BYTE block_hash[SHA256_HASH_SIZE] = "0000000000000000000000000000000000000000000000000000000000000000";
	uint64_t nonce = 0;
	size_t current_length;

	// Top hash
	apply_sha256(tx1, strlen((const char*)tx1), hashed_tx1, 1);
	apply_sha256(tx2, strlen((const char*)tx2), hashed_tx2, 1);
	apply_sha256(tx3, strlen((const char*)tx3), hashed_tx3, 1);
	apply_sha256(tx4, strlen((const char*)tx4), hashed_tx4, 1);
	strcpy((char *)tx12, (const char *)hashed_tx1);
	strcat((char *)tx12, (const char *)hashed_tx2);
	apply_sha256(tx12, strlen((const char*)tx12), hashed_tx12, 1);
	strcpy((char *)tx34, (const char *)hashed_tx3);
	strcat((char *)tx34, (const char *)hashed_tx4);
	apply_sha256(tx34, strlen((const char*)tx34), hashed_tx34, 1);
	strcpy((char *)tx1234, (const char *)hashed_tx12);
	strcat((char *)tx1234, (const char *)hashed_tx34);
	apply_sha256(tx1234, strlen((const char*)tx34), top_hash, 1);

	// prev_block_hash + top_hash
	strcpy((char*)block_content, (const char*)prev_block_hash);
	strcat((char*)block_content, (const char*)top_hash);
	current_length = strlen((char*) block_content);

	cudaEvent_t start, stop;
	startTiming(&start, &stop);

	// Device memory allocation

	BYTE *d_block_content, *d_block_hash, *d_difficulty;
	uint64_t *d_nonce;

	cudaMalloc(&d_block_content, BLOCK_SIZE);
	cudaMalloc(&d_block_hash, SHA256_HASH_SIZE);
	cudaMalloc(&d_difficulty, SHA256_HASH_SIZE);
	cudaMalloc(&d_nonce, sizeof(uint64_t));

	// Copy data to device

	cudaMemcpy(d_block_content, block_content, current_length, cudaMemcpyHostToDevice);
	cudaMemcpy(d_difficulty, DIFFICULTY, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);

	// Kernel launch

	findNonce<<<NUM_BLOCKS, THREADS_PER_BLOCK>>>(d_block_content, d_block_hash, d_nonce, d_difficulty);

	// Wait for kernel to finish

	cudaDeviceSynchronize();

	// Copy results back to host

	cudaMemcpy(block_hash, d_block_hash, SHA256_HASH_SIZE, cudaMemcpyDeviceToHost);
    cudaMemcpy(&nonce, d_nonce, sizeof(uint64_t), cudaMemcpyDeviceToHost);

	// Free device memory

	cudaFree(d_block_content);
	cudaFree(d_block_hash);
	cudaFree(d_difficulty);
	cudaFree(d_nonce);

	float seconds = stopTiming(&start, &stop);

	printResult(block_hash, nonce, seconds);

	return 0;
}