import os

dataset_path = "../data/raw/sl-currency-dataset-yolov"
splits = ["train", "valid", "test"]

# Old → New class mapping
class_mapping = {
    5: 0,  # 20
    7: 1,  # 50
    2: 2,  # 100
    8: 3,  # 500
    3: 4,  # 1000
    9: 5   # 5000
}

for split in splits:

    labels_path = os.path.join(dataset_path, split, "labels")

    for file in os.listdir(labels_path):

        label_file = os.path.join(labels_path, file)

        new_lines = []

        with open(label_file, "r") as f:
            lines = f.readlines()

        for line in lines:

            parts = line.split()
            class_id = int(parts[0])

            if class_id in class_mapping:
                parts[0] = str(class_mapping[class_id])
                new_lines.append(" ".join(parts) + "\n")

        with open(label_file, "w") as f:
            f.writelines(new_lines)

print("Class reindexing completed.")