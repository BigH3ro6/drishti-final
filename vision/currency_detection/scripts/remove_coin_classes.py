import os

# Coin class IDs to remove
coin_classes = [0, 1, 4, 6]

# Dataset path
dataset_path = "../data/raw/sl-currency-dataset-yolov"

splits = ["train", "valid", "test"]

for split in splits:

    labels_path = os.path.join(dataset_path, split, "labels")
    images_path = os.path.join(dataset_path, split, "images")

    for label_file in os.listdir(labels_path):

        label_path = os.path.join(labels_path, label_file)

        with open(label_path, "r") as f:
            lines = f.readlines()

        new_lines = []

        for line in lines:
            class_id = int(line.split()[0])

            if class_id not in coin_classes:
                new_lines.append(line)

        # If label file only had coins → remove image + label
        if len(new_lines) == 0:

            os.remove(label_path)

            image_file = label_file.replace(".txt", ".jpg")
            image_path = os.path.join(images_path, image_file)

            if os.path.exists(image_path):
                os.remove(image_path)

        else:

            with open(label_path, "w") as f:
                f.writelines(new_lines)

print("Coin classes removed successfully.")