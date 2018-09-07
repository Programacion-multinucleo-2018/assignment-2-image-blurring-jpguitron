nvcc -o exe_cu blur.cu -lopencv_core -lopencv_highgui -lopencv_imgproc -std=c++11
g++ -o exe_wt blur_wt.cpp -lopencv_core -lopencv_highgui -lopencv_imgproc -std=c++11 -fopenmp
g++ -o exe blur.cpp -lopencv_core -lopencv_highgui -lopencv_imgproc -std=c++11
