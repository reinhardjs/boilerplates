import argparse
from services.importer import SnomedImporter

def convert_escape_sequences(s):
    if not isinstance(s, str):
        return s
        
    escape_sequences = {
        '\\t': '\t',    # tab
        '\\n': '\n',    # newline
        '\\r': '\r',    # carriage return
        '\\f': '\f',    # form feed
        '\\b': '\b',    # backspace
        '\\v': '\v',    # vertical tab
        '\\a': '\a',    # bell
        '\\\\': '\\',   # backslash
        '\\"': '"',     # double quote
        "\\'": "'",     # single quote
    }
    
    if s in escape_sequences:
        return escape_sequences[s]
    elif len(s) == 1:
        return s
    try:
        return bytes(s, "utf-8").decode("unicode_escape")
    except:
        return s

def convert_args_escape_sequences(args):
    """Convert all string arguments in the namespace to their proper escape sequences"""
    for arg_name, arg_value in vars(args).items():
        if isinstance(arg_value, str):
            setattr(args, arg_name, convert_escape_sequences(arg_value))
    return args

def str2bool(v):
    if isinstance(v, bool):
        return v
    if v.lower() in ('yes', 'true', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

def main():
    parser = argparse.ArgumentParser(description="Snomed Importer")
    parser.add_argument(
        '--context', 
        type=str, 
        required=True, 
        choices=['snomed-ct', 'icd-10-gm'], 
        help='Specify the context to import, such as: snomed-ct, icd-10-gm, etc...'
    )
    parser.add_argument(
        '--doc_type', 
        type=str, 
        required=True, 
        choices=['snomed-ct-description', 'icd-10-gm-code'], 
        help='Specify the document type to import, which will be used as a prefix for the meilisearch\'s document id, e.g., snomed-ct-description, icd-10-gm-code, etc...'
    )
    parser.add_argument(
        '--source_type', 
        type=str, 
        required=True, 
        choices=['local', 'bucket'], 
        help='Source type (local or bucket)'
    )
    parser.add_argument(
        '--has_header', 
        type=str2bool, 
        required=True, 
        help='Indicates if the file has a header'
    )
    parser.add_argument(
        '--delimiter', 
        type=str, 
        required=True, 
        help='Delimiter used in the file'
    )
    parser.add_argument(
        '--file_path', 
        type=str, 
        required=True, 
        help='File path to import'
    )
    args = parser.parse_args()

    args = convert_args_escape_sequences(args)

    importer = SnomedImporter(args)
    importer.run()

if __name__ == "__main__":
    main()
