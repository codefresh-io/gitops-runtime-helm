import argparse
import yaml
import sys
import re
import csv

DEFAULT_REGISTRY_URL = "registry.example.com"

def remove_duplicates(list_of_dicts, key):
    seen = set()
    deduplicated_list = []
    
    for d in list_of_dicts:
        if d[key] not in seen:
            deduplicated_list.append(d)
            seen.add(d[key])
    
    return deduplicated_list

def replace_registry_in_image(image_string, new_registry):
    parts = image_string.split('/')
    
    if len(parts) > 2:
        parts.pop(0)
        
    return '/'.join([new_registry] + parts)

# Try to identify whether a string is a docker image
def is_docker_image(image_string):
    pattern = r'^[a-zA-Z0-9/_-]+:[a-zA-Z0-9_.-]+$'
    return bool(re.match(pattern, image_string))


def recurse_replace_registry(currValue,new_registry):
    if type(currValue) is dict:
        for key in currValue.keys():
            if key == "registry":
                currValue[key]=new_registry
            elif key == "repository" and "registry" not in currValue:
                currValue[key] = replace_registry_in_image(currValue[key],new_registry)
            elif type(currValue[key]) is str:
                if is_docker_image(currValue[key]):
                    currValue[key] = replace_registry_in_image(currValue[key],new_registry)
            else:
                recurse_replace_registry(currValue[key],new_registry)

    elif type(currValue) is list:
        for index,item in enumerate(currValue):
            if type(item) is dict or type(item) is list:
                recurse_replace_registry(item,new_registry)
            elif type(item) is str:
                if is_docker_image(item):
                    currValue[index] = replace_registry_in_image(item,new_registry)
    

def recurse_remove_tags(currValue):
    if type(currValue) is dict:
        if "tag" in currValue:
                currValue.pop("tag")
        else:
            for key in currValue.keys():
                recurse_remove_tags(currValue[key])
    elif type(currValue) is list:
        for item in currValue:
            recurse_remove_tags(item)


def recurse_get_source_target(currValue,new_registry,lstSourceTarget):
    sourceImage = ""
    if type(currValue) is dict:
        for key in currValue.keys():
            if key == "registry":
                sourceImage += currValue[key] + "/"
            if key == "repository":
                 sourceImage += currValue[key]
            if key == "tag":
               sourceImage += ":" + currValue[key]
            else:
              recurse_get_source_target(currValue[key],new_registry,lstSourceTarget)  
        if len(sourceImage) > 0:
            lstSourceTarget.append({"source_image": sourceImage, "target_image": replace_registry_in_image(sourceImage,new_registry)})

    elif type(currValue) is list:
        for item in currValue:
            recurse_get_source_target(item,new_registry,lstSourceTarget)
    elif type(currValue) is str:
        if is_docker_image(currValue):
            lstSourceTarget.append({"source_image": currValue, "target_image": replace_registry_in_image(currValue,new_registry)})

def generate_file_from_field(list_of_dicts, field_name, output_file):
    with open(output_file, 'w+') as file:
        for d in list_of_dicts:
            field_value = d.get(field_name)
            if field_value:
                file.write(str(field_value) + '\n')

def generate_image_values(dictImageValues,outputDir):
    
    with open(f"{outputDir}/values-images-with-tags.yaml", 'w+') as file:
        yaml.dump(dictImageValues, file)
    
    recurse_remove_tags(dictImageValues)

    with open(f"{outputDir}/values-images-no-tags.yaml", 'w+') as file:
        yaml.dump(dictImageValues, file)

def generate_image_list():
    # Code for generating image list
    print("Generating image list")

def generate_mirror_csv(lstSourceTarget, outputDir):
    fields = ['source_image', 'target_image']

    with open(f"{outputDir}/image-mirror.csv", 'w+') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames = fields)
        writer.writeheader()
        writer.writerows(lstSourceTarget)
    
def main():

    parser = argparse.ArgumentParser(description="Codefresh gitops runtime - private registry utils")
    parser.add_argument("images_values_file", help="Input values.yaml file")
    parser.add_argument("private_registry_url", nargs="?", default=DEFAULT_REGISTRY_URL, help="Private Registry URL")
    parser.add_argument("--output-dir", help="Output directory",default="/output")
    parser.add_argument("--action", choices=["generate-image-values", "generate-image-list", "generate-mirror-csv"], help="Action to execute")
    args = parser.parse_args()

    # Open yaml
    with open(args.images_values_file, 'r') as stream:
        try:
            dictImageValues=yaml.safe_load(stream)
        except yaml.YAMLError as e:
            print(e)
        
        lstSourceTarget = []
        recurse_get_source_target(dictImageValues,args.private_registry_url,lstSourceTarget)
        lstSourceTarget = remove_duplicates(lstSourceTarget, "source_image")
        recurse_replace_registry(dictImageValues,args.private_registry_url)

        
    if args.action == "generate-mirror-csv" or args.action is None:
        print("Creating image-mirror.csv..")
        generate_mirror_csv(lstSourceTarget,args.output_dir)
        print("Done!")

    if args.action == "generate-image-list" or args.action is None:
        print("Creating image-list.txt...")
        generate_file_from_field(lstSourceTarget,"source_image", f"{args.output_dir}/image-list.txt")
        print("Done!")

    if args.action == "generate-image-values" or args.action is None:
        print("Creating values files...")
        generate_image_values(dictImageValues,args.output_dir)
        print("Done!")

if __name__ == "__main__":
    main()