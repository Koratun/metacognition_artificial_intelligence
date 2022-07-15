import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import tensorflow as tf
import keras
from keras import layers, optimizers
from keras.datasets import cifar10
from tensorflow.python.keras.layers.core import Flatten


# Plots the history of the training algorithm
def plot_losses(history):
    sns.set()  # Switch to the Seaborn look

    # Plot Disc and Gen losses
    plt.subplot(2, 1, 1)
    plt.plot(history["d_real_loss"], label="Disc Real Loss", color="blue", linestyle="-")
    plt.plot(history["d_fake_loss"], label="Disc Fake Loss", color="red", linestyle="--")
    plt.plot(history["gen_loss"], label="Generator Loss", color="green")
    plt.xlabel("Batches", fontsize=20)
    plt.ylabel("Loss", fontsize=20)
    plt.xlim(0, len(history["d_real_loss"]) - 1)
    plt.xticks(fontsize=15)
    plt.yticks(fontsize=15)
    plt.legend(fontsize=15)

    # Plot Disc accuracy
    plt.subplot(2, 1, 2)
    plt.plot(history["d_real_acc"], label="Disc Real Accuracy", color="blue", linestyle="-")
    plt.plot(history["d_fake_acc"], label="Disc Fake Accuracy", color="red", linestyle="--")
    plt.xlabel("Batches", fontsize=20)
    plt.ylabel("Accuracy", fontsize=20)
    plt.xlim(0, len(history["d_real_loss"]) - 1)
    plt.xticks(fontsize=15)
    plt.yticks(fontsize=15)
    plt.legend(fontsize=15)
    plt.show()

    # Show predictions generated over training time
    for x in range(len(history["prediction"])):
        plt.subplot(1, len(history["prediction"]), x + 1)
        plt.axis("off")
        plt.imshow(history["prediction"][x][0, :, :, :])

    plt.show()


# define the discriminator
def define_discriminator(image_input_shape=(32, 32, 3), n_classes=10):
    # label input
    label_input = layers.Input(shape=(1,))

    # embedding for categorical input
    li = layers.Embedding(n_classes, 50)(label_input)

    # scale up to image dimensions with linear activation
    n_nodes = image_input_shape[0] * image_input_shape[1]
    li = layers.Dense(n_nodes)(li)

    # Reshape to image shape
    li = layers.Reshape((image_input_shape[0], image_input_shape[1], 1))(li)

    # image input
    in_image = layers.Input(shape=image_input_shape)

    # concat label as a channel
    merge = layers.Concatenate()([in_image, li])

    # downsample
    # Input through a convolutional layer, activate it with a non-linear function (the leaky ReLU)
    disc = layers.Conv2D(64, (5, 5))(merge)
    disc = layers.LeakyReLU()(disc)
    disc = layers.BatchNormalization()(disc)
    # Run through MaxPool2D to help the algorithm identify features in different areas of the image.
    # Has the effect of downsampling and cutting the dimensions in half.
    disc = layers.MaxPool2D()(disc)

    # Input through a convolutional layer, activate it with a non-linear function (the leaky ReLU)
    disc = layers.Conv2D(128, (3, 3))(disc)
    disc = layers.LeakyReLU()(disc)
    disc = layers.BatchNormalization()(disc)
    disc = layers.Dropout(0.3)(disc)

    # Input through a convolutional layer, activate it with a non-linear function (the leaky ReLU)
    # disc = layers.Conv2D(172, (3, 3))(disc)
    # disc = layers.LeakyReLU()(disc)
    # disc = layers.BatchNormalization()(disc)
    # disc = layers.Dropout(.4)(disc)

    # Transpose tensor from (batch, rows, cols, channels) to (batch, channels, rows, cols)
    disc = tf.transpose(disc, (0, 3, 1, 2))
    # Add fifth dimension for convLSTM layer
    disc = tf.expand_dims(disc, axis=-1)

    # Identify any possible sequences of features in the data by processing all the features using recurrent
    # techniques both forwards and backwards.
    # disc = layers.Bidirectional(layers.LSTM(128, return_sequences = True))(disc)
    # disc = layers.Dropout(.4)(disc)

    # Disc will be (batch, features (time), rows, cols, channels (1)
    disc = layers.ConvLSTM2D(32, (3, 3))(disc)
    # Output is (batch, filters, new_rows, new_cols)
    disc = layers.Dropout(0.4)(disc)

    # Flatten for final feed through dense layers
    disc = Flatten()(disc)

    # clsfy = layers.Dense(4092)(clsfy)
    # clsfy = layers.LeakyReLU()(clsfy)
    # clsfy = layers.BatchNormalization()(clsfy)
    # clsfy = layers.Dropout(.5)(clsfy)
    #
    disc = layers.Dense(512)(disc)
    disc = layers.LeakyReLU()(disc)
    disc = layers.BatchNormalization()(disc)
    disc = layers.Dropout(0.4)(disc)

    disc = layers.Dense(128)(disc)
    disc = layers.LeakyReLU()(disc)
    disc = layers.BatchNormalization()(disc)
    disc = layers.Dropout(0.3)(disc)

    # output
    out_layer = layers.Dense(1, activation="sigmoid")(disc)
    # define model
    model = keras.Model([in_image, label_input], out_layer)
    # compile model
    model.compile(
        loss="binary_crossentropy",
        optimizer=optimizers.adamax_v2.Adamax(learning_rate=0.0003, beta_1=0.7),
        metrics=["accuracy"],
    )
    return model


