#include <iostream>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctime>
#include <sstream>
#include <string>
#include "test_map.hpp"
#include "gpu_hashtable.hpp"

using namespace std;

/*
Allocate CUDA memory only through glbGpuAllocator
cudaMalloc -> glbGpuAllocator->_cudaMalloc
cudaMallocManaged -> glbGpuAllocator->_cudaMallocManaged
cudaFree -> glbGpuAllocator->_cudaFree
*/

/**
 * Function constructor GpuHashTable
 * Performs init
 * Example on using wrapper allocators _cudaMalloc and _cudaFree
 */
GpuHashTable::GpuHashTable(int size) {
	glbGpuAllocator->_cudaMallocManaged((void **) &this->keys, size * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &this->values, size * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &this->fullSize, sizeof(int));

	this->fullSize[0] = size;
	this->hSize = 0;

	cudaMemset(this->keys, 0, size * sizeof(int));
	cudaMemset(this->values, 0, size * sizeof(int));
}

/**
 * Function desctructor GpuHashTable
 */
GpuHashTable::~GpuHashTable() {
	glbGpuAllocator->_cudaFree(keys);
	glbGpuAllocator->_cudaFree(values);
	glbGpuAllocator->_cudaFree(fullSize);
}

__global__ void InsertKeysKernel(int *client_keys, int *client_values, int *keys,
                                 int *values, int fullSize, int noThreads) {
    // get index of the key that is going to be added
    unsigned int i = threadIdx.x + blockDim.x * blockIdx.x;

	if (i >= noThreads)
		return;

	if (client_keys[i] == 0)
		return;

    // get hash index for this key
    unsigned int uintA = client_keys[i];

    // credits: https://stackoverflow.com/a/12996028/7883884 also took it
	// from my SDA laboratory from first year
    uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
    uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
    uintA = (uintA >> 16u) ^ uintA;

    unsigned int hashIdx = uintA % fullSize;

    // find an available spot to insert the key
	for (unsigned int j = hashIdx; j < fullSize; j++) {
		atomicCAS(&keys[j], 0, client_keys[i]);
		if (keys[j] == client_keys[i]) {
			atomicExch(&values[j], client_values[i]);
			return;
		}
	}

	for (unsigned int j = 0; j < hashIdx; j++) {
		atomicCAS(&keys[j], 0, client_keys[i]);
		if (keys[j] == client_keys[i]) {
			atomicExch(&values[j], client_values[i]);
			return;
		}
	}
}

/**
 * Function reshape
 * Performs resize of the hashtable based on load factor
 */
void GpuHashTable::reshape(int numBucketsReshape) {
	
	int *newKeys, *newValues;
	int blockSize = 256;
	int noBlocks = (this->fullSize[0] + blockSize - 1) / blockSize;
	int *wantedSize;
	int *noThreads;

	glbGpuAllocator->_cudaMallocManaged((void **) &newKeys, numBucketsReshape * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &newValues, numBucketsReshape * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &wantedSize, sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &noThreads, sizeof(int));

	cudaMemset(newKeys, 0, numBucketsReshape * sizeof(int));
	cudaMemset(newValues, 0, numBucketsReshape * sizeof(int));

	wantedSize[0] = numBucketsReshape;
	noThreads[0] = this->fullSize[0];

	InsertKeysKernel<<<noBlocks, blockSize>>>(this->keys, this->values, newKeys, newValues, wantedSize[0], noThreads[0]);
	cudaDeviceSynchronize();

	glbGpuAllocator->_cudaFree(this->keys);
	glbGpuAllocator->_cudaFree(this->values);
	glbGpuAllocator->_cudaFree(wantedSize);
	glbGpuAllocator->_cudaFree(noThreads);

	this->keys = newKeys;
	this->values = newValues;
	this->fullSize[0] = numBucketsReshape;

	return;
}

/**
 * Function insertBatch
 * Inserts a batch of key:value, using GPU and wrapper allocators
 */
bool GpuHashTable::insertBatch(int *keys, int* values, int numKeys) {
	int blockSize = 256;
	int noBlocks = (numKeys + blockSize - 1) / blockSize;
	int *noThreads;
	
	// add new size of the insertion to the hashtable
	this->hSize += numKeys;

	float loadFactor = this->hSize * sizeof(int) * 2.f / glbGpuAllocator->_used();
	if (loadFactor > 0.8)
		reshape(1.25 * this->hSize);

	int *client_values, *client_keys;

	glbGpuAllocator->_cudaMallocManaged((void **) &client_keys, numKeys * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &client_values, numKeys * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &noThreads, sizeof(int));

	// copy data from cpu to gpu
	cudaMemcpy(client_keys, keys, numKeys * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(client_values, values, numKeys * sizeof(int), cudaMemcpyHostToDevice);

	noThreads[0] = numKeys;

	// call global kernel
	InsertKeysKernel<<<noBlocks, blockSize>>>(client_keys, client_values, this->keys, this->values, this->fullSize[0], noThreads[0]);
	cudaDeviceSynchronize();


	// free memory for global_kernel
	glbGpuAllocator->_cudaFree(client_keys);
	glbGpuAllocator->_cudaFree(client_values);
	glbGpuAllocator->_cudaFree(noThreads);

	return true;
}

__global__ void GetKeysKernel(int *client_keys, int *client_values, int *keys, int *values, int fullSize, int noThreads) {
    // get index of the key that is going to be added
    unsigned int i = threadIdx.x + blockDim.x * blockIdx.x;

	if (i >= noThreads)
		return;

	if (client_keys[i] == 0) {
		client_values[i] = 0;
		return;
	}

    // get the key received as input on this thread
    unsigned int key = client_keys[i];

    // get hash index for this key
    unsigned int uintA = key;

    // Credits: https://stackoverflow.com/a/12996028/7883884 taken from my SDA
	// lab from first year
    uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
    uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
    uintA = (uintA >> 16u) ^ uintA;

	unsigned int hashIdx = uintA % fullSize;

    // find an available spot to insert the key
	for (unsigned int j = hashIdx; j < fullSize; j++) {
		if (keys[j] == client_keys[i]) {
			client_values[i] = values[j];
			return;
		}
	}

	for (unsigned int j = 0; j < hashIdx; j++) {
		if (keys[j] == client_keys[i]) {
			client_values[i] = values[j];
			return;
		}
	}

	client_values[i] = 0;
}

/**
 * Function getBatch
 * Gets a batch of key:value, using GPU
 */
int* GpuHashTable::getBatch(int* keys, int numKeys) {
	int blockSize = 256;
	int noBlocks = (numKeys + blockSize - 1) / blockSize;
	int *client_keys, *client_values;
	int *noThreads;

	// alloc memory on gpu for keys and values
	glbGpuAllocator->_cudaMallocManaged((void **) &client_keys, numKeys * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &client_values, numKeys * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &noThreads, sizeof(int));

	// copy keys to GPU
	cudaMemcpy(client_keys, keys, numKeys * sizeof(int), cudaMemcpyHostToDevice);

	noThreads[0] = numKeys;

	GetKeysKernel<<<noBlocks, blockSize>>>(client_keys, client_values, this->keys, this->values, this->fullSize[0], noThreads[0]);
	cudaDeviceSynchronize();

	// copy values from gpu to cpu
	glbGpuAllocator->_cudaFree(client_keys);
	glbGpuAllocator->_cudaFree(noThreads);

	return client_values;
}
