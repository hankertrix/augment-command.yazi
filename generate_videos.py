#!/usr/bin/env python3

import asyncio
import os
import shutil
from pathlib import Path

# The path to the ASCII casts directory
ASCII_CAST_DIRECTORY = "./asciicasts"

# The path to the videos directory
VIDEOS_DIRECTORY = "./videos"


async def generate_videos(file_name: str, parent_directory: str):
    "Generate videos from ASCII casts."

    # Get the file path
    file_path = Path(file_name)

    # Get the parent directory path
    parent_dir_path = Path(parent_directory)

    # Get the file name without the extension
    base_name = file_path.stem

    # Get the full file path
    full_file_name = parent_dir_path / file_name

    # Get the full file path without the extension
    full_base_name = parent_dir_path / base_name

    # Get the full file name for the GIF
    full_gif_name = str(full_base_name) + ".gif"

    # Get the full file name for the video
    full_video_name = Path(VIDEOS_DIRECTORY) / (base_name + ".mp4")

    # Create the GIF file from the ASCII cast
    agg_process = await asyncio.subprocess.create_subprocess_shell(
        " ".join(["agg", str(full_file_name), full_gif_name])
    )

    # Wait for the agg process to finish
    await agg_process.wait()

    # Convert the GIF to MP4
    video_process = await asyncio.create_subprocess_shell(
        " ".join(
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
                "'scale=trunc(iw/2)*2:trunc(ih/2)*2'",
                str(full_video_name),
            ]
        ),
    )

    # Wait for the video process to finish
    await video_process.wait()

    # Remove the GIF file
    os.remove(full_gif_name)


async def main():
    "Main function to run to generate videos from ASCII casts."

    # Remove the existing videos
    if os.path.exists(VIDEOS_DIRECTORY):
        shutil.rmtree(VIDEOS_DIRECTORY)

    # Create the videos directory
    os.mkdir(VIDEOS_DIRECTORY)

    # Create the list of tasks
    tasks = []

    # Iterate through all the files in the ASCII casts directory
    for dir_path, dir_names, file_names in os.walk(ASCII_CAST_DIRECTORY):

        # Iterate over all the files in the directory
        for file_name in file_names:

            # Skip the files that are not ASCII casts
            if not file_name.endswith(".cast"):
                continue

            # Add the task to generate the video to the list
            tasks.append(generate_videos(file_name, dir_path))

    # Wait for all the tasks to finish
    await asyncio.gather(*tasks)


# Name safeguard
if __name__ == "__main__":
    asyncio.run(main())
