import struct

from .type import StoreParamsT
from .crypto import *

IMAGE_TYPE_OEM_COMMAND = 0x28
OEM_COMMAND            = "OEM_COMMAND"

SIZE_OF_OEM_COMMAND_STORE_HEADER = 44
SIZE_OF_OEM_COMMAND_STORE_SIGN   = 256

def check_params(params: StoreParamsT) -> None:
    '''
        This function checks the parameters for generate_oem_command_store
        function
    '''
    if params.p_body == b'':
        raise ErrInvalidParam('params.p_body is empty')
    if params.body_len == 0:
        raise ErrInvalidParam('Invalid body length - length 0')
    
def generate_oem_command_store(params: StoreParamsT) -> None:
    '''
        This function generates the encrypted image based on the 
        oem command image format and stores it inside a file
    '''
    check_params(params)

    p_header = [
        struct.pack('I', params.image_type),
        struct.pack('I', params.image_format_version),
        struct.pack('I', SIZE_OF_OEM_COMMAND_STORE_HEADER + SIZE_OF_OEM_COMMAND_STORE_SIGN + params.body_len),
        crypto_sha256(params.p_body)
    ]
    p_header = b''.join(p_header)[:SIZE_OF_OEM_COMMAND_STORE_HEADER]

    header_signature = crypto_rsa_sign(p_header, params.rsa_key_input_file)

    with open(params.store_output_file, 'wb') as output:
        output.write(p_header)
        output.write(header_signature)
        output.write(params.p_body)
