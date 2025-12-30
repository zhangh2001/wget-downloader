# wget-downloader

## Overview

The `wget-downloader` project provides a set of Bash scripts designed to facilitate the downloading of files using `wget`. It includes reusable functions for managing download options, handling date ranges, and retrying failed downloads, making it a robust solution for data retrieval tasks.

## Features

- **src/dld.sh**: A script that contains essential functions for downloading files with `wget`. It includes:
  - Setup for `wget` options.
  - Parsing and validating date arguments.
  - Handling retries for failed downloads.

- **example/download.sh**: A script that leverages the functions from `src/dld.sh` to download datasets from the Geoscience Data Exchange (GDEX). It allows users to specify dataset types and automatically constructs the necessary URLs for downloading.

- **Example Usage**: The `examples/download.sh` script provides a full example of how to use the `wget-downloader` functionality, serving as a guide for users.

## Installation

To use the `wget-downloader`, clone the repository and navigate to the project directory:

```bash
git clone <repository-url>
cd wget-downloader
```

## Usage

To download files, source the `example/download.sh` script with the appropriate parameters:

```bash
./example/download.sh <dataset_type> <start_year> <start_month> <start_day> <end_year> <end_month> <end_day>
```

Replace `<dataset_type>` with the desired dataset (e.g., `ds461.0`, `ds094.0`, `ds083.2`) and provide the date range for the download.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the terms specified in the LICENSE file.