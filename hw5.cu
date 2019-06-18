/*
Name: John Stephenson
BlazerId: johnds39
Course Section: CS 432
Homework #: 5
*/

#include <cstdlib>
#include <cstdio>
#include <iostream>

using namespace std;

const int ALIVE = 1;
const int DEAD = 0;

/* prints the table passed into the the function and its generation */
void printTable(int* table, int gen, int N2){
	cout << "Generation " << gen << ":\n";
	for (int i = 0; i < N2; i++) {
		for (int j = 0; j < N2; j++) {
			cout << table[N2 * i + j] << " ";
		}
		cout << "\n";
	}
}

/* modifies the nextGen table to represent the next generation of The Game of Life */
__global__
void nextGeneration(int* table, int* nextGen, int N2) {

	int j = blockDim.x * blockIdx.x + threadIdx.x + 1;
	
	for (int i = 1; i < N2-1; i++){
		if (j < N2-1) {
			int localChange = 0;
			int neighbors = 0;
			neighbors += table[N2 * (i-1) + j];
			neighbors += table[N2 * (i-1) + (j-1)];
			neighbors += table[N2 * (i-1) + (j+1)];
			neighbors += table[N2 * (i+1) + j];
			neighbors += table[N2 * (i+1) + (j-1)];
			neighbors += table[N2 * (i+1) + (j+1)];
			neighbors += table[N2 * i + (j+1)];
			neighbors += table[N2 * i + (j-1)];
	
			if (table[N2 * i + j] == DEAD && neighbors == 3) {
				nextGen[N2 * i + j] = ALIVE;
				localChange = 1;
			}
	
			if (neighbors <= 1 || neighbors >= 4) {
				if (table[N2 * i + j] == ALIVE) {
					nextGen[N2 * i + j] = DEAD;
					localChange = 1;
				}
			}

			/* this is used to make sure the two tables stay up to date with each other over the generations since they are being swapped after each iteration */
			if(localChange == 0) {
				nextGen[N2 * i + j] = table[N2 * i + j];
			}
	
		}
	}
}

/* initializes a table according to the size provided by the user with each element being randomized to be alive or dead */
void initTable(int* table, int N2){
	for (int i = 0; i < N2; i++) {
		for (int j = 0; j < N2; j++) {
			if (i == N2 - 1 || j == N2 - 1 || i == 0 || j == 0) {
				table[N2 * i + j] = DEAD;
			}
			else {
				if (rand() % 2 < 1) {
					table[N2 * i + j] = ALIVE;
				}
				else {
					table[N2 * i + j] = DEAD;
				}
			}

		}
	}
}

int main(int argc, char *argv[]){
	clock_t starttime, endtime;
	int N = atoi(argv[1]);
	int maxGen = atoi(argv[2]);
	srand(time(NULL));

	//freopen("output2.txt", "w", stdout);
	
	const int N2 = N + 2;

	int *table;
	int *nextGen;

	cudaMallocManaged((void **)&table, N2 * N2 * sizeof(int));
	cudaMallocManaged((void **)&nextGen, N2 * N2 * sizeof(int));

	initTable(table, N2);

	/* copying the initial values of the table into the nextGen table */
	for (int i = 0; i < N2; i++) {
		for (int j = 0; j < N2; j++) {
			nextGen[N2 * i + j] = table[N2 * i + j];
		}
	}

	int blockSize = 128;
	int numBlocks = (N + blockSize - 1) / blockSize;

	starttime = clock();

	/* the main game loop that continues until the max generation or the game over condition has been met */
	for(int i = 0; i < maxGen; i++){
		//printTable(table, i, N2);
		nextGeneration <<<numBlocks, blockSize>>> (table, nextGen, N2);
		cudaDeviceSynchronize();
		swap(table, nextGen);
	}

	endtime = clock();
	printf("Time taken = %lf seconds\n", ((double) endtime - starttime) / CLOCKS_PER_SEC);

	cudaFree(table);
	cudaFree(nextGen);

	return 0;
}