# define the generator
def define_generator(random_size, n_classes=10):
    # label input
    label_input = layers.Input(shape=(1,))

    # embedding for categorical input
    li = layers.Embedding(n_classes, 50)(label_input)

    # Scale up to small image shape
    n_nodes = 8 * 8
    li = layers.Dense(n_nodes)(li)

    # reshape to additional channel
    li = layers.Reshape((8, 8, 1))(li)

    # image generator input
    random_input = layers.Input(shape=(random_size,))

    # foundation for 32x32 image
    n_nodes = 128 * 8 * 8
    gen = layers.Dense(n_nodes)(random_input)
    gen = layers.LeakyReLU(alpha=0.2)(gen)
    gen = layers.Reshape((8, 8, 128))(gen)

    # merge image gen and label input
    merge = layers.Concatenate()([gen, li])

    # upsample to 16x16
    gen = layers.Conv2DTranspose(128, (4, 4), strides=(2, 2), padding="same")(merge)
    gen = layers.LeakyReLU(alpha=0.2)(gen)

    # upsample to 32x32
    gen = layers.Conv2DTranspose(172, (4, 4), strides=(2, 2), padding="same")(gen)
    gen = layers.LeakyReLU(alpha=0.2)(gen)

    # output
    out_layer = layers.Conv2D(3, (8, 8), activation="tanh", padding="same")(gen)

    model = keras.Model([random_input, label_input], out_layer)
    return model


# define the combined generator and discriminator model, for updating the generator
def define_gan(generator, discriminator):
    # make weights in the discriminator not trainable
    discriminator.trainable = False

    # get noise and label inputs from generator model
    gen_noise, gen_label = generator.input

    # get image output from the generator model
    gen_output = generator.output

    # connect image output and label input from generator as inputs to discriminator
    gan_output = discriminator([gen_output, gen_label])

    # define gan model as taking noise and label and outputting a classification
    model = keras.Model([gen_noise, gen_label], gan_output)

    # compile model
    opt = optimizers.adamax_v2.Adamax(learning_rate=0.0003, beta_1=0.7)
    model.compile(loss="binary_crossentropy", optimizer=opt)

    # reset trainability for discriminator only (gan ignores this since it has been compiled already)
    discriminator.trainable = True
    return model


# load cifar10 and scale the image data for the AI
def load_data():
    # load dataset
    (trainX, trainy), (_, _) = cifar10.load_data()

    # convert from ints to floats
    X = trainX.astype("float32")

    # scale from [0,255] to [-1,1]
    X = (X - 127.5) / 127.5
    return [X, trainy]


# select real samples
def generate_real_samples(dataset, n_samples):
    # split into images and labels
    images, labels = dataset

    # choose random instances
    indicies = np.random.randint(0, images.shape[0], n_samples)

    # select images and labels
    X, labels = images[indicies], labels[indicies]

    # generate class labels
    y = np.ones((n_samples, 1))

    return [X, labels], y


# generate noise as input for the generator
def generate_noise(random_size, n_samples, n_classes=10):
    # generate points in the latent space
    x_input = np.random.randn(random_size * n_samples)

    # reshape into a batch of inputs for the network
    z_input = x_input.reshape(n_samples, random_size)

    # generate labels
    labels = np.random.randint(0, n_classes, n_samples)

    return [z_input, labels]


# use the generator to generate n fake examples, with class labels
def generate_fake_samples(generator, random_size, n_samples):
    # generate points in latent space
    z_input, labels_input = generate_noise(random_size, n_samples)

    # predict outputs
    images = generator.predict([z_input, labels_input])

    # create class labels
    y = np.zeros((n_samples, 1))

    return [images, labels_input], y


