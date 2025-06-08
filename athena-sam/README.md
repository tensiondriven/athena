# Webcam Image Processing Pipeline

A pipeline that processes webcam images, performs segmentation using Segment Anything (SAM), and saves the results.

## Overview

This project sets up a pipeline to process live webcam feeds. The pipeline:

1. Reads configuration from a YAML file containing webcam URLs
2. Polls each webcam every second
3. Saves raw images locally
4. Runs segmentation on each image using SAM (Segment Anything)
5. Extracts and saves all detected objects/features with their masked images

## Features

- **YAML Configuration**: Easy setup via configuration files
- **Real-time Processing**: Polls webcam feeds every second
- **Image Segmentation**: Uses Segment Anything Model for object detection
- **Feature Extraction**: Automatically extracts all detected objects
- **Local Storage**: Saves both raw images and segmented results
- **Masked Images**: Generates and saves masked versions of detected objects

## Requirements

- Python 3.8+
- OpenCV (`cv2`)
- requests
- PyYAML
- Pillow (PIL)
- numpy

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd athena-sam

# Install dependencies
pip install -r requirements.txt
```

**Note**: This project uses a remote SAM server running at `http://llm:8100`. No local SAM model installation is required.

## SAM Server

The Segment Anything Model (SAM) runs on a dedicated server accessible at `http://llm:8100`. 

### Server Management

The SAM server is managed via Docker Compose on the `llm` machine:

```bash
# SSH to the SAM server machine
ssh j@llm

# Navigate to the docker-compose directory
cd ~/docker-compose/sam

# Check server status
docker-compose ps

# Start the server (if not running)
docker-compose up -d

# Stop the server
docker-compose down

# View server logs
docker-compose logs -f
```

### Server Health Check

You can verify the SAM server is running by making a simple HTTP request:

```bash
curl http://llm:8100/health
```

## Testing

### Quick Test Script

A comprehensive test script is provided to verify the complete pipeline functionality:

```bash
# Run the test script
./test_sam_server.sh
```

The test script will:
1. Check SAM server health
2. Create a test image (if none exists)
3. Send the image for segmentation
4. Receive and validate JSON response
5. Extract any returned mask files
6. Provide a summary of results

**Test Output:**
- `test_output/response_TIMESTAMP.json` - JSON response with object metadata
- `test_output/masks_TIMESTAMP/` - Extracted mask files (if available)
- `test_image.jpg` - Test image (auto-generated if needed)

**Requirements for test script:**
- `curl` - For HTTP requests
- `jq` - For JSON parsing (optional but recommended)
- `ImageMagick` - For creating test images (optional)

## Configuration

Create a `config.yaml` file with your webcam settings:

```yaml
# Webcam configuration
webcams:
  - name: "front_entrance"
    url: "http://192.168.1.100/cam1.jpg"
    enabled: true
  - name: "parking_lot"
    url: "http://192.168.1.101/cam2.jpg"
    enabled: true
  - name: "back_yard"
    url: "http://example.com/webcam/feed.jpg"
    enabled: false

# Processing settings
processing:
  poll_interval: 1.0  # seconds between polls
  save_raw_images: true
  save_segmented_images: true
  save_masked_objects: true

# Output configuration
output:
  base_path: "./output"
  raw_images_dir: "raw"
  segmented_dir: "segmented"
  objects_dir: "objects"
  
# SAM server configuration
sam:
  server_url: "http://llm:8100"
  timeout: 30  # seconds
  retry_attempts: 3
```

## Usage

### Basic Usage

```bash
# Run with default config
python pipeline.py

# Run with custom config
python pipeline.py --config custom_config.yaml

# Run with specific webcam
python pipeline.py --webcam front_entrance

# Dry run (test configuration without processing)
python pipeline.py --dry-run
```

### Command Line Options

```bash
python pipeline.py [OPTIONS]

Options:
  --config PATH          Path to configuration file (default: config.yaml)
  --webcam NAME         Process only specified webcam
  --output PATH         Override output directory
  --interval SECONDS    Override poll interval
  --dry-run            Test configuration without processing
  --verbose            Enable verbose logging
  --help               Show help message
```

## Project Structure

```
athena-sam/
├── README.md                 # This file
├── requirements.txt          # Python dependencies
├── config.yaml              # Configuration file
├── pipeline.py              # Main pipeline script
├── test_sam_server.sh       # SAM server test script
├── src/
│   ├── webcam_poller.py     # Webcam polling logic
│   ├── sam_client.py        # SAM server client
│   ├── image_saver.py       # Image saving utilities
│   └── config_loader.py     # Configuration loading
├── test_output/             # Test script output
│   ├── response_*.json      # Test responses
│   └── masks_*/             # Test mask files
└── output/                  # Generated output
    ├── front_entrance/
    │   ├── raw/            # Raw webcam images
    │   ├── segmented/      # Segmented images
    │   └── objects/        # Individual object masks
    └── parking_lot/
        ├── raw/
        ├── segmented/
        └── objects/
```

## Output Format

### Directory Structure
Each webcam creates its own directory with subdirectories for different types of output:

```
output/
└── {webcam_name}/
    ├── raw/                 # Original webcam images
    │   └── {timestamp}.jpg
    ├── segmented/           # Images with all segments highlighted
    │   └── {timestamp}_segmented.jpg
    └── objects/             # Individual object masks and crops
        └── {timestamp}/
            ├── object_001_mask.png
            ├── object_001_crop.jpg
            ├── object_002_mask.png
            ├── object_002_crop.jpg
            └── metadata.json
```

### Metadata Format
Each object extraction includes a `metadata.json` file:

```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "webcam": "front_entrance",
  "total_objects": 3,
  "objects": [
    {
      "id": 1,
      "confidence": 0.95,
      "bbox": [100, 150, 200, 300],
      "area": 15000,
      "mask_file": "object_001_mask.png",
      "crop_file": "object_001_crop.jpg"
    }
  ]
}
```

## Development

### Running Tests
```bash
# Run all tests
python -m pytest tests/

# Run specific test
python -m pytest tests/test_webcam_poller.py

# Run with coverage
python -m pytest --cov=src tests/
```

### Code Style
```bash
# Format code
black src/ tests/

# Check linting
flake8 src/ tests/

# Type checking
mypy src/
```

## Troubleshooting

### Common Issues

1. **Webcam Connection Errors**
   - Check if URLs are accessible
   - Verify network connectivity
   - Ensure webcam supports HTTP requests

2. **SAM Server Issues**
   - Verify SAM server is running at `http://llm:8100`
   - Check network connectivity to the SAM server
   - Ensure server has sufficient resources for processing

3. **Permission Errors**
   - Check write permissions for output directory
   - Verify file system space availability

### Logging

Enable verbose logging for debugging:
```bash
python pipeline.py --verbose
```

Log files are saved to `logs/pipeline.log` by default.

## Performance Considerations

- **SAM Server**: Remote SAM server at `http://llm:8100` handles all segmentation processing
- **Network**: Requires stable connection to SAM server and webcam sources
- **Storage**: Raw images and masks can consume significant disk space
- **Bandwidth**: Multiple webcams and SAM server communication may require substantial bandwidth

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Segment Anything Model (SAM)](https://github.com/facebookresearch/segment-anything) by Meta AI
- OpenCV community for computer vision tools
- Contributors and maintainers

## Contact

For questions, issues, or contributions, please open an issue on GitHub or contact the maintainers.