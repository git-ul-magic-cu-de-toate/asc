#ifndef _HASHCPU_
#define _HASHCPU_

#define LOADFACTORMIN = 0.5f
#define LOADFACTORMAX = 1.0f

/**
 * Class GpuHashTable to implement functions
 */
class GpuHashTable
{
	public:
		GpuHashTable(int size);
		void reshape(int sizeReshape);

		bool insertBatch(int *keys, int* values, int numKeys);
		int* getBatch(int* key, int numItems);

		
		int *keys;
		int *values;
		unsigned int hSize;
		unsigned int fullSize;

		unsigned int hashFunctionInt(void *a);
		~GpuHashTable();
};

#endif
