Utilities to assist with image mirroring to private registries

## How it works?

1. All calculated values are outputed using output-calculated-values.sh. The script contains a special template that handles image values. Specifically it derives tags for images that don't have explicit tags sepcified from the subchart appVersion.
2. Those values are then filtered using the helper script yaml-filter.py to filter only the values that contain images.
3. image-values-utils.py then uses the output of the previous steps and can generate:
   1. A list of all images
   2. Values files with and without tags including a custom registry for each image.
   3. A csv file with source and target image names (can help with image mirroring).

## Usage
1. Build the image with buildcontext being the root of the repo `docker build -f scripts/private-registry-utils/Dockerfile -t <image-tag> .`  For example: `docker build -f scripts/private-registry-utils/Dockerfile -t gitops-runtime-priv-reg .`
2. Execute with: `docker run -v <local output directory>:/output -it <image-tag> <private registry>` for example: `docker run -v /tmp/output:/output -it gitops-runtime-priv-reg myregisry.example.com`
3. See the generated files in local output folder
