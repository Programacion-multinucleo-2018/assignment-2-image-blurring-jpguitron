#include <iostream>
#include <cstdio>
#include <cmath>

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

#include "common.h"
#include <cuda_runtime.h>

#include <chrono>

#define N 5//Change bluring window size

using namespace std;

__global__ void blur_kernel(unsigned char* input, unsigned char* output, int width, int height, int step)
{

	const int xIndex = blockIdx.x * blockDim.x + threadIdx.x;
	const int yIndex = blockIdx.y * blockDim.y + threadIdx.y;

	int flr = floor (N/2.0);
	int matAvg = 0;

	//Avoiding edge pixels
	if ((xIndex < width) && (yIndex < height))
	{
		//Current pixel
		const int tid = yIndex * step + (3 * xIndex);

		int bAvg = 0;
		int grAvg = 0;
		int rAvg = 0;


		//Get the average of the surrounding pixels
		for (int i = -flr; i <= flr; i++)
		{
			for (int j = -flr; j <= flr; j++)
			{


				const int tid = (yIndex+i) * step + (3 * (xIndex+j));
				if(xIndex+j>0 && yIndex+i>0 && xIndex+j<width && yIndex+i<height )
				{
					matAvg+=1;
					bAvg += input[tid];
					grAvg += input[tid + 1];
					rAvg += input[tid + 2];
				}
			}
		}

		//Changing the central pixel with the average of the others
		output[tid] = static_cast<unsigned char>(bAvg/(matAvg));
		output[tid+1] = static_cast<unsigned char>(grAvg/(matAvg));
		output[tid+2] = static_cast<unsigned char>(rAvg/(matAvg));
	}
}

void blur(const cv::Mat& input, cv::Mat& output)
{

	cout << "Input image step: " << input.step << " rows: " << input.rows << " cols: " << input.cols << endl;

	size_t colorBytes = input.step * input.rows;
	size_t grayBytes = output.step * output.rows;

	unsigned char *d_input, *d_output;

	// Allocate device memory
	SAFE_CALL(cudaMalloc(&d_input, colorBytes), "CUDA Malloc Failed");
	SAFE_CALL(cudaMalloc(&d_output, grayBytes), "CUDA Malloc Failed");

	// Copy data from OpenCV input image to device memory
	SAFE_CALL(cudaMemcpy(d_input, input.ptr(), colorBytes, cudaMemcpyHostToDevice), "CUDA Memcpy Host To Device Failed");
	SAFE_CALL(cudaMemcpy(d_output, output.ptr(), colorBytes, cudaMemcpyHostToDevice), "CUDA Memcpy Host To Device Failed");

	// Specify a reasonable block size
	const dim3 block(16, 16);

	// Calculate grid size to cover the whole image
	const dim3 grid((int)ceil((float)input.cols / block.x), (int)ceil((float)input.rows/ block.y));
	printf("blur_kernel<<<(%d, %d) , (%d, %d)>>>\n", grid.x, grid.y, block.x, block.y);

	// Launch the color conversion kernel
	blur_kernel <<<grid, block >>>(d_input, d_output, input.cols, input.rows, static_cast<int>(input.step));

	// Synchronize to check for any kernel launch errors
	SAFE_CALL(cudaDeviceSynchronize(), "Kernel Launch Failed");

	// Copy back data from destination device meory to OpenCV output image
	SAFE_CALL(cudaMemcpy(output.ptr(), d_output, grayBytes, cudaMemcpyDeviceToHost), "CUDA Memcpy Host To Device Failed");

	// Free the device memory
	SAFE_CALL(cudaFree(d_input), "CUDA Free Failed");
	SAFE_CALL(cudaFree(d_output), "CUDA Free Failed");
}

int main(int argc, char *argv[])
{
	string imagePath;

	if(argc < 2)
		imagePath = "image.jpg";
  	else
  		imagePath = argv[1];

	// Read input image from the disk
	cv::Mat input = cv::imread(imagePath, CV_LOAD_IMAGE_COLOR);

	if (input.empty())
	{
		cout << "Image Not Found!" << std::endl;
		cin.get();
		return -1;
	}

	//Create output image
	cv::Mat output(input.rows, input.cols, CV_8UC3);
	//output = input.clone();
	//Execute blur function and measure time
	auto start_cpu =  chrono::high_resolution_clock::now();
	blur(input, output);
	auto end_cpu =  chrono::high_resolution_clock::now();
	chrono::duration<float, std::milli> duration_ms = end_cpu - start_cpu;
	printf("elapsed %f ms\n", duration_ms.count());


	//Allow the windows to resize
	namedWindow("Input", cv::WINDOW_NORMAL);
	namedWindow("Output", cv::WINDOW_NORMAL);

	//Show the input and output
	imshow("Input", input);
	imshow("Output", output);

	//Wait for key press
	cv::waitKey();

	return 0;
}
