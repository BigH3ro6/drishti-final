import os

dataset_path = "../data/raw/sl-currency-dataset-yolov"
splits = ["train", "valid", "test"]

errors = 0

for split in splits:

    images_path = os.path.join(dataset_path, split, "images")
    labels_path = os.path.join(dataset_path, split, "labels")

    images = set([img.split(".")[0] for img in os.listdir(images_path)])
    labels = set([lbl.split(".")[0] for lbl in os.listdir(labels_path)])

    # Check missing labels
    missing_labels = images - labels
    if missing_labels:
        print(f"{split}: {len(missing_labels)} images missing labels")

    # Check empty label files
    for file in os.listdir(labels_path):
        label_file = os.path.join(labels_path, file)

        if os.path.getsize(label_file) == 0:
            print(f"Empty label: {label_file}")
            errors += 1

        with open(label_file, "r") as f:
            lines = f.readlines()

        for line in lines:
            parts = line.split()

            if len(parts) != 5:
                print(f"Invalid label format: {label_file}")
                errors += 1
                continue

            x, y, w, h = map(float, parts[1:])

            if not (0 <= x <= 1 and 0 <= y <= 1 and 0 <= w <= 1 and 0 <= h <= 1):
                print(f"Invalid bounding box: {label_file}")
                errors += 1

print("\nValidation completed")
print("Total issues:", errors)