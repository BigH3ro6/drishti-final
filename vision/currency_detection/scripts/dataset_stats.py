import os
from collections import Counter

dataset_path = "data/raw/sl-currency-dataset-yolov"
splits = ["train", "valid", "test"]

class_counts = Counter()

for split in splits:

    labels_path = os.path.join(dataset_path, split, "labels")

    for file in os.listdir(labels_path):

        label_file = os.path.join(labels_path, file)

        with open(label_file, "r") as f:
            lines = f.readlines()

        for line in lines:
            class_id = int(line.split()[0])
            class_counts[class_id] += 1


print("\nClass Distribution:\n")

for cls, count in sorted(class_counts.items()):
    print(f"Class {cls}: {count} labels")