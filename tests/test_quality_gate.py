import unittest

import numpy as np

from server.app import assess_quality_gate


class QualityGateTests(unittest.TestCase):
    def test_assess_quality_gate_accepts_standard_fundus(self):
        y, x = np.mgrid[0:240, 0:240]
        gray = (120 + 18 * np.sin(x / 18.0) + 12 * np.cos(y / 22.0) + 8 * np.sin((x + y) / 16.0)).astype(np.uint8)
        green = (gray + 18).clip(0, 255).astype(np.uint8)
        mask = np.ones((240, 240), dtype=bool)

        result = assess_quality_gate(gray, green, mask)

        self.assertTrue(result["isGood"])
        self.assertGreater(result["overallScore"], 0.0)
        self.assertGreaterEqual(result["qualityPasses"], 2)


if __name__ == "__main__":
    unittest.main()
