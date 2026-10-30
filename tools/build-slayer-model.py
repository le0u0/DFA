"""Build the current detailed Slayer model (legacy command kept for convenience)."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('package-slayer-detail.py')),run_name='__main__')