def train_hours(generator, discriminator, gan, dataset, random_size, batch_size, runtime_hours, history):
    bat_per_epo = int(dataset[0].shape[0] / batch_size)
    half_batch = int(batch_size / 2)
    start = tf.timestamp()
    runtime_secs = runtime_hours * 60 * 60

    # Execute training while time is left
    # Enumerate epochs
    i = 0
    # timer for generating examples across training
    generate_time = tf.timestamp() + float(runtime_secs) / 10
    while runtime_secs > (tf.timestamp() - start):
        # Enumerate batches
        for j in range(bat_per_epo):
            batch_start = tf.timestamp()
            # get randomly selected 'real' samples
            [X_real, labels_real], y_real = generate_real_samples(dataset, half_batch)

            # update discriminator model weights
            d_loss_real, d_acc_real = discriminator.train_on_batch([X_real, labels_real], y_real)

            # generate 'fake' examples
            [X_fake, labels], y_fake = generate_fake_samples(generator, random_size, half_batch)

            # update discriminator model weights
            d_loss_fake, d_acc_fake = discriminator.train_on_batch([X_fake, labels], y_fake)

            # prepare noise as input for the generator
            [z_input, labels_input] = generate_noise(random_size, batch_size)

            # create inverted labels for the fake samples
            inverted_labels = np.ones((batch_size, 1))

            # update the generator via the discriminator's error
            g_loss = gan.train_on_batch([z_input, labels_input], inverted_labels)

            # Keep a history of the losses to display after completion
            history["d_real_loss"].append(d_loss_real)
            history["d_fake_loss"].append(d_loss_fake)
            history["d_real_acc"].append(d_acc_real)
            history["d_fake_acc"].append(d_acc_fake)
            history["gen_loss"].append(g_loss)

            # Get time info
            sec_elapsed = int(tf.timestamp() - start)
            batch_sec = tf.timestamp() - batch_start
            percent_done = float(sec_elapsed) / runtime_secs * 100
            if percent_done == 0:
                percent_done = 1e-5
            elif percent_done > 100:
                percent_done = 100
            time_remaining = runtime_secs - sec_elapsed
            if time_remaining < 0:
                time_remaining = 0

            # summarize loss on this batch
            print(
                f">{i+1:3d}, {j+1:3d}/{bat_per_epo:d}, d_r={d_loss_real:.3f}, d_f={d_loss_fake:.3f}, g={g_loss:.3f} "
                f"[Elapsed: {(sec_elapsed // 60) // 60:02.0f}h {(sec_elapsed // 60) % 60:02.0f}m {sec_elapsed % 60:02.0f}s, "
                f"{batch_size*2/batch_sec:6.1f} examples/s, "
                f"ETC: {(time_remaining // 60) // 60:02.0f}h {(time_remaining // 60) % 60:02.0f}m {time_remaining % 60:02.0f}s, "
                f"{percent_done:.1f}% Done]"
            )

        # increment epoch counter
        i += 1

        # Create an image with the current weights and scale it for display at the end.
        if generate_time < tf.timestamp():
            generate_time = tf.timestamp() + float(runtime_secs) / 10
            noise, _ = generate_noise(random_size, 1)
            history["prediction"].append((generator.predict([noise, np.asarray([0])]) + 1) / 2)

    # Generate final example for end of this training.
    noise, _ = generate_noise(random_size, 1)
    history["prediction"].append((generator.predict([noise, np.asarray([0])]) + 1) / 2)
    # save the GAN
    generator.save("playground_ai\\cifar_generator")
    discriminator.save("playground_ai\\cifar_disc")
    return history


