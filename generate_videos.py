#!/usr/bin/env python3

import os
import shutil
import subprocess
from pathlib import Path

# The path to the ASCII casts directory
ASCII_CAST_DIRECTORY = "./asciicasts"

# The path to the videos directory
VIDEOS_DIRECTORY = "./videos"


def main():
    "Main function to run to generate videos from ASCII casts."

    # Remove the existing videos
    if os.path.exists(VIDEOS_DIRECTORY):
        shutil.rmtree(VIDEOS_DIRECTORY)

    # Create the videos directory
    os.mkdir(VIDEOS_DIRECTORY)

    # Get the path to the videos directory
    videos_directory = Path(VIDEOS_DIRECTORY)

    # Iterate through all the files in the ASCII casts directory
    for dir_path, dir_names, file_names in os.walk(ASCII_CAST_DIRECTORY):

        # Iterate over all the files in the directory
        for file_name in file_names:

            # Skip the files that are not ASCII casts
            if not file_name.endswith(".cast"):
                continue

            # Get the file path
            file_path = Path(file_name)

            # Get the parent directory path
            parent_dir_path = Path(dir_path)

            # Get the file name without the extension
            base_name = file_path.stem

            # Get the full file path
            full_file_name = parent_dir_path / file_name

            # Get the full file path without the extension
            full_base_name = parent_dir_path / base_name

            # Get the full file name for the GIF
            full_gif_name = str(full_base_name) + ".gif"

            # Get the full file name for the video
            full_video_name = videos_directory / (base_name + ".mp4")

            # Create the GIF file from the ASCII cast
            subprocess.run(["agg", full_file_name, full_gif_name])

            # Convert the GIF to MP4
            subprocess.run(
                [
                    "ffmpeg",
                    "-y",
                    "-i",
                    full_gif_name,
                    "-movflags",
                    "faststart",
                    "-pix_fmt",
                    "yuv420p",
                    "-vf",
                    "scale=trunc(iw/2)*2:trunc(ih/2)*2",
                    full_video_name,
                ],
            )

            # Remove the GIF file
            os.remove(full_gif_name)


# Name safeguard
if __name__ == "__main__":
    main()
