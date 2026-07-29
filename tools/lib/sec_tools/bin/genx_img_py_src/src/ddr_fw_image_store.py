import struct

from .type import StoreParamsT
from .crypto import *

IMAGE_TYPE_DDR_FW0 = 0x60
DDR_FW0            = "DDR_FW0"
IMAGE_TYPE_DDR_FW1 = 0x61
DDR_FW1            = "DDR_FW1"

SIZE_OF_DDR_FW_IMAGE_STORE_HEADER = 60

def check_params(params: StoreParamsT) -> None:
    '''
        This function checks the parameters for generate_ddr_fw_image_store
        function
    '''
    if params.p_body == b'':
        raise ErrInvalidParam('params.p_body is empty')
    if params.body_len == 0:
        raise ErrInvalidParam('Invalid body length - length 0')
    if params.body_len % CRYPTO_AES_KEY_LEN:
        raise ErrInvalidParam(f'Invalid body length - length not multiple of {CRYPTO_AES_KEY_LEN}')
    
def generate_ddr_fw_image_store(params: StoreParamsT) -> None:
    '''
        This function generates the encrypted image based on the
        ddr fw image format and stores it inside a file
    '''
    check_params(params)

    if not params.no_encryption:
        params.iv = crypto_get_random(CRYPTO_IV_LEN)

    p_header = [
        struct.pack('I', params.image_type),
        struct.pack('I', params.image_format_version),
        struct.pack('I', SIZE_OF_DDR_FW_IMAGE_STORE_HEADER + params.body_len),
        params.iv.rjust(CRYPTO_IV_LEN, b'\x00'),
        crypto_sha256(params.p_body)
    ]
    p_header = b''.join(p_header)[:SIZE_OF_DDR_FW_IMAGE_STORE_HEADER]

    if not params.no_encryption:
        params.p_body = crypto_aes256_enc(params.p_body, params.aes_enc_key, params.iv)
    else:
        print('WARNING: Skipping encryption')

    with open(params.store_output_file, 'wb') as output:
        output.write(p_header)
        output.write(params.p_body)
