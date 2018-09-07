#include <iostream>
#include <cstdio>
#include <cmath>
#include <chrono>

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

#define N 5//Change bluring window size

using namespace std;


void blur(const cv::Mat& input, cv::Mat& output)
{
	cout << "Input image step: " << input.step << " rows: " << input.rows << " cols: " << input.cols << endl;

  int flr = floor (N/2.0);

  for (int iy = flr; iy < input.rows-flr; iy++)
  {
    for (int ix = flr; ix < input.cols-flr; ix++)
    {
      int bAvg = 0;
      int grAvg = 0;
      int rAvg = 0;

      for (int i = -flr; i <= flr; i++)
      {
        for (int j = -flr; j <= flr; j++)
        {
          int iyn = iy+i;
          int ixn = ix+j;
          bAvg += input.at<cv::Vec3b>(iyn,ixn)[0];
          grAvg += input.at<cv::Vec3b>(iyn,ixn)[1];
          rAvg += input.at<cv::Vec3b>(iyn,ixn)[2];
        }
      }

      output.at<cv::Vec3b>(iy,ix)[0] = bAvg/(N*N);
      output.at<cv::Vec3b>(iy,ix)[1] = grAvg/(N*N);
      output.at<cv::Vec3b>(iy,ix)[2] = rAvg/(N*N);

    }
  }

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
	cv::Mat output(input.rows, input.cols, CV_8UC3);//Resultado a color
  output = input.clone();
	//Call the wrapper function
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
