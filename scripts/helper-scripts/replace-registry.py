import yaml
import sys
import re
import csv



def replace_registry_in_image(image_string, new_registry):
    if '/' in image_string:
        parts = image_string.split('/')
        if len(parts) >= 2:
            parts[0] = new_registry
            return '/'.join(parts)
    else:
        return new_registry + '/' + image_string

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
        for item in currValue:
            recurse_replace_registry(item,new_registry)

def recurse_get_source_target(currValue,new_registry,lstSourceTarget):
    oldImage = ""
    if type(currValue) is dict:
        for key in currValue.keys():
            if key == "registry":
                oldImage += currValue[key] + "/"
            if key == "repository":
                 oldImage += currValue[key]
            if key == "tag":
               oldImage += ":" + currValue[key]
            
            elif type(currValue[key]) is str:
                if is_docker_image(currValue[key]):
                    oldImage = currValue[key]
            
            recurse_get_source_target(currValue[key],new_registry,lstSourceTarget)
            
        if len(oldImage) > 0:
            lstSourceTarget.append({"source_image": oldImage, "target_image": replace_registry_in_image(oldImage,new_registry)})
            

    elif type(currValue) is list:
        for item in currValue:
            recurse_get_source_target(item,new_registry,lstSourceTarget)


def main(yamlFilepath, newRegistry):
    # Open yaml
    with open(yamlFilepath, 'r') as stream:
        try:
            d=yaml.safe_load(stream)
        except yaml.YAMLError as e:
            print(e)
        
        lstSourceTarget = []
        recurse_get_source_target(d,newRegistry,lstSourceTarget)
        print(yaml.dump(lstSourceTarget))
        #recurse_replace_registry(d,newRegistry)
        #print(yaml.dump(d))

        #
        
if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SyntaxError("Wrong number of arguments. Usage: replace-registry.py <path to yaml> <registry to replace with")
    else:
       main(sys.argv[1], sys.argv[2])