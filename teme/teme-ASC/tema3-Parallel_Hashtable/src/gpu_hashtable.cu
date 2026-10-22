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

unsigned int hashFunctionInt(void *a)
{
	/*
	 * Credits: https://stackoverflow.com/a/12996028/7883884
	 */
	unsigned int uintA = *((unsigned int *)a);

	uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
	uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
	uintA = (uintA >> 16u) ^ uintA;
	return uintA;
}

/**
 * Function constructor GpuHashTable
 * Performs init
 * Example on using wrapper allocators _cudaMalloc and _cudaFree
 */
GpuHashTable::GpuHashTable(int size) {
	glbGpuAllocator->_cudaMallocManaged((void **) &this->keys, size * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &this->values, size * sizeof(int));

	this->fullSize = size;
	this->hSize = 0;

	cudaMemset(this->keys, 0, size);
	cudaMemset(this->values, 0, size);

	cudaDeviceSynchronize();
}

/**
 * Function desctructor GpuHashTable
 */
GpuHashTable::~GpuHashTable() {
	glbGpuAllocator->_cudaFree(keys);
	glbGpuAllocator->_cudaFree(values);
}

__global__ void InsertKeysKernel(int *client_keys, int *client_values, int *keys,
                                 int *values, int fullSize) {
    // get index of the key that is going to be added
    unsigned int i = threadIdx.x + blockDim.x * blockIdx.x;

    // get hash index for this key
    unsigned int uintA = client_keys[i];

    // credits: https://stackoverflow.com/a/12996028/7883884
    uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
    uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
    uintA = (uintA >> 16u) ^ uintA;

    unsigned int hashIdx = uintA % fullSize;

    // check if key already exists and update value if so
    for (unsigned int j = 0; j < fullSize; j++) {
        if (keys[j] == client_keys[i]) {
            atomicExch(&values[j], client_values[i]);
            return;
        }
    }

    // find an available spot to insert the key
	for (unsigned int j = hashIdx; j < fullSize; j++) {
		int key = atomicCAS(&keys[j], 0, client_keys[i]);
		if (key == 0) {
			atomicExch(&values[j], client_values[i]);
			return;
		}
	}

	for (unsigned int j = 0; j < hashIdx; j++) {
		int key = atomicCAS(&keys[j], 0, client_keys[i]);
		if (key == 0) {
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
	int noBlocks = 1, blockSize = this->fullSize;

	glbGpuAllocator->_cudaMallocManaged((void **) &newKeys, numBucketsReshape * sizeof(int));
	glbGpuAllocator->_cudaMallocManaged((void **) &newValues, numBucketsReshape * sizeof(int));

	cudaMemset(newKeys, 0, numBucketsReshape);
	cudaMemset(newValues, 0, numBucketsReshape);

	cudaDeviceSynchronize();

	InsertKeysKernel<<<noBlocks, blockSize>>>(this->keys, this->values, newKeys, newValues, numBucketsReshape);
	cudaDeviceSynchronize();

	glbGpuAllocator->_cudaFree(this->keys);
	glbGpuAllocator->_cudaFree(this->values);

	cudaDeviceSynchronize();

	this->keys = newKeys;
	this->values = newValues;
	this->fullSize = numBucketsReshape;

	return;
}

/**
 * Function insertBatch
 * Inserts a batch of key:value, using GPU and wrapper allocators
 */
bool GpuHashTable::insertBatch(int *keys, int* values, int numKeys) {
	int noBlocks = 1;
	int blockSize = numKeys;
	
	// add new size of the insertion to the hashtable
	this->hSize += numKeys;

	// printf("this is size before insertion %d and fullsize %d\n", this->hSize, this->fullSize);
	
	// float loadFactor = this->hSize * sizeof(int) * 2.f / glbGpuAllocator->_used();
	float loadFactor = this->hSize / this->fullSize;
	if (loadFactor > 0.9) {
		reshape(1.2 * this->hSize);
	}

	// for (int i = 0; i < numKeys; i++) {
	// 	printf("The key is: %d the value is %d\n", keys[i], values[i]);
	// }
	// printf("\n\n");

	// for (int i = 0; i < this->fullSize; i++) {
	// 	printf("The key is: %d the value is %d\n", this->keys[i], this->values[i]);
	// }
	// printf("\n\n");

	// alloc memory for global_kernel
	int *client_values, *client_keys;

	glbGpuAllocator->_cudaMalloc((void **) &client_keys, numKeys * sizeof(int));
	glbGpuAllocator->_cudaMalloc((void **) &client_values, numKeys * sizeof(int));

	// copy data from cpu to gpu
	cudaMemcpy(client_keys, keys, numKeys * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(client_values, values, numKeys * sizeof(int), cudaMemcpyHostToDevice);
	cudaDeviceSynchronize();

	// call global kernel
	InsertKeysKernel<<<noBlocks, blockSize>>>(client_keys, client_values, this->keys, this->values, this->fullSize);
	cudaDeviceSynchronize();

	// std::cout << "KEYS ARE INSERTED NOW: \n";
	// for (int i = 0; i < this->fullSize; i++) {
	// 	printf("The key is: %d the value is %d\n", this->keys[i], this->values[i]);
	// }
	// printf("\n\n");

	// printf("this is size AFTER insertion %d and fullsize %d\n", this->hSize, this->fullSize);

	// free memory for global_kernel
	glbGpuAllocator->_cudaFree(client_keys);
	glbGpuAllocator->_cudaFree(client_values);

	return true;
}

__global__ void GetKeysKernel(int *client_keys, int *client_values, int *keys, int *values, int fullSize) {
    // get index of the key that is going to be added
    unsigned int i = threadIdx.x + blockDim.x * blockIdx.x;

    // get the key received as input on this thread
    unsigned int key = client_keys[i];

    // get hash index for this key
    unsigned int uintA = key;

    // Credits: https://stackoverflow.com/a/12996028/7883884
    uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
    uintA = ((uintA >> 16u) ^ uintA) * 0x45d9f3b;
    uintA = (uintA >> 16u) ^ uintA;

    // Traverse the keys array from 0 to fullSize to find the value for the key
    for (unsigned int j = 0; j < fullSize; j++) {
        if (keys[j] != 0 && key == keys[j]) {
            client_values[i] = values[j];
            return;
        }
    }

    // unsigned int hashIdx = uintA % fullSize;

    // // get the value corresponding to the key from the hashtable's keys
    // for (unsigned int j = hashIdx; j < fullSize; j++) {
    //     if (keys[j] != 0 && key == keys[j]) {
    //         client_values[i] = values[j];
    //         return;
    //     }
    // }

	// for (unsigned int j = 0; j < hashIdx; j++) {
    //     if (keys[j] != 0 && key == keys[j]) {
    //         client_values[i] = values[j];
    //         return;
    //     }
    // }
}

/**
 * Function getBatch
 * Gets a batch of key:value, using GPU
 */
int* GpuHashTable::getBatch(int* keys, int numKeys) {
	int noBlocks = 1;
	int blockSize = numKeys;
	int *client_keys, *client_values;
	int *gotValues = NULL;

	// alloc memory on cpu for values that are going to be extracted
	// from hashtable
	gotValues = (int *) malloc(sizeof(int) * numKeys);
	DIE(NULL == values, "couldn't alloc values");

	// alloc memory on gpu for keys and values
	glbGpuAllocator->_cudaMalloc((void **) &client_keys, numKeys * sizeof(int));
	glbGpuAllocator->_cudaMalloc((void **) &client_values, numKeys * sizeof(int));

	// copy keys to GPU
	cudaMemcpy(client_keys, keys, numKeys * sizeof(int), cudaMemcpyHostToDevice);
	cudaDeviceSynchronize();

	// for (int i = 0; i < this->fullSize; i++) {
	// 	std::cout << this->keys[i] << " " << this->values[i] << "\n";
	// }
	// std::cout << "THESE ARE THE VALUES AND KEYS BRO, GET THEM ALL: \n";

	// call kernel to get the keys
	GetKeysKernel<<<noBlocks, blockSize>>>(client_keys, client_values, this->keys, this->values, this->fullSize);
	cudaDeviceSynchronize();

	// copy values from gpu to cpu
	cudaMemcpy(gotValues, client_values, sizeof(int) * numKeys, cudaMemcpyDeviceToHost);

	glbGpuAllocator->_cudaFree(client_keys);
	glbGpuAllocator->_cudaFree(client_values);

	return gotValues;
}