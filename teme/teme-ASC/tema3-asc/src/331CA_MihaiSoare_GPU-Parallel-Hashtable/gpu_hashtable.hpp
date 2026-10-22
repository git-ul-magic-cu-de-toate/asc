#ifndef _HASHCPU_
#define _HASHCPU_

#define HASHTABLE_LOADFACTOR 0.8
#define HASHTABLE_RESHAPE 1.25
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

		~GpuHashTable();
};

#endif
