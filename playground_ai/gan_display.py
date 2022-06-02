import numpy as np
from keras.models import load_model
from matplotlib import pyplot
from generative_adversarial_network import generate_noise

# create and save a plot of generated images
def save_plot(examples, n):
	# plot images
	for i in range(n * n):
		# define subplot
		pyplot.subplot(n, n, 1 + i)
		# turn off axis
		pyplot.axis('off')
		# plot raw pixel data
		pyplot.imshow(examples[i, :, :, :])
	pyplot.show()
 
# load model
generator = load_model("cifar_generator")
# generate noise for generator
noise, _ = generate_noise(100, 100)
print("\n\n\n\n\nPlease type the number of the kind of images you want to see! The generator will display 100 images in a 10x10 grid.")
print("0) Airplane")
print("1) Car")
print("2) Bird")
print("3) Cat")
print("4) Deer")
print("5) Dog")
print("6) Frog")
print("7) Horse")
print("8) Ship")
print("9) Truck")
print("10) All")
print("If 'All' is selected, each image type will have its own column.")

# Get user input which must be a number between 0-10
user_input = input("> ")
num = -1
try:
    num = int(user_input)
except ValueError:
    print("Please input a number.")
    num = -1

while num < 0 or num > 10:
    print("Please input a number between 0-10.")
    user_input = input("\n> ")
    try:
        num = int(user_input)
    except ValueError:
        print("Please input a number.")
        num = -1

# specify labels
labels = None
if num == 10:
    labels = np.asarray([x for _ in range(10) for x in range(10)])
else:
    labels = np.asarray([num for _ in range(10) for x in range(10)])

print("Generating...")

# generate images
X  = generator.predict([noise, labels])
# scale from [-1,1] to [0,1]
X = (X + 1) / 2

print("Displaying results!")

# plot the result
save_plot(X, 10)