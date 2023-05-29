# Program to convert yaml file to dictionary
import yaml
import sys

def set_nested_dict_value(nested_dict, path, value):
    """Set a value in a nested dictionary using a dot-delimited path."""
    keys = path.split('.')
    for key in keys[:-1]:
        nested_dict = nested_dict.setdefault(key, {})
    nested_dict[keys[-1]] = value

def recurse_filter(currValue, filteredDict, filterKeyPathList, currentPath):
    bMatched = False
    for filterKeyPath in filterKeyPathList:
        if currentPath.endswith(filterKeyPath) and currValue:
            bMatched = True
    if bMatched == True:
        set_nested_dict_value(filteredDict,currentPath,currValue)
    elif type(currValue) is dict:
        for key in currValue.keys():
            if not currentPath:
                path =  key
            else:
                path = currentPath + "." + key
            recurse_filter(currValue[key], filteredDict, filterKeyPathList, path)
    else:
        return

def main(yamlFilepath, filterKeys):
    # Open yaml
    with open(yamlFilepath, 'r') as stream:
        try:
            d=yaml.safe_load(stream)
        except yaml.YAMLError as e:
            print(e)

    filteredDict = {}
    lstFilterKeys = filterKeys.split(",")
    recurse_filter(d, filteredDict, lstFilterKeys, "")
    print(yaml.dump(filteredDict))
        
if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SyntaxError("Wrong number of arguments. Usage: filter-values.py <path to yaml> <key paths to filter by, separated by commas - for example image.repository,foo.bar>")
    else:
       main(sys.argv[1], sys.argv[2])