"""
Computer Systems Architecture - Lab 3

Threadpool assignment:
    Use a pool of threads to search for a DNA sequence in a list of DNA samples
"""
from concurrent.futures import ThreadPoolExecutor as ThreadPool
import random

random.seed(random.randint(1, 100000))

# generate many DNA samples, need to be large, otherwise there's no point of a concurrent program
dna_samples = []  # TODO 1.

SEARCH_SEQUENCE = []  # TODO 2.


def search_dna_sequence(sequence, sample):
    return sequence in sample


def thread_job(sample_index):
    """
    Each thread searches the sequence in a given sample
    """
    if search_dna_sequence(SEARCH_SEQUENCE, dna_samples[sample_index]):
        return "DNA sequence found in sample {}".format(sample_index)
    return "DNA sequence not found in sample {}".format(sample_index)


if __name__ == "__main__":
    string = ''
    for i in range(0, 13):
        for i in range(0, 25):
            string += random.choice("ATGC")
        dna_samples.append(string)

    search = ['']
    for i in range(0, 2):
        search[0] += random.choice("ATGC")

    SEARCH_SEQUENCE = search[0]
    thread_pool = ThreadPool(max_workers= 30)

    with thread_pool as executor:
        results = executor.map(thread_job, range(0, len(dna_samples)))

    for result in results:
        print(result)
