# AI Playground

These files are here as a convenience for those that are working on the AI. You may tinker with them as you please, just do not commit any of the changes you make.

There are two AI examples in this folder: Deep Sight and GAN

## Deep Sight

This was a project I created in production studio two semesters ago that would help a drone know how far it had moved in the world simply from using the camera and comparing the change in the images it saw over time.

It takes as input two images of size 128x128x3 (the 3 is for RGB) as well as its rotational measurements as recorded by the drone's accelerometer.

Its output is 3 floating point values representing the change in the X, Y, and Z axes. Theoretically, as long as the input data and the AI's predictions were very close to correct, then the drone would always be able to know its position in the world relative to where it booted up.

## Generative Adversarial Network (GAN)

This was a project I made in the Deep Learning class. This AI (after it has been trained) requires no datasets besides user input. It asks the user what object they would like the AI to draw, and then the AI draws an image for that category.

The trick with this AI is in training. While training this AI is actually two separate AIs that learn from each other.

Feel free to look up the concept of GANs online as they explain it far more concisely than I do, but that is the general premise of how this AI functions.

Unfortunately, what I did not expect was the sheer amount of computational power that an AI like this requires to train. I ran this AI for 3 straight days uninterrupted, and the best images it could come with were colored blobs.

Now I don't have a supercomputer, but my computer (Nvidia card) can handle games that are very intense on the graphics card with ease, so the fact that this AI literally took days to barely produce some different colors is astounding.

If you would like to run this AI on your system, make sure you limit its training to either 10 minutes or 1 or 2 epochs. That way you won't stall your computer for too long. Probably. It honestly depends on how beefy your computer is.

## Purpose of the Playground

Please look into these examples and figure out how they work. And feel free to add additional files to this folder to experiment with other AIs you might want to build to see how they work. This way when we are making a program for the user that can build any AI they require, then we will be able to learn from making our own AIs to see how we can implement that for the user.
