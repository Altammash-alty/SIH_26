import asyncio
import io
import sys
from pathlib import Path

import numpy as np
from fastapi import UploadFile
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from server.app import screen_fundus_image


RESPONSE_KEYS = {
    "patient",
    "stage1Quality",
    "stage2Preprocess",
    "stage3Segmentation",
    "stage4Grading",
    "stage5Explainability",
    "routing",
    "images",
}


def make_fundus(with_lesions=False):
    size = 512
    y_coords, x_coords = np.mgrid[:size, :size]
    fundus = (x_coords - 256) ** 2 + (y_coords - 256) ** 2 <= 235 ** 2
    image = np.zeros((size, size, 3), dtype=np.uint8)
    image[fundus] = [145, 128, 105]

    if with_lesions:
        lesions = [
            (140, 170, [25, 25, 25]),
            (370, 340, [25, 25, 25]),
            (250, 100, [140, 250, 180]),
        ]
        for center_x, center_y, color in lesions:
            lesion = (x_coords - center_x) ** 2 + (y_coords - center_y) ** 2 <= 14 ** 2
            image[lesion] = color

    output = io.BytesIO()
    Image.fromarray(image).save(output, format="PNG")
    output.seek(0)
    return output


async def screen_synthetic(with_lesions):
    upload = UploadFile(filename="synthetic.png", file=make_fundus(with_lesions))
    return await screen_fundus_image(file=upload)


def test_clean_and_planted_lesions():
    clean = asyncio.run(screen_synthetic(False))
    planted = asyncio.run(screen_synthetic(True))

    assert set(clean) == RESPONSE_KEYS
    assert clean["stage3Segmentation"]["darkLesionCount"] == 0
    assert clean["stage3Segmentation"]["brightExudateCount"] == 0
    assert clean["stage4Grading"]["grade"] == 0

    assert planted["stage3Segmentation"]["darkLesionCount"] == 2
    assert planted["stage3Segmentation"]["brightExudateCount"] == 1


if __name__ == "__main__":
    test_clean_and_planted_lesions()
    print("screen_fundus synthetic regression: PASS")