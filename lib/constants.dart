const int kSampRate = 50; // Hz - approximate sampling rate of acceleration data
const double kVerticalAxisSpace = 0.33; // x100% of the screen to be occupied by the axis when in portrait layout
const int kAccBufferSize = kSampRate*20*2; // maximal number of samples to be stored for showing (*2 to account for both time and acceleration samples)
const List<double> kSamplesToPlot = [1,5,10,20]; // Approximate time (s) to scale plot with acceleration values