# train the generator and discriminator
def train(generator, discriminator, gan, dataset, random_size, n_epochs=100, batch_size=128, runtime_hours=0):
    history = {
        "d_real_loss": [],
        "d_real_acc": [],
        "d_fake_loss": [],
        "d_fake_acc": [],
        "gen_loss": [],
        "prediction": [],
    }
    if runtime_hours > 0:
        return train_hours(generator, discriminator, gan, dataset, random_size, batch_size, runtime_hours, history)
    bat_per_epo = int(dataset[0].shape[0] / batch_size)
    half_batch = int(batch_size / 2)
    start = tf.timestamp()
    total_batches = n_epochs * bat_per_epo
    # Enumerate epochs
    for i in range(n_epochs):
        # Enumerate batches
        for j in range(bat_per_epo):
            batch_start = tf.timestamp()
            # get randomly selected 'real' samples
            [X_real, labels_real], y_real = generate_real_samples(dataset, half_batch)

            # update discriminator model weights
            d_loss_real, d_acc_real = discriminator.train_on_batch([X_real, labels_real], y_real)

            # generate 'fake' examples
            [X_fake, labels], y_fake = generate_fake_samples(generator, random_size, half_batch)

            # update discriminator model weights
            d_loss_fake, d_acc_fake = discriminator.train_on_batch([X_fake, labels], y_fake)

            # prepare noise as input for the generator
            [z_input, labels_input] = generate_noise(random_size, batch_size)

            # create inverted labels for the fake samples
            inverted_labels = np.ones((batch_size, 1))

            # update the generator via the discriminator's error
            g_loss = gan.train_on_batch([z_input, labels_input], inverted_labels)

            # Keep a history of the losses to display after completion
            history["d_real_loss"].append(d_loss_real)
            history["d_fake_loss"].append(d_loss_fake)
            history["d_real_acc"].append(d_acc_real)
            history["d_fake_acc"].append(d_acc_fake)
            history["gen_loss"].append(g_loss)

            # Get time info
            sec_elapsed = int(tf.timestamp() - start)
            batch_sec = tf.timestamp() - batch_start
            percent_done = float(i * bat_per_epo + j) / total_batches * 100
            if percent_done == 0:
                percent_done = 1e-5
            time_remaining = int(100 * sec_elapsed / percent_done) - sec_elapsed
            if time_remaining < 0:
                time_remaining = 0

            # summarize loss on this batch
            print(
                f">{i+1:3d}, {j+1:3d}/{bat_per_epo:d}, d_r={d_loss_real:.3f}, d_f={d_loss_fake:.3f}, g={g_loss:.3f} "
                f"[Elapsed: {(sec_elapsed // 60) // 60:02.0f}h {(sec_elapsed // 60) % 60:02.0f}m {sec_elapsed % 60:02.0f}s, "
                f"{batch_size*2/batch_sec:6.1f} examples/s, "
                f"ETC: {(time_remaining // 60) // 60:02.0f}h {(time_remaining // 60) % 60:02.0f}m {time_remaining % 60:02.0f}s, "
                f"{percent_done:.1f}% Done]"
            )

        # Create an image with the current weights and scale it for display at the end.
        if n_epochs >= 10:
            if i % (n_epochs // 10) == 0:
                noise, _ = generate_noise(random_size, 1)
                history["prediction"].append((generator.predict([noise, np.asarray([0])]) + 1) / 2)
        else:
            noise, _ = generate_noise(random_size, 1)
            history["prediction"].append((generator.predict([noise, np.asarray([0])]) + 1) / 2)

    noise, _ = generate_noise(random_size, 1)
    history["prediction"].append((generator.predict([noise, np.asarray([0])]) + 1) / 2)
    # save the GAN
    # gan.save("cifar_gan")
    generator.save("playground_ai\\cifar_generator")
    discriminator.save("playground_ai\\cifar_disc")
    return history


def load_gan():
    gan = keras.models.load_model("cifar_gan")
    generator = keras.Model(gan.input, gan.layers[-2].output)
    discriminator = gan.layers[-1]
    discriminator.compile(
        loss="binary_crossentropy", optimizer=optimizers.Adam(lr=0.0003, beta_1=0.7), metrics=["accuracy"]
    )
    return gan, generator, discriminator


def save_models(gan, generator, discriminator):
    discriminator.trainable = False
    gan.save("cifar_gan")
    discriminator.trainable = True
    generator.save("cifar_generator")
    discriminator.save("cifar_disc")


def load_models():
    discriminator = keras.models.load_model("cifar_disc")
    generator = keras.models.load_model("cifar_generator")
    gan = keras.models.load_model("cifar_gan")
    return gan, generator, discriminator


def main():
    # size of the noise to be generated
    random_size = 100

    # create the discriminator
    # discriminator = define_discriminator()
    # discriminator.summary()
    discriminator = keras.models.load_model("playground_ai\\cifar_disc")

    # create the generator
    # generator = define_generator(random_size)
    # generator.summary()
    generator = keras.models.load_model("playground_ai\\cifar_generator")

    # create the gan
    gan = define_gan(generator, discriminator)

    # gan, generator, discriminator = load_gan()

    # load image data
    dataset = load_data()

    # train model
    history = train(generator, discriminator, gan, dataset, random_size, n_epochs=1, batch_size=128, runtime_hours=0)

    # Save the GAN and its submodels (gen and disc)
    # save_models(gan, generator, discriminator)

    # Print history of algorithm
    plot_losses(history)


if __name__ == "__main__":
    main()
